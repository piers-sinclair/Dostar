import type { JSX } from 'react';
import { createRootRoute, Outlet } from '@tanstack/react-router';
import { TanStackRouterDevtools } from '@tanstack/router-devtools';
import { ErrorBoundary } from '@/shared/components/common/ErrorBoundary';
import { Toaster } from '@/shared/components/ui/sonner';

export const Route = createRootRoute({
    component: RootLayout,
});

function RootLayout(): JSX.Element {
    return (
        <>
            <nav className="border-b bg-background px-8 py-4">
                <h1 className="text-lg font-semibold text-foreground">Dostar</h1>
            </nav>
            <main className="min-h-screen bg-background p-8">
                <ErrorBoundary>
                    <Outlet />
                </ErrorBoundary>
            </main>
            <Toaster />
            {import.meta.env.DEV && <TanStackRouterDevtools />}
        </>
    );
}
