# 공유 가계부 웹 통계 플랫폼

공유 가계부 앱의 통계 기능을 확장한 웹 플랫폼입니다.

## 기술 스택

- **Framework**: Next.js 14+ (App Router)
- **Language**: TypeScript
- **Styling**: Tailwind CSS
- **Charts**: Recharts
- **State Management**: Zustand + TanStack Query
- **Backend**: Supabase (PostgreSQL + Auth)
- **Deployment**: Vercel

## 핵심 기능

- ✅ 인증 (앱과 동일한 Supabase 계정)
- ✅ 대시보드 (월별 요약, 차트)
- ✅ 고급 통계 (6가지 차트)
- ✅ Excel/CSV 파일 업로드/다운로드
- ✅ 반응형 디자인 (Mobile/Tablet/Desktop)
- ✅ 다크모드

## 시작하기

### 1. 환경 변수 설정

`.env.local` 파일을 생성하고 Supabase 정보를 입력하세요:

```bash
cp .env.local.example .env.local
```

```env
NEXT_PUBLIC_SUPABASE_URL=your_supabase_url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_anon_key
```

### 2. 의존성 설치

```bash
npm install
```

### 3. 개발 서버 실행

```bash
npm run dev
```

브라우저에서 [http://localhost:3000](http://localhost:3000)을 열어 확인하세요.

## 프로젝트 구조

```
web/
├── src/
│   ├── app/                  # Next.js App Router
│   │   ├── (auth)/          # 인증 관련 라우트
│   │   ├── (main)/          # 메인 앱 라우트
│   │   ├── layout.tsx
│   │   ├── page.tsx
│   │   └── globals.css
│   ├── components/           # UI 컴포넌트
│   │   ├── ui/              # shadcn/ui 컴포넌트
│   │   └── charts/          # 차트 컴포넌트
│   ├── lib/                  # 유틸리티
│   │   ├── supabase/        # Supabase 클라이언트
│   │   └── utils.ts
│   ├── hooks/                # Custom hooks
│   ├── stores/               # Zustand 스토어
│   └── types/                # TypeScript 타입
├── public/                   # 정적 파일
├── package.json
├── tsconfig.json
├── tailwind.config.ts
└── next.config.ts
```

## 빌드 및 배포

### 로컬 빌드

```bash
npm run build
npm run start
```

### Vercel 배포

```bash
# Vercel CLI 설치
npm i -g vercel

# 배포
vercel --prod
```

환경 변수는 Vercel 대시보드에서 설정하세요.

## 개발 가이드

### 디자인 시스템

앱의 디자인 시스템을 웹에 적용했습니다:

- **색상**: `globals.css`의 CSS 변수 사용
- **간격**: `spacing` 토큰 (xs/sm/md/lg/xl/xxl)
- **모서리**: `borderRadius` 토큰
- **타이포그래피**: Material Design 3 기반

### 유틸리티 함수

```typescript
import { formatCurrency, formatDate, cn } from '@/lib/utils';

formatCurrency(15000); // ₩15,000
formatDate(new Date(), 'short'); // 2026. 2. 1.
cn('bg-primary', 'text-white'); // Tailwind 클래스 병합
```

### Supabase 클라이언트

```typescript
// 클라이언트 컴포넌트
import { createClient } from '@/lib/supabase/client';
const supabase = createClient();

// 서버 컴포넌트
import { createClient } from '@/lib/supabase/server';
const supabase = await createClient();
```

## 문서

- [전체 계획](../docs/01-plan/features/web-statistics-platform.plan.md)
- [기능 명세](../docs/01-plan/features/web-statistics-features.md)
- [디자인 매핑](../docs/01-plan/features/web-design-system-mapping.md)
- [개발 로드맵](../docs/01-plan/features/web-development-roadmap.md)

## 라이센스

Private
