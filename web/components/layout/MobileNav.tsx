'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import {
  LayoutDashboard,
  Receipt,
  PieChart,
  Landmark,
  Settings,
} from 'lucide-react';

const navigation = [
  { name: '대시보드', href: '/dashboard', icon: LayoutDashboard },
  { name: '거래', href: '/ledger', icon: Receipt },
  { name: '통계', href: '/statistics', icon: PieChart },
  { name: '자산', href: '/asset', icon: Landmark },
  { name: '설정', href: '/settings', icon: Settings },
];

export function MobileNav() {
  const pathname = usePathname();

  return (
    <nav className='fixed bottom-0 left-0 right-0 z-40 flex border-t border-card-border bg-white md:hidden'>
      {navigation.map((item) => {
        const isActive =
          pathname === item.href ||
          (item.href !== '/settings' && pathname.startsWith(item.href + '/'));
        const Icon = item.icon;
        return (
          <Link
            key={item.name}
            href={item.href}
            className={`flex flex-1 flex-col items-center gap-1 py-2 text-xs transition-colors ${
              isActive ? 'text-primary' : 'text-on-surface-variant'
            }`}
          >
            <Icon size={20} />
            <span className='font-medium'>{item.name}</span>
          </Link>
        );
      })}
    </nav>
  );
}
