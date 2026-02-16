import { type LucideIcon } from 'lucide-react';

export type UserBreakdown = {
  name: string;
  color: string;
  value: string;
};

type SummaryCardProps = {
  icon: LucideIcon;
  iconColor: string;
  label: string;
  value: string;
  valueColor?: string;
  subText?: string;
  userBreakdowns?: UserBreakdown[];
};

export function SummaryCard({
  icon: Icon,
  iconColor,
  label,
  value,
  valueColor = 'text-on-surface',
  subText,
  userBreakdowns,
}: SummaryCardProps) {
  return (
    <div className='flex flex-col gap-2 rounded-[16px] border border-card-border bg-white p-6'>
      <div className='flex items-center gap-2'>
        <Icon size={18} style={{ color: iconColor }} />
        <span className='text-[13px] font-medium text-on-surface-variant'>{label}</span>
      </div>
      <p className={`text-xl font-semibold ${valueColor}`}>{value}</p>
      {userBreakdowns && userBreakdowns.length > 0 && (
        <div className='flex flex-col gap-0.5'>
          {userBreakdowns.slice(0, 4).map((u) => (
            <div key={u.name} className='flex items-center gap-1.5'>
              <div className='flex max-w-[70px] items-center gap-1.5'>
                <span
                  className='inline-block h-2 w-2 shrink-0 rounded-[4px]'
                  style={{ backgroundColor: u.color }}
                />
                <span className='truncate text-[11px] text-on-surface-variant'>{u.name}</span>
              </div>
              <span className='text-[11px] text-on-surface-variant'>{u.value}</span>
            </div>
          ))}
        </div>
      )}
      {subText ? (
        <p className='text-xs text-on-surface-variant'>{subText}</p>
      ) : null}
    </div>
  );
}
