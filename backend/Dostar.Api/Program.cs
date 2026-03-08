using Dostar.SharedKernel;
using Dostar.Todos.Implementation;
using Scalar.AspNetCore;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddOpenApi();
builder.Services.AddHealthChecks();

IModule[] modules =
[
    new TodosModule(),
];
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
