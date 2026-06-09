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

Releases are automated via release-please:

1. Merge `feat:` or `fix:` commits to `main`
2. release-please opens a versioned release PR with an updated `CHANGELOG.md`
3. Merging the release PR creates a GitHub Release with a version tag

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
