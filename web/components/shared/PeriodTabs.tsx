'use client';

export type PeriodType = 'day' | 'week' | 'month' | 'year';

const PERIOD_LABELS: Record<PeriodType, string> = {
  day: '일',
  week: '주',
  month: '월',
  year: '년',
};

type PeriodTabsProps = {
  value: PeriodType;
  onChange: (period: PeriodType) => void;
};

export function PeriodTabs({ value, onChange }: PeriodTabsProps) {
  return (
    <div className='flex rounded-[10px] border border-[#EEEEEE] bg-tab-bg p-[3px]'>
      {(Object.keys(PERIOD_LABELS) as PeriodType[]).map((period) => (
        <button
          key={period}
          onClick={() => onChange(period)}
          className={`rounded-[8px] px-4 py-1.5 text-sm font-medium transition-all ${
            value === period
              ? 'bg-white text-on-surface shadow-sm'
              : 'text-on-surface-variant hover:text-on-surface'
          }`}
        >
          {PERIOD_LABELS[period]}
        </button>
      ))}
    </div>
  );
}
