# Developer guide

## Stack

| Layer | Technology |
|-------|-----------|
| Backend | .NET 10 Minimal APIs, modular monolith |
| Frontend | React + Vite + TypeScript |
| Package manager (frontend) | **pnpm** — never npm or yarn |
| Database | PostgreSQL via EF Core (Azure Flexible Server in prod) |
| IaC | Bicep |
| Compute | Azure App Service (backend) + Azure Static Web Apps (frontend) |
| CLI tool | `dostar` — .NET global tool ([piers-sinclair/Dostar.Cli](https://github.com/piers-sinclair/Dostar.Cli)) |
| Auth | None in template |
| Test assertions | **Shouldly** |
| Validation | **FluentValidation** |

## Repo structure

```
backend/                ← all .NET projects (not src/ — decoupling is explicit)
  Dostar.Api/           ← host/entry-point only; no business logic
  Dostar.SharedKernel/  ← IModule + IEndpointModule interfaces, framework-level shared types
  Modules/              ← one module per business feature or infrastructure concern
    Todos/
      Dostar.Todos.Contracts/           ← public API: interfaces + models (no implementation)
      Dostar.Todos.Implementation/      ← implementation: DbContext, handlers, IModule impl
      Dostar.Todos.UnitTests/           ← unit tests (in-memory EF Core, NSubstitute)
      Dostar.Todos.IntegrationTests/    ← integration tests (WebApplicationFactory + Testcontainers)
frontend/               ← React + Vite; standalone, separate toolchain
tests/                  ← cross-cutting tests only (UI tests, multi-module)
infra/                  ← Bicep templates
.claude/
  commands/             ← Claude Code skills (scaffold-module, playwright, etc.)
Dostar.slnx             ← .NET solution at repo root
```

## Running locally

See [README.md](../README.md) for prerequisites and the initial setup steps (database, migrations).

```bash
# Backend — from repo root
dotnet run --project backend/Dostar.Api --launch-profile http
# → http://localhost:5000/healthz/live   (health check)
# → http://localhost:5000/scalar/v1      (API docs)

# Frontend — from repo root
cd frontend && pnpm dev
# → http://localhost:5173

# Frontend build / lint / format
cd frontend && pnpm build
cd frontend && pnpm lint
cd frontend && pnpm format
```

**VS Code**: press `F5` — builds and starts `Dostar.Api`, auto-opens Scalar.

### CORS

| Policy | Used when | Allowed origins |
|--------|-----------|-----------------|
| `DevelopmentCors` | `IsDevelopment()` is true | `http://localhost:5173` (hardcoded) |
| `ProductionCors` | all other environments | `Cors:AllowedOrigins` array from `appsettings.json` |

`appsettings.Development.json` pre-populates `Cors:AllowedOrigins` with `http://localhost:5173` so `pnpm dev` works out of the box.
In production, set `Cors:AllowedOrigins` to your Azure Static Web App hostname (or via env var `Cors__AllowedOrigins__0`).

## Running tests

```bash
# Unit tests (per module)
dotnet test backend/Modules/<Module>/Dostar.<Module>.UnitTests

# Integration tests (per module — requires Docker)
dotnet test backend/Modules/<Module>/Dostar.<Module>.IntegrationTests

# UI tests (Playwright)
cd tests && pnpm exec playwright test
```

See [CONTRIBUTING.md](../CONTRIBUTING.md) for test conventions.

## CLI tool

```bash
dostar add-module <Name>     # scaffold a new module
dostar remove-module <Name>  # remove a module (with dry-run flag)
dostar new-project <name>    # clone + rename template
```

Source: [piers-sinclair/Dostar.Cli](https://github.com/piers-sinclair/Dostar.Cli)

## Milestones

55 issues across 9 milestones:

```
M1 (Foundation) → M2 (Modular Architecture) ─┬→ M3 (CLI)
                                               ├→ M4 (Testing)
                                               ├→ M5 (CI/CD) → M6 (Infra)
                                               └→ M9 (Frontend Patterns)
                                    M7 (AI Agents) and M8 (Docs) — any time after M2
```
