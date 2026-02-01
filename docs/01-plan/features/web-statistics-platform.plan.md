# 웹 통계 플랫폼 개발 계획

## 1. 프로젝트 개요

### 목적
공유 가계부 앱의 통계 기능을 웹으로 확장하여 더 강화된 데이터 분석 및 시각화 기능을 제공합니다.

### 핵심 가치
- **데이터 임포트/익스포트**: Excel/CSV 파일 업로드 및 다운로드
- **고급 분석**: 앱보다 더 상세한 통계 차트 및 리포트
- **동일 사용자 계정**: 앱과 동일한 Supabase 인증 공유
- **일관된 디자인**: 앱의 디자인 시스템을 웹에 적용

---

## 2. 기술 스택

### Frontend
```
- Framework: Next.js 14+ (App Router)
- Language: TypeScript
- Styling: Tailwind CSS + shadcn/ui
- Charts: Recharts (또는 Chart.js)
- State: Zustand
- Data Fetching: TanStack Query
```

### Backend
```
- BaaS: Supabase (기존 프로젝트 공유)
  - PostgreSQL 데이터베이스
  - Authentication (동일 사용자)
  - Row Level Security
```

### 파일 처리
```
- Upload: react-dropzone
- Excel: xlsx (SheetJS)
- CSV: papaparse
- Download: file-saver
```

### Deployment
```
- Frontend: Vercel
- Backend: Supabase (이미 배포됨)
```

---

## 3. 프로젝트 구조

```
web/
├── app/                          # Next.js App Router
│   ├── (auth)/                  # 인증 관련 라우트
│   │   ├── login/
│   │   └── register/
│   ├── (main)/                  # 메인 앱 라우트
│   │   ├── dashboard/          # 대시보드
│   │   ├── statistics/         # 상세 통계
│   │   ├── import-export/      # 파일 업로드/다운로드
│   │   └── settings/           # 설정
│   ├── layout.tsx
│   └── page.tsx
│
├── components/                   # UI 컴포넌트
│   ├── ui/                      # shadcn/ui 기본 컴포넌트
│   ├── charts/                  # 차트 컴포넌트
│   ├── layout/                  # 레이아웃 컴포넌트
│   └── features/                # 기능별 컴포넌트
│
├── lib/                          # 유틸리티
│   ├── supabase/                # Supabase 클라이언트
│   ├── excel/                   # Excel 처리
│   ├── csv/                     # CSV 처리
│   └── utils.ts
│
├── hooks/                        # Custom hooks
│   ├── useAuth.ts
│   ├── useStatistics.ts
│   └── useFileUpload.ts
│
├── stores/                       # Zustand 스토어
│   └── auth-store.ts
│
├── types/                        # TypeScript 타입
│   └── index.ts
│
├── styles/                       # 스타일
│   └── design-tokens.css        # 디자인 토큰 (앱 기반)
│
├── public/                       # 정적 파일
│
├── .env.local                    # 환경 변수
├── package.json
├── tailwind.config.ts
├── tsconfig.json
└── next.config.js
```

---

## 4. 핵심 기능 명세

### 4.1 인증 (Authentication)

#### 로그인/회원가입
- Supabase Auth 사용 (앱과 동일)
- 이메일/비밀번호 인증
- Google 소셜 로그인 (선택)
- 세션 관리 (JWT)

#### 보안
- Row Level Security (RLS)
- HTTPS 필수
- CSRF 보호

---

### 4.2 대시보드

#### 메인 화면
```
1. 월별 요약
   - 수입/지출/자산 카드
   - 전월 대비 증감률
   - 최근 6개월 추이 차트

2. 카테고리별 지출 분석
   - 도넛 차트 (상위 5개 + 기타)
   - 사용자별 비교 (공유 가계부)
   - 테이블 뷰

3. 최근 거래 목록
   - 최근 10개 거래
   - 필터 및 검색
```

#### 차트 라이브러리 선택
- **Recharts** (권장):
  - React 네이티브
  - 커스터마이징 용이
  - TypeScript 지원

---

### 4.3 고급 통계 페이지

#### 차트 종류
```
1. 월별 추이 (Line Chart)
   - 수입/지출/저축 추세
   - 평균선 표시
   - 6개월/1년/전체 선택

2. 카테고리 분석 (Pie/Donut Chart)
   - 지출 카테고리 비율
   - 고정비/변동비 구분
   - 사용자별 필터

3. 결제수단 분석 (Bar Chart)
   - 결제수단별 사용 금액
   - 비율 표시

4. 사용자별 비교 (Stacked Bar)
   - 공유 가계부의 사용자별 지출
   - 월별 비교

5. 연도별 추이 (Bar Chart)
   - 연간 수입/지출 비교
   - 최근 3년 데이터

6. 예산 대비 지출 (Progress Chart)
   - 카테고리별 예산 진행률
   - 경고 표시 (예산 초과 시)
```

#### 필터 기능
- 기간 선택 (일/주/월/연)
- 거래 유형 (수입/지출/자산)
- 카테고리 선택
- 사용자 선택 (공유 가계부)
- 고정비/변동비 필터

---

### 4.4 파일 임포트/익스포트

#### Excel 업로드 (.xlsx)
```typescript
// 지원 형식
{
  "날짜": "2025-02-01",
  "유형": "지출",
  "카테고리": "식비",
  "금액": 15000,
  "메모": "점심",
  "결제수단": "신한카드"
}

// 처리 흐름
1. 파일 업로드 (react-dropzone)
2. 검증 (날짜, 금액 형식)
3. 미리보기 (테이블)
4. 사용자 확인 후 저장
5. 중복 체크 (날짜+금액+메모)
```

#### CSV 업로드
```
날짜,유형,카테고리,금액,메모,결제수단
2025-02-01,지출,식비,15000,점심,신한카드
```

#### Excel/CSV 다운로드
```typescript
// 다운로드 옵션
1. 전체 거래 내역
2. 선택한 기간
3. 필터링된 데이터
4. 통계 요약 시트 포함 (선택)

// 형식
- .xlsx (Excel)
- .csv (CSV)
```

#### 템플릿 제공
- 빈 템플릿 다운로드
- 샘플 데이터 포함 템플릿

---

### 4.5 디자인 시스템

#### Tailwind CSS 설정
```typescript
// tailwind.config.ts
export default {
  theme: {
    extend: {
      colors: {
        // Flutter colorScheme → Tailwind 변환
        primary: {
          DEFAULT: '#2E7D32',
          container: '#A8DAB5',
          onPrimary: '#FFFFFF',
          onContainer: '#00210B',
        },
        surface: {
          DEFAULT: '#FDFDF5',
          container: '#EFEEE6',
          containerHighest: '#E3E3DB',
          onSurface: '#1A1C19',
          onSurfaceVariant: '#44483E',
        },
        outline: {
          DEFAULT: '#74796D',
          variant: '#C4C8BB',
        },
        expense: '#BA1A1A',
        income: '#2E7D32',
        asset: '#006A6A',
        error: '#BA1A1A',
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
    },
  },
};
```

#### 컴포넌트 스타일 가이드
```
- Button: bg-primary text-onPrimary rounded-md h-[52px]
- Input: bg-surface-containerHighest rounded-md h-[52px]
- Card: bg-surface rounded-lg shadow-md p-md
- Dialog: bg-surface rounded-xl p-lg
```

---

### 4.6 설정 페이지

#### 사용자 설정
- 프로필 정보 수정
- 색상 테마 변경
- 비밀번호 변경

#### 가계부 설정
- 가계부 선택 (공유 가계부 목록)
- 기본 가계부 설정

---

## 5. 데이터베이스 스키마

### 기존 Supabase 테이블 활용
```sql
-- 이미 존재하는 테이블 사용
- profiles (사용자)
- ledgers (가계부)
- ledger_members (멤버)
- transactions (거래)
- categories (카테고리)
- payment_methods (결제수단)
- budgets (예산)
```

### 웹 전용 테이블 (선택)
```sql
-- 파일 업로드 히스토리 (선택)
CREATE TABLE file_upload_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users NOT NULL,
  ledger_id UUID REFERENCES ledgers NOT NULL,
  file_name TEXT NOT NULL,
  file_type TEXT NOT NULL, -- 'excel' or 'csv'
  row_count INT NOT NULL,
  uploaded_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS 정책
ALTER TABLE file_upload_history ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own upload history"
  ON file_upload_history FOR SELECT
  USING (auth.uid() = user_id);
```

---

## 6. API 설계

### Supabase 클라이언트
```typescript
// lib/supabase/client.ts
import { createClient } from '@supabase/supabase-js';

export const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
);
```

### 통계 API (Repository 패턴)
```typescript
// lib/supabase/statistics-repository.ts
export async function getCategoryStatistics(params: {
  ledgerId: string;
  year: number;
  month: number;
  type: 'income' | 'expense';
}) {
  // Supabase 쿼리 (앱 로직과 동일)
}

export async function getMonthlyTrend(params: {
  ledgerId: string;
  months: number;
}) {
  // 월별 추이 데이터
}
```

---

## 7. 개발 단계

### Phase 1: 프로젝트 초기화 (1일)
- [x] Next.js 프로젝트 생성
- [ ] Tailwind + shadcn/ui 설치
- [ ] Supabase 클라이언트 설정
- [ ] 디자인 토큰 CSS 작성
- [ ] 기본 레이아웃 구성

### Phase 2: 인증 구현 (1일)
- [ ] Supabase Auth 연동
- [ ] 로그인/회원가입 페이지
- [ ] 세션 관리 (Zustand)
- [ ] Protected Route

### Phase 3: 대시보드 (2일)
- [ ] 월별 요약 카드
- [ ] 카테고리 도넛 차트
- [ ] 월별 추이 라인 차트
- [ ] 최근 거래 목록

### Phase 4: 고급 통계 (2일)
- [ ] 연도별 추이
- [ ] 결제수단 분석
- [ ] 사용자별 비교
- [ ] 예산 진행률
- [ ] 필터 기능

### Phase 5: 파일 임포트/익스포트 (2일)
- [ ] Excel/CSV 업로드
- [ ] 데이터 검증 및 미리보기
- [ ] Supabase 저장
- [ ] Excel/CSV 다운로드
- [ ] 템플릿 제공

### Phase 6: 디자인 시스템 (1일)
- [ ] house.pen에 웹 디자인 시안 작성
- [ ] shadcn/ui 컴포넌트 커스터마이징
- [ ] 다크모드 지원
- [ ] 반응형 디자인

### Phase 7: 설정 및 마무리 (1일)
- [ ] 설정 페이지
- [ ] 에러 핸들링
- [ ] 로딩 상태
- [ ] 테스트
- [ ] 배포 (Vercel)

---

## 8. 환경 변수

### .env.local
```bash
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
```

---

## 9. 추가 고려 사항

### 성능 최적화
- 서버 컴포넌트 활용 (Next.js 14+)
- 이미지 최적화 (Next.js Image)
- 코드 스플리팅
- React Query 캐싱

### 보안
- RLS 정책 검증
- XSS 방지
- CSRF 토큰
- 파일 업로드 검증 (크기, 형식)

### 접근성
- ARIA 라벨
- 키보드 네비게이션
- 색상 대비 (WCAG AA)

### 테스트
- Unit: Vitest
- Integration: React Testing Library
- E2E: Playwright (선택)

---

## 10. 디자인 시안 (house.pen)

### 작업 위치
- x 좌표: **15000** (Improved Design 영역)
- 페이지 구성:
  1. Web Login (15000)
  2. Web Dashboard (15400)
  3. Web Statistics (15800)
  4. Web Import/Export (16200)
  5. Web Settings (16600)

### 디자인 시스템 체크리스트
- [ ] 색상 팔레트 (앱과 동일)
- [ ] 타이포그래피
- [ ] 버튼 스타일
- [ ] 입력 필드
- [ ] 카드 스타일
- [ ] 차트 스타일
- [ ] 다이얼로그
- [ ] 토스트/스낵바
- [ ] 반응형 레이아웃 (Desktop/Tablet/Mobile)

---

## 11. 성공 지표

### 기능 완성도
- [ ] 앱과 동일한 사용자 로그인 가능
- [ ] Excel/CSV 업로드/다운로드 기능 완료
- [ ] 최소 6가지 차트 구현
- [ ] 앱 디자인과 일관성 유지

### 성능
- [ ] Lighthouse 점수 90+ (Performance)
- [ ] 첫 페이지 로딩 < 2초
- [ ] 차트 렌더링 < 500ms

### 사용자 경험
- [ ] 반응형 디자인 (모바일/태블릿/데스크톱)
- [ ] 다크모드 지원
- [ ] 직관적인 UI/UX

---

## 12. 참고 자료

### 문서
- [Next.js 14 Docs](https://nextjs.org/docs)
- [Supabase Docs](https://supabase.com/docs)
- [Recharts Docs](https://recharts.org/)
- [shadcn/ui](https://ui.shadcn.com/)

### 기존 프로젝트 파일
- `DESIGN_SYSTEM.md`: 디자인 토큰 및 컴포넌트 스펙
- `lib/shared/themes/design_tokens.dart`: Flutter 디자인 토큰
- `lib/features/statistics/`: 통계 로직 참고
- `household.pen`: 디자인 시안

---

## 13. 다음 단계

1. **디자인 시안 작성**: house.pen에 웹 페이지 디자인
2. **설계 문서 작성**: `web-statistics-platform.design.md` 생성
3. **프로젝트 초기화**: Next.js 프로젝트 생성
4. **개발 시작**: Phase 1부터 순차 진행
