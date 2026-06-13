import {
    createMemoryHistory,
    createRootRoute,
    createRouter,
    RouterContextProvider,
} from '@tanstack/react-router';
import { render, type RenderOptions } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import type { ReactElement } from 'react';
import { Toaster } from '@/shared/components/ui/sonner';

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
    const router = createRouter({
        routeTree: createRootRoute(),
        history: createMemoryHistory(),
    });

    return render(
        <QueryClientProvider client={client}>
            <RouterContextProvider router={router}>{ui}</RouterContextProvider>
            <Toaster />
        </QueryClientProvider>,
        options
    );
}
