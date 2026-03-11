using System.Globalization;
using System.Threading.RateLimiting;
using Dostar.Api.Cors;
using Dostar.Api.HealthChecks;
using Dostar.Api.Middleware;
using Dostar.SharedKernel;
using Dostar.Todos.Implementation;
using Microsoft.AspNetCore.Diagnostics.HealthChecks;
using Microsoft.AspNetCore.HttpLogging;
using Microsoft.AspNetCore.RateLimiting;
using Scalar.AspNetCore;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddOpenApi();
builder.Services.AddHealthChecks();
builder.Services.AddProblemDetails();

const string TestEnvironmentName = "Test";
const string RateLimitRejectionMessage = "Too many requests. Please try again later.";
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
builder.Services.AddHttpLogging(options =>
{
    options.LoggingFields = HttpLoggingFields.RequestMethod
        | HttpLoggingFields.RequestPath
        | HttpLoggingFields.ResponseStatusCode
        | HttpLoggingFields.Duration;
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

app.UseCors(app.Environment.IsDevelopment() ? CorsPolicy.Development : CorsPolicy.Production);
app.UseRateLimiter();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
    app.MapScalarApiReference();
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
foreach (var module in modules.OfType<IEndpointModule>())
    module.MapEndpoints(app);

app.Run();
