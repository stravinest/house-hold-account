'use client';

import { useState, useEffect } from 'react';
import { X, Minus, Plus } from 'lucide-react';
import { createClient } from '@/lib/supabase/client';
import { addTransaction } from '@/lib/actions/transaction';
import { cn } from '@/lib/utils';

type TransactionType = 'expense' | 'income' | 'asset';

type Category = {
  id: string;
  name: string;
  type: string;
  icon: string | null;
};

type PaymentMethod = {
  id: string;
  name: string;
};

interface AddTransactionDialogProps {
  open: boolean;
  onClose: () => void;
  ledgerId: string;
  onSuccess: () => void;
}

export function AddTransactionDialog({
  open,
  onClose,
  ledgerId,
  onSuccess,
}: AddTransactionDialogProps) {
  const [type, setType] = useState<TransactionType>('expense');
  const [amount, setAmount] = useState('');
  const [description, setDescription] = useState('');
  const [date, setDate] = useState(() => {
    const now = new Date();
    return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`;
  });
  const [categoryId, setCategoryId] = useState<string | null>(null);
  const [paymentMethodId, setPaymentMethodId] = useState<string | null>(null);
  const [memo, setMemo] = useState('');
  const [isRecurring, setIsRecurring] = useState(false);
  const [isFixedExpense, setIsFixedExpense] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');

  const [categories, setCategories] = useState<Category[]>([]);
  const [paymentMethods, setPaymentMethods] = useState<PaymentMethod[]>([]);

  useEffect(() => {
    if (!open) return;
    const fetchData = async () => {
      const supabase = createClient();
      const [catRes, pmRes] = await Promise.all([
        supabase.from('categories').select('id, name, type, icon').eq('ledger_id', ledgerId).order('sort_order'),
        supabase.from('payment_methods').select('id, name').eq('ledger_id', ledgerId).order('created_at'),
      ]);
      setCategories(catRes.data || []);
      setPaymentMethods(pmRes.data || []);
    };
    fetchData();
  }, [open, ledgerId]);

  useEffect(() => {
    if (!open) return;
    const handleEsc = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onClose();
    };
    document.addEventListener('keydown', handleEsc);
    return () => document.removeEventListener('keydown', handleEsc);
  }, [open, onClose]);

  useEffect(() => {
    if (open) {
      document.body.style.overflow = 'hidden';
      return () => { document.body.style.overflow = ''; };
    }
  }, [open]);

  const resetForm = () => {
    setType('expense');
    setAmount('');
    setDescription('');
    const now = new Date();
    setDate(`${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`);
    setCategoryId(null);
    setPaymentMethodId(null);
    setMemo('');
    setIsRecurring(false);
    setIsFixedExpense(false);
    setError('');
  };

  const handleClose = () => {
    resetForm();
    onClose();
  };

  const handleSubmit = async () => {
    if (!amount || Number(amount) <= 0) {
      setError('금액을 입력해주세요.');
      return;
    }
    if (!description.trim()) {
      setError('제목을 입력해주세요.');
      return;
    }

    setSaving(true);
    setError('');

    const formData = new FormData();
    formData.set('ledger_id', ledgerId);
    formData.set('type', type);
    formData.set('amount', amount);
    formData.set('description', description.trim());
    formData.set('date', date);
    if (categoryId) formData.set('category_id', categoryId);
    if (paymentMethodId) formData.set('payment_method_id', paymentMethodId);
    if (memo.trim()) formData.set('memo', memo.trim());
    if (isRecurring) formData.set('is_recurring', 'true');
    if (isFixedExpense) formData.set('is_fixed_expense', 'true');

    const result = await addTransaction(formData);

    if (result?.error) {
      setError(result.error);
      setSaving(false);
      return;
    }

    setSaving(false);
    handleClose();
    onSuccess();
  };

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && !(e.target instanceof HTMLTextAreaElement) && !saving) {
      e.preventDefault();
      handleSubmit();
    }
  };

  const filteredCategories = categories.filter((c) => c.type === type);

  const typeColor = type === 'income' ? 'text-income' : type === 'expense' ? 'text-expense' : 'text-primary';
  const typeBgColor = type === 'income' ? 'bg-income/10' : type === 'expense' ? 'bg-expense/10' : 'bg-primary/10';

  if (!open) return null;

  return (
    <div className='fixed inset-0 z-50 flex items-center justify-center'>
      <div className='fixed inset-0 bg-black/50' onClick={handleClose} />
      <div className='relative z-10 flex max-h-[90vh] w-full max-w-[580px] flex-col rounded-[20px] bg-white shadow-xl'>
        {/* Header */}
        <div className='flex items-center justify-between border-b border-separator px-6 py-[18px]'>
          <h2 className='text-lg font-bold text-on-surface'>거래 추가</h2>
          <button
            onClick={handleClose}
            className='flex h-8 w-8 items-center justify-center rounded-full hover:bg-surface-container'
          >
            <X size={18} className='text-on-surface-variant' />
          </button>
        </div>

        {/* Body */}
        <div className='flex flex-col gap-5 overflow-y-auto px-6 py-5' onKeyDown={handleKeyDown}>
          {/* Type Selector */}
          <div className='flex rounded-md bg-tab-bg p-1'>
            {(['expense', 'income', 'asset'] as TransactionType[]).map((t) => (
              <button
                key={t}
                onClick={() => {
                  setType(t);
                  setCategoryId(null);
                }}
                className={cn(
                  'flex-1 rounded-[10px] py-2.5 text-sm font-semibold transition-all',
                  type === t
                    ? 'bg-white text-on-surface shadow-sm'
                    : 'text-on-surface-variant hover:text-on-surface',
                )}
              >
                {t === 'expense' ? '지출' : t === 'income' ? '수입' : '자산'}
              </button>
            ))}
          </div>

          {/* Amount Section */}
          <div className={cn('flex flex-col gap-2 rounded-[14px] p-4', typeBgColor)}>
            <label className='text-xs font-medium text-on-surface-variant'>금액</label>
            <div className='flex items-center gap-2'>
              <span className={cn('text-2xl font-bold', typeColor)}>
                {type === 'expense' ? <Minus size={20} /> : <Plus size={20} />}
              </span>
              <input
                type='number'
                value={amount}
                onChange={(e) => setAmount(e.target.value)}
                placeholder='0'
                min='0'
                autoFocus
                className={cn(
                  'w-full bg-transparent text-2xl font-bold outline-none placeholder:text-on-surface-variant/40',
                  typeColor,
                )}
              />
              <span className={cn('text-lg font-semibold', typeColor)}>원</span>
            </div>
          </div>

          {/* Title */}
          <div className='flex flex-col gap-1.5'>
            <label className='text-[13px] font-medium text-on-surface-variant'>제목</label>
            <input
              type='text'
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              placeholder='거래 내용을 입력하세요'
              className='h-[46px] w-full rounded-[10px] border border-card-border bg-tab-bg px-4 text-sm outline-none focus:border-primary'
            />
          </div>

          {/* Date */}
          <div className='flex flex-col gap-1.5'>
            <label className='text-[13px] font-medium text-on-surface-variant'>날짜</label>
            <input
              type='date'
              value={date}
              onChange={(e) => setDate(e.target.value)}
              className='h-[46px] w-full rounded-[10px] border border-card-border bg-tab-bg px-4 text-sm outline-none focus:border-primary'
            />
          </div>

          {/* Category Chips */}
          {filteredCategories.length > 0 && (
            <div className='flex flex-col gap-2'>
              <label className='text-[13px] font-medium text-on-surface-variant'>카테고리</label>
              <div className='flex flex-wrap gap-2'>
                {filteredCategories.map((cat) => (
                  <button
                    key={cat.id}
                    onClick={() => setCategoryId(categoryId === cat.id ? null : cat.id)}
                    className={cn(
                      'rounded-[20px] border px-3 py-1.5 text-sm transition-all',
                      categoryId === cat.id
                        ? 'border-primary bg-primary/10 font-medium text-primary'
                        : 'border-card-border bg-white text-on-surface-variant hover:border-primary/50',
                    )}
                  >
                    {cat.icon ? `${cat.icon} ` : ''}{cat.name}
                  </button>
                ))}
              </div>
            </div>
          )}

          {/* Payment Method Chips */}
          {paymentMethods.length > 0 && type === 'expense' && (
            <div className='flex flex-col gap-2'>
              <label className='text-[13px] font-medium text-on-surface-variant'>결제수단</label>
              <div className='flex flex-wrap gap-2'>
                {paymentMethods.map((pm) => (
                  <button
                    key={pm.id}
                    onClick={() => setPaymentMethodId(paymentMethodId === pm.id ? null : pm.id)}
                    className={cn(
                      'rounded-[20px] border px-3 py-1.5 text-sm transition-all',
                      paymentMethodId === pm.id
                        ? 'border-primary bg-primary/10 font-medium text-primary'
                        : 'border-card-border bg-white text-on-surface-variant hover:border-primary/50',
                    )}
                  >
                    {pm.name}
                  </button>
                ))}
              </div>
            </div>
          )}

          {/* Options Row */}
          {type === 'expense' && (
            <div className='flex items-center gap-4'>
              <label className='flex cursor-pointer items-center gap-2 text-sm text-on-surface-variant'>
                <input
                  type='checkbox'
                  checked={isRecurring}
                  onChange={(e) => setIsRecurring(e.target.checked)}
                  className='h-4 w-4 rounded accent-primary'
                />
                반복
              </label>
              <label className='flex cursor-pointer items-center gap-2 text-sm text-on-surface-variant'>
                <input
                  type='checkbox'
                  checked={isFixedExpense}
                  onChange={(e) => setIsFixedExpense(e.target.checked)}
                  className='h-4 w-4 rounded accent-primary'
                />
                고정비
              </label>
            </div>
          )}

          {/* Memo */}
          <div className='flex flex-col gap-1.5'>
            <label className='text-[13px] font-medium text-on-surface-variant'>메모</label>
            <textarea
              value={memo}
              onChange={(e) => setMemo(e.target.value)}
              placeholder='메모를 입력하세요 (선택)'
              rows={2}
              className='w-full resize-none rounded-[10px] border border-card-border bg-tab-bg px-4 py-3 text-sm outline-none focus:border-primary'
            />
          </div>

          {/* Error */}
          {error && (
            <p className='text-sm text-expense'>{error}</p>
          )}
        </div>

        {/* Footer */}
        <div className='flex items-center justify-end gap-3 border-t border-separator px-6 py-4'>
          <button
            onClick={handleClose}
            className='h-11 rounded-[10px] px-5 text-sm font-semibold text-on-surface-variant hover:bg-surface-container'
          >
            취소
          </button>
          <button
            onClick={handleSubmit}
            disabled={saving}
            className='h-11 rounded-[10px] bg-primary px-6 text-sm font-semibold text-white transition-colors hover:bg-primary/90 disabled:opacity-50'
          >
            {saving ? '저장 중...' : '저장'}
          </button>
        </div>
      </div>
    </div>
  );
}
