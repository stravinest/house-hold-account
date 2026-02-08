'use client';

import { useState, useRef, useCallback } from 'react';
import { createClient } from '@/lib/supabase/client';
import type { TransactionDetail } from '@/components/shared/TransactionDetailModal';

type SupabaseTransactionRow = {
  id: string;
  title: string;
  amount: number;
  type: string;
  date: string;
  memo?: string | null;
  is_fixed_expense?: boolean;
  is_recurring?: boolean;
  recurring_type?: string | null;
  categories?: { name: string; icon: string; color: string } | null;
  payment_methods?: { name: string } | null;
  profiles?: { display_name: string; color: string } | null;
};

function mapToTransactionDetail(row: SupabaseTransactionRow): TransactionDetail {
  return {
    id: row.id,
    description: row.title,
    amount: row.amount,
    type: row.type as 'income' | 'expense',
    date: row.date,
    memo: row.memo || undefined,
    categoryName: row.categories?.name || undefined,
    categoryIcon: row.categories?.icon || undefined,
    categoryColor: row.categories?.color || undefined,
    paymentMethodName: row.payment_methods?.name || undefined,
    authorName: row.profiles?.display_name || undefined,
    authorColor: row.profiles?.color || undefined,
    isFixedExpense: row.is_fixed_expense || false,
    isRecurring: row.is_recurring || false,
    recurringType: row.recurring_type || undefined,
  };
}

export function useTransactionDetail() {
  const [selectedTxId, setSelectedTxId] = useState<string | null>(null);
  const [detailModalTx, setDetailModalTx] = useState<TransactionDetail | null>(null);
  const [detailLoading, setDetailLoading] = useState(false);
  const clickTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const isLoadingRef = useRef(false);

  const handleTxClick = useCallback((txId: string) => {
    if (clickTimerRef.current) {
      clearTimeout(clickTimerRef.current);
      clickTimerRef.current = null;
    }
    clickTimerRef.current = setTimeout(() => {
      setSelectedTxId(txId);
      clickTimerRef.current = null;
    }, 250);
  }, []);

  const handleTxDoubleClick = useCallback(async (txId: string) => {
    if (clickTimerRef.current) {
      clearTimeout(clickTimerRef.current);
      clickTimerRef.current = null;
    }
    if (isLoadingRef.current) return;

    setSelectedTxId(txId);
    setDetailLoading(true);
    isLoadingRef.current = true;

    try {
      const supabase = createClient();
      const { data: txData } = await supabase
        .from('transactions')
        .select(
          '*, categories(name, icon, color), payment_methods(name), profiles(display_name, color)'
        )
        .eq('id', txId)
        .single();

      if (txData) {
        setDetailModalTx(mapToTransactionDetail(txData as SupabaseTransactionRow));
      }
    } catch {
      // 상세 조회 실패 시 무시
    } finally {
      setDetailLoading(false);
      isLoadingRef.current = false;
    }
  }, []);

  const closeDetail = useCallback(() => {
    setDetailModalTx(null);
    setSelectedTxId(null);
  }, []);

  return {
    selectedTxId,
    detailModalTx,
    detailLoading,
    handleTxClick,
    handleTxDoubleClick,
    closeDetail,
  };
}
