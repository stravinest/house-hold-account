import { createClient } from '@/lib/supabase/server';
import type { CategoryInsert } from '@/lib/types/database';

export async function getCategories(ledgerId: string, type?: 'income' | 'expense' | 'asset') {
  const supabase = await createClient();

  let query = supabase
    .from('categories')
    .select('*')
    .eq('ledger_id', ledgerId)
    .order('sort_order', { ascending: true });

  if (type) {
    query = query.eq('type', type);
  }

  const { data, error } = await query;
  if (error) throw error;
  return data || [];
}

export async function createCategory(data: CategoryInsert) {
  const supabase = await createClient();

  const { data: result, error } = await supabase
    .from('categories')
    .insert(data)
    .select()
    .single();

  if (error) throw error;
  return result;
}

export async function updateCategory(id: string, data: Partial<CategoryInsert>) {
  const supabase = await createClient();

  const { data: result, error } = await supabase
    .from('categories')
    .update(data)
    .eq('id', id)
    .select()
    .single();

  if (error) throw error;
  return result;
}

export async function deleteCategory(id: string) {
  const supabase = await createClient();

  const { error } = await supabase
    .from('categories')
    .delete()
    .eq('id', id);

  if (error) throw error;
}
