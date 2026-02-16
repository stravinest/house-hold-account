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

type IncomeCategoryItem = {
  name: string;
  amount: number;
  percentage: number;
};

type IncomeCategoryBreakdownProps = {
  data: IncomeCategoryItem[];
  onCategoryClick?: (categoryName: string, color: string, percentage: number) => void;
};

export function IncomeCategoryBreakdown({ data, onCategoryClick }: IncomeCategoryBreakdownProps) {
  const isClickable = !!onCategoryClick;

  return (
    <div className='flex w-full flex-col rounded-[16px] border border-card-border bg-white p-6 md:w-[320px]'>
      <div className='mb-4 flex items-center justify-between'>
        <h3 className='text-[15px] font-semibold text-on-surface'>카테고리별 수입</h3>
        {isClickable && data.length > 0 && (
          <span className='text-[11px] text-on-surface-variant'>클릭하여 상세 보기</span>
        )}
      </div>
      <div className='flex flex-col gap-3'>
        {data.length > 0 ? (
          data.map((item, index) => (
            <div
              key={item.name}
              className={`flex items-center justify-between ${isClickable ? 'cursor-pointer rounded-lg px-1 py-1 transition-colors hover:bg-[#F5F5F3]' : ''}`}
              onClick={() => onCategoryClick?.(item.name, COLORS[index % COLORS.length], item.percentage)}
            >
              <div className='flex items-center gap-2'>
                <div
                  className='h-[10px] w-[10px] rounded-full'
                  style={{ backgroundColor: COLORS[index % COLORS.length] }}
                />
                <span className='text-[13px] text-on-surface'>{item.name}</span>
              </div>
              <div className='flex items-center gap-3'>
                <span className='text-xs text-on-surface-variant'>{item.percentage}%</span>
                <span className='text-[13px] text-income'>{formatAmount(item.amount)}</span>
              </div>
            </div>
          ))
        ) : (
          <p className='py-4 text-center text-sm text-on-surface-variant'>
            데이터가 없습니다
          </p>
        )}
      </div>
    </div>
  );
}
