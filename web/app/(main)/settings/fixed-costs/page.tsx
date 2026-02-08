import { Repeat, CalendarCheck, Clock, Plus } from 'lucide-react';
import { formatAmount } from '@/lib/utils';
import { BackLink } from '@/components/shared/BackLink';
import { SummaryCard } from '@/components/shared/SummaryCard';

// 더미 데이터 (UI 전용)
const dummyFixedCosts = [
  {
    id: '1',
    name: '월세',
    amount: 500000,
    dueDay: 25,
    category: '주거',
    isPaid: true,
  },
  {
    id: '2',
    name: '통신비',
    amount: 55000,
    dueDay: 15,
    category: '통신',
    isPaid: true,
  },
  {
    id: '3',
    name: '구독 서비스',
    amount: 14900,
    dueDay: 1,
    category: '구독',
    isPaid: false,
  },
  {
    id: '4',
    name: '보험료',
    amount: 120000,
    dueDay: 10,
    category: '보험',
    isPaid: false,
  },
];

export default function FixedCostsPage() {
  const totalMonthly = dummyFixedCosts.reduce((sum, item) => sum + item.amount, 0);
  const paidCount = dummyFixedCosts.filter((item) => item.isPaid).length;
  const nextDue = dummyFixedCosts
    .filter((item) => !item.isPaid)
    .sort((a, b) => a.dueDay - b.dueDay)[0];

  return (
    <div className='flex flex-col gap-6'>
      <BackLink href='/settings' label='설정' />
      <div className='flex items-center justify-between'>
        <h1 className='text-[22px] font-semibold text-on-surface'>고정비 관리</h1>
        <button className='flex items-center gap-2 rounded-[10px] bg-primary px-4 py-2.5 text-sm font-semibold text-white transition-colors hover:bg-primary/90'>
          <Plus size={16} />
          고정비 추가
        </button>
      </div>

      {/* Summary Cards */}
      <div className='grid grid-cols-1 gap-4 md:grid-cols-3'>
        <SummaryCard
          icon={Repeat}
          iconColor='#2E7D32'
          label='월 고정비 합계'
          value={formatAmount(totalMonthly)}
          valueColor='text-primary'
        />
        <SummaryCard
          icon={CalendarCheck}
          iconColor='#42A5F5'
          label='납부 완료'
          value={`${paidCount} / ${dummyFixedCosts.length}건`}
          valueColor='text-on-surface'
        />
        <SummaryCard
          icon={Clock}
          iconColor='#FF7043'
          label='다음 납부일'
          value={nextDue ? `매월 ${nextDue.dueDay}일` : '-'}
          valueColor='text-on-surface'
          subText={nextDue ? nextDue.name : undefined}
        />
      </div>

      {/* Fixed Cost List */}
      <div className='rounded-[16px] border border-card-border bg-white p-6'>
        <h2 className='mb-4 text-[15px] font-semibold text-on-surface'>고정비 목록</h2>
        <div className='flex flex-col'>
          {dummyFixedCosts.map((item) => (
            <div
              key={item.id}
              className='flex items-center justify-between border-b border-separator py-3 last:border-b-0'
            >
              <div className='flex items-center gap-3'>
                <Repeat size={18} className='text-on-surface-variant' />
                <div>
                  <p className='text-sm font-medium text-on-surface'>{item.name}</p>
                  <p className='text-xs text-on-surface-variant'>
                    {item.category} / 매월 {item.dueDay}일
                  </p>
                </div>
              </div>
              <div className='flex items-center gap-3'>
                <span className='text-sm font-semibold text-on-surface'>
                  {formatAmount(item.amount)}
                </span>
                <span
                  className={`rounded-[8px] px-2.5 py-1 text-xs font-semibold ${
                    item.isPaid
                      ? 'bg-green-50 text-primary'
                      : 'bg-orange-50 text-orange-600'
                  }`}
                >
                  {item.isPaid ? '납부 완료' : '미납'}
                </span>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
