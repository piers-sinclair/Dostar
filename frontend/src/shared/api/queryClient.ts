import { MutationCache, QueryCache, QueryClient, type QueryClientConfig } from '@tanstack/react-query';
import { toast } from 'sonner';
import { ApiError } from './client';

function handleGlobalError(error: unknown) {
    if (!(error instanceof ApiError)) return;
    if (error.status === 401) {
        // TODO: redirect to login on 401
        return;
    }
    if (error.status >= 500) {
        toast.error(error.message);
    }
}

export function createQueryClient(
    options?: Omit<QueryClientConfig, 'queryCache' | 'mutationCache'>
) {
    return new QueryClient({
        ...options,
        queryCache: new QueryCache({ onError: handleGlobalError }),
        mutationCache: new MutationCache({ onError: handleGlobalError }),
    });
}
