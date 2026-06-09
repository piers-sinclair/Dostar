export interface Todo {
    id: string;
    title: string;
    isCompleted: boolean;
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
