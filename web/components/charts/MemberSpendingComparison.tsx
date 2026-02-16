'use client';

import { formatAmount } from '@/lib/utils';

type MemberSpendingItem = {
  name: string;
  amount: number;
  color: string;
  isMe?: boolean;
};

type MemberSpendingComparisonProps = {
  members: MemberSpendingItem[];
  periodLabel: string;
  total: number;
};

export function MemberSpendingComparison({
  members,
  periodLabel,
  total,
}: MemberSpendingComparisonProps) {
  const maxAmount = Math.max(...members.map((m) => m.amount), 1);

  return (
    <div className='rounded-[16px] border border-card-border bg-white p-6'>
      <div className='mb-4 flex items-center justify-between'>
        <h3 className='text-[15px] font-semibold text-on-surface'>멤버별 지출 비교</h3>
        <span className='text-xs text-on-surface-variant'>{periodLabel}</span>
      </div>
      <div className='flex flex-col gap-4'>
        {members.length > 0 ? (
          <>
            {members.map((member) => {
              const barPercentage = (member.amount / maxAmount) * 100;
              const percent = total > 0 ? Math.round((member.amount / total) * 100) : 0;
              return (
                <div key={member.name} className='flex flex-col gap-2'>
                  <div className='flex items-center justify-between'>
                    <div className='flex items-center gap-2'>
                      <div
                        className='h-6 w-6 rounded-full'
                        style={{ backgroundColor: member.color || '#A8DAB5' }}
                      />
                      <span className='text-[13px] text-on-surface'>
                        {member.name}
                        {member.isMe ? ' (나)' : ''}
                      </span>
                    </div>
                    <div className='flex items-center gap-3'>
                      <span className='text-xs text-on-surface-variant'>{percent}%</span>
                      <span className='text-[13px] text-expense'>
                        {formatAmount(member.amount)}
                      </span>
                    </div>
                  </div>
                  <div className='h-2 w-full rounded-[4px] bg-[#F0F0EC]'>
                    <div
                      className='h-full rounded-[4px] transition-all'
                      style={{
                        width: `${barPercentage}%`,
                        backgroundColor: member.color || '#A8DAB5',
                      }}
                    />
                  </div>
                </div>
              );
            })}
            <div className='border-t border-[#F0F0EC] pt-3'>
              <div className='flex items-center justify-between'>
                <span className='text-sm font-medium text-on-surface'>합계</span>
                <span className='text-sm font-bold text-expense'>
                  {formatAmount(total)}
                </span>
              </div>
            </div>
          </>
        ) : (
          <p className='py-4 text-center text-sm text-on-surface-variant'>
            데이터가 없습니다
          </p>
        )}
      </div>
    </div>
  );
}
