import { describe, expect, it, vi } from 'vitest';
import { mapProblemDetailsErrors } from './mapProblemDetailsErrors';

describe('mapProblemDetailsErrors', () => {
    it('maps field errors from problem details, lowercasing the first char', () => {
        const setError = vi.fn();

        mapProblemDetailsErrors({ errors: { Title: ['Title is required'] } }, setError);

        expect(setError).toHaveBeenCalledWith('title', { message: 'Title is required' });
    });

    it('sets root error when problem details has no field errors', () => {
        const setError = vi.fn();

        mapProblemDetailsErrors({ detail: 'Server error' }, setError);

        expect(setError).toHaveBeenCalledWith('root', { message: 'Server error' });
    });

    it('sets fallback root error for problem details with no detail or errors', () => {
        const setError = vi.fn();

        mapProblemDetailsErrors({ status: 500 }, setError);

        expect(setError).toHaveBeenCalledWith('root', { message: 'An unexpected error occurred.' });
    });

    it('sets fallback root error for non-problem-details value', () => {
        const setError = vi.fn();

        mapProblemDetailsErrors(new Error('network failure'), setError);

        expect(setError).toHaveBeenCalledWith('root', { message: 'An unexpected error occurred.' });
    });

    it('maps multiple field errors, using the first message per field', () => {
        const setError = vi.fn();

        mapProblemDetailsErrors(
            { errors: { Title: ['Too short', 'Required'], IsComplete: ['Must be boolean'] } },
            setError,
        );

        expect(setError).toHaveBeenCalledWith('title', { message: 'Too short' });
        expect(setError).toHaveBeenCalledWith('isComplete', { message: 'Must be boolean' });
    });
});
