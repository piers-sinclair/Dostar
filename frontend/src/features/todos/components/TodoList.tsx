import { useState, type JSX } from 'react';

import { Trash2 } from 'lucide-react';
import { Button } from '@/shared/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/shared/components/ui/card';
import { Checkbox } from '@/shared/components/ui/checkbox';
import { Input } from '@/shared/components/ui/input';
import { useDeleteTodo, useTodos, useUpdateTodo } from '@/features/todos/hooks/useTodos';
import { cn } from '@/shared/lib/utils';
import { CreateTodoForm } from './CreateTodoForm';

const Key = { Enter: 'Enter', Escape: 'Escape' } as const;

export function TodoList(): JSX.Element {
    const [editingId, setEditingId] = useState<string | null>(null);
    const [editValue, setEditValue] = useState('');

    const { data: todos, isLoading } = useTodos();
    const deleteTodo = useDeleteTodo();
    const updateTodo = useUpdateTodo();

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
                                            if (e.key === Key.Enter)
                                                commitEdit(todo.id, todo.isCompleted, todo.title);
                                            if (e.key === Key.Escape) cancelEdit();
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
                                            e.key === Key.Enter && startEdit(todo.id, todo.title)
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
