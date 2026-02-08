'use client';

import Link from 'next/link';
import { type ComponentProps, type MouseEvent } from 'react';
import { cn } from '@/lib/utils';
import { useNavigation } from './NavigationProgress';

interface LinkWithProgressProps extends ComponentProps<typeof Link> {
  loadingText?: string;
}

export function LinkWithProgress({
  loadingText,
  children,
  onClick,
  className,
  href,
  ...props
}: LinkWithProgressProps) {
  const { navigatingTo, startNavigation } = useNavigation();
  const hrefString = typeof href === 'string' ? href : href.pathname ?? '';
  const isThisLoading = navigatingTo === hrefString;
  const isAnyLoading = navigatingTo !== null;

  const handleClick = (e: MouseEvent<HTMLAnchorElement>) => {
    startNavigation(hrefString);
    onClick?.(e);
  };

  return (
    <Link
      href={href}
      className={cn(
        className,
        isAnyLoading && !isThisLoading && 'pointer-events-none',
        isThisLoading && 'pointer-events-none opacity-80',
      )}
      onClick={handleClick}
      {...props}
    >
      {isThisLoading && loadingText ? (
        <>
          <span className='mr-2 inline-block h-4 w-4 animate-spin rounded-full border-2 border-current border-t-transparent' />
          {loadingText}
        </>
      ) : (
        children
      )}
    </Link>
  );
}
