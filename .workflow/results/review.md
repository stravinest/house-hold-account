# 코드 리뷰 결과 - Phase 2: 카테고리 및 거래 추가 UI 개선

## 요약
- 검토 파일: 5개
- Critical: 2개 / High: 3개 / Medium: 2개 / Low: 1개

---

## Critical 이슈

### [transaction.dart:82-126] copyWith 메서드의 nullable 필드 처리 버그
- **문제**: `categoryId`와 `paymentMethodId`를 `null`로 설정할 수 없음. `null`을 전달해도 기존 값이 유지되는 버그 존재
- **위험**: 사용자가 카테고리를 "선택 안함"으로 변경하려 해도 적용되지 않음. 데이터 무결성 문제 발생 가능
- **해결**: nullable 필드를 명시적으로 null로 설정할 수 있도록 패턴 변경 필요

```dart
// 현재 코드 (문제)
Transaction copyWith({
  String? categoryId,  // null 전달 시 구분 불가능
  // ...
}) {
  return Transaction(
    categoryId: categoryId ?? this.categoryId,  // null 전달해도 기존 값 유지
    // ...
  );
}

// 수정 방법 1: Optional 패턴 사용
class Optional<T> {
  final T? value;
  final bool isSet;
  const Optional(this.value) : isSet = true;
  const Optional.unset() : value = null, isSet = false;
}

Transaction copyWith({
  Optional<String>? categoryId,
  Optional<String>? paymentMethodId,
  // ...
}) {
  return Transaction(
    categoryId: categoryId != null && categoryId.isSet 
        ? categoryId.value 
        : this.categoryId,
    // ...
  );
}

// 수정 방법 2: 별도 메서드 제공
Transaction clearCategory() {
  return copyWith().._categoryId = null;
}
```

### [transaction_provider.dart:108-143] createTransaction 메서드의 파라미터 시그니처 불일치
- **문제**: `categoryId`가 `required`로 선언되어 있지만, nullable 변경 사항이 반영되지 않음
- **위험**: 컴파일 에러는 없지만 nullable 정책과 불일치. UI에서 null 전달이 불가능할 수 있음
- **해결**: 파라미터를 nullable로 변경

```dart
// 현재 코드
Future<Transaction> createTransaction({
  required String categoryId,  // nullable이어야 함
  // ...
}) async {

// 수정 코드
Future<Transaction> createTransaction({
  String? categoryId,  // nullable로 변경
  // ...
}) async {
```

---

## High 이슈

### [add_transaction_sheet.dart:101-111] 에러 처리 원칙 위반 (rethrow 누락)
- **문제**: `_submit()` 메서드에서 `createTransaction` 호출 시 에러를 catch하지만 rethrow하지 않음
- **위험**: Provider의 에러 상태가 UI에 전파되지 않아 일관성 없는 에러 처리 발생 가능
- **해결**: CLAUDE.md의 에러 처리 원칙에 따라 rethrow 추가

```dart
// 현재 코드
try {
  await ref.read(transactionNotifierProvider.notifier).createTransaction(
    // ...
  );
  // 성공 처리
} catch (e) {
  // SnackBar만 표시하고 끝
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('오류: $e')),
    );
  }
} finally {
  // ...
}

// 수정 코드
try {
  await ref.read(transactionNotifierProvider.notifier).createTransaction(
    // ...
  );
  if (mounted) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('거래가 추가되었습니다')),
    );
  }
} catch (e, st) {
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('오류: $e')),
    );
  }
  // UI는 에러를 표시했지만, provider 상태와 동기화를 위해 rethrow
  // 단, 이 경우는 UI가 최종 처리자이므로 rethrow 불필요할 수도 있음
  // 프로젝트 정책에 따라 결정 필요
}
```

**재검토 필요**: 이 케이스는 UI가 최종 에러 처리자이므로 rethrow가 필수는 아님. 프로젝트의 에러 처리 일관성 정책 재확인 필요

### [category_provider.dart:62-100] CategoryNotifier의 일관성 없는 에러 처리
- **문제**: `createCategory`, `updateCategory`, `deleteCategory` 메서드에서 에러를 catch하지 않아 rethrow가 없음
- **위험**: 에러 발생 시 state가 업데이트되지 않고, UI에서 적절한 피드백을 못 받을 수 있음
- **해결**: PaymentMethodNotifier 패턴처럼 try-catch-rethrow 추가

```dart
// 참고: PaymentMethodNotifier의 올바른 패턴
Future<PaymentMethod> createPaymentMethod({
  required String name,
  String icon = '',
  String color = '#6750A4',
}) async {
  if (_ledgerId == null) throw Exception('가계부를 선택해주세요');

  try {
    final paymentMethod = await _repository.createPaymentMethod(
      ledgerId: _ledgerId,
      name: name,
      icon: icon,
      color: color,
    );

    _ref.invalidate(paymentMethodsProvider);
    await loadPaymentMethods();
    return paymentMethod;
  } catch (e, st) {
    state = AsyncValue.error(e, st);
    rethrow;  // 에러 전파
  }
}

// CategoryNotifier도 동일하게 수정 필요
Future<Category> createCategory({
  required String name,
  required String icon,
  required String color,
  required String type,
}) async {
  if (_ledgerId == null) throw Exception('가계부를 선택해주세요');

  try {
    final category = await _repository.createCategory(
      ledgerId: _ledgerId,
      name: name,
      icon: icon,
      color: color,
      type: type,
    );
    await loadCategories();
    return category;
  } catch (e, st) {
    state = AsyncValue.error(e, st);
    rethrow;
  }
}
```

### [add_transaction_sheet.dart:490-521, 721-750] 카테고리/결제수단 추가 다이얼로그의 에러 처리 부족
- **문제**: `createCategory` 및 `createPaymentMethod` 호출 시 에러를 catch하지만, state 업데이트 없이 SnackBar만 표시
- **위험**: Provider의 에러 상태와 UI가 동기화되지 않음
- **해결**: 에러 발생 시에도 UI를 닫지 말고 사용자가 수정할 수 있도록 유지

```dart
// 현재 코드 (490-521줄)
try {
  final newCategory = await ref
      .read(categoryNotifierProvider.notifier)
      .createCategory(/* ... */);

  setState(() => _selectedCategory = newCategory);

  if (dialogContext.mounted) {
    Navigator.pop(dialogContext);  // 성공 시 다이얼로그 닫기
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('카테고리가 추가되었습니다')),
    );
  }
  // provider 갱신
} catch (e) {
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('오류: $e')),
    );
  }
  // 다이얼로그를 닫지 않아 사용자가 재시도 가능 - 이 부분은 양호
}

// 개선 제안: 다이얼로그 내 로딩 상태 표시 추가
// StatefulBuilder 내부에 isLoading 상태 추가하여 중복 클릭 방지
```

---

## Medium 이슈

### [add_transaction_sheet.dart:386-387] 하드코딩된 아이콘 및 색상 배열
- **문제**: 아이콘과 색상이 코드에 직접 하드코딩되어 있어 유지보수성 저하
- **위험**: 아이콘/색상 변경 시 여러 곳 수정 필요 (카테고리, 결제수단 각각)
- **해결**: 상수 파일로 분리하여 재사용성 향상

```dart
// lib/core/constants/ui_constants.dart 생성
class UIConstants {
  static const categoryIcons = ['🍽️', '🚗', '🏠', '💊', '🎮', '👔', '📚', '✈️'];
  static const categoryColors = [
    '#4CAF50', '#2196F3', '#F44336', '#FF9800', 
    '#9C27B0', '#00BCD4', '#E91E63', '#795548'
  ];
  
  static const paymentMethodIcons = ['💳', '💰', '🏦', '📱', '🪙', '💵', '💴', '💶'];
  static const paymentMethodColors = [
    '#6750A4', '#2196F3', '#4CAF50', '#FF9800',
    '#E91E63', '#00BCD4', '#9C27B0', '#795548'
  ];
}

// add_transaction_sheet.dart에서 사용
final icons = UIConstants.categoryIcons;
final colors = UIConstants.categoryColors;
```

### [004_make_category_nullable.sql:1-10] 마이그레이션 롤백 스크립트 미제공
- **문제**: ALTER TABLE 문만 있고 롤백 방법이 없음
- **위험**: 프로덕션에서 문제 발생 시 신속한 롤백 불가능
- **해결**: DOWN 마이그레이션 스크립트 추가

```sql
-- UP migration (현재 내용)
ALTER TABLE transactions ALTER COLUMN category_id DROP NOT NULL;

-- DOWN migration (추가 필요 - 별도 파일로 관리)
-- 주의: category_id가 NULL인 레코드가 있으면 실패함
-- 사전에 NULL 값을 처리하는 로직 필요
UPDATE transactions SET category_id = '기본_카테고리_ID' WHERE category_id IS NULL;
ALTER TABLE transactions ALTER COLUMN category_id SET NOT NULL;
```

---

## Low 이슈

### [add_transaction_sheet.dart:214-232] 지출명/수입명 필드의 중복 코드
- **문제**: labelText, hintText, validator 메시지가 동적으로 생성되지만 패턴이 반복됨
- **위험**: 낮음. 가독성 저하 정도
- **해결**: 변수로 추출하여 가독성 향상

```dart
// 현재 코드
TextFormField(
  controller: _memoController,
  decoration: InputDecoration(
    labelText: _type == 'expense' ? '지출명' : '수입명',
    hintText: _type == 'expense' ? '예: 점심식사, 커피' : '예: 월급, 용돈',
    // ...
  ),
  validator: (value) {
    if (value == null || value.trim().isEmpty) {
      return _type == 'expense' ? '지출명을 입력해주세요' : '수입명을 입력해주세요';
    }
    return null;
  },
),

// 개선 코드
final isExpense = _type == 'expense';
final transactionLabel = isExpense ? '지출명' : '수입명';
final transactionHint = isExpense ? '예: 점심식사, 커피' : '예: 월급, 용돈';

TextFormField(
  controller: _memoController,
  decoration: InputDecoration(
    labelText: transactionLabel,
    hintText: transactionHint,
    // ...
  ),
  validator: (value) {
    if (value == null || value.trim().isEmpty) {
      return '$transactionLabel을 입력해주세요';
    }
    return null;
  },
),
```

---

## 긍정적인 점

1. **UI/UX 개선**: 레이아웃 순서 변경이 직관적이며, 금액 입력 시 자동 포커스 선택 기능이 사용성을 크게 향상시킴
2. **인라인 추가/삭제 기능**: 거래 추가 중 카테고리/결제수단을 즉시 관리할 수 있어 사용자 흐름이 매끄러움
3. **nullable 처리 일관성**: DB 스키마부터 Entity, Model, Repository까지 nullable 변경이 일관되게 적용됨
4. **금액 입력 포맷터**: 천 단위 구분 기호 자동 적용으로 가독성 향상
5. **PaymentMethodNotifier의 에러 처리**: rethrow 패턴을 올바르게 구현하여 CLAUDE.md 원칙 준수
6. **삭제 확인 다이얼로그**: 사용자 실수 방지를 위한 확인 절차 포함

---

## 추가 권장사항

### 1. 테스트 추가
- **단위 테스트**: `TransactionModel.toCreateJson()`에서 `categoryId: null` 케이스 테스트
- **위젯 테스트**: "선택 안함" 선택 후 거래 생성 시나리오
- **통합 테스트**: 카테고리 null 상태로 저장 -> 조회 -> 수정 플로우

```dart
// test/features/transaction/data/models/transaction_model_test.dart
test('toCreateJson should handle null categoryId', () {
  final json = TransactionModel.toCreateJson(
    ledgerId: 'ledger-1',
    categoryId: null,  // null 케이스
    userId: 'user-1',
    amount: 10000,
    type: 'expense',
    date: DateTime(2024, 1, 1),
  );
  
  expect(json['category_id'], isNull);
});
```

### 2. 에러 메시지 개선
현재 `catch (e)` 블록에서 `SnackBar(content: Text('오류: $e'))`로 표시하는데, Supabase 에러는 기술적이고 길 수 있음. 사용자 친화적인 메시지로 변환하는 유틸리티 추가 권장

```dart
// lib/core/utils/error_message.dart
class ErrorMessage {
  static String getUserFriendly(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    
    if (errorStr.contains('foreign key') || errorStr.contains('violates')) {
      return '다른 거래에서 사용 중인 항목은 삭제할 수 없습니다';
    }
    if (errorStr.contains('duplicate')) {
      return '이미 존재하는 이름입니다';
    }
    if (errorStr.contains('network')) {
      return '네트워크 연결을 확인해주세요';
    }
    
    return '오류가 발생했습니다. 다시 시도해주세요';
  }
}

// 사용
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text(ErrorMessage.getUserFriendly(e))),
);
```

### 3. 카테고리/결제수단 선택 UX 개선
현재 FilterChip을 사용하는데, 항목이 많아지면 스크롤이 어려울 수 있음. GridView로 변경하거나 검색 기능 추가 고려

### 4. 접근성(a11y) 개선
- 아이콘 선택 시 Semantics 레이블 추가
- 색상 선택 시 색약자를 위한 텍스트 힌트 추가

### 5. 마이그레이션 문서화
`supabase/migrations/README.md` 생성하여 각 마이그레이션의 목적과 주의사항 문서화

---

## 우선순위 요약

**즉시 수정 필요 (Critical)**
1. `Transaction.copyWith()` nullable 필드 처리 버그 수정
2. `TransactionNotifier.createTransaction()` 파라미터 시그니처 수정

**수정 권장 (High)**
1. `CategoryNotifier`에 try-catch-rethrow 패턴 추가
2. 에러 처리 일관성 정책 재확인 및 문서화

**개선 권장 (Medium/Low)**
1. 하드코딩된 상수 분리
2. 마이그레이션 롤백 스크립트 추가
3. 에러 메시지 사용자 친화적으로 개선

---

---

# 코드 리뷰 결과 - AssetCategoryList Redesign

## 요약
- 검토 파일: 1개 (asset_category_list.dart)
- Critical: 0개
- High: 1개
- Medium: 3개
- Low: 1개

## High 이슈
### [lib/features/asset/presentation/widgets/asset_category_list.dart:7] 불필요한 ConsumerWidget 사용
- **문제**: ConsumerWidget으로 변경했으나 WidgetRef를 전혀 사용하지 않음
- **위험**: 불필요한 리빌드 트리거 및 성능 저하 가능성
- **해결**: StatelessWidget으로 변경하거나, 실제 provider 사용 시 WidgetRef 활용
```dart
class AssetCategoryList extends StatelessWidget {
  // WidgetRef ref 파라미터 제거
  @override
  Widget build(BuildContext context) {  // WidgetRef ref 제거
    // ... 기존 로직 유지
  }
}
```

## Medium 이슈
### [lib/features/asset/presentation/widgets/asset_category_list.dart:12-20] 중복된 색상 파싱 로직
- **문제**: CategoryRankingList와 동일한 `_parseColor` 메서드가 중복 구현됨
- **위험**: 코드 중복으로 인한 유지보수성 저하
- **해결**: 공유 유틸리티로 추출하거나, category 패키지에서 제공하는 헬퍼 함수 사용
```dart
// core/utils/color_utils.dart에 통합
Color parseColorString(String? colorString) {
  if (colorString == null) return Colors.grey;
  try {
    final colorValue = int.parse(colorString.replaceFirst('#', '0xFF'));
    return Color(colorValue);
  } catch (e) {
    return Colors.grey;
  }
}
```

### [lib/features/asset/presentation/widgets/asset_category_list.dart:125] 금액 포맷팅 일관성 부족
- **문제**: '원' vs ' 원' 혼재 (줄 96: '원', 줄 125: ' 원')
- **위험**: UI 일관성 저하
- **해결**: 프로젝트 전체에서 '원'으로 통일
```dart
// 수정 전
'${numberFormat.format(item.amount)} 원',

// 수정 후
'${numberFormat.format(item.amount)}원',
```

### [lib/features/asset/presentation/widgets/asset_category_list.dart:57-131] ExpansionTile 복잡성 증가
- **문제**: 기본 접힘 상태의 ExpansionTile로 사용자 경험 복잡성 증가
- **위험**: 사용자가 개별 자산을 보려면 추가 클릭 필요
- **해결**: initiallyExpanded: true로 변경하거나, 디자인 요구사항 재검토
```dart
ExpansionTile(
  initiallyExpanded: true,  // 또는 false 유지하되 UX 검토
  // ... 나머지 유지
)
```

## Low 이슈
### [lib/features/asset/presentation/widgets/asset_category_list.dart:43] 불필요한 스프레드 연산자
- **문제**: 정렬 시 불필요한 리스트 복사본 생성
- **위험**: 메모리 사용량 증가 (대규모 데이터에서 영향)
- **해결**: 직접 정렬 또는 효율적인 방법 사용
```dart
// 수정 전
final sortedCategories = [...byCategory]
  ..sort((a, b) => b.amount.compareTo(a.amount));

// 수정 후
final sortedCategories = List<CategoryAsset>.from(byCategory)
  ..sort((a, b) => b.amount.compareTo(a.amount));
```

## 긍정적인 점
- CategoryRankingList와의 디자인 일관성 성공적 구현
- 순위/백분율/Progress Bar 기능 정상 추가
- 금액 기준 정렬 로직 적절하게 구현
- 만기일 정보 제거로 UI 간소화
- 프로젝트 컨벤션 준수 (작은따옴표, 한글 주석)

## 추가 권장사항
- **테스트 코드 작성**: UI 변경에 대한 위젯 테스트 추가 권장
- **접근성 고려**: ExpansionTile의 확장/접기 상태에 대한 시각적/스크린 리더 지원 검토
- **성능 최적화**: 대량 데이터 시 ExpansionTile의 렌더링 성능 모니터링
- **사용성 테스트**: 실제 사용자 피드백을 통한 ExpansionTile 기본 상태 결정

---

## 전체 평가

**Phase 2 구현은 기능적으로 잘 작동하며 사용성이 크게 향상되었습니다.** 다만 nullable 필드 처리 버그와 에러 처리 일관성 문제를 해결해야 프로덕션 준비가 완료됩니다. Critical 이슈 2건만 수정하면 안전하게 배포 가능합니다.

**AssetCategoryList redesign은 CategoryRankingList와의 디자인 통합에 성공했으나, ConsumerWidget 불필요 사용과 UI 복잡성 증가 문제가 있습니다.** High 이슈 1건 수정과 Medium 이슈 검토를 통해 코드 품질을 개선할 수 있습니다.

---

---

# 종합 코드 리뷰 결과 - house-hold-account 전체 프로젝트

**프로젝트**: house-hold-account (공유 가계부 앱)
**리뷰 일시**: 2026-01-15
**리뷰어**: Senior Code Reviewer

---

## Executive Summary

| 심각도 | 이슈 수 | 주요 영역 |
|--------|---------|-----------|
| CRITICAL | 3 | N+1 쿼리, 보안, 코드 복잡도 |
| HIGH | 4 | 에러 처리, SQL Injection 위험, 입력 검증 |
| MEDIUM | 5 | 코드 구조, 디자인 패턴, 테스트 |
| LOW | 3 | 스타일, 문서화 |

**전체 검토 범위:**
- 검토 파일: 주요 5개 + 코드베이스 전체 (~100개 Dart 파일)
- 코드베이스: Clean Architecture 적용, Feature-first 구조
- 상태 관리: Riverpod 8.9/10 점수
- 데이터베이스: Supabase + RLS 정책

---

## Critical 이슈 (필수 수정)

### CRIT-01. [statistics_repository.dart:126-174] N+1 쿼리 문제

- **문제**: `getMonthlyTrend()` 메서드에서 반복문 내 DB 쿼리 실행. 6개월 조회 시 6번의 DB 호출 발생.
- **위험**: 성능 저하, DB 부하 증가, 사용자 경험 악화
- **영향 범위**: 통계 페이지 로딩 시간 6배 증가

```dart
// 문제 코드 (lines 133-143)
for (int i = months - 1; i >= 0; i--) {
  // 매 반복마다 DB 쿼리 실행 - N+1 문제!
  final response = await _client
      .from('transactions')
      .select('amount, type')
      .eq('ledger_id', ledgerId)
      .gte('date', startDate.toIso8601String().split('T').first)
      .lte('date', endDate.toIso8601String().split('T').first);
  // ...
}
```

```dart
// 해결: 단일 쿼리로 전체 기간 조회 후 메모리에서 그룹화
Future<List<MonthlyStatistics>> getMonthlyTrend({
  required String ledgerId,
  int months = 6,
}) async {
  final now = DateTime.now();
  final startDate = DateTime(now.year, now.month - months + 1, 1);
  final endDate = DateTime(now.year, now.month + 1, 0);

  // 단일 쿼리로 전체 기간 데이터 조회
  final response = await _client
      .from('transactions')
      .select('amount, type, date')
      .eq('ledger_id', ledgerId)
      .gte('date', startDate.toIso8601String().split('T').first)
      .lte('date', endDate.toIso8601String().split('T').first);

  // 메모리에서 월별 그룹화
  final Map<String, MonthlyStatistics> grouped = {};
  for (final row in response as List) {
    final date = DateTime.parse(row['date'] as String);
    final key = '${date.year}-${date.month}';
    // ... 그룹화 로직
  }
  
  return grouped.values.toList();
}
```

### CRIT-02. [asset_repository.dart:52-85] N+1 쿼리 문제

- **문제**: `getMonthlyAssets()` 메서드에서 동일한 N+1 패턴 발생
- **위험**: 통계 페이지에서 자산 데이터 로딩 시 성능 저하
- **영향**: 6개월 자산 추이 조회 시 6번 DB 호출

```dart
// 문제 코드 (lines 59-69)
for (int i = months - 1; i >= 0; i--) {
  final response = await _client
      .from('transactions')
      .select('amount')
      .eq('ledger_id', ledgerId)
      .eq('type', 'asset')
      .lte('date', endOfMonth.toIso8601String().split('T').first);
  // ...
}
```

```dart
// 해결: Supabase RPC 함수 또는 단일 쿼리 + 클라이언트 집계
// Option 1: DB Function 생성 (권장)
// CREATE FUNCTION get_monthly_asset_totals(p_ledger_id UUID, p_months INT)
// RETURNS TABLE(year INT, month INT, total BIGINT) AS $$
// ...

// Option 2: 전체 조회 후 클라이언트 집계
final allAssets = await _client
    .from('transactions')
    .select('amount, date')
    .eq('ledger_id', ledgerId)
    .eq('type', 'asset')
    .lte('date', DateTime.now().toIso8601String().split('T').first);

// 누적 합계 계산 로직...
```

### CRIT-03. [add_transaction_sheet.dart] 파일 크기 과대 (1233줄)

- **문제**: 단일 파일에 너무 많은 책임이 집중됨 (SRP 위반)
- **위험**: 유지보수 어려움, 테스트 어려움, 코드 이해도 저하
- **권장**: 500줄 이하로 분리

**현재 파일 구조 분석:**
| 섹션 | 라인 수 | 책임 |
|------|---------|------|
| State/Controller | 1-103 | 상태 관리 |
| Form Validation | 119-137 | 유효성 검증 |
| Submit Logic | 139-281 | 제출 로직 |
| Build Method | 283-655 | UI 빌드 |
| Category Grid | 657-738 | 카테고리 UI |
| Payment Method | 932-1019 | 결제수단 UI |
| Dialogs | 1040-1210 | 다이얼로그 |
| Formatter | 1213-1233 | 입력 포맷터 |

```dart
// 해결: 위젯 분리 리팩토링
// lib/features/transaction/presentation/widgets/
//   add_transaction_sheet.dart           (메인 - 300줄)
//   add_transaction_form.dart            (폼 컨트롤러)
//   transaction_type_selector.dart       (수입/지출/자산 선택)
//   category_selection_grid.dart         (카테고리 그리드)
//   payment_method_chips.dart            (결제수단 칩)
//   transaction_dialogs.dart             (다이얼로그 모음)
```

---

## High 이슈 (수정 권장)

### HIGH-01. [supabase_config.dart:25-29] SharedPreferences 보안 취약점

- **문제**: Supabase URL과 Anon Key를 SharedPreferences에 평문 저장
- **위험**: 루팅된 기기에서 키 탈취 가능, 앱 역공학 시 노출
- **심각도**: 중간 (Anon Key는 공개키이나 URL 노출은 권장하지 않음)

```dart
// 문제 코드 (lines 25-29)
static Future<void> _saveConfigToSharedPreferences() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('flutter.supabase_url', supabaseUrl);
  await prefs.setString('flutter.supabase_anon_key', supabaseAnonKey);
}
```

```dart
// 해결 방안 1: flutter_secure_storage 사용
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

static Future<void> _saveConfigToSecureStorage() async {
  const storage = FlutterSecureStorage();
  await storage.write(key: 'supabase_url', value: supabaseUrl);
  await storage.write(key: 'supabase_anon_key', value: supabaseAnonKey);
}

// 해결 방안 2: 저장 자체 불필요 (권장)
// .env에서 직접 로드하므로 SharedPreferences 저장 제거
// 이 메서드의 용도가 위젯 확장 등이라면 필요시에만 로드
```

### HIGH-02. [search_page.dart:26] SQL Injection 위험

- **문제**: 사용자 입력을 직접 쿼리에 삽입
- **위험**: SQL Injection 공격 가능성 (Supabase가 자동 이스케이프하나 방어적 코딩 필요)

```dart
// 문제 코드 (line 26)
.or('title.ilike.%$query%,memo.ilike.%$query%')
```

```dart
// 해결: 입력 검증 및 sanitize
final sanitizedQuery = query
    .replaceAll('%', r'\%')
    .replaceAll('_', r'\_')
    .replaceAll("'", "''");

// 또는 Supabase의 파라미터화된 쿼리 사용
// ilike 연산자는 Supabase에서 자동 이스케이프되나
// 특수문자 처리가 필요
```

### HIGH-03. [home_page.dart:465, 703] catch(_) 안티패턴

- **문제**: 에러를 무시하는 catch(_) 패턴 사용 (4곳 발견)
- **위험**: 디버깅 어려움, 에러 추적 불가, 문제 은폐
- **발견 위치**:
  - `home_page.dart:465`
  - `home_page.dart:703`
  - `transaction_list.dart:268`
  - `daily_category_breakdown_sheet.dart:307`

```dart
// 문제 코드
} catch (_) {
  return const Color(0xFFA8D8EA);
}
```

```dart
// 해결: 최소한 로깅 추가
} catch (e, st) {
  // 프로덕션에서는 crashlytics/sentry로 전송
  debugPrint('Color parsing failed: $e');
  return const Color(0xFFA8D8EA);
}

// 또는 tryParse 패턴 사용
Color? _tryParseColor(String? colorStr) {
  if (colorStr == null) return null;
  final hex = colorStr.replaceFirst('#', '');
  final value = int.tryParse('FF$hex', radix: 16);
  return value != null ? Color(value) : null;
}

Color _parseColor(String? colorStr) {
  return _tryParseColor(colorStr) ?? const Color(0xFFA8D8EA);
}
```

### HIGH-04. [asset_repository.dart:177-253] rethrow 누락

- **문제**: Repository 메서드들에서 catch 후 Exception 재포장만 하고 rethrow 누락
- **위험**: 스택 트레이스 손실, 원본 에러 정보 유실

```dart
// 문제 코드 (lines 188-191)
} catch (e) {
  throw Exception('목표 조회 실패: $e');  // 원본 스택트레이스 손실!
}
```

```dart
// 해결: rethrow 추가 또는 커스텀 예외 사용
// 방법 1: rethrow
} catch (e, st) {
  // 로깅
  debugPrint('목표 조회 실패: $e\n$st');
  rethrow;
}

// 방법 2: 커스텀 예외 (프로젝트 표준 따름)
} catch (e, st) {
  throw AssetRepositoryException(
    message: '목표 조회 실패',
    originalError: e,
    stackTrace: st,
  );
}
```

---

## Medium 이슈 (개선 권장)

### MED-01. [statistics_repository.dart] 중복 코드

- **문제**: `getYearlyTrend()`와 `getYearlyTrendWithAverage()`가 거의 동일한 로직
- **권장**: 공통 로직 추출

```dart
// 해결: 내부 헬퍼 메서드 추출
Future<List<YearlyStatistics>> _fetchYearlyData({
  required String ledgerId,
  required int years,
  required DateTime baseDate,
}) async {
  // 공통 로직
}

Future<List<YearlyStatistics>> getYearlyTrend(...) async {
  return _fetchYearlyData(...);
}

Future<TrendStatisticsData> getYearlyTrendWithAverage(...) async {
  final data = await _fetchYearlyData(...);
  // 평균 계산 로직
}
```

### MED-02. [add_transaction_sheet.dart:1022-1038] 색상 생성 로직

- **문제**: 랜덤 색상 생성이 시간 기반으로 예측 가능
- **권장**: 진정한 랜덤 또는 순환 방식 사용

```dart
// 현재 코드
return colors[(DateTime.now().millisecondsSinceEpoch % colors.length)];

// 해결: dart:math Random 사용
import 'dart:math';
final _random = Random();
return colors[_random.nextInt(colors.length)];
```

### MED-03. [search_page.dart:11] StateProvider 직접 수정

- **문제**: `StateProvider` 직접 state 변경 (프로젝트 컨벤션: `invalidate()` 사용 권장)
- **영향**: 미미하나 일관성 위해 수정 권장

```dart
// 현재 코드
ref.read(searchQueryProvider.notifier).state = value;

// 권장: 검색은 즉시 반응이 필요하므로 현재 패턴 유지 가능
// 단, 복잡한 상태는 StateNotifier 사용 검토
```

### MED-04. [statistics_repository.dart:87] 이모티콘 하드코딩

- **문제**: 고정비 카테고리 아이콘으로 이모티콘 직접 사용
- **위험**: 프로젝트 컨벤션 위반 (이모티콘 사용 금지)

```dart
// 문제 코드 (line 87)
categoryIcon = '📌';

// 해결: 아이콘 상수 또는 빈 문자열 사용
categoryIcon = '';  // 또는 Icons 상수 참조
```

### MED-05. [asset_repository.dart:285-329] getEnhancedStatistics 복잡도

- **문제**: 단일 메서드에서 7개 DB 호출 (N+1보다 더 심각)
- **권장**: 병렬 처리 또는 DB 함수로 통합

```dart
// 현재: 순차 호출 7회
final totalAmount = await getTotalAssets(ledgerId: ledgerId);
final monthlyChange = await getMonthlyChange(...);
final lastMonthTotal = await _getTotalAssetsUntil(...);
final yearAgoTotal = await _getTotalAssetsUntil(...);
final monthly = await getMonthlyAssets(ledgerId: ledgerId);
final byCategory = await getAssetsByCategory(ledgerId: ledgerId);

// 해결: Future.wait로 병렬 처리
final results = await Future.wait([
  getTotalAssets(ledgerId: ledgerId),
  getMonthlyChange(...),
  _getTotalAssetsUntil(ledgerId: ledgerId, date: lastMonthDate),
  _getTotalAssetsUntil(ledgerId: ledgerId, date: yearAgoDate),
  getMonthlyAssets(ledgerId: ledgerId),
  getAssetsByCategory(ledgerId: ledgerId),
]);
```

---

## Low 이슈 (선택)

### LOW-01. [add_transaction_sheet.dart:302] 하드코딩된 BorderRadius

- **문제**: `Radius.circular(20)` 직접 사용
- **권장**: 디자인 토큰 `BorderRadiusToken.xl` 사용

```dart
// 현재
borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),

// 권장
borderRadius: BorderRadius.vertical(
  top: Radius.circular(BorderRadiusToken.xl),
),
```

### LOW-02. [search_page.dart:180] 주석 없는 fallback 색상

- **문제**: 매직 넘버 `0xFF9E9E9E` 사용
- **권장**: 상수로 추출 또는 주석 추가

```dart
// 현재
const fallbackColor = Color(0xFF9E9E9E); // Grey 500

// 권장: 상수 파일로 이동
// lib/core/constants/color_constants.dart
const kFallbackCategoryColor = Color(0xFF9E9E9E);
```

### LOW-03. [statistics_repository.dart:546-598] Model 클래스 위치

- **문제**: Repository 파일 내에 Model 클래스 정의
- **권장**: 별도 파일로 분리

```
// 권장 구조
lib/features/statistics/
  domain/entities/
    category_statistics.dart
    monthly_statistics.dart
  data/repositories/
    statistics_repository.dart  (Repository만)
```

---

## 아키텍처 평가

### 긍정적인 점

| 항목 | 점수 | 설명 |
|------|------|------|
| Feature-First 구조 | 9/10 | Clean Architecture 잘 적용됨 |
| Riverpod 사용 | 8.5/10 | invalidate 패턴 적절히 사용 |
| 디자인 시스템 | 8/10 | 디자인 토큰 도입, 일관성 확보 |
| RLS 정책 | 9/10 | 모든 테이블에 적용됨 |

### 개선 필요

| 항목 | 현재 | 목표 | 권장 조치 |
|------|------|------|-----------|
| Repository 쿼리 최적화 | 4/10 | 8/10 | N+1 문제 해결 |
| 파일 크기 | 5/10 | 8/10 | 대형 파일 분리 |
| 에러 처리 일관성 | 6/10 | 9/10 | rethrow 패턴 통일 |

---

## 보안 평가

| 항목 | 상태 | 위험도 | 조치 |
|------|------|--------|------|
| SharedPreferences 민감정보 | 취약 | 중간 | flutter_secure_storage 전환 |
| SQL Injection | 낮은 위험 | 낮음 | 입력 sanitize 추가 |
| RLS 정책 | 양호 | - | 유지 |
| 환경변수 관리 | 양호 | - | .env 커밋 방지됨 |

---

## 성능 평가

| 문제 | 영향 | 예상 개선 |
|------|------|----------|
| N+1 쿼리 (통계) | 페이지 로딩 6배 지연 | 80% 개선 예상 |
| N+1 쿼리 (자산) | 자산 페이지 지연 | 80% 개선 예상 |
| 순차 DB 호출 | API 응답 지연 | 50% 개선 예상 |

---

## 권장 조치 우선순위

### 즉시 조치 (1주 내)

1. **CRIT-01, CRIT-02**: N+1 쿼리 문제 해결
   - `statistics_repository.dart` 리팩토링
   - `asset_repository.dart` 리팩토링
   
2. **HIGH-03, HIGH-04**: 에러 처리 개선
   - catch(_) 패턴 제거
   - rethrow 추가

### 단기 조치 (2주 내)

3. **CRIT-03**: add_transaction_sheet.dart 분리
   - 위젯 컴포넌트화
   - 테스트 용이성 확보

4. **HIGH-01**: SharedPreferences 보안 개선
   - flutter_secure_storage 도입 또는 저장 제거

### 중기 조치 (1개월 내)

5. **HIGH-02**: 검색 입력 sanitize
6. **MED-01~05**: 코드 품질 개선
7. **LOW-01~03**: 스타일 통일

---

## 결론

전체적으로 Clean Architecture가 잘 적용된 프로젝트입니다. Feature-first 구조와 Riverpod 상태 관리가 적절히 사용되었으며, 디자인 시스템 도입으로 UI 일관성이 확보되어 있습니다.

**주요 개선 영역:**
1. **성능**: N+1 쿼리 문제가 통계/자산 기능에서 심각하게 발생 (CRITICAL)
2. **유지보수성**: 대형 파일 분리 필요 (CRITICAL)
3. **에러 처리**: rethrow 패턴 통일 필요 (HIGH)
4. **보안**: SharedPreferences 민감정보 저장 개선 (HIGH)

위 이슈들을 우선순위에 따라 해결하면 앱의 품질과 성능이 크게 향상될 것으로 예상됩니다.

---

*이 리뷰는 자동화된 분석과 수동 코드 검토를 통해 작성되었습니다.*
*리뷰 일시: 2026-01-15*

---

# 코드 리뷰 결과 - 1차 UI/UX 개선 (터치 영역 및 디자인 토큰)

**리뷰 일시**: 2026-01-17
**리뷰어**: Senior Code Reviewer

## 요약
- 검토 파일: 3개
- Critical: 0개 / High: 0개 / Medium: 2개 / Low: 1개

---

## Medium 이슈

### MED-01. [home_page.dart:653] Material + InkWell 패턴의 일관성
- **문제**: `Material(color: Colors.transparent)` + `InkWell` 패턴이 프로젝트에서 처음 사용됨
- **영향**: 다른 파일들의 GestureDetector 사용 패턴과 불일치 (color_picker.dart, asset_goal_progress_bar.dart)
- **해결**: 이 패턴이 더 나은 UX(ripple 효과)를 제공하므로, 다른 GestureDetector 사용 위치에도 동일하게 적용하는 것을 권장

```dart
// 현재 변경된 패턴 (권장)
Material(
  color: Colors.transparent,
  child: InkWell(
    onTap: () {},
    borderRadius: BorderRadius.circular(BorderRadiusToken.sm),
    child: Padding(...),
  ),
)
```

### MED-02. [calendar_header.dart / statistics_date_selector.dart] 다른 파일과의 일관성 부재
- **문제**: `visualDensity: VisualDensity.compact`와 `constraints` 제거가 3개 파일에만 적용됨
- **영향**: 아래 파일들에는 여전히 compact 스타일이 남아있어 UI 일관성 부재
  - `period_filter.dart` (line 31)
  - `expense_type_filter.dart` (line 48)
  - `statistics_type_filter.dart` (line 47)
  - `asset_goal_form_sheet.dart` (line 241)
- **해결**: SegmentedButton의 visualDensity.compact는 의도적인 디자인일 수 있으므로 확인 필요. IconButton의 48dp 기본값 복원은 접근성 측면에서 올바른 방향

---

## Low 이슈

### LOW-01. [전체] 프로젝트 전반의 하드코딩된 값 잔존
- **문제**: 변경된 3개 파일은 디자인 토큰을 사용하지만, 프로젝트 전반에 하드코딩된 값이 다수 존재
- **영향**: 
  - `fontSize: 11, 12, 13, 14, 16, 18, 20, 24` 등 하드코딩 54개 이상
  - `EdgeInsets.all(16), EdgeInsets.all(24)` 등 하드코딩 52개 이상
- **해결**: 점진적 마이그레이션 필요. 현재 변경은 올바른 방향이며, 향후 리팩토링 시 참고

---

## 긍정적인 점

### 1. 접근성 개선 (터치 영역 복원)
- IconButton의 `visualDensity: VisualDensity.compact`와 `constraints: BoxConstraints(minWidth: 40)` 제거로 기본 48dp 터치 영역 복원
- Material Design 가이드라인 준수 (최소 48x48dp 권장)

### 2. 디자인 토큰 적용 일관성
- `Spacing.xs`, `Spacing.sm`, `Spacing.md` 적절히 사용
- `BorderRadiusToken.sm` 사용
- `IconSize.sm` 사용
- 하드코딩된 `fontSize` 제거 및 `textTheme.bodySmall` 사용

### 3. UX 개선 (Ripple 효과)
- `GestureDetector` -> `InkWell` 변경으로 터치 피드백 제공
- Material Design의 터치 피드백 패턴 준수

### 4. 코드 품질
- import 문 추가 (design_tokens.dart) 올바르게 처리
- 기존 기능 동작에 영향 없음

---

## 추가 권장사항

### 1. 향후 리팩토링 대상
동일한 개선을 적용하면 좋을 파일들:
- `lib/shared/widgets/color_picker.dart` - GestureDetector -> InkWell
- `lib/features/asset/presentation/widgets/asset_goal_progress_bar.dart` - GestureDetector -> InkWell
- `lib/features/share/presentation/widgets/*.dart` - fontSize 하드코딩 다수
- `lib/features/ledger/presentation/widgets/calendar_day_cell.dart` - fontSize: 12 하드코딩

### 2. 디자인 토큰 확장 고려
- `FontSize` 토큰 추가 고려 (xs: 10, sm: 12, md: 14, lg: 16, xl: 18, xxl: 24)
- 현재는 Theme.textTheme 사용이 권장되지만, 세밀한 제어 필요시 유용

### 3. 테스트 권장
- 48dp 터치 영역 복원으로 인한 레이아웃 변경 확인 (특히 AppBar 내 아이콘 간격)
- 다크 모드에서 ripple 효과 색상 확인

---

## 결론

**승인 권장** - 변경 내용이 디자인 시스템 가이드라인을 잘 따르고 있으며, 접근성과 UX를 개선합니다. Medium 이슈는 프로젝트 전체 일관성에 관한 것으로, 점진적 개선을 통해 해결 가능합니다.

---

## 리뷰어 체크리스트
- [x] 보안 취약점 없음
- [x] 데이터 손실 위험 없음
- [x] 기능 버그 없음
- [x] 성능 이슈 없음
- [x] 디자인 토큰 사용 적절
- [x] 접근성 개선 적절
- [ ] 프로젝트 전체 일관성 (향후 개선 필요)

---

*리뷰 일시: 2026-01-17*

---

# 코드 리뷰 결과 - 2차 UI/UX 개선 (AnimatedSwitcher, InkWell, 네비게이션 라벨)

**리뷰 일시**: 2026-01-17
**리뷰어**: Senior Code Reviewer

## 요약
- 검토 파일: 3개
- Critical: 1개 / High: 0개 / Medium: 2개 / Low: 0개

---

## Critical 이슈

### CRIT-01. [home_page.dart:279-284] AnimatedSwitcher로 변경 시 상태 손실 문제

- **문제**: `IndexedStack`에서 `AnimatedSwitcher`로 변경하면 탭 전환 시 이전 탭의 상태가 완전히 파괴됩니다.
  - `IndexedStack`: 모든 자식 위젯을 메모리에 유지하고 visibility만 토글
  - `AnimatedSwitcher`: 현재 위젯만 유지하고 이전 위젯은 dispose됨

- **위험**:
  - `StatisticsPage` 스크롤 위치 손실
  - `AssetPage` 스크롤/확장 상태 손실
  - `MoreTabView` 스크롤 위치 손실
  - 사용자가 탭 전환 후 돌아왔을 때 초기 상태로 리셋됨 (UX 저하)
  - `CalendarView`의 월별 네비게이션 상태도 손실 가능

- **해결**: `IndexedStack` 유지하거나, 상태 보존이 필요한 탭만 별도 처리

```dart
// 방법 1: IndexedStack 유지 (권장 - 상태 보존)
body: IndexedStack(
  index: _selectedIndex,
  children: [
    CalendarTabView(...),
    const StatisticsTabView(),
    const AssetTabView(),
    const MoreTabView(),
  ],
),

// 방법 2: AnimatedSwitcher 유지 + AutomaticKeepAliveClientMixin 적용
// 각 탭 위젯에서 상태 보존 필요
class StatisticsTabView extends StatefulWidget {
  @override
  State<StatisticsTabView> createState() => _StatisticsTabViewState();
}

class _StatisticsTabViewState extends State<StatisticsTabView> 
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  
  @override
  Widget build(BuildContext context) {
    super.build(context);  // 필수!
    return const StatisticsPage();
  }
}
```

---

## Medium 이슈

### MED-01. [home_page.dart:293-294] NavigationBar height 기본값 사용 시 주의

- **문제**: `height: 56` 제거로 Material 3 기본 높이(80dp)로 변경됨
- **영향**: 네비게이션 바가 이전보다 24dp 더 높아져 화면 콘텐츠 영역 감소
- **평가**: `labelBehavior: onlyShowSelected`와 조합하면 UX적으로 적절함. 라벨이 표시되므로 80dp가 더 자연스러움.
- **권장**: 변경 유지 가능, 단 디자인 일관성 확인 필요

### MED-02. [color_picker.dart:64-67] 터치 영역 vs 시각적 크기 불일치

- **문제**: 터치 영역 44dp, 시각적 원 36dp로 8dp 차이
- **영향**: 
  - 잉크 리플이 36dp 원 바깥에서도 발생 가능
  - 시각적 피드백과 터치 영역 불일치로 사용자 혼란 가능
- **권장**: 현재 구현은 접근성 측면에서 올바름 (44dp 최소 터치 영역). 유지 권장.

---

## 긍정적인 점

### 1. 디자인 토큰 일관성 적용 (우수)
- 모든 하드코딩된 값이 디자인 토큰으로 교체됨
- `Spacing.xs`, `Spacing.sm`, `Spacing.md`, `Spacing.lg` 일관 사용
- `BorderRadiusToken.xs`, `BorderRadiusToken.sm` 적절한 사용
- `AnimationDuration.duration200` 토큰 활용

### 2. InkWell + Material 패턴 (우수)
- `GestureDetector` -> `Material + InkWell` 변경으로 시각적 피드백 개선
- `customBorder: CircleBorder()` 적용으로 원형 리플 효과 구현
- 터치 피드백이 Material Design 가이드라인 준수

### 3. 네비게이션 라벨 표시 (우수)
- `alwaysHide` -> `onlyShowSelected`로 변경
- 선택된 탭에만 라벨 표시하여 사용자가 현재 위치 파악 용이
- UX 개선 효과 높음 (특히 신규 사용자)

### 4. 접근성 개선 (우수)
- `TouchTarget.minimum` (44dp) 사용으로 WCAG 접근성 준수
- ColorScheme 사용으로 다크모드 자동 대응

### 5. 코드 품질 개선
- `_buildTabContent` 메서드 추출로 가독성 향상
- 불필요한 `visualDensity`, `padding` 속성 제거로 코드 간결화

---

## 성능 영향 평가

| 항목 | 이전 (IndexedStack) | 이후 (AnimatedSwitcher) | 평가 |
|------|---------------------|------------------------|------|
| 메모리 | 모든 탭 상시 유지 | 현재 탭만 유지 | 개선 |
| 초기 로딩 | 4개 탭 모두 빌드 | 1개 탭만 빌드 | 개선 |
| 탭 전환 속도 | 즉시 | 200ms 애니메이션 | 미세 지연 |
| 상태 보존 | 완전 보존 | 손실 | **악화** |

**결론**: 메모리/초기 로딩은 개선되나, 상태 손실이 UX에 부정적 영향. Critical 이슈 해결 필요.

---

## 추가 권장사항

1. **AnimatedSwitcher 유지 시**: 각 탭 뷰에 `AutomaticKeepAliveClientMixin` 적용 검토
2. **테스트 추가**: 탭 전환 후 상태 보존 테스트 케이스 작성
3. **사용자 테스트**: 네비게이션 라벨 표시 변경에 대한 사용자 피드백 수집

---

## 리뷰어 체크리스트
- [x] 보안 취약점 없음
- [x] 데이터 손실 위험 없음
- [ ] 기능 버그 없음 (**상태 손실 이슈 발견**)
- [x] 성능 이슈 없음 (오히려 개선)
- [x] 디자인 토큰 사용 적절
- [x] 접근성 개선 적절
- [x] InkWell 패턴 적절

---

*리뷰 일시: 2026-01-17*

---

# 코드 리뷰 결과 - Flutter/Riverpod 성능 최적화 1차

**리뷰 일시**: 2026-01-17
**리뷰어**: Senior Code Reviewer

## 요약
- **검토 파일**: 5개
- **Critical**: 0개
- **High**: 1개
- **Medium**: 2개
- **Low**: 1개

---

## High 이슈

### HIGH-01. [calendar_view.dart:38-45] 중복 Provider Watch로 인한 select() 최적화 무효화

- **문제**: `currentLedgerProvider`를 select()와 전체 watch() 두 번 호출하여 select() 최적화 효과가 상쇄됨
- **위험**: select()로 isShared만 watch하더라도, 바로 아래에서 전체 currentLedgerProvider를 다시 watch하면 전체 데이터 변경 시 위젯이 리빌드됨
- **해결**: 두 가지 방법 중 하나 선택

```dart
// 현재 코드 (문제)
final isShared = ref.watch(
  currentLedgerProvider.select(
    (data) => data.valueOrNull?.isShared ?? false,
  ),
);
final currentLedgerAsync = ref.watch(currentLedgerProvider); // 중복 watch!
final currentLedger = currentLedgerAsync.valueOrNull;

// 해결 방안 1: select() 제거 (currentLedger가 어차피 필요하므로)
// 가장 간단한 해결책
final currentLedgerAsync = ref.watch(currentLedgerProvider);
final currentLedger = currentLedgerAsync.valueOrNull;
final isShared = currentLedger?.isShared ?? false;
final memberCount = isShared ? 2 : 1;

// 해결 방안 2: CalendarDayCell이 currentLedger 전체가 필요 없다면
// CalendarDayCell에 필요한 값만 전달하도록 리팩토링 (더 나은 최적화)
// 예: currentLedger 대신 isShared, memberColors 등 필요한 값만 전달
```

**참고**: 주석에 "select()로 isShared만 watch하여 불필요한 리빌드 방지"라고 명시되어 있으나, 실제로는 두 번째 watch로 인해 효과가 없음.

---

## Medium 이슈

### MED-01. [전체 파일] cacheExtent 값의 일관성 부재

- **문제**: 모든 ListView에 동일하게 `cacheExtent: 500`을 적용했지만, 각 리스트 아이템의 높이와 사용 맥락이 다름
- **위험**: 
  - 아이템 높이가 큰 경우 (예: _LedgerCard ~150px) 500px은 1-2개 아이템만 미리 렌더링
  - 아이템 높이가 작은 경우 불필요하게 많은 아이템을 미리 렌더링하여 메모리 낭비
- **해결**: 각 리스트의 특성에 맞게 cacheExtent 조정 권장

```dart
// 권장 기준 (아이템 높이 기반):
// - 작은 아이템 (50-80px): cacheExtent: 300-500 (5-8개 미리 렌더링)
// - 중간 아이템 (100-150px): cacheExtent: 500-800 (4-6개 미리 렌더링)
// - 큰 아이템 (150px+): cacheExtent: 800-1000 (4-6개 미리 렌더링)

// transaction_list.dart - 아이템 높이 약 80px
cacheExtent: 400,

// ledger_management_page.dart - 아이템 높이 약 150-200px
cacheExtent: 800,

// search_page.dart - ListTile 기본 높이 약 56px
cacheExtent: 400,

// category_management_page.dart - Card + ListTile 약 70px
cacheExtent: 350,
```

### MED-02. [calendar_view.dart:55] RepaintBoundary 단독 적용의 효과 불명확

- **문제**: RepaintBoundary를 CalendarMonthSummary에만 적용했으나, 실제 리페인트 범위를 측정하지 않고 적용
- **위험**: 
  - 잘못된 위치의 RepaintBoundary는 오히려 성능 저하 유발 (추가 레이어 생성 비용)
  - CalendarMonthSummary만 리페인트되는 것이 아니라면 효과 없음
- **해결**: Flutter DevTools의 "Highlight Repaints" 기능으로 실제 리페인트 범위 확인 후 적용 여부 결정

```dart
// RepaintBoundary 적용 전 확인 사항:
// 1. Flutter DevTools > Rendering > Highlight Repaints 활성화
// 2. 캘린더 스크롤/월 변경 시 어떤 위젯이 리페인트되는지 확인
// 3. 확인 후 실제로 분리가 필요한 곳에만 적용

// 현재 코드 - CalendarMonthSummary만 적용
RepaintBoundary(
  child: CalendarMonthSummary(...),
),

// 권장: 실제 측정 후 필요한 곳에 적용
// 또는 전체 섹션별로 일관되게 적용
Column(
  children: [
    RepaintBoundary(child: CalendarMonthSummary(...)),
    RepaintBoundary(child: CalendarHeader(...)),
    RepaintBoundary(child: CalendarDaysOfWeekHeader(...)),
    RepaintBoundary(child: TableCalendar(...)),
  ],
)
```

---

## Low 이슈

### LOW-01. [ledger_management_page.dart:42] 디자인 토큰 미사용

- **문제**: `padding: const EdgeInsets.all(16)` 하드코딩 사용
- **위험**: 프로젝트 컨벤션 위반 (CLAUDE.md: Spacing.md 사용 권장)
- **해결**: 디자인 토큰으로 교체

```dart
// 현재 코드 (line 42)
padding: const EdgeInsets.all(16),

// 권장 코드
padding: const EdgeInsets.all(Spacing.md),
```

---

## 긍정적인 점

1. **select() 활용 시도**: Riverpod의 select()를 활용하여 필요한 데이터만 watch하려는 접근은 올바른 방향
2. **cacheExtent 일괄 적용**: 스크롤 성능 최적화를 위한 cacheExtent 적용은 좋은 시도
3. **주석 문서화**: `// 성능 최적화: 스크롤 시 미리 렌더링` 등 최적화 의도를 주석으로 명시하여 코드 가독성 향상
4. **RepaintBoundary 고려**: 리페인트 최적화를 위한 RepaintBoundary 사용 시도는 올바른 접근
5. **loading 상태에도 cacheExtent 적용**: transaction_list.dart에서 loading 스켈레톤에도 cacheExtent 적용하여 일관성 유지

---

## 추가 권장사항

### 1. 더 효과적인 Riverpod select() 패턴

```dart
// select()가 효과적인 경우: 큰 객체에서 일부만 필요하고,
// 해당 위젯에서 전체 객체를 다시 watch하지 않을 때
final userName = ref.watch(
  userProvider.select((user) => user.name),
);
// 이 위젯에서 userProvider를 다시 watch하지 않아야 함!

// select() 대신 별도 Provider가 나은 경우:
// 여러 곳에서 동일한 파생 데이터가 필요할 때
final isSharedProvider = Provider((ref) {
  return ref.watch(currentLedgerProvider).valueOrNull?.isShared ?? false;
});

// 사용
final isShared = ref.watch(isSharedProvider);
```

### 2. ListView 추가 최적화 기법

```dart
// 아이템 높이가 고정되어 있다면 itemExtent 사용 (강력 권장)
ListView.builder(
  itemExtent: 80, // 고정 높이 지정 시 스크롤 성능 대폭 향상
  itemCount: items.length,
  itemBuilder: (context, index) => ItemWidget(item: items[index]),
)

// prototypeItem 사용 (Flutter 3.x 권장, 높이 측정 자동화)
ListView.builder(
  prototypeItem: const TransactionCard.skeleton(),
  itemCount: items.length,
  itemBuilder: (context, index) => TransactionCard(item: items[index]),
)

// addAutomaticKeepAlives: false (아이템이 매우 많고 상태 보존 불필요 시)
ListView.builder(
  addAutomaticKeepAlives: false,
  addRepaintBoundaries: true, // 기본값 true
  itemCount: items.length,
  itemBuilder: (context, index) => ItemWidget(item: items[index]),
)
```

### 3. const 생성자 활용

```dart
// CalendarDayCell 등 자주 생성되는 위젯에 const 적용 검토
// 파라미터가 모두 compile-time constant일 때만 가능
const CalendarEmptyCell(
  day: day,  // runtime 값이므로 const 불가
  // ...
)

// 내부 위젯에서 const 사용 가능한 부분 활용
Container(
  decoration: const BoxDecoration(  // const 가능
    borderRadius: BorderRadius.circular(8),
  ),
  child: child,
)
```

### 4. 성능 측정 권장

최적화 전후 비교를 위해 다음 도구 활용 권장:

```bash
# Profile 모드로 실행 (실제 성능 측정)
flutter run --profile

# DevTools에서 확인할 항목:
# 1. Timeline 탭: 프레임 드롭 확인 (16ms 초과 여부)
# 2. Widget rebuild 횟수 비교 (Provider 최적화 효과)
# 3. Memory 탭: 메모리 사용량 변화
# 4. Rendering > Highlight Repaints: 리페인트 영역 확인
```

### 5. 향후 최적화 고려 사항

| 항목 | 현재 상태 | 권장 개선 |
|------|----------|----------|
| Provider select | 부분 적용 | 전체 검토 필요 |
| ListView cacheExtent | 500 고정 | 아이템별 조정 |
| itemExtent | 미사용 | 고정 높이 리스트에 적용 |
| RepaintBoundary | 1곳만 적용 | 측정 후 필요 시 추가 |
| const 생성자 | 부분 적용 | 전체 검토 필요 |

---

## 결론

**수정 필요**: 1건 (HIGH-01: 중복 Provider watch)
**권장 수정**: 3건 (Medium 2, Low 1)

전반적으로 성능 최적화 방향은 올바르나, **calendar_view.dart의 중복 Provider watch 문제**는 select() 최적화 효과를 완전히 무효화하므로 반드시 수정해야 합니다.

나머지 이슈는 권장 사항으로, 실제 성능 측정 후 필요에 따라 적용하면 됩니다. cacheExtent와 RepaintBoundary는 Flutter DevTools로 실제 효과를 측정한 후 최적 값을 결정하는 것을 권장합니다.

---

## 리뷰어 체크리스트
- [x] 보안 취약점 없음
- [x] 데이터 손실 위험 없음
- [ ] 기능 버그 없음 (**select() 최적화 무효화 발견**)
- [x] 성능 이슈 없음 (개선 시도)
- [x] 디자인 토큰 사용 (부분 미적용)
- [x] 프로젝트 컨벤션 준수

---

*리뷰 일시: 2026-01-17*

---

# 코드 리뷰 결과 - Flutter/Supabase 성능 최적화 전체 작업 (최종 리뷰)

**리뷰 일시**: 2026-01-17
**리뷰어**: Senior Code Reviewer

## 요약
- **검토 파일**: 7개 (수정된 파일) + 7개 (미적용 파일 확인)
- **Critical**: 0개
- **High**: 1개
- **Medium**: 3개
- **Low**: 2개

---

## 전체 변경 사항 검토 결과

### 1차 작업: ListView 및 위젯 최적화

| 파일 | 변경 내용 | 평가 |
|------|----------|------|
| `calendar_view.dart` | 중복 provider watch 수정 | 이전 리뷰에서 지적, 수정 완료 |
| `transaction_list.dart` | cacheExtent: 500 추가 | 적절 |
| `search_page.dart` | cacheExtent: 500 추가 | 적절 |
| `ledger_management_page.dart` | cacheExtent + Spacing.md | 적절 |
| `category_management_page.dart` | cacheExtent: 500 추가 | 적절 |

### 2차 작업: DB 쿼리 최적화

| 항목 | 상태 | 평가 |
|------|------|------|
| 마이그레이션 024 생성 | 완료 | 부분 적용 (아래 참조) |
| idx_transactions_ledger_id_date | 적용됨 | 날짜 범위 쿼리 최적화 |
| idx_transactions_ledger_type_date | 미적용 | 작업 설명에 있었으나 누락 |
| idx_transactions_user_id | 미적용 | 작업 설명에 있었으나 누락 |
| idx_transactions_ledger_payment_method | 미적용 | 작업 설명에 있었으나 누락 |

### 3차 작업: 이미지 캐싱

| 파일 | 변경 내용 | 평가 |
|------|----------|------|
| `login_page.dart` | CachedNetworkImage 적용 | 적절 |

---

## High 이슈

### [cacheExtent 일관성 누락] 6개 파일에 cacheExtent 미적용

- **문제**: ListView.builder/separated를 사용하는 여러 파일에 cacheExtent 최적화가 적용되지 않음
- **위험**: 동일한 최적화 패턴이 일부만 적용되어 성능 불일치 및 유지보수 혼란
- **누락 파일**:
  1. `payment_method_management_page.dart` (57행, 69행)
  2. `home_page.dart` (350행, 379행) - 가계부 선택 모달
  3. `category_ranking_list.dart` (31행, 53행) - shrinkWrap 사용
  4. `payment_method_list.dart` (25행, 139행) - shrinkWrap 사용
  5. `trend_detail_list.dart` (46행, 106행, 238행) - shrinkWrap 사용
  6. `asset_goal_card.dart` (484행) - shrinkWrap 사용
- **해결**: 스크롤 가능한 ListView에 cacheExtent 추가

```dart
// payment_method_management_page.dart:57 수정 예시
return ListView.builder(
  padding: const EdgeInsets.all(Spacing.md),
  cacheExtent: 500, // 추가
  itemCount: paymentMethods.length,
  ...
);
```

**참고**: shrinkWrap: true + NeverScrollableScrollPhysics()를 사용하는 ListView는 부모 스크롤에 종속되므로 cacheExtent 효과가 제한적입니다. 이들 파일(category_ranking_list, payment_method_list, trend_detail_list, asset_goal_card)은 선택적으로 적용해도 됩니다.

---

## Medium 이슈

### MED-01. [ledger_management_page.dart:111] 디자인 토큰 미적용 하드코딩 잔존

- **문제**: `_LedgerCard` 내부에 `padding: const EdgeInsets.all(16)` 하드코딩 (43행은 수정됨)
- **위험**: 프로젝트 디자인 시스템 일관성 위반
- **해결**: `Spacing.md` 사용

```dart
// 현재 (111행)
padding: const EdgeInsets.all(16),

// 수정
padding: const EdgeInsets.all(Spacing.md),
```

### MED-02. [마이그레이션 024] 인덱스 이름 불일치 및 추가 인덱스 누락

- **문제**: 마이그레이션 파일 내용이 작업 설명과 불일치
  - 생성된 인덱스: `idx_transactions_ledger_id_date` (ledger_id, date)
  - 작업 설명에 있었으나 누락된 인덱스:
    - `idx_transactions_ledger_type_date` (ledger_id, type, date) - 통계 쿼리용
    - `idx_transactions_user_id` (user_id) - 사용자별 거래 조회
    - `idx_transactions_ledger_payment_method` (ledger_id, payment_method_id, date) - 결제수단 탭
- **위험**: 통계 쿼리 최적화 효과 제한
- **해결**: 추가 마이그레이션으로 나머지 인덱스 생성 권장

```sql
-- 025_add_additional_transaction_indexes.sql
-- 통계 쿼리 최적화용 복합 인덱스
CREATE INDEX IF NOT EXISTS idx_transactions_ledger_type_date 
ON transactions(ledger_id, type, date);

-- 사용자별 거래 조회 최적화용 인덱스
CREATE INDEX IF NOT EXISTS idx_transactions_user_id 
ON transactions(user_id);

-- 결제수단 탭 최적화용 복합 인덱스
CREATE INDEX IF NOT EXISTS idx_transactions_ledger_payment_method 
ON transactions(ledger_id, payment_method_id, date);
```

### MED-03. [login_page.dart:282-286] CachedNetworkImage placeholder 과도함

- **문제**: 20x20 아이콘에 CircularProgressIndicator 사용 - 시각적으로 과함
- **위험**: 미미한 UX 영향
- **해결**: 더 간결한 placeholder 권장

```dart
// 현재
placeholder: (context, url) => const SizedBox(
  width: 20,
  height: 20,
  child: CircularProgressIndicator(strokeWidth: 2),
),

// 권장 (더 간결)
placeholder: (context, url) => const SizedBox(width: 20, height: 20),
```

---

## Low 이슈

### LOW-01. [skeleton_loading.dart:214] SkeletonListView에 cacheExtent 없음

- **문제**: 공통 위젯 `SkeletonListView`에 cacheExtent가 없음
- **위험**: 스켈레톤은 짧은 리스트(5개)라 실질 영향 미미
- **해결**: 일관성을 위해 추가 고려

### LOW-02. [statistics 관련 ListView] shrinkWrap 사용 리스트의 성능

- **문제**: statistics 위젯들의 ListView가 shrinkWrap: true 사용
- **위험**: 데이터가 많아지면 성능 저하 가능 (전체 높이 계산 필요)
- **현재 상태**: 현재 데이터 양에서는 문제 없음
- **해결**: 데이터 증가 시 Sliver 기반으로 리팩토링 검토

---

## 긍정적인 점

### 1. ListView 최적화 일관성
- 주요 사용자 상호작용 ListView 5개에 cacheExtent: 500 적용
- 스크롤 성능 개선 (미리 렌더링으로 프레임 드롭 감소)
- loading 상태에도 동일한 cacheExtent 적용으로 일관성 유지

### 2. 디자인 토큰 적용
- `ledger_management_page.dart`에 Spacing.md 적용 및 import 추가
- 프로젝트 컨벤션 준수

### 3. CachedNetworkImage 적용
- login_page에서 네트워크 이미지 캐싱으로 재방문 시 로딩 속도 개선
- placeholder, errorWidget 적절히 설정
- Image.network 사용처 완전 제거 (Grep 검색 결과 없음)

### 4. DB 인덱스 추가
- `idx_transactions_ledger_id_date` 인덱스로 날짜 범위 쿼리 성능 개선
- 캘린더 뷰, 월간 통계, 일별 합계 쿼리에 효과

### 5. 이전 리뷰 이슈 해결
- calendar_view.dart의 중복 provider watch 문제 해결 (1차 리뷰 HIGH-01)
- select() 최적화 무효화 문제 수정

---

## 추가 권장사항

### 프로덕션 배포 전 체크리스트

1. **cacheExtent 일관성 확보** (High - 선택적):
   - `payment_method_management_page.dart`에 cacheExtent 추가 권장
   - 나머지 shrinkWrap ListView는 선택적 적용

2. **DB 인덱스 완성** (Medium - 권장):
   ```bash
   # 마이그레이션 추가 및 적용
   supabase db diff
   ```

3. **디자인 토큰 통일** (Low):
   - `ledger_management_page.dart:111`의 하드코딩 수정

4. **성능 테스트** (권장):
   - 50개 이상 거래 내역으로 스크롤 성능 측정
   - 통계 탭에서 6개월 이상 데이터로 쿼리 속도 확인

---

## 프로덕션 준비 상태

| 항목 | 상태 | 비고 |
|------|------|------|
| ListView 최적화 | 주요 적용 완료 | 5/11 파일 적용, 나머지 선택적 |
| DB 인덱스 | 부분 적용 | 1/4 인덱스 적용 |
| 이미지 캐싱 | 완료 | login_page 적용 |
| 디자인 토큰 | 부분 적용 | 1곳 하드코딩 잔존 |
| calendar_view 이슈 | 해결됨 | 중복 watch 수정 완료 |
| 보안 이슈 | 없음 | - |
| 데이터 손실 위험 | 없음 | - |

---

## 결론

**조건부 프로덕션 배포 가능**

- 현재 변경사항으로도 성능 개선 효과가 있으며 부작용 위험 없음
- 1차 리뷰의 Critical 이슈(중복 provider watch)가 해결되어 안정성 확보
- High 이슈(cacheExtent 일관성)는 선택적 개선 사항이며 기능 장애 아님
- Medium 이슈(인덱스 추가)는 데이터 증가 시 효과 발휘, 현재 소규모 데이터에서는 큰 영향 없음

**권장 사항**:
1. High 이슈 중 `payment_method_management_page.dart`만 추가 수정하면 주요 스크롤 리스트 최적화 완료
2. 추가 인덱스 마이그레이션은 데이터 증가 시점에 적용해도 무방

---

## 리뷰어 체크리스트 (최종)

- [x] 보안 취약점 없음
- [x] 데이터 손실 위험 없음
- [x] 기능 버그 없음
- [x] 성능 개선 적절
- [x] 디자인 토큰 사용 (부분 미적용 1곳)
- [x] 프로젝트 컨벤션 준수
- [x] 이전 리뷰 이슈 해결 확인
- [ ] cacheExtent 일관성 (선택적 개선 필요)
- [ ] DB 인덱스 완성 (선택적 추가 필요)

---

*최종 리뷰 일시: 2026-01-17*
