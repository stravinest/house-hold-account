/**
 * 금액을 한국 원화 형식으로 포맷팅
 * @param amount 금액
 * @param showSign 부호 표시 여부 (양수: +, 음수: -)
 */
export function formatAmount(amount: number, showSign = false): string {
  const formatted = Math.abs(amount).toLocaleString('ko-KR');
  if (showSign) {
    return amount >= 0 ? `+${formatted}원` : `-${formatted}원`;
  }
  return `${formatted}원`;
}

/**
 * 금액을 만원 단위로 축약 포맷팅
 * @param amount 금액
 */
export function formatAmountShort(amount: number): string {
  if (Math.abs(amount) >= 100000000) {
    return `${(amount / 100000000).toFixed(1)}억`;
  }
  if (Math.abs(amount) >= 10000) {
    return `${(amount / 10000).toFixed(0)}만`;
  }
  return amount.toLocaleString('ko-KR');
}

/**
 * 날짜를 YYYY.MM.DD 형식으로 포맷팅
 */
export function formatDate(dateStr: string): string {
  const normalized = dateStr.length === 10 ? dateStr + 'T12:00:00' : dateStr;
  const date = new Date(normalized);
  const y = date.getFullYear();
  const m = String(date.getMonth() + 1).padStart(2, '0');
  const d = String(date.getDate()).padStart(2, '0');
  return `${y}.${m}.${d}`;
}

/**
 * 날짜를 "2026년 2월 7일 (토)" 형식으로 포맷팅
 */
export function formatDateWithDay(dateStr: string): string {
  const date = new Date(dateStr);
  if (isNaN(date.getTime())) return dateStr;
  const days = ['일', '월', '화', '수', '목', '금', '토'];
  const y = date.getFullYear();
  const m = date.getMonth() + 1;
  const d = date.getDate();
  const day = days[date.getDay()];
  return `${y}년 ${m}월 ${d}일 (${day})`;
}

/**
 * 날짜를 "2월 7일 14:30" 형식으로 포맷팅
 */
export function formatDateTime(dateStr: string): string {
  const normalized = dateStr.length === 10 ? dateStr + 'T12:00:00' : dateStr;
  const date = new Date(normalized);
  if (isNaN(date.getTime())) return dateStr;
  const m = date.getMonth() + 1;
  const d = date.getDate();
  const h = String(date.getHours()).padStart(2, '0');
  const min = String(date.getMinutes()).padStart(2, '0');
  if (dateStr.length === 10) {
    return `${m}월 ${d}일`;
  }
  return `${m}월 ${d}일 ${h}:${min}`;
}

/**
 * 퍼센트 계산
 */
export function getPercentage(used: number, total: number): number {
  if (total === 0) return 0;
  return Math.round((used / total) * 100);
}
