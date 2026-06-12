import {
    useMutation,
    useQuery,
    useQueryClient,
    type QueryClient,
    type UseMutationResult,
    type UseQueryResult,
} from '@tanstack/react-query';
import { apiClient } from '../../../shared/api/client';
import type { CreateTodoRequest, TodoDto } from '../../../shared/api/generated';

const TODOS_API_PATH = '/api/v1/todos';
const TODOS_QUERY_KEY = ['todos'] as const;

type UpdateTodoVariables = { id: string; title: string; isCompleted: boolean };
type OptimisticContext = { previous: TodoDto[] | undefined };

function rollbackTodos(ctx: OptimisticContext | undefined, client: QueryClient) {
    if (ctx?.previous) client.setQueryData(TODOS_QUERY_KEY, ctx.previous);
}

function invalidateTodos(client: QueryClient) {
    return client.invalidateQueries({ queryKey: TODOS_QUERY_KEY });
}

export function useTodos(): UseQueryResult<TodoDto[], Error> {
    return useQuery<TodoDto[], Error>({
        queryKey: TODOS_QUERY_KEY,
        queryFn: () => apiClient<TodoDto[]>(TODOS_API_PATH),
    });
}

export function useCreateTodo(): UseMutationResult<TodoDto, Error, CreateTodoRequest> {
    const client = useQueryClient();
    return useMutation<TodoDto, Error, CreateTodoRequest>({
        mutationFn: (req) => apiClient<TodoDto>(TODOS_API_PATH, { method: 'POST', data: req }),
        onSuccess: () => invalidateTodos(client),
    });
}

export function useDeleteTodo(): UseMutationResult<void, Error, string, OptimisticContext> {
    const client = useQueryClient();
    return useMutation<void, Error, string, OptimisticContext>({
        mutationFn: (id) => apiClient<void>(`${TODOS_API_PATH}/${id}`, { method: 'DELETE' }),
        onMutate: async (id) => {
            await client.cancelQueries({ queryKey: TODOS_QUERY_KEY });
            const previous = client.getQueryData<TodoDto[]>(TODOS_QUERY_KEY);
            client.setQueryData<TodoDto[]>(
                TODOS_QUERY_KEY,
                (old) => old?.filter((t) => t.id !== id) ?? []
            );
            return { previous };
        },
        onError: (_err, _id, ctx) => rollbackTodos(ctx, client),
        onSettled: () => invalidateTodos(client),
    });
}

export function useUpdateTodo(): UseMutationResult<
    TodoDto,
    Error,
    UpdateTodoVariables,
    OptimisticContext
> {
    const client = useQueryClient();
    return useMutation<TodoDto, Error, UpdateTodoVariables, OptimisticContext>({
        mutationFn: ({ id, title, isCompleted }) =>
            apiClient<TodoDto>(`${TODOS_API_PATH}/${id}`, {
                method: 'PUT',
                data: { title, isCompleted },
            }),
        onMutate: async ({ id, title, isCompleted }) => {
            await client.cancelQueries({ queryKey: TODOS_QUERY_KEY });
            const previous = client.getQueryData<TodoDto[]>(TODOS_QUERY_KEY);
            client.setQueryData<TodoDto[]>(
                TODOS_QUERY_KEY,
                (old) => old?.map((t) => (t.id === id ? { ...t, title, isCompleted } : t)) ?? []
            );
            return { previous };
        },
        onError: (_err, _vars, ctx) => rollbackTodos(ctx, client),
        onSettled: () => invalidateTodos(client),
    });
}
