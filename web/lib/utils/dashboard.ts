export type PeriodType = 'day' | 'week' | 'month' | 'year';
export type TypeFilter = 'all' | 'income' | 'expense';

export type DashboardTransaction = {
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

export type CategoryDataItem = {
  name: string;
  value: number;
  color: string;
};

export type DashboardSummary = {
  income: number;
  expense: number;
  balance: number;
};

// typeFilter에 따라 요약 카드에 표시할 값을 계산
export function getFilteredSummary(
  summary: DashboardSummary,
  filter: TypeFilter,
): DashboardSummary {
  switch (filter) {
    case 'income':
      return { income: summary.income, expense: 0, balance: summary.income };
    case 'expense':
      return { income: 0, expense: summary.expense, balance: -summary.expense };
    default:
      return summary;
  }
}

// typeFilter에 따라 차트 데이터 필터링
export function getFilteredChartData(
  data: { label: string; income: number; expense: number }[],
  filter: TypeFilter,
): { label: string; income: number; expense: number }[] {
  switch (filter) {
    case 'income':
      return data.map((d) => ({ ...d, expense: 0 }));
    case 'expense':
      return data.map((d) => ({ ...d, income: 0 }));
    default:
      return data;
  }
}

// typeFilter에 따라 차트 모드 결정
export function getChartMode(filter: TypeFilter): 'single' | 'dual' {
  return filter === 'all' ? 'dual' : 'single';
}

// typeFilter에 따라 차트 제목 결정
export function getChartTitle(period: PeriodType, filter: TypeFilter): string {
  const typeLabel = filter === 'income' ? '수입' : filter === 'expense' ? '지출' : '수입/지출';
  switch (period) {
    case 'day': return `시간대별 ${typeLabel}`;
    case 'week': return `요일별 ${typeLabel}`;
    case 'month': return `주별 ${typeLabel}`;
    case 'year': return `월별 ${typeLabel}`;
  }
}

// typeFilter에 따라 거래 목록 필터링
export function getFilteredTransactions(
  transactions: DashboardTransaction[],
  filter: TypeFilter,
): DashboardTransaction[] {
  if (filter === 'all') return transactions;
  return transactions.filter((tx) => tx.type === filter);
}

export type MemberInfo = {
  id: string;
  name: string;
  color: string;
};

export type BreakdownItem = {
  name: string;
  color: string;
  value: number;
};

export type UserBreakdownResult = {
  income: BreakdownItem[];
  expense: BreakdownItem[];
  balance: BreakdownItem[];
};

// 유저별 수입/지출/합계 분류 계산
export function getUserBreakdowns(
  transactions: DashboardTransaction[],
  members: MemberInfo[],
): UserBreakdownResult {
  const incomeMap: Record<string, number> = {};
  const expenseMap: Record<string, number> = {};

  for (const tx of transactions) {
    const authorName = tx.authorName || '';
    if (tx.type === 'income') {
      incomeMap[authorName] = (incomeMap[authorName] || 0) + tx.amount;
    } else if (tx.type === 'expense') {
      expenseMap[authorName] = (expenseMap[authorName] || 0) + tx.amount;
    }
  }

  return {
    income: members.map((m) => ({ name: m.name, color: m.color, value: incomeMap[m.name] || 0 })),
    expense: members.map((m) => ({ name: m.name, color: m.color, value: expenseMap[m.name] || 0 })),
    balance: members.map((m) => ({
      name: m.name,
      color: m.color,
      value: (incomeMap[m.name] || 0) - (expenseMap[m.name] || 0),
    })),
  };
}

// 날짜 라벨 생성
export function getDateLabel(period: PeriodType, date: Date): string {
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

// 날짜 이동
export function navigateDate(period: PeriodType, date: Date, direction: number): Date {
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
