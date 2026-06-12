# Form handling with React Hook Form + Zod

All forms use [React Hook Form](https://react-hook-form.com) with [Zod](https://zod.dev) for schema validation via [@hookform/resolvers](https://github.com/react-hook-form/resolvers).

## Pattern

Define a Zod schema, infer the type, pass `zodResolver(schema)` to `useForm`:

```ts
const schema = z.object({
    title: z.string().min(1, 'Title is required').max(200),
});

type FormValues = z.infer<typeof schema>;

const { register, handleSubmit, formState: { errors } } = useForm<FormValues>({
    resolver: zodResolver(schema),
});
```

## Server-side validation errors

The backend returns RFC 9457 `ProblemDetails` with field errors under `errors`:

```json
{ "errors": { "Title": ["Title is required."] } }
```

`src/shared/lib/mapProblemDetailsErrors.ts` maps these to React Hook Form's `setError`:

```ts
try {
    await onSubmit(values);
} catch (err) {
    mapProblemDetailsErrors(err, setError);
}
```

Field names are normalised to camelCase (backend `Title` → form `title`). If no field errors are present, the message is set on `errors.root`.

## Accessibility

Always render errors with `role="alert"` so screen readers announce them:

```tsx
{errors.title && <p role="alert">{errors.title.message}</p>}
{errors.root && <p role="alert">{errors.root.message}</p>}
```
