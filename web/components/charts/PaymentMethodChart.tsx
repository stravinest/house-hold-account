'use client';

import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
} from 'recharts';
import { formatAmountShort } from '@/lib/utils';

type PaymentMethodData = {
  name: string;
  amount: number;
};

export function PaymentMethodChart({ data }: { data: PaymentMethodData[] }) {
  if (data.length === 0) {
    return (
      <div className='flex flex-col items-center justify-center rounded-xl bg-white p-6 shadow-sm'>
        <h2 className='mb-4 text-lg font-bold text-gray-900'>결제수단별 지출</h2>
        <p className='text-sm text-gray-400'>데이터가 없습니다</p>
      </div>
    );
  }

  return (
    <div className='rounded-xl bg-white p-6 shadow-sm'>
      <h2 className='mb-4 text-lg font-bold text-gray-900'>결제수단별 지출</h2>
      <div className='h-72'>
        <ResponsiveContainer width='100%' height='100%'>
          <BarChart data={data} layout='vertical'>
            <CartesianGrid strokeDasharray='3 3' stroke='#F3F4F6' horizontal={false} />
            <XAxis
              type='number'
              tickFormatter={formatAmountShort}
              tick={{ fontSize: 12, fill: '#6B7280' }}
              axisLine={{ stroke: '#E5E7EB' }}
            />
            <YAxis
              type='category'
              dataKey='name'
              tick={{ fontSize: 12, fill: '#6B7280' }}
              axisLine={{ stroke: '#E5E7EB' }}
              width={80}
            />
            <Tooltip
              formatter={(value: number) => [
                `${value.toLocaleString('ko-KR')}원`,
                '지출',
              ]}
              contentStyle={{
                borderRadius: '8px',
                border: 'none',
                boxShadow: '0 2px 8px rgba(0,0,0,0.1)',
              }}
            />
            <Bar dataKey='amount' fill='#2E7D32' radius={[0, 4, 4, 0]} barSize={24} />
          </BarChart>
        </ResponsiveContainer>
      </div>
    </div>
  );
}
