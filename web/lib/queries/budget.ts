import { createClient } from '@/lib/supabase/server';
import type { BudgetInsert } from '@/lib/types/database';

export async function getBudgets(ledgerId: string, year: number, month: number) {
  const supabase = await createClient();

  const { data, error } = await supabase
    .from('budgets')
    .select('*, categories(name, icon, color)')
    .eq('ledger_id', ledgerId)
    .eq('year', year)
    .eq('month', month);

  if (error) throw error;
  return data || [];
}

export async function upsertBudget(data: BudgetInsert) {
  const supabase = await createClient();

  const { data: result, error } = await supabase
    .from('budgets')
    .upsert(data, {
      onConflict: 'ledger_id,category_id,year,month',
    })
    .select()
    .single();

  if (error) throw error;
  return result;
}

export async function deleteBudget(id: string) {
  const supabase = await createClient();

  const { error } = await supabase
    .from('budgets')
    .delete()
    .eq('id', id);

  if (error) throw error;
}
