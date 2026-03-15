import path from 'path';
import react from '@vitejs/plugin-react';
import { coverageConfigDefaults, defineConfig } from 'vitest/config';

export default defineConfig({
    plugins: [react()],
    resolve: {
        alias: { '@': path.resolve(__dirname, './src') },
    },
    server: {
        proxy: {
            '/api': {
                target: 'http://localhost:5000',
                rewrite: (path) => path.replace(/^\/api/, ''),
            },
        },
    },
    test: {
        coverage: {
            provider: 'v8',
            reporter: ['text', 'html', 'cobertura'],
            exclude: [...coverageConfigDefaults.exclude, 'src/main.tsx'],
        },
    },
});
