import type { JSX } from 'react';
import { zodResolver } from '@hookform/resolvers/zod';
import { useForm } from 'react-hook-form';
import { toast } from 'sonner';
import { z } from 'zod';
import { Button } from '@/shared/components/ui/button';
import { Input } from '@/shared/components/ui/input';
import { useCreateTodo } from '@/features/todos/hooks/useTodos';
import { mapProblemDetailsErrors } from '@/shared/lib/mapProblemDetailsErrors';

const schema = z.object({
    title: z.string().min(1, 'Title is required').max(200, 'Title must be 200 characters or fewer'),
});

type FormValues = z.infer<typeof schema>;

export function CreateTodoForm(): JSX.Element {
    const createTodo = useCreateTodo();
    const {
        register,
        handleSubmit,
        reset,
        setError,
        formState: { errors, isSubmitting },
    } = useForm<FormValues>({ resolver: zodResolver(schema) });

    async function submit(values: FormValues) {
        try {
            await createTodo.mutateAsync({ title: values.title });
            reset();
            toast.success('Todo created');
        } catch (err) {
            mapProblemDetailsErrors(err, setError);
        }
    }

    return (
        <form onSubmit={handleSubmit(submit)}>
            <div className="flex gap-2">
                <div className="flex-1">
                    <Input
                        {...register('title')}
                        placeholder="What needs doing?"
                        disabled={isSubmitting}
                    />
                    {errors.title && (
                        <p className="mt-1 text-sm text-destructive" role="alert">
                            {errors.title.message}
                        </p>
                    )}
                    {errors.root && (
                        <p className="mt-1 text-sm text-destructive" role="alert">
                            {errors.root.message}
                        </p>
                    )}
                </div>
                <Button type="submit" disabled={isSubmitting}>
                    {isSubmitting ? 'Adding…' : 'Add'}
                </Button>
            </div>
        </form>
    );
}
