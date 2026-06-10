import { getAccessToken } from '../lib/auth';

const BASE_URL = import.meta.env.VITE_API_BASE_URL ?? '';

export async function apiClient<T>(
    url: string,
    options?: RequestInit & { data?: unknown; params?: Record<string, string> }
): Promise<T> {
    const { data, params, ...init } = options ?? {};

    const query = params ? '?' + new URLSearchParams(params).toString() : '';
    const token = await getAccessToken();

    const res = await fetch(`${BASE_URL}${url}${query}`, {
        ...init,
        headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${token}`,
            ...init?.headers,
        },
        body: data !== undefined ? JSON.stringify(data) : init?.body,
    });

    if (!res.ok) throw await res.json();

    if (res.status === 204) return undefined as T;
    return res.json() as Promise<T>;
}
