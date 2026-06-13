import type { FieldPath, FieldValues, UseFormSetError } from 'react-hook-form';
import { isProblemDetails } from '../types/api';
import { ApiError } from '../api/client';

export function mapProblemDetailsErrors<T extends FieldValues>(
    error: unknown,
    setError: UseFormSetError<T>
): void {
    const body = error instanceof ApiError ? error.body : error;
    const p = isProblemDetails(body) ? body : undefined;
    if (p?.errors) {
        for (const [field, messages] of Object.entries(p.errors)) {
            const key = (field.charAt(0).toLowerCase() + field.slice(1)) as FieldPath<T>;
            setError(key, { message: messages[0] });
        }
    } else {
        const msg =
            error instanceof ApiError ? error.message : p?.detail ?? 'An unexpected error occurred.';
        setError('root', { message: msg });
    }
}
