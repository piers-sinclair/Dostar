import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import { QueryClientProvider } from '@tanstack/react-query';
import { ReactQueryDevtools } from '@tanstack/react-query-devtools';
import { createRouter, RouterProvider } from '@tanstack/react-router';
import { createQueryClient } from '@/shared/api/queryClient';
import { routeTree } from './routeTree.gen';
import './index.css';

const queryClient = createQueryClient({
    defaultOptions: {
        queries: {
            staleTime: 30_000,
            retry: 1,
        },
    },
});

const router = createRouter({ routeTree });

createRoot(document.getElementById('root')!).render(
    <StrictMode>
        <QueryClientProvider client={queryClient}>
            <RouterProvider router={router} />
            {import.meta.env.DEV && <ReactQueryDevtools initialIsOpen={false} />}
        </QueryClientProvider>
    </StrictMode>
);
