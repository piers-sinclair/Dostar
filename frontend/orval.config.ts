import { defineConfig } from 'orval';

export default defineConfig({
    dostar: {
        input: {
            target: 'http://localhost:5000/openapi/v1.json',
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
