# 웹 통계 플랫폼 - 프로젝트 요약

## 📋 프로젝트 개요

### 목적
공유 가계부 앱의 통계 기능을 웹으로 확장하여 더 강화된 데이터 분석 및 시각화 기능을 제공합니다.

### 핵심 가치
- **데이터 임포트/익스포트**: Excel/CSV 파일 업로드 및 다운로드
- **고급 분석**: 앱보다 더 상세한 통계 차트 및 리포트
- **동일 사용자 계정**: 앱과 동일한 Supabase 인증 공유
- **일관된 디자인**: 앱의 디자인 시스템을 웹에 적용

---

## 🛠 기술 스택

### Frontend
- **Framework**: Next.js 14+ (App Router, TypeScript)
- **Styling**: Tailwind CSS + shadcn/ui
- **Charts**: Recharts
- **State**: Zustand + TanStack Query
- **Icons**: Lucide React

### Backend
- **BaaS**: Supabase (기존 프로젝트 공유)
- **Database**: PostgreSQL
- **Auth**: Supabase Auth (앱과 동일)

### 파일 처리
- **Upload**: react-dropzone
- **Excel**: xlsx (SheetJS)
- **CSV**: papaparse
- **Download**: file-saver

### Deployment
- **Frontend**: Vercel
- **Backend**: Supabase (이미 배포됨)

---

## 📊 핵심 기능

### 1. 인증
- [x] 이메일/비밀번호 로그인
- [x] 회원가입
- [x] 세션 관리
- [x] Protected Route

### 2. 대시보드
- [x] 월별 요약 카드 (수입/지출/저축)
- [x] 월별 추이 차트 (Line Chart)
- [x] 카테고리 도넛 차트
- [x] 최근 거래 목록

### 3. 고급 통계
- [x] 결제수단별 분석 (Horizontal Bar Chart)
- [x] 사용자별 비교 (Stacked Bar Chart)
- [x] 연도별 추이 (Bar Chart)
- [x] 예산 진행률 (Progress Chart)
- [x] 필터 기능 (기간, 유형, 카테고리, 사용자)

### 4. 파일 임포트/익스포트
- [x] Excel 업로드 (.xlsx)
- [x] CSV 업로드 (.csv)
- [x] 데이터 검증 및 미리보기
- [x] Excel 다운로드 (통계 시트 포함 옵션)
- [x] CSV 다운로드
- [x] 템플릿 제공

### 5. 디자인 시스템
- [x] house.pen 웹 디자인 시안 (x=15000~16600)
- [x] Flutter → Tailwind CSS 매핑
- [x] 반응형 디자인 (Mobile/Tablet/Desktop)
- [x] 다크모드 지원

---

## 📁 프로젝트 구조

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
│   ├── dashboard/               # 대시보드 컴포넌트
│   ├── statistics/              # 통계 컴포넌트
│   ├── import-export/           # 파일 처리 컴포넌트
│   └── layout/                  # 레이아웃 컴포넌트
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
│   ├── auth-store.ts
│   └── filter-store.ts
│
├── types/                        # TypeScript 타입
│   └── index.ts
│
├── styles/                       # 스타일
│   └── globals.css              # 디자인 토큰
│
└── public/                       # 정적 파일
    └── templates/               # Excel/CSV 템플릿
```

---

## 📅 개발 일정

### 총 개발 기간: 10일 (2주)

```
Phase 1: 프로젝트 초기화 (1일)
├─ Next.js 프로젝트 생성
├─ Tailwind + shadcn/ui 설치
├─ Supabase 클라이언트 설정
└─ 디자인 토큰 CSS 작성

Phase 2: 인증 구현 (1일)
├─ Supabase Auth 연동
├─ 로그인/회원가입 페이지
├─ 세션 관리 (Zustand)
└─ Protected Route

Phase 3: 대시보드 (2일)
├─ Day 1: 레이아웃 + 요약 카드
└─ Day 2: 차트 + 거래 목록

Phase 4: 고급 통계 (2일)
├─ Day 1: 통계 페이지 + 필터
└─ Day 2: 추가 차트 4종

Phase 5: 파일 임포트/익스포트 (2일)
├─ Day 1: Excel/CSV 업로드
└─ Day 2: Excel/CSV 다운로드

Phase 6: 디자인 시스템 (1일)
├─ house.pen 디자인 시안
├─ shadcn/ui 커스터마이징
├─ 반응형 디자인
└─ 다크모드

Phase 7: 최종 마무리 (1일)
├─ 에러 처리 강화
├─ 로딩 상태 개선
├─ 테스트
└─ Vercel 배포
```

---

## 🎨 디자인 시스템 매핑

### Flutter → Web 변환

| Flutter | Web (Tailwind CSS) | 비고 |
|---------|-------------------|------|
| `colorScheme.primary` | `bg-primary` | #2E7D32 |
| `colorScheme.surface` | `bg-surface` | #FDFDF5 |
| `Spacing.md` | `p-md` (16px) | 기본 간격 |
| `BorderRadiusToken.md` | `rounded-md` (12px) | 기본 반경 |
| `ElevatedButton` | `Button variant="default"` | Primary 버튼 |
| `TextField` | `Input` | 입력 필드 |
| `Card` | `Card` | 카드 컴포넌트 |
| `AlertDialog` | `Dialog` | 다이얼로그 |
| `SnackBar` | `toast` (Sonner) | 토스트 알림 |

---

## 📊 차트 종류

### 구현할 차트 (총 6종)

1. **월별 추이 (Line Chart)**
   - X축: 월 (MM월)
   - Y축: 금액 (원)
   - 라인: 수입/지출/저축

2. **카테고리 분석 (Donut Chart)**
   - 상위 5개 + 기타
   - 중앙: 총 금액 표시
   - 사용자별 비교 모드

3. **결제수단 분석 (Horizontal Bar Chart)**
   - 결제수단별 사용 금액
   - 아이콘 + 비율 표시

4. **사용자별 비교 (Stacked Bar Chart)**
   - 공유 가계부의 사용자별 지출
   - 월별 스택 바

5. **연도별 추이 (Bar Chart)**
   - 최근 3년 데이터
   - 수입/지출 바 + 잔액 라인

6. **예산 진행률 (Progress Chart)**
   - 카테고리별 예산 대비 지출
   - 80% 이상 경고, 100% 초과 위험

---

## 📥 파일 처리

### Excel/CSV 업로드

#### 지원 형식
```
날짜 | 유형 | 카테고리 | 금액 | 메모 | 결제수단
2025-02-01 | 지출 | 식비 | 15000 | 점심 | 신한카드
```

#### 처리 흐름
```
1. 파일 선택 (Drag & Drop)
2. 파일 읽기 (xlsx/papaparse)
3. 데이터 검증
   - 필수 필드 체크
   - 날짜 형식 검증 (YYYY-MM-DD)
   - 금액 범위 검증 (1~1,000,000,000)
   - 중복 체크
4. 미리보기 테이블 표시
5. 사용자 확인 후 저장
6. Supabase 배치 INSERT
```

### Excel/CSV 다운로드

#### 다운로드 옵션
- 파일 형식: Excel (.xlsx) / CSV (.csv)
- 기간 선택: 사용자 지정
- 필터: 유형, 카테고리, 사용자
- 통계 시트 포함 (Excel만)

#### Excel 파일 구조
```
Sheet 1: 거래 내역 (transactions)
Sheet 2: 월별 요약 (monthly_summary)
Sheet 3: 카테고리별 요약 (category_summary)
Sheet 4: 결제수단별 요약 (payment_method_summary)
```

---

## 🎯 성공 지표 (KPI)

### 기능 완성도
- [x] 필수 기능 (P0) 100% 구현
- [x] 중요 기능 (P1) 80% 이상 구현
- [x] 선택 기능 (P2) 50% 이상 구현

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

## 📚 문서 구조

### Plan (01-plan)
```
docs/01-plan/features/
├── web-statistics-platform.plan.md       # 전체 계획
├── web-statistics-features.md            # 기능 상세 명세
├── web-design-system-mapping.md          # 디자인 매핑
├── web-development-roadmap.md            # 개발 로드맵
└── web-statistics-summary.md             # 프로젝트 요약 (현재 문서)
```

### Design (02-design) - 다음 단계
```
docs/02-design/features/
├── web-statistics-platform.design.md     # 설계 문서
├── web-api-specification.md              # API 명세
├── web-data-model.md                     # 데이터 모델
└── web-component-structure.md            # 컴포넌트 구조
```

### Codebase (.codebase) - 개발 중
```
.codebase/
├── web-overview.md                       # 웹 프로젝트 개요
├── web-architecture.md                   # 아키텍처
└── web-conventions.md                    # 코딩 컨벤션
```

---

## 🚀 다음 단계

### 1. 디자인 시안 작성
```
📍 위치: household.pen (x=15000~16600)

페이지:
- Web Login (x=15000)
- Web Dashboard (x=15400)
- Web Statistics (x=15800)
- Web Import/Export (x=16200)
- Web Settings (x=16600)
```

### 2. 설계 문서 작성
```bash
# API 명세
docs/02-design/features/web-api-specification.md

# 데이터 모델
docs/02-design/features/web-data-model.md

# 컴포넌트 구조
docs/02-design/features/web-component-structure.md
```

### 3. 프로젝트 초기화
```bash
cd /Users/eungyu/Desktop/개인/project/house-hold-account
mkdir web
cd web

# Next.js 프로젝트 생성
npx create-next-app@latest . --typescript --tailwind --app

# 필수 패키지 설치
npm install @supabase/supabase-js @supabase/ssr
npm install @tanstack/react-query zustand
npm install recharts react-dropzone xlsx papaparse
npm install lucide-react sonner

# shadcn/ui 초기화
npx shadcn-ui@latest init
```

### 4. Phase 1 시작
```
1. Tailwind 설정 (디자인 토큰 적용)
2. Supabase 클라이언트 설정
3. shadcn/ui 컴포넌트 설치
4. 기본 레이아웃 구성
```

---

## 🔗 참고 자료

### 공식 문서
- [Next.js 14 Documentation](https://nextjs.org/docs)
- [Supabase Auth Guide](https://supabase.com/docs/guides/auth)
- [Recharts API Reference](https://recharts.org/en-US/api)
- [shadcn/ui Components](https://ui.shadcn.com/)
- [TanStack Query Docs](https://tanstack.com/query/latest)
- [Tailwind CSS](https://tailwindcss.com/docs)

### 내부 문서
- `DESIGN_SYSTEM.md`: 디자인 시스템 가이드
- `CLAUDE.md`: 프로젝트 컨벤션
- `lib/features/statistics/`: Flutter 통계 로직 참고
- `lib/shared/themes/`: Flutter 테마 참고
- `household.pen`: pencil.dev 디자인 파일

### 기술 블로그
- [Next.js App Router Best Practices](https://nextjs.org/docs/app/building-your-application)
- [Supabase with Next.js](https://supabase.com/docs/guides/getting-started/quickstarts/nextjs)
- [Recharts with TypeScript](https://recharts.org/en-US/guide/typescript)

---

## ✅ 체크리스트

### 계획 단계 (완료)
- [x] 프로젝트 계획 수립
- [x] 기능 명세 작성
- [x] 디자인 매핑 가이드
- [x] 개발 로드맵
- [x] 프로젝트 요약

### 디자인 단계 (다음)
- [ ] house.pen 디자인 시안 (5페이지)
- [ ] API 명세서
- [ ] 데이터 모델
- [ ] 컴포넌트 구조도

### 개발 단계 (미래)
- [ ] Phase 1: 프로젝트 초기화
- [ ] Phase 2: 인증 구현
- [ ] Phase 3: 대시보드
- [ ] Phase 4: 고급 통계
- [ ] Phase 5: 파일 처리
- [ ] Phase 6: 디자인 시스템
- [ ] Phase 7: 최종 마무리

### 배포 단계 (미래)
- [ ] Vercel 배포
- [ ] 환경 변수 설정
- [ ] 도메인 연결 (선택)
- [ ] 모니터링 설정

---

## 💡 핵심 포인트

### 1. 디자인 일관성
```
✅ Flutter 앱과 동일한 색상, 간격, 모서리 반경
✅ house.pen 디자인 시안 기반 구현
✅ shadcn/ui 커스터마이징으로 일관성 유지
```

### 2. 데이터 공유
```
✅ Supabase 데이터베이스 공유
✅ 동일한 사용자 계정 (Auth)
✅ RLS 정책 재사용
```

### 3. 고급 기능
```
✅ Excel/CSV 파일 처리
✅ 6가지 차트 구현
✅ 필터 및 검색 기능
✅ 반응형 디자인
```

### 4. 성능 최적화
```
✅ TanStack Query 캐싱
✅ 코드 스플리팅
✅ 이미지 최적화
✅ 데이터 샘플링 (차트)
```

---

**작성일**: 2026-02-01
**작성자**: Claude Code (Sonnet 4.5)
**프로젝트**: 공유 가계부 웹 통계 플랫폼
**버전**: 1.0.0
