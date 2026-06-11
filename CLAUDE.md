# Dostar — Claude Code Context

> This file is loaded by Claude Code as AI context and instructions.
> For human setup and reference (running locally, testing, CLI, project structure) see [README.md](README.md).

Dostar is a startup template for fullstack .NET modular monolith + React/Vite.
Goal: a deployable, production-ready scaffold so new teams skip weeks of boilerplate.

---

## Stack

| Layer | Technology |
|-------|-----------|
| Backend | .NET 10 Minimal APIs, modular monolith |
| Frontend | React + Vite + TypeScript + **Tailwind v4** + **shadcn/ui** + **TanStack Query** + **orval** (generated API client) + **React Hook Form + Zod** |
| Package manager (frontend) | **pnpm** — never npm or yarn |
| Database | PostgreSQL via EF Core (Azure Flexible Server in prod) |
| IaC | Bicep |
| Compute | Azure Container Apps (backend) + Azure Static Web Apps (frontend) |
| CLI tool | `dostar` — .NET global tool in [piers-sinclair/Dostar.Cli](https://github.com/piers-sinclair/Dostar.Cli) |
| AI dev tooling | Claude Code skills in `.claude/commands/` |
| Auth | None in template |
| Test assertions | **Shouldly** — never FluentAssertions |
| Validation | **FluentValidation** via `ValidationFilter<T>` in SharedKernel |
| Observability | **Azure.Monitor.OpenTelemetry.AspNetCore** + **Npgsql.OpenTelemetry** — no-op locally when `APPLICATIONINSIGHTS_CONNECTION_STRING` is unset |

---

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
tests/                  ← cross-cutting tests only (UI tests, multi-module); currently empty
infra/                  ← Bicep templates
.claude/
  commands/             ← Claude Code skills (scaffold-module, playwright, etc.)
Dostar.slnx             ← .NET solution at repo root
CLAUDE.md               ← this file
```

---

## Claude Code skills

| Skill | File | Purpose |
|-------|------|---------|
| `/add-package` | `.claude/commands/add-package.md` | Add NuGet/npm package with licence check |
| `/scaffold-module` | `.claude/commands/scaffold-module.md` | Scaffold a full feature module (Contracts + Implementation + unit tests) |
| `/add-migration` | `.claude/commands/add-migration.md` | Add EF Core migration for a module with the correct flags |
| `/code-quality` | `.claude/commands/code-quality.md` | Audit code quality (SOLID, DRY, nullability, async, naming, etc.) |
| `/audit-azure-costs` | `.claude/commands/audit-azure-costs.md` | Audit Azure infra + CI/CD for startup cost optimisation |
| `/integration-tests` | `.claude/commands/integration-tests.md` | Add integration tests for a module endpoint |
| `/playwright` | `.claude/commands/playwright.md` | Write a Playwright UI test for a user journey |
| `/create-issue` | `.claude/commands/create-issue.md` | Create a GitHub issue with labels and milestone |

> Future (build after M9): `/scaffold-page`

---

## Key conventions

- **Folder names**: `backend/` and `frontend/` at root — not `src/` — to make the deployment boundary obvious.
- **No monorepo**: `frontend/` is a standalone Vite project. No root `package.json` or `pnpm-workspace.yaml`.
- **Backend HTTP port**: `5000` (the `http` launch profile in `launchSettings.json`).
- **API docs (dev)**: Scalar UI at `http://localhost:5000/scalar/v1`.
- **.NET projects**: always created via CLI (`dotnet new`, `dotnet sln add`), never by hand.
- **AI agents**: Claude Code skills in `.claude/commands/`, not a .NET project.
- **Global usings**: each project has a `GlobalUsings.cs` at its root declaring `global using` directives for namespaces used across multiple files in that project. Avoid repeating `using` statements inside individual files.

---

## Module pattern

Two interfaces live in `backend/Dostar.SharedKernel/IModule.cs`:

- **`IModule`** — all modules (service registration only)
- **`IEndpointModule : IModule`** — feature modules that expose HTTP endpoints

Modules are registered **explicitly** in `Program.cs` (no reflection/auto-discovery). Each module
consists of four projects: `<Name>.Contracts`, `<Name>.Implementation`, `<Name>.UnitTests`, and
`<Name>.IntegrationTests`. All four live together under `backend/Modules/<Name>/` so the entire
module can be extracted into a microservice as a unit.
Consuming modules reference only `.Contracts` — never `.Implementation`.

Each module owns its own `DbContext` and EF Core migrations. Modules communicate in-process via
Contracts interfaces — no HTTP between modules.

See `docs/module-pattern.md` for the full guide.

---

## Testing

See [README.md](README.md) for how to run tests.

Libraries: **xUnit** + **Shouldly** + **NSubstitute** (unit), **Testcontainers** (integration),
**Playwright TypeScript** (UI tests).

### Unit test conventions

**Project location**: `backend/Modules/<Module>/Dostar.<Module>.UnitTests/` — colocated with the module, referencing `.Implementation` directly. All four module projects travel together to support microservice extraction.

**Method naming**: `Method_Scenario_ExpectedBehaviour`
- `GetAllAsync_WhenEmpty_ReturnsEmptyList`
- `DeleteAsync_WhenNotFound_ReturnsFalse`

**Assertions**: always use **Shouldly** (`result.ShouldBe(...)`, `result.ShouldBeNull()`, etc.) — never `Assert.*` or FluentAssertions.

**Dependencies**:
- EF Core `DbContext` → use **Testcontainers PostgreSQL** (`Testcontainers.PostgreSql`). Declare a `PostgresContainerFixture : IAsyncLifetime` that starts the container and runs migrations once, shared across all tests via `IClassFixture<PostgresContainerFixture>`. Each test class also implements `IAsyncLifetime` — `InitializeAsync` opens a fresh `DbContext`, `DisposeAsync` deletes all rows and disposes the context so each test starts with an empty table.
- Other dependencies → use NSubstitute (`Substitute.For<T>()`).

Each test must be fully self-contained — no shared mutable state between tests.

---

## CLI tool

The `dostar` CLI lives in [piers-sinclair/Dostar.Cli](https://github.com/piers-sinclair/Dostar.Cli).

> **Cross-repo dependency:** Changes to this repo can require corresponding updates to Dostar.Cli. Examples:
> - New parameters added to `infra/main.bicep` or parameter files → CLI scaffolding may need to inject or placeholder those values
> - New files added to the template that contain project-name tokens → `ProjectService` token replacement may need updating. **Note:** the CLI should only replace Dostar references in project-specific files (`.csproj`, namespaces, solution files, etc.) — it must NOT replace references to the CLI tool itself (e.g. mentions of `dostar`, `Dostar.Cli`, or CLI usage instructions), since those remain valid in the scaffolded project.
> - New module structure conventions → `add-module` scaffolding templates may need updating
>
> When making such changes, open an issue on [piers-sinclair/Dostar.Cli](https://github.com/piers-sinclair/Dostar.Cli) if a CLI update is needed.

---

## Working on a GitHub issue

Every issue must be implemented on a dedicated feature branch and merged via a pull request. Never commit directly to `main`.

### Agentic AI workflow (Claude Code)

**All agentic work must use a git worktree.** Never check out a branch directly — this pollutes the main working tree and risks overwriting uncommitted user changes.

```bash
# 1. Create the branch and worktree together
git fetch origin
git worktree add .claude/worktrees/issue-<N> -b feat/issue-<N>-<short-description> origin/main

# 2. Work inside the worktree
cd .claude/worktrees/issue-<N>

# 3. Build, commit, push, open PR (same steps as below)

# 4. Clean up after the PR merges
git worktree remove .claude/worktrees/issue-<N>
git branch -d feat/issue-<N>-<short-description>
```

`.claude/worktrees/` is gitignored — worktrees never appear as untracked files in the main repo.

**Stale worktree cleanup** — before starting any new task, prune worktrees whose branches have already been merged or deleted:

```bash
git fetch --prune                 # remove stale remote-tracking refs
git worktree prune                # remove worktree metadata for deleted paths
# then manually remove any .claude/worktrees/<name> folders still present
```

### Branch & PR workflow

1. **Create a branch** from `main` named `feat/issue-<N>-<short-description>` (inside a worktree for agentic work — see above). Always run `git fetch origin` and base the branch on `origin/main` to avoid stale-base conflicts when opening the PR.
2. **Implement** the changes.
3. **Build** — must pass with 0 warnings before committing:
   ```bash
   dotnet build   # backend
   cd frontend && pnpm build   # frontend (if changed)
   az deployment sub what-if --location australiaeast --template-file infra/main.bicep --parameters infra/main.parameters.dev.bicepparam   # infra (if changed)
   ```
4. **Commit** with a message that references the issue (`Closes #N`).
5. **Check the PR is still open before pushing** — if resuming work on an existing branch, verify the PR has not already been merged:
   ```bash
   gh pr view <branch> --json state,url
   # If state is MERGED, create a new branch from origin/main instead of pushing to the old one
   ```
6. **Push** and open a PR targeting `main`:
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
Use the `/add-package` Claude skill — it fetches the licence, validates it, and only then installs.

---

## CI/CD pipeline

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `ci.yml` | push / PR | Build + test |
| `cd-backend.yml` | push to `main` (`backend/**`) | Deploy backend to **dev** |
| `cd-frontend.yml` | push to `main` (`frontend/**`) | Deploy frontend to **dev** |
| `infra-deploy.yml` | push to `main` (`infra/**`) | Deploy Bicep to **dev** |
| `release-please.yml` | push to `main` | Opens/updates Release PR; on merge calls `cd-release.yml` |
| `cd-release.yml` | `workflow_call` from release-please, or `workflow_dispatch` | Deploy backend + frontend to **prod** |

**Why `workflow_call` instead of `push: tags`:** GitHub does not trigger workflows from events
authored by `GITHUB_TOKEN`. Since release-please uses `GITHUB_TOKEN` to push the release tag,
a `push: tags` trigger on `cd-release.yml` would never fire. The fix is to chain `cd-release.yml`
directly from `release-please.yml` using its `release_created` output — no PAT or GitHub App
needed, and no extra setup for template consumers.

**Manual prod deploy:** Go to Actions → "CD — release to prod" → Run workflow.

---

## Keeping this file up to date

**Update `CLAUDE.md` whenever you:**
- Add a new module or change the module pattern
- Change a port, URL, or default environment setting
- Introduce a new library or swap an existing one
- Add a new Claude Code skill in `.claude/commands/`

**Update `README.md` whenever you:**
- Change how to run the app or tests locally
- Add or remove CLI commands
- Update the stack or repo structure

A reminder to do this is also in `CONTRIBUTING.md`.
