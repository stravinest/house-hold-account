import { render, screen } from '@testing-library/react';
import { describe, it, expect } from 'vitest';
import Home from '@/app/page';

describe('랜딩 페이지', () => {
  it('Hero Section이 렌더링되어야 함', () => {
    render(<Home />);

    expect(screen.getByText(/우리집 생활/i)).toBeInTheDocument();
    expect(screen.getByText(/공유가계부/i)).toBeInTheDocument();
    expect(screen.getByText(/우생가계부/i)).toBeInTheDocument();
  });

  it('CTA 버튼들이 렌더링되어야 함', () => {
    render(<Home />);

    expect(screen.getByRole('link', { name: /시작하기/i })).toBeInTheDocument();
    expect(screen.getByRole('link', { name: /로그인/i })).toBeInTheDocument();
  });

  it('하이라이트 카드들이 렌더링되어야 함', () => {
    render(<Home />);

    expect(screen.getByText(/스마트 수집/i)).toBeInTheDocument();
    expect(screen.getByText(/실시간 공유/i)).toBeInTheDocument();
    expect(screen.getByText(/강력한 통계/i)).toBeInTheDocument();
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
