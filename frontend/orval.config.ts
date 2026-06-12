import { defineConfig } from 'orval';

export default defineConfig({
    dostar: {
        input: {
            target: '../backend/Dostar.Api.json',
        },
        output: {
            target: 'src/api/generated/index.ts',
            client: 'react-query',
            override: {
                mutator: {
                    path: 'src/api/client.ts',
                    name: 'apiClient',
                },
            },
        },
    },
});
