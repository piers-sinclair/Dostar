# Data fetching with TanStack Query

All server state uses [@tanstack/react-query](https://tanstack.com/query/latest).

## Setup

`QueryClientProvider` wraps the app in `src/main.tsx`. React Query Devtools mount in dev only:

```tsx
<QueryClientProvider client={queryClient}>
    <App />
    {import.meta.env.DEV && <ReactQueryDevtools initialIsOpen={false} />}
</QueryClientProvider>
```

## Hooks pattern

Put all query/mutation hooks in `src/hooks/`. Each hook wraps `useQuery` or `useMutation`:

```ts
// src/hooks/useTodos.ts
export function useTodos() {
    return useQuery<Todo[]>({
        queryKey: ['todos'],
        queryFn: () => fetchJson<Todo[]>('/api/todos'),
    });
}

export function useCreateTodo() {
    const client = useQueryClient();
    return useMutation({
        mutationFn: (req: CreateTodoRequest) => fetchJson<Todo>('/api/todos', { method: 'POST', ... }),
        onSuccess: () => client.invalidateQueries({ queryKey: ['todos'] }),
    });
}
```

## Error handling

`src/hooks/useApiError.ts` extracts a human-readable message from a `ProblemDetails` response:

```ts
const { error } = useTodos();
const message = useApiError(error); // string | null
```

## Types

Shared API types live in `src/shared/types/api.ts` — `Todo`, `CreateTodoRequest`, `ProblemDetails`.

## Cache invalidation

After mutations call `client.invalidateQueries({ queryKey: ['todos'] })`. This refetches any mounted queries with that key automatically.
