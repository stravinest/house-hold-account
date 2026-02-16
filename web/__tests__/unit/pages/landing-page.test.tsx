import { render, screen } from '@testing-library/react';
import { describe, it, expect, vi } from 'vitest';

vi.mock('@/components/ui/NavigationProgress', () => ({
  useNavigation: vi.fn(() => ({
    navigatingTo: null,
    startNavigation: vi.fn(),
  })),
  NavigationProgress: () => null,
}));

import Home from '@/app/page';

describe('랜딩 페이지', () => {
  it('Hero Section이 렌더링되어야 함', () => {
    render(<Home />);
    // 텍스트가 페이지 내 여러 곳에 나올 수 있으므로 getAllByText 사용
    expect(screen.getAllByText(/우리집 생활/i).length).toBeGreaterThanOrEqual(1);
    expect(screen.getAllByText(/공유가계부/i).length).toBeGreaterThanOrEqual(1);
    expect(screen.getAllByText(/우생가계부/i).length).toBeGreaterThanOrEqual(1);
  });

  it('CTA 버튼들이 렌더링되어야 함', () => {
    render(<Home />);
    expect(screen.getAllByRole('link', { name: /시작하기/i }).length).toBeGreaterThanOrEqual(1);
    expect(screen.getAllByRole('link', { name: /로그인/i }).length).toBeGreaterThanOrEqual(1);
  });

  it('하이라이트 카드들이 렌더링되어야 함', () => {
    render(<Home />);
    expect(screen.getAllByText(/스마트 수집/i).length).toBeGreaterThanOrEqual(1);
    expect(screen.getAllByText(/실시간 공유/i).length).toBeGreaterThanOrEqual(1);
    expect(screen.getAllByText(/강력한 통계/i).length).toBeGreaterThanOrEqual(1);
  });

  it('이용 방법 섹션이 렌더링되어야 함', () => {
    render(<Home />);
    expect(screen.getByText(/이용 방법/i)).toBeInTheDocument();
    expect(screen.getByText(/계정 만들기/i)).toBeInTheDocument();
    expect(screen.getByText(/멤버 초대하기/i)).toBeInTheDocument();
    expect(screen.getByText(/함께 기록하기/i)).toBeInTheDocument();
  });

  it('Footer가 렌더링되어야 함', () => {
    render(<Home />);
    expect(screen.getByText(/이용약관/i)).toBeInTheDocument();
    expect(screen.getByText(/개인정보처리방침/i)).toBeInTheDocument();
    expect(screen.getByText(/고객지원/i)).toBeInTheDocument();
    expect(screen.getByText(/© 2026 우생가계부/i)).toBeInTheDocument();
  });
});
