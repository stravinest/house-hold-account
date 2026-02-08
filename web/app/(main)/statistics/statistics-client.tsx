'use client';

import { useState, useCallback } from 'react';
import { TrendingUp, TrendingDown, Wallet, Hash, Calculator } from 'lucide-react';
import { createClient } from '@/lib/supabase/client';
import { formatAmount } from '@/lib/utils';
import type { PeriodType, StatisticsData } from '@/lib/queries/statistics';
import { SummaryCard } from '@/components/shared/SummaryCard';
import { DateNavigation } from '@/components/shared/DateNavigation';
import { UnderlineTabs } from '@/components/shared/UnderlineTabs';
import { UserFilterChips } from '@/components/shared/UserFilterChips';
import { SpendingBarChart } from '@/components/charts/SpendingBarChart';
import { CategoryBreakdownList } from '@/components/charts/CategoryBreakdownList';
import { PaymentMethodBreakdown } from '@/components/charts/PaymentMethodBreakdown';
import { IncomeCategoryBreakdown } from '@/components/charts/IncomeCategoryBreakdown';
import { MemberSpendingComparison } from '@/components/charts/MemberSpendingComparison';

type Member = {
  id: string;
  name: string;
  color: string;
};

type StatTransactionRow = {
  id: string;
  type: string;
  amount: number;
  date: string;
  user_id: string;
  created_at?: string;
  categories: { name: string; icon: string | null; color: string | null } | null;
  payment_methods: { name: string; type: string | null; icon: string | null; color: string | null } | null;
};

type StatisticsClientProps = {
  ledgerId: string;
  currentUserId: string;
  initialPeriod: PeriodType;
  initialDate: string;
  initialDateLabel: string;
  initialData: StatisticsData;
  members: Member[];
};

const PERIOD_TABS = [
  { key: 'day', label: '일' },
  { key: 'week', label: '주' },
  { key: 'month', label: '월' },
  { key: 'year', label: '년' },
];

const TIME_SLOTS = ['오전', '점심', '오후', '저녁', '야간'];
const DAY_NAMES_ORDERED = ['월', '화', '수', '목', '금', '토', '일'];
const DAY_NAMES = ['일', '월', '화', '수', '목', '금', '토'];

function getTimeSlot(hour: number): string {
  if (hour < 6) return '야간';
  if (hour < 11) return '오전';
  if (hour < 14) return '점심';
  if (hour < 18) return '오후';
  return '저녁';
}

function getDateRange(period: PeriodType, date: Date): { start: string; end: string } {
  const y = date.getFullYear();
  const m = date.getMonth();
  const d = date.getDate();

  switch (period) {
    case 'day': {
      const start = `${y}-${String(m + 1).padStart(2, '0')}-${String(d).padStart(2, '0')}`;
      const next = new Date(y, m, d + 1);
      const end = `${next.getFullYear()}-${String(next.getMonth() + 1).padStart(2, '0')}-${String(next.getDate()).padStart(2, '0')}`;
      return { start, end };
    }
    case 'week': {
      const dayOfWeek = date.getDay();
      const mondayOffset = dayOfWeek === 0 ? -6 : 1 - dayOfWeek;
      const monday = new Date(y, m, d + mondayOffset);
      const sunday = new Date(monday.getFullYear(), monday.getMonth(), monday.getDate() + 7);
      const start = `${monday.getFullYear()}-${String(monday.getMonth() + 1).padStart(2, '0')}-${String(monday.getDate()).padStart(2, '0')}`;
      const end = `${sunday.getFullYear()}-${String(sunday.getMonth() + 1).padStart(2, '0')}-${String(sunday.getDate()).padStart(2, '0')}`;
      return { start, end };
    }
    case 'month': {
      const start = `${y}-${String(m + 1).padStart(2, '0')}-01`;
      const nextM = m + 1 === 12 ? 0 : m + 1;
      const nextY = m + 1 === 12 ? y + 1 : y;
      const end = `${nextY}-${String(nextM + 1).padStart(2, '0')}-01`;
      return { start, end };
    }
    case 'year': {
      return { start: `${y}-01-01`, end: `${y + 1}-01-01` };
    }
  }
}

function getPrevDateRange(period: PeriodType, date: Date): { start: string; end: string } {
  switch (period) {
    case 'day': {
      const prev = new Date(date.getFullYear(), date.getMonth(), date.getDate() - 1);
      return getDateRange('day', prev);
    }
    case 'week': {
      const prev = new Date(date.getFullYear(), date.getMonth(), date.getDate() - 7);
      return getDateRange('week', prev);
    }
    case 'month': {
      const prev = new Date(date.getFullYear(), date.getMonth() - 1, 1);
      return getDateRange('month', prev);
    }
    case 'year': {
      const prev = new Date(date.getFullYear() - 1, 0, 1);
      return getDateRange('year', prev);
    }
  }
}

function getDateLabel(period: PeriodType, date: Date): string {
  const y = date.getFullYear();
  const m = date.getMonth() + 1;
  const d = date.getDate();

  switch (period) {
    case 'day':
      return `${y}년 ${m}월 ${d}일`;
    case 'week': {
      const dayOfWeek = date.getDay();
      const mondayOffset = dayOfWeek === 0 ? -6 : 1 - dayOfWeek;
      const monday = new Date(y, date.getMonth(), d + mondayOffset);
      const sunday = new Date(monday.getFullYear(), monday.getMonth(), monday.getDate() + 6);
      const weekNum = Math.ceil(monday.getDate() / 7);
      return `${m}월 ${weekNum}주차 (${monday.getMonth() + 1}/${monday.getDate()}~${sunday.getMonth() + 1}/${sunday.getDate()})`;
    }
    case 'month':
      return `${y}년 ${m}월`;
    case 'year':
      return `${y}년`;
  }
}

function navigateDate(period: PeriodType, date: Date, direction: number): Date {
  switch (period) {
    case 'day':
      return new Date(date.getFullYear(), date.getMonth(), date.getDate() + direction);
    case 'week':
      return new Date(date.getFullYear(), date.getMonth(), date.getDate() + direction * 7);
    case 'month':
      return new Date(date.getFullYear(), date.getMonth() + direction, 1);
    case 'year':
      return new Date(date.getFullYear() + direction, 0, 1);
  }
}

function getComparisonLabel(period: PeriodType): string {
  switch (period) {
    case 'day': return '어제 대비';
    case 'week': return '지난 주 대비';
    case 'month': return '전월 대비';
    case 'year': return '전년 대비';
  }
}

function getThirdLabel(period: PeriodType): string {
  switch (period) {
    case 'day': return '거래 건수';
    case 'week': return '일평균 지출';
    case 'month': return '절약액';
    case 'year': return '연간 저축';
  }
}

function getCardLabels(period: PeriodType) {
  switch (period) {
    case 'day': return { income: '오늘 수입', expense: '오늘 지출' };
    case 'week': return { income: '이번 주 수입', expense: '이번 주 지출' };
    case 'month': return { income: '이번 달 수입', expense: '이번 달 지출' };
    case 'year': return { income: '연간 수입', expense: '연간 지출' };
  }
}

function getChartMeta(period: PeriodType) {
  switch (period) {
    case 'day': return { title: '시간대별 지출', subText: '오늘' };
    case 'week': return { title: '요일별 지출', subText: '이번 주' };
    case 'month': return { title: '주별 수입/지출', subText: '이번 달' };
    case 'year': return { title: '월별 수입/지출 추이', subText: '' };
  }
}

function getDiffText(current: number, previous: number, label: string): string {
  if (previous === 0 && current === 0) return '';
  const diff = current - previous;
  const sign = diff >= 0 ? '+' : '';
  return `${label} ${sign}${formatAmount(diff)}`;
}

function getThirdIcon(period: PeriodType) {
  switch (period) {
    case 'day': return Hash;
    case 'week': return Calculator;
    default: return Wallet;
  }
}

const PM_COLORS = ['#42A5F5', '#FF7043', '#AB47BC', '#FFA726', '#26A69A', '#EC407A'];

export function StatisticsClient({
  ledgerId,
  currentUserId,
  initialPeriod,
  initialDate,
  initialDateLabel,
  initialData,
  members,
}: StatisticsClientProps) {
  const [period, setPeriod] = useState<PeriodType>(initialPeriod);
  const [currentDate, setCurrentDate] = useState(new Date(initialDate));
  const [dateLabel, setDateLabel] = useState(initialDateLabel);
  const [data, setData] = useState<StatisticsData>(initialData);
  const [userFilter, setUserFilter] = useState<string>('all');
  const [loading, setLoading] = useState(false);
  const [fetchError, setFetchError] = useState<string | null>(null);

  const fetchData = useCallback(
    async (p: PeriodType, date: Date, filter: string) => {
      setLoading(true);
      setFetchError(null);
      try {
        const supabase = createClient();
        const { start, end } = getDateRange(p, date);
        const prev = getPrevDateRange(p, date);

        let query = supabase
          .from('transactions')
          .select('*, categories(name, icon, color), payment_methods(name, type, icon, color)')
          .eq('ledger_id', ledgerId)
          .gte('date', start)
          .lt('date', end)
          .order('date', { ascending: false });

        if (filter !== 'all') {
          query = query.eq('user_id', filter);
        }

        let prevQuery = supabase
          .from('transactions')
          .select('id, type, amount, date, user_id')
          .eq('ledger_id', ledgerId)
          .gte('date', prev.start)
          .lt('date', prev.end);

        if (filter !== 'all') {
          prevQuery = prevQuery.eq('user_id', filter);
        }

        const [{ data: txData }, { data: prevTxData }] = await Promise.all([
          query,
          prevQuery,
        ]);
        const txs = txData || [];
        const prevTxs = prevTxData || [];

        const income = txs.filter((t) => t.type === 'income').reduce((s, t) => s + t.amount, 0);
        const expense = txs.filter((t) => t.type === 'expense').reduce((s, t) => s + t.amount, 0);
        const prevIncome = prevTxs.filter((t) => t.type === 'income').reduce((s, t) => s + t.amount, 0);
        const prevExpense = prevTxs.filter((t) => t.type === 'expense').reduce((s, t) => s + t.amount, 0);

        let thirdValue = 0;
        let prevThirdValue = 0;
        switch (p) {
          case 'day':
            thirdValue = txs.length;
            prevThirdValue = prevTxs.length;
            break;
          case 'week':
            thirdValue = Math.round(expense / 7);
            prevThirdValue = Math.round(prevExpense / 7);
            break;
          case 'month':
          case 'year':
            thirdValue = income - expense;
            prevThirdValue = prevIncome - prevExpense;
            break;
        }

        // 차트 데이터
        const chartData: { label: string; value: number }[] = [];
        const expenseTxs = txs.filter((t) => t.type === 'expense');

        switch (p) {
          case 'day': {
            const slotMap: Record<string, number> = {};
            for (const slot of TIME_SLOTS) slotMap[slot] = 0;
            for (const tx of expenseTxs) {
              const timestamp = tx.created_at || tx.date;
              const hour = new Date(timestamp).getHours();
              const slot = getTimeSlot(hour);
              slotMap[slot] = (slotMap[slot] || 0) + tx.amount;
            }
            for (const slot of TIME_SLOTS) {
              chartData.push({ label: slot, value: slotMap[slot] || 0 });
            }
            break;
          }
          case 'week': {
            const dayMap: Record<string, number> = {};
            for (const day of DAY_NAMES_ORDERED) dayMap[day] = 0;
            for (const tx of expenseTxs) {
              const txDate = new Date(tx.date + 'T12:00:00');
              const dayName = DAY_NAMES[txDate.getDay()];
              dayMap[dayName] = (dayMap[dayName] || 0) + tx.amount;
            }
            for (const day of DAY_NAMES_ORDERED) {
              chartData.push({ label: day, value: dayMap[day] || 0 });
            }
            break;
          }
          case 'month': {
            const lastDay = new Date(date.getFullYear(), date.getMonth() + 1, 0).getDate();
            const weekCount = Math.ceil(lastDay / 7);
            for (let w = 1; w <= weekCount; w++) {
              const dayStart = (w - 1) * 7 + 1;
              const dayEnd = Math.min(w * 7, lastDay);
              const weekExpense = expenseTxs
                .filter((tx) => {
                  const txDay = new Date(tx.date + 'T12:00:00').getDate();
                  return txDay >= dayStart && txDay <= dayEnd;
                })
                .reduce((s, t) => s + t.amount, 0);
              chartData.push({ label: `${w}주`, value: weekExpense });
            }
            break;
          }
          case 'year': {
            for (let mo = 1; mo <= 12; mo++) {
              const monthExpense = expenseTxs
                .filter((tx) => {
                  const txDate = new Date(tx.date + 'T12:00:00');
                  return txDate.getMonth() + 1 === mo;
                })
                .reduce((s, t) => s + t.amount, 0);
              chartData.push({ label: `${mo}월`, value: monthExpense });
            }
            break;
          }
        }

        // 카테고리별 지출
        const catExpenseMap: Record<string, number> = {};
        for (const tx of expenseTxs) {
          const row = tx as unknown as StatTransactionRow;
          const name = row.categories?.name || '기타';
          catExpenseMap[name] = (catExpenseMap[name] || 0) + tx.amount;
        }
        const categoryExpense = Object.entries(catExpenseMap)
          .map(([name, value]) => ({ name, value }))
          .sort((a, b) => b.value - a.value);

        // 카테고리별 수입
        const incomeTxs = txs.filter((t) => t.type === 'income');
        const catIncomeMap: Record<string, number> = {};
        for (const tx of incomeTxs) {
          const row = tx as unknown as StatTransactionRow;
          const name = row.categories?.name || '기타';
          catIncomeMap[name] = (catIncomeMap[name] || 0) + tx.amount;
        }
        const totalIncome = income || 1;
        const categoryIncome = Object.entries(catIncomeMap)
          .map(([name, amount]) => ({
            name,
            amount,
            percentage: Math.round((amount / totalIncome) * 100),
          }))
          .sort((a, b) => b.amount - a.amount);

        // 결제수단별 지출
        const pmMap: Record<string, { amount: number; type: string; color: string }> = {};
        for (const tx of expenseTxs) {
          const row = tx as unknown as StatTransactionRow;
          const pmName = row.payment_methods?.name || '현금';
          const pmType = row.payment_methods?.type || 'cash';
          const pmColor = row.payment_methods?.color;
          if (!pmMap[pmName]) {
            pmMap[pmName] = { amount: 0, type: pmType, color: pmColor || '' };
          }
          pmMap[pmName].amount += tx.amount;
        }
        const paymentMethods = Object.entries(pmMap)
          .map(([name, info], idx) => ({
            name,
            amount: info.amount,
            icon: (info.type === 'card' || info.type === 'credit_card' ? 'credit-card' : 'banknote') as 'credit-card' | 'banknote',
            color: info.color || PM_COLORS[idx % PM_COLORS.length],
          }))
          .sort((a, b) => b.amount - a.amount);

        // 멤버별 지출 (members prop 사용)
        const memberMap: Record<string, { amount: number; name: string; color: string }> = {};
        for (const tx of expenseTxs) {
          const uid = tx.user_id;
          if (!memberMap[uid]) {
            const member = members.find((m) => m.id === uid);
            memberMap[uid] = {
              amount: 0,
              name: member?.name || '알 수 없음',
              color: member?.color || '#A8DAB5',
            };
          }
          memberMap[uid].amount += tx.amount;
        }
        const memberSpending = Object.entries(memberMap)
          .map(([uid, info]) => ({
            name: info.name,
            amount: info.amount,
            color: info.color,
            isMe: uid === currentUserId,
          }))
          .sort((a, b) => b.amount - a.amount);

        const chartMeta = getChartMeta(p);

        setData({
          income,
          expense,
          thirdValue,
          thirdLabel: getThirdLabel(p),
          prevIncome,
          prevExpense,
          prevThirdValue,
          comparisonLabel: getComparisonLabel(p),
          chartData,
          chartTitle: chartMeta.title,
          chartSubText: chartMeta.subText,
          categoryExpense,
          categoryIncome,
          paymentMethods,
          memberSpending,
        });
      } catch (err) {
        setFetchError('데이터를 불러오는 중 오류가 발생했습니다.');
        console.error('Failed to fetch statistics data:', err);
      } finally {
        setLoading(false);
      }
    },
    [ledgerId, currentUserId, members]
  );

  const handlePeriodChange = (newPeriod: string) => {
    const p = newPeriod as PeriodType;
    setPeriod(p);
    const newDate = new Date();
    setCurrentDate(newDate);
    setDateLabel(getDateLabel(p, newDate));
    fetchData(p, newDate, userFilter);
  };

  const handleDateChange = (direction: number) => {
    const newDate = navigateDate(period, currentDate, direction);
    setCurrentDate(newDate);
    setDateLabel(getDateLabel(period, newDate));
    fetchData(period, newDate, userFilter);
  };

  const handleFilterChange = (filter: string) => {
    setUserFilter(filter);
    fetchData(period, currentDate, filter);
  };

  const cardLabels = getCardLabels(period);
  const ThirdIcon = getThirdIcon(period);
  const totalMemberExpense = data.memberSpending.reduce((s, m) => s + m.amount, 0);

  return (
    <div className={`flex flex-col gap-6 ${loading ? 'pointer-events-none opacity-60' : ''}`}>
      {fetchError && (
        <div className='rounded-lg border border-expense/20 bg-expense/5 px-4 py-3 text-sm text-expense'>
          {fetchError}
        </div>
      )}
      {/* Period Tabs */}
      <UnderlineTabs
        tabs={PERIOD_TABS}
        activeKey={period}
        onChange={handlePeriodChange}
      />

      {/* Title + Date Navigation */}
      <div className='flex items-center justify-between'>
        <h1 className='text-[22px] font-semibold text-on-surface'>통계</h1>
        <DateNavigation
          label={dateLabel}
          onPrev={() => handleDateChange(-1)}
          onNext={() => handleDateChange(1)}
        />
      </div>

      {/* User Filter */}
      {members.length > 1 && (
        <UserFilterChips
          members={members}
          activeFilter={userFilter}
          onChange={handleFilterChange}
        />
      )}

      {/* Charts Row */}
      <div className='flex flex-col gap-4 md:flex-row md:items-stretch'>
        <SpendingBarChart
          title={data.chartTitle}
          subText={data.chartSubText}
          data={data.chartData}
          mode='single'
        />
        <CategoryBreakdownList
          title='카테고리별 지출 비율'
          data={data.categoryExpense}
        />
      </div>

      {/* Summary Cards */}
      <div className='grid grid-cols-1 gap-4 md:grid-cols-3'>
        <SummaryCard
          icon={TrendingUp}
          iconColor='#2E7D32'
          label={cardLabels.income}
          value={formatAmount(data.income)}
          valueColor='text-income'
          subText={getDiffText(data.income, data.prevIncome, data.comparisonLabel)}
        />
        <SummaryCard
          icon={TrendingDown}
          iconColor='#BA1A1A'
          label={cardLabels.expense}
          value={formatAmount(data.expense)}
          valueColor='text-expense'
          subText={getDiffText(data.expense, data.prevExpense, data.comparisonLabel)}
        />
        <SummaryCard
          icon={ThirdIcon}
          iconColor={period === 'day' ? '#44483E' : '#2E7D32'}
          label={data.thirdLabel}
          value={period === 'day' ? `${data.thirdValue}건` : formatAmount(data.thirdValue)}
          valueColor={period === 'day' ? 'text-on-surface' : 'text-primary'}
          subText={getDiffText(data.thirdValue, data.prevThirdValue, data.comparisonLabel)}
        />
      </div>

      {/* Payment Method + Income Category */}
      <div className='flex flex-col gap-4 md:flex-row md:items-stretch'>
        <PaymentMethodBreakdown data={data.paymentMethods} />
        <IncomeCategoryBreakdown data={data.categoryIncome} />
      </div>

      {/* Member Spending Comparison */}
      {members.length > 1 && (
        <MemberSpendingComparison
          members={data.memberSpending}
          periodLabel={dateLabel}
          total={totalMemberExpense}
        />
      )}
    </div>
  );
}
