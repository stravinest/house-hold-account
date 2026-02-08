# Design: 공유 가계부 웹 버전 (web-version)

> PDCA Phase: Design
> 작성일: 2026-02-06
> 상태: 작성 중
> Plan 참조: [web-version.plan.md](../../01-plan/features/web-version.plan.md)

---

## 1. 아키텍처 개요

### 1.1 기술 스택 확정

| 항목 | 기술 | 버전 | 설치 명령 |
|------|------|------|----------|
| **Framework** | Next.js | 15.3.x | `npx create-next-app@latest` |
| **Runtime** | React | 19.x | (Next.js 포함) |
| **Styling** | Tailwind CSS | 4.x | `npm install -D tailwindcss@next` |
| **Backend** | Supabase | - | `npm install @supabase/supabase-js @supabase/ssr` |
| **상태관리** | TanStack Query | 5.x | `npm install @tanstack/react-query` |
| **차트** | Recharts | 2.x | `npm install recharts` |
| **폼** | React Hook Form | 7.x | `npm install react-hook-form` |
| **검증** | Zod | 3.x | `npm install zod` |
| **다국어** | next-intl | 3.x | `npm install next-intl` |
| **테스트** | Vitest | 2.x | `npm install -D vitest @testing-library/react` |
| **E2E** | Playwright | 1.x | `npm install -D @playwright/test` |

### 1.2 Supabase MCP 통합

**핵심 원칙**: Supabase MCP를 통해 데이터베이스 작업 수행

```typescript
// Supabase MCP 도구 활용 예시
// 1. 테이블 스키마 확인: mcp__supabase__list_tables
// 2. SQL 실행: mcp__supabase__execute_sql
// 3. 타입 생성: mcp__supabase__generate_typescript_types
```

**장점**:
- 타입 안전성 자동 보장
- SQL 쿼리 직접 실행 가능
- 마이그레이션 관리 용이
- RPC 함수 즉시 사용

---

## 2. Phase 1: 프로젝트 초기 설정 (상세)

### 2.1 프로젝트 생성

```bash
# Next.js 15 프로젝트 생성 (web/ 디렉토리에)
cd /Users/eungyu/Desktop/개인/project/house-hold-account
npx create-next-app@latest web --typescript --tailwind --app --no-src-dir

# 프로젝트 구조
web/
├── app/
├── components/
├── lib/
├── public/
├── __tests__/
├── next.config.ts
├── tailwind.config.ts
├── tsconfig.json
├── package.json
└── .env.local
```

### 2.2 의존성 설치

**package.json 주요 의존성**:

```json
{
  "name": "shared-household-account-web",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "next lint",
    "test": "vitest",
    "test:e2e": "playwright test",
    "typecheck": "tsc --noEmit"
  },
  "dependencies": {
    "next": "^15.3.0",
    "react": "^19.0.0",
    "react-dom": "^19.0.0",
    "@supabase/supabase-js": "^2.50.0",
    "@supabase/ssr": "^0.6.0",
    "@tanstack/react-query": "^5.62.0",
    "recharts": "^2.15.0",
    "react-hook-form": "^7.54.0",
    "zod": "^3.24.0",
    "next-intl": "^3.25.0",
    "clsx": "^2.1.1",
    "tailwind-merge": "^2.7.0"
  },
  "devDependencies": {
    "@types/node": "^22.0.0",
    "@types/react": "^19.0.0",
    "@types/react-dom": "^19.0.0",
    "typescript": "^5.8.0",
    "tailwindcss": "^4.0.0",
    "vitest": "^2.1.0",
    "@testing-library/react": "^16.1.0",
    "@testing-library/jest-dom": "^6.6.0",
    "@playwright/test": "^1.49.0",
    "eslint": "^9.0.0",
    "eslint-config-next": "^15.3.0"
  }
}
```

### 2.3 환경 변수 설정

**.env.local**:

```bash
# Supabase (기존 프로젝트와 동일)
NEXT_PUBLIC_SUPABASE_URL=your_supabase_url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_anon_key

# Google OAuth (기존 프로젝트와 동일)
NEXT_PUBLIC_GOOGLE_CLIENT_ID=your_google_client_id
```

### 2.4 Tailwind 디자인 토큰 설정

**tailwind.config.ts**:

```typescript
import type { Config } from 'tailwindcss';

const config: Config = {
  content: [
    './app/**/*.{js,ts,jsx,tsx,mdx}',
    './components/**/*.{js,ts,jsx,tsx,mdx}',
    './features/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        // Primary (동일한 녹색)
        primary: {
          DEFAULT: '#2E7D32',
          container: '#A8DAB5',
          on: '#FFFFFF',
          'on-container': '#00210B',
        },
        // 시맨틱 색상
        expense: '#BA1A1A',
        income: '#2E7D32',
        asset: '#006A6A',
        // Surface
        surface: {
          DEFAULT: '#FDFDF5',
          container: '#EFEEE6',
          'container-high': '#E9E8E0',
          'container-highest': '#E3E3DB',
        },
        // Text
        'on-surface': {
          DEFAULT: '#1A1C19',
          variant: '#44483E',
        },
        // Outline
        outline: {
          DEFAULT: '#74796D',
          variant: '#C4C8BB',
        },
        // Error
        error: {
          DEFAULT: '#BA1A1A',
        },
      },
      spacing: {
        xs: '4px',
        sm: '8px',
        md: '16px',
        lg: '24px',
        xl: '32px',
        xxl: '48px',
      },
      borderRadius: {
        xs: '4px',
        sm: '8px',
        md: '12px',
        lg: '16px',
        xl: '20px',
        pill: '9999px',
      },
      fontSize: {
        xs: ['12px', { lineHeight: '16px' }],
        sm: ['14px', { lineHeight: '20px' }],
        base: ['16px', { lineHeight: '24px' }],
        lg: ['18px', { lineHeight: '28px' }],
        xl: ['20px', { lineHeight: '28px' }],
        '2xl': ['24px', { lineHeight: '32px' }],
        '3xl': ['30px', { lineHeight: '36px' }],
      },
    },
  },
  plugins: [],
};

export default config;
```

### 2.5 Supabase 클라이언트 설정

**lib/supabase/client.ts** (브라우저):

```typescript
import { createBrowserClient } from '@supabase/ssr';
import type { Database } from '../types/database';

export function createClient() {
  return createBrowserClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
  );
}
```

**lib/supabase/server.ts** (서버):

```typescript
import { createServerClient } from '@supabase/ssr';
import { cookies } from 'next/headers';
import type { Database } from '../types/database';

export async function createClient() {
  const cookieStore = await cookies();

  return createServerClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return cookieStore.getAll();
        },
        setAll(cookiesToSet) {
          cookiesToSet.forEach(({ name, value, options }) =>
            cookieStore.set(name, value, options)
          );
        },
      },
    }
  );
}
```

**lib/supabase/middleware.ts**:

```typescript
import { createServerClient } from '@supabase/ssr';
import { NextResponse, type NextRequest } from 'next/server';
import type { Database } from '../types/database';

export async function updateSession(request: NextRequest) {
  let supabaseResponse = NextResponse.next({
    request,
  });

  const supabase = createServerClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return request.cookies.getAll();
        },
        setAll(cookiesToSet) {
          cookiesToSet.forEach(({ name, value }) =>
            request.cookies.set(name, value)
          );
          supabaseResponse = NextResponse.next({
            request,
          });
          cookiesToSet.forEach(({ name, value, options }) =>
            supabaseResponse.cookies.set(name, value, options)
          );
        },
      },
    }
  );

  // 세션 갱신
  const {
    data: { user },
  } = await supabase.auth.getUser();

  // Protected routes 리다이렉트
  if (
    !user &&
    !request.nextUrl.pathname.startsWith('/login') &&
    !request.nextUrl.pathname.startsWith('/signup') &&
    !request.nextUrl.pathname.startsWith('/') &&
    !request.nextUrl.pathname.startsWith('/terms') &&
    !request.nextUrl.pathname.startsWith('/privacy')
  ) {
    const url = request.nextUrl.clone();
    url.pathname = '/login';
    return NextResponse.redirect(url);
  }

  return supabaseResponse;
}
```

**middleware.ts** (루트):

```typescript
import { updateSession } from './lib/supabase/middleware';

export async function middleware(request: NextRequest) {
  return await updateSession(request);
}

export const config = {
  matcher: [
    '/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)',
  ],
};
```

### 2.6 TypeScript 타입 정의 (Supabase 스키마 기반)

**Supabase MCP를 통한 타입 생성**:

```bash
# Supabase MCP의 generate_typescript_types 도구 사용
# 또는 Supabase CLI 사용
npx supabase gen types typescript --project-id <project-id> --schema house > lib/types/database.ts
```

**lib/types/database.ts** (자동 생성):

```typescript
export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[];

export interface Database {
  house: {
    Tables: {
      profiles: {
        Row: {
          id: string;
          email: string;
          display_name: string | null;
          avatar_url: string | null;
          color: string | null;
          created_at: string | null;
          updated_at: string | null;
        };
        Insert: {
          id: string;
          email: string;
          display_name?: string | null;
          avatar_url?: string | null;
          color?: string | null;
          created_at?: string | null;
          updated_at?: string | null;
        };
        Update: {
          id?: string;
          email?: string;
          display_name?: string | null;
          avatar_url?: string | null;
          color?: string | null;
          created_at?: string | null;
          updated_at?: string | null;
        };
      };
      ledgers: {
        Row: {
          id: string;
          name: string;
          description: string | null;
          currency: string;
          owner_id: string;
          is_shared: boolean;
          created_at: string | null;
          updated_at: string | null;
        };
        Insert: {
          id?: string;
          name: string;
          description?: string | null;
          currency?: string;
          owner_id: string;
          is_shared?: boolean;
          created_at?: string | null;
          updated_at?: string | null;
        };
        Update: {
          id?: string;
          name?: string;
          description?: string | null;
          currency?: string;
          owner_id?: string;
          is_shared?: boolean;
          created_at?: string | null;
          updated_at?: string | null;
        };
      };
      transactions: {
        Row: {
          id: string;
          ledger_id: string;
          category_id: string | null;
          user_id: string;
          payment_method_id: string | null;
          fixed_expense_category_id: string | null;
          amount: number;
          type: string;
          date: string;
          title: string | null;
          memo: string | null;
          image_url: string | null;
          is_recurring: boolean;
          recurring_type: string | null;
          recurring_end_date: string | null;
          is_fixed_expense: boolean;
          is_asset: boolean | null;
          maturity_date: string | null;
          created_at: string | null;
          updated_at: string | null;
          source_type: string | null;
        };
        Insert: {
          id?: string;
          ledger_id: string;
          category_id?: string | null;
          user_id: string;
          payment_method_id?: string | null;
          fixed_expense_category_id?: string | null;
          amount: number;
          type: string;
          date: string;
          title?: string | null;
          memo?: string | null;
          image_url?: string | null;
          is_recurring?: boolean;
          recurring_type?: string | null;
          recurring_end_date?: string | null;
          is_fixed_expense?: boolean;
          is_asset?: boolean | null;
          maturity_date?: string | null;
          created_at?: string | null;
          updated_at?: string | null;
          source_type?: string | null;
        };
        Update: {
          id?: string;
          ledger_id?: string;
          category_id?: string | null;
          user_id?: string;
          payment_method_id?: string | null;
          fixed_expense_category_id?: string | null;
          amount?: number;
          type?: string;
          date?: string;
          title?: string | null;
          memo?: string | null;
          image_url?: string | null;
          is_recurring?: boolean;
          recurring_type?: string | null;
          recurring_end_date?: string | null;
          is_fixed_expense?: boolean;
          is_asset?: boolean | null;
          maturity_date?: string | null;
          created_at?: string | null;
          updated_at?: string | null;
          source_type?: string | null;
        };
      };
      categories: {
        Row: {
          id: string;
          ledger_id: string;
          name: string;
          icon: string;
          color: string;
          type: string;
          is_default: boolean;
          sort_order: number;
          created_at: string | null;
        };
        Insert: {
          id?: string;
          ledger_id: string;
          name: string;
          icon?: string;
          color?: string;
          type: string;
          is_default?: boolean;
          sort_order?: number;
          created_at?: string | null;
        };
        Update: {
          id?: string;
          ledger_id?: string;
          name?: string;
          icon?: string;
          color?: string;
          type?: string;
          is_default?: boolean;
          sort_order?: number;
          created_at?: string | null;
        };
      };
      payment_methods: {
        Row: {
          id: string;
          ledger_id: string;
          name: string;
          icon: string | null;
          color: string | null;
          is_default: boolean;
          sort_order: number;
          created_at: string | null;
          auto_save_mode: string | null;
          default_category_id: string | null;
          can_auto_save: boolean | null;
          owner_user_id: string;
          auto_collect_source: string | null;
        };
        Insert: {
          id?: string;
          ledger_id: string;
          name: string;
          icon?: string | null;
          color?: string | null;
          is_default?: boolean;
          sort_order?: number;
          created_at?: string | null;
          auto_save_mode?: string | null;
          default_category_id?: string | null;
          can_auto_save?: boolean | null;
          owner_user_id: string;
          auto_collect_source?: string | null;
        };
        Update: {
          id?: string;
          ledger_id?: string;
          name?: string;
          icon?: string | null;
          color?: string | null;
          is_default?: boolean;
          sort_order?: number;
          created_at?: string | null;
          auto_save_mode?: string | null;
          default_category_id?: string | null;
          can_auto_save?: boolean | null;
          owner_user_id?: string;
          auto_collect_source?: string | null;
        };
      };
      // 나머지 테이블 (생략 - 실제로는 모든 테이블 포함)
      // asset_goals, fcm_tokens, fixed_expense_categories, fixed_expense_settings,
      // learned_push_formats, learned_sms_formats, ledger_invites, ledger_members,
      // merchant_category_rules, notification_settings, pending_transactions,
      // push_notifications, recurring_templates
    };
    Functions: {
      accept_ledger_invite: {
        Args: { target_invite_id: string };
        Returns: Json;
      };
      check_user_exists_by_email: {
        Args: { target_email: string };
        Returns: { id: string; email: string; display_name: string }[];
      };
      increment_sms_format_match_count: {
        Args: { format_id: string };
        Returns: void;
      };
      increment_push_format_match_count: {
        Args: { format_id: string };
        Returns: void;
      };
      user_can_access_ledger: {
        Args: { p_ledger_id: string };
        Returns: boolean;
      };
      is_ledger_member: {
        Args: { p_ledger_id: string; p_user_id: string };
        Returns: boolean;
      };
      is_ledger_admin: {
        Args: { p_ledger_id: string; p_user_id: string };
        Returns: boolean;
      };
      // 나머지 RPC 함수 (생략 - 실제로는 모든 함수 포함)
    };
  };
}
```

### 2.7 Vitest 설정

**vitest.config.ts**:

```typescript
import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';
import path from 'path';

export default defineConfig({
  plugins: [react()],
  test: {
    environment: 'jsdom',
    globals: true,
    setupFiles: ['./__tests__/setup.ts'],
  },
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './'),
    },
  },
});
```

**__tests__/setup.ts**:

```typescript
import '@testing-library/jest-dom';
import { cleanup } from '@testing-library/react';
import { afterEach } from 'vitest';

afterEach(() => {
  cleanup();
});
```

### 2.8 Playwright 설정

**playwright.config.ts**:

```typescript
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './__tests__/e2e',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: 'html',
  use: {
    baseURL: 'http://localhost:3000',
    trace: 'on-first-retry',
  },
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
    {
      name: 'firefox',
      use: { ...devices['Desktop Firefox'] },
    },
    {
      name: 'webkit',
      use: { ...devices['Desktop Safari'] },
    },
  ],
  webServer: {
    command: 'npm run dev',
    url: 'http://localhost:3000',
    reuseExistingServer: !process.env.CI,
  },
});
```

---

## 3. Phase 2-10 개요 (구현 시 상세화)

각 Phase는 실제 구현 단계에서 더 상세한 Design 문서로 확장됩니다.

### Phase 2: 랜딩 페이지 + 법적 문서

**디자인 파일**: `house.pen` (x:12000)

**라우트 구조**:
```
app/
├── (landing)/
│   ├── layout.tsx          # 랜딩 레이아웃 (Header, Footer)
│   ├── page.tsx            # 메인 랜딩
│   ├── terms/page.tsx      # 이용약관
│   └── privacy/page.tsx    # 개인정보처리방침
```

**주요 컴포넌트**:
- `Hero.tsx`: Hero 섹션
- `FeatureSection.tsx`: 기능 소개
- `StatisticsPreview.tsx`: 통계 미리보기
- `Footer.tsx`: Footer

**데이터 소스**:
- 이용약관: `docs/terms_of_service.md`
- 개인정보: `docs/privacy_policy.md`

### Phase 3: 인증 시스템

**디자인 파일**: `house.pen` (x:14000)

**라우트 구조**:
```
app/
├── (auth)/
│   ├── login/page.tsx
│   ├── signup/page.tsx
│   └── forgot-password/page.tsx
```

**주요 기능**:
- Supabase Auth SSR
- Google OAuth
- 이메일 인증
- 비밀번호 재설정

**상태 관리**:
- `useAuth` 훅 (Supabase 세션)

### Phase 4: 공통 레이아웃 + UI 컴포넌트

**디자인 파일**: `house.pen` (x:15000, x:22000)

**레이아웃**:
```
app/
├── (main)/
│   ├── layout.tsx          # Sidebar + Header
│   └── ...
```

**컴포넌트 라이브러리**:
```
components/
├── ui/
│   ├── Button.tsx
│   ├── Input.tsx
│   ├── Card.tsx
│   ├── Dialog.tsx
│   ├── Toast.tsx
│   └── ...
├── layout/
│   ├── Sidebar.tsx
│   ├── Header.tsx
│   └── MobileNav.tsx
└── ...
```

### Phase 5: 가계부 메인 (Ledger)

**디자인 파일**: `house.pen` (x:16000)

**라우트**:
```
app/(main)/ledger/page.tsx
```

**주요 기능**:
- 캘린더 뷰 (월간/주간/일간)
- 거래 CRUD
- 월간 요약

**Supabase 쿼리 (MCP 활용)**:
```typescript
// transactions 테이블 조회
await supabase
  .from('house.transactions')
  .select('*, category:house.categories(*), payment_method:house.payment_methods(*)')
  .eq('ledger_id', ledgerId)
  .gte('date', startDate)
  .lte('date', endDate);
```

### Phase 6: 카테고리 + 결제수단 + 고정비

**디자인 파일**: `house.pen` (x:16000)

**라우트**:
```
app/(main)/settings/
├── categories/page.tsx
├── payment-methods/page.tsx
└── fixed-expenses/page.tsx
```

### Phase 7: 통계 대시보드 (강화)

**디자인 파일**: `house.pen` (x:18000)

**라우트**:
```
app/(main)/
├── dashboard/page.tsx       # 메인 대시보드
└── statistics/
    ├── page.tsx            # 종합 통계
    ├── category/page.tsx   # 카테고리 분석
    ├── trend/page.tsx      # 추이 분석
    └── payment/page.tsx    # 결제수단 분석
```

**강화 기능**:
1. 드릴다운 (카테고리 클릭 → 거래 목록)
2. 커스텀 기간 선택
3. 분기별 비교
4. CSV/Excel/PDF 내보내기

**차트 컴포넌트 (Recharts)**:
```
components/charts/
├── DonutChart.tsx          # 도넛 차트
├── BarChart.tsx            # 막대 차트
├── LineChart.tsx           # 라인 차트
└── ComposedChart.tsx       # 복합 차트
```

### Phase 8: 자산 관리

**디자인 파일**: `house.pen` (x:20000)

**라우트**:
```
app/(main)/asset/page.tsx
```

### Phase 9: 공유 + 검색 + 예산

**디자인 파일**: `house.pen` (x:21000)

**라우트**:
```
app/(main)/
├── share/page.tsx
├── search/page.tsx
└── budget/page.tsx
```

### Phase 10: 설정 + 마무리

**디자인 파일**: `house.pen` (x:21000)

**라우트**:
```
app/(main)/settings/page.tsx
```

---

## 4. Supabase RPC 함수 활용 패턴

### 4.1 인증 관련

```typescript
// 이메일로 사용자 확인
const { data } = await supabase.rpc('check_user_exists_by_email', {
  target_email: 'user@example.com'
});

// 가계부 접근 권한 확인
const { data: canAccess } = await supabase.rpc('user_can_access_ledger', {
  p_ledger_id: ledgerId
});
```

### 4.2 가계부 초대

```typescript
// 초대 수락
const { data } = await supabase.rpc('accept_ledger_invite', {
  target_invite_id: inviteId
});
```

### 4.3 SMS/Push 포맷 (웹 제외, 참고용)

```typescript
// SMS 포맷 매칭 카운트 증가
await supabase.rpc('increment_sms_format_match_count', {
  format_id: formatId
});

// Push 포맷 매칭 카운트 증가
await supabase.rpc('increment_push_format_match_count', {
  format_id: formatId
});
```

---

## 5. TDD 전략 상세

### 5.1 단위 테스트 (Vitest)

**테스트 대상**:
- 유틸리티 함수
- 커스텀 훅
- 데이터 변환 로직

**예시**:

```typescript
// __tests__/unit/lib/utils/format.test.ts
import { describe, it, expect } from 'vitest';
import { formatCurrency, formatDate } from '@/lib/utils/format';

describe('formatCurrency', () => {
  it('한국 원화 포맷을 올바르게 적용한다', () => {
    expect(formatCurrency(1000000)).toBe('1,000,000원');
  });

  it('음수 금액을 올바르게 처리한다', () => {
    expect(formatCurrency(-50000)).toBe('-50,000원');
  });
});

describe('formatDate', () => {
  it('날짜를 YYYY-MM-DD 형식으로 포맷한다', () => {
    expect(formatDate(new Date('2026-02-06'))).toBe('2026-02-06');
  });
});
```

### 5.2 통합 테스트 (Testing Library)

**테스트 대상**:
- 컴포넌트 렌더링
- 사용자 상호작용
- 폼 제출

**예시**:

```typescript
// __tests__/integration/components/LoginForm.test.tsx
import { describe, it, expect, vi } from 'vitest';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { LoginForm } from '@/components/auth/LoginForm';

describe('LoginForm', () => {
  it('이메일과 비밀번호를 입력하면 로그인 버튼이 활성화된다', () => {
    render(<LoginForm />);

    const emailInput = screen.getByLabelText('이메일');
    const passwordInput = screen.getByLabelText('비밀번호');
    const submitButton = screen.getByRole('button', { name: '로그인' });

    expect(submitButton).toBeDisabled();

    fireEvent.change(emailInput, { target: { value: 'test@example.com' } });
    fireEvent.change(passwordInput, { target: { value: 'password123' } });

    expect(submitButton).toBeEnabled();
  });

  it('로그인 실패 시 에러 메시지를 표시한다', async () => {
    const mockLogin = vi.fn().mockRejectedValue(new Error('Invalid credentials'));
    render(<LoginForm onSubmit={mockLogin} />);

    fireEvent.change(screen.getByLabelText('이메일'), {
      target: { value: 'test@example.com' },
    });
    fireEvent.change(screen.getByLabelText('비밀번호'), {
      target: { value: 'wrong' },
    });
    fireEvent.click(screen.getByRole('button', { name: '로그인' }));

    await waitFor(() => {
      expect(screen.getByText('이메일 또는 비밀번호가 올바르지 않습니다')).toBeInTheDocument();
    });
  });
});
```

### 5.3 E2E 테스트 (Playwright)

**테스트 시나리오**:
- 회원가입 → 로그인 → 거래 추가 → 통계 확인

**예시**:

```typescript
// __tests__/e2e/transaction.spec.ts
import { test, expect } from '@playwright/test';

test('사용자가 거래를 추가하고 통계에서 확인할 수 있다', async ({ page }) => {
  // 로그인
  await page.goto('/login');
  await page.fill('input[name="email"]', 'test@example.com');
  await page.fill('input[name="password"]', 'testpass123');
  await page.click('button[type="submit"]');
  await page.waitForURL('/dashboard');

  // 거래 추가
  await page.click('button:has-text("거래 추가")');
  await page.fill('input[name="amount"]', '50000');
  await page.fill('input[name="title"]', '점심 식사');
  await page.selectOption('select[name="category"]', { label: '식비' });
  await page.click('button:has-text("저장")');

  // 통계 페이지로 이동
  await page.click('a[href="/statistics"]');

  // 거래가 통계에 반영되었는지 확인
  await expect(page.locator('text=식비')).toBeVisible();
  await expect(page.locator('text=50,000원')).toBeVisible();
});
```

---

## 6. Pencil 디자인 워크플로우

### 6.1 디자인 영역 배치 (house.pen)

| 영역 | x 좌표 | y 좌표 | 내용 | Phase |
|------|--------|--------|------|-------|
| 웹 랜딩 페이지 | 12000 | 0 | 랜딩, 이용약관, 개인정보 | Phase 2 |
| 웹 인증 | 14000 | 0 | 로그인, 회원가입 | Phase 3 |
| 웹 레이아웃 | 15000 | 0 | Sidebar, Header | Phase 4 |
| 웹 가계부 | 16000 | 0 | 메인, 캘린더, 거래 모달 | Phase 5 |
| 웹 통계 | 18000 | 0 | 대시보드, 차트, 분석 | Phase 7 |
| 웹 자산 | 20000 | 0 | 자산 관리 | Phase 8 |
| 웹 설정 | 21000 | 0 | 설정, 공유, 검색 | Phase 9, 10 |
| 웹 컴포넌트 | 22000 | 0 | 재사용 UI 컴포넌트 | Phase 4 |

### 6.2 디자인 생성 순서

**Phase 2 (랜딩 페이지) 예시**:

1. Pencil MCP로 프레임 생성 (x:12000)
2. Hero 섹션 디자인
3. Features 섹션 디자인
4. Footer 디자인
5. 스크린샷 확인
6. 코드 구현 (TDD)

**Pencil 작업 예시**:

```javascript
// house.pen에 랜딩 페이지 프레임 생성
landingFrame=I("document", {
  type: "frame",
  name: "Landing Page (Web)",
  x: 12000,
  y: 0,
  width: 1440,
  height: 3000,
  layout: "vertical",
  gap: 0,
  fill: "#FDFDF5"
})

// Hero 섹션
hero=I(landingFrame, {
  type: "frame",
  name: "Hero Section",
  width: "fill_container",
  height: 600,
  layout: "vertical",
  gap: 24,
  padding: [80, 120],
  alignItems: "center",
  justifyContent: "center"
})

// 나머지 섹션들...
```

---

## 7. 성능 최적화 전략

### 7.1 Next.js 최적화

- Server Components 우선 사용
- Client Components 최소화 (`'use client'`)
- 이미지 최적화 (`next/image`)
- 폰트 최적화 (`next/font`)
- 코드 스플리팅 (Dynamic Import)

### 7.2 Supabase 최적화

- SELECT 쿼리 최적화 (필요한 컬럼만)
- 인덱스 활용 (기존 마이그레이션 인덱스)
- RPC 함수 활용 (복잡한 로직 서버 실행)
- Realtime 구독 최소화

### 7.3 번들 사이즈 최적화

- Tree-shaking 활용
- `lodash-es` 대신 개별 함수 import
- `recharts`의 필요한 차트만 import

---

## 8. 보안 고려사항

### 8.1 RLS 정책 재사용

기존 모바일 앱의 RLS 정책을 그대로 활용합니다.

- `profiles`: 본인 프로필만 읽기/쓰기
- `ledgers`: 멤버인 가계부만 읽기, owner만 수정
- `transactions`: 멤버인 가계부의 거래만 CRUD
- `categories`, `payment_methods`: 동일

### 8.2 환경 변수 보호

- `.env.local` 사용 (Git 제외)
- `NEXT_PUBLIC_` 접두사 주의 (클라이언트 노출)
- 서버 전용 변수는 `NEXT_PUBLIC_` 없이 사용

### 8.3 CSRF 보호

- Supabase Auth의 기본 CSRF 보호 활용
- Same-Site Cookie 설정

---

## 9. 접근성 (a11y) 가이드라인

### 9.1 WCAG 2.1 AA 준수

- **색상 대비**: 최소 4.5:1 (텍스트), 3:1 (UI 요소)
- **키보드 네비게이션**: 모든 인터랙티브 요소 Tab 접근
- **포커스 인디케이터**: 명확한 포커스 상태
- **시맨틱 HTML**: `<nav>`, `<main>`, `<article>` 등

### 9.2 ARIA 속성

```tsx
// 버튼 예시
<button
  aria-label="거래 추가"
  aria-describedby="add-transaction-desc"
>
  +
</button>
<span id="add-transaction-desc" className="sr-only">
  새로운 수입 또는 지출 거래를 추가합니다
</span>

// 차트 예시
<div role="img" aria-label="월별 지출 추이 차트">
  <RechartBarChart {...props} />
</div>
```

### 9.3 스크린 리더 지원

- `sr-only` 클래스로 시각적으로 숨김 (스크린 리더는 읽음)
- 이미지에 `alt` 속성
- 링크에 명확한 텍스트

---

## 10. 다국어 (i18n) 전략

### 10.1 next-intl 설정

**i18n.ts**:

```typescript
import { getRequestConfig } from 'next-intl/server';

export default getRequestConfig(async ({ locale }) => ({
  messages: (await import(`./messages/${locale}.json`)).default
}));
```

**messages/ko.json**:

```json
{
  "common": {
    "save": "저장",
    "cancel": "취소",
    "delete": "삭제"
  },
  "auth": {
    "login": "로그인",
    "signup": "회원가입",
    "email": "이메일",
    "password": "비밀번호"
  },
  "transaction": {
    "add": "거래 추가",
    "amount": "금액",
    "category": "카테고리",
    "date": "날짜"
  }
}
```

**messages/en.json**:

```json
{
  "common": {
    "save": "Save",
    "cancel": "Cancel",
    "delete": "Delete"
  },
  "auth": {
    "login": "Login",
    "signup": "Sign Up",
    "email": "Email",
    "password": "Password"
  },
  "transaction": {
    "add": "Add Transaction",
    "amount": "Amount",
    "category": "Category",
    "date": "Date"
  }
}
```

---

## 11. CI/CD 파이프라인 (추후 구성)

### 11.1 GitHub Actions

```yaml
name: CI/CD

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
      - run: npm ci
      - run: npm run typecheck
      - run: npm run lint
      - run: npm test
      - run: npm run build

  e2e:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
      - run: npm ci
      - run: npx playwright install --with-deps
      - run: npm run test:e2e
```

### 11.2 배포 (Vercel)

- 자동 프리뷰 배포 (PR마다)
- 프로덕션 배포 (main 브랜치)
- 환경 변수 Vercel 설정

---

## 12. 다음 단계

Design 문서가 완성되면 다음 Phase로 진행합니다:

1. **Phase 1 구현 시작**: `/pdca do web-version`
   - Next.js 프로젝트 생성
   - 의존성 설치
   - Supabase 클라이언트 설정
   - 테스트 인프라 구축

2. **Phase 2 Pencil 디자인**: house.pen에 랜딩 페이지 디자인 추가

3. **TDD 방식 구현**: 각 기능마다 테스트 먼저 작성

4. **Supabase MCP 활용**: 데이터베이스 작업 시 MCP 도구 우선 사용

---

## 13. 참고 문서

- [Plan 문서](../../01-plan/features/web-version.plan.md)
- [Next.js 15 문서](https://nextjs.org/docs)
- [Supabase SSR 문서](https://supabase.com/docs/guides/auth/server-side/nextjs)
- [Tailwind CSS 4 문서](https://tailwindcss.com/docs)
- [Recharts 문서](https://recharts.org/en-US/)
- [Vitest 문서](https://vitest.dev/)
- [Playwright 문서](https://playwright.dev/)
