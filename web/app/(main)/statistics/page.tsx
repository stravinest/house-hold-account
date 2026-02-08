import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';
import { getCurrentUserLedger, getLedgerMembers } from '@/lib/queries/ledger';
import { getStatisticsData, getDateLabel } from '@/lib/queries/statistics';
import { StatisticsClient } from './statistics-client';

export default async function StatisticsPage() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();

  if (!user) {
    redirect('/login');
  }

  const ledgerInfo = await getCurrentUserLedger();

  if (!ledgerInfo?.ledger) {
    redirect('/login');
  }

  const ledgerId = ledgerInfo.ledger.id;

  // 멤버 목록 + 통계 데이터 병렬 조회
  const now = new Date();
  const initialPeriod = 'month' as const;

  const [rawMembers, initialData] = await Promise.all([
    getLedgerMembers(ledgerId),
    getStatisticsData(ledgerId, initialPeriod, now, user.id),
  ]);

  const members = rawMembers.map((m: any) => ({
    id: m.user_id,
    name: m.profiles?.display_name || m.profiles?.email || '알 수 없음',
    color: m.profiles?.color || '#A8DAB5',
  }));

  const initialDateLabel = getDateLabel(initialPeriod, now);

  return (
    <StatisticsClient
      ledgerId={ledgerId}
      currentUserId={user.id}
      initialPeriod={initialPeriod}
      initialDate={now.toISOString()}
      initialDateLabel={initialDateLabel}
      initialData={initialData}
      members={members}
    />
  );
}
