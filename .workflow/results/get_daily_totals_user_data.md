# getDailyTotals 메서드 개선 - 사용자별 데이터 포함

## 상태
완료

## 작업 개요
TransactionRepository의 getDailyTotals 메서드를 수정하여 사용자별 거래 데이터를 포함하도록 개선했습니다. 기존에는 일별 총 수입/지출만 제공했지만, 이제는 각 사용자별 수입/지출 및 사용자 색상 정보를 함께 제공합니다.

## 생성/수정 파일

### 수정된 파일
- `/Users/eungyu/Desktop/개인/project/house-hold-account/lib/features/transaction/data/repositories/transaction_repository.dart`
  - getDailyTotals 메서드 수정: 반환 타입 변경 및 사용자별 데이터 그룹화 로직 추가
  - profiles 테이블과 조인하여 사용자 색상 정보 조회

- `/Users/eungyu/Desktop/개인/project/house-hold-account/lib/features/transaction/presentation/providers/transaction_provider.dart`
  - dailyTotalsProvider 반환 타입 변경: `Map<DateTime, Map<String, int>>` → `Map<DateTime, Map<String, dynamic>>`

- `/Users/eungyu/Desktop/개인/project/house-hold-account/lib/features/ledger/presentation/widgets/calendar_view.dart`
  - _buildDayCell 메서드 수정: 새로운 데이터 구조에서 totalIncome, totalExpense 추출

### 생성된 파일
- `/Users/eungyu/Desktop/개인/project/house-hold-account/test/features/transaction/data/repositories/daily_totals_logic_test.dart`
  - 데이터 그룹화 로직에 대한 유닛 테스트 4개 작성
  - 모든 테스트 통과 확인

## 데이터 구조 변경

### 변경 전
```dart
Future<Map<DateTime, Map<String, int>>> getDailyTotals({
  required String ledgerId,
  required int year,
  required int month,
}) async {
  // 반환값:
  // {
  //   DateTime(2026, 1, 15): {
  //     'income': 50000,
  //     'expense': 30000
  //   }
  // }
}
```

### 변경 후
```dart
Future<Map<DateTime, Map<String, dynamic>>> getDailyTotals({
  required String ledgerId,
  required int year,
  required int month,
}) async {
  // 반환값:
  // {
  //   DateTime(2026, 1, 15): {
  //     'users': {
  //       'user1_id': {
  //         'income': 50000,
  //         'expense': 10000,
  //         'color': '#A8D8EA'
  //       },
  //       'user2_id': {
  //         'income': 0,
  //         'expense': 20000,
  //         'color': '#FFB6A3'
  //       }
  //     },
  //     'totalIncome': 50000,
  //     'totalExpense': 30000
  //   }
  // }
}
```

## 주요 구현 사항

### 1. Supabase JOIN 쿼리
```dart
final response = await _client
    .from('transactions')
    .select('*, profiles!user_id(color)')
    .eq('ledger_id', ledgerId)
    .gte('date', startStr)
    .lte('date', endStr)
    .order('date', ascending: true);
```

### 2. 사용자별 데이터 그룹화
- 일별, 사용자별로 거래를 2단계로 그룹화
- 각 사용자의 수입/지출을 별도로 누적
- 전체 totalIncome, totalExpense도 함께 계산

### 3. 색상 정보 처리
- profiles 테이블에서 사용자 색상 조회
- null인 경우 기본 색상 '#A8D8EA' 사용
- 마이그레이션 파일 `006_add_profile_color.sql` 참조

### 4. 에러 처리
- CLAUDE.md의 에러 처리 원칙 준수
- try-catch로 에러를 잡고 rethrow하여 상위 레이어까지 전파

## 테스트 결과

### 유닛 테스트 (4개)
1. 사용자별 거래 데이터가 일별로 올바르게 그룹화되어야 한다
2. profile에 color가 없는 경우 기본 색상을 사용해야 한다
3. 여러 날짜의 거래가 올바르게 그룹화되어야 한다
4. totalIncome과 totalExpense가 사용자별 합계와 일치해야 한다

**결과**: 모든 테스트 통과 (4/4)

### 전체 테스트
**결과**: 36개 테스트 모두 통과

### 정적 분석
```bash
flutter analyze
```
**결과**: No issues found!

## 호환성 확인

### CalendarView 위젯
- 기존 코드에서 `totals['income']`, `totals['expense']` 사용
- 새 코드에서 `totals['totalIncome']`, `totals['totalExpense']` 사용
- 정상 동작 확인

### TransactionProvider
- dailyTotalsProvider의 반환 타입만 변경
- 기존 사용처는 CalendarView만 있으므로 안전하게 수정됨

## 향후 활용 방안

이 데이터 구조를 활용하여 다음 기능을 구현할 수 있습니다:

1. **캘린더 UI 개선**
   - 각 날짜 셀에 사용자별 색상 점 표시
   - 사용자별 금액 비율 시각화

2. **통계 기능**
   - 월별 사용자별 지출 비교
   - 사용자별 카테고리 분석

3. **공유 가계부 인사이트**
   - 누가 더 많이 지출했는지 비교
   - 수입 기여도 분석

## 참고 파일
- 마이그레이션: `/Users/eungyu/Desktop/개인/project/house-hold-account/supabase/migrations/006_add_profile_color.sql`
- 테스트: `/Users/eungyu/Desktop/개인/project/house-hold-account/test/features/transaction/data/repositories/daily_totals_logic_test.dart`

## 다음 단계 제안

1. CalendarView 위젯에서 사용자별 색상 점 표시 구현
2. 일별 상세 뷰에서 사용자별 거래 분리 표시
3. 월별 사용자별 통계 페이지 추가
