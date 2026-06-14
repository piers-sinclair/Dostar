import type { JSX } from 'react';
import { Link, createRootRoute, Outlet } from '@tanstack/react-router';
import { TanStackRouterDevtools } from '@tanstack/router-devtools';
import { ErrorBoundary } from '@/shared/components/common/ErrorBoundary';
import { Toaster } from '@/shared/components/ui/sonner';

export const Route = createRootRoute({
    component: RootLayout,
});

function RootLayout(): JSX.Element {
    return (
        <>
            <nav className="flex items-center gap-6 border-b bg-background px-8 py-4">
                <Link to="/" className="text-lg font-semibold text-foreground hover:opacity-80">
                    Dostar
                </Link>
                {/* dostar:feature:todos:start */}
                <Link
                    to="/todos"
                    className="text-sm text-muted-foreground hover:text-foreground [&.active]:text-foreground [&.active]:font-medium"
                >
                    Todos
                </Link>
                {/* dostar:feature:todos:end */}
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
