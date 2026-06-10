import { Trash2 } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Checkbox } from '@/components/ui/checkbox';
import { getApiError } from '@/hooks/getApiError';
import { useDeleteTodo, useTodos, useToggleTodo } from '@/hooks/useTodos';
import { cn } from '@/lib/utils';
import { CreateTodoForm } from './CreateTodoForm';

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
            <CardContent className="space-y-4">
                <CreateTodoForm />
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
                                <Checkbox
                                    aria-label={`Mark "${todo.title}" as ${todo.isCompleted ? 'incomplete' : 'complete'}`}
                                    checked={todo.isCompleted}
                                    disabled={isBusy}
                                    onCheckedChange={() =>
                                        toggleTodo.mutate({
                                            id: todo.id,
                                            title: todo.title,
                                            isCompleted: !todo.isCompleted,
                                        })
                                    }
                                />
                                <span
                                    className={cn(
                                        'flex-1',
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
                                    <Trash2 className="h-4 w-4" />
                                </Button>
                            </li>
                        );
                    })}
                </ul>
            </CardContent>
        </Card>
    );
}
