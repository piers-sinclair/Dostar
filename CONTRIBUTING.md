# Contributing to Dostar

## Getting started

See [README.md](README.md) for stack, repo structure, prerequisites, and local setup.
See [CLAUDE.md](CLAUDE.md) for coding conventions (this file is also loaded as Claude Code AI context).

## Development workflow

- Work on a feature branch named `feat/issue-N-short-description`
- Never commit directly to `main`
- Open a PR for every change, referencing the issue: `Closes #N`

## Commit messages

Dostar uses [Conventional Commits](https://www.conventionalcommits.org/). This feeds into automated changelog generation via release-please.

**Format:** `<type>(<scope>): <description>`

| Type | When to use |
|------|-------------|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `refactor` | Code change that is not a fix or feature |
| `test` | Adding or updating tests |
| `ci` | CI/CD workflow changes |
| `chore` | Maintenance (deps, tooling) |

**Examples:**
```
feat(todos): add priority field to Todo model
fix(ci): correct SWA deployment token lookup
docs: update README with architecture diagram
ci: add release-please workflow
```

## Running checks locally

CI enforces these on every PR, but running them locally before pushing saves a round-trip:

```bash
# Backend (if changed)
dotnet build   # must produce 0 warnings

# Frontend (if changed)
cd frontend && pnpm build   # must produce 0 TypeScript errors

# Infra (if changed)
az deployment sub what-if \
  --location australiaeast \
  --template-file infra/main.bicep \
  --parameters infra/main.parameters.dev.bicepparam
```

## Testing

```bash
# Unit tests (per module)
dotnet test backend/Modules/<Module>/Dostar.<Module>.UnitTests

# Integration tests (per module — requires Docker)
dotnet test backend/Modules/<Module>/Dostar.<Module>.IntegrationTests

# UI tests (Playwright)
cd tests && pnpm exec playwright test
```

Use **Shouldly** for all assertions — never `Assert.*` or FluentAssertions.

## Adding dependencies

Use the `/add-package` Claude Code skill — it validates the licence before installing.

**Acceptable licences:** MIT, Apache 2.0, BSD-2, BSD-3, ISC  
**Avoid:** GPL, LGPL, AGPL, SSPL, BSL, or any licence restricting commercial or proprietary use.

## Claude Code skills

Skills in `.claude/commands/` are slash commands for common scaffolding tasks:

| Skill | Purpose |
|-------|---------|
| `/scaffold-module` | Create a full feature module (4 projects) |
| `/add-migration` | Add an EF Core migration for a module |
| `/add-package` | Add a NuGet or npm package (with licence check) |
| `/code-quality` | Audit code quality |
| `/audit-azure-costs` | Audit Azure infrastructure costs |
| `/integration-tests` | Add integration tests for a module endpoint |
| `/playwright` | Write a Playwright UI test |


## Dependabot

Dependabot is configured in [.github/dependabot.yml](.github/dependabot.yml) to open weekly PRs for:

| Ecosystem | Grouping |
|-----------|----------|
| NuGet | Minor + patch in one PR; major updates separate |
| npm (pnpm) | Minor + patch in one PR; major updates separate |
| GitHub Actions | All updates in one PR |

Do not merge Dependabot PRs until CI passes.

## Release process

Releases are automated via [release-please](https://github.com/googleapis/release-please). Understanding the two-phase flow is important — **dev and prod deploy on different triggers.**

### Phase 1 — continuous dev deploys (automatic)

Every merge to `main` auto-deploys to dev if the relevant paths changed:

| Changed paths | Workflow triggered |
|---|---|
| `backend/**`, `Dockerfile` | `cd-backend.yml` → migrate + deploy to dev |
| `frontend/**` | `cd-frontend.yml` → build + deploy to dev |
| `infra/**` | `infra-deploy.yml` → Bicep deploy to dev |

### Phase 2 — prod release (deliberate)

release-please runs on every push to `main` and manages a single cumulative Release PR:

1. **Commits land on `main`** using conventional commit format (see above).
2. **release-please opens or updates one Release PR** titled `chore(main): release X.Y.Z` containing:
   - An updated `CHANGELOG.md` with all visible unreleased changes grouped by type
   - A version bump in `.release-please-manifest.json`
   - **Note:** only commits since the last `v*` tag are included. The PR updates itself as more commits land — there is only ever one open Release PR.
3. **Review the Release PR** when the team is ready to ship. The CHANGELOG diff shows exactly what's going out.
4. **Merge the Release PR** → release-please creates a GitHub Release and a `vX.Y.Z` tag.
5. **The tag triggers `cd-release.yml`** → deploys backend then frontend to prod.

```
main merge (feat:/fix:)
  │
  ├── cd-backend.yml ──────────────────────────────► dev Container App
  ├── cd-frontend.yml ─────────────────────────────► dev Static Web App
  │
  └── release-please.yml ──► opens/updates Release PR
                                       │
                             team merges when ready
                                       │
                                  v* tag created
                                       │
                             cd-release.yml ─────────► prod Container App
                                                        prod Static Web App
```

### Version bumping rules

| Commit type | Version bump |
|---|---|
| `fix:` | Patch (0.1.0 → 0.1.1) |
| `feat:` | Minor (0.1.0 → 0.2.0) |
| `feat!:` or `BREAKING CHANGE:` in body | Major (0.1.0 → 1.0.0) |
| `chore:`, `ci:`, `refactor:`, `test:` | No bump — hidden from changelog |

### What the Release PR touches

The Release PR only modifies `CHANGELOG.md` and `.release-please-manifest.json`. Neither file matches the path filters on the dev deploy workflows, so merging a Release PR **never** triggers a spurious dev redeploy.

## Keeping docs up to date

Update `CLAUDE.md` whenever you:
- Add a new module or change the module pattern
- Change a port, URL, or default environment setting
- Introduce a new library or swap an existing one
- Add a new Claude Code skill

Update `README.md` whenever you:
- Change how to run the app or tests locally
- Add or remove CLI commands
- Update the stack or repo structure

## Questions?

Open a [GitHub issue](https://github.com/piers-sinclair/Dostar/issues) or start a discussion.
