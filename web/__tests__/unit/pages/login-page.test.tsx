import { render, screen } from '@testing-library/react';
import { describe, it, expect, vi } from 'vitest';

// Server actions mock
vi.mock('@/lib/actions/auth', () => ({
  signIn: vi.fn(),
  signInWithGoogle: vi.fn(),
  signUp: vi.fn(),
  signOut: vi.fn(),
  resetPassword: vi.fn(),
}));

import LoginPage from '@/app/(auth)/login/page';

describe('로그인 페이지', () => {
  it('로고와 앱 제목이 렌더링되어야 함', () => {
    render(<LoginPage />);

    expect(screen.getByText(/우생가계부/i)).toBeInTheDocument();
    expect(screen.getByText(/우리집 생활 공유가계부/i)).toBeInTheDocument();
  });

  it('이메일과 비밀번호 입력 필드가 렌더링되어야 함', () => {
    render(<LoginPage />);

    expect(screen.getByLabelText(/이메일/i)).toBeInTheDocument();
    expect(screen.getByLabelText(/비밀번호/i)).toBeInTheDocument();
  });

  it('로그인 버튼이 렌더링되어야 함', () => {
    render(<LoginPage />);

    expect(screen.getByRole('button', { name: /로그인/i })).toBeInTheDocument();
  });

  it('Google 로그인 버튼이 렌더링되어야 함', () => {
    render(<LoginPage />);

    expect(screen.getByRole('button', { name: /Google로 계속하기/i })).toBeInTheDocument();
  });

  it('회원가입 링크가 렌더링되어야 함', () => {
    render(<LoginPage />);

    expect(screen.getByText(/계정이 없으신가요/i)).toBeInTheDocument();
    expect(screen.getByRole('link', { name: /회원가입/i })).toBeInTheDocument();
  });

  it('비밀번호 찾기 링크가 렌더링되어야 함', () => {
    render(<LoginPage />);

    expect(screen.getByText(/비밀번호 찾기/i)).toBeInTheDocument();
  });
});
