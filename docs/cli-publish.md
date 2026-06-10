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

# 3. Open, init git, start building
cd MyStartup
git init && git add . && git commit -m "Initial commit"
dotnet build
cd frontend && pnpm install && pnpm dev
```

Prerequisites: [.NET 10 SDK](https://dot.net) and [Git](https://git-scm.com) must be on PATH. `pnpm` is required for the frontend; install it via `npm install -g pnpm` or `corepack enable`.

---

## How `dostar new-project` works

1. Clones `https://github.com/piers-sinclair/Dostar.git` into the output directory.
2. Strips the `.git` history so the user's repo starts clean.
3. Renames all `Dostar` / `dostar` tokens to the chosen project name (files, directories, and file contents).

The template is always sourced from `main`, so users always get the latest version without a CLI update.

---

## Publishing a new CLI release (maintainer steps)

Releases are published to [NuGet.org](https://www.nuget.org/packages/Dostar.Cli) automatically when a version tag is pushed to [piers-sinclair/Dostar.Cli](https://github.com/piers-sinclair/Dostar.Cli).

### Step-by-step

1. **Bump the version** in `Dostar.Cli.csproj`:
   ```xml
   <Version>0.2.0</Version>
   ```

2. **Commit** the version bump:
   ```bash
   git add Dostar.Cli.csproj
   git commit -m "chore: bump version to 0.2.0"
   git push
   ```

3. **Tag the release** — the tag name must match the version:
   ```bash
   git tag v0.2.0
   git push origin v0.2.0
   ```

4. The `Release` GitHub Actions workflow in `Dostar.Cli` triggers automatically, packs the tool, and pushes the `.nupkg` to NuGet.

5. The package appears on NuGet within a few minutes. NuGet may take up to 30 minutes to index it and make it searchable.

### Prerequisites for the workflow

The `NUGET_API_KEY` secret must be set in the `piers-sinclair/Dostar.Cli` GitHub repository settings:
- Go to **Settings → Secrets and variables → Actions → New repository secret**
- Name: `NUGET_API_KEY`
- Value: an API key from [NuGet.org](https://www.nuget.org) with **Push new packages and package versions** scope for `Dostar.Cli`

---

## Versioning strategy

- The CLI (`Dostar.Cli`) and the template (`Dostar`) are versioned **independently**.
- Template changes (new features, bug fixes) do not require a CLI release — users always clone `main`.
- CLI releases are needed only when the CLI code itself changes (new commands, bug fixes, flag changes).
- Use [semver](https://semver.org): `MAJOR.MINOR.PATCH`.

---

## Checking the published package

```bash
# Search NuGet for the latest version
dotnet tool search Dostar.Cli

# Install a specific version
dotnet tool install -g Dostar.Cli --version 0.2.0

# Update to the latest published version
dotnet tool update -g Dostar.Cli
```
