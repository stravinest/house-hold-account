'use client';

import { useEffect, useRef } from 'react';
import { X, Loader2 } from 'lucide-react';
import { formatAmount } from '@/lib/utils';
import type { CategoryTopItem } from '@/lib/actions/statistics';

type CategoryDetailPopupProps = {
  categoryName: string;
  categoryColor: string;
  categoryPercentage: number;
  totalAmount: number;
  type: 'expense' | 'income' | 'asset';
  items: CategoryTopItem[];
  loading: boolean;
  error?: string | null;
  periodLabel: string;
  onClose: () => void;
};

const TYPE_CONFIG = {
  expense: {
    listTitle: '지출 항목 TOP 5',
    amountColor: 'text-expense',
    rankBg: '#2E7D32',
    rankBgSub: '#E8F5E9',
    rankTextMain: '#FFFFFF',
    rankTextSub: '#2E7D32',
    amountPrefix: '-',
  },
  income: {
    listTitle: '수입 항목 TOP 5',
    amountColor: 'text-income',
    rankBg: '#2E7D32',
    rankBgSub: '#E8F5E9',
    rankTextMain: '#FFFFFF',
    rankTextSub: '#2E7D32',
    amountPrefix: '+',
  },
  asset: {
    listTitle: '자산 항목 TOP 5',
    amountColor: 'text-[#1565C0]',
    rankBg: '#1565C0',
    rankBgSub: '#E8F5E9',
    rankTextMain: '#FFFFFF',
    rankTextSub: '#2E7D32',
    amountPrefix: '',
  },
};

function getTotalLabel(type: 'expense' | 'income' | 'asset', periodLabel: string): string {
  const periodPrefix = periodLabel.includes('년') && !periodLabel.includes('월')
    ? '연간'
    : periodLabel.includes('주차')
      ? '이번 주'
      : periodLabel.includes('일')
        ? '오늘'
        : '이번 달';

  switch (type) {
    case 'expense': return `${periodPrefix} 총액`;
    case 'income': return `${periodPrefix} 총액`;
    case 'asset': return '총 자산 금액';
  }
}

export function CategoryDetailPopup({
  categoryName,
  categoryColor,
  categoryPercentage,
  totalAmount,
  type,
  items,
  loading,
  error,
  periodLabel,
  onClose,
}: CategoryDetailPopupProps) {
  const popupRef = useRef<HTMLDivElement>(null);
  const config = TYPE_CONFIG[type];
  const totalLabel = getTotalLabel(type, periodLabel);

  // body 스크롤 방지
  useEffect(() => {
    const originalOverflow = document.body.style.overflow;
    document.body.style.overflow = 'hidden';
    return () => {
      document.body.style.overflow = originalOverflow;
    };
  }, []);

  // 바깥 클릭 + ESC 닫기
  useEffect(() => {
    function handleClickOutside(e: MouseEvent) {
      if (popupRef.current && !popupRef.current.contains(e.target as Node)) {
        onClose();
      }
    }
    function handleEscape(e: KeyboardEvent) {
      if (e.key === 'Escape') onClose();
    }
    document.addEventListener('mousedown', handleClickOutside);
    document.addEventListener('keydown', handleEscape);
    return () => {
      document.removeEventListener('mousedown', handleClickOutside);
      document.removeEventListener('keydown', handleEscape);
    };
  }, [onClose]);

  return (
    <div className='fixed inset-0 z-50 flex items-center justify-center bg-black/40'>
      <div
        ref={popupRef}
        className='w-[400px] max-w-[90vw] overflow-hidden rounded-[20px] bg-white shadow-[0_8px_32px_rgba(0,0,0,0.15),0_2px_8px_rgba(0,0,0,0.05)]'
      >
        {/* Header */}
        <div className='flex flex-col gap-4 px-6 pb-5 pt-6'>
          <div className='flex items-center justify-between'>
            <div className='flex items-center gap-2.5'>
              <div
                className='h-3.5 w-3.5 rounded-full'
                style={{ backgroundColor: categoryColor }}
              />
              <span className='text-lg font-semibold text-on-surface'>{categoryName}</span>
              <span className='text-sm font-medium text-on-surface-variant'>{categoryPercentage}%</span>
            </div>
            <button
              onClick={onClose}
              className='flex h-8 w-8 items-center justify-center rounded-full bg-surface-container transition-colors hover:bg-surface-container-high'
            >
              <X size={16} className='text-on-surface-variant' />
            </button>
          </div>
          <div className='flex items-center gap-2'>
            <span className='text-[28px] font-bold text-on-surface'>
              {type === 'expense' ? '-' : type === 'income' ? '+' : ''}{formatAmount(totalAmount)}
            </span>
            <span className='text-[13px] text-on-surface-variant'>{totalLabel}</span>
          </div>
        </div>

        {/* Divider */}
        <div className='h-px bg-card-border' />

        {/* List Section */}
        <div className='flex flex-col gap-1 px-6 pb-6'>
          <div className='flex items-center justify-between pb-3'>
            <span className='text-sm font-semibold text-on-surface'>{config.listTitle}</span>
            <span className='text-xs text-on-surface-variant'>{periodLabel}</span>
          </div>

          {loading ? (
            <div className='flex items-center justify-center py-8'>
              <Loader2 size={20} className='animate-spin text-primary' />
            </div>
          ) : error ? (
            <div className='rounded-lg border border-expense/20 bg-expense/5 px-4 py-4 text-center text-sm text-expense'>
              {error}
            </div>
          ) : items.length === 0 ? (
            <p className='py-6 text-center text-sm text-on-surface-variant'>해당 기간에 거래가 없습니다</p>
          ) : (
            items.map((item) => (
              <div
                key={`top-${item.rank}`}
                className={`flex items-center justify-between py-3 ${item.rank < items.length ? 'border-b border-[#F5F5F3]' : ''}`}
              >
                <div className='flex items-center gap-3'>
                  <div
                    className='flex h-[26px] w-[26px] items-center justify-center rounded-lg text-xs font-bold'
                    style={{
                      backgroundColor: item.rank === 1 ? config.rankBg : config.rankBgSub,
                      color: item.rank === 1 ? config.rankTextMain : config.rankTextSub,
                    }}
                  >
                    {item.rank}
                  </div>
                  <div className='flex flex-col gap-0.5'>
                    <span className='text-sm font-medium text-on-surface'>{item.title}</span>
                    <div className='flex items-center gap-1.5'>
                      <span className='text-[11px] text-on-surface-variant'>{item.date}</span>
                      <div className='h-[3px] w-[3px] rounded-full bg-on-surface-variant' />
                      <div
                        className='h-3.5 w-3.5 rounded-full'
                        style={{ backgroundColor: item.userColor }}
                      />
                      <span className='text-[11px] text-on-surface-variant'>{item.userName}</span>
                    </div>
                  </div>
                </div>
                <div className='flex flex-col items-end gap-0.5'>
                  <span className={`text-sm font-semibold ${config.amountColor}`}>
                    {config.amountPrefix}{formatAmount(item.amount)}
                  </span>
                  <span className='text-[11px] text-on-surface-variant'>{item.percentage}%</span>
                </div>
              </div>
            ))
          )}
        </div>
      </div>
    </div>
  );
}
