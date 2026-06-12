# Frontend patterns

The frontend is a standalone React + Vite + TypeScript app in `frontend/`.

## UI library

[shadcn/ui](https://ui.shadcn.com) components live in `src/shared/components/ui/`. They are **owned source** — copy-pasted into the repo by the shadcn CLI, not imported from an npm package. Customise them freely.

Add more components with:

```bash
pnpm dlx shadcn@latest add <component-name>
```

## Styling

Tailwind v4 via the `@tailwindcss/vite` plugin (no `tailwind.config.js` needed). Design tokens are CSS variables in `src/index.css` under `:root` / `.dark`, mapped to Tailwind utility classes via `@theme inline`.

The `cn()` helper in `src/shared/lib/utils.ts` merges class names safely:

```ts
import { cn } from '@/shared/lib/utils';
cn('px-4', condition && 'bg-primary'); // merges + deduplicates
```

## API communication

See [tanstack-query.md](tanstack-query.md) for data fetching patterns.
See [forms.md](forms.md) for form validation patterns.
See [orval.md](orval.md) for generated API client usage.
