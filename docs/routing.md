# Routing with TanStack Router

The frontend uses [TanStack Router](https://tanstack.com/router/latest) v1 with file-based routing. Routes are defined by files in `frontend/src/routes/`; the Vite plugin watches that directory and regenerates `routeTree.gen.ts` automatically on every save.

## Setup

`TanStackRouterVite()` in `frontend/vite.config.ts` enables the plugin:

```ts
import { TanStackRouterVite } from '@tanstack/router-vite-plugin';

export default defineConfig({
    plugins: [TanStackRouterVite(), react(), tailwindcss()],
    ...
});
```

`frontend/src/main.tsx` creates the router from the generated tree and wraps the app:

```tsx
import { createRouter, RouterProvider } from '@tanstack/react-router';
import { routeTree } from './routeTree.gen';

const router = createRouter({ routeTree });

createRoot(document.getElementById('root')!).render(
    <StrictMode>
        <QueryClientProvider client={queryClient}>
            <RouterProvider router={router} />
        </QueryClientProvider>
    </StrictMode>
);
```

## File-based routing conventions

| File | URL | Purpose |
|------|-----|---------|
| `routes/__root.tsx` | all routes | Shell layout: nav, `<Outlet />`, `ErrorBoundary`, `Toaster` |
| `routes/index.tsx` | `/` | Home page |
| `routes/$.tsx` | `/*` | 404 catch-all |
| `routes/<name>.tsx` | `/<name>` | Feature page |

Every route file must export a `Route` constant created with the matching factory:

```tsx
// routes/products.tsx → /products
import { createFileRoute } from '@tanstack/react-router';

export const Route = createFileRoute('/products')({
    component: ProductsPage,
});

function ProductsPage() { ... }
```

`routeTree.gen.ts` is auto-generated — never edit it by hand.

## Adding a page

Use `/scaffold-page` to automate this. To do it manually:

1. **Create** `frontend/src/routes/<name>.tsx` using `createFileRoute('/<name>')`.
2. **Add a nav link** in `routes/__root.tsx`. Import `Link` from `@tanstack/react-router` and add it to the `<nav>` element.
3. **Create a Playwright smoke test** in `tests/Dostar.UITests/tests/<name>.spec.ts`.

The Vite plugin picks up the new file and updates `routeTree.gen.ts` automatically — no manual registration step.

## Root shell layout

`routes/__root.tsx` wraps every page with the shared chrome:

```tsx
import { createRootRoute, Link, Outlet } from '@tanstack/react-router';
import { ErrorBoundary } from '@/shared/components/common/ErrorBoundary';
import { Toaster } from '@/shared/components/ui/sonner';

export const Route = createRootRoute({ component: RootLayout });

function RootLayout() {
    return (
        <>
            <nav className="border-b bg-background px-8 py-4 flex items-center gap-6">
                <h1 className="text-lg font-semibold text-foreground">Dostar</h1>
                <Link
                    to="/products"
                    className="text-sm text-muted-foreground hover:text-foreground [&.active]:text-foreground [&.active]:font-medium"
                >
                    Products
                </Link>
            </nav>
            <main className="min-h-screen bg-background p-8">
                <ErrorBoundary>
                    <Outlet />
                </ErrorBoundary>
            </main>
            <Toaster />
            {import.meta.env.DEV && <TanStackRouterDevtools />}
        </>
    );
}
```

TanStack Router automatically adds the `active` CSS class to `<Link>` elements whose `to` path matches the current URL. Use `[&.active]:` Tailwind variants to style active links.

## PageHeader component

`shared/components/common/PageHeader.tsx` provides a consistent page heading. Use it at the top of every page component:

```tsx
import { PageHeader } from '@/shared/components/common/PageHeader';

function ProductsPage() {
    return (
        <div className="mx-auto max-w-lg space-y-6">
            <PageHeader title="Products" description="Manage your product catalogue" />
            <ProductList />
        </div>
    );
}
```

`PageHeader` renders an `<h2>` (subordinate to the `<h1>` brand name in the nav) and an optional description paragraph.

## TanStack Router + TanStack Query integration

Routes can pre-fetch data using the `loader` option, making the data available before the component renders:

```tsx
import { createFileRoute } from '@tanstack/react-router';
import { queryClient } from '@/shared/api/queryClient';

export const Route = createFileRoute('/products')({
    loader: () =>
        queryClient.ensureQueryData({
            queryKey: ['products'],
            queryFn: () => apiClient<ProductDto[]>('/api/products'),
        }),
    component: ProductsPage,
});
```

Without a loader, use `useQuery` inside the component as normal — see [tanstack-query.md](tanstack-query.md) for that pattern.

## Navigation

Use the typed `Link` component for all in-app navigation:

```tsx
import { Link } from '@tanstack/react-router';

// Navigates to /products — TypeScript-checked at compile time
<Link to="/products">Products</Link>

// Navigates to /products/123
<Link to="/products/$id" params={{ id: '123' }}>View product</Link>
```

For programmatic navigation, use `useNavigate`:

```tsx
import { useNavigate } from '@tanstack/react-router';

const navigate = useNavigate();
await navigate({ to: '/products' });
```
