'use client';

import { useState, useEffect, useRef, useCallback } from 'react';
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
} from 'recharts';
import { formatAmountShort } from '@/lib/utils';

type ChartDataItem = {
  label: string;
  value?: number;
  income?: number;
  expense?: number;
};

type SpendingBarChartProps = {
  title: string;
  subText?: string;
  data: ChartDataItem[];
  mode?: 'single' | 'dual';
};

export function SpendingBarChart({
  title,
  subText,
  data,
  mode = 'single',
}: SpendingBarChartProps) {
  const containerRef = useRef<HTMLDivElement>(null);
  const [chartWidth, setChartWidth] = useState(0);

  const measure = useCallback(() => {
    if (containerRef.current) {
      setChartWidth(containerRef.current.clientWidth);
    }
  }, []);

  useEffect(() => {
    measure();
    const el = containerRef.current;
    if (!el) return;

    const observer = new ResizeObserver(() => measure());
    observer.observe(el);
    return () => observer.disconnect();
  }, [measure]);

  return (
    <div className='flex flex-1 flex-col rounded-[16px] border border-card-border bg-white p-6'>
      <div className='mb-4 flex items-center justify-between'>
        <h3 className='text-[15px] font-semibold text-on-surface'>{title}</h3>
        {subText ? (
          <span className='text-xs text-on-surface-variant'>{subText}</span>
        ) : null}
      </div>
      <div ref={containerRef} style={{ minHeight: 200 }}>
        {chartWidth > 0 ? (
          <BarChart width={chartWidth} height={200} data={data} barGap={2}>
            <CartesianGrid strokeDasharray='3 3' stroke='#F0F0EC' vertical={false} />
            <XAxis
              dataKey='label'
              tick={{ fontSize: 12, fill: '#44483E' }}
              axisLine={false}
              tickLine={false}
            />
            <YAxis
              tick={{ fontSize: 11, fill: '#44483E' }}
              axisLine={false}
              tickLine={false}
              tickFormatter={(v) => formatAmountShort(v)}
              width={50}
            />
            <Tooltip
              formatter={(value: number, name: string) => {
                const label =
                  name === 'income' ? '수입' : name === 'expense' ? '지출' : '금액';
                return [`${value.toLocaleString('ko-KR')}원`, label];
              }}
              contentStyle={{
                borderRadius: '8px',
                border: '1px solid #F0F0EC',
                fontSize: '13px',
              }}
            />
            {mode === 'dual' ? (
              <>
                <Bar
                  dataKey='income'
                  fill='#2E7D32'
                  radius={[6, 6, 0, 0]}
                  maxBarSize={24}
                  isAnimationActive={false}
                />
                <Bar
                  dataKey='expense'
                  fill='#BA1A1A'
                  radius={[6, 6, 0, 0]}
                  maxBarSize={24}
                  isAnimationActive={false}
                />
              </>
            ) : (
              <Bar
                dataKey='value'
                fill='#A8DAB5'
                radius={[6, 6, 0, 0]}
                maxBarSize={32}
                isAnimationActive={false}
              />
            )}
          </BarChart>
        ) : (
          <div style={{ height: 200 }} />
        )}
      </div>
    </div>
  );
}
