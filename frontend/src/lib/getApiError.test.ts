import { describe, expect, it } from 'vitest';
import { getApiError } from './getApiError';

describe('getApiError', () => {
    it('returns null for null', () => {
        expect(getApiError(null)).toBeNull();
    });

    it('returns null for a plain Error', () => {
        expect(getApiError(new Error('oops'))).toBeNull();
    });

    it('returns detail when present', () => {
        expect(getApiError({ detail: 'Bad request' })).toBe('Bad request');
    });

    it('falls back to title when detail is absent', () => {
        expect(getApiError({ title: 'Not Found' })).toBe('Not Found');
    });

    it('returns default message when object is a ProblemDetails but has no detail or title', () => {
        // has 'errors' key so isProblemDetails = true, but neither detail nor title is set
        expect(getApiError({ errors: { Title: ['Required'] } })).toBe(
            'An unexpected error occurred.'
        );
    });

    it('returns null when object has no problem-details keys', () => {
        expect(getApiError({ status: 500 })).toBeNull();
    });
});
