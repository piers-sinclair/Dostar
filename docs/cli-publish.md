# CLI Packaging and Publishing

## Distribution model

| Artifact | How it's distributed |
|----------|---------------------|
| `dostar` CLI | NuGet global tool — `dotnet tool install -g Dostar.Cli` |
| Dostar template | Cloned directly from `main` at scaffold time |

**No npm package.** `dostar` is a .NET global tool, not a Node tool.

**No separate template package.** `dostar new-project` clones the latest `main` branch of this repo. This keeps the template up to date automatically — no template package to version or publish separately.

---

## User install path (zero to running project)

```bash
# 1. Install the CLI once
dotnet tool install -g Dostar.Cli

# 2. Scaffold a new project
dostar new-project MyStartup

# 3. Init git and start building
cd MyStartup
git init && git add . && git commit -m "Initial commit"
dotnet build
cd frontend && pnpm install && pnpm dev
```

Prerequisites: [.NET 10 SDK](https://dot.net) and [Git](https://git-scm.com) must be on PATH.
`pnpm` is required for the frontend — install via `npm install -g pnpm` or `corepack enable`.

---

## How `dostar new-project` works

1. Clones `https://github.com/piers-sinclair/Dostar.git` into the output directory.
2. Strips the `.git` history so the user's repo starts fresh.
3. Renames every `Dostar` / `dostar` token to the chosen project name (files, directories, and file contents).

The template is always sourced from `main`, so users always get the latest version without needing to update the CLI.

---

## Release pipeline

The CLI uses the same release-please model as the Dostar template repo itself.
**No manual version bumps, no manual git tags.**

```
conventional commits land on main in piers-sinclair/Dostar.Cli
          │
          ▼
release-please opens a "chore(main): release X.Y.Z" PR
  • bumps <Version> in Dostar.Cli.csproj
  • updates CHANGELOG.md
          │
          ▼  (maintainer merges the Release PR)
          │
          ▼
GitHub Release + git tag created (e.g. v0.2.0)
          │
          ▼
nuget-publish.yml fires → packs Dostar.Cli.csproj → pushes to NuGet.org
```

The two workflows involved:

| Workflow | File | Trigger | What it does |
|----------|------|---------|--------------|
| Release Please | `release-please.yml` | push to `main` | opens/updates the Release PR; on merge creates the GitHub Release + tag |
| NuGet Publish | `nuget-publish.yml` | `release.published` event | packs + pushes the `.nupkg` to NuGet.org |

---

## Publishing a new CLI version (maintainer steps)

1. **Write commits** using [Conventional Commits](https://www.conventionalcommits.org):

   | Prefix | Semver bump | Example |
   |--------|-------------|---------|
   | `fix:` | patch | `fix: handle empty project name` |
   | `feat:` | minor | `feat: add remove-module command` |
   | `feat!:` or `BREAKING CHANGE:` | major | `feat!: rename new-project flags` |
   | `chore:`, `ci:`, `refactor:`, `test:` | none | hidden from changelog |

2. **Merge commits to `main`** — release-please opens or updates a "chore(main): release X.Y.Z" PR automatically.

3. **Merge the Release PR** — release-please creates the GitHub Release and git tag.

4. **Done** — `nuget-publish.yml` fires and the new version appears on NuGet within a few minutes (up to 30 minutes to become searchable).

---

## One-time setup (first publish)

The `NUGET_API_KEY` secret must be set in `piers-sinclair/Dostar.Cli`:
- **Settings → Secrets and variables → Actions → New repository secret**
- Name: `NUGET_API_KEY`
- Value: a NuGet.org API key with **Push new packages and package versions** scope for `Dostar.Cli`

---

## Versioning strategy

The CLI (`Dostar.Cli`) and the template (`Dostar`) are versioned **independently**:

- Template changes (new features, bug fixes, infra changes) **do not** require a CLI release — users always clone `main`.
- CLI releases are only needed when the CLI code itself changes (new commands, bug fixes, flag changes).
- Both repos use the same release-please model and [semver](https://semver.org) (`MAJOR.MINOR.PATCH`).

---

## Checking the published package

```bash
# Search NuGet for the latest version
dotnet tool search Dostar.Cli

# Update an existing install to the latest published version
dotnet tool update -g Dostar.Cli

# Install a specific version
dotnet tool install -g Dostar.Cli --version 0.2.0
```
