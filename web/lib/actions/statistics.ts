'use server';

import { createClient } from '@/lib/supabase/server';
import { getStatisticsData, getDateLabel, getDateRange } from '@/lib/queries/statistics';
import type { PeriodType, StatisticsData } from '@/lib/queries/statistics';

type FetchStatisticsResult = {
  data?: StatisticsData;
  dateLabel?: string;
  error?: string;
};

export async function fetchStatisticsAction(
  ledgerId: string,
  period: PeriodType,
  dateISO: string,
  userFilter?: string,
): Promise<FetchStatisticsResult> {
  try {
    const supabase = await createClient();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return { error: '로그인이 필요합니다.' };

    const date = new Date(dateISO);
    const userId = userFilter === 'all' ? undefined : userFilter;
    const data = await getStatisticsData(ledgerId, period, date, user.id, userId);
    const dateLabel = getDateLabel(period, date);

    return { data, dateLabel };
  } catch (err) {
    console.error('fetchStatisticsAction error:', err);
    return { error: '통계 데이터를 불러오는 중 오류가 발생했습니다.' };
  }
}

export type CategoryTopItem = {
  rank: number;
  title: string;
  amount: number;
  percentage: number;
  date: string;
  userName: string;
  userColor: string;
};

export type CategoryTopResult = {
  items?: CategoryTopItem[];
  totalAmount?: number;
  error?: string;
};

const DAY_NAMES = ['일', '월', '화', '수', '목', '금', '토'];

export async function fetchCategoryTopItems(
  ledgerId: string,
  categoryName: string,
  type: 'expense' | 'income' | 'asset',
  period: PeriodType,
  dateISO: string,
  userFilter?: string,
): Promise<CategoryTopResult> {
  try {
    const supabase = await createClient();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return { error: '로그인이 필요합니다.' };

    const date = new Date(dateISO);
    const { start, end } = getDateRange(period, date);

    // 카테고리 ID 조회
    const { data: categories } = await supabase
      .from('categories')
      .select('id')
      .eq('ledger_id', ledgerId)
      .eq('name', categoryName);

    const categoryIds = (categories || []).map((c) => c.id);
    if (categoryIds.length === 0 && categoryName !== '미지정') {
      return { items: [], totalAmount: 0 };
    }

    // Top5 거래 조회
    let topQuery = supabase
      .from('transactions')
      .select('id, title, amount, date, user_id')
      .eq('ledger_id', ledgerId)
      .eq('type', type)
      .gte('date', start)
      .lt('date', end);

    if (categoryIds.length > 0) {
      topQuery = topQuery.in('category_id', categoryIds);
    } else {
      topQuery = topQuery.is('category_id', null);
    }
    if (userFilter && userFilter !== 'all') {
      topQuery = topQuery.eq('user_id', userFilter);
    }
    topQuery = topQuery.order('amount', { ascending: false }).limit(5);

    // 합계 조회
    let sumQuery = supabase
      .from('transactions')
      .select('amount')
      .eq('ledger_id', ledgerId)
      .eq('type', type)
      .gte('date', start)
      .lt('date', end);

    if (categoryIds.length > 0) {
      sumQuery = sumQuery.in('category_id', categoryIds);
    } else {
      sumQuery = sumQuery.is('category_id', null);
    }
    if (userFilter && userFilter !== 'all') {
      sumQuery = sumQuery.eq('user_id', userFilter);
    }

    const [topResult, sumResult] = await Promise.all([topQuery, sumQuery]);

    if (topResult.error) {
      return { error: '거래 데이터를 불러오는 중 오류가 발생했습니다.' };
    }

    const txs = topResult.data || [];
    if (txs.length === 0) {
      return { items: [], totalAmount: 0 };
    }

    const totalAmount = (sumResult.data || []).reduce((s, t) => s + t.amount, 0);

    // 유저 프로필 조회
    const userIds = [...new Set(txs.map((t) => t.user_id))];
    const { data: profiles } = await supabase
      .from('profiles')
      .select('id, display_name, color')
      .in('id', userIds);

    const profileMap = new Map((profiles || []).map((p) => [p.id, p]));

    const items: CategoryTopItem[] = txs.map((tx, idx) => {
      const profile = profileMap.get(tx.user_id);
      const txDate = new Date(tx.date + 'T12:00:00');
      const dateStr = `${txDate.getMonth() + 1}월 ${txDate.getDate()}일 (${DAY_NAMES[txDate.getDay()]})`;

      return {
        rank: idx + 1,
        title: tx.title || '제목 없음',
        amount: tx.amount,
        percentage: totalAmount > 0 ? Math.round((tx.amount / totalAmount) * 1000) / 10 : 0,
        date: dateStr,
        userName: profile?.display_name || '알 수 없음',
        userColor: profile?.color || '#A8D8EA',
      };
    });

    return { items, totalAmount };
  } catch (err) {
    console.error('fetchCategoryTopItems error:', err);
    return { error: '데이터를 불러오는 중 오류가 발생했습니다.' };
  }
}
