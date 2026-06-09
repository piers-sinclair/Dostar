import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { getApiError } from '@/hooks/getApiError';
import { useDeleteTodo, useTodos, useToggleTodo } from '@/hooks/useTodos';
import { cn } from '@/lib/utils';

export function TodoList() {
    const { data: todos, isLoading, error: queryError } = useTodos();
    const deleteTodo = useDeleteTodo();
    const toggleTodo = useToggleTodo();

    const queryErrorMessage = getApiError(queryError);
    const mutationErrorMessage = getApiError(deleteTodo.error ?? toggleTodo.error);

    return (
        <Card>
            <CardHeader>
                <CardTitle>Todos</CardTitle>
            </CardHeader>
            <CardContent>
                {isLoading && <p className="text-muted-foreground">Loading…</p>}
                {queryErrorMessage && <p className="text-destructive">{queryErrorMessage}</p>}
                {mutationErrorMessage && <p className="text-destructive">{mutationErrorMessage}</p>}
                <ul className="space-y-2">
                    {todos?.map((todo) => {
                        const isToggling =
                            toggleTodo.isPending && toggleTodo.variables?.id === todo.id;
                        const isDeleting = deleteTodo.isPending && deleteTodo.variables === todo.id;
                        const isBusy = isToggling || isDeleting;

                        return (
                            <li key={todo.id} className="flex items-center gap-2">
                                <input
                                    type="checkbox"
                                    aria-label={`Mark "${todo.title}" as ${todo.isCompleted ? 'incomplete' : 'complete'}`}
                                    checked={todo.isCompleted}
                                    disabled={isBusy}
                                    onChange={() =>
                                        toggleTodo.mutate({
                                            id: todo.id,
                                            isCompleted: !todo.isCompleted,
                                        })
                                    }
                                />
                                <span
                                    className={cn(
                                        todo.isCompleted && 'line-through text-muted-foreground'
                                    )}
                                >
                                    {todo.title}
                                </span>
                                <Button
                                    variant="ghost"
                                    size="sm"
                                    aria-label={`Delete "${todo.title}"`}
                                    disabled={isBusy}
                                    onClick={() => deleteTodo.mutate(todo.id)}
                                >
                                    ×
                                </Button>
                            </li>
                        );
                    })}
                </ul>
            </CardContent>
        </Card>
    );
}
