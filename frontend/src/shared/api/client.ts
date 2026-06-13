import { getApiError } from '@/shared/lib/getApiError';

export class ApiError extends Error {
    readonly status: number;
    readonly body: unknown;

    constructor(status: number, message: string, body?: unknown) {
        super(message);
        this.name = 'ApiError';
        this.status = status;
        this.body = body;
    }
}

export async function apiClient<T>(
    url: string,
    options?: RequestInit & { data?: unknown; params?: Record<string, string> }
): Promise<T> {
    const baseUrl = import.meta.env.VITE_API_BASE_URL ?? '';
    const { data, params, ...init } = options ?? {};

    const query = params ? '?' + new URLSearchParams(params).toString() : '';

    const res = await fetch(`${baseUrl}${url}${query}`, {
        ...init,
        headers: {
            'Content-Type': 'application/json',
            ...init?.headers,
        },
        body: data !== undefined ? JSON.stringify(data) : init?.body,
    });

    if (!res.ok) {
        let body: unknown;
        try {
            body = await res.json();
        } catch {
            // non-JSON body — body stays undefined, message falls back to default
        }
        throw new ApiError(res.status, getApiError(body) ?? 'An unexpected error occurred.', body);
    }

    if (res.status === 204) return undefined as T;
    return res.json() as Promise<T>;
}
