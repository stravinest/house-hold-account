'use client';

import Link from 'next/link';
import { ArrowLeft } from 'lucide-react';

type BackLinkProps = {
  href: string;
  label: string;
};

export function BackLink({ href, label }: BackLinkProps) {
  return (
    <Link
      href={href}
      className='flex items-center gap-2 text-on-surface-variant transition-colors hover:text-on-surface'
    >
      <ArrowLeft size={20} />
      <span className='text-sm font-medium'>{label}</span>
    </Link>
  );
}
