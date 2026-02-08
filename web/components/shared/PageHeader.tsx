import { type LucideIcon } from 'lucide-react';

type PageHeaderProps = {
  title: string;
  actionLabel?: string;
  actionIcon?: LucideIcon;
  onAction?: () => void;
  actionHref?: string;
};

export function PageHeader({
  title,
  actionLabel,
  actionIcon: ActionIcon,
  onAction,
}: PageHeaderProps) {
  return (
    <div className='flex items-center justify-between'>
      <h1 className='text-[22px] font-semibold text-on-surface'>{title}</h1>
      {actionLabel ? (
        <button
          onClick={onAction}
          className='flex items-center gap-2 rounded-[10px] bg-primary px-4 py-2.5 text-sm font-semibold text-white transition-colors hover:bg-primary/90'
        >
          {ActionIcon ? <ActionIcon size={16} /> : null}
          {actionLabel}
        </button>
      ) : null}
    </div>
  );
}
