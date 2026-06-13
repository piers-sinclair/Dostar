import type { JSX } from 'react';
import { createRootRoute, Outlet } from '@tanstack/react-router';
import { TanStackRouterDevtools } from '@tanstack/router-devtools';

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
                <Outlet />
            </main>
            {import.meta.env.DEV && <TanStackRouterDevtools />}
        </>
    );
}
