# Gap Analysis: 공유 가계부 웹 버전 (web-version)

> 분석일: 2026-02-06
> Design 문서: `docs/02-design/features/web-version.design.md`
> Plan 문서: `docs/01-plan/features/web-version.plan.md`
> 실제 구현: `web/` 디렉토리

---

## 1. Match Rate (일치율)

### 1.1 전체 요약

| 구분 | 설계 항목 수 | 구현 완료 | 부분 구현 | 미구현 | 일치율 |
|------|------------|----------|----------|--------|--------|
| Phase 1 (프로젝트 설정) | 7 | 6 | 0 | 1 | 85.7% |
| Phase 2 (랜딩 페이지) | 5 | 3 | 1 | 1 | 70.0% |
| Phase 3 (인증) | 7 | 2 | 3 | 2 | 42.9% |
| Phase 4 (레이아웃) | 7 | 3 | 0 | 4 | 42.9% |
| Phase 5 (가계부) | 6 | 2 | 0 | 4 | 33.3% |
| Phase 6 (카테고리/결제수단/고정비) | 6 | 2 | 0 | 4 | 33.3% |
| Phase 7 (통계) | 10 | 4 | 1 | 5 | 45.0% |
| Phase 8 (자산) | 5 | 1 | 0 | 4 | 20.0% |
| Phase 9 (검색/공유/예산) | 6 | 3 | 0 | 3 | 50.0% |
| Phase 10 (설정/알림) | 7 | 2 | 0 | 5 | 28.6% |
| 추가 설계 항목 | 7 | 0 | 2 | 5 | 14.3% |
| **합계** | **73** | **28** | **7** | **38** | **38.4%** |

### 1.2 구현 성숙도 분석

| 성숙도 | 설명 | 항목 수 |
|--------|------|---------|
| UI 완료 + 기능 완료 | 디자인과 비즈니스 로직 모두 구현 | 6 |
| UI 완료 + 기능 미구현 (Mock) | UI만 존재, 하드코딩 데이터, Supabase 미연동 | 22 |
| 부분 구현 | 일부만 구현 또는 구현에 결함 있음 | 7 |
| 미구현 | 설계 문서에는 있으나 코드 없음 | 38 |

**핵심 발견**: 구현된 28개 항목 중 22개가 **UI만 존재**(하드코딩 Mock 데이터)하는 상태입니다. Supabase 백엔드와 실제 연동된 기능은 0개입니다.

---

## 2. 구현 완료 항목 목록

### 2.1 Phase 1: 프로젝트 설정 (6/7 완료)

| # | 항목 | 상태 | 비고 |
|---|------|------|------|
| 1 | Next.js 15 프로젝트 생성 (web/) | 완료 | Next.js 15.3, React 19, App Router |
| 2 | Tailwind CSS 설정 + 디자인 토큰 적용 | 완료 | tailwind.config.ts에 디자인 토큰 정의 (Tailwind 3.4, 설계는 4.x) |
| 3 | Supabase 클라이언트 설정 (@supabase/ssr) | 완료 | client.ts, server.ts, middleware.ts 생성 |
| 4 | Vitest + Testing Library 설정 | 완료 | vitest.config.ts, setup.ts, 6개 단위 테스트 작성 |
| 5 | Playwright 설정 | 완료 | playwright.config.ts 생성 (E2E 테스트 파일은 미작성) |
| 6 | TypeScript 타입 정의 | 완료 | database.ts 생성 (profiles, ledgers만 - 나머지 TODO) |

### 2.2 Phase 2: 랜딩 페이지 (3/5 완료)

| # | 항목 | 상태 | 비고 |
|---|------|------|------|
| 1 | 랜딩 페이지 (Hero, Features, CTA, Footer) | 완료 | app/page.tsx - 5개 섹션 구현 |
| 2 | 이용약관 페이지 | 완료 | (legal)/terms/page.tsx - 3개 조항 요약, 전체 문서 미포함 |
| 3 | 개인정보처리방침 페이지 | 완료 | (legal)/privacy/page.tsx - 3개 조항 요약, 전체 문서 미포함 |

### 2.3 Phase 3: 인증 (2/7 완료)

| # | 항목 | 상태 | 비고 |
|---|------|------|------|
| 1 | 로그인 페이지 UI | 완료 | (auth)/login/page.tsx - 이메일/비밀번호 폼 + Google 버튼 |
| 2 | 회원가입 페이지 UI | 완료 | (auth)/signup/page.tsx - 이메일/비밀번호/비밀번호 확인 폼 |

### 2.4 Phase 4: 레이아웃 (3/7 완료)

| # | 항목 | 상태 | 비고 |
|---|------|------|------|
| 1 | Sidebar 네비게이션 | 완료 | components/layout/Sidebar.tsx - 6개 네비게이션 항목 |
| 2 | Header | 완료 | components/layout/Header.tsx - 가계부 선택기(UI만) + 사용자 프로필(하드코딩) |
| 3 | Main Layout | 완료 | (main)/layout.tsx - Sidebar + Header + Content 구조 |

### 2.5 Phase 5-10: 기능 페이지 (UI만 완료, 하드코딩 데이터)

| # | 항목 | 상태 | 비고 |
|---|------|------|------|
| 1 | 대시보드 페이지 | UI 완료 (Mock) | 하드코딩 요약 카드 + 최근 거래 5건 |
| 2 | 거래 내역 페이지 | UI 완료 (Mock) | 하드코딩 거래 8건 + 월간 요약 |
| 3 | 통계 페이지 | UI 완료 (Mock) | 4개 Recharts 차트 (모두 하드코딩 데이터) |
| 4 | 자산 관리 페이지 | UI 완료 (Mock) | 하드코딩 자산 5건 + 총 자산/카테고리별 |
| 5 | 검색 페이지 | UI 완료 (Mock) | 하드코딩 데이터 내 텍스트 검색 + 수입/지출 필터 |
| 6 | 카테고리 관리 페이지 | UI 완료 (Mock) | 3개 탭(지출/수입/자산) + 카테고리 그리드 |
| 7 | 결제수단 관리 페이지 | UI 완료 (Mock) | 하드코딩 3개 결제수단 |
| 8 | 예산 관리 페이지 | UI 완료 (Mock) | 하드코딩 4개 카테고리 진행률 바 |
| 9 | 공유 관리 페이지 | UI 완료 (Mock) | 하드코딩 2명 멤버 + 빈 대기 초대 |
| 10 | 설정 페이지 | UI 완료 (Mock) | 하드코딩 프로필 + 설정 메뉴 목록 |
| 11 | 알림 설정 페이지 | UI 완료 (Mock) | 5개 토글 (로컬 state만, 저장 안됨) |

### 2.6 테스트

| # | 항목 | 상태 | 비고 |
|---|------|------|------|
| 1 | 랜딩 페이지 테스트 | 완료 | 5개 테스트 케이스 (렌더링 확인) |
| 2 | 로그인 페이지 테스트 | 완료 | 5개 테스트 케이스 (렌더링 확인) |
| 3 | 설정 페이지 테스트 | 존재 | 파일 존재 확인됨 |
| 4 | 검색 페이지 테스트 | 존재 | 파일 존재 확인됨 |
| 5 | 예산 페이지 테스트 | 존재 | 파일 존재 확인됨 |
| 6 | 대시보드 페이지 테스트 | 존재 | 파일 존재 확인됨 |

---

## 3. 미구현/부분구현 항목 목록

### 3.1 Critical (치명적) - 앱 핵심 기능 부재

| # | Phase | 항목 | 상태 | 설명 |
|---|-------|------|------|------|
| 1 | 3 | Supabase Auth 실제 연동 | 미구현 | 로그인/회원가입 폼이 submit 시 아무 동작 안 함. 실제 Supabase Auth API 호출 코드 없음. |
| 2 | 3 | Protected Routes (실제 보호) | 결함 있음 | middleware.ts의 조건문에 `!request.nextUrl.pathname.startsWith('/')` 이 포함되어 모든 경로가 조건을 만족하지 않으므로, 인증되지 않은 사용자도 모든 페이지에 접근 가능. |
| 3 | 5 | 거래 CRUD (Supabase 연동) | 미구현 | 모든 거래 데이터가 하드코딩. Supabase에서 데이터를 읽거나 쓰는 코드 없음. |
| 4 | 6 | 카테고리/결제수단 CRUD (Supabase 연동) | 미구현 | '추가' 버튼 존재하나 클릭 시 동작 없음. |
| 5 | 전체 | Supabase 데이터 연동 | 미구현 | 모든 페이지가 하드코딩 Mock 데이터 사용. Supabase 쿼리 코드 없음. |
| 6 | 전체 | TanStack Query 상태관리 | 미구현 | package.json에 설치되어 있으나 사용하는 코드 0개. |

### 3.2 High (높음) - 주요 기능 부재

| # | Phase | 항목 | 상태 | 설명 |
|---|-------|------|------|------|
| 1 | 1 | ESLint + Prettier 설정 | 미구현 | eslint, eslint-config-next가 devDependencies에 있으나 .eslintrc/eslint.config 파일 없음 |
| 2 | 3 | 비밀번호 재설정 페이지 | 미구현 | forgot-password 디렉토리 없음 |
| 3 | 3 | 이메일 인증 처리 | 미구현 | 인증 확인 콜백 페이지 없음 |
| 4 | 4 | 기본 UI 컴포넌트 라이브러리 | 미구현 | components/ui/ 디렉토리 없음 (Button, Input, Card, Dialog, Toast 등) |
| 5 | 4 | 테마 시스템 (라이트/다크 모드) | 미구현 | tailwind.config에 darkMode: 'class' 설정만, 실제 토글/전환 없음 |
| 6 | 4 | 반응형 레이아웃 (모바일 하단 네비게이션) | 미구현 | MobileNav 컴포넌트 없음. Sidebar가 항상 데스크톱 크기로 표시 |
| 7 | 5 | 캘린더 뷰 | 미구현 | 거래 목록만 존재, 캘린더 UI 없음 |
| 8 | 5 | 일별/주별 뷰 전환 | 미구현 | 뷰 전환 기능 없음 |
| 9 | 5 | 거래 추가/수정 모달 | 미구현 | '거래 추가' 버튼 클릭 시 동작 없음 |
| 10 | 6 | 고정비 관리 페이지 | 미구현 | fixed-expenses 디렉토리 없음, 설정 메뉴에도 포함 안 됨 |
| 11 | 7 | 기간 선택 기능 (실제 동작) | 부분 구현 | UI에 '이번 달/지난 달/올해' 버튼 있으나 state만 변경, 데이터 변경 없음 |
| 12 | 7 | CSV/Excel/PDF 내보내기 | 미구현 | 내보내기 관련 코드 없음 |
| 13 | 7 | 드릴다운 (카테고리 클릭 시) | 미구현 | 차트 클릭 이벤트 없음 |
| 14 | 8 | 자산 CRUD (Supabase 연동) | 미구현 | '자산 추가' 버튼 클릭 시 동작 없음 |
| 15 | 8 | 자산 배분 차트 | 미구현 | 차트 없음, 숫자만 표시 |
| 16 | 8 | 자산 추이 라인 차트 | 미구현 | 추이 차트 없음 |
| 17 | 9 | 검색 고급 필터 (날짜, 금액 범위) | 미구현 | 텍스트 + 수입/지출 필터만 존재 |
| 18 | 10 | 프로필 편집 기능 | 미구현 | 프로필 섹션은 하드코딩 표시만 |
| 19 | 10 | E2E 테스트 (Playwright) | 미구현 | playwright.config.ts만 존재, __tests__/e2e/ 디렉토리 비어있음 |

### 3.3 Medium (중간) - 품질/사용성 관련

| # | Phase | 항목 | 상태 | 설명 |
|---|-------|------|------|------|
| 1 | 1 | TypeScript 타입 정의 (완전한) | 부분 구현 | profiles, ledgers만 정의. transactions, categories, payment_methods 등 미정의 (TODO 주석) |
| 2 | 2 | 반응형 디자인 (모바일/태블릿/데스크톱) | 부분 구현 | 랜딩 페이지가 flex/고정 width 사용하여 모바일에서 깨질 가능성 (반응형 break point 미사용) |
| 3 | 2 | SEO 메타 태그 | 부분 구현 | RootLayout에 title/description만 존재. Open Graph, Twitter Card, sitemap.xml, robots.txt 없음 |
| 4 | 7 | 커스텀 날짜 범위 선택 | 미구현 | 3개 프리셋만 있고 커스텀 Date Picker 없음 |
| 5 | 7 | 분기별 비교 | 미구현 | 비교 기능 없음 |
| 6 | 7 | 전년 동기 비교 | 미구현 | 비교 기능 없음 |
| 7 | 8 | 자산 목표 관리 | 미구현 | 목표 설정 UI 없음 |
| 8 | 10 | 테마/언어 설정 | 미구현 | 설정 페이지에 테마/언어 메뉴 없음 |
| 9 | 10 | 성능 최적화 | 미확인 | Lighthouse 테스트 미수행 |
| 10 | 10 | 접근성 검증 | 미확인 | WCAG 검증 미수행, aria 속성 부재 |
| 11 | 추가 | React Hook Form + Zod 폼 유효성 | 미구현 | package.json에 설치되어 있으나 사용하는 코드 0개 |
| 12 | 추가 | next-intl 다국어 | 미구현 | package.json에 설치되어 있으나 messages/ 디렉토리 없고 사용 코드 0개 |

### 3.4 Low (낮음) - 개선 사항

| # | Phase | 항목 | 상태 | 설명 |
|---|-------|------|------|------|
| 1 | 추가 | CI/CD (GitHub Actions) | 미구현 | .github/ 디렉토리 없음 |
| 2 | 추가 | Vercel 배포 | 미구현 | 배포 설정 없음 |
| 3 | 2 | 법적 문서 전체 내용 | 부분 구현 | 이용약관/개인정보 페이지에 3개 조항 요약만 표시. "전체 약관은 docs 참조하세요" 안내 |
| 4 | 4 | components/forms/ 디렉토리 | 미구현 | 폼 전용 컴포넌트 없음 |
| 5 | 계획 | features/ 디렉토리 구조 | 미구현 | 설계의 Feature-first 구조 미적용 (features/ 디렉토리 없음) |
| 6 | 계획 | stores/ 디렉토리 | 미구현 | Zustand 스토어 미구현 |
| 7 | 계획 | lib/hooks/ 디렉토리 | 미구현 | 커스텀 훅 없음 (useAuth 등) |
| 8 | 계획 | lib/utils/ 디렉토리 | 미구현 | 유틸리티 함수 없음 (formatCurrency 등이 각 페이지에 중복 정의) |

---

## 4. 구현 품질 상세 분석

### 4.1 미들웨어 보호 로직 결함 (Critical)

`web/lib/supabase/middleware.ts` 43번째 줄:

```typescript
if (
  !user &&
  !request.nextUrl.pathname.startsWith('/login') &&
  !request.nextUrl.pathname.startsWith('/signup') &&
  !request.nextUrl.pathname.startsWith('/') &&      // <-- 이 조건이 항상 false
  !request.nextUrl.pathname.startsWith('/terms') &&
  !request.nextUrl.pathname.startsWith('/privacy')
)
```

`!request.nextUrl.pathname.startsWith('/')`는 모든 유효한 경로에서 false가 되므로 전체 조건문이 항상 false입니다. 즉, **인증되지 않은 사용자가 모든 페이지에 접근 가능**합니다.

**수정 방안**: 이 줄을 제거하고, 랜딩 페이지(`/`)는 명시적으로 허용하도록 변경해야 합니다.

### 4.2 코드 중복 문제 (Medium)

`formatAmount` 함수가 다음 파일들에 각각 별도로 정의되어 있습니다:
- `web/app/(main)/dashboard/page.tsx`
- `web/app/(main)/ledger/page.tsx`
- `web/app/(main)/search/page.tsx`
- `web/app/(main)/asset/page.tsx`
- `web/app/(main)/settings/budget/page.tsx`

이는 `lib/utils/` 에 공통 유틸리티로 추출되어야 합니다.

### 4.3 설치된 패키지 vs 실제 사용

| 패키지 | 설치 여부 | 사용 여부 | 비고 |
|--------|----------|----------|------|
| @supabase/ssr | 설치됨 | 클라이언트 설정만 | 실제 쿼리 호출 없음 |
| @supabase/supabase-js | 설치됨 | 타입만 import | 실제 데이터 조회 없음 |
| @tanstack/react-query | 설치됨 | 미사용 | Provider 설정 없음, 사용 코드 0개 |
| react-hook-form | 설치됨 | 미사용 | 폼 핸들링에 사용 안 함 (HTML form만) |
| zod | 설치됨 | 미사용 | 스키마 정의 없음 |
| next-intl | 설치됨 | 미사용 | i18n 설정/messages 없음 |
| recharts | 설치됨 | **사용 중** | 4개 차트 컴포넌트에서 활용 |
| clsx | 설치됨 | 미사용 | className 조합에 사용 안 함 |
| tailwind-merge | 설치됨 | 미사용 | 클래스 병합에 사용 안 함 |

**7개 패키지 중 1개만 실제 사용** (recharts). 나머지 6개는 Dead Code 상태입니다.

### 4.4 디렉토리 구조 차이

**설계된 구조**:
```
web/
├── app/
├── components/
│   ├── ui/           <-- 미구현
│   ├── charts/       <-- 구현됨
│   ├── layout/       <-- 구현됨
│   └── forms/        <-- 미구현
├── features/         <-- 미구현
├── lib/
│   ├── supabase/     <-- 구현됨
│   ├── utils/        <-- 미구현
│   ├── hooks/        <-- 미구현
│   ├── types/        <-- 부분 구현
│   └── constants/    <-- 미구현
├── stores/           <-- 미구현
└── styles/           <-- 미구현
```

**실제 구조**:
```
web/
├── app/              <-- 구현됨 (16개 페이지)
├── components/
│   ├── charts/       <-- 구현됨 (4개 파일)
│   └── layout/       <-- 구현됨 (2개 파일)
├── lib/
│   ├── supabase/     <-- 구현됨 (3개 파일, 설정만)
│   └── types/        <-- 부분 구현 (1개 파일, 불완전)
└── __tests__/        <-- 구현됨 (7개 테스트 파일)
```

---

## 5. 종합 평가

### 5.1 현재 상태 진단

**전체 일치율: 38.4%** (73개 설계 항목 중 28개 구현)

그러나 이 수치조차 과대평가입니다. 실질적 관점에서 보면:

- **실제 동작하는 기능**: 프로젝트 설정, 정적 페이지 렌더링, 차트 렌더링(Mock 데이터)뿐
- **Supabase 연동 기능**: 0개 (모든 데이터가 하드코딩)
- **사용자 인터랙션**: 검색 필터링(Mock 데이터 내), 기간 선택(UI만), 알림 토글(로컬 state만)
- **실질적 기능 일치율**: 약 **15-20%** (인프라 + 정적 UI만 완성)

### 5.2 구현 상태 분류

```
Phase 1 (인프라):      [=========-] 86%  - 거의 완료 (ESLint 설정만 부재)
Phase 2 (랜딩):        [======----] 70%  - UI 완료, SEO/반응형 미확인
Phase 3 (인증):        [==--------] 29%  - UI만 완료, 실제 인증 미연동
Phase 4 (레이아웃):    [===-------] 43%  - 기본 레이아웃만, UI 라이브러리 없음
Phase 5 (가계부):      [=---------] 17%  - 목록 UI만, CRUD/캘린더 미구현
Phase 6 (카테고리):    [=---------] 17%  - 목록 UI만, CRUD 미구현
Phase 7 (통계):        [===-------] 40%  - 차트 UI 완료, 실제 데이터 연동 없음
Phase 8 (자산):        [=---------] 10%  - 목록 UI만, 차트/CRUD 미구현
Phase 9 (검색/공유):   [==--------] 25%  - UI만, Supabase 미연동
Phase 10 (설정):       [=---------] 14%  - 설정 목록만, 실제 기능 없음
```

### 5.3 주요 격차 (Gap) 분석

#### 격차 1: 백엔드 연동 전무 (Critical)
- **현상**: 모든 페이지가 하드코딩된 Mock 데이터로 렌더링
- **영향**: 실제 서비스로서 기능하지 않음
- **필요 작업량**: 전체 작업의 약 40% 차지

#### 격차 2: 인증 시스템 미완성 (Critical)
- **현상**: 로그인/회원가입 UI만 존재, Supabase Auth 호출 없음
- **영향**: 사용자 식별 불가, 데이터 접근 제어 불가
- **부가 이슈**: 미들웨어 보호 로직에 논리적 결함 존재

#### 격차 3: UI 컴포넌트 라이브러리 부재 (High)
- **현상**: 재사용 가능한 Button, Input, Card, Dialog, Toast 컴포넌트 없음
- **영향**: 각 페이지에서 스타일 중복, 일관성 저하, 유지보수 어려움

#### 격차 4: 반응형/접근성 미대응 (High)
- **현상**: 데스크톱 고정 레이아웃만 존재
- **영향**: 모바일/태블릿에서 사용 불가, WCAG 비준수

#### 격차 5: 설치된 라이브러리 미활용 (Medium)
- **현상**: 7개 패키지 설치 후 미사용 (TanStack Query, React Hook Form, Zod 등)
- **영향**: 번들 사이즈 불필요한 증가, 설계 의도 미반영

### 5.4 권장 우선순위

| 순위 | 작업 | 심각도 | 예상 공수 |
|------|------|--------|----------|
| 1 | 미들웨어 보호 로직 버그 수정 | Critical | 0.5일 |
| 2 | Supabase Auth 연동 (로그인/회원가입/세션관리) | Critical | 2-3일 |
| 3 | UI 컴포넌트 라이브러리 구축 (Button, Input, Card, Dialog, Toast) | High | 2-3일 |
| 4 | 공통 유틸리티 추출 (formatCurrency, formatDate 등) | Medium | 0.5일 |
| 5 | 거래 CRUD + Supabase 연동 (핵심 기능) | Critical | 3-5일 |
| 6 | 카테고리/결제수단 CRUD + Supabase 연동 | High | 2-3일 |
| 7 | TanStack Query 상태관리 적용 | High | 2-3일 |
| 8 | 통계 차트 실제 데이터 연동 | High | 2-3일 |
| 9 | 반응형 레이아웃 + 모바일 네비게이션 | High | 2-3일 |
| 10 | 비밀번호 재설정 + 이메일 인증 | High | 1-2일 |
| 11 | 고정비 관리 페이지 | Medium | 1-2일 |
| 12 | 다크 모드 구현 | Medium | 1-2일 |
| 13 | React Hook Form + Zod 폼 유효성 적용 | Medium | 2-3일 |
| 14 | next-intl 다국어 적용 | Medium | 2-3일 |
| 15 | E2E 테스트 작성 (Playwright) | Medium | 2-3일 |
| 16 | 데이터 내보내기 (CSV/Excel/PDF) | Medium | 2-3일 |
| 17 | SEO 최적화 (OG Tags, sitemap, robots.txt) | Low | 1일 |
| 18 | CI/CD (GitHub Actions) + Vercel 배포 | Low | 1-2일 |
| 19 | 접근성 검증 + 개선 | Low | 2-3일 |
| 20 | ESLint + Prettier 설정 | Low | 0.5일 |

**예상 총 잔여 작업량**: 약 30-45일 (1인 기준)

### 5.5 결론

현재 웹 버전은 **프로토타입/목업 수준**입니다. 프로젝트 인프라(Phase 1)는 잘 구축되어 있고, UI 스캐폴딩이 전체 페이지에 걸쳐 완성되어 있어 시각적으로는 완성도가 높아 보입니다. 그러나 **실제 비즈니스 로직과 백엔드 연동이 전혀 없는 상태**이며, 설치된 핵심 라이브러리들(TanStack Query, React Hook Form, Zod, next-intl)이 활용되지 않고 있습니다.

가장 시급한 작업은 **(1) 미들웨어 보안 결함 수정**, **(2) Supabase Auth 연동**, **(3) 핵심 CRUD 기능 구현**입니다. 이 세 가지가 완료되면 나머지 기능은 이미 구축된 UI를 기반으로 점진적으로 연동할 수 있습니다.

---

## 6. 파일 참조

### 설계 문서
- `docs/01-plan/features/web-version.plan.md`
- `docs/02-design/features/web-version.design.md`

### 구현 파일 (16개 페이지)
- `web/app/page.tsx` (랜딩)
- `web/app/(legal)/terms/page.tsx`
- `web/app/(legal)/privacy/page.tsx`
- `web/app/(auth)/login/page.tsx`
- `web/app/(auth)/signup/page.tsx`
- `web/app/(main)/dashboard/page.tsx`
- `web/app/(main)/ledger/page.tsx`
- `web/app/(main)/statistics/page.tsx`
- `web/app/(main)/asset/page.tsx`
- `web/app/(main)/search/page.tsx`
- `web/app/(main)/settings/page.tsx`
- `web/app/(main)/settings/categories/page.tsx`
- `web/app/(main)/settings/payment-methods/page.tsx`
- `web/app/(main)/settings/budget/page.tsx`
- `web/app/(main)/settings/share/page.tsx`
- `web/app/(main)/settings/notifications/page.tsx`

### 컴포넌트 (6개)
- `web/components/layout/Sidebar.tsx`
- `web/components/layout/Header.tsx`
- `web/components/charts/CategoryPieChart.tsx`
- `web/components/charts/MonthlyTrendChart.tsx`
- `web/components/charts/PaymentMethodChart.tsx`
- `web/components/charts/MemberChart.tsx`

### 인프라 파일
- `web/lib/supabase/client.ts`
- `web/lib/supabase/server.ts`
- `web/lib/supabase/middleware.ts`
- `web/lib/types/database.ts`
- `web/middleware.ts`
- `web/tailwind.config.ts`
- `web/vitest.config.ts`
- `web/playwright.config.ts`
- `web/__tests__/setup.ts`

### 테스트 파일 (6개)
- `web/__tests__/unit/pages/landing-page.test.tsx`
- `web/__tests__/unit/pages/login-page.test.tsx`
- `web/__tests__/unit/pages/settings.test.tsx`
- `web/__tests__/unit/pages/search.test.tsx`
- `web/__tests__/unit/pages/budget.test.tsx`
- `web/__tests__/unit/pages/dashboard.test.tsx`
