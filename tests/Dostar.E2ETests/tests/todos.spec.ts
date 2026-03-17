import { test, expect } from '@playwright/test';

// These tests require the Todos UI to be implemented (see frontend Todos feature).
// They are skipped until that work is complete.

test.describe('Todos', () => {
    test.skip('create a new Todo via the UI and it appears in the list', async ({ page }) => {
        await page.goto('/');

        await page.getByLabel('New todo').fill('Buy milk');
        await page.getByRole('button', { name: 'Add' }).click();

        await expect(page.getByRole('listitem').filter({ hasText: 'Buy milk' })).toBeVisible();
    });

    test.skip('mark a Todo complete and UI updates', async ({ page }) => {
        await page.goto('/');

        // Create a todo first
        await page.getByLabel('New todo').fill('Walk the dog');
        await page.getByRole('button', { name: 'Add' }).click();

        const todoItem = page.getByRole('listitem').filter({ hasText: 'Walk the dog' });
        await expect(todoItem).toBeVisible();

        // Mark it complete
        await todoItem.getByRole('checkbox').check();

        await expect(todoItem).toHaveClass(/completed/);
    });
});
