import type { ProblemDetails } from '../types/api';

export function getApiError(error: unknown): string | null {
    if (!error) return null;
    const p = error as ProblemDetails;
    return p.detail ?? p.title ?? 'An unexpected error occurred.';
}
