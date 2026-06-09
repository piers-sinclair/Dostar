import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { useTodos, useDeleteTodo, useToggleTodo } from './hooks/useTodos';
import { getApiError } from './hooks/getApiError';

function App() {
    const { data: todos, isLoading, error } = useTodos();
    const deleteTodo = useDeleteTodo();
    const toggleTodo = useToggleTodo();
    const errorMessage = getApiError(error);

    return (
        <main className="min-h-screen bg-background p-8">
            <div className="mx-auto max-w-lg space-y-6">
                <h1 className="text-3xl font-bold text-foreground">Dostar</h1>
                <Card>
                    <CardHeader>
                        <CardTitle>Todos</CardTitle>
                    </CardHeader>
                    <CardContent>
                        {isLoading && <p className="text-muted-foreground">Loading…</p>}
                        {errorMessage && <p className="text-destructive">{errorMessage}</p>}
                        <ul className="space-y-2">
                            {todos?.map((todo) => (
                                <li key={todo.id} className="flex items-center gap-2">
                                    <input
                                        type="checkbox"
                                        checked={todo.isCompleted}
                                        onChange={() =>
                                            toggleTodo.mutate({
                                                id: todo.id,
                                                isCompleted: !todo.isCompleted,
                                            })
                                        }
                                    />
                                    <span
                                        className={
                                            todo.isCompleted ? 'line-through text-muted-foreground' : ''
                                        }
                                    >
                                        {todo.title}
                                    </span>
                                    <Button
                                        variant="ghost"
                                        size="sm"
                                        onClick={() => deleteTodo.mutate(todo.id)}
                                    >
                                        ×
                                    </Button>
                                </li>
                            ))}
                        </ul>
                    </CardContent>
                </Card>
            </div>
        </main>
    );
}

export default App;
