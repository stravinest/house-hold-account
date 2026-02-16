'use client';

import { useState, useCallback, useMemo } from 'react';
import { TrendingUp, TrendingDown, Wallet, Plus, Download, Upload, FileSpreadsheet, Loader2 } from 'lucide-react';
import { createClient } from '@/lib/supabase/client';
import { formatAmount, formatDateTime } from '@/lib/utils';
import { SummaryCard } from '@/components/shared/SummaryCard';
import { PeriodTabs, type PeriodType } from '@/components/shared/PeriodTabs';
import { DateNavigation } from '@/components/shared/DateNavigation';
import { TransactionDetailModal } from '@/components/shared/TransactionDetailModal';
import { useTransactionDetail } from '@/lib/hooks/useTransactionDetail';
import { AddTransactionDialog } from '@/components/transaction/AddTransactionDialog';
import { ExportPanel } from '@/components/transaction/ExportPanel';
import { ImportPanel } from '@/components/transaction/ImportPanel';
import { generateSampleExcel } from '@/lib/utils/excel';
import {
  type TypeFilter,
  getFilteredSummary,
  getFilteredTransactions,
  getDateLabel,
  navigateDate,
} from '@/lib/utils/dashboard';

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

export function LedgerClient({
  ledgerId,
  initialData,
  initialYear,
  initialMonth,
}: LedgerClientProps) {
  const [data, setData] = useState<LedgerData>(initialData);
  const [typeFilter, setTypeFilter] = useState<TypeFilter>('all');
  const [period, setPeriod] = useState<PeriodType>('month');
  const [currentDate, setCurrentDate] = useState(
    () => new Date(initialYear, initialMonth - 1, 1)
  );
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

  const filteredSummary = useMemo(
    () => getFilteredSummary(data, typeFilter),
    [data, typeFilter],
  );
  const filteredTransactions = useMemo(
    () => {
      if (typeFilter === 'all') return data.transactions;
      return data.transactions.filter((tx) => tx.type === typeFilter);
    },
    [data.transactions, typeFilter],
  );

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

        const serialized = transactions.map((tx: any) => ({
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
    fetchData(p, currentDate);
  };

  const handleDateNav = (direction: number) => {
    const next = navigateDate(period, currentDate, direction);
    setCurrentDate(next);
    fetchData(period, next);
  };

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

      {/* welcomeRow: tabRow + btnGroup (디자인 TGzU4) */}
      <div className='flex flex-col gap-4'>
        {/* tabRow: PeriodTabs + DateNav + TypeTabs */}
        <div className='flex items-center justify-between'>
          <PeriodTabs value={period} onChange={handlePeriodChange} />
          <DateNavigation
            label={getDateLabel(period, currentDate)}
            onPrev={() => handleDateNav(-1)}
            onNext={() => handleDateNav(1)}
          />
          <div className='flex items-center gap-1'>
            {(['all', 'income', 'expense'] as const).map((t) => (
              <button
                key={t}
                onClick={() => setTypeFilter(t)}
                className={`rounded-[8px] px-[14px] py-[6px] text-xs font-medium transition-colors ${
                  typeFilter === t
                    ? 'bg-primary text-white'
                    : 'bg-tab-bg text-on-surface-variant hover:bg-surface-container'
                }`}
              >
                {t === 'all' ? '전체' : t === 'income' ? '수입' : '지출'}
              </button>
            ))}
          </div>
        </div>

        {/* btnGroup */}
        <div className='flex items-center justify-end gap-2'>
          <button
            onClick={() => generateSampleExcel()}
            className='flex items-center gap-1.5 rounded-[10px] border border-[#E0E0E0] px-4 py-[10px] text-[13px] font-medium text-on-surface-variant transition-colors hover:bg-surface-container'
          >
            <FileSpreadsheet size={14} />
            샘플 다운로드
          </button>
          <button
            onClick={() => setExportOpen(true)}
            className='flex items-center gap-1.5 rounded-[10px] border border-[#E0E0E0] px-4 py-[10px] text-[13px] font-medium text-on-surface-variant transition-colors hover:bg-surface-container'
          >
            <Download size={14} />
            내보내기
          </button>
          <button
            onClick={() => setImportOpen(true)}
            className='flex items-center gap-1.5 rounded-[10px] border border-[#E0E0E0] px-4 py-[10px] text-[13px] font-medium text-on-surface-variant transition-colors hover:bg-surface-container'
          >
            <Upload size={14} />
            가져오기
          </button>
          <button
            onClick={() => setAddDialogOpen(true)}
            className='flex items-center gap-1.5 rounded-[10px] bg-primary px-4 py-[10px] text-[13px] font-semibold text-white transition-colors hover:bg-primary/90'
          >
            <Plus size={16} />
            거래 추가
          </button>
        </div>
      </div>

      {/* Summary Cards */}
      <div className='grid grid-cols-1 gap-4 md:grid-cols-3'>
        <SummaryCard
          icon={TrendingUp}
          iconColor='#2E7D32'
          label='수입'
          value={formatAmount(filteredSummary.income)}
          valueColor='text-income'
        />
        <SummaryCard
          icon={TrendingDown}
          iconColor='#BA1A1A'
          label='지출'
          value={formatAmount(filteredSummary.expense)}
          valueColor='text-expense'
        />
        <SummaryCard
          icon={Wallet}
          iconColor='#2E7D32'
          label='합계'
          value={formatAmount(filteredSummary.balance)}
          valueColor='text-primary'
        />
      </div>

      {/* Transaction List */}
      <div className='rounded-[16px] border border-card-border bg-white p-6'>
        {filteredTransactions.length > 0 ? (
          <div className='flex flex-col'>
            {filteredTransactions.map((tx) => (
              <div
                key={tx.id}
                onClick={() => handleTxClick(tx.id)}
                onDoubleClick={() => handleTxDoubleClick(tx.id)}
                className={`flex cursor-pointer items-center justify-between border-b border-[#F5F5F3] py-[14px] transition-colors last:border-b-0 hover:bg-surface ${
                  selectedTxId === tx.id
                    ? 'bg-primary/5'
                    : ''
                }`}
              >
                <div className='flex items-center gap-3'>
                  <div className='flex h-9 w-9 shrink-0 items-center justify-center rounded-[10px] bg-surface-container'>
                    {tx.categoryIcon ? (
                      <span className='material-icons-outlined text-[18px] text-on-surface-variant'>{tx.categoryIcon}</span>
                    ) : (
                      <span className='text-base text-on-surface-variant'>?</span>
                    )}
                  </div>
                  <div className='min-w-0 flex-1'>
                    <p className='truncate text-sm font-medium text-on-surface'>{tx.description}</p>
                    <div className='flex items-center gap-1.5'>
                      {tx.userName && (
                        <span className='flex shrink-0 items-center gap-1'>
                          <span
                            className='flex h-4 w-4 shrink-0 items-center justify-center rounded-full text-[9px] font-bold text-white'
                            style={{ backgroundColor: tx.userColor || '#9E9E9E' }}
                          >
                            {tx.userName.charAt(0)}
                          </span>
                          <span className='shrink-0 text-xs text-on-surface-variant'>{tx.userName}</span>
                        </span>
                      )}
                      <p className='truncate text-xs text-on-surface-variant'>
                        {formatDateTime(tx.createdAt)}
                        {tx.categoryName ? ` / ${tx.categoryName}` : ''}
                      </p>
                    </div>
                  </div>
                </div>
                <div className='flex shrink-0 items-center'>
                  <p
                    className={`text-[14px] font-semibold whitespace-nowrap ${
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
          </div>
        )}
      </div>

      <TransactionDetailModal
        open={!!detailModalTx || detailLoading}
        onClose={closeDetail}
        transaction={detailModalTx}
        loading={detailLoading}
        onSuccess={() => fetchData(period, currentDate)}
      />

      <AddTransactionDialog
        open={addDialogOpen}
        onClose={() => setAddDialogOpen(false)}
        ledgerId={ledgerId}
        onSuccess={() => fetchData(period, currentDate)}
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
        onSuccess={() => fetchData(period, currentDate)}
      />
    </div>
  );
}
