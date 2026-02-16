'use client';

import { useState, useCallback } from 'react';
import { TrendingUp, TrendingDown, Wallet, Hash, Calculator, Loader2 } from 'lucide-react';
import { formatAmount } from '@/lib/utils';
import type { PeriodType, StatisticsData } from '@/lib/queries/statistics';
import { fetchStatisticsAction, fetchCategoryTopItems } from '@/lib/actions/statistics';
import type { CategoryTopItem } from '@/lib/actions/statistics';
import { SummaryCard } from '@/components/shared/SummaryCard';
import { PeriodTabs } from '@/components/shared/PeriodTabs';
import { DateNavigation } from '@/components/shared/DateNavigation';
import { UserFilterChips } from '@/components/shared/UserFilterChips';
import { SpendingBarChart } from '@/components/charts/SpendingBarChart';
import { CategoryBreakdownList } from '@/components/charts/CategoryBreakdownList';
import { PaymentMethodBreakdown } from '@/components/charts/PaymentMethodBreakdown';
import { IncomeCategoryBreakdown } from '@/components/charts/IncomeCategoryBreakdown';
import { MemberSpendingComparison } from '@/components/charts/MemberSpendingComparison';
import { CategoryDetailPopup } from '@/components/charts/CategoryDetailPopup';

type Member = {
  id: string;
  name: string;
  color: string;
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

function getCardLabels(period: PeriodType) {
  switch (period) {
    case 'day': return { income: '오늘 수입', expense: '오늘 지출' };
    case 'week': return { income: '이번 주 수입', expense: '이번 주 지출' };
    case 'month': return { income: '이번 달 수입', expense: '이번 달 지출' };
    case 'year': return { income: '연간 수입', expense: '연간 지출' };
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

export function StatisticsClient({
  ledgerId,
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

  // Category Detail Popup state
  const [popupState, setPopupState] = useState<{
    open: boolean;
    categoryName: string;
    categoryColor: string;
    categoryPercentage: number;
    type: 'expense' | 'income' | 'asset';
    items: CategoryTopItem[];
    totalAmount: number;
    loading: boolean;
    error: string | null;
  }>({
    open: false,
    categoryName: '',
    categoryColor: '',
    categoryPercentage: 0,
    type: 'expense',
    items: [],
    totalAmount: 0,
    loading: false,
    error: null,
  });

  const fetchData = useCallback(
    async (p: PeriodType, date: Date, filter: string) => {
      setLoading(true);
      setFetchError(null);
      try {
        const result = await fetchStatisticsAction(
          ledgerId,
          p,
          date.toISOString(),
          filter,
        );
        if (result.error) {
          setFetchError(result.error);
          return;
        }
        if (result.data) {
          setData(result.data);
        }
        if (result.dateLabel) {
          setDateLabel(result.dateLabel);
        }
      } catch {
        setFetchError('데이터를 불러오는 중 오류가 발생했습니다.');
      } finally {
        setLoading(false);
      }
    },
    [ledgerId]
  );

  const handlePeriodChange = (p: PeriodType) => {
    setPeriod(p);
    const newDate = new Date();
    setCurrentDate(newDate);
    fetchData(p, newDate, userFilter);
  };

  const handleDateChange = (direction: number) => {
    const newDate = navigateDate(period, currentDate, direction);
    setCurrentDate(newDate);
    fetchData(period, newDate, userFilter);
  };

  const handleFilterChange = (filter: string) => {
    setUserFilter(filter);
    fetchData(period, currentDate, filter);
  };

  const handleCategoryClick = useCallback(
    async (categoryName: string, color: string, percentage: number, type: 'expense' | 'income' | 'asset') => {
      setPopupState({
        open: true,
        categoryName,
        categoryColor: color,
        categoryPercentage: percentage,
        type,
        items: [],
        totalAmount: 0,
        loading: true,
        error: null,
      });

      const result = await fetchCategoryTopItems(
        ledgerId,
        categoryName,
        type,
        period,
        currentDate.toISOString(),
        userFilter,
      );

      setPopupState((prev) => ({
        ...prev,
        items: result.items || [],
        totalAmount: result.totalAmount || 0,
        loading: false,
        error: result.error || null,
      }));
    },
    [ledgerId, period, currentDate, userFilter]
  );

  const cardLabels = getCardLabels(period);
  const ThirdIcon = getThirdIcon(period);
  const totalMemberExpense = data.memberSpending.reduce((s, m) => s + m.amount, 0);

  return (
    <div className='relative flex flex-col gap-6'>
      {loading && (
        <div className='absolute inset-0 z-10 flex items-start justify-center pt-40'>
          <div className='flex items-center gap-2 rounded-full bg-white px-4 py-2 shadow-lg'>
            <Loader2 size={16} className='animate-spin text-primary' />
            <span className='text-sm text-on-surface-variant'>불러오는 중...</span>
          </div>
        </div>
      )}
      {fetchError && (
        <div className='rounded-lg border border-expense/20 bg-expense/5 px-4 py-3 text-sm text-expense'>
          {fetchError}
        </div>
      )}
      {/* tabRow: PeriodTabs + DateNav + UserFilter */}
      <div className='flex items-center justify-between'>
        <PeriodTabs value={period} onChange={handlePeriodChange} />
        <DateNavigation
          label={dateLabel}
          onPrev={() => handleDateChange(-1)}
          onNext={() => handleDateChange(1)}
        />
        {members.length > 1 ? (
          <UserFilterChips
            members={members}
            activeFilter={userFilter}
            onChange={handleFilterChange}
            compact
          />
        ) : (
          <div />
        )}
      </div>

      {/* Charts Row */}
      <div className='flex flex-col gap-4 md:flex-row md:items-stretch'>
        <SpendingBarChart
          title={data.chartTitle}
          subText={data.chartSubText}
          data={data.chartData}
          mode='single'
        />
        <IncomeCategoryBreakdown
          data={data.categoryIncome}
          onCategoryClick={(name, color, pct) => handleCategoryClick(name, color, pct, 'income')}
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
          subText={data.income === 0 && data.prevIncome === 0 ? '수입 없음' : getDiffText(data.income, data.prevIncome, data.comparisonLabel)}
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
          value={
            period === 'day'
              ? `${data.thirdValue}건`
              : period === 'week'
                ? formatAmount(data.thirdValue)
                : `${data.thirdValue >= 0 ? '+' : ''}${formatAmount(data.thirdValue)}`
          }
          valueColor={
            period === 'day'
              ? 'text-on-surface'
              : data.thirdValue >= 0
                ? 'text-income'
                : 'text-expense'
          }
          subText={data.thirdSub || getDiffText(data.thirdValue, data.prevThirdValue, data.comparisonLabel)}
        />
      </div>

      {/* Payment Method + Category Expense */}
      <div className='flex flex-col gap-4 md:flex-row md:items-stretch'>
        <PaymentMethodBreakdown data={data.paymentMethods} />
        <CategoryBreakdownList
          title='카테고리별 지출'
          data={data.categoryExpense}
          onCategoryClick={(name, color, pct) => handleCategoryClick(name, color, pct, 'expense')}
        />
      </div>

      {/* Member Spending Comparison */}
      {members.length > 1 && (
        <MemberSpendingComparison
          members={data.memberSpending}
          periodLabel={dateLabel}
          total={totalMemberExpense}
        />
      )}
      {/* Category Detail Popup */}
      {popupState.open && (
        <CategoryDetailPopup
          categoryName={popupState.categoryName}
          categoryColor={popupState.categoryColor}
          categoryPercentage={popupState.categoryPercentage}
          totalAmount={popupState.totalAmount}
          type={popupState.type}
          items={popupState.items}
          loading={popupState.loading}
          error={popupState.error}
          periodLabel={dateLabel}
          onClose={() => setPopupState((prev) => ({ ...prev, open: false }))}
        />
      )}
    </div>
  );
}
