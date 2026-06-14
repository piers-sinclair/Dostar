import type { JSX } from 'react';
import { createFileRoute } from '@tanstack/react-router';
import { TodoList } from '@/features/todos/components/TodoList';

export const Route = createFileRoute('/todos')({
    component: TodosPage,
});

function TodosPage(): JSX.Element {
    return (
        <div className="mx-auto max-w-lg space-y-6">
            <TodoList />
        </div>
    );
}
