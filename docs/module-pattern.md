# Module Pattern

Dostar uses a **modular monolith** structure. Each feature is a self-contained module that registers its own services and maps its own endpoints. `Program.cs` never needs to change when a module is added or removed.

## IModule interface

Every module implements `IModule` from `Dostar.SharedKernel`:

```csharp
public interface IModule
{
    void RegisterServices(IServiceCollection services, IConfiguration config);
    void MapEndpoints(IEndpointRouteBuilder app);
}
```

## Auto-discovery

`Program.cs` scans all loaded assemblies at startup for concrete `IModule` implementations and calls them in order:

1. `RegisterServices` — runs before `builder.Build()` to register DI services.
2. `MapEndpoints` — runs after `app` is built to map route handlers.

Because module assemblies are **project references** of `Dostar.Api`, they are guaranteed to be loaded when the scan runs.

## Adding a module

1. Create a new class library under `backend/Modules/<Name>/Dostar.<Name>/`.
2. Add a project reference to `Dostar.SharedKernel`.
3. Implement `IModule`:

```csharp
namespace Dostar.Todos;

public class TodosModule : IModule
{
    public void RegisterServices(IServiceCollection services, IConfiguration config)
    {
        // Register DbContext, repositories, etc.
    }

    public void MapEndpoints(IEndpointRouteBuilder app)
    {
        app.MapGet("/todos", () => Results.Ok());
    }
}
```

4. Add a project reference from `Dostar.Api` to `Dostar.<Name>`.
5. Add both projects to the solution (`dotnet sln add`).

No changes to `Program.cs` are needed — auto-discovery picks up the new `IModule` automatically.

## Module conventions

- Each module owns its own `DbContext` and EF Core migrations.
- Modules communicate **in-process** via shared interfaces — no HTTP calls between modules.
- Place shared contracts (events, value objects) in `Dostar.SharedKernel`, not in individual modules.
