using Dostar.Api.Cors;
using Dostar.Api.Middleware;
using Dostar.SharedKernel;
using Dostar.Todos.Implementation;
using Microsoft.AspNetCore.HttpLogging;
using Scalar.AspNetCore;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddOpenApi();
builder.Services.AddHealthChecks();
builder.Services.AddProblemDetails();

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

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
    app.MapScalarApiReference();
}

app.MapHealthChecks("/healthz");
foreach (var module in modules.OfType<IEndpointModule>())
    module.MapEndpoints(app);

app.Run();
