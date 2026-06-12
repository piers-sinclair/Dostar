import type { FieldPath, FieldValues, UseFormSetError } from 'react-hook-form';
import { isProblemDetails } from '../types/api';

export function mapProblemDetailsErrors<T extends FieldValues>(
    error: unknown,
    setError: UseFormSetError<T>
): void {
    const p = isProblemDetails(error) ? error : undefined;
    if (p?.errors) {
        for (const [field, messages] of Object.entries(p.errors)) {
            const key = (field.charAt(0).toLowerCase() + field.slice(1)) as FieldPath<T>;
            setError(key, { message: messages[0] });
        }
    } else {
        setError('root', { message: p?.detail ?? 'An unexpected error occurred.' });
    }
}
