'use client';

import { ChevronLeft, ChevronRight } from 'lucide-react';

type DateNavigationProps = {
  label: string;
  onPrev: () => void;
  onNext: () => void;
};

export function DateNavigation({ label, onPrev, onNext }: DateNavigationProps) {
  return (
    <div className='flex items-center gap-2'>
      <button
        onClick={onPrev}
        className='flex h-8 w-8 items-center justify-center rounded-[8px] bg-tab-bg transition-colors hover:bg-surface-container'
      >
        <ChevronLeft size={16} className='text-on-surface-variant' />
      </button>
      <span className='min-w-[100px] text-center text-[15px] font-semibold text-on-surface'>
        {label}
      </span>
      <button
        onClick={onNext}
        className='flex h-8 w-8 items-center justify-center rounded-[8px] bg-tab-bg transition-colors hover:bg-surface-container'
      >
        <ChevronRight size={16} className='text-on-surface-variant' />
      </button>
    </div>
  );
}
