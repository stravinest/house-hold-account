'use client';

import { useState, useRef, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { signOut } from '@/lib/actions/auth';
import { LogOut, X, Check } from 'lucide-react';
import { createClient } from '@/lib/supabase/client';

type LedgerInfo = {
  id: string;
  name: string;
  role: string;
  created_at?: string;
};

type HeaderProps = {
  displayName: string;
  color: string;
  ledgerName: string;
  currentLedgerId: string;
  allLedgers: LedgerInfo[];
};

const ROLE_LABELS: Record<string, string> = {
  owner: '소유자',
  admin: '관리자',
  member: '멤버',
};

export function Header({
  displayName,
  color,
  ledgerName,
  currentLedgerId,
  allLedgers,
}: HeaderProps) {
  const router = useRouter();
  const [showUserMenu, setShowUserMenu] = useState(false);
  const [showLedgerMenu, setShowLedgerMenu] = useState(false);
  const [ledgerMemberCounts, setLedgerMemberCounts] = useState<Record<string, number>>({});
  const [monthTxCount, setMonthTxCount] = useState<number | null>(null);
  const ledgerRef = useRef<HTMLDivElement>(null);
  const userRef = useRef<HTMLDivElement>(null);
  const initial = displayName.charAt(0);

  // 드롭다운 외부 클릭 시 닫기
  useEffect(() => {
    function handleClickOutside(e: MouseEvent) {
      if (ledgerRef.current && !ledgerRef.current.contains(e.target as Node)) {
        setShowLedgerMenu(false);
      }
      if (userRef.current && !userRef.current.contains(e.target as Node)) {
        setShowUserMenu(false);
      }
    }
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  // 가계부 드롭다운 열릴 때 멤버 수 + 이번 달 거래 수 조회
  useEffect(() => {
    if (!showLedgerMenu) return;

    async function fetchLedgerDetails() {
      const supabase = createClient();

      // 각 가계부의 멤버 수 조회
      const counts: Record<string, number> = {};
      for (const ledger of allLedgers) {
        const { count } = await supabase
          .from('ledger_members')
          .select('*', { count: 'exact', head: true })
          .eq('ledger_id', ledger.id);
        counts[ledger.id] = count || 0;
      }
      setLedgerMemberCounts(counts);

      // 현재 가계부 이번 달 거래 수
      const now = new Date();
      const y = now.getFullYear();
      const m = now.getMonth() + 1;
      const startDate = `${y}-${String(m).padStart(2, '0')}-01`;
      const nextMonth = m === 12 ? 1 : m + 1;
      const nextYear = m === 12 ? y + 1 : y;
      const endDate = `${nextYear}-${String(nextMonth).padStart(2, '0')}-01`;

      const { count: txCount } = await supabase
        .from('transactions')
        .select('*', { count: 'exact', head: true })
        .eq('ledger_id', currentLedgerId)
        .gte('date', startDate)
        .lt('date', endDate);

      setMonthTxCount(txCount || 0);
    }

    fetchLedgerDetails();
  }, [showLedgerMenu, allLedgers, currentLedgerId]);

  const handleLedgerSelect = (ledgerId: string) => {
    if (ledgerId === currentLedgerId) {
      setShowLedgerMenu(false);
      return;
    }
    // TODO: 가계부 전환 로직 (쿠키/세션에 선택된 가계부 저장 후 리로드)
    setShowLedgerMenu(false);
    router.refresh();
  };

  const currentLedger = allLedgers.find((l) => l.id === currentLedgerId);
  const currentRole = currentLedger?.role || 'owner';

  // 가계부 아이콘 색상 배열
  const ledgerColors = ['#2E7D32', '#42A5F5', '#FF7043', '#AB47BC', '#26A69A'];

  return (
    <header className='flex h-[60px] items-center justify-between border-b border-card-border bg-white px-7'>
      {/* Ledger Selector */}
      <div className='relative' ref={ledgerRef}>
        <button
          onClick={() => {
            setShowLedgerMenu(!showLedgerMenu);
            setShowUserMenu(false);
          }}
          className='flex items-center gap-2 rounded-[10px] border border-[#E8E8E8] bg-tab-bg px-[14px] py-2 transition-colors hover:bg-surface-container'
        >
          <span className='text-sm font-medium text-on-surface'>{ledgerName}</span>
          <span className={`text-[10px] text-on-surface-variant transition-transform ${showLedgerMenu ? 'rotate-180' : ''}`}>
            &#9660;
          </span>
        </button>

        {showLedgerMenu && (
          <div className='absolute left-0 top-12 z-20 w-[300px] rounded-[12px] border border-card-border bg-white shadow-lg'>
            {/* 헤더 */}
            <div className='flex items-center justify-between px-4 pb-3 pt-4'>
              <span className='text-[15px] font-semibold text-on-surface'>가계부 선택</span>
              <button
                onClick={() => setShowLedgerMenu(false)}
                className='flex h-7 w-7 items-center justify-center rounded-full text-on-surface-variant transition-colors hover:bg-surface-container'
              >
                <X size={16} />
              </button>
            </div>

            <div className='h-px w-full bg-separator' />

            {/* 가계부 목록 */}
            <div className='py-1'>
              {allLedgers.map((ledger, idx) => {
                const isSelected = ledger.id === currentLedgerId;
                const colorIdx = idx % ledgerColors.length;
                const memberCount = ledgerMemberCounts[ledger.id];
                const roleLabel = ROLE_LABELS[ledger.role] || ledger.role;

                return (
                  <button
                    key={ledger.id}
                    onClick={() => handleLedgerSelect(ledger.id)}
                    className={`flex w-full items-center justify-between px-4 py-3 text-left transition-colors ${
                      isSelected ? 'bg-tab-bg' : 'hover:bg-surface-container'
                    }`}
                  >
                    <div className='flex items-center gap-3'>
                      <div
                        className='flex h-9 w-9 items-center justify-center rounded-full'
                        style={{ backgroundColor: ledgerColors[colorIdx] }}
                      >
                        <span className='text-[13px] font-semibold text-white'>
                          {ledger.name.charAt(0)}
                        </span>
                      </div>
                      <div className='text-left'>
                        <p className={`text-sm ${isSelected ? 'font-semibold' : 'font-medium'} text-on-surface`}>
                          {ledger.name}
                        </p>
                        <p className='text-xs text-on-surface-variant'>
                          {memberCount !== undefined ? `멤버 ${memberCount}명` : '...'}
                          {' / '}
                          {roleLabel}
                        </p>
                      </div>
                    </div>
                    {isSelected && <Check size={16} className='text-primary' />}
                  </button>
                );
              })}
            </div>

            <div className='h-px w-full bg-separator' />

            {/* 가계부 정보 */}
            <div className='px-4 py-3'>
              <p className='mb-2 text-xs font-semibold text-on-surface-variant'>가계부 정보</p>
              <div className='flex flex-col gap-1.5'>
                <div className='flex items-center justify-between'>
                  <span className='text-xs text-[#79747E]'>생성일</span>
                  <span className='text-xs font-medium text-on-surface'>
                    {currentLedger?.created_at
                      ? new Date(currentLedger.created_at).toLocaleDateString('ko-KR', {
                          year: 'numeric',
                          month: '2-digit',
                          day: '2-digit',
                        })
                      : '-'}
                  </span>
                </div>
                <div className='flex items-center justify-between'>
                  <span className='text-xs text-[#79747E]'>이번 달 거래</span>
                  <span className='text-xs font-medium text-on-surface'>
                    {monthTxCount !== null ? `${monthTxCount}건` : '...'}
                  </span>
                </div>
                <div className='flex items-center justify-between'>
                  <span className='text-xs text-[#79747E]'>내 역할</span>
                  <span className='text-xs font-medium text-primary'>
                    {ROLE_LABELS[currentRole] || currentRole}
                  </span>
                </div>
              </div>
            </div>
          </div>
        )}
      </div>

      {/* User Section */}
      <div className='relative' ref={userRef}>
        <button
          onClick={() => {
            setShowUserMenu(!showUserMenu);
            setShowLedgerMenu(false);
          }}
          className='flex items-center gap-3'
        >
          <span className='text-sm text-on-surface-variant'>{displayName}</span>
          <div
            className='flex h-9 w-9 items-center justify-center rounded-full'
            style={{ backgroundColor: color }}
          >
            <span className='text-sm font-semibold text-white'>{initial}</span>
          </div>
        </button>

        {showUserMenu && (
          <div className='absolute right-0 top-12 z-10 w-48 rounded-[12px] border border-card-border bg-white py-1 shadow-lg'>
            <form action={signOut}>
              <button
                type='submit'
                className='flex w-full items-center gap-2 px-4 py-2.5 text-left text-sm text-expense transition-colors hover:bg-surface-container'
              >
                <LogOut size={16} />
                로그아웃
              </button>
            </form>
          </div>
        )}
      </div>
    </header>
  );
}
