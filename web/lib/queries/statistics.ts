import { createClient } from '@/lib/supabase/server';

export type PeriodType = 'day' | 'week' | 'month' | 'year';

export type StatisticsData = {
  income: number;
  expense: number;
  thirdValue: number;
  thirdLabel: string;
  thirdSub?: string;
  prevIncome: number;
  prevExpense: number;
  prevThirdValue: number;
  comparisonLabel: string;
  chartData: { label: string; value: number }[];
  chartTitle: string;
  chartSubText: string;
  categoryExpense: { name: string; value: number }[];
  categoryIncome: { name: string; amount: number; percentage: number }[];
  paymentMethods: { name: string; amount: number; icon: 'credit-card' | 'banknote'; color: string }[];
  memberSpending: { name: string; amount: number; color: string; isMe: boolean }[];
};

export function getDateRange(period: PeriodType, date: Date): { start: string; end: string } {
  const y = date.getFullYear();
  const m = date.getMonth();
  const d = date.getDate();

  switch (period) {
    case 'day': {
      const start = `${y}-${String(m + 1).padStart(2, '0')}-${String(d).padStart(2, '0')}`;
      const next = new Date(y, m, d + 1);
      const end = `${next.getFullYear()}-${String(next.getMonth() + 1).padStart(2, '0')}-${String(next.getDate()).padStart(2, '0')}`;
      return { start, end };
    }
    case 'week': {
      const day = date.getDay();
      const mondayOffset = day === 0 ? -6 : 1 - day;
      const monday = new Date(y, m, d + mondayOffset);
      const sunday = new Date(monday.getFullYear(), monday.getMonth(), monday.getDate() + 7);
      const start = `${monday.getFullYear()}-${String(monday.getMonth() + 1).padStart(2, '0')}-${String(monday.getDate()).padStart(2, '0')}`;
      const end = `${sunday.getFullYear()}-${String(sunday.getMonth() + 1).padStart(2, '0')}-${String(sunday.getDate()).padStart(2, '0')}`;
      return { start, end };
    }
    case 'month': {
      const start = `${y}-${String(m + 1).padStart(2, '0')}-01`;
      const nextM = m + 1 === 12 ? 0 : m + 1;
      const nextY = m + 1 === 12 ? y + 1 : y;
      const end = `${nextY}-${String(nextM + 1).padStart(2, '0')}-01`;
      return { start, end };
    }
    case 'year': {
      return { start: `${y}-01-01`, end: `${y + 1}-01-01` };
    }
  }
}

function getPrevDateRange(period: PeriodType, date: Date): { start: string; end: string } {
  switch (period) {
    case 'day': {
      const prev = new Date(date.getFullYear(), date.getMonth(), date.getDate() - 1);
      return getDateRange('day', prev);
    }
    case 'week': {
      const prev = new Date(date.getFullYear(), date.getMonth(), date.getDate() - 7);
      return getDateRange('week', prev);
    }
    case 'month': {
      const prev = new Date(date.getFullYear(), date.getMonth() - 1, 1);
      return getDateRange('month', prev);
    }
    case 'year': {
      const prev = new Date(date.getFullYear() - 1, 0, 1);
      return getDateRange('year', prev);
    }
  }
}

function getTimeSlot(hour: number): string {
  if (hour < 6) return '야간';
  if (hour < 11) return '오전';
  if (hour < 14) return '점심';
  if (hour < 18) return '오후';
  return '저녁';
}

const DAY_NAMES = ['일', '월', '화', '수', '목', '금', '토'];
const TIME_SLOTS = ['오전', '점심', '오후', '저녁', '야간'];

function getComparisonLabel(period: PeriodType): string {
  switch (period) {
    case 'day': return '어제 대비';
    case 'week': return '지난 주 대비';
    case 'month': return '전월 대비';
    case 'year': return '전년 대비';
  }
}

function getThirdLabel(period: PeriodType): string {
  switch (period) {
    case 'day': return '거래 건수';
    case 'week': return '일평균 지출';
    case 'month': return '합계';
    case 'year': return '연간 합계';
  }
}

function getCardLabels(period: PeriodType) {
  switch (period) {
    case 'day': return { income: '오늘 수입', expense: '오늘 지출' };
    case 'week': return { income: '이번 주 수입', expense: '이번 주 지출' };
    case 'month': return { income: '이번 달 수입', expense: '이번 달 지출' };
    case 'year': return { income: '연간 수입', expense: '연간 지출' };
  }
}

function getChartMeta(period: PeriodType) {
  switch (period) {
    case 'day': return { title: '시간대별 지출', subText: '오늘' };
    case 'week': return { title: '요일별 지출', subText: '이번 주' };
    case 'month': return { title: '주별 수입/지출', subText: '이번 달' };
    case 'year': return { title: '월별 수입/지출 추이', subText: '' };
  }
}

const PM_COLORS = ['#42A5F5', '#FF7043', '#AB47BC', '#FFA726', '#26A69A', '#EC407A'];

export async function getStatisticsData(
  ledgerId: string,
  period: PeriodType,
  date: Date,
  currentUserId: string,
  userId?: string,
): Promise<StatisticsData> {
  const supabase = await createClient();
  const { start, end } = getDateRange(period, date);
  const prev = getPrevDateRange(period, date);

  // 현재 기간 + 이전 기간 거래를 병렬 조회 (relation embedding 없이 단순 select)
  let query = supabase
    .from('transactions')
    .select('id, type, amount, date, user_id, category_id, payment_method_id, created_at')
    .eq('ledger_id', ledgerId)
    .gte('date', start)
    .lt('date', end)
    .order('date', { ascending: false });

  if (userId && userId !== 'all') {
    query = query.eq('user_id', userId);
  }

  let prevQuery = supabase
    .from('transactions')
    .select('id, type, amount, date, user_id')
    .eq('ledger_id', ledgerId)
    .gte('date', prev.start)
    .lt('date', prev.end);

  if (userId && userId !== 'all') {
    prevQuery = prevQuery.eq('user_id', userId);
  }

  // 카테고리, 결제수단, 멤버 정보를 별도로 조회
  const categoriesQuery = supabase
    .from('categories')
    .select('id, name, icon, color')
    .eq('ledger_id', ledgerId);

  const pmQuery = supabase
    .from('payment_methods')
    .select('id, name, type, icon, color')
    .eq('ledger_id', ledgerId);

  const membersQuery = supabase
    .from('ledger_members')
    .select('user_id')
    .eq('ledger_id', ledgerId);

  const [currentResult, prevResult, catResult, pmResult, memberResult] = await Promise.all([
    query,
    prevQuery,
    categoriesQuery,
    pmQuery,
    membersQuery,
  ]);

  const txs = currentResult.data || [];
  const prevTxs = prevResult.data || [];
  const memberUserIds = new Set((memberResult.data || []).map((m) => m.user_id));

  // 멤버 user_id로만 profiles 조회
  const { data: profileData } = memberUserIds.size > 0
    ? await supabase
        .from('profiles')
        .select('id, display_name, color')
        .in('id', Array.from(memberUserIds))
    : { data: [] };

  // lookup maps 생성
  const catMap = new Map((catResult.data || []).map((c) => [c.id, c]));
  const pmLookup = new Map((pmResult.data || []).map((p) => [p.id, p]));
  const profileMap = new Map((profileData || []).map((p) => [p.id, p]));
  const memberLookup = new Map(
    Array.from(memberUserIds).map((uid) => {
      const profile = profileMap.get(uid);
      return [uid, { name: profile?.display_name || '알 수 없음', color: profile?.color || '#A8DAB5' }];
    })
  );

  // 수입/지출 합계
  const income = txs.filter((t) => t.type === 'income').reduce((s, t) => s + t.amount, 0);
  const expense = txs.filter((t) => t.type === 'expense').reduce((s, t) => s + t.amount, 0);
  const prevIncome = prevTxs.filter((t) => t.type === 'income').reduce((s, t) => s + t.amount, 0);
  const prevExpense = prevTxs.filter((t) => t.type === 'expense').reduce((s, t) => s + t.amount, 0);

  // 3번째 카드 값 계산
  let thirdValue = 0;
  let prevThirdValue = 0;
  let thirdSub = '';
  switch (period) {
    case 'day': {
      thirdValue = txs.length;
      prevThirdValue = prevTxs.length;
      const expCount = txs.filter((t) => t.type === 'expense').length;
      const incCount = txs.filter((t) => t.type === 'income').length;
      const astCount = txs.filter((t) => t.type === 'asset').length;
      const parts = [];
      if (expCount > 0) parts.push(`지출 ${expCount}건`);
      if (incCount > 0) parts.push(`수입 ${incCount}건`);
      if (astCount > 0) parts.push(`자산 ${astCount}건`);
      thirdSub = parts.length > 0 ? parts.join(', ') : '거래 없음';
      break;
    }
    case 'week':
      thirdValue = Math.round(expense / 7);
      prevThirdValue = Math.round(prevExpense / 7);
      break;
    case 'month':
    case 'year':
      thirdValue = income - expense;
      prevThirdValue = prevIncome - prevExpense;
      break;
  }

  // 차트 데이터 생성
  const chartData: { label: string; value: number }[] = [];
  const expenseTxs = txs.filter((t) => t.type === 'expense');

  switch (period) {
    case 'day': {
      const slotMap: Record<string, number> = {};
      for (const slot of TIME_SLOTS) slotMap[slot] = 0;
      for (const tx of expenseTxs) {
        // created_at에 실제 시간 정보가 있으므로 이를 사용
        const timestamp = tx.created_at || tx.date;
        const hour = new Date(timestamp).getHours();
        const slot = getTimeSlot(hour);
        slotMap[slot] = (slotMap[slot] || 0) + tx.amount;
      }
      for (const slot of TIME_SLOTS) {
        chartData.push({ label: slot, value: slotMap[slot] || 0 });
      }
      break;
    }
    case 'week': {
      const dayMap: Record<string, number> = {};
      for (const day of ['월', '화', '수', '목', '금', '토', '일']) dayMap[day] = 0;
      for (const tx of expenseTxs) {
        const d = new Date(tx.date + 'T12:00:00');
        const dayName = DAY_NAMES[d.getDay()];
        dayMap[dayName] = (dayMap[dayName] || 0) + tx.amount;
      }
      for (const day of ['월', '화', '수', '목', '금', '토', '일']) {
        chartData.push({ label: day, value: dayMap[day] || 0 });
      }
      break;
    }
    case 'month': {
      for (let w = 1; w <= 4; w++) {
        const weekStart = new Date(date.getFullYear(), date.getMonth(), (w - 1) * 7 + 1);
        const weekEnd = w === 4
          ? new Date(date.getFullYear(), date.getMonth() + 1, 0)
          : new Date(date.getFullYear(), date.getMonth(), w * 7);
        const weekExpense = expenseTxs
          .filter((tx) => {
            const txDate = new Date(tx.date + 'T12:00:00');
            return txDate >= weekStart && txDate <= weekEnd;
          })
          .reduce((s, t) => s + t.amount, 0);
        chartData.push({ label: `${w}주`, value: weekExpense });
      }
      break;
    }
    case 'year': {
      for (let mo = 1; mo <= 12; mo++) {
        const monthExpense = expenseTxs
          .filter((tx) => {
            const txDate = new Date(tx.date + 'T12:00:00');
            return txDate.getMonth() + 1 === mo;
          })
          .reduce((s, t) => s + t.amount, 0);
        chartData.push({ label: `${mo}월`, value: monthExpense });
      }
      break;
    }
  }

  // 카테고리별 지출
  const catExpenseMap: Record<string, number> = {};
  for (const tx of expenseTxs) {
    const cat = tx.category_id ? catMap.get(tx.category_id) : null;
    const name = cat?.name || '미지정';
    catExpenseMap[name] = (catExpenseMap[name] || 0) + tx.amount;
  }
  const categoryExpense = Object.entries(catExpenseMap)
    .map(([name, value]) => ({ name, value }))
    .sort((a, b) => b.value - a.value);

  // 카테고리별 수입
  const incomeTxs = txs.filter((t) => t.type === 'income');
  const catIncomeMap: Record<string, number> = {};
  for (const tx of incomeTxs) {
    const cat = tx.category_id ? catMap.get(tx.category_id) : null;
    const name = cat?.name || '미지정';
    catIncomeMap[name] = (catIncomeMap[name] || 0) + tx.amount;
  }
  const totalIncome = income || 1;
  const categoryIncome = Object.entries(catIncomeMap)
    .map(([name, amount]) => ({
      name,
      amount,
      percentage: Math.round((amount / totalIncome) * 100),
    }))
    .sort((a, b) => b.amount - a.amount);

  // 결제수단별 지출
  const pmAggMap: Record<string, { amount: number; type: string; color: string }> = {};
  for (const tx of expenseTxs) {
    const pm = tx.payment_method_id ? pmLookup.get(tx.payment_method_id) : null;
    const pmName = pm?.name || '미지정';
    const pmType = pm?.type || 'cash';
    const pmColor = pm?.color;
    if (!pmAggMap[pmName]) {
      pmAggMap[pmName] = { amount: 0, type: pmType, color: pmColor || '' };
    }
    pmAggMap[pmName].amount += tx.amount;
  }
  const paymentMethods = Object.entries(pmAggMap)
    .map(([name, info], idx) => ({
      name,
      amount: info.amount,
      icon: (info.type === 'card' || info.type === 'credit_card' ? 'credit-card' : 'banknote') as 'credit-card' | 'banknote',
      color: info.color || PM_COLORS[idx % PM_COLORS.length],
    }))
    .sort((a, b) => b.amount - a.amount);

  // 멤버별 지출 (지출 없는 멤버도 0원으로 포함)
  const memberAggMap: Record<string, { amount: number; name: string; color: string }> = {};
  for (const [uid, info] of memberLookup) {
    memberAggMap[uid] = {
      amount: 0,
      name: info.name,
      color: info.color,
    };
  }
  for (const tx of txs.filter((t) => t.type === 'expense')) {
    const uid = tx.user_id;
    if (memberAggMap[uid]) {
      memberAggMap[uid].amount += tx.amount;
    } else {
      const member = memberLookup.get(uid);
      memberAggMap[uid] = {
        amount: tx.amount,
        name: member?.name || '알 수 없음',
        color: member?.color || '#A8DAB5',
      };
    }
  }
  const memberSpending = Object.entries(memberAggMap)
    .map(([uid, info]) => ({
      name: info.name,
      amount: info.amount,
      color: info.color,
      isMe: uid === currentUserId,
    }))
    .sort((a, b) => b.amount - a.amount);

  const chartMeta = getChartMeta(period);

  return {
    income,
    expense,
    thirdValue,
    thirdLabel: getThirdLabel(period),
    thirdSub: thirdSub || undefined,
    prevIncome,
    prevExpense,
    prevThirdValue,
    comparisonLabel: getComparisonLabel(period),
    chartData,
    chartTitle: chartMeta.title,
    chartSubText: chartMeta.subText,
    categoryExpense,
    categoryIncome,
    paymentMethods,
    memberSpending,
  };
}

export function getDateLabel(period: PeriodType, date: Date): string {
  const y = date.getFullYear();
  const m = date.getMonth() + 1;
  const d = date.getDate();

  switch (period) {
    case 'day':
      return `${y}년 ${m}월 ${d}일`;
    case 'week': {
      const day = date.getDay();
      const mondayOffset = day === 0 ? -6 : 1 - day;
      const monday = new Date(y, date.getMonth(), d + mondayOffset);
      const sunday = new Date(monday.getFullYear(), monday.getMonth(), monday.getDate() + 6);
      const weekNum = Math.ceil(monday.getDate() / 7);
      return `${m}월 ${weekNum}주차 (${monday.getMonth() + 1}/${monday.getDate()}~${sunday.getMonth() + 1}/${sunday.getDate()})`;
    }
    case 'month':
      return `${y}년 ${m}월`;
    case 'year':
      return `${y}년`;
  }
}

export function navigateDate(period: PeriodType, date: Date, direction: number): Date {
  const y = date.getFullYear();
  const m = date.getMonth();
  const d = date.getDate();

  switch (period) {
    case 'day':
      return new Date(y, m, d + direction);
    case 'week':
      return new Date(y, m, d + direction * 7);
    case 'month':
      return new Date(y, m + direction, 1);
    case 'year':
      return new Date(y + direction, 0, 1);
  }
}

export { getCardLabels };
