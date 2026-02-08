'use client';

import { forwardRef, type InputHTMLAttributes } from 'react';
import { cn } from '@/lib/utils';

interface InputProps extends InputHTMLAttributes<HTMLInputElement> {
  label?: string;
  error?: string;
}

export const Input = forwardRef<HTMLInputElement, InputProps>(
  ({ label, error, className, id, ...props }, ref) => {
    return (
      <div className='flex flex-col gap-1.5'>
        {label ? (
          <label htmlFor={id} className='text-[13px] font-medium text-on-surface-variant'>
            {label}
          </label>
        ) : null}
        <input
          ref={ref}
          id={id}
          className={cn(
            'h-[46px] w-full rounded-[10px] bg-[#F8F9FA] px-4 text-sm outline-none',
            'border border-[#E8E8E8] focus:border-primary',
            error && 'border-expense focus:border-expense',
            className,
          )}
          {...props}
        />
        {error ? (
          <p className='text-xs text-expense'>{error}</p>
        ) : null}
      </div>
    );
  },
);

Input.displayName = 'Input';
