import { redirect } from 'next/navigation';
import { getCurrentUserLedger } from '@/lib/queries/ledger';
import { getTransactions } from '@/lib/queries/transaction';
import { extractDay } from '@/lib/utils';
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

  const [monthTransactions, recentTransactions] = await Promise.all([
    getTransactions(ledgerId, { year, month }),
    getTransactions(ledgerId, { limit: 10 }),
  ]);

  // 수입/지출 요약
  const income = (monthTransactions as any[])
    .filter((t: any) => t.type === 'income')
    .reduce((sum: number, t: any) => sum + t.amount, 0);
  const expense = (monthTransactions as any[])
    .filter((t: any) => t.type === 'expense')
    .reduce((sum: number, t: any) => sum + t.amount, 0);

  // 카테고리별 지출 집계 (색상 포함)
  const categoryColorMap: Record<string, { value: number; color: string }> = {};
  for (const tx of monthTransactions as any[]) {
    if (tx.type === 'expense') {
      const catName = tx.categories?.name || '기타';
      const catColor = tx.categories?.color || '#78909C';
      if (!categoryColorMap[catName]) categoryColorMap[catName] = { value: 0, color: catColor };
      categoryColorMap[catName].value += tx.amount;
    }
  }
  const categoryData = Object.entries(categoryColorMap)
    .map(([name, { value, color }]) => ({ name, value, color }))
    .sort((a, b) => b.value - a.value);

  // 현재 월의 주별 차트 데이터 (초기 period='month'에 맞춤)
  const lastDay = new Date(year, month, 0).getDate();
  const weekCount = Math.ceil(lastDay / 7);
  const chartData = [];
  for (let w = 1; w <= weekCount; w++) {
    const dayStart = (w - 1) * 7 + 1;
    const dayEnd = Math.min(w * 7, lastDay);
    let weekIncome = 0, weekExpense = 0;
    for (const tx of monthTransactions as any[]) {
      const txDay = extractDay(tx.date);
      if (txDay === null) continue;
      if (txDay >= dayStart && txDay <= dayEnd) {
        if (tx.type === 'income') weekIncome += tx.amount;
        else if (tx.type === 'expense') weekExpense += tx.amount;
      }
    }
    chartData.push({ label: `${w}주`, income: weekIncome, expense: weekExpense });
  }

  // 거래 직렬화 함수
  const serializeTx = (tx: any) => ({
    id: tx.id,
    description: tx.title,
    amount: tx.amount,
    type: tx.type as string,
    date: typeof tx.date === 'string' ? tx.date : String(tx.date),
    categoryName: tx.categories?.name || '',
    categoryIcon: tx.categories?.icon || '',
    categoryColor: tx.categories?.color || undefined,
    authorName: tx.profiles?.display_name || undefined,
    authorColor: tx.profiles?.color || undefined,
    isFixedExpense: tx.is_fixed_expense || false,
  });

  const serializedTransactions = recentTransactions.map(serializeTx);

  // 주요 지출 TOP 5
  const topExpenses = (monthTransactions as any[])
    .filter((t: any) => t.type === 'expense')
    .sort((a: any, b: any) => b.amount - a.amount)
    .slice(0, 5)
    .map(serializeTx);

  return (
    <DashboardClient
      ledgerId={ledgerId}
      initialYear={year}
      initialMonth={month}
      initialData={{
        income,
        expense,
        balance: income - expense,
        transactions: serializedTransactions,
        topExpenses,
        categoryData,
        chartData,
      }}
    />
  );
}
