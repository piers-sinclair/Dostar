// Re-export all feature-specific handlers so the MSW server can compose them.
// Each backend module owns its handlers under features/<name>/mocks/handlers.ts.
export { handlers, defaultTodos, TODOS_URL, TODO_BY_ID_URL } from '@/features/todos/mocks/handlers';
