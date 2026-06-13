---
description: Add an EF Core migration for a Dostar module using the correct project and startup-project flags.
argument-hint: <MigrationName> [--module <Name>]
allowed-tools: Bash(dotnet *) Read Glob
---

# add-migration

Add an EF Core migration for a Dostar module using the correct flags for this project's structure.

## Usage

```
/add-migration <MigrationName> [--module <ModuleName>]
```

- `<MigrationName>` — descriptive name in PascalCase (e.g. `InitialCreate`, `AddInvoiceStatus`)
- `--module` — the PascalCase module name (e.g. `Todos`). If omitted, ask the user to specify.

## What this skill does

1. **Resolve the module name** — if `--module` was not provided, list the directories under
   `backend/Modules/` and ask the user which module to migrate.

2. **Run the migration command:**
   ```bash
   dotnet ef migrations add <MigrationName> \
     --project backend/Modules/<ModuleName>/Dostar.<ModuleName>.Implementation \
     --startup-project backend/Dostar.Api \
     --context <ModuleName>DbContext
   ```

3. **Confirm success** — show the user the generated migration file path(s) under
   `backend/Modules/<ModuleName>/Dostar.<ModuleName>.Implementation/Migrations/`.

## Applying migrations

To apply the migration to your local database (requires the connection string in
`appsettings.Development.json` to point to a running PostgreSQL instance):

```bash
dotnet ef database update \
  --project backend/Modules/<ModuleName>/Dostar.<ModuleName>.Implementation \
  --startup-project backend/Dostar.Api \
  --context <ModuleName>DbContext
```

## Removing the last migration (before it's applied)

```bash
dotnet ef migrations remove \
  --project backend/Modules/<ModuleName>/Dostar.<ModuleName>.Implementation \
  --startup-project backend/Dostar.Api \
  --context <ModuleName>DbContext
```

## Notes

- `--startup-project backend/Dostar.Api` is always required — `Dostar.Api` holds
  `Microsoft.EntityFrameworkCore.Design` and is the application host used to instantiate
  the `DbContext` at design time.
- Migration files are written into the `.Implementation` project under `Infrastructure/Migrations/`.
- See `docs/migrations.md` for the full migration guide.
