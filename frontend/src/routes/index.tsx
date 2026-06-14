import type { JSX } from 'react';
import { createFileRoute, Link } from '@tanstack/react-router';
import { Button } from '@/shared/components/ui/button';
import {
    Card,
    CardContent,
    CardDescription,
    CardHeader,
    CardTitle,
} from '@/shared/components/ui/card';

export const Route = createFileRoute('/')({
    component: IndexPage,
});

function IndexPage(): JSX.Element {
    return (
        <div className="mx-auto max-w-3xl space-y-8">
            <div>
                <h2 className="text-3xl font-bold tracking-tight">Welcome to Dostar</h2>
                <p className="mt-2 text-muted-foreground">
                    A production-ready fullstack template — .NET 10 modular monolith + React/Vite.
                    Use the <code className="text-xs">dostar</code> CLI to scaffold structure and
                    Claude Code skills to implement features with AI.
                </p>
            </div>
            <div className="grid gap-4 sm:grid-cols-2">
                <Card>
                    <CardHeader>
                        <CardTitle>Try the demo</CardTitle>
                        <CardDescription>
                            Todos is a working end-to-end example — list, create, edit, delete, and
                            toggle completion.
                        </CardDescription>
                    </CardHeader>
                    <CardContent>
                        <Button asChild size="sm">
                            <Link to="/todos">Go to Todos</Link>
                        </Button>
                    </CardContent>
                </Card>
                <Card>
                    <CardHeader>
                        <CardTitle>Add a backend module</CardTitle>
                        <CardDescription>
                            Scaffold the .NET module structure, then use the Claude Code skill to
                            implement it with AI.
                        </CardDescription>
                    </CardHeader>
                    <CardContent className="space-y-1">
                        <p className="text-xs text-muted-foreground">
                            <code>dostar add-module Orders</code>
                        </p>
                        <p className="text-xs text-muted-foreground">
                            then <code>/scaffold-module</code> in Claude Code
                        </p>
                    </CardContent>
                </Card>
                <Card>
                    <CardHeader>
                        <CardTitle>Add a frontend feature</CardTitle>
                        <CardDescription>
                            Wire the route and nav link, then use the Claude Code skill to build out
                            the components with AI.
                        </CardDescription>
                    </CardHeader>
                    <CardContent className="space-y-1">
                        <p className="text-xs text-muted-foreground">
                            <code>dostar add-feature Orders --type list</code>
                        </p>
                        <p className="text-xs text-muted-foreground">
                            then <code>/scaffold-feature</code> in Claude Code
                        </p>
                    </CardContent>
                </Card>
                <Card>
                    <CardHeader>
                        <CardTitle>Remove when done</CardTitle>
                        <CardDescription>
                            Clean up the Todos example once you have replaced it with your own
                            features.
                        </CardDescription>
                    </CardHeader>
                    <CardContent>
                        <code className="text-xs text-muted-foreground">
                            dostar remove-feature todos
                        </code>
                    </CardContent>
                </Card>
            </div>
        </div>
    );
}
