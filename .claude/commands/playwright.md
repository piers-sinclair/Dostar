# playwright

Write or run a Playwright UI test for the specified user journey.

## Usage

```
/playwright <user journey description>
```

Example: `/playwright user can create a todo and see it in the list`

## Context

- Tests live in `tests/` at the repo root
- Config: `tests/playwright.config.ts`
- Base URL: `http://localhost:5173` (Vite dev server — must be running)
- Framework: `@playwright/test` — use `test`, `expect`, `Page`
- File naming: `tests/<feature>.spec.ts`

## Steps

### 1. Read existing tests

Read `tests/playwright.config.ts` and any existing `tests/*.spec.ts` files to understand current conventions.

### 2. Identify the test scenario

From `$ARGUMENTS`, determine:
- Which feature is being tested
- The step-by-step user actions (navigate, fill, click, assert)
- The expected final state

### 3. Write the test file

Create or extend `tests/<feature>.spec.ts`:

```typescript
import { test, expect } from '@playwright/test';

test.describe('<Feature>', () => {
    test('<scenario from $ARGUMENTS>', async ({ page }) => {
        // Navigate to the starting point
        await page.goto('/');

        // Perform user actions using semantic locators
        await page.getByRole('textbox', { name: 'Title' }).fill('Buy milk');
        await page.getByRole('button', { name: 'Add todo' }).click();

        // Assert the expected outcome
        await expect(page.getByRole('listitem').filter({ hasText: 'Buy milk' })).toBeVisible();
    });
});
```

**Locator rules:**
- Always use semantic locators: `getByRole`, `getByLabel`, `getByText`, `getByPlaceholder`
- Never use CSS selectors (`.class`) or XPath
- Prefer `getByRole` with `name` option — it matches accessible name

**Assertion rules:**
- Use `expect(locator).toBeVisible()` for presence checks
- Use `expect(locator).toHaveText(...)` for text content
- Use `expect(page).toHaveURL(...)` for navigation
- Always `await` every action and assertion

### 4. Run the tests

```bash
cd tests && pnpm exec playwright test
```

Or run a single file:

```bash
cd tests && pnpm exec playwright test <feature>.spec.ts
```

Fix any failures before reporting complete. The Vite dev server (`pnpm dev`) must be running.

### 5. Debug if needed

```bash
cd tests && pnpm exec playwright test --headed        # watch the browser
cd tests && pnpm exec playwright test --ui            # interactive UI mode
cd tests && pnpm exec playwright test --debug         # step through with DevTools
```

## Guidelines

- Each `test()` is independent — no shared mutable state between tests
- Use `test.beforeEach` to reset state (navigate to `/`, clear storage) when needed
- Add `await page.goto('/')` as the first action in each test
- Group related tests in `test.describe()` blocks
- Keep test file names kebab-case: `todo-creation.spec.ts`
