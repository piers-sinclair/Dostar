# Testing

Dostar has three test layers:

| Layer | Technology | Location |
|-------|-----------|----------|
| Unit | xUnit + Shouldly + NSubstitute | `backend/Modules/<Module>/Dostar.<Module>.UnitTests/` |
| Integration | xUnit + Testcontainers (real PostgreSQL) | `backend/Modules/<Module>/Dostar.<Module>.IntegrationTests/` |
| E2E | Playwright (TypeScript) | `tests/Dostar.E2ETests/` |

---

## Unit tests

```bash
dotnet test backend/Modules/Todos/Dostar.Todos.UnitTests
```

- Use EF Core In-Memory provider; one fresh DB per test (`Guid.NewGuid().ToString()` as name).
- Mock other dependencies with NSubstitute.
- Assertions with Shouldly — never `Assert.*` or FluentAssertions.
- Method naming: `MethodName_Condition_ExpectedOutcome`

## Integration tests

```bash
dotnet test backend/Modules/Todos/Dostar.Todos.IntegrationTests
```

- Spin up a real PostgreSQL container via Testcontainers.
- Requires Docker Desktop (or compatible runtime) to be running.

---

## E2E tests (Playwright)

### Prerequisites

1. Start the backend:
   ```bash
   dotnet run --project backend/Dostar.Api --launch-profile http
   ```
2. Start the frontend:
   ```bash
   cd frontend && pnpm dev
   ```
3. (First time only) install Playwright browsers:
   ```bash
   cd tests/Dostar.E2ETests && pnpm exec playwright install --with-deps chromium
   ```

### Running

```bash
cd tests/Dostar.E2ETests
pnpm test:e2e
```

By default tests run against `http://localhost:5173`. Override with the `E2E_BASE_URL` environment variable:

```bash
E2E_BASE_URL=https://staging.example.com pnpm test:e2e
```

### Viewing the report

```bash
pnpm test:e2e:report
```

The HTML report opens at `playwright-report/index.html`. Screenshots and traces for failed tests are saved under `test-results/`.

### CI behaviour

When the `CI` environment variable is set:
- Only Chromium runs (Firefox and WebKit are skipped).
- Tests retry up to 2 times on failure.
- `forbidOnly` is enabled (`.only` calls fail the run).

### Adding new tests

Place test files in `tests/Dostar.E2ETests/tests/`. Use `@playwright/test` selectors that favour accessible roles and labels (`getByRole`, `getByLabel`, `getByText`) over CSS selectors.
