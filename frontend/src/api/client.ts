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

    if (!res.ok) throw await res.json();

    // 204 No Content — no body; T is void for these calls
    if (res.status === 204) return undefined as T;
    // Safe cast: the API contract guarantees the response shape matches T
    return res.json() as Promise<T>;
}
