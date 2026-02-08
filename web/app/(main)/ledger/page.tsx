import { redirect } from 'next/navigation';
import { getCurrentUserLedger } from '@/lib/queries/ledger';
import { getTransactions, getMonthSummary } from '@/lib/queries/transaction';
import { LedgerClient } from './ledger-client';

export default async function LedgerPage() {
  const ledgerInfo = await getCurrentUserLedger();

  if (!ledgerInfo?.ledger) {
    redirect('/login');
  }

  const ledgerId = ledgerInfo.ledger.id;
  const now = new Date();
  const year = now.getFullYear();
  const month = now.getMonth() + 1;

  const [transactions, summary] = await Promise.all([
    getTransactions(ledgerId, { year, month }),
    getMonthSummary(ledgerId, year, month),
  ]);

  const serialized = transactions.map((tx: any) => ({
    id: tx.id,
    description: tx.title,
    amount: tx.amount,
    type: tx.type as string,
    date: tx.date,
    createdAt: tx.created_at || tx.date,
    categoryName: tx.categories?.name || '',
    categoryIcon: tx.categories?.icon || '',
    paymentMethodName: tx.payment_methods?.name || '',
    userName: tx.profiles?.display_name || '',
    userColor: tx.profiles?.color || '#A8D8EA',
  }));

  return (
    <LedgerClient
      ledgerId={ledgerId}
      initialYear={year}
      initialMonth={month}
      initialData={{
        income: summary.income,
        expense: summary.expense,
        balance: summary.balance,
        transactions: serialized,
      }}
    />
  );
}
