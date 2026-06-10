import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { ReactQueryDevtools } from '@tanstack/react-query-devtools';
import { MsalProvider } from '@azure/msal-react';
import { msalInstance } from './lib/auth';
import './index.css';
import App from './App.tsx';

const queryClient = new QueryClient({
    defaultOptions: {
        queries: {
            staleTime: 30_000,
            retry: 1,
        },
    },
});

createRoot(document.getElementById('root')!).render(
    <StrictMode>
        <MsalProvider instance={msalInstance}>
            <QueryClientProvider client={queryClient}>
                <App />
                {import.meta.env.DEV && <ReactQueryDevtools initialIsOpen={false} />}
            </QueryClientProvider>
        </MsalProvider>
    </StrictMode>
);
