import type { JSX } from 'react';
import { createFileRoute, Link } from '@tanstack/react-router';

export const Route = createFileRoute('/$')({
    component: NotFoundPage,
});

function NotFoundPage(): JSX.Element {
    return (
        <div className="mx-auto max-w-lg space-y-6">
            <h1 className="text-3xl font-bold text-foreground">404 — Page not found</h1>
            <Link to="/" className="text-primary underline">
                Go home
            </Link>
        </div>
    );
}
