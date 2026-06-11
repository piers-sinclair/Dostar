using System.Globalization;
using System.Threading.RateLimiting;
using Asp.Versioning;
using Azure.Monitor.OpenTelemetry.AspNetCore;
using Dostar.Api.Cors;
using Dostar.Api.HealthChecks;
using Dostar.Api.Middleware;
using Dostar.SharedKernel;
using Dostar.Todos.Implementation;
using Dostar.Todos.Implementation.Infrastructure;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Diagnostics.HealthChecks;
using Microsoft.AspNetCore.HttpLogging;
using Microsoft.AspNetCore.RateLimiting;
using Npgsql;
using OpenTelemetry;
using Scalar.AspNetCore;

const string V1DocumentName = "v1";
const string OpenApiRouteTemplate = "/openapi/{documentName}.json";
const string VersionedRoutePrefix = "/api/v{version:apiVersion}";
const string TestEnvironmentName = "Test";
const string RateLimitRejectionMessage = "Too many requests. Please try again later.";
const string AppInsightsConnectionStringKey = "APPLICATIONINSIGHTS_CONNECTION_STRING";

var builder = WebApplication.CreateBuilder(args);

var otelBuilder = builder.Services.AddOpenTelemetry()
    .WithTracing(tracing => tracing.AddNpgsql())
    .WithMetrics(metrics => metrics.AddNpgsqlInstrumentation());

if (!string.IsNullOrEmpty(builder.Configuration[AppInsightsConnectionStringKey]))
    otelBuilder.UseAzureMonitor();

builder.Services.AddOpenApi(V1DocumentName);
builder.Services.AddHealthChecks();
builder.Services.AddProblemDetails();
builder.Services.AddApiVersioning(options =>
{
    options.DefaultApiVersion = new ApiVersion(1, 0);
    options.AssumeDefaultVersionWhenUnspecified = false;
    options.ReportApiVersions = true;
});

var isTestEnvironment = builder.Environment.IsEnvironment(TestEnvironmentName);
builder.Services.AddRateLimiter(options =>
{
    options.GlobalLimiter = PartitionedRateLimiter.Create<HttpContext, string>(context =>
        isTestEnvironment
            ? RateLimitPartition.GetNoLimiter(RateLimitPolicy.TestPartition)
            : RateLimitPartition.GetFixedWindowLimiter(
                partitionKey: context.Connection.RemoteIpAddress?.ToString() ?? RateLimitPolicy.UnknownIpPartition,
                factory: _ => new FixedWindowRateLimiterOptions
                {
                    PermitLimit = RateLimitPolicy.GlobalPermitLimit,
                    Window = RateLimitPolicy.RateLimitWindow,
                    QueueProcessingOrder = QueueProcessingOrder.OldestFirst,
                    QueueLimit = RateLimitPolicy.NoQueueLimit
                }));

    options.AddFixedWindowLimiter(RateLimitPolicy.Strict, o =>
    {
        o.PermitLimit = isTestEnvironment ? int.MaxValue : RateLimitPolicy.StrictPermitLimit;
        o.Window = RateLimitPolicy.RateLimitWindow;
        o.QueueProcessingOrder = QueueProcessingOrder.OldestFirst;
        o.QueueLimit = RateLimitPolicy.NoQueueLimit;
    });

    options.OnRejected = async (context, token) =>
    {
        context.HttpContext.Response.StatusCode = StatusCodes.Status429TooManyRequests;
        if (context.Lease.TryGetMetadata(MetadataName.RetryAfter, out var retryAfter))
            context.HttpContext.Response.Headers.RetryAfter =
                ((int)retryAfter.TotalSeconds).ToString(CultureInfo.InvariantCulture);
        await context.HttpContext.Response.WriteAsync(RateLimitRejectionMessage, token);
    };
});

builder.Services.AddHttpLogging(options =>
{
    options.LoggingFields = HttpLoggingFields.RequestMethod
        | HttpLoggingFields.RequestPath
        | HttpLoggingFields.ResponseStatusCode
        | HttpLoggingFields.Duration;
});

var allowedOrigins = builder.Configuration.GetSection(CorsPolicy.ConfigSection).Get<string[]>() ?? [];
builder.Services.AddCors(options =>
{
    options.AddPolicy(CorsPolicy.Development, policy =>
        policy.WithOrigins(CorsPolicy.DevOrigin)
              .AllowAnyHeader()
              .AllowAnyMethod());

    options.AddPolicy(CorsPolicy.Production, policy =>
        policy.WithOrigins(allowedOrigins)
              .AllowAnyHeader()
              .AllowAnyMethod());
});

IModule[] modules =
[
    new TodosModule(),
];
foreach (var module in modules)
    module.RegisterServices(builder.Services, builder.Configuration);

var app = builder.Build();

app.UseMiddleware<SecurityHeadersMiddleware>();
app.UseExceptionHandler();
app.UseStatusCodePages();
app.UseMiddleware<CorrelationIdMiddleware>();
app.UseHttpLogging();

app.UseCors(app.Environment.IsDevelopment() && allowedOrigins.Length == 0 ? CorsPolicy.Development : CorsPolicy.Production);
app.UseRateLimiter();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi(OpenApiRouteTemplate);
    app.MapScalarApiReference(options => options.AddDocument(V1DocumentName));
}

app.MapHealthChecks("/healthz/live", new HealthCheckOptions
{
    Predicate = _ => false,
    ResponseWriter = HealthCheckResponseWriter.WriteResponse
});
app.MapHealthChecks("/healthz/ready", new HealthCheckOptions
{
    ResponseWriter = HealthCheckResponseWriter.WriteResponse
});

var endpointModules = modules.OfType<IEndpointModule>().ToArray();
var versionSetBuilder = app.NewApiVersionSet();
foreach (var module in endpointModules)
    versionSetBuilder = versionSetBuilder.HasApiVersion(module.Version);
var apiVersionSet = versionSetBuilder.ReportApiVersions().Build();

var versionedGroup = app.MapGroup(VersionedRoutePrefix)
    .WithApiVersionSet(apiVersionSet);

foreach (var module in endpointModules)
    module.MapEndpoints(versionedGroup);

app.Run();

public partial class Program { }
