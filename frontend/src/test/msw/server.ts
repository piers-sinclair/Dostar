import type { RequestHandler } from 'msw';
import { setupServer } from 'msw/node';

const modules = import.meta.glob<{ handlers: RequestHandler[] }>(
    '../../features/**/mocks/handlers.ts',
    { eager: true }
);
const handlers = Object.values(modules).flatMap((m) => m.handlers);

export const server = setupServer(...handlers);
