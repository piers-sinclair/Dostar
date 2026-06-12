import * as React from 'react';
import * as LabelPrimitive from '@radix-ui/react-label';
import { cva, type VariantProps } from 'class-variance-authority';

import { cn } from '@/shared/lib/utils';

const labelVariants = cva(
    'text-sm font-medium leading-none peer-disabled:cursor-not-allowed peer-disabled:opacity-70'
);

function Label({
    className,
    ref,
    ...props
}: React.ComponentPropsWithoutRef<typeof LabelPrimitive.Root> &
    VariantProps<typeof labelVariants> &
    React.RefAttributes<React.ElementRef<typeof LabelPrimitive.Root>>): React.JSX.Element {
    return <LabelPrimitive.Root ref={ref} className={cn(labelVariants(), className)} {...props} />;
}

export { Label };
