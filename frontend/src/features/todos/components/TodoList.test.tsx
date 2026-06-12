import { screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { http, HttpResponse } from 'msw';
import { describe, expect, it } from 'vitest';
import { server } from '@/test/msw/server';
import { defaultTodos, TODO_BY_ID_URL, TODOS_URL } from '@/features/todos/mocks/handlers';
import { renderWithProviders } from '@/test/utils';
import { TodoList } from './TodoList';

describe('TodoList', () => {
    it('shows a loading indicator while fetching', () => {
        renderWithProviders(<TodoList />);

        expect(screen.getByText('Loading…')).toBeInTheDocument();
    });

    it('renders todos returned by the API', async () => {
        renderWithProviders(<TodoList />);

        expect(await screen.findByText('Buy milk')).toBeInTheDocument();
        expect(screen.getByText('Walk dog')).toBeInTheDocument();
    });

    it('renders completed todo with line-through style', async () => {
        renderWithProviders(<TodoList />);

        await screen.findByText('Walk dog');
        const walkDog = screen.getByRole('button', { name: 'Edit "Walk dog"' });
        expect(walkDog).toHaveClass('line-through');
    });

    it('shows error message when the API fails', async () => {
        server.use(
            http.get(TODOS_URL, () =>
                HttpResponse.json({ detail: 'Database unavailable' }, { status: 503 })
            )
        );
        renderWithProviders(<TodoList />);

        expect(await screen.findByText('Database unavailable')).toBeInTheDocument();
    });

    it('removes a todo from the list after a successful delete', async () => {
        const user = userEvent.setup();
        let deleted = false;

        server.use(
            http.get(TODOS_URL, () =>
                HttpResponse.json(deleted ? [defaultTodos[1]] : defaultTodos)
            ),
            http.delete(TODO_BY_ID_URL, () => {
                deleted = true;
                return new HttpResponse(null, { status: 204 });
            })
        );
        renderWithProviders(<TodoList />);

        await screen.findByText('Buy milk');
        await user.click(screen.getByRole('button', { name: `Delete "${defaultTodos[0].title}"` }));

        await waitFor(() => {
            expect(screen.queryByText('Buy milk')).not.toBeInTheDocument();
        });
    });

    it('restores a todo when the delete API call fails', async () => {
        const user = userEvent.setup();
        server.use(
            http.delete(TODO_BY_ID_URL, () =>
                HttpResponse.json({ detail: 'Failed' }, { status: 500 })
            )
        );
        renderWithProviders(<TodoList />);

        await screen.findByText('Buy milk');
        await user.click(screen.getByRole('button', { name: `Delete "${defaultTodos[0].title}"` }));

        expect(await screen.findByText('Buy milk')).toBeInTheDocument();
    });

    it('enters edit mode when a todo title is clicked', async () => {
        const user = userEvent.setup();
        renderWithProviders(<TodoList />);

        await screen.findByText('Buy milk');
        await user.click(screen.getByRole('button', { name: 'Edit "Buy milk"' }));

        expect(screen.getByDisplayValue('Buy milk')).toBeInTheDocument();
    });

    it('cancels edit on Escape', async () => {
        const user = userEvent.setup();
        renderWithProviders(<TodoList />);

        await screen.findByText('Buy milk');
        await user.click(screen.getByRole('button', { name: 'Edit "Buy milk"' }));
        await user.keyboard('{Escape}');

        expect(screen.queryByDisplayValue('Buy milk')).not.toBeInTheDocument();
        expect(screen.getByRole('button', { name: 'Edit "Buy milk"' })).toBeInTheDocument();
    });
});
