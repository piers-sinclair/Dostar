import { defineConfig } from 'orval';

export default defineConfig({
    dostar: {
        input: {
            target: '../backend/Dostar.Api.json',
        },
        output: {
            target: 'src/shared/api/generated/index.ts',
            client: 'react-query',
            override: {
                mutator: {
                    path: 'src/shared/api/client.ts',
                    name: 'apiClient',
                },
            },
        },
    },
});
