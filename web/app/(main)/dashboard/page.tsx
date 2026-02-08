import { redirect } from 'next/navigation';
import { getCurrentUserLedger } from '@/lib/queries/ledger';
import { getMonthSummary, getTransactions } from '@/lib/queries/transaction';
import { DashboardClient } from './dashboard-client';

export default async function DashboardPage() {
  const ledgerInfo = await getCurrentUserLedger();

  if (!ledgerInfo?.ledger) {
    redirect('/login');
  }

  const ledgerId = ledgerInfo.ledger.id;
  const now = new Date();
  const year = now.getFullYear();
  const month = now.getMonth() + 1;

  const [summary, recentTransactions] = await Promise.all([
    getMonthSummary(ledgerId, year, month),
    getTransactions(ledgerId, { limit: 10 }),
  ]);

  // 카테고리별 지출 집계
  const expenseTransactions = await getTransactions(ledgerId, { year, month, type: 'expense' });
  const categoryMap: Record<string, number> = {};
  for (const tx of expenseTransactions as any[]) {
    const catName = tx.categories?.name || '기타';
    categoryMap[catName] = (categoryMap[catName] || 0) + tx.amount;
  }
  const categoryData = Object.entries(categoryMap)
    .map(([name, value]) => ({ name, value }))
    .sort((a, b) => b.value - a.value);

  // 최근 6개월 차트 데이터
  const chartData = [];
  for (let i = 5; i >= 0; i--) {
    const targetMonth = month - i;
    const targetYear = targetMonth <= 0 ? year - 1 : year;
    const adjustedMonth = targetMonth <= 0 ? targetMonth + 12 : targetMonth;
    const s = await getMonthSummary(ledgerId, targetYear, adjustedMonth);
    chartData.push({
      label: `${adjustedMonth}월`,
      income: s.income,
      expense: s.expense,
    });
  }

  // 직렬화
  const serializedTransactions = recentTransactions.map((tx: any) => ({
    id: tx.id,
    description: tx.title,
    amount: tx.amount,
    type: tx.type as string,
    date: tx.date,
    categoryName: tx.categories?.name || '',
    categoryIcon: tx.categories?.icon || '',
  }));

  return (
    <DashboardClient
      ledgerId={ledgerId}
      initialYear={year}
      initialMonth={month}
      initialData={{
        income: summary.income,
        expense: summary.expense,
        balance: summary.balance,
        transactions: serializedTransactions,
        categoryData,
        chartData,
      }}
    />
  );
}
