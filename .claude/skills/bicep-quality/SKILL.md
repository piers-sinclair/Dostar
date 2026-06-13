---
description: Audit Bicep files for naming, structure, and Azure best practices, then report all findings before making any changes.
argument-hint: [path]
allowed-tools: Bash(az bicep *) Bash(git *) Read Glob Grep
---

# bicep-quality

Audit Bicep files for quality issues across naming, structure, and Azure best practices, then report findings before making any changes.

## Usage

```
/bicep-quality [path]
```

- No argument → audits all `.bicep` files changed on the current branch (`git diff main...HEAD --name-only | grep '\.bicep$'`)
- Path given → audits all `.bicep` files under that path recursively

## Workflow

1. **Determine scope**: resolve the file list (diff or path)
2. **Read every file** in scope
3. **Audit** each file against every category below
4. **Report** all findings grouped by category, with severity, file reference, what was found, and a suggested fix
5. **Ask the user** which findings (if any) they want applied — do not touch any file until they confirm

## Severity levels

| Level | Meaning |
|-------|---------|
| `Error` | Clear, unambiguous violation — fix unconditionally (e.g. magic string repeated 2+ times, file over 100 lines) |
| `Warning` | Probable violation that needs context to confirm (e.g. SRP smell, vague module name) |
| `Info` | Improvement opportunity — naming suggestion, minor clarity improvement |

## Reporting format

For each finding, output:

```
[<Severity>] <Category> — <file>:<line or range>
  Found: <what was found>
  Fix:   <suggested change>
```

Group findings by category. At the end, print a summary table:

| Category | Error | Warning | Info |
|----------|-------|---------|------|
| ...      | N     | N       | N    |

Then ask: **"Which findings would you like me to fix? List numbers, 'all', or 'none'."**

---

## Audit categories

### 1. Module size and single responsibility

Each module file should represent one cohesive infrastructure concern.

Flag:
- Any `.bicep` file (excluding `main.bicep`) that exceeds ~100 lines — treat this as a sign the module is doing too much
- A file with logical sections separated by comments (section headers) — each section is a candidate for extraction into its own module
- `main.bicep` containing inline resource definitions — it should contain only module calls and top-level parameter/variable declarations

Expected fix: extract cohesive sections into named sub-modules, making the parent file a thin orchestrator.

### 2. Naming consistency

Flag:
- Parameters not using `camelCase`
- Variables not using `camelCase`
- Resource symbolic names not using `camelCase`
- Outputs not using `camelCase`
- Module names in `module` declarations not using `camelCase`
- Abbreviations (`mgr`, `svc`, `tmp`) in names — prefer full words
- Generic names (`data`, `result`, `item`, `value`) where a specific name exists
- Inconsistent naming patterns across files (e.g. some files use `Name` suffix on vars, others do not)

### 3. Hardcoded values

Flag any literal that:
- Has configuration or domain meaning and appears more than once across all audited files
- Should vary between environments (`dev`/`prod`) but is hardcoded
- Represents a platform-specific limit or quota that could change (e.g. max name lengths)

Expected fix: extract to a `var`, or promote to a `param` with a sensible default.

### 4. Duplicate expressions

Flag:
- The same string interpolation expression (e.g. `'${workload}-${env}-${region}-${instance}'`) duplicated in multiple resources within a file — extract to a `var`
- The same naming formula duplicated across module files — this is acceptable if it avoids cross-module coupling, but flag it as `Info` so the reviewer can decide
- The same conditional expression (`env == 'prod' ? x : y`) repeated more than once in the same file — extract to a `var`

### 5. Comments

**Default: no comments.** Code should explain itself through naming, types, and structure.

**Allow only** (and only when restructuring is not an option):
- `@description()` decorators on parameters and outputs — always keep, never flag
- Comments explaining a non-obvious Azure platform constraint, ARM quirk, or intentional workaround — the kind of thing that looks wrong and will get "fixed" back by the next engineer if left unexplained

Flag:
- Inline comments that restate what the code does (`// Create the VNet` above a `module vnet` block)
- Section-header comments (`// ---- Networking ----`) — if a file needs these to be navigable, it should be split

The test: if removing the comment would leave a future reader confused or likely to revert the code, keep it. If it just restates what the identifier already says, flag it.

### 6. Module boundary violations

Flag:
- A module that derives a resource name using the same formula as another module, when the name could instead be passed as a parameter — flag as `Info` with the trade-off (param vs. formula duplication)
- A module that takes more parameters than it uses
- A module that accepts a raw connection string or password when it could accept a Key Vault secret URI instead

### 7. Parameter hygiene

Flag:
- Required params (no default) that are only ever passed a constant value from callers — consider making them optional with a default
- Params without `@description()` decorators
- `@secure()` missing on params that carry secrets (passwords, connection strings, tokens)
- Params with an `@allowed()` constraint where the constraint is stale or incomplete

### 8. Output hygiene

Flag:
- Outputs without `@description()` decorators
- Outputs that expose sensitive values (secrets, connection strings) without `@secure()` — in Bicep, `@secure()` on outputs masks the value in deployment history
- Outputs that are declared but never consumed by any caller visible in the audit scope

### 9. Resource API versions

Flag:
- API versions that are more than 12 months old where a newer stable version is known to exist
- Preview API versions (`-preview`) used in production-scoped resources where a stable version exists

### 10. Idempotency risks

Flag:
- Resources with write-only ARM properties (passwords, secrets) that will always show as a diff on every deploy — acceptable if documented with a constraint comment (Category 5), otherwise flag
- Resources that depend on ordering but have no explicit `dependsOn` or implicit dependency through output references
- Missing `dependsOn` that could cause a race condition on first deploy

---

## Conventions reminder

- Never apply a fix before the user confirms which findings to address.
- When applying fixes, change only the code required to resolve the finding — no opportunistic refactoring.
- After applying fixes, run `az bicep build --file infra/main.bicep` as a local syntax check, and optionally `az deployment sub what-if` to validate against Azure.
