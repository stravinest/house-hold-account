'use client';

import { useEffect, useState } from 'react';
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
import { removeTransaction, updateTransaction } from '@/lib/actions/transaction';
import { useRouter } from 'next/navigation';
import { EditTransactionForm } from '@/components/transaction/EditTransactionForm';

export type TransactionDetail = {
  id: string;
  description: string;
  amount: number;
  type: 'income' | 'expense' | 'asset';
  date: string;
  memo?: string;
  categoryName?: string;
  categoryIcon?: string;
  categoryColor?: string;
  categoryId?: string;
  paymentMethodName?: string;
  paymentMethodId?: string;
  authorName?: string;
  authorColor?: string;
  isFixedExpense?: boolean;
  isRecurring?: boolean;
  recurringType?: string;
  recurringEndDate?: string;
  fixedExpenseCategoryId?: string;
  ledgerId?: string;
};

type TransactionDetailModalProps = {
  open: boolean;
  onClose: () => void;
  transaction: TransactionDetail | null;
  loading?: boolean;
  onSuccess?: () => void;
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
  onSuccess,
}: TransactionDetailModalProps) {
  const router = useRouter();
  const [deleting, setDeleting] = useState(false);
  const [confirmDelete, setConfirmDelete] = useState(false);
  const [editing, setEditing] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // ESC 키로 닫기
  useEffect(() => {
    if (!open) return;
    const handleEsc = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        if (confirmDelete) {
          setConfirmDelete(false);
        } else if (editing) {
          setEditing(false);
        } else {
          onClose();
        }
      }
    };
    document.addEventListener('keydown', handleEsc);
    return () => document.removeEventListener('keydown', handleEsc);
  }, [open, onClose, confirmDelete, editing]);

  // body 스크롤 잠금
  useEffect(() => {
    if (!open) return;
    const prev = document.body.style.overflow;
    document.body.style.overflow = 'hidden';
    return () => {
      document.body.style.overflow = prev;
    };
  }, [open]);

  // 모달 닫을 때 상태 초기화
  useEffect(() => {
    if (!open) {
      setConfirmDelete(false);
      setEditing(false);
      setError(null);
    }
  }, [open]);

  if (!open) return null;

  const showContent = !loading && transaction;
  const isExpense = transaction?.type === 'expense';
  const displayAmount = transaction
    ? isExpense
      ? -transaction.amount
      : transaction.amount
    : 0;

  const handleDelete = async () => {
    if (!transaction) return;
    setDeleting(true);
    setError(null);
    try {
      const result = await removeTransaction(transaction.id);
      if ('error' in result && result.error) {
        setError(result.error);
        setDeleting(false);
        return;
      }
      onClose();
      if (onSuccess) {
        onSuccess();
      } else {
        router.refresh();
      }
    } catch {
      setError('삭제 중 오류가 발생했습니다. 다시 시도해주세요.');
      setDeleting(false);
      return;
    } finally {
      setConfirmDelete(false);
    }
  };

  const handleEditSuccess = () => {
    setEditing(false);
    onClose();
    if (onSuccess) {
      onSuccess();
    } else {
      router.refresh();
    }
  };

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
            {editing ? '거래 수정' : '거래 상세'}
          </h2>
          <div className='flex items-center gap-2'>
            {!editing && showContent && (
              <>
                <button
                  onClick={() => setEditing(true)}
                  className='inline-flex h-8 items-center gap-1.5 rounded-lg border border-primary/30 px-3 text-xs font-medium text-primary transition-colors hover:bg-primary/5'
                >
                  <Pencil size={14} />
                  수정
                </button>
                <button
                  onClick={() => setConfirmDelete(true)}
                  className='inline-flex h-8 items-center gap-1.5 rounded-lg border border-expense/30 px-3 text-xs font-medium text-expense transition-colors hover:bg-expense/5'
                >
                  <Trash2 size={14} />
                  삭제
                </button>
              </>
            )}
            <button
              onClick={() => {
                if (editing) {
                  setEditing(false);
                } else {
                  onClose();
                }
              }}
              aria-label='닫기'
              className='flex h-8 w-8 items-center justify-center rounded-lg text-on-surface-variant transition-colors hover:bg-surface-container'
            >
              <X size={18} />
            </button>
          </div>
        </div>

        {/* Error */}
        {error && (
          <div className='mx-6 mt-4 rounded-lg border border-expense/20 bg-expense/5 px-4 py-2 text-sm text-expense'>
            {error}
          </div>
        )}

        {/* Delete Confirmation */}
        {confirmDelete && (
          <div className='border-b border-separator px-6 py-4'>
            <p className='mb-3 text-sm text-on-surface'>
              이 거래를 삭제하시겠습니까? 삭제 후 복구할 수 없습니다.
            </p>
            <div className='flex justify-end gap-2'>
              <button
                onClick={() => setConfirmDelete(false)}
                className='rounded-lg px-4 py-2 text-sm font-medium text-on-surface-variant transition-colors hover:bg-surface-container'
              >
                취소
              </button>
              <button
                onClick={handleDelete}
                disabled={deleting}
                className='inline-flex items-center gap-1.5 rounded-lg bg-expense px-4 py-2 text-sm font-medium text-white transition-colors hover:bg-expense/90 disabled:opacity-50'
              >
                {deleting && <Loader2 size={14} className='animate-spin' />}
                삭제
              </button>
            </div>
          </div>
        )}

        {/* Loading */}
        {loading && (
          <div className='flex items-center justify-center py-16'>
            <Loader2 size={32} className='animate-spin text-primary' />
          </div>
        )}

        {/* Edit Mode */}
        {editing && transaction && (
          <EditTransactionForm
            transaction={transaction}
            onSuccess={handleEditSuccess}
            onCancel={() => setEditing(false)}
          />
        )}

        {/* View Content */}
        {showContent && !editing && (
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
                <DetailRow
                  icon={<Calendar size={18} />}
                  label='날짜'
                  value={formatDateWithDay(transaction.date)}
                />
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
                {transaction.paymentMethodName && (
                  <DetailRow
                    icon={<CreditCard size={18} />}
                    label='결제수단'
                    value={transaction.paymentMethodName}
                  />
                )}
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
                {transaction.isRecurring && (
                  <DetailRow
                    icon={<Repeat size={18} />}
                    label='반복'
                    value={getRecurringLabel(transaction.recurringType)}
                  />
                )}
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
