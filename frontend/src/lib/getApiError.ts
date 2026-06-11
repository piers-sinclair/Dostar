import { isProblemDetails } from '../types/api';

export function getApiError(error: unknown): string | null {
    if (!isProblemDetails(error)) return null;
    return error.detail ?? error.title ?? 'An unexpected error occurred.';
}
