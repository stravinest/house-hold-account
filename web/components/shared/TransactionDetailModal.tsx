'use client';

import { useEffect } from 'react';
import {
  X,
  Pencil,
  Trash2,
  Calendar,
  Tag,
  CreditCard,
  User,
  Pin,
  Repeat,
  FileText,
  Loader2,
} from 'lucide-react';
import { formatAmount, formatDateWithDay } from '@/lib/utils';

export type TransactionDetail = {
  id: string;
  description: string;
  amount: number;
  type: 'income' | 'expense';
  date: string;
  memo?: string;
  categoryName?: string;
  categoryIcon?: string;
  categoryColor?: string;
  paymentMethodName?: string;
  authorName?: string;
  authorColor?: string;
  isFixedExpense?: boolean;
  isRecurring?: boolean;
  recurringType?: string;
};

type TransactionDetailModalProps = {
  open: boolean;
  onClose: () => void;
  transaction: TransactionDetail | null;
  loading?: boolean;
};

function getRecurringLabel(type?: string): string {
  switch (type) {
    case 'daily':
      return '매일 반복';
    case 'monthly':
      return '매월 반복';
    case 'yearly':
      return '매년 반복';
    default:
      return '반복';
  }
}

export function TransactionDetailModal({
  open,
  onClose,
  transaction,
  loading = false,
}: TransactionDetailModalProps) {
  // ESC 키로 닫기
  useEffect(() => {
    if (!open) return;
    const handleEsc = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onClose();
    };
    document.addEventListener('keydown', handleEsc);
    return () => document.removeEventListener('keydown', handleEsc);
  }, [open, onClose]);

  // body 스크롤 잠금
  useEffect(() => {
    if (!open) return;
    const prev = document.body.style.overflow;
    document.body.style.overflow = 'hidden';
    return () => {
      document.body.style.overflow = prev;
    };
  }, [open]);

  if (!open) return null;

  const showContent = !loading && transaction;
  const isExpense = transaction?.type === 'expense';
  const displayAmount = transaction
    ? isExpense
      ? -transaction.amount
      : transaction.amount
    : 0;

  return (
    <div
      className='fixed inset-0 z-50 flex items-center justify-center'
      role='dialog'
      aria-modal='true'
      aria-labelledby='tx-detail-title'
    >
      {/* Overlay */}
      <div className='fixed inset-0 bg-black/50' onClick={onClose} />

      {/* Modal */}
      <div className='relative z-10 w-full max-w-md rounded-2xl bg-white shadow-xl'>
        {/* Header */}
        <div className='flex items-center justify-between border-b border-separator px-6 py-4'>
          <h2
            id='tx-detail-title'
            className='text-lg font-bold text-on-surface'
          >
            거래 상세
          </h2>
          <div className='flex items-center gap-2'>
            <button
              disabled
              className='inline-flex h-8 cursor-not-allowed items-center gap-1.5 rounded-lg border border-primary/30 px-3 text-xs font-medium text-primary opacity-50'
            >
              <Pencil size={14} />
              수정
            </button>
            <button
              disabled
              className='inline-flex h-8 cursor-not-allowed items-center gap-1.5 rounded-lg border border-expense/30 px-3 text-xs font-medium text-expense opacity-50'
            >
              <Trash2 size={14} />
              삭제
            </button>
            <button
              onClick={onClose}
              aria-label='닫기'
              className='flex h-8 w-8 items-center justify-center rounded-lg text-on-surface-variant transition-colors hover:bg-surface-container'
            >
              <X size={18} />
            </button>
          </div>
        </div>

        {/* Loading */}
        {loading && (
          <div className='flex items-center justify-center py-16'>
            <Loader2 size={32} className='animate-spin text-primary' />
          </div>
        )}

        {/* Content */}
        {showContent && (
          <>
            {/* Amount Section */}
            <div className='flex flex-col items-center gap-2 px-6 py-6'>
              <span
                className={`rounded-full px-3 py-0.5 text-xs font-medium text-white ${
                  isExpense ? 'bg-expense' : 'bg-income'
                }`}
              >
                {isExpense ? '지출' : '수입'}
              </span>
              <p
                className={`text-3xl font-bold ${
                  isExpense ? 'text-expense' : 'text-income'
                }`}
              >
                {formatAmount(displayAmount, true)}
              </p>
              <p className='text-sm text-on-surface-variant'>
                {transaction.description}
              </p>
            </div>

            {/* Detail Rows */}
            <div className='border-t border-separator px-6 py-4'>
              <div className='flex flex-col divide-y divide-separator'>
                {/* 날짜 */}
                <DetailRow
                  icon={<Calendar size={18} />}
                  label='날짜'
                  value={formatDateWithDay(transaction.date)}
                />

                {/* 카테고리 */}
                {transaction.categoryName && (
                  <DetailRow
                    icon={<Tag size={18} />}
                    label='카테고리'
                    value={
                      <span className='flex items-center gap-2'>
                        {transaction.categoryColor && (
                          <span
                            className='inline-block h-2 w-2 rounded-full'
                            style={{
                              backgroundColor: transaction.categoryColor,
                            }}
                          />
                        )}
                        {transaction.categoryName}
                      </span>
                    }
                  />
                )}

                {/* 결제수단 */}
                {transaction.paymentMethodName && (
                  <DetailRow
                    icon={<CreditCard size={18} />}
                    label='결제수단'
                    value={transaction.paymentMethodName}
                  />
                )}

                {/* 작성자 */}
                {transaction.authorName && (
                  <DetailRow
                    icon={<User size={18} />}
                    label='작성자'
                    value={
                      <span className='flex items-center gap-2'>
                        <span
                          className='flex h-5 w-5 items-center justify-center rounded-full text-[10px] font-bold text-white'
                          style={{
                            backgroundColor:
                              transaction.authorColor || '#9E9E9E',
                          }}
                        >
                          {transaction.authorName.charAt(0)}
                        </span>
                        {transaction.authorName}
                      </span>
                    }
                  />
                )}

                {/* 고정비 */}
                {transaction.isFixedExpense && (
                  <DetailRow
                    icon={<Pin size={18} />}
                    label='고정비'
                    value={
                      <span className='rounded-full bg-primary/10 px-2.5 py-0.5 text-xs font-medium text-primary'>
                        고정비
                      </span>
                    }
                  />
                )}

                {/* 반복 */}
                {transaction.isRecurring && (
                  <DetailRow
                    icon={<Repeat size={18} />}
                    label='반복'
                    value={getRecurringLabel(transaction.recurringType)}
                  />
                )}

                {/* 메모 */}
                {transaction.memo && (
                  <div className='py-3'>
                    <div className='mb-2 flex items-center gap-2 text-on-surface-variant'>
                      <FileText size={18} />
                      <span className='text-sm'>메모</span>
                    </div>
                    <div className='rounded-lg bg-surface-container p-3'>
                      <p className='text-sm text-on-surface'>
                        {transaction.memo}
                      </p>
                    </div>
                  </div>
                )}
              </div>
            </div>
          </>
        )}
      </div>
    </div>
  );
}

function DetailRow({
  icon,
  label,
  value,
}: {
  icon: React.ReactNode;
  label: string;
  value: React.ReactNode;
}) {
  return (
    <div className='flex items-center justify-between py-3'>
      <div className='flex items-center gap-2 text-on-surface-variant'>
        {icon}
        <span className='text-sm'>{label}</span>
      </div>
      <div className='text-sm font-medium text-on-surface'>{value}</div>
    </div>
  );
}
