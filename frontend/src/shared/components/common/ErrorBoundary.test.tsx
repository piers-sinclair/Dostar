import type { JSX } from 'react';
import { screen } from '@testing-library/react';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { renderWithProviders } from '@/test/utils';
import { ErrorBoundary } from './ErrorBoundary';

function ThrowingChild(): JSX.Element {
    throw new Error('test error');
}

describe('ErrorBoundary', () => {
    beforeEach(() => {
        vi.spyOn(console, 'error').mockImplementation(() => {});
    });

    afterEach(() => {
        vi.restoreAllMocks();
    });

    it('renders children when no error occurs', () => {
        renderWithProviders(
            <ErrorBoundary>
                <p>hello</p>
            </ErrorBoundary>
        );

        expect(screen.getByText('hello')).toBeInTheDocument();
    });

    it('renders fallback UI when a child throws', () => {
        renderWithProviders(
            <ErrorBoundary>
                <ThrowingChild />
            </ErrorBoundary>
        );

        expect(screen.getByRole('alert')).toBeInTheDocument();
        expect(screen.getByText('Something went wrong')).toBeInTheDocument();
        expect(screen.getByRole('button', { name: 'Reload page' })).toBeInTheDocument();
    });
});
