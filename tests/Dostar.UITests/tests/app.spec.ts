import { test, expect } from '@playwright/test';

test('page loads and title is correct', async ({ page }) => {
    await page.goto('/');
    await expect(page).toHaveTitle('Dostar');
});
