import type { FieldPath, FieldValues, UseFormSetError } from 'react-hook-form';

interface ProblemDetails {
    errors?: Record<string, string[]>;
    detail?: string;
}

export function mapProblemDetailsErrors<T extends FieldValues>(
    error: unknown,
    setError: UseFormSetError<T>
): void {
    const p = error as ProblemDetails;
    if (p?.errors) {
        for (const [field, messages] of Object.entries(p.errors)) {
            const key = (field.charAt(0).toLowerCase() + field.slice(1)) as FieldPath<T>;
            setError(key, { message: messages[0] });
        }
    } else {
        setError('root', { message: p?.detail ?? 'An unexpected error occurred.' });
    }
}
