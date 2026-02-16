# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 개발 명령어

```bash
npm run dev          # 개발 서버 (포트 6001)
npm run build        # 프로덕션 빌드
npm run lint         # ESLint
npm run typecheck    # TypeScript 타입 체크
npm run test         # Vitest 단위 테스트
npm run test:e2e     # Playwright E2E 테스트
```

환경 변수: `.env.local`에 `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_ANON_KEY`, `NEXT_PUBLIC_GOOGLE_CLIENT_ID` 설정 필요.

## 아키텍처

Next.js 15 App Router 기반 공유 가계부 웹앱. Supabase(PostgreSQL + Auth + RLS)를 백엔드로 사용.

### 데이터 흐름 패턴

**Server Component → Client Component 패턴**이 핵심:

1. `app/(main)/*/page.tsx` (Server Component): `lib/queries/`의 함수로 초기 데이터 로드
2. `app/(main)/*/*-client.tsx` (Client Component): props로 초기 데이터를 받아 인터랙션 처리
3. `lib/actions/` (Server Actions): 데이터 변경 후 `revalidatePath()`로 캐시 무효화

```
Server Component → queries/*.ts → Supabase Server Client → DB
                         ↓ (props)
Client Component → 사용자 인터랙션 → actions/*.ts → Supabase Server Client → DB → revalidatePath
```

### Supabase 클라이언트 구분

- `lib/supabase/server.ts`: Server Components, Server Actions에서 사용 (쿠키 기반 세션)
- `lib/supabase/client.ts`: Client Components에서 사용 (브라우저)
- 모든 클라이언트는 `{ db: { schema: 'house' } }` 스키마 사용

### 라우트 구조

- `(auth)/`: 로그인, 회원가입, 비밀번호 재설정 (미인증 사용자)
- `(main)/`: 대시보드, 가계부, 자산, 통계, 설정 (인증 필수, `middleware.ts`에서 보호)
- `(legal)/`: 이용약관, 개인정보처리방침
- `auth/callback/`: OAuth 콜백

### 주요 디렉토리

| 경로 | 역할 |
|------|------|
| `lib/queries/` | 데이터 조회 함수 (Server Component에서 호출) |
| `lib/actions/` | 데이터 변경 Server Actions (`'use server'`) |
| `lib/hooks/` | 커스텀 훅 (예: `useTransactionDetail` - 클릭/더블클릭 처리) |
| `lib/utils/` | 포맷팅, 계산, Excel 처리 유틸리티 |
| `components/ui/` | 기본 UI 컴포넌트 (Button, Input, Card, Dialog) |
| `components/shared/` | 여러 페이지에서 공유하는 컴포넌트 (SummaryCard, PeriodTabs, TransactionDetailModal) |
| `components/charts/` | Recharts 기반 차트 컴포넌트 |
| `components/layout/` | Sidebar, Header, MobileNav |
| `components/transaction/` | 거래 추가/수정/임포트/내보내기 |

### 인증 흐름

- `useActionState` + Server Action 패턴으로 폼 처리
- `middleware.ts`에서 세션 갱신 및 라우트 보호 (publicPaths 외 접근 시 `/login` 리다이렉트)
- Google OAuth: `auth/callback/route.ts`에서 코드 교환 처리

### 디자인 토큰

`tailwind.config.ts`에 정의된 커스텀 토큰 사용:
- 색상: `primary`, `expense`, `income`, `asset`, `surface`, `on-surface`
- 간격: `xs(4px)`, `sm(8px)`, `md(16px)`, `lg(24px)`, `xl(32px)`, `xxl(48px)`
- 클래스 병합: `lib/utils/cn.ts`의 `cn()` 함수 (clsx + tailwind-merge)

## 코드 컨벤션

- 문자열은 작은따옴표(`'`) 사용
- 주석에 이모티콘 사용 금지
- 테스트 설명은 한글로 자세하게 작성
- Server Components 우선, `'use client'`는 최소화
- 색상 하드코딩 금지 - Tailwind 디자인 토큰 또는 `colorScheme` 사용
