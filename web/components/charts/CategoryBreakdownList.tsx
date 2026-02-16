'use client';

import { formatAmount } from '@/lib/utils';

const COLORS = [
  '#2E7D32',
  '#42A5F5',
  '#FF7043',
  '#AB47BC',
  '#FFA726',
  '#26A69A',
  '#EC407A',
  '#78909C',
];

type CategoryItem = {
  name: string;
  value: number;
};

type CategoryBreakdownListProps = {
  title: string;
  data: CategoryItem[];
  onCategoryClick?: (categoryName: string, color: string, percentage: number) => void;
};

export function CategoryBreakdownList({ title, data, onCategoryClick }: CategoryBreakdownListProps) {
  const total = data.reduce((sum, item) => sum + item.value, 0);
  const maxValue = Math.max(...data.map((d) => d.value), 1);
  const isClickable = !!onCategoryClick;

  return (
    <div className='flex flex-1 flex-col rounded-[16px] border border-card-border bg-white p-6'>
      <div className='mb-4 flex items-center justify-between'>
        <h3 className='text-[15px] font-semibold text-on-surface'>{title}</h3>
        {isClickable && data.length > 0 && (
          <span className='text-[11px] text-on-surface-variant'>클릭하여 상세 보기</span>
        )}
      </div>
      <div className='flex flex-col gap-4'>
        {data.length > 0 ? (
          data.map((item, index) => {
            const percent = total > 0 ? Math.round((item.value / total) * 100) : 0;
            const barPercentage = (item.value / maxValue) * 100;
            const color = COLORS[index % COLORS.length];
            return (
              <div
                key={item.name}
                className={`flex flex-col gap-2 ${isClickable ? 'cursor-pointer rounded-lg px-1 py-0.5 transition-colors hover:bg-[#F5F5F3]' : ''}`}
                onClick={() => onCategoryClick?.(item.name, color, percent)}
              >
                <div className='flex items-center justify-between'>
                  <div className='flex items-center gap-2'>
                    <div
                      className='h-2.5 w-2.5 rounded-full'
                      style={{ backgroundColor: color }}
                    />
                    <span className='text-[13px] text-on-surface'>{item.name}</span>
                  </div>
                  <div className='flex items-center gap-3'>
                    <span className='text-xs text-on-surface-variant'>{percent}%</span>
                    <span className='text-[13px] text-expense'>{formatAmount(item.value)}</span>
                  </div>
                </div>
                <div className='h-1.5 w-full rounded-[3px] bg-[#F0F0EC]'>
                  <div
                    className='h-full rounded-[3px] transition-all'
                    style={{
                      width: `${barPercentage}%`,
                      backgroundColor: color,
                    }}
                  />
                </div>
              </div>
            );
          })
        ) : (
          <p className='py-4 text-center text-sm text-on-surface-variant'>
            데이터가 없습니다
          </p>
        )}
      </div>
    </div>
  );
}
