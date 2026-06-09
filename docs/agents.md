# Claude Code Skills

Dostar ships with a set of Claude Code skills — slash commands that guide Claude through common scaffolding and audit tasks so you don't have to remember the exact commands or conventions.

## Available skills

| Skill | File | What it does |
|-------|------|-------------|
| `/scaffold-module` | `.claude/commands/scaffold-module.md` | Scaffold a full feature module (Contracts + Implementation + UnitTests + IntegrationTests) |
| `/add-migration` | `.claude/commands/add-migration.md` | Add an EF Core migration for a module with the correct `--project` and `--startup-project` flags |
| `/add-package` | `.claude/commands/add-package.md` | Add a NuGet or npm package after validating its licence |
| `/code-quality` | `.claude/commands/code-quality.md` | Audit code quality (SOLID, DRY, nullability, async, naming) |
| `/audit-azure-costs` | `.claude/commands/audit-azure-costs.md` | Audit Azure infrastructure and CI/CD workflows for startup cost optimisation |
| `/integration-tests` | `.claude/commands/integration-tests.md` | Add integration tests for a module endpoint (WebApplicationFactory + Testcontainers) |
| `/playwright` | `.claude/commands/playwright.md` | Write a Playwright TypeScript UI test for a user journey |

## How to use a skill

Open Claude Code and type the skill name followed by any arguments:

```
/scaffold-module Products — stores name, SKU, and price; supports CRUD
/add-package backend Npgsql.EntityFrameworkCore.PostgreSQL
/add-migration Todos AddDueDateToTodo
/integration-tests Todos CreateTodo endpoint
/playwright user can create a todo and see it in the list
```

Claude reads the skill file and follows its instructions step by step, using `$ARGUMENTS` as the user-provided input.

## Example usage

### Scaffold a new module

```
/scaffold-module Orders — order header with line items; status transitions (pending → confirmed → shipped)
```

Claude will:
1. Create `Dostar.Orders.Contracts`, `.Implementation`, `.UnitTests`, `.IntegrationTests` projects
2. Add them to `Dostar.slnx`
3. Wire up the EF Core DbContext and register the module in `Program.cs`
4. Scaffold endpoints, handlers, validators, and tests
5. Run `dotnet build` to confirm 0 warnings

### Add a package with licence check

```
/add-package backend MediatR
```

Claude will fetch the MediatR licence from NuGet, confirm it's MIT, then run `dotnet add` for the correct project.

### Write a UI test

```
/playwright user marks a todo as complete
```

Claude will create `tests/todos.spec.ts` using Playwright's semantic locators, run it, and fix any failures.

## How skills work

Skills are Markdown files in `.claude/commands/`. When you type `/skill-name`, Claude Code:

1. Finds the matching file (e.g. `.claude/commands/scaffold-module.md`)
2. Injects its content as instructions into the Claude context
3. Replaces `$ARGUMENTS` with whatever you typed after the skill name
4. Executes the steps described in the file

The skill file is the single source of truth for what Claude does — it's version-controlled alongside the code.

## Writing a new skill

1. Create a `.md` file in `.claude/commands/` with a descriptive name
2. Add frontmatter if needed (optional — the filename is the command name)
3. Write numbered steps explaining exactly what Claude should do
4. Use `$ARGUMENTS` where the user's input should be substituted
5. Update the skills table in both `CLAUDE.md` and this file

**Example skill structure:**

```markdown
# my-skill

Short description of what this skill does.

## Steps

1. **Read** the relevant file to understand current state.
2. **Implement** the change based on $ARGUMENTS.
3. **Verify** by running the appropriate build or test command.
4. **Report** what was created or changed.
```

## Troubleshooting

**Skill not found** — check the filename matches exactly (case-sensitive on Linux).  
**Skill does the wrong thing** — the skill file is the instruction; edit it to change behaviour.  
**Want to override a step** — just type additional instructions after the skill name, e.g.:
```
/scaffold-module Products — skip integration tests for now
```
