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
| Validation | **FluentValidation** via `ValidationFilter<T>` in SharedKernel |

---

## Repo structure

```
backend/                ← all .NET projects (not src/ — decoupling is explicit)
  Dostar.Api/           ← host/entry-point only; no business logic
  Dostar.SharedKernel/  ← IModule + IEndpointModule interfaces, framework-level shared types
  Modules/              ← one module per business feature or infrastructure concern
    Todos/
      Dostar.Todos.Contracts/        ← public API: interfaces + models (no implementation)
      Dostar.Todos.Implementation/   ← implementation: DbContext, handlers, IModule impl
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
- **Global usings**: each `.Implementation` project has a `GlobalUsings.cs` at its root declaring `global using` directives for namespaces used across multiple files in that project. Avoid repeating `using` statements inside individual files.

---

## Module pattern

Two interfaces live in `backend/Dostar.SharedKernel/IModule.cs`:

- **`IModule`** — all modules (service registration only)
- **`IEndpointModule : IModule`** — feature modules that expose HTTP endpoints

Modules are registered **explicitly** in `Program.cs` (no reflection/auto-discovery). Each module
consists of two projects: `<Name>.Contracts` (public interfaces + models) and `<Name>.Implementation`.
Consuming modules reference only `.Contracts` — never `.Implementation`.

Each module owns its own `DbContext` and EF Core migrations. Modules communicate in-process via
Contracts interfaces — no HTTP between modules.

See `docs/module-pattern.md` for the full guide.

---

## Running locally

```bash
# Backend — from repo root
dotnet run --project backend/Dostar.Api --launch-profile http
# → http://localhost:5000/healthz        (health check)
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
A compound launch config (backend + frontend together) is tracked separately.

---

## Testing

```bash
# Unit tests (per module)
dotnet test tests/Dostar.<Module>.Tests

# Integration tests (real PostgreSQL via Testcontainers)
dotnet test tests/Dostar.IntegrationTests

# E2E (Playwright)
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

---

## Working on a GitHub issue

Every issue must be implemented on a dedicated feature branch and merged via a pull request. Never commit directly to `main`.

### Branch & PR workflow

1. **Create a branch** from `main` named `feat/issue-<N>-<short-description>`
   ```bash
   git checkout main && git pull
   git checkout -b feat/issue-9-global-api-plumbing
   ```
2. **Implement** the changes.
3. **Build** — must pass with 0 warnings before committing:
   ```bash
   dotnet build   # backend
   cd frontend && pnpm build   # frontend (if changed)
   ```
4. **Commit** with a message that references the issue (`Closes #N`).
5. **Push** and open a PR targeting `main`:
   ```bash
   git push -u origin <branch>
   gh pr create --title "..." --body "..."
   ```

Only open the PR once the build and relevant tests pass locally.

---

## Licensing policy

All dependencies (NuGet, npm) must be **free for commercial use in closed-source projects**.
Acceptable licences: MIT, Apache 2.0, BSD-2, BSD-3, ISC, and equivalently permissive licences.
Avoid: GPL, LGPL, AGPL, SSPL, BSL, or any licence that restricts commercial or proprietary use.
Before adding a new package, confirm its licence meets this requirement.

---

## Keeping this file up to date

**Update `CLAUDE.md` whenever you:**
- Add a new module or change the module pattern
- Change a port, URL, or default environment setting
- Introduce a new library or swap an existing one
- Add a new `dostar` CLI command
- Add a new Claude Code skill in `.claude/commands/`

A reminder to do this is also in `CONTRIBUTING.md`.
