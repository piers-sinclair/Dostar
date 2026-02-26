# Contributing to Dostar

## Getting started

See [CLAUDE.md](CLAUDE.md) for the full stack, repo structure, running the project locally, and testing instructions.

## Coding conventions

Conventions are documented in [CLAUDE.md](CLAUDE.md). Key points:

- Frontend package manager: **pnpm** — never npm or yarn
- Test assertions: **Shouldly** — never FluentAssertions
- .NET projects: always created via `dotnet new` / `dotnet sln add`, never by hand
- Update `CLAUDE.md` when you change ports, libraries, the module pattern, or add CLI commands

## Dependabot

Dependabot is configured in [.github/dependabot.yml](.github/dependabot.yml) to open weekly PRs for:

| Ecosystem | Grouping |
|-----------|----------|
| NuGet | Minor + patch in one PR; major updates separate |
| npm (pnpm) | Minor + patch in one PR; major updates separate |
| GitHub Actions | All updates in one PR |

**Do not manually merge Dependabot PRs until CI passes.** The CI workflow is the gate — if checks are red, investigate before merging.
