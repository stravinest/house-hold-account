import { render, screen } from '@testing-library/react';
import { describe, it, expect, vi } from 'vitest';

vi.mock('@/lib/actions/auth', () => ({
  signOut: vi.fn(),
}));

vi.mock('@/lib/queries/ledger', () => ({
  getCurrentUserProfile: vi.fn().mockResolvedValue({
    id: 'user-1',
    email: 'user@example.com',
    display_name: '사용자',
    color: '#2E7D32',
  }),
}));

// next/navigation mock
vi.mock('next/navigation', () => ({
  redirect: vi.fn(),
}));

import SettingsPage from '@/app/(main)/settings/page';

describe('설정 페이지', () => {
  it('설정 제목이 렌더링되어야 함', async () => {
    const page = await SettingsPage();
    render(page);
    expect(screen.getByText('설정')).toBeInTheDocument();
  });

  it('프로필 정보가 렌더링되어야 함', async () => {
    const page = await SettingsPage();
    render(page);
    expect(screen.getByText('사용자')).toBeInTheDocument();
    expect(screen.getByText('user@example.com')).toBeInTheDocument();
  });

  it('가계부 관리 메뉴 항목들이 렌더링되어야 함', async () => {
    const page = await SettingsPage();
    render(page);
    expect(screen.getByText('멤버 관리')).toBeInTheDocument();
    expect(screen.getByText('카테고리 관리')).toBeInTheDocument();
    expect(screen.getByText('결제수단 관리')).toBeInTheDocument();
    expect(screen.getByText('고정비 관리')).toBeInTheDocument();
  });

  it('관리 메뉴가 올바른 링크를 가져야 함', async () => {
    const page = await SettingsPage();
    render(page);
    expect(screen.getByText('멤버 관리').closest('a')).toHaveAttribute('href', '/settings/share');
    expect(screen.getByText('카테고리 관리').closest('a')).toHaveAttribute('href', '/settings/categories');
    expect(screen.getByText('결제수단 관리').closest('a')).toHaveAttribute('href', '/settings/payment-methods');
    expect(screen.getByText('고정비 관리').closest('a')).toHaveAttribute('href', '/settings/fixed-costs');
  });

  it('로그아웃 버튼이 렌더링되어야 함', async () => {
    const page = await SettingsPage();
    render(page);
    expect(screen.getByText('로그아웃')).toBeInTheDocument();
  });
});
