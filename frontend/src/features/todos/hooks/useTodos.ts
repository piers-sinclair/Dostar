import { useMutation, useQueryClient } from '@tanstack/react-query';
import type { QueryClient } from '@tanstack/react-query';
import { createTodo, deleteTodo, updateTodo, getGetTodosQueryKey } from '@/shared/api/generated';
import type { CreateTodoRequest, TodoDto } from '@/shared/api/generated';

type UpdateTodoVariables = { id: string; title: string; isCompleted: boolean };
type OptimisticContext = { previous: TodoDto[] | undefined };

function invalidateTodos(client: QueryClient) {
    return client.invalidateQueries({ queryKey: getGetTodosQueryKey() });
}

// Cache invalidation on success is the only business logic needed for create
export function useCreateTodo() {
    const client = useQueryClient();
    return useMutation({
        mutationFn: (req: CreateTodoRequest) => createTodo(req).then((res) => res.data),
        onSuccess: () => invalidateTodos(client),
    });
}

// Optimistic deletion: remove from cache immediately, rollback on error
export function useDeleteTodo() {
    const client = useQueryClient();
    return useMutation<void, Error, string, OptimisticContext>({
        mutationFn: (id) => deleteTodo(id).then(() => undefined),
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
            updateTodo(id, { title, isCompleted }).then((res) => res.data as TodoDto),
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
