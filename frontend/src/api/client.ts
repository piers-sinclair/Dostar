export async function apiClient<T>(
    url: string,
    options?: RequestInit & { data?: unknown; params?: Record<string, string> }
): Promise<T> {
    const { data, params, ...init } = options ?? {};

    const query = params ? '?' + new URLSearchParams(params).toString() : '';

    const res = await fetch(`${url}${query}`, {
        ...init,
        headers: {
            'Content-Type': 'application/json',
            ...init?.headers,
        },
        body: data !== undefined ? JSON.stringify(data) : init?.body,
    });

    if (!res.ok) throw await res.json();

    if (res.status === 204) return undefined as T;
    return res.json() as Promise<T>;
}
