import { render, type RenderOptions } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import type { ReactElement } from 'react';

function createTestQueryClient() {
    return new QueryClient({
        defaultOptions: {
            queries: { retry: false, gcTime: 0 },
            mutations: { retry: false },
        },
    });
}

export function renderWithProviders(ui: ReactElement, options?: RenderOptions) {
    const client = createTestQueryClient();
    return render(<QueryClientProvider client={client}>{ui}</QueryClientProvider>, options);
}
