import { describe, it, expect } from 'vitest';
import {
  getFilteredSummary,
  getFilteredChartData,
  getChartMode,
  getChartTitle,
  getFilteredTransactions,
  getUserBreakdowns,
  getDateLabel,
  navigateDate,
  type DashboardTransaction,
  type MemberInfo,
} from '@/lib/utils/dashboard';

const makeTx = (overrides: Partial<DashboardTransaction> = {}): DashboardTransaction => ({
  id: '1',
  description: '테스트',
  amount: 10000,
  type: 'expense',
  date: '2024-01-15',
  categoryName: '식비',
  categoryIcon: '',
  ...overrides,
});

describe('getFilteredSummary - typeFilter에 따른 요약 데이터 필터링 테스트', () => {
  const summary = { income: 100000, expense: 50000, balance: 50000 };

  it('"all" 필터는 원본 데이터를 그대로 반환해야 한다', () => {
    const result = getFilteredSummary(summary, 'all');
    expect(result).toEqual(summary);
  });

  it('"income" 필터는 수입만 표시하고 지출은 0으로 설정해야 한다', () => {
    const result = getFilteredSummary(summary, 'income');
    expect(result.income).toBe(100000);
    expect(result.expense).toBe(0);
    expect(result.balance).toBe(100000);
  });

  it('"expense" 필터는 지출만 표시하고 수입은 0으로 설정해야 한다', () => {
    const result = getFilteredSummary(summary, 'expense');
    expect(result.income).toBe(0);
    expect(result.expense).toBe(50000);
    expect(result.balance).toBe(-50000);
  });
});

describe('getFilteredChartData - typeFilter에 따른 차트 데이터 필터링 테스트', () => {
  const chartData = [
    { label: '1주', income: 50000, expense: 30000 },
    { label: '2주', income: 40000, expense: 20000 },
  ];

  it('"all" 필터는 차트 데이터를 그대로 반환해야 한다', () => {
    const result = getFilteredChartData(chartData, 'all');
    expect(result).toEqual(chartData);
  });

  it('"income" 필터는 expense 값을 모두 0으로 변환해야 한다', () => {
    const result = getFilteredChartData(chartData, 'income');
    expect(result[0].income).toBe(50000);
    expect(result[0].expense).toBe(0);
    expect(result[1].income).toBe(40000);
    expect(result[1].expense).toBe(0);
  });

  it('"expense" 필터는 income 값을 모두 0으로 변환해야 한다', () => {
    const result = getFilteredChartData(chartData, 'expense');
    expect(result[0].income).toBe(0);
    expect(result[0].expense).toBe(30000);
    expect(result[1].income).toBe(0);
    expect(result[1].expense).toBe(20000);
  });

  it('빈 차트 데이터에서도 정상 동작해야 한다', () => {
    expect(getFilteredChartData([], 'all')).toEqual([]);
    expect(getFilteredChartData([], 'income')).toEqual([]);
  });
});

describe('getChartMode - typeFilter에 따른 차트 모드 결정 테스트', () => {
  it('"all" 필터는 dual 모드를 반환해야 한다', () => {
    expect(getChartMode('all')).toBe('dual');
  });

  it('"income" 필터는 single 모드를 반환해야 한다', () => {
    expect(getChartMode('income')).toBe('single');
  });

  it('"expense" 필터는 single 모드를 반환해야 한다', () => {
    expect(getChartMode('expense')).toBe('single');
  });
});

describe('getChartTitle - 기간 및 typeFilter에 따른 차트 제목 테스트', () => {
  it('월별 + 전체 필터면 "주별 수입/지출"을 반환해야 한다', () => {
    expect(getChartTitle('month', 'all')).toBe('주별 수입/지출');
  });

  it('일별 + 수입 필터면 "시간대별 수입"을 반환해야 한다', () => {
    expect(getChartTitle('day', 'income')).toBe('시간대별 수입');
  });

  it('주별 + 지출 필터면 "요일별 지출"을 반환해야 한다', () => {
    expect(getChartTitle('week', 'expense')).toBe('요일별 지출');
  });

  it('연별 + 전체 필터면 "월별 수입/지출"을 반환해야 한다', () => {
    expect(getChartTitle('year', 'all')).toBe('월별 수입/지출');
  });
});

describe('getFilteredTransactions - typeFilter에 따른 거래 목록 필터링 테스트', () => {
  const transactions = [
    makeTx({ id: '1', type: 'income', amount: 100000 }),
    makeTx({ id: '2', type: 'expense', amount: 30000 }),
    makeTx({ id: '3', type: 'expense', amount: 20000 }),
    makeTx({ id: '4', type: 'income', amount: 50000 }),
  ];

  it('"all" 필터는 모든 거래를 반환해야 한다', () => {
    expect(getFilteredTransactions(transactions, 'all')).toHaveLength(4);
  });

  it('"income" 필터는 수입 거래만 반환해야 한다', () => {
    const result = getFilteredTransactions(transactions, 'income');
    expect(result).toHaveLength(2);
    expect(result.every((tx) => tx.type === 'income')).toBe(true);
  });

  it('"expense" 필터는 지출 거래만 반환해야 한다', () => {
    const result = getFilteredTransactions(transactions, 'expense');
    expect(result).toHaveLength(2);
    expect(result.every((tx) => tx.type === 'expense')).toBe(true);
  });

  it('빈 거래 목록에서도 정상 동작해야 한다', () => {
    expect(getFilteredTransactions([], 'all')).toEqual([]);
    expect(getFilteredTransactions([], 'income')).toEqual([]);
  });
});

describe('getUserBreakdowns - 유저별 수입/지출/합계 분류 테스트', () => {
  const members: MemberInfo[] = [
    { id: 'u1', name: 'user1', color: '#2E7D32' },
    { id: 'u2', name: 'user2', color: '#A8D8EA' },
  ];

  const transactions = [
    makeTx({ id: '1', type: 'income', amount: 100000, authorName: 'user1' }),
    makeTx({ id: '2', type: 'expense', amount: 30000, authorName: 'user1' }),
    makeTx({ id: '3', type: 'expense', amount: 15000, authorName: 'user2' }),
    makeTx({ id: '4', type: 'income', amount: 50000, authorName: 'user2' }),
  ];

  it('각 유저의 수입을 정확히 분류해야 한다', () => {
    const result = getUserBreakdowns(transactions, members);
    expect(result.income[0].name).toBe('user1');
    expect(result.income[0].value).toBe(100000);
    expect(result.income[1].name).toBe('user2');
    expect(result.income[1].value).toBe(50000);
  });

  it('각 유저의 지출을 정확히 분류해야 한다', () => {
    const result = getUserBreakdowns(transactions, members);
    expect(result.expense[0].value).toBe(30000);
    expect(result.expense[1].value).toBe(15000);
  });

  it('각 유저의 합계(수입-지출)를 정확히 계산해야 한다', () => {
    const result = getUserBreakdowns(transactions, members);
    expect(result.balance[0].value).toBe(70000);  // 100000 - 30000
    expect(result.balance[1].value).toBe(35000);   // 50000 - 15000
  });

  it('거래가 없는 유저는 0을 반환해야 한다', () => {
    const onlyUser1Tx = [
      makeTx({ id: '1', type: 'income', amount: 100000, authorName: 'user1' }),
    ];
    const result = getUserBreakdowns(onlyUser1Tx, members);
    expect(result.income[1].value).toBe(0);
    expect(result.expense[1].value).toBe(0);
    expect(result.balance[1].value).toBe(0);
  });

  it('멤버 색상이 결과에 포함되어야 한다', () => {
    const result = getUserBreakdowns(transactions, members);
    expect(result.income[0].color).toBe('#2E7D32');
    expect(result.income[1].color).toBe('#A8D8EA');
  });

  it('빈 거래 목록과 빈 멤버 목록에서도 정상 동작해야 한다', () => {
    const result = getUserBreakdowns([], []);
    expect(result.income).toEqual([]);
    expect(result.expense).toEqual([]);
    expect(result.balance).toEqual([]);
  });
});

describe('getDateLabel - 기간별 날짜 라벨 생성 테스트', () => {
  it('day 기간은 "YYYY.MM.DD" 형식을 반환해야 한다', () => {
    const date = new Date(2024, 0, 15);
    expect(getDateLabel('day', date)).toBe('2024.01.15');
  });

  it('month 기간은 "YYYY년 M월" 형식을 반환해야 한다', () => {
    const date = new Date(2024, 1, 1);
    expect(getDateLabel('month', date)).toBe('2024년 2월');
  });

  it('year 기간은 "YYYY년" 형식을 반환해야 한다', () => {
    const date = new Date(2024, 5, 1);
    expect(getDateLabel('year', date)).toBe('2024년');
  });

  it('week 기간은 시작일-종료일 범위를 반환해야 한다', () => {
    const date = new Date(2024, 0, 15); // 1월 15일
    const label = getDateLabel('week', date);
    expect(label).toContain('1.15');
    expect(label).toContain(' - ');
  });
});

describe('navigateDate - 날짜 이동 테스트', () => {
  it('day 기간에서 +1 이동 시 다음날로 이동해야 한다', () => {
    const date = new Date(2024, 0, 15);
    const next = navigateDate('day', date, 1);
    expect(next.getDate()).toBe(16);
  });

  it('day 기간에서 -1 이동 시 전날로 이동해야 한다', () => {
    const date = new Date(2024, 0, 15);
    const prev = navigateDate('day', date, -1);
    expect(prev.getDate()).toBe(14);
  });

  it('week 기간에서 +1 이동 시 7일 후로 이동해야 한다', () => {
    const date = new Date(2024, 0, 15);
    const next = navigateDate('week', date, 1);
    expect(next.getDate()).toBe(22);
  });

  it('month 기간에서 +1 이동 시 다음달로 이동해야 한다', () => {
    const date = new Date(2024, 0, 1);
    const next = navigateDate('month', date, 1);
    expect(next.getMonth()).toBe(1);
  });

  it('year 기간에서 +1 이동 시 다음해로 이동해야 한다', () => {
    const date = new Date(2024, 0, 1);
    const next = navigateDate('year', date, 1);
    expect(next.getFullYear()).toBe(2025);
  });

  it('원본 날짜 객체를 변경하지 않아야 한다 (불변성 보장)', () => {
    const date = new Date(2024, 0, 15);
    navigateDate('day', date, 1);
    expect(date.getDate()).toBe(15);
  });
});
