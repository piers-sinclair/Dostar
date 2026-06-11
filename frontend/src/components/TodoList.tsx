import { useState, type JSX } from 'react';
import { Trash2 } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Checkbox } from '@/components/ui/checkbox';
import { Input } from '@/components/ui/input';
import { getApiError } from '@/lib/getApiError';
import { useDeleteTodo, useTodos, useUpdateTodo } from '@/hooks/useTodos';
import { cn } from '@/lib/utils';
import { CreateTodoForm } from './CreateTodoForm';

export function TodoList(): JSX.Element {
    const [editingId, setEditingId] = useState<string | null>(null);
    const [editValue, setEditValue] = useState('');

    const { data: todos, isLoading, error: queryError } = useTodos();
    const deleteTodo = useDeleteTodo();
    const updateTodo = useUpdateTodo();

    const queryErrorMessage = getApiError(queryError);
    const mutationErrorMessage = getApiError(deleteTodo.error ?? updateTodo.error);

    function startEdit(id: string, title: string) {
        setEditingId(id);
        setEditValue(title);
    }

    function commitEdit(id: string, isCompleted: boolean, originalTitle: string) {
        const trimmed = editValue.trim();
        setEditingId(null);
        if (!trimmed || trimmed === originalTitle) return;
        updateTodo.mutate({ id, title: trimmed, isCompleted });
    }

    function cancelEdit() {
        setEditingId(null);
    }

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
                        const isUpdating =
                            updateTodo.isPending && updateTodo.variables?.id === todo.id;
                        const isDeleting = deleteTodo.isPending && deleteTodo.variables === todo.id;
                        const isBusy = isUpdating || isDeleting;
                        const isEditing = editingId === todo.id;

                        return (
                            <li key={todo.id} className="flex items-center gap-2">
                                <Checkbox
                                    aria-label={`Mark "${todo.title}" as ${todo.isCompleted ? 'incomplete' : 'complete'}`}
                                    checked={todo.isCompleted}
                                    disabled={isBusy}
                                    onCheckedChange={() =>
                                        updateTodo.mutate({
                                            id: todo.id,
                                            title: todo.title,
                                            isCompleted: !todo.isCompleted,
                                        })
                                    }
                                />
                                {isEditing ? (
                                    <Input
                                        autoFocus
                                        className="h-7 flex-1 py-0"
                                        value={editValue}
                                        disabled={isUpdating}
                                        onChange={(e) => setEditValue(e.target.value)}
                                        onKeyDown={(e) => {
                                            if (e.key === 'Enter')
                                                commitEdit(todo.id, todo.isCompleted, todo.title);
                                            if (e.key === 'Escape') cancelEdit();
                                        }}
                                    />
                                ) : (
                                    <span
                                        role="button"
                                        tabIndex={0}
                                        aria-label={`Edit "${todo.title}"`}
                                        className={cn(
                                            'flex-1 cursor-pointer rounded px-1 hover:bg-muted',
                                            todo.isCompleted && 'line-through text-muted-foreground'
                                        )}
                                        onClick={() => startEdit(todo.id, todo.title)}
                                        onKeyDown={(e) =>
                                            e.key === 'Enter' && startEdit(todo.id, todo.title)
                                        }
                                    >
                                        {todo.title}
                                    </span>
                                )}
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
