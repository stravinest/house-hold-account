# 캘린더 관련 코드 탐색 분석 결과

## 1. CalendarView 위젯 위치 및 구조

**파일 경로**: `lib/features/ledger/presentation/widgets/calendar_view.dart`

**위젯 구성**:
- `CalendarView` (ConsumerWidget) - 메인 캘린더 위젯
- `_MonthSummary` (StatelessWidget) - 월별 수입/지출/합계 요약
- `_CustomCalendarHeader` (StatelessWidget) - 커스텀 헤더 (월 표시, 네비게이션)
- 내부 메서드 `_buildDayCell()` - 날짜 셀 렌더링

## 2. 캘린더 헤더 구조

**_CustomCalendarHeader 위젯** (313-364행):

```dart
구성요소:
- 오늘 버튼 (TextButton.icon)
  - 아이콘: Icons.today
  - 라벨: '오늘'
  - 현재 월과 오늘 월이 같으면 비활성화

- 월 타이틀 (DateFormat 사용)
  - 포맷: 'yyyy년 M월' (예: "2026년 1월")
  - 한국어 로케일 (ko_KR)

- 이전/다음 월 버튼 (IconButton)
  - 아이콘: Icons.chevron_left / chevron_right
  - onPreviousMonth: DateTime(year, month - 1)
  - onNextMonth: DateTime(year, month + 1)
```

**네비게이션 흐름**:
- 오늘 버튼 → `onDateSelected` + `onPageChanged` 콜백 호출
- 이전/다음 버튼 → `onPageChanged` 콜백만 호출

## 3. CalendarDayCell 렌더링 로직

**_buildDayCell 메서드** (146-219행):

```dart
입력 파라미터:
- day: DateTime
- dailyTotals: Map<DateTime, Map<String, int>>
  예: {DateTime(2026,1,6): {'income': 50000, 'expense': 30000}}
- isSelected: bool
- isToday: bool
- colorScheme: ColorScheme
- currentLedger: Ledger?

렌더링 구조:
Container
├─ 배경색: 선택/오늘 상태에 따라 결정
├─ 테두리: 거래 데이터가 있을 때만 표시
└─ Column (중앙 정렬)
   ├─ Text: 날짜 (14px, 굵기 조정)
   └─ 점 또는 Spacer
      ├─ 거래 있음: 6x6px 원형 점
      └─ 거래 없음: 빈 SizedBox(height: 6)
```

**색상 결정 로직**:
```dart
1. 배경색:
   - isSelected: colorScheme.primary
   - isToday: colorScheme.primaryContainer
   - 기본: null (투명)

2. 텍스트 색상:
   - isSelected: colorScheme.onPrimary
   - isToday: colorScheme.onPrimaryContainer
   - 주말(토,일): colorScheme.error
   - 평일: colorScheme.onSurface

3. 점 색상:
   - isSelected: colorScheme.onPrimary (흰색)
   - 개인 가계부: colorScheme.primary (초록색 테마)
   - 공유 가계부: Colors.green (밝은 녹색)
```

## 4. 거래 데이터를 캘린더에 표시하는 방식

**데이터 흐름**:
```
TransactionRepository.getDailyTotals()
        ↓
dailyTotalsProvider (FutureProvider)
        ↓
CalendarView.build() 에서 watch
        ↓
_buildDayCell() 에 전달
        ↓
점 인디케이터 렌더링
```

**getDailyTotals 구현** (TransactionRepository, 185-212행):
```dart
- 월별 거래 조회 → getTransactionsByMonth() 호출
- 일별로 그룹화: Map<DateTime, Map<String, int>>
- 각 날짜별로 {'income': 합계, 'expense': 합계} 계산
- 날짜 정규화: DateTime(year, month, day) - 시간 제거
```

**월별 요약 표시** (_MonthSummary, 223-274행):
```dart
- monthlyTotalProvider watch
- 3개 항목 표시:
  1. 수입 (파란색 - Colors.blue)
  2. 지출 (빨간색 - Colors.red)
  3. 합계 (양수: 녹색, 음수: 빨간색)
- NumberFormat 사용: '#,###' 포맷 (예: "1,000,000")
```

## 5. 현재 사용되는 색상 스키마

**Material Design 3 기반**:
```dart
설정 파일: lib/shared/themes/app_theme.dart

시드 색상: Color(0xFF2E7D32) - 초록색

Light 테마 (ColorScheme.fromSeed):
- primary: 초록색 계열
- primaryContainer: 밝은 초록색
- error: 빨간색 (주말)
- onSurface: 검은색
- onPrimaryContainer: 어두운 색

Dark 테마: 다크 모드에서도 동일한 구조
```

**캘린더 색상 매핑**:
```
거래 표시:
- 수입: Colors.blue (파란색)
- 지출: Colors.red (빨간색)
- 합계: Colors.green (양수) / Colors.red (음수)

가계부 구분:
- 개인 가계부 점: colorScheme.primary (초록색)
- 공유 가계부 점: Colors.green (밝은 녹색)

선택 상태:
- 선택된 날짜: primary 배경
- 오늘: primaryContainer 배경
- 주말: error 색상 텍스트
```

## 6. 캘린더와 연동된 Provider

**주요 Provider들**:

### TransactionProvider (`lib/features/transaction/presentation/providers/transaction_provider.dart`):
```dart
1. dailyTotalsProvider (FutureProvider)
   - 캘린더에 표시할 일별 합계 제공
   - 의존성: selectedLedgerId, selectedDate
   - 반환: Map<DateTime, Map<String, int>>

2. monthlyTotalProvider (FutureProvider)
   - 월별 요약 정보 제공
   - 반환: {'income': int, 'expense': int, 'balance': int}

3. dailyTransactionsProvider (FutureProvider)
   - 선택된 날짜의 거래 목록
   - 반환: List<Transaction>

4. transactionNotifierProvider (StateNotifierProvider)
   - 거래 생성/수정/삭제 처리
   - invalidate: dailyTotalsProvider, monthlyTotalProvider 등
```

### LedgerProvider (`lib/features/ledger/presentation/providers/ledger_provider.dart`):
```dart
1. currentLedgerProvider (FutureProvider)
   - 현재 선택된 가계부 정보
   - 반환: Ledger? { id, name, isShared, ... }

2. selectedLedgerIdProvider (StateProvider)
   - 사용자가 선택한 가계부 ID
   - 타입: String?

3. ledgerNotifierProvider (StateNotifierProvider)
   - 가계부 CRUD 작업
   - createLedger, updateLedger, deleteLedger, selectLedger
```

## 7. 사용자별 색상 표시를 위해 수정이 필요한 부분

### 현재 상태:
- 캘린더의 점 색상: 가계부 유형별(개인/공유)로만 구분
- 거래 카드의 사용자명: 회색 텍스트로 표시만 함
- 색상 구분: 사용자별이 아닌 거래 타입(수입/지출)별

### 사용자별 색상 구현을 위한 수정 위치:

#### 1. Transaction 엔티티 확장 필요
```
현재: userId (ID만 저장)
필요: userId 기반 사용자 색상 매핑
```

#### 2. 캘린더 점 색상 로직 수정 (calendar_view.dart, 164-167행)
```dart
현재 코드:
final dotColor = currentLedger?.isShared == true
    ? Colors.green
    : colorScheme.primary;

필요 수정:
- dailyTotalsProvider에 사용자별 데이터 포함
- 또는 Transaction 목록에서 사용자별 색상 계산
- 예: {'user1_id': Colors.blue, 'user2_id': Colors.red}
```

#### 3. TransactionRepository.getDailyTotals() 수정 (transaction_repository.dart, 185-212행)
```dart
현재: 단순히 income/expense 합계만 계산
필요: 사용자별 거래 분리
반환값: Map<DateTime, Map<String, dynamic>>
예: {
  DateTime(...): {
    'users': {
      'user1_id': {'income': 0, 'expense': 10000, 'color': '#A8D8EA'},
      'user2_id': {'income': 5000, 'expense': 0, 'color': '#FFB6A3'}
    }
  }
}
```

#### 4. 거래 카드에 사용자 색상 표시 (transaction_list.dart, 228-237행)
```
현재: userName을 회색(outline)으로만 표시
필요: userId 기반 색상 배경 추가
예: 사용자별 아바타 색상 원형 배지
```

#### 5. 캘린더 헤더에 사용자 프로필 표시 필요
```
새 위젯: UserProfileSummary
위치: CalendarView 상단 (월 표시 아래)
기능:
- 각 사용자의 프로필 사진 (또는 이니셜)
- 사용자 색상 테두리
- 월별 총 지출/수입 합계
```

## 8. 권장 구현 순서

### Phase 1: 데이터 레이어
1. profiles 테이블에 color 컬럼 추가
2. AuthService에 색상 조회/업데이트 메서드 추가
3. TransactionRepository.getDailyTotals() 수정 (사용자 정보 포함)

### Phase 2: 프레젠테이션 레이어
1. 색상 관리 Provider 추가 (userColorProvider)
2. CalendarView의 _buildDayCell() 수정 (사용자별 점 표시)
3. UserProfileSummary 위젯 생성

### Phase 3: UI 레이어
1. 설정 화면에 ColorPicker 추가
2. 거래 카드에 사용자 색상 배지 추가
3. 캘린더 헤더에 UserProfileSummary 통합

## 최종 요약

**캘린더 아키텍처**:
- TableCalendar 라이브러리 기반
- Riverpod 상태관리로 데이터 제공
- Provider 기반 자동 새로고침
- Material Design 3 테마 적용

**현재 색상 체계**:
- 가계부 유형 구분 (개인/공유)
- 거래 유형 구분 (수입/지출)
- 테마 기반 자동 색상 관리

**사용자별 색상 추가 시 핵심 변경사항**:
1. dailyTotals 데이터 구조 확장 (사용자 정보 포함)
2. _buildDayCell() 로직 수정 (사용자별 색상)
3. 캘린더 헤더에 사용자 프로필 표시
4. 색상 관리 Provider 및 설정 UI 추가
