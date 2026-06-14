---
description: Scaffold a complete frontend feature (hooks, components, MSW handlers, tests) from a plain-English description. Requires the backend module to already exist and the orval API client to be regenerated first.
argument-hint: <feature description>
allowed-tools: Bash(pnpm *) Read Write Edit Glob Grep
---

# scaffold-feature

Scaffold a complete frontend feature from a plain-English description.

## Usage

```
/scaffold-feature <Description of the feature>
```

Example: `/scaffold-feature "Products — stores name, SKU, and price; supports CRUD"`

## Prerequisites

Before running this skill:
1. The backend module must be scaffolded and the API implemented (run `/scaffold-module` first).
2. The backend must be running so Scalar can export the OpenAPI spec.
3. Run `cd frontend && pnpm run generate` to regenerate the orval API client — the hooks and components import generated types.

## What this skill does

Confirms the feature name, then generates the full frontend feature folder. Execute every step in order, then run `pnpm build` to confirm 0 TypeScript errors.

---

## Step 1 — Confirm feature names

From the description, derive:
- **Feature folder name**: kebab-case plural (e.g. `products`, `order-items`) — matches the backend route prefix
- **PascalCase singular** (e.g. `Product`) — used for component and hook naming
- **PascalCase plural** (e.g. `Products`) — used for the query hook name
- **API route prefix**: `/api/<kebab-plural>` — must match the backend exactly (check `<Name>Module.cs`)

Confirm both names with the user before proceeding.

---

## Step 2 — Infer the feature shape

From the description and the generated DTO in `@/shared/api/generated`, determine:
- **DTO fields**: names and TypeScript types
- **Create request fields**: mutable fields (exclude `id`, `createdAt`)
- **Update request fields**: same as create unless described otherwise
- **Validation rules** for the create form (matching the backend FluentValidation constraints)

---

## Step 3 — Create MSW handlers

Create `frontend/src/features/<name>/mocks/handlers.ts`:

```typescript
import { http, HttpResponse } from 'msw';
import type { <Name>Dto } from '@/shared/api/generated';

const BASE = 'http://localhost';
export const <NAME>S_URL = `${BASE}/api/<plural-name>`;
export const <NAME>_BY_ID_URL = `${BASE}/api/<plural-name>/:id`;

export const default<PluralName>: <Name>Dto[] = [
    {
        id: '11111111-1111-1111-1111-111111111111',
        // all DTO fields with representative values
        createdAt: '2024-01-01T00:00:00Z',
    },
    {
        id: '22222222-2222-2222-2222-222222222222',
        // all DTO fields with different representative values
        createdAt: '2024-01-02T00:00:00Z',
    },
];

export const handlers = [
    http.get(<NAME>S_URL, () => HttpResponse.json(default<PluralName>)),

    http.post(<NAME>S_URL, async ({ request }) => {
        const body = (await request.json()) as { /* create request fields */ };
        const item: <Name>Dto = {
            id: '33333333-3333-3333-3333-333333333333',
            // spread body fields + any defaults
            createdAt: new Date().toISOString(),
        };
        return HttpResponse.json(item, { status: 201 });
    }),

    http.put(<NAME>_BY_ID_URL, async ({ params, request }) => {
        const body = (await request.json()) as { /* update request fields */ };
        const item: <Name>Dto = {
            id: params.id as string,
            // spread body fields + any unchanged defaults
            createdAt: '2024-01-01T00:00:00Z',
        };
        return HttpResponse.json(item);
    }),

    http.delete(<NAME>_BY_ID_URL, () => new HttpResponse(null, { status: 204 })),
];
```

---

## Step 4 — Create hooks

Create `frontend/src/features/<name>/hooks/use<Name>.ts`:

```typescript
import {
    useMutation,
    useQuery,
    useQueryClient,
    type QueryClient,
    type UseMutationResult,
    type UseQueryResult,
} from '@tanstack/react-query';
import { toast } from 'sonner';
import { apiClient } from '@/shared/api/client';
import type { <Name>Dto, Create<Name>Request } from '@/shared/api/generated';
import { getApiError } from '@/shared/lib/getApiError';

const <NAME>S_API_PATH = '/api/<plural-name>';
const <NAME>S_QUERY_KEY = ['<plural-name>'] as const;

type Update<Name>Variables = { id: string; /* mutable fields matching Update<Name>Request */ };
type OptimisticContext = { previous: <Name>Dto[] | undefined };

function rollback<PluralName>(ctx: OptimisticContext | undefined, client: QueryClient) {
    if (ctx?.previous) client.setQueryData(<NAME>S_QUERY_KEY, ctx.previous);
}

function invalidate<PluralName>(client: QueryClient) {
    return client.invalidateQueries({ queryKey: <NAME>S_QUERY_KEY });
}

export function use<PluralName>(): UseQueryResult<<Name>Dto[], Error> {
    return useQuery<<Name>Dto[], Error>({
        queryKey: <NAME>S_QUERY_KEY,
        queryFn: () => apiClient<<Name>Dto[]>(<NAME>S_API_PATH),
    });
}

export function useCreate<Name>(): UseMutationResult<<Name>Dto, Error, Create<Name>Request> {
    const client = useQueryClient();
    return useMutation<<Name>Dto, Error, Create<Name>Request>({
        mutationFn: (req) => apiClient<<Name>Dto>(<NAME>S_API_PATH, { method: 'POST', data: req }),
        onSuccess: () => invalidate<PluralName>(client),
    });
}

export function useDelete<Name>(): UseMutationResult<void, Error, string, OptimisticContext> {
    const client = useQueryClient();
    return useMutation<void, Error, string, OptimisticContext>({
        mutationFn: (id) => apiClient<void>(`${<NAME>S_API_PATH}/${id}`, { method: 'DELETE' }),
        onMutate: async (id) => {
            await client.cancelQueries({ queryKey: <NAME>S_QUERY_KEY });
            const previous = client.getQueryData<<Name>Dto[]>(<NAME>S_QUERY_KEY);
            client.setQueryData<<Name>Dto[]>(
                <NAME>S_QUERY_KEY,
                (old) => old?.filter((x) => x.id !== id) ?? []
            );
            return { previous };
        },
        onError: (err, _id, ctx) => {
            rollback<PluralName>(ctx, client);
            toast.error(getApiError(err));
        },
        onSettled: () => invalidate<PluralName>(client),
    });
}
```

Add `useUpdate<Name>` with optimistic update using the same pattern as `useUpdateTodo` in
`frontend/src/features/todos/hooks/useTodos.ts` if the feature supports update. Include
`toast.error(getApiError(err))` in `onError` alongside the rollback call.

---

## Step 5 — Create the list component

Create `frontend/src/features/<name>/components/<Name>List.tsx`:

- Fetch with `use<PluralName>()`
- Show loading state (`<p className="text-muted-foreground">Loading…</p>`) and query error
- Render each item in a `<ul>` with a Delete button (`useDelete<Name>`)
- Include `<Create<Name>Form />` above the list
- Wrap in a `<Card>` with `<CardTitle><PluralName></CardTitle>` (same structure as `TodoList`)
- Disable buttons while a mutation is pending

---

## Step 6 — Create the form component

Create `frontend/src/features/<name>/components/Create<Name>Form.tsx`:

- Zod schema matching the backend FluentValidation constraints (same field limits)
- `useForm` with `zodResolver`
- Submit via `useCreate<Name>().mutateAsync`; call `reset()` on success
- Map server errors with `mapProblemDetailsErrors(err, setError)` in the catch block
- Show `errors.<field>.message` inline beneath each field and `errors.root.message` for server errors
- Follow the exact pattern of `frontend/src/features/todos/components/CreateTodoForm.tsx`

---

## Step 7 — Create component tests

Create `frontend/src/features/<name>/components/<Name>List.test.tsx`:

```typescript
import { screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { http, HttpResponse } from 'msw';
import { describe, it } from 'vitest';
import { server } from '@/test/msw/server';
import { default<PluralName>, <NAME>S_URL, <NAME>_BY_ID_URL } from '@/features/<name>/mocks/handlers';
import { renderWithProviders } from '@/test/utils';
import { <Name>List } from './<Name>List';

describe('<Name>List', () => {
    it('shows a loading indicator while fetching', () => { /* ... */ });
    it('renders <plural-name> returned by the API', async () => { /* ... */ });
    it('shows error message when the API fails', async () => { /* server.use override + error text check */ });
    it('removes a <name> from the list after a successful delete', async () => { /* server.use override + waitFor */ });
    it('restores a <name> when the delete API call fails', async () => { /* server.use override + optimistic rollback check */ });
    it('shows a toast error when the delete API call fails', async () => { /* server.use override + findByText on toast message */ });
});
```

Follow the exact patterns from `frontend/src/features/todos/components/TodoList.test.tsx`.

Create `frontend/src/features/<name>/components/Create<Name>Form.test.tsx` covering:
- renders the form
- submits successfully and resets
- shows validation errors inline

---

## Step 8 — Verify

```bash
cd frontend && pnpm build
```

Must pass with **0 TypeScript errors**. Fix any issues before reporting success.

---

## Next step

Run `dostar add-feature <Name>` (the CLI tool) to create the TanStack Router route file and the sentinel-wrapped nav link. The CLI sentinel pattern is required so `dostar remove-feature` can clean up the nav link later — never add nav links manually.

After the CLI runs, flesh out the generated `frontend/src/routes/<segment>.tsx` to import your feature's primary component and `PageHeader`:

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

If `frontend/src/shared/components/common/PageHeader.tsx` does not yet exist, create it:

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

Run `/playwright` to add a UI smoke test for the new page once it is wired up.

---

## Conventions reminder

- Feature folder name: kebab-case plural (e.g. `products`, `order-items`).
- Components, hooks, and handlers all live under `frontend/src/features/<name>/`.
- MSW handlers are auto-discovered via glob — no changes to `test/msw/server.ts` needed.
- Never import between feature folders; shared code goes to `shared/`.
- `pnpm` only — never `npm` or `yarn`.
- Only use emojis if the user explicitly requests it.
