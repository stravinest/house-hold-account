# house.pen 웹 디자인 가이드

## 📐 웹 디자인 위치

house.pen 파일에 웹 통계 플랫폼 디자인이 추가되었습니다.

### 좌표 정보

```
Web Statistics Platform Section
x 좌표: 15000 (기준점)
총 너비: 약 7200px
```

| 페이지 | x 좌표 | 크기 (W×H) | 설명 |
|--------|--------|------------|------|
| **Web Login** | 15000 | 1440×900 | 로그인 페이지 (2분할 레이아웃) |
| **Web Dashboard** | 16540 | 1440×900 | 대시보드 (요약 카드 + 차트) |
| **Web Statistics** | 18080 | 1440×1200 | 상세 통계 (필터 + 4가지 차트) |
| **Web Import/Export** | 19620 | 1440×900 | 파일 업로드/다운로드 |
| **Web Settings** | 21160 | 1440×900 | 설정 (프로필/가계부/테마) |

---

## 🎨 디자인 시스템

### 색상 토큰 (Flutter 앱과 동일)

모든 웹 디자인은 앱의 디자인 토큰을 사용합니다:

```
$--primary: #2E7D32 (녹색)
$--surface: #FDFDF5 (배경)
$--surface-container: #EFEEE6
$--surface-container-highest: #E3E3DB

$--income: #2E7D32 (수입)
$--expense: #BA1A1A (지출)
$--asset: #006A6A (자산)

$--on-surface: #1A1C19 (기본 텍스트)
$--on-surface-variant: #44483E (보조 텍스트)
```

### 간격 (Spacing)

```
xs:  4px
sm:  8px
md:  16px
lg:  24px
xl:  32px
```

### 모서리 반경 (Border Radius)

```
sm:  8px
md:  12px (기본 - 버튼, 입력 필드)
lg:  16px (카드)
xl:  20px
```

### 타이포그래피

```
Font Family: Inter (Material Design 3 기준)

제목:
- headline-large: 32px, 600
- headline-medium: 28px, 600
- headline-small: 24px, 600

본문:
- body-large: 16px, 400
- body-medium: 14px, 400
- body-small: 12px, 400

라벨:
- label-large: 14px, 500
- label-medium: 12px, 500
```

---

## 📄 페이지별 상세

### 1. Web Login (x=15000)

**레이아웃:** 2분할 (좌우 50:50)

#### 왼쪽 패널 (브랜딩)
- 배경: `$--primary-container`
- 로고 (120×120)
- 제목: "공유 가계부" (48px)
- 부제: "웹에서 더 강력한 통계와 분석을"
- 기능 목록:
  - 📊 6가지 상세 차트
  - 📁 Excel/CSV 파일 관리
  - 🔍 강력한 필터 및 검색

#### 오른쪽 패널 (로그인 폼)
- 배경: `$--surface`
- 제목: "로그인" (32px)
- 이메일 입력 (52px 높이, 12px 모서리)
- 비밀번호 입력 (눈 아이콘 토글)
- 로그인 버튼 (Primary, 52px)
- 회원가입 링크

**반응형:**
- Desktop: 1440×900
- Mobile: 세로 스택 레이아웃 (예정)

---

### 2. Web Dashboard (x=16540)

**레이아웃:** 헤더 + 콘텐츠

#### 헤더 (72px)
- 앱 이름: "공유 가계부"
- 오른쪽: 알림 아이콘 + 프로필 아이콘

#### 요약 카드 (3개, 가로 배치)
각 카드 (140px 높이):
- 아이콘 + 제목
- 금액 (32px, 700)
- 전월 대비 증감률

1. **수입 카드**
   - 배경: #E8F5E9 (연한 녹색)
   - 아이콘: trending-up
   - 색상: `$--income`

2. **지출 카드**
   - 배경: #FFEBEE (연한 빨강)
   - 아이콘: trending-down
   - 색상: `$--expense`

3. **저축 카드**
   - 배경: #E0F7FA (연한 청록)
   - 아이콘: piggy-bank
   - 색상: `$--asset`

#### 차트 섹션
- 왼쪽: 월별 추이 (Line Chart, 가변 너비)
- 오른쪽: 카테고리 분석 (Donut Chart, 480px 고정)

#### 최근 거래 목록
- 높이: 200px
- 테이블 형식 (Placeholder)

---

### 3. Web Statistics (x=18080)

**레이아웃:** 헤더 + 필터 + 차트 그리드

#### 필터 바 (80px)
- 기간 선택 (calendar 아이콘)
- 유형 선택 (filter 아이콘)
- 카테고리 선택 (tag 아이콘)

#### 차트 그리드 (2×2)

**상단 행:**
1. 결제수단별 분석 (Horizontal Bar Chart)
   - 가변 너비
2. 사용자별 비교 (Stacked Bar Chart)
   - 480px 고정

**하단 행:**
3. 연도별 추이 (Bar + Line Chart)
   - 가변 너비
4. 예산 진행률 (Progress Chart)
   - 480px 고정

---

### 4. Web Import/Export (x=19620)

**레이아웃:** 2분할 (좌우 50:50)

#### 왼쪽: 파일 업로드
- **드롭존 (300px 높이)**
  - 점선 테두리
  - upload-cloud 아이콘 (64px)
  - "파일을 드래그하거나 클릭하여 업로드"
  - "Excel (.xlsx) 또는 CSV 파일 (최대 10MB)"
  - "파일 선택" 버튼

- **미리보기 영역**
  - 배경: `$--surface-container`
  - Placeholder: "파일을 업로드하면 여기에 미리보기가 표시됩니다"

#### 오른쪽: 파일 다운로드
- **파일 형식 선택**
  - Excel (선택됨, Primary)
  - CSV (비선택, Outlined)

- **기간 선택**
  - 시작 날짜 입력
  - ~ (구분자)
  - 종료 날짜 입력

- **다운로드 버튼**
  - download 아이콘 + "다운로드"
  - Primary, 52px

- **템플릿**
  - "빈 템플릿 다운로드" 링크
  - file-text 아이콘

---

### 5. Web Settings (x=21160)

**레이아웃:** 사이드바 + 메인

#### 사이드바 (280px)
- **프로필** (선택됨, Primary Container)
- 가계부
- 테마

#### 메인 콘텐츠
- **제목:** "프로필 설정" (24px)

- **프로필 사진**
  - 80×80 원형
  - Primary 배경 + user 아이콘
  - "사진 변경" 버튼

- **표시 이름**
  - 라벨: "표시 이름"
  - 입력 필드 (52px)

- **내 색상**
  - 5가지 파스텔 톤 색상 팔레트
  - 원형 (48×48)
  - 선택된 색상: Primary 테두리 (3px)

- **액션 버튼**
  - 취소 (Outlined)
  - 저장 (Primary)

---

## 🔧 pencil.dev에서 확인하기

### 1. house.pen 파일 열기

```bash
cd /Users/eungyu/Desktop/개인/project/house-hold-account
open house.pen
```

또는 pencil.dev에서 직접 열기:
- https://pencil.dev
- "Open File" → house.pen 선택

### 2. 웹 디자인 섹션으로 이동

**방법 1: 좌표로 이동**
- View 메뉴 → "Go to Position"
- x: 15000 입력
- Enter

**방법 2: 프레임 검색**
- 좌측 레이어 패널에서 "Web Statistics Platform" 검색
- 더블클릭하여 이동

### 3. 각 페이지 확인

1. **Web Login**: x=15000
2. **Web Dashboard**: x=16540 (오른쪽으로 1540px 이동)
3. **Web Statistics**: x=18080 (추가 1540px 이동)
4. **Web Import/Export**: x=19620
5. **Web Settings**: x=21160

---

## 📝 수정 가이드

### 색상 변경

모든 색상은 디자인 토큰을 사용합니다:

```json
"fill": "$--primary"         // ✅ 권장
"fill": "#2E7D32"            // ❌ 하드코딩 금지
```

### 간격 조정

```json
"gap": 16,                   // ✅ 16px ($--spacing-md)
"gap": 15,                   // ❌ 임의 값 금지
```

### 새 컴포넌트 추가

1. 기존 컴포넌트 복사 (Cmd+C, Cmd+V)
2. ID 변경 필수
3. 디자인 토큰 사용 확인
4. 간격/모서리 토큰 사용 확인

---

## 🔄 백업 및 복구

### 백업 파일

작업 중 자동으로 생성된 백업:

```bash
house.pen.backup   # 첫 번째 백업 (Login + Dashboard)
house.pen.backup2  # 두 번째 백업 (Statistics + Import/Export 추가)
house.pen.backup3  # 세 번째 백업 (Settings 추가)
```

### 복구 방법

```bash
# 최신 백업으로 복구
mv house.pen.backup3 house.pen

# 특정 백업으로 복구
mv house.pen.backup2 house.pen
```

---

## 🚀 다음 단계

### 웹 구현 시 참고

1. **디자인 토큰 적용**
   - `web/src/app/globals.css`에 CSS 변수로 정의됨
   - Tailwind 클래스로 사용

2. **컴포넌트 구현**
   - shadcn/ui 컴포넌트 사용
   - 디자인 시안과 동일한 크기/간격 적용

3. **반응형 적용**
   - Desktop: 1440px (기준)
   - Tablet: 768-1023px
   - Mobile: <768px

### 추가 디자인 필요 시

```bash
# 새 페이지 JSON 생성
nano web-design-new-page.json

# house.pen에 추가
node add-new-page.js
```

---

## 📚 관련 문서

- [웹 디자인 매핑](./web-design-system-mapping.md)
- [개발 로드맵](./web-development-roadmap.md)
- [프로젝트 계획](./web-statistics-platform.plan.md)

---

**작성일**: 2026-02-01
**버전**: 1.0.0
**작성자**: Claude Code (Sonnet 4.5)
