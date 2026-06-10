import { useEffect } from 'react';
import { AuthenticatedTemplate, useMsal } from '@azure/msal-react';
import { InteractionStatus } from '@azure/msal-browser';
import { apiTokenRequest } from './lib/auth';
import { TodoList } from './components/TodoList';

function App() {
    const { instance, inProgress } = useMsal();

    useEffect(() => {
        if (inProgress === InteractionStatus.None && instance.getAllAccounts().length === 0) {
            instance.loginRedirect(apiTokenRequest);
        }
    }, [instance, inProgress]);

    return (
        <main className="min-h-screen bg-background p-8">
            <div className="mx-auto max-w-lg space-y-6">
                <h1 className="text-3xl font-bold text-foreground">Dostar</h1>
                <AuthenticatedTemplate>
                    <TodoList />
                </AuthenticatedTemplate>
            </div>
        </main>
    );
}

export default App;
