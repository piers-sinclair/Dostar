import type { JSX } from 'react';
import { createFileRoute } from '@tanstack/react-router';
import { TodoList } from '@/features/todos/components/TodoList';

export const Route = createFileRoute('/')({
    component: IndexPage,
});

function IndexPage(): JSX.Element {
    return (
        <div className="mx-auto max-w-lg space-y-6">
            <TodoList />
        </div>
    );
}
