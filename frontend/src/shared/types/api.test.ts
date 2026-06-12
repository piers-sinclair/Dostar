import { describe, expect, it } from 'vitest';
import { isProblemDetails } from './api';

describe('isProblemDetails', () => {
    it('returns true when object has detail', () => {
        expect(isProblemDetails({ detail: 'Not found' })).toBe(true);
    });

    it('returns true when object has title', () => {
        expect(isProblemDetails({ title: 'Bad Request' })).toBe(true);
    });

    it('returns true when object has errors', () => {
        expect(isProblemDetails({ errors: { Title: ['Required'] } })).toBe(true);
    });

    it('returns false for null', () => {
        expect(isProblemDetails(null)).toBe(false);
    });

    it('returns false for a string', () => {
        expect(isProblemDetails('error')).toBe(false);
    });

    it('returns false for a plain Error', () => {
        expect(isProblemDetails(new Error('oops'))).toBe(false);
    });

    it('returns false for an empty object', () => {
        expect(isProblemDetails({})).toBe(false);
    });
});
