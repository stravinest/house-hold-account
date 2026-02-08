'use client';

import { useState } from 'react';
import { X, Download } from 'lucide-react';
import { createClient } from '@/lib/supabase/client';
import { exportTransactions } from '@/lib/utils/excel';
import type { ExportOptions } from '@/lib/types/excel';
import { cn } from '@/lib/utils';

type ExportRow = {
  date: string;
  type: string;
  amount: number;
  title: string;
  categories: { name: string } | null;
  payment_methods: { name: string } | null;
  profiles: { display_name: string } | null;
  memo: string | null;
  is_fixed_expense: boolean;
};

function getQuickDateRange(key: string): { start: string; end: string } {
  const now = new Date();
  const y = now.getFullYear();
  const m = now.getMonth();

  switch (key) {
    case 'thisMonth': {
      const start = `${y}-${String(m + 1).padStart(2, '0')}-01`;
      const lastDay = new Date(y, m + 1, 0).getDate();
      const end = `${y}-${String(m + 1).padStart(2, '0')}-${String(lastDay).padStart(2, '0')}`;
      return { start, end };
    }
    case 'lastMonth': {
      const prevMonth = m === 0 ? 11 : m - 1;
      const prevYear = m === 0 ? y - 1 : y;
      const start = `${prevYear}-${String(prevMonth + 1).padStart(2, '0')}-01`;
      const lastDay = new Date(prevYear, prevMonth + 1, 0).getDate();
      const end = `${prevYear}-${String(prevMonth + 1).padStart(2, '0')}-${String(lastDay).padStart(2, '0')}`;
      return { start, end };
    }
    case 'last3Months': {
      const threeMonthsAgo = new Date(y, m - 2, 1);
      const start = `${threeMonthsAgo.getFullYear()}-${String(threeMonthsAgo.getMonth() + 1).padStart(2, '0')}-01`;
      const lastDay = new Date(y, m + 1, 0).getDate();
      const end = `${y}-${String(m + 1).padStart(2, '0')}-${String(lastDay).padStart(2, '0')}`;
      return { start, end };
    }
    case 'thisYear': {
      return { start: `${y}-01-01`, end: `${y}-12-31` };
    }
    default:
      return { start: '', end: '' };
  }
}

interface ExportPanelProps {
  open: boolean;
  onClose: () => void;
  ledgerId: string;
}

export function ExportPanel({ open, onClose, ledgerId }: ExportPanelProps) {
  const today = new Date();
  const firstDay = `${today.getFullYear()}-${String(today.getMonth() + 1).padStart(2, '0')}-01`;
  const lastDay = `${today.getFullYear()}-${String(today.getMonth() + 1).padStart(2, '0')}-${String(new Date(today.getFullYear(), today.getMonth() + 1, 0).getDate()).padStart(2, '0')}`;

  const [options, setOptions] = useState<ExportOptions>({
    startDate: firstDay,
    endDate: lastDay,
    transactionType: 'all',
    includeCategory: true,
    includePaymentMethod: true,
    includeMemo: false,
    includeAuthor: false,
    includeFixedExpense: false,
    fileFormat: 'xlsx',
  });
  const [exporting, setExporting] = useState(false);
  const [error, setError] = useState('');

  const handleExport = async () => {
    setExporting(true);
    setError('');

    if (options.startDate > options.endDate) {
      setError('시작 날짜가 종료 날짜보다 큽니다.');
      setExporting(false);
      return;
    }

    try {
      const supabase = createClient();
      let query = supabase
        .from('transactions')
        .select('*, categories(name), payment_methods(name), profiles(display_name)')
        .eq('ledger_id', ledgerId)
        .gte('date', options.startDate)
        .lte('date', options.endDate)
        .order('date', { ascending: false });

      if (options.transactionType !== 'all') {
        query = query.eq('type', options.transactionType);
      }

      const { data, error: fetchError } = await query;

      if (fetchError) {
        setError(fetchError.message);
        setExporting(false);
        return;
      }

      if (!data || data.length === 0) {
        setError('내보낼 거래가 없습니다.');
        setExporting(false);
        return;
      }

      const rows = data.map((tx: ExportRow) => ({
        date: tx.date,
        type: tx.type,
        amount: tx.amount,
        description: tx.title,
        categoryName: tx.categories?.name,
        paymentMethodName: tx.payment_methods?.name,
        memo: tx.memo ?? undefined,
        userName: tx.profiles?.display_name,
        isFixedExpense: tx.is_fixed_expense,
      }));

      exportTransactions(rows, options);
      onClose();
    } catch {
      setError('내보내기 중 오류가 발생했습니다.');
    } finally {
      setExporting(false);
    }
  };

  if (!open) return null;

  return (
    <div className='fixed inset-0 z-50 flex items-center justify-center'>
      <div className='fixed inset-0 bg-black/50' onClick={onClose} />
      <div className='relative z-10 w-full max-w-[480px] rounded-[20px] bg-white shadow-xl'>
        {/* Header */}
        <div className='flex items-center justify-between border-b border-separator px-6 py-[18px]'>
          <h2 className='text-lg font-bold text-on-surface'>내보내기</h2>
          <button
            onClick={onClose}
            className='flex h-8 w-8 items-center justify-center rounded-full hover:bg-surface-container'
          >
            <X size={18} className='text-on-surface-variant' />
          </button>
        </div>

        {/* Body */}
        <div className='flex flex-col gap-5 px-6 py-5'>
          {/* Period */}
          <div className='flex flex-col gap-2'>
            <label className='text-[13px] font-medium text-on-surface-variant'>기간</label>
            <div className='flex flex-wrap gap-1.5'>
              {([
                ['thisMonth', '이번 달'],
                ['lastMonth', '지난 달'],
                ['last3Months', '최근 3개월'],
                ['thisYear', '올해 전체'],
              ] as const).map(([key, label]) => {
                const range = getQuickDateRange(key);
                const isActive = options.startDate === range.start && options.endDate === range.end;
                return (
                  <button
                    key={key}
                    onClick={() => setOptions({ ...options, startDate: range.start, endDate: range.end })}
                    className={cn(
                      'rounded-lg px-3 py-1.5 text-xs font-medium transition-all',
                      isActive
                        ? 'bg-primary text-white'
                        : 'bg-tab-bg text-on-surface-variant hover:text-on-surface',
                    )}
                  >
                    {label}
                  </button>
                );
              })}
            </div>
            <div className='flex items-center gap-2'>
              <input
                type='date'
                value={options.startDate}
                onChange={(e) => setOptions({ ...options, startDate: e.target.value })}
                className='h-[42px] flex-1 rounded-[10px] border border-[#E8E8E8] bg-[#F8F9FA] px-3 text-sm outline-none focus:border-primary'
              />
              <span className='text-sm text-on-surface-variant'>~</span>
              <input
                type='date'
                value={options.endDate}
                onChange={(e) => setOptions({ ...options, endDate: e.target.value })}
                className='h-[42px] flex-1 rounded-[10px] border border-[#E8E8E8] bg-[#F8F9FA] px-3 text-sm outline-none focus:border-primary'
              />
            </div>
          </div>

          {/* Transaction Type */}
          <div className='flex flex-col gap-2'>
            <label className='text-[13px] font-medium text-on-surface-variant'>유형</label>
            <div className='flex rounded-[10px] bg-[#F5F6F5] p-1'>
              {([
                ['all', '전체'],
                ['income', '수입'],
                ['expense', '지출'],
                ['asset', '자산'],
              ] as const).map(([value, label]) => (
                <button
                  key={value}
                  onClick={() => setOptions({ ...options, transactionType: value })}
                  className={cn(
                    'flex-1 rounded-[8px] py-2 text-sm font-medium transition-all',
                    options.transactionType === value
                      ? 'bg-white text-on-surface shadow-sm'
                      : 'text-on-surface-variant hover:text-on-surface',
                  )}
                >
                  {label}
                </button>
              ))}
            </div>
          </div>

          {/* Include Options */}
          <div className='flex flex-col gap-2'>
            <label className='text-[13px] font-medium text-on-surface-variant'>포함 항목</label>
            <div className='flex flex-wrap gap-2'>
              {([
                ['includeCategory', '카테고리'],
                ['includePaymentMethod', '결제수단'],
                ['includeMemo', '메모'],
                ['includeAuthor', '작성자'],
                ['includeFixedExpense', '고정비'],
              ] as const).map(([key, label]) => (
                <button
                  key={key}
                  onClick={() =>
                    setOptions({ ...options, [key]: !options[key] })
                  }
                  className={cn(
                    'rounded-[20px] border px-3 py-1.5 text-sm transition-all',
                    options[key]
                      ? 'border-primary bg-primary/10 font-medium text-primary'
                      : 'border-[#E8E8E8] bg-white text-on-surface-variant',
                  )}
                >
                  {label}
                </button>
              ))}
            </div>
          </div>

          {/* File Format */}
          <div className='flex flex-col gap-2'>
            <label className='text-[13px] font-medium text-on-surface-variant'>파일 형식</label>
            <div className='flex gap-3'>
              {(['xlsx', 'csv'] as const).map((fmt) => (
                <button
                  key={fmt}
                  onClick={() => setOptions({ ...options, fileFormat: fmt })}
                  className={cn(
                    'flex-1 rounded-[10px] border py-2.5 text-sm font-medium transition-all',
                    options.fileFormat === fmt
                      ? 'border-primary bg-primary/5 text-primary'
                      : 'border-[#E8E8E8] text-on-surface-variant hover:border-primary/50',
                  )}
                >
                  {fmt.toUpperCase()}
                </button>
              ))}
            </div>
          </div>

          {error && <p className='text-sm text-expense'>{error}</p>}
        </div>

        {/* Footer */}
        <div className='flex gap-3 border-t border-[#F0F0EC] px-6 py-4'>
          <button
            onClick={onClose}
            className='flex flex-1 items-center justify-center rounded-xl border border-[#E0E0E0] py-[14px] text-[15px] font-medium text-[#44483E] transition-colors hover:bg-surface-container'
          >
            취소
          </button>
          <button
            onClick={handleExport}
            disabled={exporting}
            className='flex flex-1 items-center justify-center gap-2 rounded-xl bg-primary py-[14px] text-[15px] font-semibold text-white transition-colors hover:bg-primary/90 disabled:opacity-50'
          >
            <Download size={16} />
            {exporting ? '내보내는 중...' : '내보내기'}
          </button>
        </div>
      </div>
    </div>
  );
}
