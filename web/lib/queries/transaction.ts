import { createClient } from '@/lib/supabase/server';
import type { TransactionInsert } from '@/lib/types/database';

export async function getTransactions(ledgerId: string, options?: {
  month?: number;
  year?: number;
  type?: 'income' | 'expense' | 'asset';
  limit?: number;
  search?: string;
}) {
  const supabase = await createClient();

  let query = supabase
    .from('transactions')
    .select('*, categories(name, icon, color), payment_methods(name), profiles(display_name, color)')
    .eq('ledger_id', ledgerId)
    .order('date', { ascending: false });

  if (options?.type) {
    query = query.eq('type', options.type);
  }

  if (options?.year && options?.month) {
    const startDate = `${options.year}-${String(options.month).padStart(2, '0')}-01`;
    const endMonth = options.month === 12 ? 1 : options.month + 1;
    const endYear = options.month === 12 ? options.year + 1 : options.year;
    const endDate = `${endYear}-${String(endMonth).padStart(2, '0')}-01`;
    query = query.gte('date', startDate).lt('date', endDate);
  }

  if (options?.search) {
    query = query.ilike('title', `%${options.search}%`);
  }

  if (options?.limit) {
    query = query.limit(options.limit);
  }

  const { data, error } = await query;

  if (error) throw error;
  return data || [];
}

export async function getMonthSummary(ledgerId: string, year: number, month: number) {
  const transactions = await getTransactions(ledgerId, { year, month });

  const income = transactions
    .filter((t) => t.type === 'income')
    .reduce((sum, t) => sum + t.amount, 0);
  const expense = transactions
    .filter((t) => t.type === 'expense')
    .reduce((sum, t) => sum + t.amount, 0);

  return {
    income,
    expense,
    balance: income - expense,
    transactionCount: transactions.length,
  };
}

export async function createTransaction(data: TransactionInsert) {
  const supabase = await createClient();

  const { data: result, error } = await supabase
    .from('transactions')
    .insert(data)
    .select()
    .single();

  if (error) throw error;
  return result;
}

export async function updateTransaction(id: string, data: Partial<TransactionInsert>) {
  const supabase = await createClient();

  const { data: result, error } = await supabase
    .from('transactions')
    .update(data)
    .eq('id', id)
    .select()
    .single();

  if (error) throw error;
  return result;
}

export async function deleteTransaction(id: string) {
  const supabase = await createClient();

  const { error } = await supabase
    .from('transactions')
    .delete()
    .eq('id', id);

  if (error) throw error;
}
