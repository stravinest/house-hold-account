'use client';

import { formatAmount } from '@/lib/utils';

type TopExpenseItem = {
  id?: string;
  description: string;
  amount: number;
  categoryName: string;
  authorName?: string;
  isFixedExpense?: boolean;
};

type CategoryDataItem = {
  name: string;
  value: number;
  color: string;
};

type TopSpendingSectionProps = {
  topExpenses: TopExpenseItem[];
  categoryData: CategoryDataItem[];
};

export function TopSpendingSection({ topExpenses, categoryData }: TopSpendingSectionProps) {
  const top5Categories = categoryData.slice(0, 5);

  return (
    <div className='flex flex-col overflow-hidden rounded-[16px] border border-card-border bg-white md:flex-row'>
      {/* 주요 지출 TOP 5 */}
      <div className='flex flex-1 flex-col gap-4 border-b border-card-border p-6 md:border-b-0 md:border-r'>
        <h3 className='text-[16px] font-semibold text-on-surface'>주요 지출 TOP 5</h3>
        <div className='flex flex-col'>
          {topExpenses.length > 0 ? (
            topExpenses.map((tx, index) => (
              <div
                key={tx.id || index}
                className={`flex items-center justify-between py-3 ${
                  index < topExpenses.length - 1 ? 'border-b border-[#F5F5F3]' : ''
                }`}
              >
                <div className='flex items-center gap-3'>
                  <span className='text-sm font-bold text-income'>{index + 1}</span>
                  <div className='flex flex-col gap-0.5'>
                    <span className='text-sm font-medium text-on-surface'>{tx.description}</span>
                    <span className='text-xs text-on-surface-variant'>
                      {tx.authorName || '-'}
                      {' | '}
                      {tx.isFixedExpense ? '고정비' : '지출'}
                      {tx.categoryName ? ` - ${tx.categoryName}` : ''}
                    </span>
                  </div>
                </div>
                <span className='shrink-0 text-sm font-semibold text-expense'>
                  {formatAmount(-tx.amount)}
                </span>
              </div>
            ))
          ) : (
            <p className='py-8 text-center text-sm text-on-surface-variant'>
              지출 내역이 없습니다
            </p>
          )}
        </div>
      </div>

      {/* 카테고리별 지출 TOP 5 */}
      <div className='flex flex-1 flex-col gap-4 p-6'>
        <h3 className='text-[16px] font-semibold text-on-surface'>카테고리별 지출 TOP 5</h3>
        <div className='flex flex-col'>
          {top5Categories.length > 0 ? (
            top5Categories.map((cat, index) => (
              <div
                key={cat.name}
                className={`flex items-center justify-between py-3 ${
                  index < top5Categories.length - 1 ? 'border-b border-[#F5F5F3]' : ''
                }`}
              >
                <div className='flex items-center gap-2.5'>
                  <span className='text-sm font-bold text-income'>{index + 1}</span>
                  <span
                    className='h-2 w-2 shrink-0 rounded-[4px]'
                    style={{ backgroundColor: cat.color }}
                  />
                  <span className='text-sm font-medium text-on-surface'>{cat.name}</span>
                </div>
                <span className='shrink-0 text-sm font-semibold text-expense'>
                  {formatAmount(-cat.value)}
                </span>
              </div>
            ))
          ) : (
            <p className='py-8 text-center text-sm text-on-surface-variant'>
              지출 내역이 없습니다
            </p>
          )}
        </div>
      </div>
    </div>
  );
}
