'use client';

import { useState, useCallback } from 'react';
import Link from 'next/link';
import { TrendingUp, TrendingDown, Wallet } from 'lucide-react';
import { createClient } from '@/lib/supabase/client';
import { formatAmount, formatDate, generateChartData } from '@/lib/utils';
import { SummaryCard } from '@/components/shared/SummaryCard';
import { PeriodTabs, type PeriodType } from '@/components/shared/PeriodTabs';
import { DateNavigation } from '@/components/shared/DateNavigation';
import { SpendingBarChart } from '@/components/charts/SpendingBarChart';
import { TopSpendingSection } from '@/components/charts/TopSpendingSection';
import { TransactionDetailModal } from '@/components/shared/TransactionDetailModal';
import { useTransactionDetail } from '@/lib/hooks/useTransactionDetail';

type Transaction = {
  id: string;
  description: string;
  amount: number;
  type: string;
  date: string;
  categoryName: string;
  categoryIcon: string;
  categoryColor?: string;
  authorName?: string;
  authorColor?: string;
  isFixedExpense?: boolean;
};

type TransactionQueryRow = {
  id: string;
  title: string;
  amount: number;
  type: string;
  date: string;
  created_at?: string;
  is_fixed_expense?: boolean;
  categories: { name: string; icon: string | null; color: string | null } | null;
  profiles: { display_name: string | null; color: string | null } | null;
};

type CategoryDataItem = {
  name: string;
  value: number;
  color: string;
};

type DashboardData = {
  income: number;
  expense: number;
  balance: number;
  transactions: Transaction[];
  topExpenses: Transaction[];
  categoryData: CategoryDataItem[];
  chartData: { label: string; income: number; expense: number }[];
};

type DashboardClientProps = {
  ledgerId: string;
  initialData: DashboardData;
  initialYear: number;
  initialMonth: number;
};

function getDateLabel(period: PeriodType, date: Date): string {
  const y = date.getFullYear();
  const m = date.getMonth() + 1;
  const d = date.getDate();

  switch (period) {
    case 'day':
      return `${y}.${String(m).padStart(2, '0')}.${String(d).padStart(2, '0')}`;
    case 'week': {
      const weekEnd = new Date(date);
      weekEnd.setDate(weekEnd.getDate() + 6);
      const em = weekEnd.getMonth() + 1;
      const ed = weekEnd.getDate();
      return `${m}.${String(d).padStart(2, '0')} - ${em}.${String(ed).padStart(2, '0')}`;
    }
    case 'month':
      return `${y}년 ${m}월`;
    case 'year':
      return `${y}년`;
  }
}

function navigateDate(period: PeriodType, date: Date, direction: number): Date {
  const next = new Date(date);
  switch (period) {
    case 'day':
      next.setDate(next.getDate() + direction);
      break;
    case 'week':
      next.setDate(next.getDate() + direction * 7);
      break;
    case 'month':
      next.setMonth(next.getMonth() + direction);
      break;
    case 'year':
      next.setFullYear(next.getFullYear() + direction);
      break;
  }
  return next;
}

function getChartTitle(period: PeriodType): string {
  switch (period) {
    case 'day': return '시간대별 수입/지출';
    case 'week': return '요일별 수입/지출';
    case 'month': return '주별 수입/지출';
    case 'year': return '월별 수입/지출';
  }
}

export function DashboardClient({
  ledgerId,
  initialData,
  initialYear,
  initialMonth,
}: DashboardClientProps) {
  const [period, setPeriod] = useState<PeriodType>('month');
  const [currentDate, setCurrentDate] = useState(
    () => new Date(initialYear, initialMonth - 1, 1)
  );
  const [data, setData] = useState<DashboardData>(initialData);
  const [loading, setLoading] = useState(false);
  const [fetchError, setFetchError] = useState<string | null>(null);
  const {
    selectedTxId,
    detailModalTx,
    detailLoading,
    handleTxClick,
    handleTxDoubleClick,
    closeDetail,
  } = useTransactionDetail();

  const fetchData = useCallback(
    async (p: PeriodType, d: Date) => {
      setLoading(true);
      setFetchError(null);
      try {
        const supabase = createClient();
        const y = d.getFullYear();
        const m = d.getMonth() + 1;
        const day = d.getDate();

        let startDate: string;
        let endDate: string;

        switch (p) {
          case 'day': {
            startDate = `${y}-${String(m).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
            const nextDay = new Date(y, m - 1, day + 1);
            endDate = `${nextDay.getFullYear()}-${String(nextDay.getMonth() + 1).padStart(2, '0')}-${String(nextDay.getDate()).padStart(2, '0')}`;
            break;
          }
          case 'week': {
            const weekEnd = new Date(d);
            weekEnd.setDate(weekEnd.getDate() + 7);
            startDate = `${y}-${String(m).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
            endDate = `${weekEnd.getFullYear()}-${String(weekEnd.getMonth() + 1).padStart(2, '0')}-${String(weekEnd.getDate()).padStart(2, '0')}`;
            break;
          }
          case 'month': {
            startDate = `${y}-${String(m).padStart(2, '0')}-01`;
            const nextMonth = m === 12 ? 1 : m + 1;
            const nextYear = m === 12 ? y + 1 : y;
            endDate = `${nextYear}-${String(nextMonth).padStart(2, '0')}-01`;
            break;
          }
          case 'year':
            startDate = `${y}-01-01`;
            endDate = `${y + 1}-01-01`;
            break;
        }

        const { data: txData, error: txError } = await supabase
          .from('transactions')
          .select('*, categories(name, icon, color), profiles(display_name, color)')
          .eq('ledger_id', ledgerId)
          .gte('date', startDate)
          .lt('date', endDate)
          .order('date', { ascending: false });

        if (txError) throw txError;

        const transactions = txData || [];

        const income = transactions
          .filter((t) => t.type === 'income')
          .reduce((s, t) => s + t.amount, 0);
        const expense = transactions
          .filter((t) => t.type === 'expense')
          .reduce((s, t) => s + t.amount, 0);

        const categoryMap: Record<string, { value: number; color: string }> = {};
        for (const tx of transactions) {
          if (tx.type === 'expense') {
            const row = tx as unknown as TransactionQueryRow;
            const name = row.categories?.name || '기타';
            const color = row.categories?.color || '#78909C';
            if (!categoryMap[name]) categoryMap[name] = { value: 0, color };
            categoryMap[name].value += tx.amount;
          }
        }
        const categoryData: CategoryDataItem[] = Object.entries(categoryMap)
          .map(([name, { value, color }]) => ({ name, value, color }))
          .sort((a, b) => b.value - a.value);

        const serializeTx = (row: TransactionQueryRow): Transaction => ({
          id: row.id,
          description: row.title,
          amount: row.amount,
          type: row.type,
          date: row.date,
          categoryName: row.categories?.name || '',
          categoryIcon: row.categories?.icon || '',
          categoryColor: row.categories?.color || undefined,
          authorName: row.profiles?.display_name || undefined,
          authorColor: row.profiles?.color || undefined,
          isFixedExpense: row.is_fixed_expense || false,
        });

        const serialized = transactions.slice(0, 10).map((tx) =>
          serializeTx(tx as unknown as TransactionQueryRow)
        );

        const topExpenses = transactions
          .filter((t) => t.type === 'expense')
          .sort((a, b) => b.amount - a.amount)
          .slice(0, 5)
          .map((tx) => serializeTx(tx as unknown as TransactionQueryRow));

        const chartData = generateChartData(
          transactions.map((tx) => ({ type: tx.type, amount: tx.amount, date: tx.date })),
          p,
          d,
        );

        setData({
          income,
          expense,
          balance: income - expense,
          transactions: serialized,
          topExpenses,
          categoryData,
          chartData,
        });
      } catch (err) {
        setFetchError('데이터를 불러오는 중 오류가 발생했습니다.');
      } finally {
        setLoading(false);
      }
    },
    [ledgerId]
  );

  const handlePeriodChange = (p: PeriodType) => {
    setPeriod(p);
    fetchData(p, currentDate);
  };

  const handleDateNav = (direction: number) => {
    const next = navigateDate(period, currentDate, direction);
    setCurrentDate(next);
    fetchData(period, next);
  };

  return (
    <div className={`flex flex-col gap-6 ${loading ? 'pointer-events-none opacity-60' : ''}`}>
      {fetchError && (
        <div className='rounded-lg border border-expense/20 bg-expense/5 px-4 py-3 text-sm text-expense'>
          {fetchError}
        </div>
      )}
      {/* Title centered */}
      <h1 className='text-center text-[22px] font-semibold text-on-surface'>대시보드</h1>

      {/* Tabs (left) + Date (right) */}
      <div className='flex items-center justify-between'>
        <PeriodTabs value={period} onChange={handlePeriodChange} />
        <DateNavigation
          label={getDateLabel(period, currentDate)}
          onPrev={() => handleDateNav(-1)}
          onNext={() => handleDateNav(1)}
        />
      </div>

      {/* Summary Cards */}
      <div className='grid grid-cols-1 gap-4 md:grid-cols-3'>
        <SummaryCard
          icon={TrendingUp}
          iconColor='#2E7D32'
          label='수입'
          value={formatAmount(data.income)}
          valueColor='text-income'
        />
        <SummaryCard
          icon={TrendingDown}
          iconColor='#BA1A1A'
          label='지출'
          value={formatAmount(data.expense)}
          valueColor='text-expense'
        />
        <SummaryCard
          icon={Wallet}
          iconColor='#2E7D32'
          label='합계'
          value={formatAmount(data.balance)}
          valueColor='text-primary'
        />
      </div>

      {/* Chart */}
      <SpendingBarChart
        title={getChartTitle(period)}
        data={data.chartData}
        mode='dual'
      />

      {/* Top Spending */}
      <TopSpendingSection
        topExpenses={data.topExpenses}
        categoryData={data.categoryData}
      />

      {/* Recent Transactions */}
      <div className='rounded-[16px] border border-card-border bg-white p-6'>
        <div className='mb-4 flex items-center justify-between'>
          <h2 className='text-[15px] font-semibold text-on-surface'>
            최근 거래
          </h2>
          <Link
            href='/ledger'
            className='text-sm font-medium text-primary hover:underline'
          >
            모두 보기
          </Link>
        </div>
        {data.transactions.length > 0 ? (
          <div className='flex flex-col'>
            {data.transactions.map((tx) => (
              <div
                key={tx.id}
                onClick={() => handleTxClick(tx.id)}
                onDoubleClick={() => handleTxDoubleClick(tx.id)}
                className={`flex cursor-pointer items-center justify-between border-b border-separator border-l-2 py-3 transition-colors last:border-b-0 hover:bg-surface ${
                  selectedTxId === tx.id
                    ? 'border-l-primary bg-primary/5'
                    : 'border-l-transparent'
                }`}
              >
                <div className='flex items-center gap-3'>
                  <div className='flex h-9 w-9 items-center justify-center rounded-full bg-surface-container'>
                    <span className='text-base'>{tx.categoryIcon || ''}</span>
                  </div>
                  <div>
                    <p className='text-sm font-medium text-on-surface'>{tx.description}</p>
                    <p className='text-xs text-on-surface-variant'>
                      {formatDate(tx.date)}
                      {tx.categoryName ? ` / ${tx.categoryName}` : ''}
                    </p>
                  </div>
                </div>
                <div className='flex items-center gap-3'>
                  {tx.authorName && (
                    <span className='flex shrink-0 items-center gap-1.5'>
                      <span
                        className='flex h-5 w-5 shrink-0 items-center justify-center rounded-full text-[10px] font-bold text-white'
                        style={{ backgroundColor: tx.authorColor || '#9E9E9E' }}
                      >
                        {tx.authorName.charAt(0)}
                      </span>
                      <span className='max-w-[60px] truncate text-xs text-on-surface-variant'>{tx.authorName}</span>
                    </span>
                  )}
                  <p
                    className={`text-sm font-semibold ${
                      tx.type === 'income' ? 'text-income' : 'text-expense'
                    }`}
                  >
                    {formatAmount(tx.type === 'expense' ? -tx.amount : tx.amount, true)}
                  </p>
                </div>
              </div>
            ))}
          </div>
        ) : (
          <div className='flex flex-col items-center gap-3 py-12'>
            <p className='text-sm text-on-surface-variant'>거래 내역이 없습니다</p>
            <Link
              href='/ledger'
              className='text-sm font-medium text-primary hover:underline'
            >
              첫 거래를 추가해보세요
            </Link>
          </div>
        )}
      </div>
      <TransactionDetailModal
        open={!!detailModalTx || detailLoading}
        onClose={closeDetail}
        transaction={detailModalTx}
        loading={detailLoading}
      />
    </div>
  );
}
