import { TodoList } from './components/TodoList';

function App() {
    return (
        <main className="min-h-screen bg-background p-8">
            <div className="mx-auto max-w-lg space-y-6">
                <h1 className="text-3xl font-bold text-foreground">Dostar</h1>
                <TodoList />
            </div>
        </main>
    );
}

export default App;
