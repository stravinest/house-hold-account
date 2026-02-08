# 공유 가계부 웹 버전

가족, 커플, 룸메이트와 함께 사용하는 가계부 웹 애플리케이션

## 기술 스택

- **Framework**: Next.js 15 (App Router)
- **Language**: TypeScript
- **Styling**: Tailwind CSS 3.4
- **Backend**: Supabase (PostgreSQL, Auth, RLS, Realtime)
- **상태관리**: TanStack Query
- **차트**: Recharts
- **폼 관리**: React Hook Form + Zod
- **다국어**: next-intl
- **테스트**: Vitest + Testing Library + Playwright

## 개발 환경 설정

### 1. 의존성 설치

```bash
npm install
```

### 2. 환경 변수 설정

`.env.local` 파일을 생성하고 다음 값을 설정하세요:

```bash
NEXT_PUBLIC_SUPABASE_URL=your_supabase_url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_anon_key
NEXT_PUBLIC_GOOGLE_CLIENT_ID=your_google_client_id
```

### 3. 개발 서버 실행

```bash
npm run dev
```

브라우저에서 [http://localhost:3000](http://localhost:3000)을 열어 확인하세요.

## 프로젝트 구조

```
web/
├── app/                      # Next.js App Router
│   ├── (auth)/               # 인증 관련 라우트
│   ├── (main)/               # 메인 앱 라우트
│   └── (landing)/            # 랜딩 페이지
├── components/               # 재사용 UI 컴포넌트
│   ├── ui/                   # 기본 UI (Button, Input 등)
│   ├── charts/               # 차트 컴포넌트
│   ├── layout/               # 레이아웃 컴포넌트
│   └── forms/                # 폼 컴포넌트
├── features/                 # Feature별 컴포넌트/훅
├── lib/                      # 유틸리티 및 설정
│   ├── supabase/             # Supabase 클라이언트
│   ├── utils/                # 유틸리티 함수
│   ├── hooks/                # 커스텀 훅
│   ├── types/                # TypeScript 타입
│   └── constants/            # 상수
└── __tests__/                # 테스트
    ├── unit/                 # 단위 테스트
    ├── integration/          # 통합 테스트
    └── e2e/                  # E2E 테스트
```

## 스크립트

```bash
npm run dev          # 개발 서버 실행
npm run build        # 프로덕션 빌드
npm run start        # 프로덕션 서버 실행
npm run lint         # ESLint 실행
npm run test         # Vitest 단위/통합 테스트
npm run test:e2e     # Playwright E2E 테스트
npm run typecheck    # TypeScript 타입 체크
```

## 디자인 시스템

### 색상

- **Primary**: `#2E7D32` (녹색)
- **Expense**: `#BA1A1A` (빨강)
- **Income**: `#2E7D32` (녹색)
- **Asset**: `#006A6A` (청록색)

### 간격

- **xs**: 4px
- **sm**: 8px
- **md**: 16px (기본)
- **lg**: 24px
- **xl**: 32px
- **xxl**: 48px

### Border Radius

- **xs**: 4px
- **sm**: 8px
- **md**: 12px (기본)
- **lg**: 16px
- **xl**: 20px

## 개발 가이드

### TDD 방식 개발

1. 테스트 작성 (Red)
2. 최소한의 코드로 테스트 통과 (Green)
3. 리팩토링 (Refactor)

### Supabase 타입 생성

```bash
npx supabase gen types typescript --project-id <project-id> --schema house > lib/types/database.ts
```

### 컴포넌트 작성 규칙

- Server Components 우선 사용
- Client Components는 최소화 (`'use client'`)
- 하드코딩된 문자열 금지 (i18n 사용)
- 디자인 토큰 활용 (Tailwind 클래스)

## 배포

Vercel 배포 권장:

```bash
vercel --prod
```

## 참고 문서

- [Next.js 문서](https://nextjs.org/docs)
- [Supabase 문서](https://supabase.com/docs)
- [Tailwind CSS 문서](https://tailwindcss.com/docs)
- [Plan 문서](../docs/01-plan/features/web-version.plan.md)
- [Design 문서](../docs/02-design/features/web-version.design.md)

## 라이선스

Private
