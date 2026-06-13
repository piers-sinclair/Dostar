import { Component, type ErrorInfo, type JSX, type ReactNode } from 'react';

interface Props {
    children: ReactNode;
}

interface State {
    error: Error | null;
}

export class ErrorBoundary extends Component<Props, State> {
    state: State = { error: null };

    static getDerivedStateFromError(error: Error): State {
        return { error };
    }

    componentDidCatch(error: Error, info: ErrorInfo) {
        console.error('Render error caught by ErrorBoundary:', error, info.componentStack);
    }

    render() {
        if (this.state.error) {
            return <FallbackUI error={this.state.error} />;
        }
        return this.props.children;
    }
}

function FallbackUI({ error }: { error: Error }): JSX.Element {
    return (
        <main
            role="alert"
            className="flex min-h-[50vh] flex-col items-center justify-center gap-4 p-8"
        >
            <h1 className="text-2xl font-bold text-foreground">Something went wrong</h1>
            {import.meta.env.DEV && (
                <pre className="max-w-xl overflow-auto rounded bg-muted p-4 text-sm text-muted-foreground">
                    {error.message}
                </pre>
            )}
            <button
                className="rounded bg-primary px-4 py-2 text-primary-foreground hover:bg-primary/90"
                onClick={() => window.location.reload()}
            >
                Reload page
            </button>
        </main>
    );
}
