# Dostar — Claude Code Context

Dostar is a startup template for fullstack .NET modular monolith + React/Vite.
Goal: a deployable, production-ready scaffold so new teams skip weeks of boilerplate.

---

## Stack

| Layer | Technology |
|-------|-----------|
| Backend | .NET 10 Minimal APIs, modular monolith |
| Frontend | React + Vite + TypeScript |
| Package manager (frontend) | **pnpm** — never npm or yarn |
| Database | PostgreSQL via EF Core (Azure Flexible Server in prod) |
| IaC | Bicep |
| Compute | Azure App Service (backend) + Azure Static Web Apps (frontend) |
| CLI tool | `dostar` — .NET global tool using System.CommandLine |
| AI dev tooling | Claude Code skills in `.claude/commands/` |
| Auth | None in template |
| Test assertions | **Shouldly** — never FluentAssertions |

---

## Repo structure

```
backend/                ← all .NET projects (not src/ — decoupling is explicit)
  Dostar.Api/           ← host/entry-point only; no business logic
  Dostar.Shared/        ← IModule interface, shared types (future)
  Modules/              ← one project per business module (future)
    Todos/
      Dostar.Todos/
frontend/               ← React + Vite; standalone, separate toolchain
tests/                  ← test projects (unit + integration + E2E)
tools/                  ← dostar CLI source
infra/                  ← Bicep templates
.claude/
  commands/             ← Claude Code skills (scaffold-module, playwright, etc.)
Dostar.slnx             ← .NET solution at repo root
CLAUDE.md               ← this file
```

---

## Key conventions

- **Folder names**: `backend/` and `frontend/` at root — not `src/` — to make the deployment boundary obvious.
- **No monorepo**: `frontend/` is a standalone Vite project. No root `package.json` or `pnpm-workspace.yaml`.
- **Backend HTTP port**: `5000` (the `http` launch profile in `launchSettings.json`).
- **API docs (dev)**: Scalar UI at `http://localhost:5000/scalar/v1`.
- **.NET projects**: always created via CLI (`dotnet new`, `dotnet sln add`), never by hand.
- **AI agents**: Claude Code skills in `.claude/commands/`, not a .NET project.

---

## Module pattern

Each feature module implements `IModule` with two methods:

```csharp
public interface IModule
{
    void RegisterServices(IServiceCollection services, IConfiguration config);
    void MapEndpoints(IEndpointRouteBuilder app);
}
```

`Program.cs` discovers and registers all modules at startup. Each module owns its own
`DbContext` and EF Core migrations. Modules communicate in-process via shared interfaces —
no HTTP between modules.

> The pattern is scaffolded once implemented in M2. Update this section then.

---

## Running locally

```bash
# Backend — from repo root
dotnet run --project backend/Dostar.Api --launch-profile http
# → http://localhost:5000/healthz        (health check)
# → http://localhost:5000/scalar/v1      (API docs)

# Frontend — once scaffolded (issue #3)
cd frontend && pnpm dev
# → http://localhost:5173
```

**VS Code**: press `F5` — builds and starts `Dostar.Api`, auto-opens Scalar.
A compound launch config (backend + frontend together) will be added in issue #3.

---

## Testing

```bash
# Unit tests (per module)
dotnet test tests/Dostar.<Module>.Tests

# Integration tests (real PostgreSQL via Testcontainers)
dotnet test tests/Dostar.IntegrationTests

# E2E (Playwright — once frontend exists)
cd tests && pnpm exec playwright test
```

Libraries: **xUnit** + **Shouldly** + **NSubstitute** (unit), **Testcontainers** (integration),
**Playwright TypeScript** (E2E).

---

## CLI tool

```bash
dostar add-module <Name>     # scaffold a new module
dostar remove-module <Name>  # remove a module (with dry-run flag)
dostar new-project <name>    # clone + rename template
```

Source lives in `tools/Dostar.Cli/`.

---

## GitHub issues & milestones

55 issues across 9 milestones. Sequencing:

```
M1 (Foundation) → M2 (Modular Architecture) ─┬→ M3 (CLI)
                                               ├→ M4 (Testing)
                                               ├→ M5 (CI/CD) → M6 (Infra)
                                               └→ M9 (Frontend Patterns)
                                    M7 (AI Agents) and M8 (Docs) — any time after M2
```
