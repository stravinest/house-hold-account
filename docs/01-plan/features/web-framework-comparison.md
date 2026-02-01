# 웹 프레임워크 비교 분석

## 프로젝트 요구사항 정리

### 핵심 요구사항
- ✅ Supabase 연동 (기존 데이터베이스)
- ✅ 통계 차트 렌더링 (클라이언트 인터랙티브)
- ✅ 파일 업로드/다운로드 (Excel/CSV)
- ✅ 앱과 동일한 디자인 시스템
- ✅ 반응형 디자인
- ✅ SEO는 중요하지 않음 (인증 필요한 대시보드)

### 비기능 요구사항
- 빠른 개발 속도 (10일 목표)
- 풍부한 생태계 (shadcn/ui, Recharts 등)
- 배포 편의성 (Vercel)
- 타입 안전성 (TypeScript)

---

## 1. Next.js 14+ (App Router)

### ⭐ 장점

#### 1.1 풍부한 생태계
```typescript
// shadcn/ui와 완벽한 호환
// 거의 모든 라이브러리가 Next.js 예제 제공
import { Button } from '@/components/ui/button';
```

#### 1.2 Vercel 배포 최적화
```bash
# 한 줄 배포
vercel --prod

# 자동 프리뷰, 엣지 네트워크, 이미지 최적화 등 무료
```

#### 1.3 서버/클라이언트 컴포넌트 분리
```typescript
// Server Component (기본): 빠른 초기 로딩
export default async function Dashboard() {
  const data = await getStatistics(); // 서버에서 fetch
  return <Chart data={data} />;
}

// Client Component: 인터랙티브 차트
'use client';
export function Chart({ data }) {
  return <Recharts data={data} />;
}
```

#### 1.4 파일 기반 라우팅 (App Router)
```
app/
├── (auth)/login/page.tsx          → /login
├── (main)/dashboard/page.tsx      → /dashboard
└── (main)/statistics/page.tsx     → /statistics

# 직관적이고 빠른 개발
```

#### 1.5 이미지/폰트 자동 최적화
```typescript
import Image from 'next/image';

<Image src="/logo.png" width={200} height={100} alt="Logo" />
// 자동으로 WebP 변환, lazy loading, 반응형 이미지
```

#### 1.6 풍부한 문서 및 커뮤니티
- 공식 문서가 매우 상세함
- shadcn/ui, TanStack Query 등 모든 라이브러리가 Next.js 예제 제공
- Stack Overflow, GitHub Discussions 활발

### ❌ 단점

#### 1.1 학습 곡선 (App Router)
```typescript
// 서버/클라이언트 컴포넌트 구분이 처음엔 헷갈림
// 'use client' 지시어 필요
```

#### 1.2 번들 크기
```
초기 번들: ~200KB (gzip)
비교적 무거운 편
```

#### 1.3 Vercel 종속성
```
Vercel 외 배포 시 일부 기능 제한
(Edge Runtime, Image Optimization 등)
```

---

## 2. Remix 2.0+

### ⭐ 장점

#### 2.1 Web 표준 중심
```typescript
// Form 기반 데이터 변경 (Progressive Enhancement)
export async function action({ request }: ActionFunctionArgs) {
  const formData = await request.formData();
  await updateTransaction(formData);
  return redirect('/dashboard');
}

export default function EditTransaction() {
  return (
    <Form method="post">
      <input name="amount" />
      <button>저장</button>
    </Form>
  );
}
// JavaScript 꺼져도 동작!
```

#### 2.2 뛰어난 데이터 로딩
```typescript
// 병렬 로딩 (Waterfall 없음)
export async function loader({ params }: LoaderFunctionArgs) {
  // 자동으로 병렬 실행
  return json({
    user: await getUser(params.id),
    stats: await getStats(params.id),
  });
}

// Next.js는 수동으로 Promise.all 해야 함
```

#### 2.3 Optimistic UI 기본 지원
```typescript
import { useFetcher } from '@remix-run/react';

function TransactionItem() {
  const fetcher = useFetcher();
  const isDeleting = fetcher.state !== 'idle';

  return (
    <div style={{ opacity: isDeleting ? 0.5 : 1 }}>
      <fetcher.Form method="post" action="/delete">
        <button>삭제</button>
      </fetcher.Form>
    </div>
  );
}
```

#### 2.4 에러 핸들링
```typescript
// 라우트별 에러 바운더리
export function ErrorBoundary() {
  const error = useRouteError();
  return <div>에러 발생: {error.message}</div>;
}
```

#### 2.5 배포 플랫폼 자유도
```
- Vercel
- Netlify
- Cloudflare Workers
- Fly.io
- 자체 서버 (Express, Fastify 등)
```

### ❌ 단점

#### 2.1 생태계 규모
```
shadcn/ui: Next.js 우선 지원
많은 라이브러리가 Next.js 예제만 제공
Remix 예제 찾기 어려움
```

#### 2.2 SSR 강제
```typescript
// 모든 페이지가 SSR
// 정적 사이트 생성(SSG) 불가
// CDN 캐싱 어려움
```

#### 2.3 파일 업로드 처리
```typescript
// FormData만 사용 가능
// Blob, File 직접 처리 어려움
// Excel/CSV 파싱을 서버에서 해야 함

export async function action({ request }: ActionFunctionArgs) {
  const formData = await request.formData();
  const file = formData.get('file') as File;

  // 서버에서 파싱 (클라이언트 측 미리보기 어려움)
  const data = await parseExcel(file);
  // ...
}
```

#### 2.4 클라이언트 인터랙티브 차트
```typescript
// Recharts 같은 클라이언트 라이브러리 사용 시
// Hydration 이슈 발생 가능
// SSR/CSR 경계가 모호함
```

#### 2.5 커뮤니티 규모
```
Next.js: GitHub Stars 120k+
Remix: GitHub Stars 28k+

작은 커뮤니티 = 적은 예제, 적은 플러그인
```

---

## 3. Vite + React (SPA)

### ⭐ 장점

#### 3.1 매우 빠른 개발 속도
```bash
# HMR 속도 (밀리초 단위)
Vite: ~50ms
Next.js: ~200ms
```

#### 3.2 단순함
```typescript
// 서버/클라이언트 구분 없음
// 모든 코드가 클라이언트에서 실행
```

#### 3.3 번들 크기 최적화
```
초기 번들: ~100KB (gzip)
Next.js보다 50% 작음
```

#### 3.4 자유로운 라우팅
```typescript
import { BrowserRouter } from 'react-router-dom';

// React Router, TanStack Router 등 선택 가능
```

### ❌ 단점

#### 3.1 SSR/SEO 불가
```
모든 페이지가 CSR
초기 로딩 느림 (JavaScript 번들 다운로드 필요)
```

#### 3.2 Supabase Auth SSR 문제
```typescript
// 쿠키 기반 세션 관리 어려움
// 새로고침 시 로그인 상태 유지 복잡
```

#### 3.3 파일 라우팅 없음
```typescript
// 수동으로 라우트 정의 필요
<Route path="/dashboard" element={<Dashboard />} />
<Route path="/statistics" element={<Statistics />} />
// ... 30개 이상 라우트 수동 작성
```

---

## 4. SvelteKit

### ⭐ 장점

#### 4.1 작은 번들 크기
```
초기 번들: ~50KB (gzip)
가장 가벼움
```

#### 4.2 빠른 성능
```
Virtual DOM 없음
컴파일 타임 최적화
```

#### 4.3 간결한 문법
```svelte
<script>
  let count = 0;
</script>

<button on:click={() => count++}>
  {count}
</button>
```

### ❌ 단점

#### 4.1 생태계 규모
```
shadcn/ui: Svelte 버전 없음
Recharts: Svelte 버전 없음
대부분 라이브러리를 직접 포팅해야 함
```

#### 4.2 TypeScript 지원 약함
```
타입 추론이 React보다 약함
```

#### 4.3 학습 곡선
```
새로운 문법 학습 필요
React 경험 재사용 불가
```

---

## 5. Astro

### ⭐ 장점

#### 5.1 정적 사이트에 최적화
```typescript
// Island Architecture
// 필요한 부분만 JavaScript
```

#### 5.2 다양한 프레임워크 혼용
```astro
---
import ReactChart from './Chart.tsx';
import SvelteForm from './Form.svelte';
---

<ReactChart client:load />
<SvelteForm client:idle />
```

### ❌ 단점

#### 5.1 인터랙티브 앱에 부적합
```
정적 콘텐츠에 최적화
대시보드 같은 SPA에는 오버엔지니어링
```

#### 5.2 Supabase Auth 복잡
```
SSR 인증 처리 복잡
```

---

## 비교표

| 항목 | Next.js | Remix | Vite+React | SvelteKit | Astro |
|------|---------|-------|------------|-----------|-------|
| **생태계** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐ |
| **개발 속도** | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ |
| **성능** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **번들 크기** | ⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **학습 곡선** | ⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐ |
| **배포** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **Supabase** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ |
| **파일 처리** | ⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐ |
| **차트** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐ |
| **shadcn/ui** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ❌ | ⭐⭐⭐ |

---

## 프로젝트별 추천

### 이 프로젝트 (통계 대시보드)에 가장 적합한 순서

#### 🥇 1순위: **Next.js 14+ (App Router)**

**추천 이유:**
```
✅ shadcn/ui 완벽 지원 (디자인 시스템 빠른 구축)
✅ Recharts 예제 풍부 (6가지 차트 빠른 구현)
✅ Supabase 공식 가이드 (SSR Auth)
✅ Vercel 배포 간편 (10일 안에 완성 목표)
✅ 풍부한 커뮤니티 (문제 해결 빠름)
✅ 파일 업로드 클라이언트 처리 (미리보기 구현 쉬움)
```

**단점 감수 가능:**
```
❌ 번들 크기 큼 → 대시보드는 초기 로딩보다 기능성 중요
❌ App Router 학습 → 문서 풍부해서 빠르게 학습 가능
❌ Vercel 종속 → 프로젝트 특성상 문제 없음
```

#### 🥈 2순위: **Vite + React + React Router**

**추천 이유:**
```
✅ 매우 빠른 개발 속도 (HMR)
✅ 단순한 구조 (서버/클라이언트 구분 없음)
✅ 파일 업로드 처리 자유로움
✅ 작은 번들 크기
```

**단점:**
```
❌ 파일 라우팅 수동 설정 (30+ 라우트)
❌ Supabase SSR Auth 복잡
❌ SEO 불가 (이 프로젝트는 괜찮음)
```

**추천 상황:**
- 이미 Vite + React 경험이 많은 경우
- SSR이 필요 없는 경우
- 번들 크기 최적화가 최우선인 경우

#### 🥉 3순위: **Remix**

**추천 이유:**
```
✅ 데이터 로딩 우수
✅ Optimistic UI
✅ Web 표준
```

**단점:**
```
❌ shadcn/ui 예제 부족
❌ 파일 업로드 클라이언트 미리보기 어려움
❌ Recharts SSR 이슈 가능성
❌ 커뮤니티 작음
```

**추천 상황:**
- Remix 경험이 이미 있는 경우
- 서버 중심 아키텍처 선호
- 배포 플랫폼 자유도 필요

---

## 최종 추천: Next.js 14+

### 선택 이유 요약

#### 1. 시간 효율성 (10일 목표)
```typescript
// shadcn/ui 설치 1분
npx shadcn-ui@latest init
npx shadcn-ui@latest add button input card dialog

// 모든 컴포넌트 예제가 Next.js 기준
// 복붙으로 빠른 개발 가능
```

#### 2. 파일 처리 편의성
```typescript
'use client';

// 클라이언트에서 Excel 파싱
const handleUpload = async (file: File) => {
  const data = await parseExcelFile(file); // 브라우저에서 실행
  setPreview(data); // 즉시 미리보기
};

// Remix는 서버에서 파싱해야 함 (미리보기 구현 복잡)
```

#### 3. Supabase 공식 지원
```typescript
// @supabase/ssr 패키지
// Next.js용 공식 가이드
// SSR Auth 쿠키 관리 자동
```

#### 4. Recharts 호환성
```typescript
'use client';

// Recharts는 클라이언트 라이브러리
// Next.js Client Component로 쉽게 사용
export function Chart() {
  return <LineChart data={data} />;
}

// Remix는 SSR 때문에 Hydration 이슈 가능
```

#### 5. 배포 편의성
```bash
# Vercel 무료 티어
- 자동 HTTPS
- 엣지 네트워크
- 이미지 최적화
- 프리뷰 배포 (PR별)
- 환경 변수 관리

# 1분 배포
vercel --prod
```

---

## 대안 고려 시나리오

### 만약 Vite + React를 선택한다면

**프로젝트 구조:**
```typescript
// Vite + React + React Router + TanStack Query

npm create vite@latest web -- --template react-ts
npm install react-router-dom @tanstack/react-query
npm install @supabase/supabase-js

// 장점
- 빠른 HMR
- 단순한 구조
- 작은 번들

// 단점
- 라우팅 수동 설정
- Supabase Auth SSR 불가 (쿠키 세션 복잡)
```

### 만약 Remix를 선택한다면

**프로젝트 구조:**
```typescript
npx create-remix@latest web

// 장점
- 데이터 로딩 최적화
- Form 기반 변경
- Optimistic UI

// 단점
- shadcn/ui 예제 부족 (직접 포팅 필요)
- Excel 파일 클라이언트 미리보기 구현 복잡
- Recharts SSR 이슈 가능성
```

---

## 결론

### ✅ Next.js 14+ 유지 추천

**이유:**
1. **10일 개발 목표** → 가장 빠른 개발 가능
2. **파일 처리 중요** → 클라이언트 미리보기 쉬움
3. **차트 6종** → Recharts 예제 풍부
4. **디자인 시스템** → shadcn/ui 완벽 지원
5. **Supabase 연동** → 공식 가이드 존재

**다른 선택지가 나은 경우:**
- Vite: 이미 Vite 경험 많고, 번들 크기 최우선
- Remix: Remix 경험 많고, 서버 중심 선호
- SvelteKit: 새로운 기술 학습 의지, 성능 최우선
- Astro: 정적 콘텐츠 위주 (이 프로젝트는 아님)

---

## 다음 단계 제안

### Option A: Next.js 유지 (추천)
```bash
cd web
npx create-next-app@latest . --typescript --tailwind --app
```

### Option B: Vite + React (대안)
```bash
cd web
npm create vite@latest . -- --template react-ts
npm install react-router-dom @tanstack/react-query
```

### Option C: Remix (도전)
```bash
cd web
npx create-remix@latest .
```

**어떤 선택을 하시겠습니까?**
