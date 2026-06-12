# Generated API client with orval

[orval](https://orval.dev) generates a type-safe API client from the backend's OpenAPI spec.

## Setup

`frontend/orval.config.ts` points at the local backend:

```ts
input: { target: 'http://localhost:5000/openapi/v1.json' }
output: { target: 'src/shared/api/generated/index.ts', client: 'react-query' }
```

The custom `src/shared/api/client.ts` handles authentication, JSON serialisation, and `ProblemDetails` errors uniformly.

## Generating the client

The backend must be running (`dotnet run --project backend/Dostar.Api --launch-profile http`), then:

```bash
pnpm generate:api
```

This writes `src/shared/api/generated/index.ts`. The file is gitignored (`.gitkeep` preserves the directory). Re-run whenever the API changes.

## Using generated hooks

```ts
import { useGetTodos, usePostTodos } from '@/shared/api/generated';

function TodoList() {
    const { data, isLoading } = useGetTodos();
    const create = usePostTodos();
    ...
}
```

## Custom client

`src/shared/api/client.ts` is the orval mutator — it replaces `axios` with a `fetch`-based wrapper that:
- Serialises request bodies to JSON
- Supports query-string params
- Returns `undefined` for 204 No Content
- Throws the parsed `ProblemDetails` JSON on non-OK responses
