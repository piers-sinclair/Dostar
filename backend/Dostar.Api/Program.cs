using Dostar.SharedKernel;
using Scalar.AspNetCore;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddOpenApi();
builder.Services.AddHealthChecks();

var modules = DiscoverModules();
foreach (var module in modules)
    module.RegisterServices(builder.Services, builder.Configuration);

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
    app.MapScalarApiReference();
}

app.MapHealthChecks("/healthz");

foreach (var module in modules)
    module.MapEndpoints(app);

app.Run();

static IReadOnlyList<IModule> DiscoverModules() =>
    AppDomain.CurrentDomain.GetAssemblies()
        .SelectMany(a => a.GetTypes())
        .Where(t => t is { IsAbstract: false, IsInterface: false } && t.IsAssignableTo(typeof(IModule)))
        .Select(t => (IModule)Activator.CreateInstance(t)!)
        .ToList();
