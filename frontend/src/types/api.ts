export interface Todo {
    id: string;
    title: string;
    isCompleted: boolean;
    createdAt: string;
}

export interface CreateTodoRequest {
    title: string;
}

export interface ProblemDetails {
    type?: string;
    title?: string;
    status?: number;
    detail?: string;
    errors?: Record<string, string[]>;
}

export function isProblemDetails(error: unknown): error is ProblemDetails {
    return (
        typeof error === 'object' &&
        error !== null &&
        ('detail' in error || 'title' in error || 'errors' in error)
    );
}
