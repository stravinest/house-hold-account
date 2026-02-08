'use server';

import { revalidatePath } from 'next/cache';
import { createClient } from '@/lib/supabase/server';

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

  const type = formData.get('type') as 'income' | 'expense';
  const amount = Number(formData.get('amount'));
  const description = formData.get('description') as string;
  const categoryId = formData.get('category_id') as string;
  const paymentMethodId = formData.get('payment_method_id') as string;
  const date = formData.get('date') as string;
  const memo = formData.get('memo') as string;
  const isRecurring = formData.get('is_recurring') === 'true';
  const isFixedExpense = formData.get('is_fixed_expense') === 'true';

  if (!amount || !description || !date) {
    return { error: '금액, 내용, 날짜는 필수 항목입니다.' };
  }

  const { error } = await supabase
    .from('transactions')
    .insert({
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
      is_fixed_expense: isFixedExpense,
    });

  if (error) return { error: error.message };

  revalidatePath('/ledger');
  revalidatePath('/dashboard');
  revalidatePath('/statistics');
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

  revalidatePath('/ledger');
  revalidatePath('/dashboard');
  revalidatePath('/statistics');
  return { success: true };
}
