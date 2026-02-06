# Plan: 공유 가계부 웹 버전 (web-version)

> PDCA Phase: Plan
> 작성일: 2026-02-06
> 상태: 작성 중

---

## 1. 개요

### 1.1 목적

현재 Flutter 기반 모바일 앱의 웹 버전을 Next.js + Tailwind CSS로 구현한다.
기존 앱의 모든 기능을 포함하되, 통계/분석 기능을 대폭 강화하여 데스크톱 환경에 최적화된 경험을 제공한다.

### 1.2 핵심 원칙

1. **디자인 퍼스트**: house.pen(Pencil MCP)에 웹 디자인을 먼저 추가한 후 코드를 구현
2. **TDD 방식**: 테스트 코드를 먼저 작성하고 최소한의 코드로 구현
3. **기존 인프라 활용**: 동일한 Supabase 백엔드 사용 (DB, Auth, RLS 그대로)
4. **점진적 구현**: Feature 단위로 순차적 구현

### 1.3 기술 스택

| 항목 | 기술 | 비고 |
|------|------|------|
| Framework | Next.js 15 (App Router) | React 19, Server Components |
| Styling | Tailwind CSS v4 | 디자인 토큰 연동 |
| Backend | Supabase (기존) | PostgreSQL, Auth, RLS, Realtime |
| 상태관리 | Zustand 또는 TanStack Query | 서버 상태 + 클라이언트 상태 |
| 차트 | Recharts 또는 Nivo | 통계 강화 대응 |
| 테스트 | Vitest + Testing Library + Playwright | 단위/통합/E2E |
| 인증 | Supabase Auth (@supabase/ssr) | 기존 사용자 계정 공유 |
| 다국어 | next-intl | 한국어/영어 |
| 폼 관리 | React Hook Form + Zod | 유효성 검증 |

---

## 2. 현재 앱 기능 분석 (이관 대상)

### 2.1 Feature 목록 및 웹 이관 범위

| # | Feature | 모바일 기능 | 웹 이관 | 비고 |
|---|---------|-----------|---------|------|
| 1 | **auth** | 로그인, 회원가입, Google 로그인, 비밀번호 재설정 | O (전체) | Supabase Auth SSR |
| 2 | **ledger** | 가계부 메인 (일별/주별/캘린더 뷰), 거래 목록 | O (전체) | 데스크톱 최적화 레이아웃 |
| 3 | **transaction** | 수입/지출/자산 거래 CRUD | O (전체) | 모달 -> 사이드 패널 또는 모달 |
| 4 | **category** | 카테고리 관리 (수입/지출/자산) | O (전체) | 설정 내 관리 |
| 5 | **payment_method** | 결제수단 관리 | O (부분) | SMS 자동수집 제외 (모바일 전용) |
| 6 | **statistics** | 카테고리/추이/결제수단 통계 | O (강화) | 대시보드, 드릴다운, 내보내기 추가 |
| 7 | **asset** | 자산 관리 (정기예금, 주식 등) | O (전체) | 포트폴리오 뷰 강화 |
| 8 | **share** | 가계부 공유, 멤버 관리 | O (전체) | 초대/역할 관리 |
| 9 | **fixed_expense** | 고정비 관리 | O (전체) | - |
| 10 | **budget** | 예산 관리 | O (전체) | 시각화 강화 |
| 11 | **search** | 거래 검색/필터링 | O (전체) | 고급 필터 추가 |
| 12 | **notification** | 푸시 알림 설정 | O (부분) | 웹 Push 또는 이메일 알림 |
| 13 | **settings** | 사용자 설정 | O (전체) | 테마, 언어, 프로필 |
| 14 | **widget** | 홈 화면 위젯 | X (제외) | 모바일 전용 기능 |
| 15 | **랜딩페이지** | N/A (신규) | O (신규) | 서비스 소개, CTA |
| 16 | **이용약관/개인정보** | 마크다운 뷰어 | O (전체) | 기존 문서 활용 |

### 2.2 웹 제외 기능 (모바일 전용)

- SMS 자동수집 (another_telephony) - Android 전용 API
- 알림 리스너 (NotificationListenerService) - Android 전용
- 홈 화면 위젯 (home_widget) - 모바일 전용
- 딥링크 (app_links) - 모바일 전용

---

## 3. 웹 강화 기능 (통계/분석)

### 3.1 강화된 통계 대시보드

현재 앱의 3탭 구조를 넘어 종합 대시보드로 확장:

#### A. 메인 대시보드 (신규)
- 이번 달 총 수입/지출/자산 요약 카드
- 전월 대비 증감율
- 카테고리별 Top 5 지출
- 최근 거래 목록
- 예산 대비 실지출 게이지

#### B. 카테고리 분석 (강화)
- 기존: 도넛 차트 + 목록
- 추가: 카테고리 클릭 시 드릴다운 (해당 거래 목록)
- 추가: 다중 카테고리 비교
- 추가: 고정비 vs 변동비 비율 추이

#### C. 추이 분석 (강화)
- 기존: 월별/연별 막대 차트
- 추가: 커스텀 날짜 범위 선택
- 추가: 분기별 비교
- 추가: 트렌드 라인 (이동 평균)
- 추가: 전년 동기 비교

#### D. 결제수단 분석 (강화)
- 기존: 도넛 차트
- 추가: 결제수단별 월간 추이
- 추가: 결제수단별 카테고리 교차 분석

#### E. 공유 가계부 분석 (강화)
- 기존: 사용자별 도넛 차트
- 추가: 멤버별 기여도 타임라인
- 추가: 정산 분석 (누가 얼마나 더 지출)
- 추가: 멤버별 카테고리 비교

#### F. 데이터 내보내기 (신규)
- CSV 다운로드
- Excel 다운로드
- PDF 리포트 생성

---

## 4. 프로젝트 구조

### 4.1 디렉토리 구조

```
web/
├── src/
│   ├── app/                      # Next.js App Router
│   │   ├── (auth)/               # 인증 관련 라우트 그룹
│   │   │   ├── login/
│   │   │   ├── signup/
│   │   │   └── forgot-password/
│   │   ├── (main)/               # 인증 후 메인 라우트 그룹
│   │   │   ├── dashboard/        # 대시보드 (메인)
│   │   │   ├── ledger/           # 가계부
│   │   │   ├── statistics/       # 통계
│   │   │   ├── asset/            # 자산
│   │   │   ├── budget/           # 예산
│   │   │   ├── share/            # 공유
│   │   │   ├── search/           # 검색
│   │   │   └── settings/         # 설정
│   │   ├── (landing)/            # 랜딩 페이지
│   │   │   ├── page.tsx          # 메인 랜딩
│   │   │   ├── terms/            # 이용약관
│   │   │   └── privacy/          # 개인정보처리방침
│   │   ├── layout.tsx
│   │   ├── page.tsx              # 루트 (랜딩으로 리다이렉트)
│   │   └── globals.css
│   ├── components/               # 재사용 UI 컴포넌트
│   │   ├── ui/                   # 기본 UI (Button, Input, Card 등)
│   │   ├── charts/               # 차트 컴포넌트
│   │   ├── layout/               # 레이아웃 (Sidebar, Header 등)
│   │   └── forms/                # 폼 컴포넌트
│   ├── features/                 # Feature별 컴포넌트/훅
│   │   ├── auth/
│   │   ├── ledger/
│   │   ├── transaction/
│   │   ├── category/
│   │   ├── statistics/
│   │   ├── asset/
│   │   ├── budget/
│   │   ├── share/
│   │   ├── search/
│   │   ├── payment-method/
│   │   ├── fixed-expense/
│   │   └── settings/
│   ├── lib/                      # 유틸리티 및 설정
│   │   ├── supabase/             # Supabase 클라이언트
│   │   │   ├── client.ts         # 브라우저 클라이언트
│   │   │   ├── server.ts         # 서버 클라이언트
│   │   │   └── middleware.ts     # 미들웨어
│   │   ├── utils/                # 유틸리티 함수
│   │   ├── hooks/                # 커스텀 훅
│   │   ├── types/                # TypeScript 타입 정의
│   │   └── constants/            # 상수
│   ├── stores/                   # Zustand 스토어
│   └── styles/                   # 스타일 관련
│       └── design-tokens.ts      # Tailwind 디자인 토큰
├── public/                       # 정적 파일
├── __tests__/                    # 테스트 디렉토리
│   ├── unit/                     # 단위 테스트
│   ├── integration/              # 통합 테스트
│   └── e2e/                      # E2E 테스트 (Playwright)
├── next.config.ts
├── tailwind.config.ts
├── tsconfig.json
├── vitest.config.ts
├── playwright.config.ts
├── package.json
└── .env.local
```

### 4.2 디자인 토큰 매핑 (Flutter -> Tailwind)

| Flutter Token | Tailwind 등가물 | 값 |
|---------------|-----------------|-----|
| Spacing.xs | gap-1 / p-1 | 4px |
| Spacing.sm | gap-2 / p-2 | 8px |
| Spacing.md | gap-4 / p-4 | 16px |
| Spacing.lg | gap-6 / p-6 | 24px |
| Spacing.xl | gap-8 / p-8 | 32px |
| Spacing.xxl | gap-12 / p-12 | 48px |
| BorderRadiusToken.md | rounded-xl | 12px |
| Primary (#2E7D32) | primary | 커스텀 |
| Expense (#BA1A1A) | expense | 커스텀 |
| Income (#2E7D32) | income | 커스텀 |
| Asset (#006A6A) | asset | 커스텀 |

---

## 5. 구현 순서 (Phase별)

### Phase 1: 프로젝트 초기 설정 및 테스트 인프라
**목표**: 개발 환경 구축, 테스트 시스템, CI 기반 마련

1. Next.js 프로젝트 생성 (`web/`)
2. Tailwind CSS 설정 + 디자인 토큰 적용
3. Supabase 클라이언트 설정 (@supabase/ssr)
4. Vitest + Testing Library 설정
5. Playwright 설정
6. ESLint + Prettier 설정
7. TypeScript 타입 정의 (Supabase 스키마 기반)

**디자인 작업**: 없음 (인프라)

### Phase 2: 랜딩 페이지 + 법적 문서
**목표**: 서비스 소개 페이지 및 법적 문서

1. **Pencil 디자인**: 랜딩 페이지 디자인 (house.pen에 추가)
2. **Pencil 디자인**: 이용약관/개인정보처리방침 페이지 디자인
3. 랜딩 페이지 구현 (Hero, Features, CTA, Footer)
4. 이용약관 페이지 구현 (기존 `docs/terms_of_service.md` 활용)
5. 개인정보처리방침 페이지 구현 (기존 `docs/privacy_policy.md` 활용)
6. 반응형 디자인 (모바일/태블릿/데스크톱)
7. SEO 메타 태그

**TDD**: 랜딩 페이지 렌더링 테스트, 링크 연결 테스트

### Phase 3: 인증 시스템
**목표**: 로그인/회원가입 + 세션 관리

1. **Pencil 디자인**: 로그인/회원가입 페이지 디자인
2. Supabase Auth 미들웨어 구현
3. 로그인 페이지 (이메일 + Google OAuth)
4. 회원가입 페이지
5. 비밀번호 재설정 페이지
6. 이메일 인증 처리
7. 인증 상태 관리 (Protected Routes)

**TDD**: 인증 훅 테스트, 폼 유효성 테스트, 미들웨어 테스트

### Phase 4: 공통 레이아웃 및 UI 컴포넌트
**목표**: 앱 셸 + 재사용 컴포넌트 라이브러리

1. **Pencil 디자인**: 메인 레이아웃 (Sidebar + Header + Content)
2. **Pencil 디자인**: 기본 UI 컴포넌트 (Button, Input, Card, Dialog, Toast)
3. Sidebar 네비게이션
4. Header (사용자 프로필, 가계부 전환)
5. 기본 UI 컴포넌트 구현
6. 테마 시스템 (라이트/다크 모드)
7. 반응형 레이아웃 (모바일 시 하단 네비게이션)

**TDD**: 컴포넌트 단위 테스트, 접근성 테스트

### Phase 5: 가계부 메인 (Ledger)
**목표**: 핵심 거래 관리 기능

1. **Pencil 디자인**: 가계부 메인 페이지 (일별/주별/캘린더 뷰)
2. **Pencil 디자인**: 거래 추가/수정 모달
3. 가계부 목록 및 전환
4. 캘린더 뷰 구현
5. 일별 뷰 구현
6. 주별 뷰 구현
7. 거래 추가/수정/삭제 (CRUD)
8. 월간 수입/지출/자산 요약

**TDD**: Repository 테스트, 거래 CRUD 테스트, 뷰 전환 테스트

### Phase 6: 카테고리 + 결제수단 + 고정비
**목표**: 거래 관련 설정 기능

1. **Pencil 디자인**: 카테고리 관리 페이지
2. **Pencil 디자인**: 결제수단 관리 페이지
3. **Pencil 디자인**: 고정비 관리 페이지
4. 카테고리 CRUD
5. 결제수단 CRUD (SMS 자동수집 제외)
6. 고정비 관리

**TDD**: 각 CRUD 기능별 테스트

### Phase 7: 통계 대시보드 (강화)
**목표**: 기존 통계 + 강화된 분석 기능

1. **Pencil 디자인**: 메인 대시보드
2. **Pencil 디자인**: 카테고리 분석 (드릴다운 포함)
3. **Pencil 디자인**: 추이 분석 (커스텀 기간)
4. **Pencil 디자인**: 결제수단 분석
5. **Pencil 디자인**: 공유 가계부 분석
6. 메인 대시보드 위젯 구현
7. 카테고리 도넛 차트 + 드릴다운
8. 추이 막대/라인 차트 + 커스텀 기간
9. 결제수단 분석 차트
10. 공유 멤버별 분석
11. 전월/전년 비교 기능
12. CSV/Excel/PDF 데이터 내보내기

**TDD**: 차트 데이터 변환 테스트, 필터링 테스트, 내보내기 테스트

### Phase 8: 자산 관리
**목표**: 자산 포트폴리오 관리

1. **Pencil 디자인**: 자산 관리 페이지 (포트폴리오 뷰)
2. 자산 CRUD
3. 자산 목표 관리
4. 자산 배분 차트
5. 자산 추이 라인 차트

**TDD**: 자산 계산 로직 테스트, 차트 데이터 테스트

### Phase 9: 공유 + 검색 + 예산
**목표**: 나머지 핵심 기능

1. **Pencil 디자인**: 공유 관리 페이지
2. **Pencil 디자인**: 검색 페이지
3. **Pencil 디자인**: 예산 관리 페이지
4. 가계부 공유/초대/멤버 관리
5. 거래 검색 (고급 필터)
6. 예산 설정 및 실지출 비교

**TDD**: 공유 권한 테스트, 검색 필터 테스트, 예산 계산 테스트

### Phase 10: 설정 + 알림 + 마무리
**목표**: 설정 및 부가 기능

1. **Pencil 디자인**: 설정 페이지
2. 사용자 프로필 설정
3. 테마/언어 설정
4. 알림 설정 (웹 Push 또는 설정 UI)
5. E2E 테스트 (Playwright)
6. 성능 최적화
7. 접근성 검증

**TDD**: 설정 변경 테스트, E2E 시나리오

---

## 6. Supabase 연동 전략

### 6.1 기존 인프라 활용

웹과 모바일이 **동일한 Supabase 프로젝트**를 사용한다:

- 동일 DB 테이블 (transactions, categories, ledgers 등)
- 동일 RLS 정책 (Row Level Security)
- 동일 Auth 사용자 (이메일/Google)
- 동일 RPC 함수

### 6.2 웹 전용 설정

```typescript
// @supabase/ssr 사용
// Server Component: createServerClient
// Client Component: createBrowserClient
// Middleware: 세션 갱신
```

### 6.3 타입 안전성

```bash
# Supabase CLI로 TypeScript 타입 자동 생성
npx supabase gen types typescript --project-id <project-id> > src/lib/types/database.ts
```

---

## 7. 테스트 전략 (TDD)

### 7.1 테스트 피라미드

```
          E2E (Playwright)
         /                \
        /  통합 테스트      \
       /  (Testing Library) \
      /                      \
     /    단위 테스트 (Vitest) \
    /____________________________\
```

### 7.2 테스트 종류별 범위

| 종류 | 도구 | 대상 | 비율 |
|------|------|------|------|
| 단위 테스트 | Vitest | 유틸리티, 훅, 스토어, 데이터 변환 | 60% |
| 통합 테스트 | Vitest + Testing Library | 컴포넌트 렌더링, 사용자 상호작용 | 30% |
| E2E 테스트 | Playwright | 핵심 사용자 플로우 | 10% |

### 7.3 TDD 워크플로우

```
1. 실패하는 테스트 작성 (Red)
2. 최소한의 코드로 테스트 통과 (Green)
3. 리팩토링 (Refactor)
4. 반복
```

### 7.4 테스트 파일 구조

```
__tests__/
├── unit/
│   ├── lib/utils/              # 유틸리티 테스트
│   ├── lib/hooks/              # 커스텀 훅 테스트
│   ├── stores/                 # 스토어 테스트
│   └── features/               # Feature 로직 테스트
├── integration/
│   ├── components/             # 컴포넌트 통합 테스트
│   └── features/               # Feature UI 통합 테스트
└── e2e/
    ├── auth.spec.ts            # 인증 플로우
    ├── transaction.spec.ts     # 거래 CRUD 플로우
    ├── statistics.spec.ts      # 통계 확인 플로우
    └── share.spec.ts           # 공유 플로우
```

---

## 8. Pencil 디자인 전략 (house.pen)

### 8.1 디자인 영역 배치

house.pen 내 웹 디자인 영역:

| 영역 | x 좌표 | 내용 |
|------|--------|------|
| 기존 모바일 디자인 | 0 ~ 10000 | 현재 앱 디자인 |
| **웹 랜딩 페이지** | **12000** | 랜딩, 이용약관, 개인정보 |
| **웹 인증** | **14000** | 로그인, 회원가입 |
| **웹 레이아웃** | **15000** | Sidebar, Header, 레이아웃 |
| **웹 가계부** | **16000** | 메인, 캘린더, 거래 모달 |
| **웹 통계** | **18000** | 대시보드, 차트, 분석 |
| **웹 자산** | **20000** | 자산 관리 |
| **웹 설정** | **21000** | 설정, 공유, 검색 |
| **웹 컴포넌트** | **22000** | 재사용 UI 컴포넌트 |

### 8.2 디자인 원칙

1. **앱과 일관된 브랜딩**: 동일한 Primary 색상 (#2E7D32), 디자인 토큰
2. **데스크톱 최적화**: Sidebar 네비게이션, 넓은 콘텐츠 영역
3. **반응형**: 1440px(데스크톱), 1024px(태블릿), 768px(모바일)
4. **라이트/다크 모드**: 모바일과 동일한 테마 시스템

---

## 9. 랜딩 페이지 구성

### 9.1 섹션 구성

1. **Hero**: 서비스 타이틀 + 간단한 소개 + CTA(시작하기/로그인) + 앱 스크린샷
2. **Features**: 핵심 기능 소개 (아이콘 + 설명)
   - 가계부 관리 (수입/지출/자산)
   - 가계부 공유 (가족/커플/룸메이트)
   - 통계 분석 (차트/추이/비교)
   - 자산 관리 (포트폴리오)
   - 예산 관리
   - 모바일 앱 연동
3. **Statistics Preview**: 통계 기능 미리보기 (스크린샷/목업)
4. **Mobile App**: 모바일 앱 다운로드 안내
5. **Footer**: 이용약관, 개인정보처리방침, 문의

### 9.2 법적 문서

- 기존 `docs/terms_of_service.md` 내용을 마크다운 렌더링
- 기존 `docs/privacy_policy.md` 내용을 마크다운 렌더링
- 모바일 앱과 동일한 내용 유지

---

## 10. 비기능 요구사항

### 10.1 성능

- Lighthouse 점수 90+ (Performance, Accessibility, Best Practices, SEO)
- First Contentful Paint < 1.5s
- Largest Contentful Paint < 2.5s
- 페이지 번들 사이즈 최적화 (코드 스플리팅)

### 10.2 접근성 (a11y)

- WCAG 2.1 AA 준수
- 키보드 네비게이션 지원
- 스크린 리더 호환
- 충분한 색상 대비 (4.5:1 이상)

### 10.3 보안

- HTTPS 전용
- CSP (Content Security Policy) 설정
- XSS 방지 (React 기본 이스케이핑)
- CSRF 보호 (Supabase Auth)
- 환경 변수 보호 (.env.local)

### 10.4 SEO

- 동적 메타 태그 (next/metadata)
- Open Graph / Twitter Card
- sitemap.xml / robots.txt
- 시맨틱 HTML

---

## 11. 리스크 및 대응

| 리스크 | 영향 | 대응 |
|--------|------|------|
| Supabase RLS 정책 불일치 | 보안 | 기존 RLS 정책 변경 없이 활용, 웹 전용 필요 시 추가만 |
| 차트 라이브러리 성능 | UX | 대량 데이터 시 서버 사이드 집계 RPC 함수 추가 |
| 모바일/웹 동시 수정 | 데이터 일관성 | Supabase Realtime 활용 |
| 다국어 동기화 | 유지보수 | 번역 키를 JSON으로 관리하여 앱과 공유 |
| 테스트 커버리지 부족 | 품질 | TDD 방식으로 최소 80% 커버리지 유지 |

---

## 12. 성공 기준

- [ ] 모바일 앱의 핵심 기능 100% 웹 이관 (SMS 자동수집, 위젯 제외)
- [ ] 강화된 통계 대시보드 구현 (6가지 이상 차트 타입)
- [ ] 데이터 내보내기 기능 (CSV, Excel, PDF)
- [ ] Lighthouse 점수 90+ (모든 카테고리)
- [ ] 테스트 커버리지 80% 이상
- [ ] 반응형 디자인 (모바일/태블릿/데스크톱)
- [ ] 라이트/다크 모드 지원
- [ ] 한국어/영어 다국어 지원
- [ ] 랜딩 페이지 + 법적 문서 완비
- [ ] house.pen에 모든 웹 페이지 디자인 완료

---

## 13. 예상 산출물

| 산출물 | 형식 | 위치 |
|--------|------|------|
| 웹 디자인 | .pen (Pencil) | house.pen (x:12000+) |
| 웹 소스코드 | Next.js + TypeScript | web/ |
| 테스트 코드 | Vitest + Playwright | web/__tests__/ |
| 디자인 문서 | Markdown | docs/02-design/features/web-version.design.md |
| API 타입 | TypeScript | web/src/lib/types/database.ts |
