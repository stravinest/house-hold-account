import { cn } from '@/lib/utils';

interface CardProps {
  children: React.ReactNode;
  className?: string;
}

export function Card({ children, className }: CardProps) {
  return (
    <div className={cn('rounded-[16px] border border-card-border bg-white p-6', className)}>
      {children}
    </div>
  );
}

interface CardHeaderProps {
  title: string;
  action?: React.ReactNode;
}

export function CardHeader({ title, action }: CardHeaderProps) {
  return (
    <div className='mb-4 flex items-center justify-between'>
      <h2 className='text-lg font-bold text-on-surface'>{title}</h2>
      {action}
    </div>
  );
}
