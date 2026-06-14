---
description: Scaffold a complete Dostar backend module (Contracts, Implementation, UnitTests) from a plain-English description.
argument-hint: <module description>
allowed-tools: Bash(dotnet *) Read Write Edit Glob Grep
---

# scaffold-module

Scaffold a complete Dostar feature module from a plain-English description.

## Usage

```
/scaffold-module <Description of the module>
```

Example: `/scaffold-module "Products — stores name, SKU, and price; supports CRUD"`

## What this skill does

Before starting, ask the user to confirm the **PascalCase module name** derived from the
description (e.g. `Products`). All file paths, namespaces, and CLI commands derive from this name.
Also derive a **kebab-case plural route prefix** (e.g. `products`, `order-items`).

Execute every step in order, then run `dotnet build` to confirm 0 warnings.

**TDD note:** when extending an existing module (adding a method or fixing a bug), write the failing test first (Step 11), then implement to make it pass. For a brand-new scaffold both are created together, but the unit tests in Step 11 still define the expected behaviour before `dotnet test` validates it.

---

## Step 1 — Infer the module shape

From the description, determine:
- **Entity fields**: name, C# type, required/optional
- **CRUD operations needed**: default is GetAll, GetById, Create, Update, Delete
- **Validation rules** for Create and Update (NotEmpty, MaximumLength, range, etc.)

---

## Step 2 — Create the Contracts project

```bash
dotnet new classlib -n Dostar.<Name>.Contracts \
  -o backend/Modules/<Name>/Dostar.<Name>.Contracts \
  --framework net10.0
dotnet sln Dostar.slnx add \
  backend/Modules/<Name>/Dostar.<Name>.Contracts/Dostar.<Name>.Contracts.csproj \
  --solution-folder backend
```

Delete the generated `Class1.cs`.

Create `backend/Modules/<Name>/Dostar.<Name>.Contracts/<Name>Dto.cs`:
```csharp
namespace Dostar.<Name>.Contracts;

public record <Name>Dto(Guid Id, /* fields from description */, DateTimeOffset CreatedAt);
```

Create `backend/Modules/<Name>/Dostar.<Name>.Contracts/I<Name>Service.cs`:
```csharp
namespace Dostar.<Name>.Contracts;

public interface I<Name>Service
{
    Task<IEnumerable<<Name>Dto>> GetAllAsync(CancellationToken cancellationToken = default);
    Task<<Name>Dto> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task<<Name>Dto> CreateAsync(/* typed params inferred from description */, CancellationToken cancellationToken = default);
    Task<<Name>Dto> UpdateAsync(Guid id, /* typed params inferred from description */, CancellationToken cancellationToken = default);
    Task DeleteAsync(Guid id, CancellationToken cancellationToken = default);
}
```

No extra NuGet packages or project references needed in Contracts.

---

## Step 3 — Create the Implementation project

```bash
dotnet new classlib -n Dostar.<Name>.Implementation \
  -o backend/Modules/<Name>/Dostar.<Name>.Implementation \
  --framework net10.0
dotnet sln Dostar.slnx add \
  backend/Modules/<Name>/Dostar.<Name>.Implementation/Dostar.<Name>.Implementation.csproj \
  --solution-folder backend
dotnet add \
  backend/Modules/<Name>/Dostar.<Name>.Implementation/Dostar.<Name>.Implementation.csproj \
  reference \
  backend/Modules/<Name>/Dostar.<Name>.Contracts/Dostar.<Name>.Contracts.csproj \
  backend/Dostar.SharedKernel/Dostar.SharedKernel.csproj
```

Delete the generated `Class1.cs`.

Edit `Dostar.<Name>.Implementation.csproj` so the `<PropertyGroup>` and item groups match the
canonical pattern from `Dostar.Todos.Implementation.csproj`:
```xml
<Project Sdk="Microsoft.NET.Sdk">

  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
    <TreatWarningsAsErrors>true</TreatWarningsAsErrors>
    <AnalysisLevel>latest-Recommended</AnalysisLevel>
    <EnforceCodeStyleInBuild>true</EnforceCodeStyleInBuild>
  </PropertyGroup>

  <ItemGroup>
    <FrameworkReference Include="Microsoft.AspNetCore.App" />
  </ItemGroup>

  <ItemGroup>
    <ProjectReference Include="..\Dostar.<Name>.Contracts\Dostar.<Name>.Contracts.csproj" />
    <ProjectReference Include="..\..\..\Dostar.SharedKernel\Dostar.SharedKernel.csproj" />
  </ItemGroup>

  <ItemGroup>
    <PackageReference Include="Npgsql.EntityFrameworkCore.PostgreSQL" Version="10.0.0" />
  </ItemGroup>

</Project>
```

---

## Step 4 — Create GlobalUsings.cs

Create `backend/Modules/<Name>/Dostar.<Name>.Implementation/GlobalUsings.cs`:
```csharp
global using System.Diagnostics.CodeAnalysis;
global using Dostar.SharedKernel;
global using Dostar.SharedKernel.Exceptions;
global using Dostar.<Name>.Contracts;
global using FluentValidation;
global using Dostar.<Name>.Implementation.Application;
global using Dostar.<Name>.Implementation.Domain;
global using Dostar.<Name>.Implementation.Infrastructure;
global using Microsoft.AspNetCore.Builder;
global using Microsoft.AspNetCore.Http;
global using Microsoft.AspNetCore.Routing;
global using Microsoft.EntityFrameworkCore;
global using Microsoft.Extensions.Configuration;
global using Microsoft.Extensions.DependencyInjection;
global using Microsoft.Extensions.Logging;
```

Never add `using` directives inside individual files in this project — all go here.

---

## Step 5 — Create the Domain entity

Create `backend/Modules/<Name>/Dostar.<Name>.Implementation/Domain/<Name>.cs`:
```csharp
namespace Dostar.<Name>.Implementation.Domain;

public class <Name>
{
    public Guid Id { get; set; }
    // All fields from description with appropriate C# types
    public DateTimeOffset CreatedAt { get; set; }
}
```

---

## Step 6 — Create the DbContext

Create `backend/Modules/<Name>/Dostar.<Name>.Implementation/Infrastructure/<Name>DbContext.cs`:
```csharp
namespace Dostar.<Name>.Implementation.Infrastructure;

public class <Name>DbContext(DbContextOptions<<Name>DbContext> options) : DbContext(options)
{
    public DbSet<<Name>> <PluralName> => Set<<Name>>();
}
```

---

## Step 7 — Create the Service

Create `backend/Modules/<Name>/Dostar.<Name>.Implementation/Application/<Name>Service.cs`:
```csharp
namespace Dostar.<Name>.Implementation.Application;

[ExcludeFromCodeCoverage]
public partial class <Name>Service(<Name>DbContext db, ILogger<<Name>Service> logger) : I<Name>Service
{
    public async Task<IEnumerable<<Name>Dto>> GetAllAsync(CancellationToken cancellationToken = default) =>
        await db.<PluralName>
            .Select(x => ToDto(x))
            .ToListAsync(cancellationToken);

    public async Task<<Name>Dto> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var entity = await db.<PluralName>.AsNoTracking().FirstOrDefaultAsync(x => x.Id == id, cancellationToken);
        if (entity is null)
        {
            Log<Name>NotFound(logger, id);
            throw new NotFoundException($"<Name> {id} not found.");
        }
        return ToDto(entity);
    }

    public async Task<<Name>Dto> CreateAsync(/* typed params matching I<Name>Service */, CancellationToken cancellationToken = default)
    {
        var entity = new <Name>
        {
            Id = Guid.CreateVersion7(),
            // assign params to fields
            CreatedAt = DateTimeOffset.UtcNow,
        };
        db.<PluralName>.Add(entity);
        await db.SaveChangesAsync(cancellationToken);
        Log<Name>Created(logger, entity.Id);
        return ToDto(entity);
    }

    public async Task<<Name>Dto> UpdateAsync(Guid id, /* typed params */, CancellationToken cancellationToken = default)
    {
        var entity = await db.<PluralName>.FirstOrDefaultAsync(x => x.Id == id, cancellationToken);
        if (entity is null) throw new NotFoundException($"<Name> {id} not found.");
        // assign updated fields
        await db.SaveChangesAsync(cancellationToken);
        return ToDto(entity);
    }

    public async Task DeleteAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var deleted = await db.<PluralName>
            .Where(x => x.Id == id)
            .ExecuteDeleteAsync(cancellationToken);
        if (deleted == 0) throw new NotFoundException($"<Name> {id} not found.");
    }

    private static <Name>Dto ToDto(<Name> x) =>
        new(x.Id, /* all fields in Dto order */, x.CreatedAt);

    [LoggerMessage(Level = LogLevel.Information, Message = "<Name> created with id {<Name>Id}")]
    private static partial void Log<Name>Created(ILogger logger, Guid <name>Id);

    [LoggerMessage(Level = LogLevel.Warning, Message = "<Name> not found with id {<Name>Id}")]
    private static partial void Log<Name>NotFound(ILogger logger, Guid <name>Id);
}
```

---

## Step 8 — Create validators

Create `backend/Modules/<Name>/Dostar.<Name>.Implementation/Application/Create<Name>RequestValidator.cs`:
```csharp
namespace Dostar.<Name>.Implementation.Application;

public class Create<Name>RequestValidator : AbstractValidator<Create<Name>Request>
{
    public Create<Name>RequestValidator()
    {
        // RuleFor rules inferred from field types and constraints in the description
    }
}
```

Create `backend/Modules/<Name>/Dostar.<Name>.Implementation/Application/Update<Name>RequestValidator.cs`
with the same pattern for `Update<Name>Request`.

---

## Step 9 — Create the Module class

Create `backend/Modules/<Name>/Dostar.<Name>.Implementation/<Name>Module.cs`:
```csharp
namespace Dostar.<Name>.Implementation;

public class <Name>Module : IEndpointModule
{
    private const string ConnectionStringName = "Default";
    private const string RoutePrefix = "/api/<kebab-plural-name>";
    private const string RootRoute = "/";
    private const string IdRoute = "/{id:guid}";

    public void RegisterServices(IServiceCollection services, IConfiguration config)
    {
        services.AddDbContext<<Name>DbContext>(options =>
            options.UseNpgsql(config.GetConnectionString(ConnectionStringName)));
        services.AddScoped<I<Name>Service, <Name>Service>();
        services.AddScoped<IValidator<Create<Name>Request>, Create<Name>RequestValidator>();
        services.AddScoped<IValidator<Update<Name>Request>, Update<Name>RequestValidator>();
    }

    public void MapEndpoints(IEndpointRouteBuilder app)
    {
        var group = app.MapGroup(RoutePrefix);

        group.MapGet(RootRoute, async (I<Name>Service service, CancellationToken ct) =>
            Results.Ok(await service.GetAllAsync(ct)));

        group.MapGet(IdRoute, async (Guid id, I<Name>Service service, CancellationToken ct) =>
            Results.Ok(await service.GetByIdAsync(id, ct)));

        group.MapPost(RootRoute, async (Create<Name>Request request, I<Name>Service service, CancellationToken ct) =>
        {
            var item = await service.CreateAsync(/* request fields */, ct);
            return Results.Created($"{RoutePrefix}/{item.Id}", item);
        }).AddEndpointFilter<ValidationFilter<Create<Name>Request>>();

        group.MapPut(IdRoute, async (Guid id, Update<Name>Request request, I<Name>Service service, CancellationToken ct) =>
            Results.Ok(await service.UpdateAsync(id, /* request fields */, ct)))
            .AddEndpointFilter<ValidationFilter<Update<Name>Request>>();

        group.MapDelete(IdRoute, async (Guid id, I<Name>Service service, CancellationToken ct) =>
        {
            await service.DeleteAsync(id, ct);
            return Results.NoContent();
        });
    }
}

public record Create<Name>Request(/* fields from description, excluding Id and CreatedAt */);
public record Update<Name>Request(/* same mutable fields as Create */);
```

---

## Step 10 — Wire Dostar.Api

```bash
dotnet add backend/Dostar.Api/Dostar.Api.csproj \
  reference \
  backend/Modules/<Name>/Dostar.<Name>.Implementation/Dostar.<Name>.Implementation.csproj
```

Edit `backend/Dostar.Api/Program.cs`:
- Add `using Dostar.<Name>.Implementation;` at the top with the other module using directives
- Add `new <Name>Module(),` to the `IModule[] modules` array

---

## Step 11 — Create the unit test project

```bash
dotnet new xunit -n Dostar.<Name>.UnitTests \
  -o backend/Modules/<Name>/Dostar.<Name>.UnitTests \
  --framework net10.0
dotnet sln Dostar.slnx add \
  backend/Modules/<Name>/Dostar.<Name>.UnitTests/Dostar.<Name>.UnitTests.csproj \
  --solution-folder backend
dotnet add backend/Modules/<Name>/Dostar.<Name>.UnitTests/Dostar.<Name>.UnitTests.csproj \
  reference \
  backend/Modules/<Name>/Dostar.<Name>.Implementation/Dostar.<Name>.Implementation.csproj
dotnet add backend/Modules/<Name>/Dostar.<Name>.UnitTests/Dostar.<Name>.UnitTests.csproj package Shouldly
dotnet add backend/Modules/<Name>/Dostar.<Name>.UnitTests/Dostar.<Name>.UnitTests.csproj package AutoFixture
dotnet add backend/Modules/<Name>/Dostar.<Name>.UnitTests/Dostar.<Name>.UnitTests.csproj package NSubstitute
dotnet add backend/Modules/<Name>/Dostar.<Name>.UnitTests/Dostar.<Name>.UnitTests.csproj package Microsoft.EntityFrameworkCore.InMemory
dotnet add backend/Modules/<Name>/Dostar.<Name>.UnitTests/Dostar.<Name>.UnitTests.csproj package coverlet.collector
```

Edit `Dostar.<Name>.UnitTests.csproj` to match the canonical pattern from
`backend/Modules/Todos/Dostar.Todos.UnitTests/Dostar.Todos.UnitTests.csproj`:
- Add `<TreatWarningsAsErrors>true</TreatWarningsAsErrors>` in `<PropertyGroup>`
- Add `<IsPackable>false</IsPackable>` in `<PropertyGroup>`
- Add an item group `<Using Include="Xunit" />`

Delete the generated `UnitTest1.cs`.

Create `backend/Modules/<Name>/Dostar.<Name>.UnitTests/<Name>ServiceTests.cs`:
- Explicit `using` directives at the top of the file (no GlobalUsings in test projects)
- Static `CreateDbContext()` helper using `UseInMemoryDatabase(Guid.NewGuid().ToString())`
- Static `CreateService(<Name>DbContext db)` helper: `new <Name>Service(db, Substitute.For<ILogger<<Name>Service>>())`
- `await using var db = CreateDbContext();` in every test; call `CreateService(db)` to get the SUT
- One `[Fact]` per scenario, covering:
  - `GetAllAsync` when empty → empty list
  - `CreateAsync` → returns DTO with correct field values
  - `GetAllAsync` after create → returns the item
  - `GetByIdAsync` when exists → returns DTO
  - `GetByIdAsync` when not found → `Should.ThrowAsync<NotFoundException>(...)`
  - `GetByIdAsync` when not found → logs a warning (create an explicit `ILogger` substitute via `Substitute.For<ILogger<<Name>Service>>()`, pass it to `new <Name>Service(db, logger)`, assert `logger.Received(1).Log(LogLevel.Warning, ...)`)
  - `UpdateAsync` when exists → updates fields and returns DTO
  - `UpdateAsync` when not found → `Should.ThrowAsync<NotFoundException>(...)`
  - `DeleteAsync` when exists → completes without throwing; item no longer retrievable via `GetAllAsync`
  - `DeleteAsync` when not found → `Should.ThrowAsync<NotFoundException>(...)`
- **Shouldly** assertions only — never FluentAssertions

---

## Step 12 — Verify

```bash
dotnet build
dotnet test backend/Modules/<Name>/Dostar.<Name>.UnitTests
```

Both must pass with **0 warnings** and **0 failures**. Fix any issues before reporting success.

---

## Conventions reminder

- `TreatWarningsAsErrors` is on — every warning is a blocker.
- No `using` inside `.Implementation` files; everything goes in `GlobalUsings.cs`.
- Assertions: **Shouldly only** — never FluentAssertions.
- Validation: **FluentValidation + `ValidationFilter<T>`** — never DataAnnotations.
- Route prefix: lowercase kebab-case plural (e.g. `/api/products`, `/api/order-items`).
- **EF Core migrations are NOT created here** — after your DB is running, use `/add-migration`.
- For any new NuGet package not already used in the codebase, run `/add-package` first.
