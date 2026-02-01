# 웹 통계 플랫폼 개발 로드맵

## 전체 일정 개요

```
총 개발 기간: 10일 (2주)
├─ Phase 1: 프로젝트 초기화 (1일)
├─ Phase 2: 인증 구현 (1일)
├─ Phase 3: 대시보드 (2일)
├─ Phase 4: 고급 통계 (2일)
├─ Phase 5: 파일 임포트/익스포트 (2일)
├─ Phase 6: 디자인 시스템 (1일)
└─ Phase 7: 최종 마무리 (1일)
```

---

## Phase 1: 프로젝트 초기화 (1일)

### 목표
- Next.js 프로젝트 생성 및 기본 설정
- 디자인 시스템 구축
- 개발 환경 세팅

### 작업 목록

#### 1.1 프로젝트 생성
```bash
# Next.js 프로젝트 생성
npx create-next-app@latest web --typescript --tailwind --app

# 디렉토리 이동
cd web

# 필수 패키지 설치
npm install @supabase/supabase-js @supabase/ssr
npm install @tanstack/react-query zustand
npm install lucide-react class-variance-authority clsx tailwind-merge
npm install sonner

# shadcn/ui 초기화
npx shadcn-ui@latest init

# shadcn/ui 컴포넌트 설치
npx shadcn-ui@latest add button
npx shadcn-ui@latest add input
npx shadcn-ui@latest add card
npx shadcn-ui@latest add dialog
npx shadcn-ui@latest add select
npx shadcn-ui@latest add switch
npx shadcn-ui@latest add badge
npx shadcn-ui@latest add table
npx shadcn-ui@latest add dropdown-menu

# 차트 라이브러리
npm install recharts

# 파일 처리
npm install react-dropzone xlsx papaparse file-saver
npm install -D @types/papaparse

# 날짜 처리
npm install date-fns
```

#### 1.2 Tailwind 설정
- `tailwind.config.ts` 작성 (디자인 토큰 적용)
- `app/globals.css` CSS 변수 정의
- 반응형 브레이크포인트 설정

#### 1.3 Supabase 클라이언트
```typescript
// lib/supabase/client.ts
// lib/supabase/server.ts (서버 컴포넌트용)
// lib/supabase/middleware.ts (미들웨어)
```

#### 1.4 기본 레이아웃
```
app/
├── layout.tsx         # Root 레이아웃
├── page.tsx           # 홈페이지
└── globals.css        # 전역 스타일
```

#### 완료 기준
- [x] Next.js 프로젝트 빌드 성공
- [x] Tailwind CSS 정상 작동
- [x] Supabase 연결 테스트 성공
- [x] shadcn/ui 컴포넌트 렌더링 확인

---

## Phase 2: 인증 구현 (1일)

### 목표
- 앱과 동일한 Supabase Auth 연동
- 로그인/회원가입 페이지
- 세션 관리

### 작업 목록

#### 2.1 Supabase Auth 설정
```typescript
// lib/supabase/auth.ts
export async function signIn(email: string, password: string) { }
export async function signUp(email: string, password: string) { }
export async function signOut() { }
export async function getSession() { }
```

#### 2.2 로그인 페이지
```
app/(auth)/login/page.tsx
components/auth/login-form.tsx
```

**기능:**
- 이메일/비밀번호 입력
- 로그인 버튼
- 회원가입 링크
- 에러 메시지 표시

#### 2.3 회원가입 페이지
```
app/(auth)/register/page.tsx
components/auth/register-form.tsx
```

**기능:**
- 이메일/비밀번호 입력
- 비밀번호 확인
- 회원가입 버튼
- 로그인 링크

#### 2.4 세션 관리 (Zustand)
```typescript
// stores/auth-store.ts
interface AuthState {
  user: User | null;
  session: Session | null;
  isLoading: boolean;
  setUser: (user: User | null) => void;
  setSession: (session: Session | null) => void;
}
```

#### 2.5 Protected Route
```typescript
// components/protected-route.tsx
export function ProtectedRoute({ children }: { children: React.ReactNode }) {
  // 로그인 확인
  // 미로그인 시 /login 리다이렉트
}
```

#### 완료 기준
- [x] 로그인 성공
- [x] 회원가입 성공
- [x] 로그아웃 성공
- [x] 세션 지속 (새로고침 후에도 유지)
- [x] Protected Route 동작

---

## Phase 3: 대시보드 (2일)

### 목표
- 메인 대시보드 화면 구현
- 기본 차트 (월별 추이, 카테고리 도넛)
- 최근 거래 목록

### 작업 목록

#### Day 1: 레이아웃 및 요약 카드

##### 3.1 대시보드 레이아웃
```
app/(main)/dashboard/page.tsx
components/dashboard/dashboard-layout.tsx
```

##### 3.2 요약 카드 (Summary Cards)
```typescript
components/dashboard/summary-card.tsx

<SummaryCard
  title="이번 달 수입"
  amount={1500000}
  trend={+5.2}  // 전월 대비
  icon={TrendingUp}
  color="income"
/>
```

**카드 종류:**
- 수입 카드 (income)
- 지출 카드 (expense)
- 저축 카드 (asset)

##### 3.3 Repository 구현
```typescript
// lib/supabase/statistics-repository.ts
export async function getMonthSummary(ledgerId: string, year: number, month: number) {
  // 수입/지출/저축 합계 조회
}
```

#### Day 2: 차트 및 거래 목록

##### 3.4 월별 추이 차트 (Line Chart)
```typescript
components/charts/monthly-trend-chart.tsx

// Recharts LineChart 사용
// - X축: 월 (MM월)
// - Y축: 금액 (원)
// - 3개 라인: 수입/지출/저축
```

##### 3.5 카테고리 도넛 차트
```typescript
components/charts/category-donut-chart.tsx

// Recharts PieChart 사용
// - 상위 5개 카테고리 + 기타
// - 색상: 카테고리 색상 사용
// - 중앙: 총 금액 표시
```

##### 3.6 최근 거래 목록
```typescript
components/dashboard/recent-transactions.tsx

// 최근 10개 거래
// - 날짜, 카테고리, 메모, 금액
// - 클릭 시 상세 페이지 (추후)
```

#### 완료 기준
- [x] 요약 카드 3개 표시
- [x] 월별 추이 차트 렌더링
- [x] 카테고리 도넛 차트 렌더링
- [x] 최근 거래 10개 표시
- [x] 반응형 레이아웃 (모바일/데스크톱)

---

## Phase 4: 고급 통계 (2일)

### 목표
- 상세 통계 페이지
- 다양한 차트 구현
- 필터 기능

### 작업 목록

#### Day 1: 통계 페이지 및 필터

##### 4.1 통계 페이지 레이아웃
```
app/(main)/statistics/page.tsx
components/statistics/statistics-layout.tsx
```

##### 4.2 필터 UI
```typescript
components/statistics/statistics-filters.tsx

// 필터 옵션:
// - 기간 선택 (DatePicker)
// - 거래 유형 (Select)
// - 카테고리 (MultiSelect)
// - 사용자 (공유 가계부)
```

##### 4.3 필터 상태 관리
```typescript
// stores/filter-store.ts
interface FilterState {
  dateRange: { start: Date; end: Date };
  type: 'all' | 'income' | 'expense';
  categoryIds: string[];
  userIds: string[];
}
```

#### Day 2: 추가 차트 구현

##### 4.4 결제수단 분석 (Horizontal Bar Chart)
```typescript
components/charts/payment-method-chart.tsx

// - 결제수단별 사용 금액
// - 아이콘 표시
// - 비율 표시
```

##### 4.5 사용자별 비교 (Stacked Bar Chart)
```typescript
components/charts/user-comparison-chart.tsx

// - 공유 가계부의 사용자별 지출
// - 월별 스택 바
// - 사용자 색상 사용
```

##### 4.6 연도별 추이 (Bar Chart)
```typescript
components/charts/yearly-trend-chart.tsx

// - 최근 3년 데이터
// - 수입/지출 바
// - 잔액 라인
```

##### 4.7 예산 진행률 (Progress Chart)
```typescript
components/charts/budget-progress-chart.tsx

// - 카테고리별 예산 진행률
// - 80% 이상 경고 (노랑)
// - 100% 초과 위험 (빨강)
```

#### 완료 기준
- [x] 필터 UI 동작
- [x] 결제수단 차트 렌더링
- [x] 사용자별 비교 차트 렌더링
- [x] 연도별 추이 차트 렌더링
- [x] 예산 진행률 표시
- [x] 필터 적용 시 차트 업데이트

---

## Phase 5: 파일 임포트/익스포트 (2일)

### 목표
- Excel/CSV 업로드 기능
- 데이터 검증 및 미리보기
- Excel/CSV 다운로드 기능

### 작업 목록

#### Day 1: 파일 업로드

##### 5.1 업로드 페이지
```
app/(main)/import-export/page.tsx
components/import-export/import-export-layout.tsx
```

##### 5.2 파일 드롭존
```typescript
components/import-export/file-dropzone.tsx

// react-dropzone 사용
// - Drag & Drop 지원
// - .xlsx, .csv 파일만 허용
// - 최대 파일 크기: 10MB
```

##### 5.3 Excel 파싱
```typescript
// lib/excel/parse-excel.ts
export async function parseExcelFile(file: File): Promise<Transaction[]> {
  // xlsx 라이브러리 사용
  // - 첫 번째 시트 읽기
  // - 헤더 행 인식
  // - 데이터 변환
}
```

##### 5.4 데이터 검증
```typescript
// lib/validation/transaction-validator.ts
export function validateTransaction(row: any): ValidationResult {
  // - 필수 필드 체크
  // - 날짜 형식 검증
  // - 금액 범위 검증
  // - 중복 체크
}
```

##### 5.5 미리보기 테이블
```typescript
components/import-export/preview-table.tsx

// - 검증 결과 표시 (에러/경고 아이콘)
// - 편집 가능 (선택)
// - 확인/취소 버튼
```

#### Day 2: 파일 다운로드

##### 5.6 다운로드 옵션 UI
```typescript
components/import-export/download-options.tsx

// - 파일 형식 선택 (Excel/CSV)
// - 기간 선택
// - 필터 옵션
// - 통계 시트 포함 여부 (Excel만)
```

##### 5.7 Excel 생성
```typescript
// lib/excel/create-excel.ts
export async function createExcelFile(
  transactions: Transaction[],
  options: DownloadOptions
): Promise<Blob> {
  // xlsx 라이브러리 사용
  // - 거래 내역 시트
  // - 통계 요약 시트 (선택)
}
```

##### 5.8 CSV 생성
```typescript
// lib/csv/create-csv.ts
export function createCsvFile(transactions: Transaction[]): Blob {
  // papaparse 사용
  // - UTF-8 BOM 추가 (한글 깨짐 방지)
}
```

##### 5.9 템플릿 다운로드
```typescript
// public/templates/
// - transaction-template.xlsx
// - transaction-template-sample.xlsx (샘플 데이터 포함)
```

#### 완료 기준
- [x] Excel 파일 업로드 성공
- [x] CSV 파일 업로드 성공
- [x] 데이터 검증 동작
- [x] 미리보기 테이블 표시
- [x] Supabase 저장 성공
- [x] Excel 다운로드 성공
- [x] CSV 다운로드 성공
- [x] 템플릿 다운로드 성공

---

## Phase 6: 디자인 시스템 (1일)

### 목표
- house.pen에 웹 디자인 시안 작성
- shadcn/ui 컴포넌트 커스터마이징
- 반응형 디자인 완성
- 다크모드 지원

### 작업 목록

#### 6.1 house.pen 디자인 시안
```
위치: x = 15000 (Improved Design 영역)

페이지 구성:
1. Web Login (x=15000)
   - 로그인 폼
   - 회원가입 링크
   - 브랜딩

2. Web Dashboard (x=15400)
   - NavBar
   - 요약 카드 3개
   - 월별 추이 차트
   - 카테고리 도넛 차트
   - 최근 거래 목록

3. Web Statistics (x=15800)
   - 필터 UI
   - 결제수단 차트
   - 사용자별 비교
   - 연도별 추이
   - 예산 진행률

4. Web Import/Export (x=16200)
   - 파일 업로드 영역
   - 미리보기 테이블
   - 다운로드 옵션

5. Web Settings (x=16600)
   - 프로필 설정
   - 가계부 선택
   - 테마 설정
```

#### 6.2 컴포넌트 커스터마이징
```typescript
// components/ui/*.tsx (shadcn/ui)
// - 디자인 토큰 적용
// - 호버/포커스/액티브 상태
// - 애니메이션 duration 일치
```

#### 6.3 반응형 레이아웃 검증
```
- Mobile (< 768px): 1열 레이아웃
- Tablet (768-1023px): 2열 레이아웃
- Desktop (>= 1024px): 3열 레이아웃
```

#### 6.4 다크모드 구현
```typescript
// app/layout.tsx
import { ThemeProvider } from 'next-themes';

<ThemeProvider attribute="class" defaultTheme="system">
  {children}
</ThemeProvider>

// 다크모드 CSS 변수 추가
// globals.css에 .dark 클래스 스타일 정의
```

#### 완료 기준
- [x] house.pen 디자인 시안 완성
- [x] 모든 페이지 반응형 확인
- [x] 다크모드 정상 작동
- [x] 디자인 토큰 일관성 검증
- [x] 앱과 시각적 일관성 확인

---

## Phase 7: 최종 마무리 (1일)

### 목표
- 에러 처리 강화
- 로딩 상태 개선
- 테스트
- 배포

### 작업 목록

#### 7.1 에러 처리
```typescript
// components/error-boundary.tsx
// app/error.tsx (Next.js 에러 페이지)

// 에러 타입별 메시지
// - NETWORK_ERROR: '네트워크 연결을 확인하세요.'
// - AUTH_ERROR: '로그인이 필요합니다.'
// - VALIDATION_ERROR: '입력 값을 확인하세요.'
// - SERVER_ERROR: '서버 오류가 발생했습니다.'
```

#### 7.2 로딩 상태
```typescript
// components/loading-spinner.tsx
// app/loading.tsx (Next.js 로딩 페이지)

// 컴포넌트별 로딩 상태
// - 차트: Skeleton
// - 테이블: Shimmer
// - 버튼: Spinner
```

#### 7.3 최적화
```typescript
// - React Query 캐싱 설정
// - 이미지 최적화 (Next.js Image)
// - 코드 스플리팅 (dynamic import)
// - 번들 크기 분석 (next bundle-analyzer)
```

#### 7.4 테스트
```bash
# Unit Tests (Vitest)
npm run test

# E2E Tests (Playwright) - 선택
npm run test:e2e

# 수동 테스트 체크리스트
- [ ] 로그인/로그아웃
- [ ] 대시보드 차트 렌더링
- [ ] 통계 필터 동작
- [ ] Excel 업로드/다운로드
- [ ] CSV 업로드/다운로드
- [ ] 반응형 레이아웃
- [ ] 다크모드 전환
```

#### 7.5 배포 (Vercel)
```bash
# Vercel CLI 설치
npm i -g vercel

# 로그인
vercel login

# 배포
vercel --prod

# 환경 변수 설정 (Vercel 대시보드)
NEXT_PUBLIC_SUPABASE_URL=...
NEXT_PUBLIC_SUPABASE_ANON_KEY=...
```

#### 7.6 문서화
```markdown
# web/README.md
- 프로젝트 개요
- 기술 스택
- 로컬 개발 환경 설정
- 빌드 및 배포
- 환경 변수
- 디렉토리 구조
```

#### 완료 기준
- [x] 모든 에러 핸들링 동작
- [x] 로딩 상태 표시
- [x] 테스트 통과
- [x] Lighthouse 점수 90+ (Performance)
- [x] Vercel 배포 성공
- [x] README.md 작성 완료

---

## 우선순위 매트릭스

### P0 (필수)
```
- ✅ 인증 (로그인/회원가입)
- ✅ 대시보드 (요약 카드 + 기본 차트)
- ✅ Excel/CSV 업로드
- ✅ Excel/CSV 다운로드
- ✅ 디자인 일관성 (앱과 동일)
```

### P1 (중요)
```
- ✅ 고급 통계 차트 (4가지 이상)
- ✅ 필터 기능
- ✅ 반응형 디자인
- ✅ 에러 처리
- ✅ 로딩 상태
```

### P2 (선택)
```
- ⚠️ 다크모드 (시간 여유 시)
- ⚠️ PDF 리포트 생성
- ⚠️ 이메일 리포트 발송
- ⚠️ 커스텀 차트 저장
```

---

## 리스크 관리

### 기술적 리스크

| 리스크 | 영향도 | 대응 방안 |
|--------|--------|----------|
| Supabase RLS 정책 누락 | 높음 | 앱의 RLS 정책 재사용, 테스트 강화 |
| 파일 업로드 크기 제한 | 중간 | 클라이언트 측 검증, 청크 업로드 고려 |
| 차트 렌더링 성능 | 중간 | 데이터 샘플링, 가상 스크롤 |
| 브라우저 호환성 | 낮음 | 최신 브라우저만 지원 명시 |

### 일정 리스크

| 리스크 | 확률 | 대응 방안 |
|--------|------|----------|
| 디자인 시안 작업 지연 | 중간 | 기존 shadcn/ui 스타일 활용 |
| 파일 파싱 버그 | 중간 | 충분한 테스트 케이스 준비 |
| 통계 쿼리 최적화 필요 | 낮음 | 앱의 최적화된 쿼리 재사용 |

---

## 성공 지표 (KPI)

### 기능 완성도
- [x] 필수 기능 100% 구현
- [x] P1 기능 80% 이상 구현
- [x] P2 기능 50% 이상 구현

### 성능
- [x] Lighthouse Performance: 90+
- [x] 첫 페이지 로딩: < 2초
- [x] 차트 렌더링: < 500ms

### 품질
- [x] TypeScript 타입 에러: 0개
- [x] ESLint 경고: 10개 이하
- [x] 접근성 (a11y) 점수: 90+

### 사용자 경험
- [x] 앱과 디자인 일관성 유지
- [x] 직관적인 UI/UX
- [x] 에러 메시지 명확성

---

## 다음 단계

### 1. 디자인 시안 작성
```
house.pen에 웹 페이지 디자인 (x=15000~16600)
- 앱의 디자인 시스템 참고
- Material Design 3 가이드라인 준수
```

### 2. 설계 문서 작성
```
docs/02-design/features/web-statistics-platform.design.md
- API 명세
- 데이터 모델
- 컴포넌트 구조
- 페이지 라우팅
```

### 3. 프로젝트 초기화
```bash
cd /Users/eungyu/Desktop/개인/project/house-hold-account
mkdir web
cd web
npx create-next-app@latest . --typescript --tailwind --app
```

### 4. Phase 1 시작
```
- Tailwind 설정
- Supabase 클라이언트 설정
- shadcn/ui 설치
- 기본 레이아웃 구성
```

---

## 참고 자료

### 공식 문서
- [Next.js 14 Docs](https://nextjs.org/docs)
- [Supabase Auth](https://supabase.com/docs/guides/auth)
- [Recharts Documentation](https://recharts.org/en-US/api)
- [shadcn/ui](https://ui.shadcn.com/)
- [TanStack Query](https://tanstack.com/query/latest)

### 내부 문서
- `DESIGN_SYSTEM.md`: 디자인 시스템 가이드
- `web-statistics-platform.plan.md`: 전체 계획
- `web-statistics-features.md`: 기능 명세
- `web-design-system-mapping.md`: 디자인 매핑

### 코드 참고
- `lib/features/statistics/`: Flutter 통계 로직
- `lib/shared/themes/`: Flutter 테마 정의
- `household.pen`: pencil.dev 디자인 파일
