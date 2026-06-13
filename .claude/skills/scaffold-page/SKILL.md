---
description: Scaffold a routed page (TanStack Router file-based route, PageHeader component, nav link, Playwright smoke test) from a plain-English description. Requires the frontend feature to already exist.
argument-hint: <page name and feature>
allowed-tools: Bash(pnpm *) Read Write Edit Glob Grep
---

# scaffold-page

Scaffold a routed page from a plain-English description.

## Usage

```
/scaffold-page <Description of the page>
```

Example: `/scaffold-page "Products page — lists all products"`

## Prerequisites

Before running this skill:
1. The backend module must exist (run `/scaffold-module` first).
2. The frontend feature folder must exist (run `/scaffold-feature` first).

## What this skill does

Confirms the page name, then wires the feature into the router shell: route file, `PageHeader` component (created once), nav link, and a Playwright smoke test stub. Execute every step in order, then run `pnpm build` to confirm 0 TypeScript errors.

---

## Step 1 — Confirm page names

From the description, derive:
- **Route segment**: kebab-case singular or plural as appropriate (e.g. `products`, `order-items`) — becomes the URL path `/<segment>`
- **PascalCase name** (e.g. `Products`) — used in the route component name and `PageHeader` title
- **Feature folder name**: the existing `frontend/src/features/<name>/` folder that the page renders

Confirm all three with the user before proceeding.

---

## Step 2 — Check / create `PageHeader`

Check whether `frontend/src/shared/components/common/PageHeader.tsx` exists.

**If it does not exist**, create it:

```tsx
import type { JSX } from 'react';

interface PageHeaderProps {
    title: string;
    description?: string;
}

export function PageHeader({ title, description }: PageHeaderProps): JSX.Element {
    return (
        <div className="space-y-1">
            <h2 className="text-2xl font-bold tracking-tight text-foreground">{title}</h2>
            {description && (
                <p className="text-sm text-muted-foreground">{description}</p>
            )}
        </div>
    );
}
```

**If it already exists**, skip this step — never overwrite it.

---

## Step 3 — Create the route file

Create `frontend/src/routes/<segment>.tsx`:

```tsx
import type { JSX } from 'react';
import { createFileRoute } from '@tanstack/react-router';
import { PageHeader } from '@/shared/components/common/PageHeader';
import { <Name>List } from '@/features/<feature>/components/<Name>List';

export const Route = createFileRoute('/<segment>')({
    component: <Name>Page,
});

function <Name>Page(): JSX.Element {
    return (
        <div className="mx-auto max-w-lg space-y-6">
            <PageHeader title="<PascalCaseName>" />
            <<Name>List />
        </div>
    );
}
```

Replace `<Name>List` with the real list component that exists in the feature folder. If the feature has a different primary component, use that instead and adjust the import.

TanStack Router's Vite plugin watches `routes/` and regenerates `routeTree.gen.ts` automatically — no manual registration needed.

---

## Step 4 — Add a nav link to `__root.tsx`

Read `frontend/src/routes/__root.tsx` to understand its current state, then apply the appropriate edit below.

### Case A — `Link` is not yet imported (first nav link)

1. Add `Link` to the `@tanstack/react-router` import.
2. Add `flex items-center gap-6` to the `<nav>` element's `className`.
3. Add the link after the `<h1>`:

```tsx
<Link
    to="/<segment>"
    className="text-sm text-muted-foreground hover:text-foreground [&.active]:text-foreground [&.active]:font-medium"
>
    <PascalCaseName>
</Link>
```

### Case B — `Link` is already imported (subsequent nav links)

Add the new `<Link>` element alongside the existing ones inside `<nav>`, maintaining the same className pattern as the others.

---

## Step 5 — Create the Playwright smoke test stub

Create `tests/Dostar.UITests/tests/<segment>.spec.ts`:

```typescript
import { test, expect } from "@playwright/test";

const <SEGMENT_UPPER>_URL = "**/api/v1/<segment>";

test.describe("<PascalCaseName>", () => {
    test.beforeEach(async ({ page }) => {
        await page.route(<SEGMENT_UPPER>_URL, async (route) => {
            await route.fulfill({ json: [] });
        });
        await page.goto("/<segment>");
    });

    test("shows the page heading", async ({ page }) => {
        await expect(
            page.getByRole("heading", { name: "<PascalCaseName>" })
        ).toBeVisible();
    });

    test("shows the nav link as active", async ({ page }) => {
        await expect(
            page.getByRole("link", { name: "<PascalCaseName>" })
        ).toHaveClass(/active/);
    });
});
```

Replace `<SEGMENT_UPPER>` with the route segment in SCREAMING_SNAKE_CASE (e.g. `products` → `PRODUCTS`). Adjust the mock URL to match the real API path used by the feature's hooks.

---

## Step 6 — Verify

```bash
cd frontend && pnpm build
```

Must pass with **0 TypeScript errors**. Fix any issues before reporting success.

---

## Conventions reminder

- Route file name matches the URL segment exactly: `routes/products.tsx` → `/products`.
- `PageHeader` lives in `shared/components/common/` — create it once, never duplicate.
- Nav links use `[&.active]` Tailwind variants for TanStack Router's automatic active-class injection.
- Playwright tests live in `tests/Dostar.UITests/tests/` and mock all API calls via `page.route()`.
- `pnpm` only — never `npm` or `yarn`.
- Only use emojis if the user explicitly requests it.
