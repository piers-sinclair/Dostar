import { http, HttpResponse } from 'msw';
import type { TodoDto } from '@/api/generated';

// Must match the base URL configured in .env.test (VITE_API_BASE_URL=http://localhost)
const BASE = 'http://localhost';
export const TODOS_URL = `${BASE}/api/v1/todos`;
export const TODO_BY_ID_URL = `${BASE}/api/v1/todos/:id`;

export const defaultTodos: TodoDto[] = [
    {
        id: '11111111-1111-1111-1111-111111111111',
        title: 'Buy milk',
        isCompleted: false,
        createdAt: '2024-01-01T00:00:00Z',
    },
    {
        id: '22222222-2222-2222-2222-222222222222',
        title: 'Walk dog',
        isCompleted: true,
        createdAt: '2024-01-01T00:00:00Z',
    },
];

export const handlers = [
    http.get(TODOS_URL, () => HttpResponse.json(defaultTodos)),

    http.post(TODOS_URL, async ({ request }) => {
        const body = (await request.json()) as { title: string };
        const todo: TodoDto = {
            id: '33333333-3333-3333-3333-333333333333',
            title: body.title,
            isCompleted: false,
            createdAt: new Date().toISOString(),
        };
        return HttpResponse.json(todo, { status: 201 });
    }),

    http.put(TODO_BY_ID_URL, async ({ params, request }) => {
        const body = (await request.json()) as { title: string; isCompleted: boolean };
        const todo: TodoDto = {
            id: params.id as string,
            title: body.title,
            isCompleted: body.isCompleted,
            createdAt: '2024-01-01T00:00:00Z',
        };
        return HttpResponse.json(todo);
    }),

    http.delete(TODO_BY_ID_URL, () => new HttpResponse(null, { status: 204 })),
];
