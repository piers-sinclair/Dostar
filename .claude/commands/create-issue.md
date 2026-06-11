# create-issue

Create a GitHub issue in the `__GITHUB_ORG__/Dostar` repository with labels and an optional milestone.

## Usage

```
/create-issue <title> [--body <description>] [--label <label>] [--milestone <milestone-title>]
```

- `--body` — issue description. If omitted, Claude constructs a clear body from the title and any inline context.
- `--label` — label to apply (repeatable). Must match an existing repo label.
- `--milestone` — milestone title (e.g. `M8: DX & Documentation`). Claude resolves it to a number automatically.

## What this skill does

1. **Resolve the milestone number** (if `--milestone` is provided):
   ```
   gh api repos/__GITHUB_ORG__/Dostar/milestones | jq '.[] | select(.title == "<title>") | .number'
   ```

2. **Validate labels** — confirm each label exists in the repo before creating the issue:
   ```
   gh label list --repo __GITHUB_ORG__/Dostar
   ```

3. **Draft the body** — if `--body` was not provided, write a clear, actionable issue body from the title and any context given. Include an **Acceptance criteria** section.

4. **Create the issue**:
   ```
   gh issue create \
     --repo __GITHUB_ORG__/Dostar \
     --title "..." \
     --body "..." \
     --label "<label>" \
     --milestone <number>
   ```

5. **Report** the URL of the newly created issue.

## Available labels

`backend`, `frontend`, `architecture`, `data`, `cli`, `testing`, `ci`, `deployment`, `infra`, `observability`, `agents`, `docs`, `dx`, `example`, `enhancement`, `bug`, `documentation`, `setup`, `auth`

## Available milestones (as of last update)

| Title | Purpose |
|-------|---------|
| M5: CI/CD Pipelines | GitHub Actions pipeline work |
| M7: AI Dev-Acceleration Agents | Claude Code skills |
| M8: DX & Documentation | DX, docs, CLI usability |
| M9: Frontend Patterns | React/Vite/shadcn patterns |
| M10: Production Readiness | Observability, security, prod hardening |
