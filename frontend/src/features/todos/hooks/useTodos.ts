import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import type { QueryClient } from '@tanstack/react-query';
import {
    getGetTodosUrl,
    getGetTodosQueryKey,
    getCreateTodoUrl,
    getUpdateTodoUrl,
    getDeleteTodoUrl,
} from '@/shared/api/generated';
import type { CreateTodoRequest, TodoDto } from '@/shared/api/generated';
import { apiClient } from '@/shared/api/client';

type UpdateTodoVariables = { id: string; title: string; isCompleted: boolean };
type OptimisticContext = { previous: TodoDto[] | undefined };

function invalidateTodos(client: QueryClient) {
    return client.invalidateQueries({ queryKey: getGetTodosQueryKey() });
}

// orval hooks can't be used directly — apiClient returns the plain JSON body,
// not the { data, status, headers } envelope the generated hooks expect.
// Use apiClient with orval's URL/queryKey helpers instead.

export function useTodos() {
    return useQuery({
        queryKey: getGetTodosQueryKey(),
        queryFn: () => apiClient<TodoDto[]>(getGetTodosUrl()),
    });
}

// Cache invalidation on success is the only business logic needed for create
export function useCreateTodo() {
    const client = useQueryClient();
    return useMutation({
        mutationFn: (req: CreateTodoRequest) =>
            apiClient<TodoDto>(getCreateTodoUrl(), { method: 'POST', data: req }),
        onSuccess: () => invalidateTodos(client),
    });
}

// Optimistic deletion: remove from cache immediately, rollback on error
export function useDeleteTodo() {
    const client = useQueryClient();
    return useMutation<void, Error, string, OptimisticContext>({
        mutationFn: (id) => apiClient<void>(getDeleteTodoUrl(id), { method: 'DELETE' }),
        onMutate: async (id) => {
            await client.cancelQueries({ queryKey: getGetTodosQueryKey() });
            const previous = client.getQueryData<TodoDto[]>(getGetTodosQueryKey());
            client.setQueryData<TodoDto[]>(
                getGetTodosQueryKey(),
                (old) => old?.filter((t) => t.id !== id) ?? []
            );
            return { previous };
        },
        onError: (_err, _id, ctx) => {
            if (ctx?.previous) client.setQueryData(getGetTodosQueryKey(), ctx.previous);
        },
        onSettled: () => invalidateTodos(client),
    });
}

// Optimistic update: patch cache immediately, rollback on error
export function useUpdateTodo() {
    const client = useQueryClient();
    return useMutation<TodoDto, Error, UpdateTodoVariables, OptimisticContext>({
        mutationFn: ({ id, title, isCompleted }) =>
            apiClient<TodoDto>(getUpdateTodoUrl(id), {
                method: 'PUT',
                data: { title, isCompleted },
            }),
        onMutate: async ({ id, title, isCompleted }) => {
            await client.cancelQueries({ queryKey: getGetTodosQueryKey() });
            const previous = client.getQueryData<TodoDto[]>(getGetTodosQueryKey());
            client.setQueryData<TodoDto[]>(
                getGetTodosQueryKey(),
                (old) => old?.map((t) => (t.id === id ? { ...t, title, isCompleted } : t)) ?? []
            );
            return { previous };
        },
        onError: (_err, _vars, ctx) => {
            if (ctx?.previous) client.setQueryData(getGetTodosQueryKey(), ctx.previous);
        },
        onSettled: () => invalidateTodos(client),
    });
}
