import { defineConfig, devices } from '@playwright/test';

const baseURL = process.env.UI_BASE_URL ?? 'http://localhost:5173';
const isCI = !!process.env.CI;

export default defineConfig({
    testDir: './tests',
    fullyParallel: true,
    forbidOnly: isCI,
    retries: isCI ? 2 : 0,
    workers: isCI ? 1 : undefined,
    reporter: [['html'], ['list']],
    use: {
        baseURL,
        trace: 'on-first-retry',
        screenshot: 'only-on-failure',
    },
    projects: isCI
        ? [{ name: 'chromium', use: { ...devices['Desktop Chrome'] } }]
        : [
              { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
              { name: 'firefox', use: { ...devices['Desktop Firefox'] } },
              { name: 'webkit', use: { ...devices['Desktop Safari'] } },
          ],
    outputDir: 'test-results/',
    webServer: {
        command: 'pnpm dev --port 5173',
        url: baseURL,
        cwd: '../../frontend',
        reuseExistingServer: !isCI,
    },
});
