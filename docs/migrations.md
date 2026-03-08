# EF Core Migrations

Each module owns its own `DbContext` and migrations. They are fully independent — migrating one module has no effect on another.

## Setup per module

Each `.Implementation` project manages its own data layer. Add the required packages:

```bash
dotnet add backend/Modules/<Name>/Dostar.<Name>.Implementation package Npgsql.EntityFrameworkCore.PostgreSQL
```

Place the `DbContext` at:

```
backend/Modules/<Name>/Dostar.<Name>.Implementation/Infrastructure/<Name>DbContext.cs
```

Register it in `RegisterServices`:

```csharp
public void RegisterServices(IServiceCollection services, IConfiguration configuration)
{
    services.AddDbContext<TodosDbContext>(options =>
        options.UseNpgsql(configuration.GetConnectionString("Default")));
}
```

## Adding a migration

```bash
dotnet ef migrations add <MigrationName> \
  --project backend/Modules/<Name>/Dostar.<Name>.Implementation \
  --startup-project backend/Dostar.Api \
  --context <Name>DbContext
```

Migrations are written into the `.Implementation` project under `Infrastructure/Migrations/`.

## Applying migrations

```bash
# Apply a specific module's migrations
dotnet ef database update \
  --project backend/Modules/<Name>/Dostar.<Name>.Implementation \
  --startup-project backend/Dostar.Api \
  --context <Name>DbContext

# Remove the last migration (before it's applied)
dotnet ef migrations remove \
  --project backend/Modules/<Name>/Dostar.<Name>.Implementation \
  --startup-project backend/Dostar.Api \
  --context <Name>DbContext
```

## Connection string

The connection string key is `Default`, configured in `appsettings.Development.json`:

```json
{
  "ConnectionStrings": {
    "Default": "Host=localhost;Port=5432;Database=dostar;Username=dostar;Password=dostar"
  }
}
```

In production this is set via Azure App Service environment variables (never committed to the repo).

## Why `--startup-project backend/Dostar.Api`?

`Dostar.Api` holds `Microsoft.EntityFrameworkCore.Design` and is the application host, so the `dotnet ef` tool uses it to instantiate the `DbContext` at design time. The `--project` flag tells it where to write the migration files.
