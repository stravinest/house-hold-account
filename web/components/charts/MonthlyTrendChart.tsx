'use client';

import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  Legend,
} from 'recharts';
import { formatAmountShort } from '@/lib/utils';

type MonthlyData = {
  month: string;
  income: number;
  expense: number;
};

export function MonthlyTrendChart({ data }: { data: MonthlyData[] }) {
  if (data.length === 0) {
    return (
      <div className='flex flex-col items-center justify-center rounded-xl bg-white p-6 shadow-sm'>
        <h2 className='mb-4 text-lg font-bold text-gray-900'>월별 추이</h2>
        <p className='text-sm text-gray-400'>데이터가 없습니다</p>
      </div>
    );
  }

  return (
    <div className='rounded-xl bg-white p-6 shadow-sm'>
      <h2 className='mb-4 text-lg font-bold text-gray-900'>월별 추이</h2>
      <div className='h-72'>
        <ResponsiveContainer width='100%' height='100%'>
          <LineChart data={data}>
            <CartesianGrid strokeDasharray='3 3' stroke='#F3F4F6' />
            <XAxis
              dataKey='month'
              tick={{ fontSize: 12, fill: '#6B7280' }}
              axisLine={{ stroke: '#E5E7EB' }}
            />
            <YAxis
              tickFormatter={formatAmountShort}
              tick={{ fontSize: 12, fill: '#6B7280' }}
              axisLine={{ stroke: '#E5E7EB' }}
            />
            <Tooltip
              formatter={(value: number, name: string) => [
                `${value.toLocaleString('ko-KR')}원`,
                name === 'income' ? '수입' : '지출',
              ]}
              contentStyle={{
                borderRadius: '8px',
                border: 'none',
                boxShadow: '0 2px 8px rgba(0,0,0,0.1)',
              }}
            />
            <Legend
              formatter={(value: string) => (
                <span className='text-sm text-gray-600'>
                  {value === 'income' ? '수입' : '지출'}
                </span>
              )}
            />
            <Line
              type='monotone'
              dataKey='income'
              stroke='#2E7D32'
              strokeWidth={2}
              dot={{ fill: '#2E7D32', r: 4 }}
              activeDot={{ r: 6 }}
            />
            <Line
              type='monotone'
              dataKey='expense'
              stroke='#BA1A1A'
              strokeWidth={2}
              dot={{ fill: '#BA1A1A', r: 4 }}
              activeDot={{ r: 6 }}
            />
          </LineChart>
        </ResponsiveContainer>
      </div>
    </div>
  );
}
