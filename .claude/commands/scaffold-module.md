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
    Task<IEnumerable<<Name>Dto>> GetAllAsync();
    Task<<Name>Dto?> GetByIdAsync(Guid id);
    Task<<Name>Dto> CreateAsync(/* typed params inferred from description */);
    Task<<Name>Dto?> UpdateAsync(Guid id, /* typed params inferred from description */);
    Task<bool> DeleteAsync(Guid id);
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
global using Dostar.SharedKernel;
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

public class <Name>Service(<Name>DbContext db) : I<Name>Service
{
    public async Task<IEnumerable<<Name>Dto>> GetAllAsync() =>
        await db.<PluralName>
            .Select(x => ToDto(x))
            .ToListAsync();

    public async Task<<Name>Dto?> GetByIdAsync(Guid id)
    {
        var entity = await db.<PluralName>.FindAsync(id);
        return entity is null ? null : ToDto(entity);
    }

    public async Task<<Name>Dto> CreateAsync(/* typed params matching I<Name>Service */)
    {
        var entity = new <Name>
        {
            Id = Guid.NewGuid(),
            // assign params to fields
            CreatedAt = DateTimeOffset.UtcNow,
        };
        db.<PluralName>.Add(entity);
        await db.SaveChangesAsync();
        return ToDto(entity);
    }

    public async Task<<Name>Dto?> UpdateAsync(Guid id, /* typed params */)
    {
        var entity = await db.<PluralName>.FindAsync(id);
        if (entity is null)
            return null;
        // assign updated fields
        await db.SaveChangesAsync();
        return ToDto(entity);
    }

    public async Task<bool> DeleteAsync(Guid id)
    {
        var entity = await db.<PluralName>.FindAsync(id);
        if (entity is null)
            return false;
        db.<PluralName>.Remove(entity);
        await db.SaveChangesAsync();
        return true;
    }

    private static <Name>Dto ToDto(<Name> x) =>
        new(x.Id, /* all fields in Dto order */, x.CreatedAt);
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

        group.MapGet(RootRoute, async (I<Name>Service service) =>
            Results.Ok(await service.GetAllAsync()));

        group.MapGet(IdRoute, async (Guid id, I<Name>Service service) =>
        {
            var item = await service.GetByIdAsync(id);
            return item is null ? Results.NotFound() : Results.Ok(item);
        });

        group.MapPost(RootRoute, async (Create<Name>Request request, I<Name>Service service) =>
        {
            var item = await service.CreateAsync(/* request fields */);
            return Results.Created($"{RoutePrefix}/{item.Id}", item);
        }).AddEndpointFilter<ValidationFilter<Create<Name>Request>>();

        group.MapPut(IdRoute, async (Guid id, Update<Name>Request request, I<Name>Service service) =>
        {
            var item = await service.UpdateAsync(id, /* request fields */);
            return item is null ? Results.NotFound() : Results.Ok(item);
        }).AddEndpointFilter<ValidationFilter<Update<Name>Request>>();

        group.MapDelete(IdRoute, async (Guid id, I<Name>Service service) =>
        {
            var deleted = await service.DeleteAsync(id);
            return deleted ? Results.NoContent() : Results.NotFound();
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
dotnet new xunit -n Dostar.<Name>.Tests \
  -o tests/Dostar.<Name>.Tests \
  --framework net10.0
dotnet sln Dostar.slnx add \
  tests/Dostar.<Name>.Tests/Dostar.<Name>.Tests.csproj \
  --solution-folder tests
dotnet add tests/Dostar.<Name>.Tests/Dostar.<Name>.Tests.csproj \
  reference \
  backend/Modules/<Name>/Dostar.<Name>.Implementation/Dostar.<Name>.Implementation.csproj
dotnet add tests/Dostar.<Name>.Tests/Dostar.<Name>.Tests.csproj package Shouldly
dotnet add tests/Dostar.<Name>.Tests/Dostar.<Name>.Tests.csproj package NSubstitute
dotnet add tests/Dostar.<Name>.Tests/Dostar.<Name>.Tests.csproj package Microsoft.EntityFrameworkCore.InMemory
dotnet add tests/Dostar.<Name>.Tests/Dostar.<Name>.Tests.csproj package coverlet.collector
```

Edit `Dostar.<Name>.Tests.csproj` to match the canonical pattern from
`tests/Dostar.Todos.Tests/Dostar.Todos.Tests.csproj`:
- Add `<TreatWarningsAsErrors>true</TreatWarningsAsErrors>` in `<PropertyGroup>`
- Add `<IsPackable>false</IsPackable>` in `<PropertyGroup>`
- Add an item group `<Using Include="Xunit" />`

Delete the generated `UnitTest1.cs`.

Create `tests/Dostar.<Name>.Tests/<Name>ServiceTests.cs`, following the exact pattern in
`tests/Dostar.Todos.Tests/TodoServiceTests.cs`:
- Explicit `using` directives at the top of the file (no GlobalUsings in test projects)
- Static `CreateDbContext()` helper using `UseInMemoryDatabase(Guid.NewGuid().ToString())`
- `await using var db = CreateDbContext();` in every test
- One `[Fact]` per scenario, covering:
  - `GetAllAsync` when empty → empty list
  - `CreateAsync` → returns DTO with correct field values
  - `GetAllAsync` after create → returns the item
  - `GetByIdAsync` when exists → returns DTO
  - `GetByIdAsync` when not found → returns null
  - `UpdateAsync` when exists → updates fields and returns DTO
  - `UpdateAsync` when not found → returns null
  - `DeleteAsync` when exists → returns true, item no longer retrievable
  - `DeleteAsync` when not found → returns false
- **Shouldly** assertions only — never FluentAssertions

---

## Step 12 — Verify

```bash
dotnet build
dotnet test tests/Dostar.<Name>.Tests
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
