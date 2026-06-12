import { screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { http, HttpResponse } from 'msw';
import { describe, expect, it } from 'vitest';
import { server } from '@/test/msw/server';
import { TODOS_URL } from '@/test/msw/handlers';
import { renderWithProviders } from '@/test/utils';
import { CreateTodoForm } from './CreateTodoForm';

describe('CreateTodoForm', () => {
    it('renders the input and submit button', () => {
        renderWithProviders(<CreateTodoForm />);

        expect(screen.getByPlaceholderText('What needs doing?')).toBeInTheDocument();
        expect(screen.getByRole('button', { name: 'Add' })).toBeInTheDocument();
    });

    it('shows client validation error when submitted with empty title', async () => {
        const user = userEvent.setup();
        renderWithProviders(<CreateTodoForm />);

        await user.click(screen.getByRole('button', { name: 'Add' }));

        expect(await screen.findByRole('alert')).toHaveTextContent('Title is required');
    });

    it('resets the input after a successful submission', async () => {
        const user = userEvent.setup();
        renderWithProviders(<CreateTodoForm />);

        await user.type(screen.getByPlaceholderText('What needs doing?'), 'Buy milk');
        await user.click(screen.getByRole('button', { name: 'Add' }));

        await waitFor(() => {
            expect(screen.getByPlaceholderText('What needs doing?')).toHaveValue('');
        });
    });

    it('shows server field validation error returned by the API', async () => {
        const user = userEvent.setup();
        server.use(
            http.post(TODOS_URL, () =>
                HttpResponse.json({ errors: { Title: ['Title is too long'] } }, { status: 400 }),
            ),
        );
        renderWithProviders(<CreateTodoForm />);

        await user.type(screen.getByPlaceholderText('What needs doing?'), 'something');
        await user.click(screen.getByRole('button', { name: 'Add' }));

        expect(await screen.findByRole('alert')).toHaveTextContent('Title is too long');
    });

    it('shows a root error when the API returns a non-field problem details', async () => {
        const user = userEvent.setup();
        server.use(
            http.post(TODOS_URL, () =>
                HttpResponse.json({ detail: 'Service unavailable' }, { status: 503 }),
            ),
        );
        renderWithProviders(<CreateTodoForm />);

        await user.type(screen.getByPlaceholderText('What needs doing?'), 'something');
        await user.click(screen.getByRole('button', { name: 'Add' }));

        expect(await screen.findByRole('alert')).toHaveTextContent('Service unavailable');
    });
});
