import { createClient } from '@/lib/supabase/server';

export async function getCurrentUserProfile() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();

  if (!user) return null;

  const { data: profile } = await supabase
    .from('profiles')
    .select('*')
    .eq('id', user.id)
    .single();

  return profile;
}

export async function getCurrentUserLedger() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();

  if (!user) return null;

  // 사용자가 멤버인 가계부 목록
  const { data: members } = await supabase
    .from('ledger_members')
    .select('ledger_id, role, ledgers(*)')
    .eq('user_id', user.id)
    .order('created_at', { ascending: true });

  if (!members || members.length === 0) return null;

  // 첫 번째 가계부 반환 (기본)
  return {
    ledger: (members[0] as any).ledgers,
    role: members[0].role,
    allLedgers: members.map((m: any) => ({ ...m.ledgers, role: m.role })),
  };
}

export async function getLedgerMembers(ledgerId: string) {
  const supabase = await createClient();

  const { data } = await supabase
    .from('ledger_members')
    .select('*, profiles(*)')
    .eq('ledger_id', ledgerId)
    .order('created_at', { ascending: true });

  return data || [];
}

export async function getLedgerInvites(ledgerId: string) {
  const supabase = await createClient();

  const { data } = await supabase
    .from('ledger_invites')
    .select('*')
    .eq('ledger_id', ledgerId)
    .eq('status', 'pending')
    .order('created_at', { ascending: false });

  return data || [];
}
