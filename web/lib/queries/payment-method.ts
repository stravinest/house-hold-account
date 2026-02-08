import { createClient } from '@/lib/supabase/server';
import type { PaymentMethodInsert } from '@/lib/types/database';

export async function getPaymentMethods(ledgerId: string) {
  const supabase = await createClient();

  const { data, error } = await supabase
    .from('payment_methods')
    .select('*')
    .eq('ledger_id', ledgerId)
    .order('created_at', { ascending: true });

  if (error) throw error;
  return data || [];
}

export async function createPaymentMethod(data: PaymentMethodInsert) {
  const supabase = await createClient();

  const { data: result, error } = await supabase
    .from('payment_methods')
    .insert(data)
    .select()
    .single();

  if (error) throw error;
  return result;
}

export async function updatePaymentMethod(id: string, data: Partial<PaymentMethodInsert>) {
  const supabase = await createClient();

  const { data: result, error } = await supabase
    .from('payment_methods')
    .update(data)
    .eq('id', id)
    .select()
    .single();

  if (error) throw error;
  return result;
}

export async function deletePaymentMethod(id: string) {
  const supabase = await createClient();

  const { error } = await supabase
    .from('payment_methods')
    .delete()
    .eq('id', id);

  if (error) throw error;
}
