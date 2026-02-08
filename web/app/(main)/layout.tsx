import { Sidebar } from '@/components/layout/Sidebar';
import { Header } from '@/components/layout/Header';
import { MobileNav } from '@/components/layout/MobileNav';
import { getCurrentUserProfile, getCurrentUserLedger } from '@/lib/queries/ledger';

export default async function MainLayout({ children }: { children: React.ReactNode }) {
  const [profile, ledgerInfo] = await Promise.all([
    getCurrentUserProfile(),
    getCurrentUserLedger(),
  ]);

  const displayName = profile?.display_name || '사용자';
  const color = profile?.color || '#2E7D32';
  const ledgerName = ledgerInfo?.ledger?.name || '내 가계부';
  const currentLedgerId = ledgerInfo?.ledger?.id || '';
  const allLedgers = ledgerInfo?.allLedgers || [];

  return (
    <div className='flex h-screen bg-white'>
      <Sidebar />
      <div className='flex flex-1 flex-col'>
        <Header
          displayName={displayName}
          color={color}
          ledgerName={ledgerName}
          currentLedgerId={currentLedgerId}
          allLedgers={allLedgers}
        />
        <main className='flex-1 overflow-auto bg-surface p-4 pb-20 md:p-7 md:pb-7'>
          {children}
        </main>
      </div>
      <MobileNav />
    </div>
  );
}
