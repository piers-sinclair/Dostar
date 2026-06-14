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
feat(orders): add status field to Order model
fix(ci): correct SWA deployment token lookup
docs: update README with architecture diagram
ci: add release-please workflow
```

## Pre-commit hooks

Dostar uses [lefthook](https://github.com/evilmartians/lefthook) to run format and lint checks before every commit, catching CI failures before they reach the server.

Hooks are installed automatically when the devcontainer is created (`postCreate.sh` runs `pnpm install` and symlinks lefthook to `/usr/local/bin`). If you're working outside the devcontainer, install once:

```bash
cd frontend && pnpm install      # installs hooks
npm install -g lefthook          # makes lefthook findable by git hooks
```

| Hook | Command | Runs when |
|------|---------|-----------|
| Backend format | `dotnet format --verify-no-changes` | Any `backend/**/*.cs` file is staged |
| Frontend lint | `pnpm --dir frontend lint` | Any `frontend/**/*.{ts,tsx,js,jsx}` file is staged |
| Frontend format | `pnpm --dir frontend format:check` | Any `frontend/**` file is staged |

To skip hooks in an emergency (e.g. a WIP commit):

```bash
git commit --no-verify -m "wip: ..."
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

## Adding dependencies

Use the `/add-package` Claude Code skill — it validates the licence before installing.

**Acceptable licences:** MIT, Apache 2.0, BSD-2, BSD-3, ISC  
**Avoid:** GPL, LGPL, AGPL, SSPL, BSL, or any licence restricting commercial or proprietary use.

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

## Cross-repo secrets

### `CLI_COMPAT_PAT` — CLI compatibility CI

`ci-cli-compat.yml` fires a `repository_dispatch` event to [piers-sinclair/Dostar.Cli](https://github.com/piers-sinclair/Dostar.Cli) on every push to `main`. This triggers an end-to-end test in the CLI repo that scaffolds a project from the latest template and verifies it builds and passes tests.

The dispatch requires a token with write access to Dostar.Cli. To set this up:

1. Go to [GitHub → Settings → Developer settings → Fine-grained personal access tokens](https://github.com/settings/personal-access-tokens/new).
2. Set **Resource owner** to the account that owns `Dostar.Cli` (`piers-sinclair`).
3. Set **Repository access** to `piers-sinclair/Dostar.Cli` only.
4. Under **Permissions → Repository permissions**, set **Contents** to **Read and write** (this is the minimum scope needed to trigger `repository_dispatch`).
5. Generate the token and copy it.
6. In this repo ([piers-sinclair/Dostar](https://github.com/piers-sinclair/Dostar)), go to **Settings → Secrets and variables → Actions** and add a new repository secret named **`CLI_COMPAT_PAT`** with the token value.

The `client_payload` sent with the dispatch includes the triggering commit SHA and repo name so the CLI workflow can post a commit status back to this repo.

## Questions?

Open a [GitHub issue](https://github.com/piers-sinclair/Dostar/issues) or start a discussion.
