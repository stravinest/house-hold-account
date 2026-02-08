import Link from 'next/link';
import {
  User,
  Mail,
  Palette,
  Users,
  Tag,
  CreditCard,
  Repeat,
  FileText,
  Shield,
  Info,
  LogOut,
  ChevronRight,
} from 'lucide-react';
import { signOut } from '@/lib/actions/auth';
import { getCurrentUserProfile } from '@/lib/queries/ledger';

const managementItems = [
  { label: '멤버 관리', href: '/settings/share', icon: Users },
  { label: '카테고리 관리', href: '/settings/categories', icon: Tag },
  { label: '결제수단 관리', href: '/settings/payment-methods', icon: CreditCard },
  { label: '고정비 관리', href: '/settings/fixed-costs', icon: Repeat },
];

const infoItems = [
  { label: '이용약관', href: '/settings/terms', icon: FileText },
  { label: '개인정보처리방침', href: '/settings/privacy', icon: Shield },
  { label: '앱 버전', href: '#', icon: Info, extra: 'v1.0.0' },
];

export default async function SettingsPage() {
  const profile = await getCurrentUserProfile();
  const displayName = profile?.display_name || '사용자';
  const email = profile?.email || '';
  const initial = displayName.charAt(0);
  const color = profile?.color || '#2E7D32';

  return (
    <div className='flex flex-col gap-6'>
      <h1 className='text-[22px] font-semibold text-on-surface'>설정</h1>

      {/* Profile Card */}
      <div className='rounded-[16px] border border-card-border bg-white p-6'>
        <div className='flex items-center gap-4'>
          <div
            className='flex h-14 w-14 items-center justify-center rounded-full'
            style={{ backgroundColor: color }}
          >
            <span className='text-xl font-bold text-white'>{initial}</span>
          </div>
          <div className='flex flex-1 flex-col gap-2'>
            <div className='flex items-center gap-2'>
              <User size={14} className='text-on-surface-variant' />
              <span className='text-sm font-medium text-on-surface'>{displayName}</span>
            </div>
            <div className='flex items-center gap-2'>
              <Mail size={14} className='text-on-surface-variant' />
              <span className='text-sm text-on-surface-variant'>{email}</span>
            </div>
            <div className='flex items-center gap-2'>
              <Palette size={14} className='text-on-surface-variant' />
              <div
                className='h-4 w-4 rounded-full border border-card-border'
                style={{ backgroundColor: color }}
              />
            </div>
          </div>
        </div>
      </div>

      {/* Management + Info in 2 columns */}
      <div className='grid grid-cols-1 gap-4 md:grid-cols-2'>
        {/* Management */}
        <div className='rounded-[16px] border border-card-border bg-white'>
          <div className='border-b border-separator px-5 py-3'>
            <h2 className='text-sm font-semibold text-on-surface'>가계부 관리</h2>
          </div>
          {managementItems.map((item, index) => {
            const Icon = item.icon;
            return (
              <Link
                key={item.href}
                href={item.href}
                className={`flex items-center justify-between px-5 py-3.5 transition-colors hover:bg-surface ${
                  index < managementItems.length - 1
                    ? 'border-b border-separator'
                    : ''
                }`}
              >
                <div className='flex items-center gap-3'>
                  <Icon size={18} className='text-on-surface-variant' />
                  <span className='text-sm font-medium text-on-surface'>
                    {item.label}
                  </span>
                </div>
                <ChevronRight size={16} className='text-on-surface-variant' />
              </Link>
            );
          })}
        </div>

        {/* Info */}
        <div className='rounded-[16px] border border-card-border bg-white'>
          <div className='border-b border-separator px-5 py-3'>
            <h2 className='text-sm font-semibold text-on-surface'>정보</h2>
          </div>
          {infoItems.map((item, index) => {
            const Icon = item.icon;
            return (
              <Link
                key={item.label}
                href={item.href}
                className={`flex items-center justify-between px-5 py-3.5 transition-colors hover:bg-surface ${
                  index < infoItems.length - 1
                    ? 'border-b border-separator'
                    : ''
                }`}
              >
                <div className='flex items-center gap-3'>
                  <Icon size={18} className='text-on-surface-variant' />
                  <span className='text-sm font-medium text-on-surface'>
                    {item.label}
                  </span>
                </div>
                {item.extra ? (
                  <span className='text-xs text-on-surface-variant'>{item.extra}</span>
                ) : (
                  <ChevronRight size={16} className='text-on-surface-variant' />
                )}
              </Link>
            );
          })}
        </div>
      </div>

      {/* Logout Button */}
      <form action={signOut}>
        <button
          type='submit'
          className='flex w-full items-center justify-center gap-2 rounded-[16px] border border-expense bg-white py-3.5 text-sm font-semibold text-expense transition-colors hover:bg-red-50'
        >
          <LogOut size={16} />
          로그아웃
        </button>
      </form>
    </div>
  );
}
