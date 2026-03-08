using Dostar.SharedKernel;
using Scalar.AspNetCore;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddOpenApi();
builder.Services.AddHealthChecks();

IModule[] modules = [];

foreach (var module in modules)
    module.RegisterServices(builder.Services, builder.Configuration);

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
    app.MapScalarApiReference();
}

app.MapHealthChecks("/healthz");

foreach (var module in modules.OfType<IEndpointModule>())
    module.MapEndpoints(app);

app.Run();
