# 공유 가계부 앱 - 주니어 개발자 가이드

이 문서는 주니어 개발자가 프로젝트를 빠르게 이해하고 개발에 참여할 수 있도록 작성되었습니다.

---

## 목차

1. [프로젝트 개요](#1-프로젝트-개요)
2. [화면별 설명 및 코드 위치](#2-화면별-설명-및-코드-위치)
3. [기능별 설명 및 코드 위치](#3-기능별-설명-및-코드-위치)
4. [버튼별 설명 및 코드 위치](#4-버튼별-설명-및-코드-위치)
5. [기능 흐름도 (Flow)](#5-기능-흐름도-flow)

---

## 1. 프로젝트 개요

### 1.1 앱 소개
공유 가계부는 가족, 커플, 룸메이트와 함께 수입/지출을 관리할 수 있는 Flutter 기반 크로스플랫폼 앱입니다.

### 1.2 기술 스택
| 분류 | 기술 |
|------|------|
| Framework | Flutter (Dart SDK ^3.10.3) |
| Backend | Supabase (PostgreSQL + Auth + Realtime) |
| 상태관리 | Riverpod (flutter_riverpod) |
| 라우팅 | go_router |
| 차트 | fl_chart |
| 캘린더 | table_calendar |

### 1.3 프로젝트 구조
```
lib/
├── main.dart                 # 앱 진입점
├── config/                   # 설정 파일
│   ├── router.dart          # 라우팅 설정
│   └── supabase_config.dart # Supabase 연결 설정
├── core/                     # 공통 상수
│   └── constants/
├── shared/                   # 공유 컴포넌트
│   └── themes/              # 테마 설정
└── features/                 # 기능별 모듈 (Feature-first 구조)
    ├── auth/                # 인증
    ├── ledger/              # 가계부
    ├── transaction/         # 거래 기록
    ├── category/            # 카테고리
    ├── budget/              # 예산
    ├── statistics/          # 통계
    ├── share/               # 공유
    ├── search/              # 검색
    └── settings/            # 설정
```

### 1.4 Feature 모듈 구조
각 Feature는 Clean Architecture를 따릅니다:
```
features/{feature}/
├── domain/           # 도메인 레이어 (비즈니스 로직의 핵심)
│   └── entities/    # Entity 정의 (데이터 모델의 순수한 형태)
├── data/             # 데이터 레이어 (외부 데이터 소스와 통신)
│   ├── models/      # Model (JSON 직렬화/역직렬화)
│   └── repositories/ # Repository (데이터 소스 접근)
└── presentation/     # 프레젠테이션 레이어 (UI)
    ├── pages/       # 페이지 (전체 화면)
    ├── widgets/     # 위젯 (재사용 가능한 UI 컴포넌트)
    └── providers/   # Provider (상태 관리)
```

---

## 2. 화면별 설명 및 코드 위치

### 2.1 스플래시 화면 (Splash Screen)
**설명**: 앱 시작 시 표시되는 로딩 화면. 인증 상태를 확인하여 로그인 또는 홈으로 이동합니다.

| 항목 | 위치 |
|------|------|
| 화면 코드 | `lib/config/router.dart:139-191` (`SplashPage` 클래스) |
| 라우트 경로 | `/` |

**핵심 로직**:
```dart
// router.dart:153-163
Future<void> _checkAuth() async {
  await Future.delayed(const Duration(seconds: 1));
  final authState = ref.read(authStateProvider);
  if (authState.valueOrNull != null) {
    context.go(Routes.home);
  } else {
    context.go(Routes.login);
  }
}
```

---

### 2.2 로그인 화면 (Login Page)
**설명**: 이메일/비밀번호 또는 Google 소셜 로그인을 제공합니다.

| 항목 | 위치 |
|------|------|
| 화면 코드 | `lib/features/auth/presentation/pages/login_page.dart` |
| Provider | `lib/features/auth/presentation/providers/auth_provider.dart` |
| 라우트 경로 | `/login` |

**UI 구성**:
- 앱 로고 및 타이틀 (라인 114-136)
- 이메일 입력 필드 (라인 141-158)
- 비밀번호 입력 필드 (라인 162-190)
- 로그인 버튼 (라인 206-215)
- Google 로그인 버튼 (라인 237-248)
- 회원가입 링크 (라인 253-265)

**핵심 로직**:
```dart
// login_page.dart:29-75 - 이메일 로그인 처리
Future<void> _handleEmailLogin() async {
  await ref.read(authNotifierProvider.notifier).signInWithEmail(
    email: _emailController.text.trim(),
    password: _passwordController.text,
  );
  // 인증 상태 확인 후 홈으로 이동
}
```

---

### 2.3 회원가입 화면 (Signup Page)
**설명**: 새 사용자 계정을 생성합니다.

| 항목 | 위치 |
|------|------|
| 화면 코드 | `lib/features/auth/presentation/pages/signup_page.dart` |
| 라우트 경로 | `/signup` |

**입력 필드**:
- 이름 (라인 122-140)
- 이메일 (라인 144-163)
- 비밀번호 (라인 167-195)
- 비밀번호 확인 (라인 199-229)

---

### 2.4 홈 화면 (Home Page)
**설명**: 앱의 메인 화면으로 하단 네비게이션으로 4개의 탭을 제공합니다.

| 항목 | 위치 |
|------|------|
| 화면 코드 | `lib/features/ledger/presentation/pages/home_page.dart` |
| 라우트 경로 | `/home` |

**하단 네비게이션 탭** (라인 119-148):
| 탭 | 인덱스 | 위젯 | 설명 |
|-----|--------|------|------|
| 캘린더 | 0 | `CalendarTabView` | 캘린더 + 일별 거래 목록 |
| 통계 | 1 | `StatisticsTabView` | 수입/지출 통계 차트 |
| 예산 | 2 | `BudgetTabView` | 예산 관리 |
| 더보기 | 3 | `MoreTabView` | 공유관리, 카테고리, 설정 등 |

**탭별 위젯 클래스**:
- `CalendarTabView` (라인 200-233): 캘린더와 거래 목록
- `StatisticsTabView` (라인 236-243): 통계 페이지
- `BudgetTabView` (라인 246-253): 예산 페이지
- `MoreTabView` (라인 256-342): 더보기 메뉴

---

### 2.5 캘린더 뷰 (Calendar View)
**설명**: 월별 캘린더와 월간 수입/지출 요약을 표시합니다.

| 항목 | 위치 |
|------|------|
| 위젯 코드 | `lib/features/ledger/presentation/widgets/calendar_view.dart` |

**구성 요소**:
- `_MonthSummary` (라인 106-154): 월별 수입/지출/합계 요약
- `TableCalendar` (라인 29-99): 캘린더 위젯

---

### 2.6 거래 목록 (Transaction List)
**설명**: 선택한 날짜의 거래 내역을 카드 형태로 표시합니다.

| 항목 | 위치 |
|------|------|
| 위젯 코드 | `lib/features/ledger/presentation/widgets/transaction_list.dart` |

**구성 요소**:
- `TransactionList` (라인 10-62): 거래 목록 메인 위젯
- `_EmptyState` (라인 65-114): 거래가 없을 때 표시
- `_TransactionCard` (라인 117-267): 개별 거래 카드 (스와이프로 수정/삭제)

---

### 2.7 거래 추가 시트 (Add Transaction Sheet)
**설명**: 새 거래(수입/지출)를 추가하는 바텀 시트입니다.

| 항목 | 위치 |
|------|------|
| 위젯 코드 | `lib/features/transaction/presentation/widgets/add_transaction_sheet.dart` |

**입력 필드**:
- 수입/지출 타입 선택 (라인 177-197)
- 금액 입력 (라인 201-233)
- 날짜 선택 (라인 239-247)
- 카테고리 선택 (라인 251-265)
- 메모 입력 (라인 271-279)

---

### 2.8 통계 페이지 (Statistics Page)
**설명**: 카테고리별 수입/지출 통계를 차트로 표시합니다.

| 항목 | 위치 |
|------|------|
| 화면 코드 | `lib/features/statistics/presentation/pages/statistics_page.dart` |
| Provider | `lib/features/statistics/presentation/providers/statistics_provider.dart` |

**구성 위젯**:
| 위젯 | 라인 | 설명 |
|------|------|------|
| `_MonthlySummaryCard` | 62-126 | 월별 수입/지출/잔액 요약 |
| `_TypeSelector` | 165-191 | 지출/수입 타입 선택 |
| `_CategoryPieChart` | 194-275 | 카테고리별 파이 차트 |
| `_CategoryList` | 278-359 | 카테고리별 금액 목록 |
| `_MonthlyTrendChart` | 362-489 | 월별 추세 막대 차트 |
| `_DailyTrendChart` | 492-628 | 일별 추세 라인 차트 |

---

### 2.9 예산 페이지 (Budget Page)
**설명**: 월별 예산을 설정하고 사용 현황을 확인합니다.

| 항목 | 위치 |
|------|------|
| 화면 코드 | `lib/features/budget/presentation/pages/budget_page.dart` |
| Provider | `lib/features/budget/presentation/providers/budget_provider.dart` |
| 다이얼로그 | `lib/features/budget/presentation/widgets/add_budget_dialog.dart` |

**구성 위젯**:
- `_BudgetSummaryCard` (라인 206-326): 전체 예산 요약
- `_BudgetList` (라인 329-449): 카테고리별 예산 목록

---

### 2.10 공유 관리 페이지 (Share Management Page)
**설명**: 가계부 공유 멤버 관리 및 초대 기능을 제공합니다.

| 항목 | 위치 |
|------|------|
| 화면 코드 | `lib/features/share/presentation/pages/share_management_page.dart` |
| Provider | `lib/features/share/presentation/providers/share_provider.dart` |
| 라우트 경로 | `/share` |

**탭 구성**:
| 탭 | 클래스 | 라인 | 설명 |
|-----|--------|------|------|
| 멤버 | `_MembersTab` | 79-325 | 현재 가계부 멤버 목록 |
| 받은 초대 | `_ReceivedInvitesTab` | 328-453 | 받은 초대 수락/거절 |
| 보낸 초대 | `_SentInvitesTab` | 456-564 | 보낸 초대 취소 |

---

### 2.11 카테고리 관리 페이지 (Category Management Page)
**설명**: 수입/지출 카테고리를 추가, 수정, 삭제합니다.

| 항목 | 위치 |
|------|------|
| 화면 코드 | `lib/features/category/presentation/pages/category_management_page.dart` |
| Provider | `lib/features/category/presentation/providers/category_provider.dart` |
| 라우트 경로 | `/category` |

**탭 구성**: 지출 / 수입 (TabBar)

---

### 2.12 가계부 관리 페이지 (Ledger Management Page)
**설명**: 여러 가계부를 생성하고 관리합니다.

| 항목 | 위치 |
|------|------|
| 화면 코드 | `lib/features/ledger/presentation/pages/ledger_management_page.dart` |
| 라우트 경로 | `/ledger-manage` |

---

### 2.13 검색 페이지 (Search Page)
**설명**: 메모 기반으로 거래 내역을 검색합니다.

| 항목 | 위치 |
|------|------|
| 화면 코드 | `lib/features/search/presentation/pages/search_page.dart` |
| 라우트 경로 | `/search` |

---

### 2.14 설정 페이지 (Settings Page)
**설명**: 앱 설정, 계정 관리, 로그아웃 기능을 제공합니다.

| 항목 | 위치 |
|------|------|
| 화면 코드 | `lib/features/settings/presentation/pages/settings_page.dart` |
| 라우트 경로 | `/settings` |

**설정 항목**:
- 테마 변경 (라인 30-35)
- 알림 설정 (라인 37-45)
- 프로필 편집 (라인 51-57)
- 비밀번호 변경 (라인 59-63)
- 데이터 내보내기 (라인 71-76)
- 로그아웃 (라인 108-112)
- 회원 탈퇴 (라인 113-117)

---

## 3. 기능별 설명 및 코드 위치

### 3.1 인증 (Authentication)

#### 3.1.1 이메일 로그인
| 항목 | 위치 |
|------|------|
| UI 처리 | `login_page.dart:29-75` |
| Provider | `auth_provider.dart:182-196` |
| Service | `auth_provider.dart:69-89` |

#### 3.1.2 회원가입
| 항목 | 위치 |
|------|------|
| UI 처리 | `signup_page.dart:35-84` |
| Provider | `auth_provider.dart:163-180` |
| Service | `auth_provider.dart:31-66` |

#### 3.1.3 Google 로그인
| 항목 | 위치 |
|------|------|
| UI 처리 | `login_page.dart:77-96` |
| Service | `auth_provider.dart:92-97` |

#### 3.1.4 로그아웃
| 항목 | 위치 |
|------|------|
| UI 처리 | `settings_page.dart:229-254` |
| Provider | `auth_provider.dart:210-218` |

---

### 3.2 가계부 관리 (Ledger)

#### 3.2.1 가계부 목록 조회
| 항목 | 위치 |
|------|------|
| Provider | `ledger_provider.dart:15-26` (`ledgersProvider`) |
| Repository | `ledger_repository.dart` |

#### 3.2.2 가계부 생성
| 항목 | 위치 |
|------|------|
| UI | `ledger_management_page.dart:300-441` (`_LedgerDialog`) |
| Provider | `ledger_provider.dart:70-87` |

#### 3.2.3 가계부 선택/변경
| 항목 | 위치 |
|------|------|
| Provider | `ledger_provider.dart:12` (`selectedLedgerIdProvider`) |
| UI | `home_page.dart:161-196` (`_showLedgerSelector`) |

---

### 3.3 거래 관리 (Transaction)

#### 3.3.1 거래 목록 조회
| 항목 | 위치 |
|------|------|
| Provider | `transaction_provider.dart:16-25` (`dailyTransactionsProvider`) |
| UI | `transaction_list.dart:10-62` |

#### 3.3.2 거래 추가
| 항목 | 위치 |
|------|------|
| UI | `add_transaction_sheet.dart` |
| Provider | `transaction_provider.dart:108-141` |

#### 3.3.3 거래 삭제
| 항목 | 위치 |
|------|------|
| UI | `transaction_list.dart:145-167` |
| Provider | `transaction_provider.dart:175-183` |

---

### 3.4 카테고리 관리 (Category)

#### 3.4.1 카테고리 목록
| 항목 | 위치 |
|------|------|
| Provider | `category_provider.dart:13-19` (`categoriesProvider`) |
| 수입 카테고리 | `category_provider.dart:22-25` (`incomeCategoriesProvider`) |
| 지출 카테고리 | `category_provider.dart:28-31` (`expenseCategoriesProvider`) |

#### 3.4.2 카테고리 추가/수정
| 항목 | 위치 |
|------|------|
| UI | `category_management_page.dart:222-406` (`_CategoryDialog`) |
| Provider | `category_provider.dart:62-79` |

---

### 3.5 예산 관리 (Budget)

#### 3.5.1 예산 목록
| 항목 | 위치 |
|------|------|
| Provider | `budget_provider.dart` (`budgetsProvider`) |
| UI | `budget_page.dart:64-120` |

#### 3.5.2 예산 추가
| 항목 | 위치 |
|------|------|
| UI | `add_budget_dialog.dart` |
| 호출 위치 | `budget_page.dart:127-132` |

---

### 3.6 통계 (Statistics)

#### 3.6.1 카테고리별 통계
| 항목 | 위치 |
|------|------|
| Provider | `statistics_provider.dart` (`categoryStatisticsProvider`) |
| UI | `statistics_page.dart:194-275` (`_CategoryPieChart`) |

#### 3.6.2 월별/일별 추세
| 항목 | 위치 |
|------|------|
| 월별 추세 | `statistics_page.dart:362-489` |
| 일별 추세 | `statistics_page.dart:492-628` |

---

### 3.7 공유 기능 (Share)

#### 3.7.1 멤버 초대
| 항목 | 위치 |
|------|------|
| UI | `share_management_page.dart:567-708` (`_InviteDialog`) |
| Provider | `share_provider.dart` |

#### 3.7.2 초대 수락/거절
| 항목 | 위치 |
|------|------|
| UI | `share_management_page.dart:418-452` |

---

### 3.8 검색 (Search)

| 항목 | 위치 |
|------|------|
| Provider | `search_page.dart:13-30` (`searchResultsProvider`) |
| UI | `search_page.dart:32-131` |

---

## 4. 버튼별 설명 및 코드 위치

### 4.1 AppBar 버튼

#### 4.1.1 검색 버튼 (돋보기 아이콘)
| 항목 | 값 |
|------|------|
| 위치 | `home_page.dart:73-78` |
| 동작 | 검색 페이지로 이동 (`context.push(Routes.search)`) |

#### 4.1.2 설정 버튼 (톱니바퀴 아이콘)
| 항목 | 값 |
|------|------|
| 위치 | `home_page.dart:79-84` |
| 동작 | 설정 페이지로 이동 (`context.push(Routes.settings)`) |

#### 4.1.3 가계부 선택 버튼 (책 아이콘)
| 항목 | 값 |
|------|------|
| 위치 | `home_page.dart:62-70` |
| 동작 | 가계부 선택 바텀시트 표시 (`_showLedgerSelector`) |

---

### 4.2 FloatingActionButton

#### 4.2.1 거래 추가 버튼 (+ 아이콘)
| 항목 | 값 |
|------|------|
| 위치 | `home_page.dart:114-118` |
| 동작 | 거래 추가 바텀시트 표시 |

**코드**:
```dart
FloatingActionButton(
  onPressed: () => _showAddTransactionSheet(context, selectedDate),
  child: const Icon(Icons.add),
)
```

#### 4.2.2 멤버 초대 버튼 (공유 관리 페이지)
| 항목 | 값 |
|------|------|
| 위치 | `share_management_page.dart:55-60` |
| 동작 | 초대 다이얼로그 표시 |

#### 4.2.3 카테고리 추가 버튼
| 항목 | 값 |
|------|------|
| 위치 | `category_management_page.dart:52-56` |
| 동작 | 카테고리 추가 다이얼로그 표시 |

#### 4.2.4 가계부 추가 버튼
| 항목 | 값 |
|------|------|
| 위치 | `ledger_management_page.dart:68-71` |
| 동작 | 가계부 추가 다이얼로그 표시 |

---

### 4.3 더보기 탭 메뉴 버튼

| 버튼 | 위치 | 동작 |
|------|------|------|
| 공유 관리 | `home_page.dart:279-285` | `/share` 페이지로 이동 |
| 카테고리 관리 | `home_page.dart:286-292` | `/category` 페이지로 이동 |
| 가계부 관리 | `home_page.dart:293-300` | `/ledger-manage` 페이지로 이동 |
| 설정 | `home_page.dart:304-310` | `/settings` 페이지로 이동 |
| 로그아웃 | `home_page.dart:311-337` | 로그아웃 확인 다이얼로그 후 로그아웃 처리 |

---

### 4.4 거래 추가 시트 버튼

| 버튼 | 위치 | 동작 |
|------|------|------|
| 취소 버튼 | `add_transaction_sheet.dart:141-143` | 시트 닫기 |
| 저장 버튼 | `add_transaction_sheet.dart:152-161` | 거래 저장 |
| 지출/수입 선택 | `add_transaction_sheet.dart:177-197` | 타입 변경 |
| 날짜 선택 | `add_transaction_sheet.dart:239-247` | DatePicker 표시 |
| 카테고리 칩 | `add_transaction_sheet.dart:306-320` | 카테고리 선택 |

---

### 4.5 설정 페이지 버튼

| 버튼 | 위치 | 동작 |
|------|------|------|
| 테마 변경 | `settings_page.dart:30-35` | 테마 선택 시트 표시 |
| 알림 토글 | `settings_page.dart:37-45` | 알림 On/Off |
| 비밀번호 변경 | `settings_page.dart:59-63` | 비밀번호 재설정 이메일 발송 |
| 로그아웃 | `settings_page.dart:108-112` | 로그아웃 확인 후 처리 |
| 회원 탈퇴 | `settings_page.dart:113-117` | 탈퇴 확인 후 처리 |

---

### 4.6 예산 페이지 버튼

| 버튼 | 위치 | 동작 |
|------|------|------|
| 예산 추가 | `budget_page.dart:36-40` | 예산 추가 다이얼로그 |
| 이전 달 복사 | `budget_page.dart:43-49` | 이전 달 예산 복사 |
| 수정 (PopupMenu) | `budget_page.dart:404-413` | 예산 수정 다이얼로그 |
| 삭제 (PopupMenu) | `budget_page.dart:414-424` | 예산 삭제 확인 |

---

### 4.7 공유 관리 페이지 버튼

| 버튼 | 위치 | 동작 |
|------|------|------|
| 초대하기 FAB | `share_management_page.dart:55-60` | 초대 다이얼로그 표시 |
| 초대 수락 | `share_management_page.dart:400-405` | 초대 수락 처리 |
| 초대 거절 | `share_management_page.dart:395-398` | 초대 거절 처리 |
| 멤버 역할 변경 | `share_management_page.dart:255-280` | 관리자/멤버 전환 |
| 멤버 내보내기 | `share_management_page.dart:282-324` | 멤버 제거 |

---

## 5. 기능 흐름도 (Flow)

### 5.1 앱 시작 Flow

```
앱 시작
    │
    ▼
┌─────────────────────────────────┐
│  main.dart                      │
│  - Supabase 초기화              │
│  - ProviderScope으로 앱 감싸기   │
└─────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────┐
│  SplashPage (router.dart:139)   │
│  - 1초 대기                     │
│  - authStateProvider 확인       │
└─────────────────────────────────┘
    │
    ├─── 로그인됨 ──▶ HomePage (/home)
    │
    └─── 로그인 안됨 ──▶ LoginPage (/login)
```

### 5.2 로그인 Flow

```
LoginPage
    │
    ├─── [이메일 로그인]
    │        │
    │        ▼
    │    _handleEmailLogin()
    │        │
    │        ▼
    │    authNotifierProvider.signInWithEmail()
    │        │
    │        ▼
    │    AuthService.signInWithEmail()
    │        │
    │        ▼
    │    Supabase Auth (signInWithPassword)
    │        │
    │        ▼
    │    authStateProvider 업데이트
    │        │
    │        ▼
    │    context.go(Routes.home)
    │
    └─── [Google 로그인]
             │
             ▼
         _handleGoogleLogin()
             │
             ▼
         AuthService.signInWithGoogle()
             │
             ▼
         OAuth 리다이렉트
```

### 5.3 거래 추가 Flow

```
HomePage (FAB 버튼 클릭)
    │
    ▼
┌─────────────────────────────────┐
│  _showAddTransactionSheet()     │
│  (home_page.dart:152-159)       │
└─────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────┐
│  AddTransactionSheet            │
│  - 타입 선택 (수입/지출)         │
│  - 금액 입력                    │
│  - 날짜 선택                    │
│  - 카테고리 선택                │
│  - 메모 입력                    │
└─────────────────────────────────┘
    │
    ▼ [저장 버튼]
┌─────────────────────────────────┐
│  _submit()                      │
│  (add_transaction_sheet.dart:60)│
└─────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────┐
│  transactionNotifierProvider    │
│  .createTransaction()           │
│  (transaction_provider.dart:108)│
└─────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────┐
│  TransactionRepository          │
│  .createTransaction()           │
└─────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────┐
│  Supabase DB INSERT             │
└─────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────┐
│  Provider 갱신 (invalidate)     │
│  - dailyTransactionsProvider    │
│  - monthlyTransactionsProvider  │
│  - monthlyTotalProvider         │
│  - dailyTotalsProvider          │
└─────────────────────────────────┘
    │
    ▼
UI 자동 업데이트
```

### 5.4 가계부 공유 초대 Flow

```
ShareManagementPage (FAB 클릭)
    │
    ▼
┌─────────────────────────────────┐
│  _InviteDialog 표시             │
│  - 이메일 입력                  │
│  - 역할 선택 (멤버/관리자)       │
└─────────────────────────────────┘
    │
    ▼ [초대 버튼]
┌─────────────────────────────────┐
│  shareNotifierProvider          │
│  .sendInvite()                  │
└─────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────┐
│  ShareRepository.sendInvite()   │
│  Supabase ledger_invites INSERT │
└─────────────────────────────────┘
    │
    ▼
초대받은 사용자 앱
    │
    ▼
┌─────────────────────────────────┐
│  receivedInvitesProvider로 조회 │
│  _ReceivedInvitesTab에서 표시   │
└─────────────────────────────────┘
    │
    ├─── [수락]
    │        │
    │        ▼
    │    shareNotifierProvider.acceptInvite()
    │        │
    │        ▼
    │    ledger_members에 추가
    │        │
    │        ▼
    │    가계부 접근 가능
    │
    └─── [거절]
             │
             ▼
         shareNotifierProvider.rejectInvite()
             │
             ▼
         초대 상태 업데이트
```

### 5.5 날짜별 거래 조회 Flow

```
캘린더에서 날짜 선택 (CalendarView)
    │
    ▼
┌─────────────────────────────────┐
│  onDaySelected 콜백             │
│  (calendar_view.dart:95-97)     │
└─────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────┐
│  selectedDateProvider 업데이트  │
│  (home_page.dart:94-96)         │
└─────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────┐
│  dailyTransactionsProvider      │
│  자동 재조회 (watch 의존성)      │
│  (transaction_provider.dart:16) │
└─────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────┐
│  TransactionRepository          │
│  .getTransactionsByDate()       │
└─────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────┐
│  Supabase Query                 │
│  SELECT * FROM transactions     │
│  WHERE ledger_id = ? AND date = ?│
└─────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────┐
│  TransactionList 위젯 업데이트   │
│  (transaction_list.dart)        │
└─────────────────────────────────┘
```

### 5.6 데이터 계층 Flow (Clean Architecture)

```
┌───────────────────────────────────────────────────────────────┐
│                    Presentation Layer (UI)                     │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐        │
│  │   Page      │ ◀─▶│   Widget    │ ◀─▶│   Provider  │        │
│  └─────────────┘    └─────────────┘    └─────────────┘        │
│         │                                     │                │
│         ▼                                     ▼                │
│  사용자 인터랙션                         상태 관리 및            │
│  (버튼 클릭, 입력 등)                    비즈니스 로직 호출      │
└───────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌───────────────────────────────────────────────────────────────┐
│                      Data Layer                                │
│  ┌─────────────────────────────────────────────────────┐      │
│  │                   Repository                         │      │
│  │  - Supabase 클라이언트를 통해 데이터 CRUD 수행         │      │
│  │  - JSON 데이터를 Model로 변환                         │      │
│  └─────────────────────────────────────────────────────┘      │
│                              │                                 │
│                              ▼                                 │
│  ┌─────────────────────────────────────────────────────┐      │
│  │                     Model                            │      │
│  │  - fromJson(): JSON → Dart 객체                      │      │
│  │  - toJson(): Dart 객체 → JSON                        │      │
│  └─────────────────────────────────────────────────────┘      │
└───────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌───────────────────────────────────────────────────────────────┐
│                     Domain Layer                               │
│  ┌─────────────────────────────────────────────────────┐      │
│  │                    Entity                            │      │
│  │  - 순수한 비즈니스 모델 정의                          │      │
│  │  - UI나 DB에 의존하지 않음                           │      │
│  └─────────────────────────────────────────────────────┘      │
└───────────────────────────────────────────────────────────────┘
```

---

## 부록: 빠른 참조

### Provider 목록

| Provider | 파일 위치 | 용도 |
|----------|-----------|------|
| `authStateProvider` | `auth_provider.dart:8` | 인증 상태 스트림 |
| `currentUserProvider` | `auth_provider.dart:13` | 현재 사용자 |
| `ledgersProvider` | `ledger_provider.dart:15` | 가계부 목록 |
| `selectedLedgerIdProvider` | `ledger_provider.dart:12` | 선택된 가계부 ID |
| `currentLedgerProvider` | `ledger_provider.dart:29` | 현재 가계부 |
| `dailyTransactionsProvider` | `transaction_provider.dart:16` | 일별 거래 |
| `monthlyTransactionsProvider` | `transaction_provider.dart:28` | 월별 거래 |
| `categoriesProvider` | `category_provider.dart:13` | 카테고리 목록 |
| `budgetsProvider` | `budget_provider.dart` | 예산 목록 |
| `searchResultsProvider` | `search_page.dart:13` | 검색 결과 |

### 라우트 상수

| 상수 | 경로 | 페이지 |
|------|------|--------|
| `Routes.splash` | `/` | SplashPage |
| `Routes.login` | `/login` | LoginPage |
| `Routes.signup` | `/signup` | SignupPage |
| `Routes.home` | `/home` | HomePage |
| `Routes.search` | `/search` | SearchPage |
| `Routes.settings` | `/settings` | SettingsPage |
| `Routes.share` | `/share` | ShareManagementPage |
| `Routes.category` | `/category` | CategoryManagementPage |
| `Routes.ledgerManage` | `/ledger-manage` | LedgerManagementPage |

---

이 가이드가 프로젝트 이해에 도움이 되길 바랍니다!
