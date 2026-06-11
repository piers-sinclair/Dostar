import {
    useMutation,
    useQuery,
    useQueryClient,
    type UseMutationResult,
    type UseQueryResult,
} from '@tanstack/react-query';
import { apiClient } from '../api/client';
import type { CreateTodoRequest, Todo } from '../types/api';

const BASE = '/api/v1/todos';

type UpdateTodoVariables = { id: string; title: string; isCompleted: boolean };
type OptimisticContext = { previous: Todo[] | undefined };

export function useTodos(): UseQueryResult<Todo[], Error> {
    return useQuery<Todo[], Error>({
        queryKey: ['todos'],
        queryFn: () => apiClient<Todo[]>(BASE),
    });
}

export function useCreateTodo(): UseMutationResult<Todo, Error, CreateTodoRequest> {
    const client = useQueryClient();
    return useMutation<Todo, Error, CreateTodoRequest>({
        mutationFn: (req) => apiClient<Todo>(BASE, { method: 'POST', data: req }),
        onSuccess: () => client.invalidateQueries({ queryKey: ['todos'] }),
    });
}

export function useDeleteTodo(): UseMutationResult<void, Error, string, OptimisticContext> {
    const client = useQueryClient();
    return useMutation<void, Error, string, OptimisticContext>({
        mutationFn: (id) => apiClient<void>(`${BASE}/${id}`, { method: 'DELETE' }),
        onMutate: async (id) => {
            await client.cancelQueries({ queryKey: ['todos'] });
            const previous = client.getQueryData<Todo[]>(['todos']);
            client.setQueryData<Todo[]>(['todos'], (old) => old?.filter((t) => t.id !== id) ?? []);
            return { previous };
        },
        onError: (_err, _id, ctx) => {
            if (ctx?.previous) client.setQueryData(['todos'], ctx.previous);
        },
        onSettled: () => client.invalidateQueries({ queryKey: ['todos'] }),
    });
}

export function useUpdateTodo(): UseMutationResult<Todo, Error, UpdateTodoVariables, OptimisticContext> {
    const client = useQueryClient();
    return useMutation<Todo, Error, UpdateTodoVariables, OptimisticContext>({
        mutationFn: ({ id, title, isCompleted }) =>
            apiClient<Todo>(`${BASE}/${id}`, {
                method: 'PUT',
                data: { title, isComplete: isCompleted },
            }),
        onMutate: async ({ id, title, isCompleted }) => {
            await client.cancelQueries({ queryKey: ['todos'] });
            const previous = client.getQueryData<Todo[]>(['todos']);
            client.setQueryData<Todo[]>(
                ['todos'],
                (old) => old?.map((t) => (t.id === id ? { ...t, title, isCompleted } : t)) ?? []
            );
            return { previous };
        },
        onError: (_err, _vars, ctx) => {
            if (ctx?.previous) client.setQueryData(['todos'], ctx.previous);
        },
        onSettled: () => client.invalidateQueries({ queryKey: ['todos'] }),
    });
}
