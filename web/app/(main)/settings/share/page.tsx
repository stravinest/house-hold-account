import { redirect } from 'next/navigation';
import { UserPlus, Mail } from 'lucide-react';
import { getCurrentUserLedger, getLedgerMembers, getLedgerInvites } from '@/lib/queries/ledger';
import { BackLink } from '@/components/shared/BackLink';

const roleLabels: Record<string, { label: string; bg: string; text: string }> = {
  owner: { label: '소유자', bg: 'bg-green-50', text: 'text-primary' },
  admin: { label: '관리자', bg: 'bg-blue-50', text: 'text-blue-600' },
  member: { label: '멤버', bg: 'bg-surface-container', text: 'text-on-surface-variant' },
};

export default async function SharePage() {
  const ledgerInfo = await getCurrentUserLedger();

  if (!ledgerInfo?.ledger) {
    redirect('/login');
  }

  const ledgerId = ledgerInfo.ledger.id;
  const [members, invites] = await Promise.all([
    getLedgerMembers(ledgerId),
    getLedgerInvites(ledgerId),
  ]);

  return (
    <div className='flex flex-col gap-6'>
      {/* Header */}
      <BackLink href='/settings' label='설정' />
      <div className='flex items-center justify-between'>
        <h1 className='text-[22px] font-semibold text-on-surface'>멤버 관리</h1>
        <button className='flex items-center gap-2 rounded-[10px] bg-primary px-4 py-2.5 text-sm font-semibold text-white transition-colors hover:bg-primary/90'>
          <UserPlus size={16} />
          멤버 초대
        </button>
      </div>

      {/* Member List */}
      <div className='rounded-[16px] border border-card-border bg-white p-6'>
        <h2 className='mb-4 text-[15px] font-semibold text-on-surface'>멤버 목록</h2>
        <div className='flex flex-col gap-4'>
          {members.map((member: any) => {
            const profile = member.profiles;
            const displayName = profile?.display_name || profile?.email || '사용자';
            const initial = displayName.charAt(0);
            const color = profile?.color || '#2E7D32';
            const roleInfo = roleLabels[member.role] || roleLabels.member;

            return (
              <div
                key={member.id}
                className='flex items-center justify-between'
              >
                <div className='flex items-center gap-3'>
                  <div
                    className='flex h-10 w-10 items-center justify-center rounded-full'
                    style={{ backgroundColor: color }}
                  >
                    <span className='text-sm font-semibold text-white'>
                      {initial}
                    </span>
                  </div>
                  <div>
                    <p className='text-sm font-medium text-on-surface'>{displayName}</p>
                    <p className='text-xs text-on-surface-variant'>{profile?.email}</p>
                  </div>
                </div>
                <span
                  className={`rounded-[8px] px-3 py-1.5 text-xs font-semibold ${roleInfo.bg} ${roleInfo.text}`}
                >
                  {roleInfo.label}
                </span>
              </div>
            );
          })}
        </div>
      </div>

      {/* Pending Invites */}
      <div className='rounded-[16px] border border-card-border bg-white p-6'>
        <h2 className='mb-4 text-[15px] font-semibold text-on-surface'>대기 중인 초대</h2>
        {invites.length > 0 ? (
          <div className='flex flex-col gap-3'>
            {invites.map((invite: any) => (
              <div
                key={invite.id}
                className='flex items-center justify-between border-b border-separator py-3 last:border-b-0'
              >
                <div className='flex items-center gap-3'>
                  <Mail size={16} className='text-on-surface-variant' />
                  <div>
                    <p className='text-sm font-medium text-on-surface'>
                      {invite.invitee_email}
                    </p>
                    <p className='text-xs text-on-surface-variant'>
                      {roleLabels[invite.role]?.label || '멤버'}
                    </p>
                  </div>
                </div>
                <span className='rounded-[8px] bg-yellow-50 px-3 py-1.5 text-xs font-semibold text-yellow-600'>
                  대기 중
                </span>
              </div>
            ))}
          </div>
        ) : (
          <div className='flex flex-col items-center gap-3 py-12'>
            <Mail size={32} className='text-on-surface-variant' />
            <p className='text-sm text-on-surface-variant'>대기 중인 초대가 없습니다</p>
          </div>
        )}
      </div>
    </div>
  );
}
