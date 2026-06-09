import path from 'path';
import react from '@vitejs/plugin-react';
import tailwindcss from '@tailwindcss/vite';
import { coverageConfigDefaults, defineConfig } from 'vitest/config';

export default defineConfig({
    plugins: [react(), tailwindcss()],
    resolve: {
        alias: { '@': path.resolve(__dirname, './src') },
    },
    server: {
        host: true,
        open: true,
        allowedHosts: true,
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
