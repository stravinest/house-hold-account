import type { PeriodType } from '@/components/shared/PeriodTabs';

export type DateParts = {
  year: number;
  month: number;
  day: number;
  dayOfWeek: number;
};

// 다양한 날짜 타입(string, Date, null 등)에서 년/월/일을 안전하게 추출
export function extractDateParts(dateVal: unknown): DateParts | null {
  let dateStr: string;
  if (typeof dateVal === 'string') {
    dateStr = dateVal;
  } else if (dateVal instanceof Date) {
    dateStr = dateVal.toISOString();
  } else if (dateVal != null) {
    dateStr = String(dateVal);
  } else {
    return null;
  }

  const dateOnly = dateStr.substring(0, 10);
  const y = parseInt(dateOnly.substring(0, 4), 10);
  const m = parseInt(dateOnly.substring(5, 7), 10);
  const d = parseInt(dateOnly.substring(8, 10), 10);

  if (isNaN(y) || isNaN(m) || isNaN(d)) return null;

  const dateObj = new Date(y, m - 1, d, 12, 0, 0);
  return { year: y, month: m - 1, day: d, dayOfWeek: dateObj.getDay() };
}

// 날짜에서 일(day)만 추출하는 간략 버전 (서버 사이드용)
export function extractDay(dateVal: unknown): number | null {
  const parts = extractDateParts(dateVal);
  return parts ? parts.day : null;
}

export type ChartDataPoint = {
  label: string;
  income: number;
  expense: number;
};

// 트랜잭션 목록으로부터 기간별 차트 데이터를 생성
export function generateChartData(
  transactions: { type: string; amount: number; date: unknown }[],
  period: PeriodType,
  baseDate: Date,
): ChartDataPoint[] {
  switch (period) {
    case 'day': {
      const slots = ['오전', '점심', '오후', '저녁', '야간'];
      const map: Record<string, { income: number; expense: number }> = {};
      for (const s of slots) map[s] = { income: 0, expense: 0 };
      for (const tx of transactions) {
        const parts = extractDateParts(tx.date);
        if (!parts) continue;
        // DATE 컬럼은 시간 정보가 없으므로 수입/지출별 고정 슬롯 배치
        if (tx.type === 'income') map['오전'].income += tx.amount;
        else if (tx.type === 'expense') map['오후'].expense += tx.amount;
      }
      return slots.map((s) => ({ label: s, ...map[s] }));
    }
    case 'week': {
      const dayLabels = ['월', '화', '수', '목', '금', '토', '일'];
      const dayNamesJs = ['일', '월', '화', '수', '목', '금', '토'];
      const map: Record<string, { income: number; expense: number }> = {};
      for (const d of dayLabels) map[d] = { income: 0, expense: 0 };
      for (const tx of transactions) {
        const parts = extractDateParts(tx.date);
        if (!parts) continue;
        const dayName = dayNamesJs[parts.dayOfWeek];
        if (tx.type === 'income') map[dayName].income += tx.amount;
        else if (tx.type === 'expense') map[dayName].expense += tx.amount;
      }
      return dayLabels.map((d) => ({ label: d, ...map[d] }));
    }
    case 'month': {
      const lastDay = new Date(baseDate.getFullYear(), baseDate.getMonth() + 1, 0).getDate();
      const weekCount = Math.ceil(lastDay / 7);
      const buckets = Array.from({ length: weekCount }, () => ({ income: 0, expense: 0 }));
      for (const tx of transactions) {
        const parts = extractDateParts(tx.date);
        if (!parts) continue;
        const weekIdx = Math.min(Math.floor((parts.day - 1) / 7), weekCount - 1);
        if (tx.type === 'income') buckets[weekIdx].income += tx.amount;
        else if (tx.type === 'expense') buckets[weekIdx].expense += tx.amount;
      }
      return buckets.map((b, i) => ({ label: `${i + 1}주`, ...b }));
    }
    case 'year': {
      const buckets = Array.from({ length: 12 }, () => ({ income: 0, expense: 0 }));
      for (const tx of transactions) {
        const parts = extractDateParts(tx.date);
        if (!parts) continue;
        if (tx.type === 'income') buckets[parts.month].income += tx.amount;
        else if (tx.type === 'expense') buckets[parts.month].expense += tx.amount;
      }
      return buckets.map((b, i) => ({ label: `${i + 1}월`, ...b }));
    }
  }
}
