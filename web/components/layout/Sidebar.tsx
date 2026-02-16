'use client';

import Link from 'next/link';
import Image from 'next/image';
import { usePathname } from 'next/navigation';
import {
  LayoutDashboard,
  Receipt,
  PieChart,
  Landmark,
  Settings,
  Loader2,
} from 'lucide-react';
import { useNavigation } from '@/components/ui/NavigationProgress';

const navigation = [
  { name: '대시보드', href: '/dashboard', icon: LayoutDashboard },
  { name: '거래', href: '/ledger', icon: Receipt },
  { name: '통계', href: '/statistics', icon: PieChart },
  { name: '자산', href: '/asset', icon: Landmark },
  { name: '설정', href: '/settings', icon: Settings },
];

export function Sidebar() {
  const pathname = usePathname();
  const { navigatingTo, startNavigation } = useNavigation();

  return (
    <aside className='hidden h-screen w-[260px] flex-col border-r border-card-border bg-sidebar px-4 py-6 md:flex'>
      {/* Logo */}
      <div className='flex items-center gap-[10px] px-2'>
        <Image src='/app_icon.png' alt='logo' width={32} height={32} />
        <span className='text-base font-semibold text-on-surface'>우생가계부</span>
      </div>

      {/* Navigation */}
      <nav className='mt-7 flex flex-col gap-1'>
        {navigation.map((item) => {
          const isActive =
            pathname === item.href ||
            (item.href !== '/settings' && pathname.startsWith(item.href + '/'));
          const isNavigating = navigatingTo === item.href;
          const Icon = item.icon;
          return (
            <Link
              key={item.name}
              href={item.href}
              onClick={() => startNavigation(item.href)}
              className={`flex items-center gap-[10px] rounded-[10px] px-[14px] py-[10px] text-sm font-medium transition-colors ${
                isActive
                  ? 'bg-primary text-white'
                  : isNavigating
                    ? 'bg-primary/10 text-primary'
                    : 'text-on-surface-variant hover:bg-surface-container hover:text-on-surface'
              }`}
            >
              {isNavigating ? (
                <Loader2 size={20} className='animate-spin' />
              ) : (
                <Icon size={20} />
              )}
              <span>{item.name}</span>
            </Link>
          );
        })}
      </nav>
    </aside>
  );
}
