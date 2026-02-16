'use client';

import { useState, useEffect } from 'react';
import { Minus, Plus, Loader2 } from 'lucide-react';
import { createClient } from '@/lib/supabase/client';
import { updateTransaction } from '@/lib/actions/transaction';
import { cn } from '@/lib/utils';
import type { TransactionDetail } from '@/components/shared/TransactionDetailModal';
import { CategoryIcon } from '@/components/shared/CategoryIcon';

type TransactionType = 'expense' | 'income' | 'asset';
type RecurringType = 'daily' | 'monthly' | 'yearly';

type Category = {
  id: string;
  name: string;
  type: string;
  icon: string | null;
};

type FixedExpenseCategory = {
  id: string;
  name: string;
  icon: string | null;
};

type PaymentMethod = {
  id: string;
  name: string;
};

interface EditTransactionFormProps {
  transaction: TransactionDetail;
  onSuccess: () => void;
  onCancel: () => void;
}

export function EditTransactionForm({
  transaction,
  onSuccess,
  onCancel,
}: EditTransactionFormProps) {
  const [type, setType] = useState<TransactionType>(transaction.type as TransactionType);
  const [amount, setAmount] = useState(String(transaction.amount));
  const [description, setDescription] = useState(transaction.description || '');
  const [date, setDate] = useState(transaction.date);
  const [categoryId, setCategoryId] = useState<string | null>(transaction.categoryId || null);
  const [paymentMethodId, setPaymentMethodId] = useState<string | null>(transaction.paymentMethodId || null);
  const [memo, setMemo] = useState(transaction.memo || '');
  const [isRecurring, setIsRecurring] = useState(transaction.isRecurring || false);
  const [recurringType, setRecurringType] = useState<RecurringType>(
    (transaction.recurringType as RecurringType) || 'monthly'
  );
  const [recurringEndDate, setRecurringEndDate] = useState(transaction.recurringEndDate || '');
  const [isFixedExpense, setIsFixedExpense] = useState(transaction.isFixedExpense || false);
  const [fixedExpenseCategoryId, setFixedExpenseCategoryId] = useState<string | null>(transaction.fixedExpenseCategoryId || null);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');

  const [categories, setCategories] = useState<Category[]>([]);
  const [fixedExpenseCategories, setFixedExpenseCategories] = useState<FixedExpenseCategory[]>([]);
  const [paymentMethods, setPaymentMethods] = useState<PaymentMethod[]>([]);

  useEffect(() => {
    if (!transaction.ledgerId) return;
    const fetchData = async () => {
      const supabase = createClient();
      const [catRes, pmRes, fecRes] = await Promise.all([
        supabase.from('categories').select('id, name, type, icon').eq('ledger_id', transaction.ledgerId!).order('sort_order'),
        supabase.from('payment_methods').select('id, name').eq('ledger_id', transaction.ledgerId!).order('created_at'),
        supabase.from('fixed_expense_categories').select('id, name, icon').eq('ledger_id', transaction.ledgerId!).order('sort_order'),
      ]);
      setCategories(catRes.data || []);
      setPaymentMethods(pmRes.data || []);
      setFixedExpenseCategories(fecRes.data || []);
    };
    fetchData();
  }, [transaction.ledgerId]);

  const handleFixedExpenseChange = (checked: boolean) => {
    setIsFixedExpense(checked);
    if (checked) {
      setIsRecurring(true);
      setRecurringType('monthly');
    }
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
    formData.set('type', type);
    formData.set('amount', amount);
    formData.set('description', description.trim());
    formData.set('date', date);
    if (categoryId) formData.set('category_id', categoryId);
    if (paymentMethodId && type === 'expense') formData.set('payment_method_id', paymentMethodId);
    if (memo.trim()) formData.set('memo', memo.trim());
    if (isFixedExpense && type === 'expense') formData.set('is_fixed_expense', 'true');
    if (isRecurring && type === 'expense') {
      formData.set('is_recurring', 'true');
      formData.set('recurring_type', recurringType);
      if (recurringEndDate) formData.set('recurring_end_date', recurringEndDate);
    }

    const result = await updateTransaction(transaction.id, formData);

    if (result?.error) {
      setError(result.error);
      setSaving(false);
      return;
    }

    setSaving(false);
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

  return (
    <div className='flex flex-col'>
      <div className='flex max-h-[60vh] flex-col gap-4 overflow-y-auto px-6 py-4' onKeyDown={handleKeyDown}>
        {/* Type Selector */}
        <div className='flex rounded-md bg-tab-bg p-1'>
          {(['expense', 'income', 'asset'] as TransactionType[]).map((t) => (
            <button
              key={t}
              onClick={() => {
                setType(t);
                setCategoryId(null);
                if (t !== 'expense') {
                  setIsFixedExpense(false);
                  setIsRecurring(false);
                  setPaymentMethodId(null);
                }
              }}
              className={cn(
                'flex-1 rounded-[10px] py-2 text-sm font-semibold transition-all',
                type === t
                  ? 'bg-white text-on-surface shadow-sm'
                  : 'text-on-surface-variant hover:text-on-surface',
              )}
            >
              {t === 'expense' ? '지출' : t === 'income' ? '수입' : '자산'}
            </button>
          ))}
        </div>

        {/* Amount */}
        <div className={cn('flex flex-col gap-1.5 rounded-[14px] p-3', typeBgColor)}>
          <label className='text-xs font-medium text-on-surface-variant'>금액</label>
          <div className='flex items-center gap-2'>
            <span className={cn('text-xl font-bold', typeColor)}>
              {type === 'expense' ? <Minus size={18} /> : <Plus size={18} />}
            </span>
            <input
              type='number'
              value={amount}
              onChange={(e) => {
                const val = e.target.value;
                if (val === '' || Number(val) >= 0) setAmount(val);
              }}
              placeholder='0'
              min='0'
              autoFocus
              className={cn(
                'w-full bg-transparent text-xl font-bold outline-none placeholder:text-on-surface-variant/40',
                typeColor,
              )}
            />
            <span className={cn('text-base font-semibold', typeColor)}>원</span>
          </div>
        </div>

        {/* Title */}
        <div className='flex flex-col gap-1'>
          <label className='text-[13px] font-medium text-on-surface-variant'>제목</label>
          <input
            type='text'
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            placeholder='거래 내용을 입력하세요'
            maxLength={40}
            className='h-10 w-full rounded-[10px] border border-card-border bg-tab-bg px-3 text-sm outline-none focus:border-primary'
          />
        </div>

        {/* Date */}
        <div className='flex flex-col gap-1'>
          <label className='text-[13px] font-medium text-on-surface-variant'>날짜</label>
          <input
            type='date'
            value={date}
            onChange={(e) => setDate(e.target.value)}
            className='h-10 w-full rounded-[10px] border border-card-border bg-tab-bg px-3 text-sm outline-none focus:border-primary'
          />
        </div>

        {/* Fixed Expense + Recurring (expense only) */}
        {type === 'expense' && (
          <>
            <div className='flex items-center gap-4'>
              <label className='flex cursor-pointer items-center gap-2 text-sm text-on-surface'>
                <input
                  type='checkbox'
                  checked={isFixedExpense}
                  onChange={(e) => handleFixedExpenseChange(e.target.checked)}
                  className='h-4 w-4 rounded accent-primary'
                />
                고정비
              </label>
              <label className='flex cursor-pointer items-center gap-2 text-sm text-on-surface'>
                <input
                  type='checkbox'
                  checked={isRecurring}
                  onChange={(e) => {
                    setIsRecurring(e.target.checked);
                    if (!e.target.checked && !isFixedExpense) {
                      setRecurringEndDate('');
                    }
                  }}
                  disabled={isFixedExpense}
                  className='h-4 w-4 rounded accent-primary disabled:opacity-50'
                />
                반복
                {isFixedExpense && <span className='text-xs text-on-surface-variant'>(자동)</span>}
              </label>
            </div>

            {/* Fixed Expense Category */}
            {isFixedExpense && fixedExpenseCategories.length > 0 && (
              <div className='flex flex-col gap-1.5'>
                <label className='text-[13px] font-medium text-on-surface-variant'>고정비 카테고리</label>
                <div className='flex flex-wrap gap-1.5'>
                  {fixedExpenseCategories.map((fec) => (
                    <button
                      key={fec.id}
                      onClick={() => setFixedExpenseCategoryId(fixedExpenseCategoryId === fec.id ? null : fec.id)}
                      className={cn(
                        'flex items-center gap-1.5 rounded-[20px] border px-3 py-1 text-sm transition-all',
                        fixedExpenseCategoryId === fec.id
                          ? 'border-primary bg-primary/10 font-medium text-primary'
                          : 'border-card-border bg-white text-on-surface-variant hover:border-primary/50',
                      )}
                    >
                      <CategoryIcon icon={fec.icon} name={fec.name} />
                      {fec.name}
                    </button>
                  ))}
                </div>
              </div>
            )}

            {/* Recurring Settings */}
            {isRecurring && (
              <div className='flex flex-col gap-3 rounded-[12px] border border-card-border bg-tab-bg p-3'>
                <div className='flex flex-col gap-1.5'>
                  <label className='text-[13px] font-medium text-on-surface-variant'>반복 주기</label>
                  <div className='flex rounded-md bg-white p-1'>
                    {([
                      { value: 'daily' as RecurringType, label: '매일' },
                      { value: 'monthly' as RecurringType, label: '매월' },
                      { value: 'yearly' as RecurringType, label: '매년' },
                    ]).map((opt) => (
                      <button
                        key={opt.value}
                        onClick={() => setRecurringType(opt.value)}
                        className={cn(
                          'flex-1 rounded-[8px] py-1.5 text-sm font-medium transition-all',
                          recurringType === opt.value
                            ? 'bg-primary text-white shadow-sm'
                            : 'text-on-surface-variant hover:text-on-surface',
                        )}
                      >
                        {opt.label}
                      </button>
                    ))}
                  </div>
                </div>
                <div className='flex flex-col gap-1'>
                  <label className='text-[13px] font-medium text-on-surface-variant'>
                    종료일 (미입력 시 무기한)
                  </label>
                  <input
                    type='date'
                    value={recurringEndDate}
                    onChange={(e) => setRecurringEndDate(e.target.value)}
                    min={date}
                    className='h-[38px] w-full rounded-[10px] border border-card-border bg-white px-3 text-sm outline-none focus:border-primary'
                  />
                </div>
              </div>
            )}
          </>
        )}

        {/* Category Chips (고정비가 아닐 때만 표시) */}
        {!isFixedExpense && filteredCategories.length > 0 && (
          <div className='flex flex-col gap-1.5'>
            <label className='text-[13px] font-medium text-on-surface-variant'>카테고리</label>
            <div className='flex flex-wrap gap-1.5'>
              {filteredCategories.map((cat) => (
                <button
                  key={cat.id}
                  onClick={() => setCategoryId(categoryId === cat.id ? null : cat.id)}
                  className={cn(
                    'flex items-center gap-1.5 rounded-[20px] border px-3 py-1 text-sm transition-all',
                    categoryId === cat.id
                      ? 'border-primary bg-primary/10 font-medium text-primary'
                      : 'border-card-border bg-white text-on-surface-variant hover:border-primary/50',
                  )}
                >
                  <CategoryIcon icon={cat.icon} name={cat.name} />
                  {cat.name}
                </button>
              ))}
            </div>
          </div>
        )}

        {/* Payment Method Chips */}
        {paymentMethods.length > 0 && type === 'expense' && (
          <div className='flex flex-col gap-1.5'>
            <label className='text-[13px] font-medium text-on-surface-variant'>결제수단</label>
            <div className='flex flex-wrap gap-1.5'>
              {paymentMethods.map((pm) => (
                <button
                  key={pm.id}
                  onClick={() => setPaymentMethodId(paymentMethodId === pm.id ? null : pm.id)}
                  className={cn(
                    'rounded-[20px] border px-3 py-1 text-sm transition-all',
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

        {/* Memo */}
        <div className='flex flex-col gap-1'>
          <label className='text-[13px] font-medium text-on-surface-variant'>메모</label>
          <textarea
            value={memo}
            onChange={(e) => setMemo(e.target.value)}
            placeholder='메모를 입력하세요 (선택)'
            rows={2}
            maxLength={500}
            className='w-full resize-none rounded-[10px] border border-card-border bg-tab-bg px-3 py-2 text-sm outline-none focus:border-primary'
          />
        </div>

        {error && <p className='text-sm text-expense'>{error}</p>}
      </div>

      {/* Footer */}
      <div className='flex items-center justify-end gap-3 border-t border-separator px-6 py-3'>
        <button
          onClick={onCancel}
          className='h-10 rounded-[10px] px-4 text-sm font-semibold text-on-surface-variant hover:bg-surface-container'
        >
          취소
        </button>
        <button
          onClick={handleSubmit}
          disabled={saving}
          className='inline-flex h-10 items-center gap-1.5 rounded-[10px] bg-primary px-5 text-sm font-semibold text-white transition-colors hover:bg-primary/90 disabled:opacity-50'
        >
          {saving && <Loader2 size={14} className='animate-spin' />}
          {saving ? '저장 중...' : '저장'}
        </button>
      </div>
    </div>
  );
}
