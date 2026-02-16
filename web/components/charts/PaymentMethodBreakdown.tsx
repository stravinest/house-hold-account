'use client';

import { CreditCard, Banknote } from 'lucide-react';
import { formatAmount } from '@/lib/utils';

type PaymentMethodItem = {
  name: string;
  amount: number;
  icon: 'credit-card' | 'banknote';
  color: string;
};

type PaymentMethodBreakdownProps = {
  data: PaymentMethodItem[];
};

export function PaymentMethodBreakdown({ data }: PaymentMethodBreakdownProps) {
  const maxAmount = Math.max(...data.map((d) => d.amount), 1);
  const totalAmount = data.reduce((sum, d) => sum + d.amount, 0);

  return (
    <div className='flex flex-1 flex-col rounded-[16px] border border-card-border bg-white p-6'>
      <h3 className='mb-4 text-[15px] font-semibold text-on-surface'>결제수단별 지출</h3>
      <div className='flex flex-col gap-4'>
        {data.length > 0 ? (
          data.map((item) => {
            const IconComponent = item.icon === 'credit-card' ? CreditCard : Banknote;
            const barPercentage = (item.amount / maxAmount) * 100;
            const percent = totalAmount > 0 ? Math.round((item.amount / totalAmount) * 100) : 0;
            return (
              <div key={item.name} className='flex flex-col gap-2'>
                <div className='flex items-center justify-between'>
                  <div className='flex items-center gap-2'>
                    <IconComponent size={16} style={{ color: item.color }} />
                    <span className='text-[13px] text-on-surface'>{item.name}</span>
                  </div>
                  <div className='flex items-center gap-3'>
                    <span className='text-xs text-on-surface-variant'>{percent}%</span>
                    <span className='text-[13px] text-expense'>{formatAmount(item.amount)}</span>
                  </div>
                </div>
                <div className='h-1.5 w-full rounded-[3px] bg-[#F0F0EC]'>
                  <div
                    className='h-full rounded-[3px] transition-all'
                    style={{
                      width: `${barPercentage}%`,
                      backgroundColor: item.color,
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
