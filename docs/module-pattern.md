# Module Pattern

Dostar uses a **modular monolith** structure. Each feature is a self-contained module that registers its own services and optionally maps its own endpoints.

## Interfaces

Two interfaces live in `Dostar.SharedKernel`:

**`IModule`** — every module implements this, including infrastructure modules with no HTTP surface:
```csharp
public interface IModule
{
    void RegisterServices(IServiceCollection services, IConfiguration config);
}
```

**`IEndpointModule`** — extends `IModule` for modules that expose HTTP endpoints:
```csharp
public interface IEndpointModule : IModule
{
    void MapEndpoints(IEndpointRouteBuilder app);
}
```

## Registration

Modules are registered explicitly in `Program.cs`:

```csharp
IModule[] modules =
[
    new AzureStorageModule(),   // infrastructure — IModule only
    new TodosModule(),          // feature — IEndpointModule
];

foreach (var module in modules)
    module.RegisterServices(builder.Services, builder.Configuration);

var app = builder.Build();

foreach (var module in modules.OfType<IEndpointModule>())
    module.MapEndpoints(app);
```

Order matters: infrastructure modules that register shared services should appear before feature modules that depend on them.

## Project structure per module

Each module lives under `backend/Modules/<Name>/` and consists of two projects:

```
backend/Modules/Todos/
  Dostar.Todos.Contracts/        ← public API: interfaces + shared models only
  Dostar.Todos.Implementation/   ← implementation: DbContext, handlers, IModule impl
```

**References:**
- `Dostar.Todos.Implementation` → `Dostar.Todos.Contracts` (owns its public API)
- `Dostar.Todos.Implementation` → `Dostar.SharedKernel` (IModule / IEndpointModule)
- `Dostar.Api` → `Dostar.Todos.Implementation` (to get the module registered at startup)
- Other modules that need Todos services → `Dostar.Todos.Contracts` only — never the Implementation project

## Adding a module

### Feature module (with endpoints)

1. Create `Dostar.<Name>.Contracts` class library — add interfaces and models consumed by other modules.
2. Create `Dostar.<Name>.Implementation` class library — reference Contracts and SharedKernel.
3. Implement `IEndpointModule`:

```csharp
namespace Dostar.Todos.Implementation;

public class TodosModule : IEndpointModule
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

4. If the module needs a database, add `Npgsql.EntityFrameworkCore.PostgreSQL` to the `.Implementation` project and place the `DbContext` at `Infrastructure/<Name>DbContext.cs`. See `docs/migrations.md` for the full migration workflow.
5. Add `Dostar.Api` → `Dostar.<Name>.Implementation` project reference.
6. Add both projects to the solution (`dotnet sln add`).
7. Register the module in `Program.cs`.

### Infrastructure module (no endpoints)

Same steps, but implement `IModule` instead of `IEndpointModule` — no `MapEndpoints` needed.

## Module conventions

- Each module owns its own `DbContext` and EF Core migrations.
- Modules communicate **in-process** via Contracts interfaces — no HTTP calls between modules.
- `Dostar.SharedKernel` is for framework-level contracts (`IModule`, `IEndpointModule`) only — not module-specific interfaces.
- A module's `.Contracts` project must have no implementation dependencies (no EF Core, no HTTP, no business logic).

## Request validation

Dostar uses `FluentValidation` for request validation via a shared `ValidationFilter<T>` endpoint filter in `Dostar.SharedKernel`. Invalid requests receive a `422 Unprocessable Entity` response with a `errors` object keyed by field name (standard `ValidationProblemDetails`).

### Adding a validator for a new module

1. Create a validator in your `.Implementation` project (conventionally in `Application/`):

```csharp
public class CreateWidgetRequestValidator : AbstractValidator<CreateWidgetRequest>
{
    public CreateWidgetRequestValidator()
    {
        RuleFor(x => x.Name).NotEmpty().MaximumLength(200);
    }
}
```

2. Register the validator in `RegisterServices`:

```csharp
services.AddScoped<IValidator<CreateWidgetRequest>, CreateWidgetRequestValidator>();
```

3. Attach the filter to the relevant endpoint in `MapEndpoints`:

```csharp
group.MapPost("/", handler)
    .AddEndpointFilter<ValidationFilter<CreateWidgetRequest>>();
```

No additional package references are needed — `FluentValidation` flows through `Dostar.SharedKernel`.

## Unit tests

Unit tests for a module live under `tests/Dostar.<Name>.Tests/` — not alongside the module in `backend/`. All test types (unit, integration, UI tests) are co-located in the root `tests/` folder so that `backend/` remains pure production code and CI can run the full suite with a single `dotnet test tests/` invocation.

```
tests/
  Dostar.Todos.Tests/          ← unit tests for the Todos module
  Dostar.IntegrationTests/     ← cross-module integration tests (Testcontainers)
```

Test projects are grouped under the `/tests/` solution folder in `Dostar.slnx`.

**Stack:** xUnit + Shouldly + NSubstitute. Use `Microsoft.EntityFrameworkCore.InMemory` for DbContext isolation in unit tests.
