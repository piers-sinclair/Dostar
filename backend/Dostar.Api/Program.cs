using Asp.Versioning;
using Dostar.Api.Cors;
using Dostar.Api.Middleware;
using Dostar.SharedKernel;
using Dostar.Todos.Implementation;
using Microsoft.AspNetCore.HttpLogging;
using Scalar.AspNetCore;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddOpenApi("v1");
builder.Services.AddHealthChecks();
builder.Services.AddProblemDetails();
builder.Services.AddApiVersioning(options =>
{
    options.DefaultApiVersion = new ApiVersion(1, 0);
    options.AssumeDefaultVersionWhenUnspecified = false;
    options.ReportApiVersions = true;
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

app.UseExceptionHandler();
app.UseStatusCodePages();
app.UseMiddleware<CorrelationIdMiddleware>();
app.UseHttpLogging();

app.UseCors(app.Environment.IsDevelopment() ? CorsPolicy.Development : CorsPolicy.Production);

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi("/openapi/{documentName}.json");
    app.MapScalarApiReference(options => options.AddDocument("v1"));
}

app.MapHealthChecks("/healthz");

var endpointModules = modules.OfType<IEndpointModule>().ToArray();
var versionSetBuilder = app.NewApiVersionSet();
foreach (var module in endpointModules)
    versionSetBuilder = versionSetBuilder.HasApiVersion(module.Version);
var apiVersionSet = versionSetBuilder.ReportApiVersions().Build();

var versionedGroup = app.MapGroup("/api/v{version:apiVersion}")
    .WithApiVersionSet(apiVersionSet);

foreach (var module in endpointModules)
    module.MapEndpoints(versionedGroup);

app.Run();
