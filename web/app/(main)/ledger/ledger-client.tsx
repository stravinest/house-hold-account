'use client';

import { useState, useCallback } from 'react';
import { TrendingUp, TrendingDown, Wallet, Plus, Calendar, Download, Upload, ChevronLeft, ChevronRight } from 'lucide-react';
import { createClient } from '@/lib/supabase/client';
import { formatAmount, formatDateTime } from '@/lib/utils';
import { SummaryCard } from '@/components/shared/SummaryCard';
import { TransactionDetailModal } from '@/components/shared/TransactionDetailModal';
import { useTransactionDetail } from '@/lib/hooks/useTransactionDetail';
import { AddTransactionDialog } from '@/components/transaction/AddTransactionDialog';
import { ExportPanel } from '@/components/transaction/ExportPanel';
import { ImportPanel } from '@/components/transaction/ImportPanel';

type Transaction = {
  id: string;
  description: string;
  amount: number;
  type: string;
  date: string;
  createdAt: string;
  categoryName: string;
  categoryIcon: string;
  paymentMethodName: string;
  userName: string;
  userColor: string;
};

type TransactionQueryRow = {
  id: string;
  title: string;
  amount: number;
  type: string;
  date: string;
  created_at: string;
  categories: { name: string; icon: string | null; color: string | null } | null;
  payment_methods: { name: string } | null;
  profiles: { display_name: string | null; color: string | null } | null;
};

type LedgerData = {
  income: number;
  expense: number;
  balance: number;
  transactions: Transaction[];
};

type LedgerClientProps = {
  ledgerId: string;
  initialData: LedgerData;
  initialYear: number;
  initialMonth: number;
};

type FilterType = 'all' | 'income' | 'expense';

export function LedgerClient({
  ledgerId,
  initialData,
  initialYear,
  initialMonth,
}: LedgerClientProps) {
  const [data, setData] = useState<LedgerData>(initialData);
  const [filter, setFilter] = useState<FilterType>('all');
  const [year, setYear] = useState(initialYear);
  const [month, setMonth] = useState(initialMonth);
  const [loading, setLoading] = useState(false);
  const [fetchError, setFetchError] = useState<string | null>(null);
  const [addDialogOpen, setAddDialogOpen] = useState(false);
  const [exportOpen, setExportOpen] = useState(false);
  const [importOpen, setImportOpen] = useState(false);
  const {
    selectedTxId,
    detailModalTx,
    detailLoading,
    handleTxClick,
    handleTxDoubleClick,
    closeDetail,
  } = useTransactionDetail();

  const fetchData = useCallback(
    async (y: number, m: number) => {
      setLoading(true);
      setFetchError(null);
      try {
        const supabase = createClient();
        const startDate = `${y}-${String(m).padStart(2, '0')}-01`;
        const nextMonth = m === 12 ? 1 : m + 1;
        const nextYear = m === 12 ? y + 1 : y;
        const endDate = `${nextYear}-${String(nextMonth).padStart(2, '0')}-01`;

        const { data: txData } = await supabase
          .from('transactions')
          .select('*, categories(name, icon, color), payment_methods(name), profiles(display_name, color)')
          .eq('ledger_id', ledgerId)
          .gte('date', startDate)
          .lt('date', endDate)
          .order('date', { ascending: false });

        const transactions = txData || [];
        const income = transactions
          .filter((t) => t.type === 'income')
          .reduce((s, t) => s + t.amount, 0);
        const expense = transactions
          .filter((t) => t.type === 'expense')
          .reduce((s, t) => s + t.amount, 0);

        const serialized = transactions.map((tx: TransactionQueryRow) => ({
          id: tx.id,
          description: tx.title,
          amount: tx.amount,
          type: tx.type,
          date: tx.date,
          createdAt: tx.created_at || tx.date,
          categoryName: tx.categories?.name || '',
          categoryIcon: tx.categories?.icon || '',
          paymentMethodName: tx.payment_methods?.name || '',
          userName: tx.profiles?.display_name || '',
          userColor: tx.profiles?.color || '#A8D8EA',
        }));

        setData({
          income,
          expense,
          balance: income - expense,
          transactions: serialized,
        });
      } catch (err) {
        setFetchError('데이터를 불러오는 중 오류가 발생했습니다.');
        console.error('Failed to fetch ledger data:', err);
      } finally {
        setLoading(false);
      }
    },
    [ledgerId]
  );

  const handleMonthChange = (direction: number) => {
    let newMonth = month + direction;
    let newYear = year;
    if (newMonth > 12) {
      newMonth = 1;
      newYear += 1;
    } else if (newMonth < 1) {
      newMonth = 12;
      newYear -= 1;
    }
    setMonth(newMonth);
    setYear(newYear);
    fetchData(newYear, newMonth);
  };

  const filteredTransactions = data.transactions.filter((tx) => {
    if (filter === 'all') return true;
    return tx.type === filter;
  });

  return (
    <div className={`flex flex-col gap-6 ${loading ? 'pointer-events-none opacity-60' : ''}`}>
      {fetchError && (
        <div className='rounded-lg border border-expense/20 bg-expense/5 px-4 py-3 text-sm text-expense'>
          {fetchError}
        </div>
      )}
      {/* Header */}
      <div className='flex items-center justify-between'>
        <h1 className='text-[22px] font-semibold text-on-surface'>거래 내역</h1>
        <div className='flex items-center gap-2'>
          <button
            onClick={() => setExportOpen(true)}
            className='flex h-9 items-center gap-1.5 rounded-[8px] bg-tab-bg px-3 text-sm text-on-surface-variant transition-colors hover:bg-surface-container'
            title='내보내기'
          >
            <Download size={16} />
            내보내기
          </button>
          <button
            onClick={() => setImportOpen(true)}
            className='flex h-9 items-center gap-1.5 rounded-[8px] bg-tab-bg px-3 text-sm text-on-surface-variant transition-colors hover:bg-surface-container'
            title='가져오기'
          >
            <Upload size={16} />
            가져오기
          </button>
          <button
            onClick={() => setAddDialogOpen(true)}
            className='flex items-center gap-2 rounded-[10px] bg-primary px-4 py-2 text-sm font-semibold text-white transition-colors hover:bg-primary/90'
          >
            <Plus size={16} />
            거래 추가
          </button>
        </div>
      </div>

      {/* Month Navigation & Filters */}
      <div className='flex flex-col gap-3 md:flex-row md:items-center md:justify-between'>
        <div className='flex items-center gap-2 text-sm text-on-surface-variant'>
          <Calendar size={16} />
          <button
            onClick={() => handleMonthChange(-1)}
            className='flex h-7 w-7 items-center justify-center rounded-[6px] hover:bg-surface-container'
          >
            <ChevronLeft size={14} />
          </button>
          <span className='font-medium text-on-surface'>
            {year}년 {month}월
          </span>
          <button
            onClick={() => handleMonthChange(1)}
            className='flex h-7 w-7 items-center justify-center rounded-[6px] hover:bg-surface-container'
          >
            <ChevronRight size={14} />
          </button>
        </div>

        <div className='flex rounded-[8px] bg-tab-bg p-[2px]'>
          {(['all', 'income', 'expense'] as FilterType[]).map((f) => (
            <button
              key={f}
              onClick={() => setFilter(f)}
              className={`rounded-[8px] px-4 py-1.5 text-sm font-medium transition-all ${
                filter === f
                  ? 'bg-primary text-white'
                  : 'text-on-surface-variant hover:text-on-surface'
              }`}
            >
              {f === 'all' ? '전체' : f === 'income' ? '수입' : '지출'}
            </button>
          ))}
        </div>
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

      {/* Transaction List */}
      <div className='rounded-[16px] border border-card-border bg-white'>
        {filteredTransactions.length > 0 ? (
          <div className='flex flex-col'>
            {filteredTransactions.map((tx) => (
              <div
                key={tx.id}
                onClick={() => handleTxClick(tx.id)}
                onDoubleClick={() => handleTxDoubleClick(tx.id)}
                className={`flex cursor-pointer items-center justify-between border-b border-separator px-6 py-4 transition-colors last:border-b-0 hover:bg-surface ${
                  selectedTxId === tx.id ? 'bg-primary/5' : ''
                }`}
              >
                <div className='flex flex-col gap-1'>
                  <p className='text-sm font-medium text-on-surface'>
                    {tx.description}
                  </p>
                  <div className='flex items-center gap-2 text-xs text-on-surface-variant'>
                    <span>{formatDateTime(tx.createdAt)}</span>
                    {tx.categoryName && (
                      <>
                        <span className='text-separator'>|</span>
                        <span>{tx.categoryName}</span>
                      </>
                    )}
                  </div>
                  {tx.userName && (
                    <div className='flex items-center gap-1.5'>
                      <span
                        className='inline-block h-2.5 w-2.5 rounded-full'
                        style={{ backgroundColor: tx.userColor }}
                      />
                      <span className='text-xs text-on-surface-variant'>
                        {tx.userName}
                      </span>
                    </div>
                  )}
                </div>
                <p
                  className={`text-sm font-semibold whitespace-nowrap ${
                    tx.type === 'income' ? 'text-income' : 'text-expense'
                  }`}
                >
                  {formatAmount(tx.type === 'expense' ? -tx.amount : tx.amount, true)}
                </p>
              </div>
            ))}
          </div>
        ) : (
          <div className='flex flex-col items-center gap-3 py-12'>
            <p className='text-sm text-on-surface-variant'>거래 내역이 없습니다</p>
          </div>
        )}
      </div>

      <TransactionDetailModal
        open={!!detailModalTx || detailLoading}
        onClose={closeDetail}
        transaction={detailModalTx}
        loading={detailLoading}
      />

      <AddTransactionDialog
        open={addDialogOpen}
        onClose={() => setAddDialogOpen(false)}
        ledgerId={ledgerId}
        onSuccess={() => fetchData(year, month)}
      />

      <ExportPanel
        open={exportOpen}
        onClose={() => setExportOpen(false)}
        ledgerId={ledgerId}
      />

      <ImportPanel
        open={importOpen}
        onClose={() => setImportOpen(false)}
        ledgerId={ledgerId}
        onSuccess={() => fetchData(year, month)}
      />
    </div>
  );
}
