import type { ProblemDetails } from '../types/api';

export function getApiError(error: unknown): string | null {
    if (!error) return null;
    // apiClient always throws the parsed JSON body; shape matches ProblemDetails from the API
    const p = error as ProblemDetails;
    return p.detail ?? p.title ?? 'An unexpected error occurred.';
}
