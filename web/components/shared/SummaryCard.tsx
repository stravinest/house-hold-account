import { type LucideIcon } from 'lucide-react';

type SummaryCardProps = {
  icon: LucideIcon;
  iconColor: string;
  label: string;
  value: string;
  valueColor?: string;
  subText?: string;
};

export function SummaryCard({
  icon: Icon,
  iconColor,
  label,
  value,
  valueColor = 'text-on-surface',
  subText,
}: SummaryCardProps) {
  return (
    <div className='flex flex-col gap-3 rounded-[16px] border border-card-border bg-white p-6'>
      <div className='flex items-center gap-2'>
        <Icon size={18} style={{ color: iconColor }} />
        <span className='text-sm text-on-surface-variant'>{label}</span>
      </div>
      <p className={`text-2xl font-bold ${valueColor}`}>{value}</p>
      {subText ? (
        <p className='text-xs text-on-surface-variant'>{subText}</p>
      ) : null}
    </div>
  );
}
