'use server';

import { revalidatePath } from 'next/cache';
import { createClient } from '@/lib/supabase/server';

const VALID_TYPES = ['expense', 'income', 'asset'];
const VALID_RECURRING_TYPES = ['daily', 'monthly', 'yearly'];
const DATE_REGEX = /^\d{4}-\d{2}-\d{2}$/;

function validateAmount(value: unknown): number | null {
  const num = Number(value);
  if (!Number.isFinite(num) || num <= 0 || num > 999_999_999) return null;
  return Math.floor(num);
}

function validateDate(value: unknown): string | null {
  if (typeof value !== 'string' || !DATE_REGEX.test(value)) return null;
  const d = new Date(value);
  if (isNaN(d.getTime())) return null;
  return value;
}

export async function addTransaction(formData: FormData) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: '로그인이 필요합니다.' };

  const ledgerId = formData.get('ledger_id') as string;

  // 가계부 멤버십 검증
  const { data: membership } = await supabase
    .from('ledger_members')
    .select('id')
    .eq('ledger_id', ledgerId)
    .eq('user_id', user.id)
    .single();
  if (!membership) return { error: '해당 가계부에 대한 권한이 없습니다.' };

  const type = formData.get('type') as string;
  if (!VALID_TYPES.includes(type)) {
    return { error: '유효하지 않은 거래 유형입니다.' };
  }

  const amount = validateAmount(formData.get('amount'));
  if (amount === null) {
    return { error: '유효한 금액을 입력해주세요. (1~999,999,999)' };
  }

  const description = (formData.get('description') as string || '').trim();
  if (!description) {
    return { error: '제목을 입력해주세요.' };
  }

  const date = validateDate(formData.get('date'));
  if (!date) {
    return { error: '유효한 날짜를 입력해주세요.' };
  }

  const categoryId = formData.get('category_id') as string;
  const paymentMethodId = formData.get('payment_method_id') as string;
  const memo = formData.get('memo') as string;
  const isRecurring = formData.get('is_recurring') === 'true';
  const isFixedExpense = formData.get('is_fixed_expense') === 'true';
  const fixedExpenseCategoryId = formData.get('fixed_expense_category_id') as string;
  const recurringType = formData.get('recurring_type') as string;
  const recurringEndDate = formData.get('recurring_end_date') as string;
  const isAsset = formData.get('is_asset') === 'true';
  const maturityDate = formData.get('maturity_date') as string;

  // 거래 삽입
  const insertData: Record<string, unknown> = {
    ledger_id: ledgerId,
    user_id: user.id,
    type,
    amount,
    title: description,
    category_id: categoryId || null,
    payment_method_id: paymentMethodId || null,
    date,
    memo: memo || null,
    is_recurring: isRecurring,
    recurring_type: isRecurring ? (recurringType || null) : null,
    recurring_end_date: isRecurring && recurringEndDate ? recurringEndDate : null,
    is_fixed_expense: isFixedExpense,
    fixed_expense_category_id: isFixedExpense && fixedExpenseCategoryId ? fixedExpenseCategoryId : null,
    is_asset: isAsset,
    maturity_date: isAsset && maturityDate ? maturityDate : null,
  };

  const { error } = await supabase
    .from('transactions')
    .insert(insertData);

  if (error) return { error: error.message };

  // 반복 거래인 경우 recurring_templates에도 추가
  if (isRecurring && recurringType) {
    const startDate = new Date(date);
    const recurringDay = startDate.getDate();

    const templateData: Record<string, unknown> = {
      ledger_id: ledgerId,
      user_id: user.id,
      category_id: categoryId || null,
      payment_method_id: paymentMethodId || null,
      amount,
      type,
      title: description,
      memo: memo || null,
      recurring_type: recurringType,
      start_date: date,
      end_date: recurringEndDate || null,
      recurring_day: recurringDay,
      is_fixed_expense: isFixedExpense,
      fixed_expense_category_id: isFixedExpense && fixedExpenseCategoryId ? fixedExpenseCategoryId : null,
      last_generated_date: date,
      is_active: true,
    };

    await supabase.from('recurring_templates').insert(templateData);
  }

  revalidatePath('/ledger');
  revalidatePath('/dashboard');
  revalidatePath('/statistics');
  return { success: true };
}

export async function updateTransaction(id: string, formData: FormData) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: '로그인이 필요합니다.' };

  const { data: transaction } = await supabase
    .from('transactions')
    .select('ledger_id')
    .eq('id', id)
    .single();
  if (!transaction) return { error: '거래를 찾을 수 없습니다.' };

  const { data: membership } = await supabase
    .from('ledger_members')
    .select('id')
    .eq('ledger_id', transaction.ledger_id)
    .eq('user_id', user.id)
    .single();
  if (!membership) return { error: '해당 가계부에 대한 권한이 없습니다.' };

  const type = formData.get('type') as string;
  if (!VALID_TYPES.includes(type)) {
    return { error: '유효하지 않은 거래 유형입니다.' };
  }

  const amount = validateAmount(formData.get('amount'));
  if (amount === null) {
    return { error: '유효한 금액을 입력해주세요. (1~999,999,999)' };
  }

  const description = (formData.get('description') as string || '').trim();
  if (!description) {
    return { error: '제목을 입력해주세요.' };
  }

  const date = validateDate(formData.get('date'));
  if (!date) {
    return { error: '유효한 날짜를 입력해주세요.' };
  }

  const categoryId = formData.get('category_id') as string;
  const paymentMethodId = formData.get('payment_method_id') as string;
  const memo = formData.get('memo') as string;
  const isRecurring = formData.get('is_recurring') === 'true';
  const isFixedExpense = formData.get('is_fixed_expense') === 'true';
  const recurringType = formData.get('recurring_type') as string;
  const recurringEndDate = formData.get('recurring_end_date') as string;

  const { error } = await supabase
    .from('transactions')
    .update({
      type,
      amount,
      title: description,
      category_id: categoryId || null,
      payment_method_id: paymentMethodId || null,
      date,
      memo: memo || null,
      is_recurring: isRecurring,
      recurring_type: isRecurring ? (recurringType || null) : null,
      recurring_end_date: isRecurring && recurringEndDate ? recurringEndDate : null,
      is_fixed_expense: isFixedExpense,
    })
    .eq('id', id);

  if (error) return { error: error.message };

  try {
    revalidatePath('/ledger');
    revalidatePath('/dashboard');
    revalidatePath('/statistics');
  } catch {
    // revalidatePath 실패해도 수정은 성공했으므로 무시
  }
  return { success: true };
}

export async function removeTransaction(id: string) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: '로그인이 필요합니다.' };

  const { data: transaction } = await supabase
    .from('transactions')
    .select('ledger_id')
    .eq('id', id)
    .single();
  if (!transaction) return { error: '거래를 찾을 수 없습니다.' };

  const { data: membership } = await supabase
    .from('ledger_members')
    .select('id')
    .eq('ledger_id', transaction.ledger_id)
    .eq('user_id', user.id)
    .single();
  if (!membership) return { error: '해당 가계부에 대한 권한이 없습니다.' };

  const { error } = await supabase
    .from('transactions')
    .delete()
    .eq('id', id);

  if (error) return { error: error.message };

  try {
    revalidatePath('/ledger');
    revalidatePath('/dashboard');
    revalidatePath('/statistics');
  } catch {
    // revalidatePath 실패해도 삭제는 성공했으므로 무시
  }
  return { success: true };
}
