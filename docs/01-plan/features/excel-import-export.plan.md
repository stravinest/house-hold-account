# 웹 거래 페이지 기능 Planning Document

> **Summary**: 웹 거래 페이지에 엑셀 내보내기/가져오기, 검색/필터, 거래 추가 기능 구현
>
> **Project**: shared_household_account
> **Version**: 1.0.0+1
> **Author**: eungyu
> **Date**: 2026-02-08
> **Status**: Draft

---

## 1. Overview

### 1.1 Purpose

웹 버전 거래 페이지(7Nyol)의 핵심 인터랙션 기능들을 구현한다:
1. **엑셀 내보내기/가져오기**: 거래 데이터를 엑셀(.xlsx)/CSV로 내보내고, 외부 파일에서 일괄 가져오기
2. **검색/필터**: 월별 날짜 필터, 거래 유형(전체/수입/지출) 필터
3. **거래 추가**: 웹 다이얼로그를 통한 거래 생성 (지출/수입/자산)

### 1.2 Background

- 웹 버전 거래 페이지(7Nyol)의 디자인이 완성되어 있으나, 내보내기/가져오기/검색/거래추가 인터랙션이 미구현
- 사용자가 웹에서도 앱과 동일한 거래 관리 경험을 원함
- Flutter 앱에서 `excel: ^4.0.6`, `csv: ^6.0.0`, `share_plus`, `path_provider` 패키지가 이미 추가됨
- 웹 거래 페이지 헤더에 '내보내기', '가져오기', '거래 추가' 버튼이 디자인되어 있음 (SoCvj)

### 1.3 Related Documents

- Design:
  - `house.pen` Node ID `J8rAe` - 엑셀 내보내기 패널
  - `house.pen` Node ID `5K1SN` - 엑셀 가져오기 패널
  - `house.pen` Node ID `7Nyol` - 웹 거래 페이지 (Sidebar + Content Area)
  - `house.pen` Node ID `8545T` - 거래 추가 다이얼로그
  - `house.pen` Node ID `8dQwI` - 날짜/유형 필터 영역
  - `house.pen` Node ID `SoCvj` - 내보내기/가져오기/거래추가 버튼 그룹
- Architecture: `CLAUDE.md` (Clean Architecture Feature-first 구조)

---

## 2. Scope

### 2.1 In Scope

- [x] 엑셀 내보내기 (Export)
  - [x] 기간 선택 (시작일~종료일, 빠른 선택 버튼: 이번 달/지난 달/최근 3개월/올해 전체)
  - [x] 거래 유형 필터 (전체/지출만/수입만/자산만)
  - [x] 포함 항목 선택 (카테고리, 결제수단, 메모, 작성자, 고정비)
  - [x] 파일 형식 선택 (.xlsx / .csv)
  - [x] 파일 공유/저장 기능 (share_plus 활용)
- [x] 엑셀 가져오기 (Import)
  - [x] 파일 선택 (.xlsx / .csv 지원, 최대 10MB)
  - [x] 자동 컬럼 매핑 (날짜, 금액, 카테고리 등)
  - [x] 중복 거래 자동 건너뜀
  - [x] 가져오기 옵션 (미분류 카테고리 자동 생성, 기존 결제수단 매칭, 가져오기 전 미리보기)
  - [x] 가져오기 결과 요약 표시
- [x] 검색/필터 기능
  - [x] 월별 날짜 필터 (캘린더 아이콘 + "2026년 2월" 표시)
  - [x] 거래 유형 탭 필터 (전체/수입/지출)
- [x] 거래 추가 기능
  - [x] 거래 추가 다이얼로그 (house.pen 8545T 디자인)
  - [x] 유형 선택 (지출/수입/자산 탭)
  - [x] 금액 입력
  - [x] 제목, 날짜, 카테고리, 결제수단 입력
  - [x] 할부/반복/고정비 토글 옵션
  - [x] 메모 입력 (선택)
- [x] 웹 버전 (Next.js/React) 지원
- [x] Flutter 앱 (Android/iOS) 지원 (엑셀 내보내기/가져오기)

### 2.2 Out of Scope

- 자동 정기 백업/내보내기
- Google Sheets/OneDrive 직접 연동
- PDF 내보내기
- 이미지 첨부파일 내보내기/가져오기
- 거래 수정/삭제 다이얼로그 (별도 PDCA)
- 고급 검색 (키워드 검색, 금액 범위 검색)

---

## 3. Requirements

### 3.1 Functional Requirements

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-01 | 사용자가 기간을 설정하여 거래 데이터를 .xlsx 형식으로 내보낼 수 있다 | High | Pending |
| FR-02 | 사용자가 기간을 설정하여 거래 데이터를 .csv 형식으로 내보낼 수 있다 | High | Pending |
| FR-03 | 내보내기 시 거래 유형(지출/수입/자산) 필터링이 가능하다 | High | Pending |
| FR-04 | 내보내기 시 포함할 컬럼(카테고리, 결제수단, 메모, 작성자, 고정비)을 선택할 수 있다 | Medium | Pending |
| FR-05 | 내보낸 파일을 기기에 저장하거나 다른 앱으로 공유할 수 있다 | High | Pending |
| FR-06 | .xlsx 또는 .csv 파일을 선택하여 거래를 일괄 가져올 수 있다 | High | Pending |
| FR-07 | 가져오기 시 컬럼을 자동으로 매핑하고, 사용자가 수정할 수 있다 | Medium | Pending |
| FR-08 | 가져오기 시 중복 거래를 자동으로 감지하고 건너뛴다 | High | Pending |
| FR-09 | 가져오기 전 미리보기로 데이터를 확인할 수 있다 | Medium | Pending |
| FR-10 | 가져오기 완료 후 결과 요약(성공/건너뜀/실패 건수)을 표시한다 | Medium | Pending |
| FR-11 | 빠른 기간 선택 버튼(이번 달, 지난 달, 최근 3개월, 올해 전체)을 제공한다 | Low | Pending |
| **검색/필터** | | | |
| FR-12 | 월별 날짜 필터로 거래 목록을 해당 월로 필터링할 수 있다 | High | Pending |
| FR-13 | 거래 유형 탭(전체/수입/지출)으로 거래를 필터링할 수 있다 | High | Pending |
| FR-14 | 필터 변경 시 거래 목록과 요약 카드(수입/지출/잔액)가 실시간 갱신된다 | High | Pending |
| **거래 추가** | | | |
| FR-15 | '거래 추가' 버튼 클릭 시 거래 추가 다이얼로그가 열린다 | High | Pending |
| FR-16 | 지출/수입/자산 유형을 탭으로 선택할 수 있다 | High | Pending |
| FR-17 | 금액, 제목, 날짜, 카테고리, 결제수단을 입력할 수 있다 | High | Pending |
| FR-18 | 할부/반복/고정비 토글 옵션을 설정할 수 있다 | Medium | Pending |
| FR-19 | 메모를 선택적으로 입력할 수 있다 | Low | Pending |
| FR-20 | 거래 저장 시 Supabase에 데이터가 저장되고, 거래 목록이 갱신된다 | High | Pending |

### 3.2 Non-Functional Requirements

| Category | Criteria | Measurement Method |
|----------|----------|-------------------|
| Performance | 1,000건 내보내기 3초 이내 완료 | Stopwatch 측정 |
| Performance | 10MB 파일 가져오기 10초 이내 완료 | Stopwatch 측정 |
| UX | 내보내기/가져오기 진행 상태 표시 (로딩 인디케이터) | 시각적 확인 |
| Data Integrity | 가져오기 시 데이터 손실 없음 (날짜, 금액, 문자열 정확 변환) | 단위 테스트 |
| Compatibility | Excel 2007+ (.xlsx) 호환 | Excel/Google Sheets에서 열기 확인 |

---

## 4. Success Criteria

### 4.1 Definition of Done

- [ ] 내보내기 기능 구현 완료 (.xlsx, .csv)
- [ ] 가져오기 기능 구현 완료 (.xlsx, .csv)
- [ ] 내보내기 패널 UI 구현 (house.pen J8rAe 디자인 준수)
- [ ] 가져오기 패널 UI 구현 (house.pen 5K1SN 디자인 준수)
- [ ] 검색/필터 기능 구현 (월별 날짜, 유형 필터)
- [ ] 거래 추가 다이얼로그 구현 (house.pen 8545T 디자인 준수)
- [ ] Supabase 연동 (거래 CRUD)
- [ ] 단위 테스트 작성 및 통과
- [ ] 한국어/영어 다국어 지원 (i18n)
- [ ] 코드 리뷰 완료

### 4.2 Quality Criteria

- [ ] 서비스 레이어 테스트 커버리지 80% 이상
- [ ] flutter analyze 에러 없음
- [ ] 빌드 성공 (Android)

---

## 5. Risks and Mitigation

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| 대용량 파일(10MB+) 가져오기 시 메모리 부족 | High | Medium | 스트리밍 방식 파싱, 진행률 표시, 파일 크기 제한 |
| 다양한 엑셀 형식/인코딩 호환성 문제 | Medium | High | UTF-8 기본 처리, 인코딩 감지 로직, 지원 형식 명시 |
| 중복 거래 감지 정확도 | Medium | Medium | 날짜+금액+제목 복합 키 기반 중복 판별 |
| 가져오기 시 카테고리/결제수단 매핑 실패 | Low | High | 미분류 카테고리 자동 할당, 사용자 수동 매핑 옵션 |
| iOS에서 파일 접근 권한 제한 | Medium | Low | file_picker 패키지 활용, iOS 문서 디렉토리 사용 |

---

## 6. Architecture Considerations

### 6.1 Project Level Selection

| Level | Characteristics | Recommended For | Selected |
|-------|-----------------|-----------------|:--------:|
| **Starter** | Simple structure | Static sites | |
| **Dynamic** | Feature-based modules, services layer | Web apps with backend, SaaS MVPs | **O** |
| **Enterprise** | Strict layer separation, DI, microservices | High-traffic systems | |

### 6.2 Key Architectural Decisions

| Decision | Options | Selected | Rationale |
|----------|---------|----------|-----------|
| Excel 라이브러리 | excel / syncfusion | excel ^4.0.6 | 이미 pubspec.yaml에 추가됨, 무료, 충분한 기능 |
| CSV 라이브러리 | csv / dart:convert | csv ^6.0.0 | 이미 pubspec.yaml에 추가됨 |
| 파일 공유 | share_plus / open_file | share_plus ^10.1.4 | 이미 pubspec.yaml에 추가됨, 크로스 플랫폼 지원 |
| 파일 선택 | file_picker | file_picker (추가 필요) | 파일 선택 UI 제공, .xlsx/.csv 필터 지원 |
| 파일 저장 경로 | path_provider | path_provider ^2.1.5 | 이미 pubspec.yaml에 추가됨 |

### 6.3 Clean Architecture Approach

```
Selected Level: Dynamic (Feature-first Clean Architecture)

신규/수정 파일 구조:

[Flutter 앱 - 엑셀 내보내기/가져오기]
lib/features/transaction/
├── data/
│   └── services/
│       ├── excel_export_service.dart      # 엑셀/CSV 내보내기 로직
│       └── excel_import_service.dart      # 엑셀/CSV 가져오기 로직
├── domain/
│   └── entities/
│       └── export_options.dart            # 내보내기 옵션 엔티티
├── presentation/
│   ├── widgets/
│   │   ├── export_panel.dart              # 내보내기 패널 UI (J8rAe)
│   │   └── import_panel.dart              # 가져오기 패널 UI (5K1SN)
│   └── providers/
│       └── excel_provider.dart            # 내보내기/가져오기 상태 관리

[웹 버전 - 거래 페이지 전체 기능]
web/src/
├── components/
│   ├── transaction/
│   │   ├── transaction-list.tsx           # 거래 목록 (7Nyol 기반)
│   │   ├── transaction-summary-cards.tsx  # 요약 카드 (수입/지출/잔액)
│   │   ├── transaction-filter.tsx         # 날짜/유형 필터 (8dQwI)
│   │   ├── add-transaction-dialog.tsx     # 거래 추가 다이얼로그 (8545T)
│   │   ├── export-panel.tsx              # 내보내기 패널 (J8rAe)
│   │   └── import-panel.tsx              # 가져오기 패널 (5K1SN)
│   └── ui/                               # 공통 UI 컴포넌트 (이미 있을 수 있음)
├── lib/
│   ├── excel-export.ts                   # 엑셀 내보내기 서비스
│   └── excel-import.ts                   # 엑셀 가져오기 서비스
└── app/
    └── ledger/
        └── transactions/
            └── page.tsx                   # 거래 페이지 (기존 수정)
```

---

## 7. Convention Prerequisites

### 7.1 Existing Project Conventions

- [x] `CLAUDE.md` has coding conventions section
- [x] 다국어 지원 (app_ko.arb, app_en.arb)
- [x] Riverpod 상태관리
- [x] Clean Architecture Feature-first 구조
- [x] Equatable 기반 Entity

### 7.2 Conventions to Define/Verify

| Category | Current State | To Define | Priority |
|----------|---------------|-----------|:--------:|
| **Naming** | exists | 기존 패턴 준수 (snake_case 파일명, camelCase 변수) | High |
| **Folder structure** | exists | transaction feature 내 서비스 추가 | High |
| **Import order** | exists | 기존 패턴 준수 | Medium |
| **i18n keys** | exists | export/import 관련 키 추가 | High |
| **Error handling** | exists | rethrow 패턴 준수 | Medium |

### 7.3 Dependencies Needed

| Package | Purpose | Status |
|---------|---------|--------|
| `excel: ^4.0.6` | .xlsx 파일 생성/읽기 | 이미 추가됨 |
| `csv: ^6.0.0` | CSV 파일 생성/읽기 | 이미 추가됨 |
| `path_provider: ^2.1.5` | 임시 파일 저장 경로 | 이미 추가됨 |
| `share_plus: ^10.1.4` | 파일 공유 | 이미 추가됨 |
| `file_picker` | 파일 선택 (가져오기용) | **추가 필요** |

---

## 8. Implementation Plan

### 8.1 Phase 1: 내보내기 (Export) - Core

1. `ExportOptions` 엔티티 정의 (기간, 유형, 포함 항목, 파일 형식)
2. `ExcelExportService` 구현
   - `exportToXlsx()`: 거래 목록 -> .xlsx 파일 생성
   - `exportToCsv()`: 거래 목록 -> .csv 파일 생성
   - 기간별 거래 조회 (기존 `TransactionRepository.getTransactionsByDateRange()` 활용)
3. `ExportPanel` UI 위젯 구현 (house.pen J8rAe 디자인)
4. i18n 키 추가

### 8.2 Phase 2: 가져오기 (Import) - Core

1. `ExcelImportService` 구현
   - `parseXlsx()`: .xlsx 파일 파싱 -> 거래 데이터 리스트
   - `parseCsv()`: .csv 파일 파싱 -> 거래 데이터 리스트
   - `autoMapColumns()`: 자동 컬럼 매핑
   - `detectDuplicates()`: 중복 거래 감지
2. `ImportPanel` UI 위젯 구현 (house.pen 5K1SN 디자인)
3. 가져오기 결과 요약 다이얼로그
4. i18n 키 추가

### 8.3 Phase 3: 검색/필터 기능

1. 월별 날짜 필터 컴포넌트 구현
   - 현재 월 표시 ("2026년 2월")
   - 이전/다음 월 탐색
   - 캘린더 아이콘 + 날짜 피커
2. 거래 유형 탭 필터 구현 (전체/수입/지출)
   - 선택 탭: 녹색(#2E7D32) 배경, 흰색 텍스트
   - 비선택 탭: #F5F6F5 배경
3. 필터 상태에 따른 거래 목록 및 요약 카드 실시간 갱신

### 8.4 Phase 4: 거래 추가 다이얼로그

1. 거래 추가 다이얼로그 UI 구현 (house.pen 8545T 디자인)
   - 유형 선택 탭 (지출/수입/자산 - Segmented Control)
   - 금액 입력 영역 (큰 글씨, 색상: 지출 빨강 #BA1A1A, 수입 녹색 #2E7D32)
   - 제목 입력 필드
   - 날짜 선택 (캘린더 피커)
   - 카테고리 칩 선택 (더보기 버튼 포함)
   - 결제수단 칩 선택
   - 옵션 토글 (할부, 반복, 고정비)
   - 메모 입력 (선택)
2. Supabase 거래 생성 API 연동
3. 저장 후 거래 목록 자동 갱신

### 8.5 Phase 5: Provider/State Management

1. `ExcelProvider` 구현 (Riverpod 또는 React 상태 관리)
   - 내보내기 진행 상태
   - 가져오기 진행 상태 (파싱 -> 미리보기 -> 저장)
   - 에러 처리
2. 거래 목록 상태 관리 (필터 적용, 페이지네이션)
3. 거래 추가 폼 상태 관리
4. 내보내기/가져오기 진입점 연동

### 8.6 Phase 6: 테스트 및 검증

1. `ExcelExportService` 단위 테스트
2. `ExcelImportService` 단위 테스트 (다양한 파일 형식, 인코딩, 빈 셀 등)
3. 중복 감지 로직 테스트
4. 검색/필터 로직 테스트
5. 거래 추가 유효성 검증 테스트
6. UI 컴포넌트 테스트

---

## 9. Excel Data Schema

### 9.1 내보내기 컬럼 구조

| 컬럼명 (KO) | 컬럼명 (EN) | 데이터 타입 | 필수 | 비고 |
|-------------|-------------|------------|:----:|------|
| 날짜 | Date | YYYY-MM-DD | O | |
| 유형 | Type | String | O | 수입/지출/자산 |
| 금액 | Amount | Integer | O | 원 단위 |
| 제목 | Title | String | | |
| 카테고리 | Category | String | | 옵션 선택 시 |
| 결제수단 | Payment Method | String | | 옵션 선택 시 |
| 메모 | Memo | String | | 옵션 선택 시 |
| 작성자 | Author | String | | 옵션 선택 시 |
| 고정비 | Fixed Expense | String | | 옵션 선택 시 (Y/N) |

### 9.2 가져오기 매핑 규칙

- **날짜**: YYYY-MM-DD, YYYY/MM/DD, MM/DD/YYYY 등 다양한 형식 자동 감지
- **금액**: 숫자만 추출 (콤마, 원, 기호 자동 제거)
- **유형**: '수입'/'income', '지출'/'expense', '자산'/'asset' 매칭
- **카테고리**: 기존 카테고리명과 매칭, 미매칭 시 '미분류' 할당 또는 신규 생성

---

## 10. 거래 추가 다이얼로그 UI 스펙 (Node ID: 8545T)

### 10.1 다이얼로그 구조

```
dialogPanel (580x860, cornerRadius: 20, fill: #FFFFFF)
├── dialogHeader (padding: 18/24)
│   ├── "거래 추가" (18px, 600 weight)
│   └── closeBtn (32x32, fill: #F5F5F5, cornerRadius: 16)
├── dialogBody (padding: 24, gap: 20, scrollable)
│   ├── typeSelector (Segmented Control, cornerRadius: 12, fill: #F5F6F5)
│   │   ├── 지출 탭 (선택 시 fill: #2E7D32, 텍스트: #FFFFFF)
│   │   ├── 수입 탭
│   │   └── 자산 탭
│   ├── amountSection (fill: #FAFBFA, cornerRadius: 14, padding: 20/24)
│   │   ├── "금액" 라벨
│   │   └── 금액 표시 (32px, 700 weight, 지출: #BA1A1A / 수입: #2E7D32)
│   ├── titleField (제목 입력)
│   ├── dateField (날짜 선택)
│   ├── categorySection (카테고리 칩 목록, cornerRadius: 20)
│   │   ├── 선택된 칩: fill #2E7D32, 텍스트 #FFFFFF
│   │   ├── 비선택 칩: stroke #E0E0E0
│   │   └── "더보기" 칩
│   ├── paymentSection (결제수단 칩 목록, 동일 스타일)
│   ├── optionsRow (할부/반복/고정비 토글)
│   │   ├── 할부 토글 (off 상태: #E0E0E0)
│   │   ├── 반복 토글 (off 상태: #E0E0E0)
│   │   └── 고정비 토글 (on 상태: fill #E8F5E9, stroke #2E7D32)
│   └── memoSection (메모 입력, height: 72)
└── dialogFooter (padding: 16/24, gap: 12)
    ├── 취소 버튼 (stroke: #E0E0E0, cornerRadius: 12)
    └── 저장 버튼 (fill: #2E7D32, cornerRadius: 12)
```

### 10.2 검색/필터 UI 스펙 (Node ID: 8dQwI)

```
filterRow (width: fill, justifyContent: space-between)
├── dateFilter
│   ├── calendar icon (#44483E, 16x16)
│   └── "2026년 2월" (14px, 600 weight, #1A1C19)
└── typeTabs (gap: 4)
    ├── 전체 (선택: fill #2E7D32, text #FFFFFF, cornerRadius: 8)
    ├── 수입 (비선택: fill #F5F6F5, text #44483E)
    └── 지출 (비선택: fill #F5F6F5, text #44483E)
```

### 10.3 버튼 그룹 UI 스펙 (Node ID: SoCvj)

```
btnGroup (gap: 8)
├── 내보내기 btn (stroke: #E0E0E0, cornerRadius: 10, padding: 10/16)
│   ├── download icon (#44483E, 14x14)
│   └── "내보내기" (13px, 500 weight)
├── 가져오기 btn (동일 스타일)
│   ├── upload icon (#44483E, 14x14)
│   └── "가져오기" (13px, 500 weight)
└── 거래 추가 btn (fill: #2E7D32, cornerRadius: 10, padding: 10/16)
    ├── plus icon (#FFFFFF, 16x16)
    └── "거래 추가" (13px, 600 weight, #FFFFFF)
```

---

## 11. Next Steps

1. [ ] Design 문서 작성 (`excel-import-export.design.md`)
2. [ ] `file_picker` 패키지 추가 (Flutter 앱)
3. [ ] 웹 버전 엑셀 라이브러리 선정 (xlsx / SheetJS 등)
4. [ ] 구현 시작 (Phase 1: 내보내기 -> Phase 2: 가져오기 -> Phase 3: 검색/필터 -> Phase 4: 거래 추가)

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 0.1 | 2026-02-08 | 초안 작성 (엑셀 내보내기/가져오기) | eungyu |
| 0.2 | 2026-02-08 | 검색/필터, 거래 추가 기능 추가 (8545T, 8dQwI, SoCvj) | eungyu |
