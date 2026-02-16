import { render, screen } from '@testing-library/react';
import { describe, it, expect, vi } from 'vitest';

vi.mock('@/lib/queries/ledger', () => ({
  getCurrentUserLedger: vi.fn().mockResolvedValue({
    ledger: { id: 'ledger-1', name: '테스트 가계부' },
    role: 'owner',
  }),
  getLedgerMembers: vi.fn().mockResolvedValue([
    { user_id: 'u1', profiles: { display_name: 'user1', color: '#2E7D32' } },
  ]),
}));

vi.mock('@/lib/queries/transaction', () => ({
  getTransactions: vi.fn().mockResolvedValue([
    {
      id: '1',
      title: '점심 식사',
      amount: 12000,
      type: 'expense',
      date: '2026-02-06',
      categories: { name: '식비', icon: 'restaurant', color: '#FF5722' },
      profiles: { display_name: 'user1', color: '#2E7D32' },
    },
    {
      id: '2',
      title: '급여',
      amount: 3200000,
      type: 'income',
      date: '2026-02-05',
      categories: { name: '급여', icon: 'payments', color: '#4CAF50' },
      profiles: { display_name: 'user1', color: '#2E7D32' },
    },
  ]),
}));

vi.mock('next/navigation', () => ({
  redirect: vi.fn(),
}));

// DashboardClient를 간단한 컴포넌트로 mock하여 서버 컴포넌트의 데이터 전달을 검증
vi.mock('@/app/(main)/dashboard/dashboard-client', () => ({
  DashboardClient: (props: any) => (
    <div data-testid='dashboard-client'>
      <span data-testid='ledger-id'>{props.ledgerId}</span>
      <span data-testid='income'>{props.initialData.income}</span>
      <span data-testid='expense'>{props.initialData.expense}</span>
      <span data-testid='members-count'>{props.members.length}</span>
      {props.initialData.transactions.map((tx: any) => (
        <span key={tx.id} data-testid={`tx-${tx.id}`}>{tx.description}</span>
      ))}
    </div>
  ),
}));

import DashboardPage from '@/app/(main)/dashboard/page';

describe('대시보드 페이지 - 서버 컴포넌트 데이터 전달 검증', () => {
  it('DashboardClient에 올바른 ledgerId가 전달되어야 함', async () => {
    const page = await DashboardPage();
    render(page);
    expect(screen.getByTestId('ledger-id')).toHaveTextContent('ledger-1');
  });

  it('수입/지출 합계가 올바르게 계산되어야 함', async () => {
    const page = await DashboardPage();
    render(page);
    expect(screen.getByTestId('income')).toHaveTextContent('3200000');
    expect(screen.getByTestId('expense')).toHaveTextContent('12000');
  });

  it('멤버 정보가 전달되어야 함', async () => {
    const page = await DashboardPage();
    render(page);
    expect(screen.getByTestId('members-count')).toHaveTextContent('1');
  });

  it('거래 내역이 직렬화되어 전달되어야 함', async () => {
    const page = await DashboardPage();
    render(page);
    expect(screen.getByTestId('tx-1')).toHaveTextContent('점심 식사');
    expect(screen.getByTestId('tx-2')).toHaveTextContent('급여');
  });
});
