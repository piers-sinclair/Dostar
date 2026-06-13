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
                <span className="font-semibold text-foreground">Dostar</span>
            </nav>
            <main className="min-h-screen bg-background p-8">
                <Outlet />
            </main>
            {import.meta.env.DEV && <TanStackRouterDevtools />}
        </>
    );
}
