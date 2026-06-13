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

Each module lives under `backend/Modules/<Name>/` and consists of four projects:

```
backend/Modules/Todos/
  Dostar.Todos.Contracts/        ← public API: interfaces + shared models only
  Dostar.Todos.Implementation/   ← implementation: DbContext, handlers, IModule impl
  Dostar.Todos.UnitTests/        ← unit tests (Testcontainers + NSubstitute)
  Dostar.Todos.IntegrationTests/ ← integration tests (WebApplicationFactory + Testcontainers)
```

All four projects travel together so the module can be extracted into a microservice as a unit.

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

## Logging

Inject `ILogger<TService>` via the primary constructor and define log methods using the `[LoggerMessage]` source-generation pattern. This compiles to a zero-allocation static helper — no string interpolation at the call site.

```csharp
public partial class WidgetService(WidgetDbContext db, ILogger<WidgetService> logger) : IWidgetService
{
    public async Task<WidgetDto> CreateAsync(string name, CancellationToken cancellationToken = default)
    {
        // ... create widget ...
        LogWidgetCreated(logger, widget.Id);
        return ToDto(widget);
    }

    public async Task<WidgetDto?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var widget = await db.Widgets.AsNoTracking().FirstOrDefaultAsync(w => w.Id == id, cancellationToken);
        if (widget is null)
        {
            LogWidgetNotFound(logger, id);
            return null;
        }
        return ToDto(widget);
    }

    [LoggerMessage(Level = LogLevel.Information, Message = "Widget created with id {WidgetId}")]
    private static partial void LogWidgetCreated(ILogger logger, Guid widgetId);

    [LoggerMessage(Level = LogLevel.Warning, Message = "Widget not found with id {WidgetId}")]
    private static partial void LogWidgetNotFound(ILogger logger, Guid widgetId);
}
```

**Rules:**
- Mark the service class `partial` — required by the source generator.
- Log methods are `private static partial void` — the generator emits the implementation.
- Pass `ILogger` (not `ILogger<T>`) into the log methods; the `<T>` binding lives only in the constructor.
- No DI registration needed — `ILogger<T>` is supplied automatically by ASP.NET Core's logging infrastructure.
- Add `global using Microsoft.Extensions.Logging;` to `GlobalUsings.cs` in the `.Implementation` project.

**What to log:**
- `Information` — successful mutations (record created/updated/deleted with the new id)
- `Warning` — not-found lookups (log the requested id)
- `Error` — unexpected failures (caught at the endpoint or middleware layer, not in the service)

## Tests

Unit and integration tests are colocated with their module under `backend/Modules/<Name>/`:

```bash
# Unit tests
dotnet test backend/Modules/<Name>/Dostar.<Name>.UnitTests

# Integration tests (requires Docker)
dotnet test backend/Modules/<Name>/Dostar.<Name>.IntegrationTests
```

**Stack:** xUnit + Shouldly + NSubstitute. Use Testcontainers PostgreSQL for DbContext isolation — never `InMemory`. Use NSubstitute for all other dependencies. All assertions must use Shouldly — never `Assert.*` or FluentAssertions.

**Test method naming:** `Method_Scenario_ExpectedBehaviour` — e.g. `GetAllAsync_WhenEmpty_ReturnsEmptyList`.

The root `tests/` folder is for cross-cutting UI tests (Playwright) only.
