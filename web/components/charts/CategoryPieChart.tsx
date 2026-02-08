'use client';

import { PieChart, Pie, Cell, ResponsiveContainer, Tooltip, Legend } from 'recharts';
import { formatAmountShort } from '@/lib/utils';

const COLORS = ['#2E7D32', '#4CAF50', '#81C784', '#A5D6A7', '#C8E6C9', '#E8F5E9'];

type CategoryData = {
  name: string;
  value: number;
};

export function CategoryPieChart({ data }: { data: CategoryData[] }) {
  if (data.length === 0) {
    return (
      <div className='flex flex-col items-center justify-center rounded-xl bg-white p-6 shadow-sm'>
        <h2 className='mb-4 text-lg font-bold text-gray-900'>카테고리별 지출</h2>
        <p className='text-sm text-gray-400'>데이터가 없습니다</p>
      </div>
    );
  }

  return (
    <div className='rounded-xl bg-white p-6 shadow-sm'>
      <h2 className='mb-4 text-lg font-bold text-gray-900'>카테고리별 지출</h2>
      <div className='h-72'>
        <ResponsiveContainer width='100%' height='100%'>
          <PieChart>
            <Pie
              data={data}
              cx='50%'
              cy='50%'
              innerRadius={60}
              outerRadius={100}
              paddingAngle={2}
              dataKey='value'
            >
              {data.map((entry, index) => (
                <Cell key={entry.name} fill={COLORS[index % COLORS.length]} />
              ))}
            </Pie>
            <Tooltip
              formatter={(value: number) => `${formatAmountShort(value)}원`}
              contentStyle={{
                borderRadius: '8px',
                border: 'none',
                boxShadow: '0 2px 8px rgba(0,0,0,0.1)',
              }}
            />
            <Legend
              formatter={(value: string) => (
                <span className='text-sm text-gray-600'>{value}</span>
              )}
            />
          </PieChart>
        </ResponsiveContainer>
      </div>
    </div>
  );
}
