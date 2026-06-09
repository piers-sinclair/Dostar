using System.Globalization;
using System.Threading.RateLimiting;
using Asp.Versioning;
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
using Scalar.AspNetCore;

const string V1DocumentName = "v1";
const string OpenApiRouteTemplate = "/openapi/{documentName}.json";
const string VersionedRoutePrefix = "/api/v{version:apiVersion}";
const string TestEnvironmentName = "Test";
const string RateLimitRejectionMessage = "Too many requests. Please try again later.";

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddApplicationInsightsTelemetry();

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
                    PermitLimit = 100,
                    Window = TimeSpan.FromSeconds(60),
                    QueueProcessingOrder = QueueProcessingOrder.OldestFirst,
                    QueueLimit = 0
                }));

    options.AddFixedWindowLimiter(RateLimitPolicy.Strict, o =>
    {
        o.PermitLimit = isTestEnvironment ? int.MaxValue : 10;
        o.Window = TimeSpan.FromMinutes(1);
        o.QueueProcessingOrder = QueueProcessingOrder.OldestFirst;
        o.QueueLimit = 0;
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
