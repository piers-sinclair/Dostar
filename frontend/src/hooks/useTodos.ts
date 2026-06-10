import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { apiClient } from '../api/client';
import type { CreateTodoRequest, Todo } from '../types/api';

const BASE = '/api/v1/todos';

export function useTodos() {
    return useQuery<Todo[]>({
        queryKey: ['todos'],
        queryFn: () => apiClient<Todo[]>(BASE),
    });
}

export function useCreateTodo() {
    const client = useQueryClient();
    return useMutation({
        mutationFn: (req: CreateTodoRequest) =>
            apiClient<Todo>(BASE, { method: 'POST', data: req }),
        onSuccess: () => client.invalidateQueries({ queryKey: ['todos'] }),
    });
}

export function useDeleteTodo() {
    const client = useQueryClient();
    return useMutation({
        mutationFn: (id: string) => apiClient<void>(`${BASE}/${id}`, { method: 'DELETE' }),
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

export function useUpdateTodo() {
    const client = useQueryClient();
    return useMutation({
        mutationFn: ({
            id,
            title,
            isCompleted,
        }: {
            id: string;
            title: string;
            isCompleted: boolean;
        }) =>
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
