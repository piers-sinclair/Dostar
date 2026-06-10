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

The PostgreSQL Flexible Server uses private-only VNet access — no public endpoint exists. Migrations must therefore run from inside the VNet, not from a GitHub-hosted runner.

In production, the `migrate` job in `cd-backend.yml`:

1. Builds a `migrator` Docker image (the `migrator` target in the Dockerfile — SDK image with `dotnet-ef` and `tools/run-migrations.sh` as the entrypoint)
2. Pushes it to ACR using a short-lived ACR token (`az acr login --expose-token`)
3. Constructs the PostgreSQL connection string from Bicep deployment outputs + `AZURE_POSTGRES_ADMIN_PASSWORD`
4. Creates a Container Apps Job (`ca-migrate`) inside the existing VNet-integrated Container Apps Environment (`cae-dostar-dev-aue-001`), which can reach the private database
5. Starts the job, polls until `Succeeded`, then deletes the job
6. The job runs `run-migrations.sh`, which auto-discovers every module with a `Migrations/` directory and calls `dotnet ef database update`

The `deploy` job has `needs: migrate` — the app only starts after migrations succeed.

Adding a new module requires no changes to the workflow — the script picks it up automatically.

No extra secret is required beyond the existing `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`, and `AZURE_POSTGRES_ADMIN_PASSWORD` secrets.

## Why `--startup-project backend/Dostar.Api`?

`Dostar.Api` holds `Microsoft.EntityFrameworkCore.Design` and is the application host, so the `dotnet ef` tool uses it to instantiate the `DbContext` at design time. The `--project` flag tells it where to write the migration files.
