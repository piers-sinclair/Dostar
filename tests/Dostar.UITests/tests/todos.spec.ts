import { test, expect } from "@playwright/test";

const TODOS_URL = "**/api/v1/todos";
const TODO_BY_ID_URL = "**/api/v1/todos/**";

const HttpMethod = {
    GET: "GET",
    POST: "POST",
    PUT: "PUT",
    DELETE: "DELETE",
} as const;

const buyMilk = {
    id: "11111111-1111-1111-1111-111111111111",
    title: "Buy milk",
    isCompleted: false,
    createdAt: "2024-01-01T00:00:00Z",
};
const walkDog = {
    id: "22222222-2222-2222-2222-222222222222",
    title: "Walk dog",
    isCompleted: true,
    createdAt: "2024-01-01T00:00:00Z",
};

test.beforeEach(async ({ page }) => {
    let todos = [buyMilk, walkDog];

    await page.route(TODOS_URL, async (route) => {
        const method = route.request().method();
        if (method === HttpMethod.GET) {
            await route.fulfill({ json: todos });
        } else if (method === HttpMethod.POST) {
            const body = route.request().postDataJSON() as { title: string };
            const created = {
                id: "33333333-3333-3333-3333-333333333333",
                title: body.title,
                isCompleted: false,
                createdAt: new Date().toISOString(),
            };
            todos = [...todos, created];
            await route.fulfill({ status: 201, json: created });
        } else {
            await route.continue();
        }
    });

    await page.route(TODO_BY_ID_URL, async (route) => {
        const id = route.request().url().split("/").at(-1)!;
        const method = route.request().method();
        if (method === HttpMethod.DELETE) {
            todos = todos.filter((t) => t.id !== id);
            await route.fulfill({ status: 204 });
        } else if (method === HttpMethod.PUT) {
            const body = route.request().postDataJSON() as {
                title: string;
                isCompleted: boolean;
            };
            todos = todos.map((t) =>
                t.id === id
                    ? { ...t, title: body.title, isCompleted: body.isCompleted }
                    : t,
            );
            const updated = todos.find((t) => t.id === id)!;
            await route.fulfill({ json: updated });
        } else {
            await route.continue();
        }
    });

    await page.goto("/todos");
});

test("displays the page heading and todo list card", async ({ page }) => {
    await expect(page.getByRole("heading", { name: "Dostar" })).toBeVisible();
    await expect(page.getByRole("main").getByText("Todos")).toBeVisible();
});

test("renders existing todos from the API", async ({ page }) => {
    await expect(
        page.getByRole("button", { name: 'Edit "Buy milk"' }),
    ).toBeVisible();
    await expect(
        page.getByRole("button", { name: 'Edit "Walk dog"' }),
    ).toBeVisible();
});

test("creates a new todo and shows it in the list", async ({ page }) => {
    await page.getByPlaceholder("What needs doing?").fill("Write tests");
    await page.getByRole("button", { name: "Add" }).click();

    await expect(
        page.getByRole("button", { name: 'Edit "Write tests"' }),
    ).toBeVisible();
    await expect(page.getByPlaceholder("What needs doing?")).toHaveValue("");
});

test("shows client validation error when submitting empty title", async ({
    page,
}) => {
    await page.getByRole("button", { name: "Add" }).click();

    await expect(page.getByRole("alert")).toContainText("Title is required");
});

test("deletes a todo", async ({ page }) => {
    await expect(
        page.getByRole("button", { name: 'Edit "Buy milk"' }),
    ).toBeVisible();

    await page.getByRole("button", { name: 'Delete "Buy milk"' }).click();

    await expect(
        page.getByRole("button", { name: 'Edit "Buy milk"' }),
    ).not.toBeVisible();
});

test("toggles todo completion via checkbox", async ({ page }) => {
    const checkbox = page.getByRole("checkbox", { name: /Mark "Buy milk"/ });
    await expect(checkbox).not.toBeChecked();

    await checkbox.click();

    await expect(checkbox).toBeChecked();
});

test("edits a todo title inline", async ({ page }) => {
    await page.getByRole("button", { name: 'Edit "Buy milk"' }).click();

    const input = page.locator('input:not([placeholder])');
    await input.clear();
    await input.fill("Buy oat milk");
    await input.press("Enter");

    await expect(
        page.getByRole("button", { name: 'Edit "Buy oat milk"' }),
    ).toBeVisible();
});

test("cancels edit on Escape without saving", async ({ page }) => {
    await page.getByRole("button", { name: 'Edit "Buy milk"' }).click();

    const input = page.locator('input:not([placeholder])');
    await input.fill("something else");
    await input.press("Escape");

    await expect(
        page.getByRole("button", { name: 'Edit "Buy milk"' }),
    ).toBeVisible();
    await expect(
        page.getByRole("button", { name: 'Edit "something else"' }),
    ).not.toBeVisible();
});
