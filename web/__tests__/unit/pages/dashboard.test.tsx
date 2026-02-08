import { render, screen } from '@testing-library/react';
import { describe, it, expect, vi } from 'vitest';

// Server Component 쿼리 mock
vi.mock('@/lib/queries/ledger', () => ({
  getCurrentUserLedger: vi.fn().mockResolvedValue({
    ledger: { id: 'ledger-1', name: '테스트 가계부' },
    role: 'owner',
  }),
}));

vi.mock('@/lib/queries/transaction', () => ({
  getMonthSummary: vi.fn().mockResolvedValue({
    income: 3200000,
    expense: 1300000,
    balance: 1900000,
    transactionCount: 5,
  }),
  getTransactions: vi.fn().mockResolvedValue([
    {
      id: '1',
      description: '점심 식사',
      amount: 12000,
      type: 'expense',
      date: '2026-02-06',
      categories: { name: '식비', icon: '🍔' },
    },
    {
      id: '2',
      description: '급여',
      amount: 3200000,
      type: 'income',
      date: '2026-02-05',
      categories: { name: '급여', icon: '💰' },
    },
  ]),
}));

vi.mock('@/lib/queries/asset', () => ({
  getAssetSummary: vi.fn().mockResolvedValue({
    totalAsset: 45200000,
    categories: [],
    assets: [],
  }),
}));

// next/navigation mock
vi.mock('next/navigation', () => ({
  redirect: vi.fn(),
}));

import DashboardPage from '@/app/(main)/dashboard/page';

describe('대시보드 페이지', () => {
  it('대시보드 제목이 렌더링되어야 함', async () => {
    const page = await DashboardPage();
    render(page);
    expect(screen.getByText('대시보드')).toBeInTheDocument();
  });

  it('요약 카드 4개가 모두 렌더링되어야 함', async () => {
    const page = await DashboardPage();
    render(page);
    expect(screen.getByText('이번 달 수입')).toBeInTheDocument();
    expect(screen.getByText('이번 달 지출')).toBeInTheDocument();
    expect(screen.getByText('잔액')).toBeInTheDocument();
    expect(screen.getByText('총 자산')).toBeInTheDocument();
  });

  it('최근 거래 목록이 렌더링되어야 함', async () => {
    const page = await DashboardPage();
    render(page);
    expect(screen.getByText('최근 거래')).toBeInTheDocument();
    expect(screen.getByText('점심 식사')).toBeInTheDocument();
    expect(screen.getByText('급여')).toBeInTheDocument();
  });

  it('전체보기 링크가 존재해야 함', async () => {
    const page = await DashboardPage();
    render(page);
    const link = screen.getByRole('link', { name: /전체보기/i });
    expect(link).toBeInTheDocument();
    expect(link).toHaveAttribute('href', '/ledger');
  });

  it('수입/지출 금액이 올바르게 표시되어야 함', async () => {
    const page = await DashboardPage();
    render(page);
    // 수입 금액은 요약 카드와 거래 목록에서 중복될 수 있음
    const incomeElements = screen.getAllByText('+3,200,000원');
    expect(incomeElements.length).toBeGreaterThanOrEqual(1);
    // 지출 요약 카드
    expect(screen.getByText('-1,300,000원')).toBeInTheDocument();
  });
});
