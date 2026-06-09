# EF Core Migrations

Dostar uses **code-first migrations**: domain entities (C# classes) define the schema, and `dotnet ef migrations add` generates SQL from them. Never write SQL by hand or modify migration files after they are applied.

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

```sh
dotnet ef migrations add <MigrationName> --project backend/Modules/<Name>/Dostar.<Name>.Implementation --startup-project backend/Dostar.Api --context <Name>DbContext
```

Migrations are written into the `.Implementation` project under `Infrastructure/Migrations/`.

## Applying migrations

```sh
# Apply a specific module's migrations
dotnet ef database update --project backend/Modules/<Name>/Dostar.<Name>.Implementation --startup-project backend/Dostar.Api --context <Name>DbContext

# Remove the last migration (before it's applied)
dotnet ef migrations remove --project backend/Modules/<Name>/Dostar.<Name>.Implementation --startup-project backend/Dostar.Api --context <Name>DbContext
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

## Production migrations

In production, migrations run as a dedicated step in `cd-backend.yml` **before** the app is deployed. The `migrate` job:

1. Installs `dotnet-ef` globally
2. Runs `bash tools/run-migrations.sh`, which discovers every `Dostar.<Name>.Implementation` project that has a `Migrations/` directory and calls `dotnet ef database update` for each one using the `DB_CONNECTION_STRING` secret
3. Exits cleanly

The `deploy` job has `needs: migrate` — the app only starts after migrations succeed. This prevents race conditions when multiple replicas start simultaneously and ensures a bad migration fails fast without taking down the app on boot.

Adding a new module requires no changes to the workflow — the script picks it up automatically.

To add the required secret:
1. Go to repo Settings → Secrets and variables → Actions
2. Add `DB_CONNECTION_STRING` with the full PostgreSQL connection string for the environment

## Why `--startup-project backend/Dostar.Api`?

`Dostar.Api` holds `Microsoft.EntityFrameworkCore.Design` and is the application host, so the `dotnet ef` tool uses it to instantiate the `DbContext` at design time. The `--project` flag tells it where to write the migration files.
