import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import type { CreateTodoRequest, Todo } from '../types/api';

const BASE = `${import.meta.env.VITE_API_BASE_URL ?? ''}/api/v1/todos`;

async function fetchJson<T>(url: string, init?: RequestInit): Promise<T> {
    const res = await fetch(url, init);
    if (!res.ok) throw await res.json();
    return res.json() as Promise<T>;
}

export function useTodos() {
    return useQuery<Todo[]>({
        queryKey: ['todos'],
        queryFn: () => fetchJson<Todo[]>(BASE),
    });
}

export function useCreateTodo() {
    const client = useQueryClient();
    return useMutation({
        mutationFn: (req: CreateTodoRequest) =>
            fetchJson<Todo>(BASE, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(req),
            }),
        onSuccess: () => client.invalidateQueries({ queryKey: ['todos'] }),
    });
}

export function useDeleteTodo() {
    const client = useQueryClient();
    return useMutation({
        mutationFn: (id: string) => fetchJson<void>(`${BASE}/${id}`, { method: 'DELETE' }),
        onSuccess: () => client.invalidateQueries({ queryKey: ['todos'] }),
    });
}

export function useToggleTodo() {
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
            fetchJson<Todo>(`${BASE}/${id}`, {
                method: 'PUT',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ title, isComplete: isCompleted }),
            }),
        onSuccess: () => client.invalidateQueries({ queryKey: ['todos'] }),
    });
}
