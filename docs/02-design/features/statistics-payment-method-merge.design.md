# Design: 통계 - 자동수집 결제수단 합산 기능

## 1. 개요

### 1.1 참조 문서
- Plan: `docs/01-plan/features/statistics-payment-method-merge.plan.md`

### 1.2 설계 목표
공유 가계부에서 동일 이름의 자동수집 결제수단을 통계에서 합산하여 표시

### 1.3 핵심 설계 원칙
- **자동수집 결제수단**: `name` 기준 그룹화 (합산)
- **공유 결제수단**: `payment_method_id` 기준 그룹화 (기존 동작 유지)
- **하위 호환성**: DB 스키마 변경 없음, 기존 데이터 영향 없음

## 2. 아키텍처

### 2.1 변경 범위

```
┌─────────────────────────────────────────────────────────────┐
│                     Presentation Layer                       │
│  ┌───────────────────┐  ┌────────────────────────────────┐  │
│  │ PaymentMethodList │  │ PaymentMethodDonutChart        │  │
│  │ (영향 없음)        │  │ (영향 없음)                    │  │
│  └───────────────────┘  └────────────────────────────────┘  │
├─────────────────────────────────────────────────────────────┤
│                       Domain Layer                           │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ PaymentMethodStatistics (영향 없음 - 기존 필드 활용)   │  │
│  └───────────────────────────────────────────────────────┘  │
├─────────────────────────────────────────────────────────────┤
│                        Data Layer                            │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ StatisticsRepository.getPaymentMethodStatistics()     │  │
│  │ ★ 핵심 변경 대상 ★                                    │  │
│  │ - 그룹 키 생성 로직 수정                               │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 데이터 흐름

```
[Before - 현재]
transactions → payment_method_id로 그룹화 → 개별 통계

[After - 변경 후]
transactions → can_auto_save 확인
  ├─ true  → name으로 그룹화 (합산)
  └─ false → payment_method_id로 그룹화 (기존 동작)
```

## 3. 상세 설계

### 3.1 그룹 키 생성 로직

```dart
/// 결제수단 그룹 키 생성
///
/// - 자동수집 결제수단 (can_auto_save=true): 이름 기준 그룹화
/// - 공유 결제수단 (can_auto_save=false): UUID 기준 그룹화
/// - 결제수단 없음: '_no_payment_method_'
String _getPaymentMethodGroupKey({
  required String? paymentMethodId,
  required String? name,
  required bool canAutoSave,
}) {
  // 결제수단 없는 경우
  if (paymentMethodId == null) {
    return '_no_payment_method_';
  }

  // 자동수집 결제수단: 이름 기준 그룹화
  if (canAutoSave && name != null && name.isNotEmpty) {
    return 'auto_$name';
  }

  // 공유 결제수단: UUID 기준 그룹화 (기존 동작)
  return paymentMethodId;
}
```

### 3.2 Repository 메서드 수정

**파일**: `lib/features/statistics/data/repositories/statistics_repository.dart`

**메서드**: `getPaymentMethodStatistics()`

```dart
Future<List<PaymentMethodStatistics>> getPaymentMethodStatistics({
  required String ledgerId,
  required int year,
  required int month,
  required String type,
}) async {
  final startDate = DateTime(year, month, 1);
  final endDate = DateTime(year, month + 1, 0);

  final response = await _client
      .from('transactions')
      .select(
        'amount, payment_method_id, payment_methods(name, icon, color, can_auto_save)',
      )
      .eq('ledger_id', ledgerId)
      .eq('type', type)
      .gte('date', startDate.toIso8601String().split('T').first)
      .lte('date', endDate.toIso8601String().split('T').first);

  final Map<String, PaymentMethodStatistics> grouped = {};
  int totalAmount = 0;

  for (final row in response as List) {
    final rowMap = row as Map<String, dynamic>;
    final paymentMethodIdValue = rowMap['payment_method_id'];
    final paymentMethodId = paymentMethodIdValue?.toString();
    final amount = (rowMap['amount'] as num?)?.toInt() ?? 0;
    final paymentMethod = rowMap['payment_methods'] as Map<String, dynamic>?;

    totalAmount += amount;

    // 결제수단 정보 추출
    String pmName = '미지정';
    String pmIcon = '';
    String pmColor = '#9E9E9E';
    bool canAutoSave = false;

    if (paymentMethod != null) {
      pmName = paymentMethod['name']?.toString() ?? '미지정';
      pmIcon = paymentMethod['icon']?.toString() ?? '';
      pmColor = paymentMethod['color']?.toString() ?? '#9E9E9E';
      canAutoSave = paymentMethod['can_auto_save'] == true;
    }

    // [핵심 변경] 그룹 키 생성 로직
    final groupKey = _getPaymentMethodGroupKey(
      paymentMethodId: paymentMethodId,
      name: pmName,
      canAutoSave: canAutoSave,
    );

    if (grouped.containsKey(groupKey)) {
      // 기존 그룹에 금액 합산
      grouped[groupKey] = grouped[groupKey]!.copyWith(
        amount: grouped[groupKey]!.amount + amount,
      );
    } else {
      // 새 그룹 생성 (첫 번째 발견된 메타데이터 사용)
      grouped[groupKey] = PaymentMethodStatistics(
        paymentMethodId: groupKey,
        paymentMethodName: pmName,
        paymentMethodIcon: pmIcon,
        paymentMethodColor: pmColor,
        canAutoSave: canAutoSave,
        amount: amount,
        percentage: 0,
      );
    }
  }

  // 비율 계산 및 정렬
  final result = grouped.values.map((item) {
    final percentage = totalAmount > 0
        ? (item.amount / totalAmount) * 100
        : 0.0;
    return item.copyWith(percentage: percentage);
  }).toList()..sort((a, b) => b.amount.compareTo(a.amount));

  return result;
}
```

### 3.3 엔티티 설계 (변경 없음)

`PaymentMethodStatistics` 엔티티는 현재 구조로 충분합니다.

```dart
class PaymentMethodStatistics {
  final String paymentMethodId;     // 그룹 키 (auto_이름 또는 UUID)
  final String paymentMethodName;   // 표시 이름
  final String paymentMethodIcon;   // 아이콘
  final String paymentMethodColor;  // 색상
  final bool canAutoSave;           // 자동수집 여부 (뱃지 표시용)
  final int amount;                 // 합산 금액
  final double percentage;          // 비율
  // ...
}
```

## 4. 구현 순서

### 4.1 단계별 구현

| 순서 | 작업 | 파일 | 설명 |
|------|------|------|------|
| 1 | 헬퍼 함수 추가 | `statistics_repository.dart` | `_getPaymentMethodGroupKey()` 메서드 추가 |
| 2 | 그룹화 로직 수정 | `statistics_repository.dart` | `getPaymentMethodStatistics()` 내 groupKey 생성 로직 변경 |
| 3 | 테스트 | - | 시나리오별 검증 |

### 4.2 코드 변경 상세

**변경 전 (현재 코드 - 라인 452-456)**:
```dart
if (paymentMethodId == null) {
  groupKey = '_no_payment_method_';
} else {
  groupKey = paymentMethodId;
}
```

**변경 후**:
```dart
final groupKey = _getPaymentMethodGroupKey(
  paymentMethodId: paymentMethodId,
  name: pmName,
  canAutoSave: canAutoSave,
);
```

## 5. 테스트 케이스

### 5.1 단위 테스트

```dart
// test/features/statistics/data/repositories/statistics_repository_test.dart

group('getPaymentMethodStatistics - 자동수집 결제수단 합산', () {
  test('동일 이름의 자동수집 결제수단은 합산되어야 함', () async {
    // Given: 사용자A의 KB국민카드 10,000원, 사용자B의 KB국민카드 20,000원
    // When: getPaymentMethodStatistics 호출
    // Then: KB국민카드 = 30,000원 (1개)
  });

  test('공유 결제수단은 기존처럼 개별 표시되어야 함', () async {
    // Given: 공유 결제수단 '현금' 15,000원
    // When: getPaymentMethodStatistics 호출
    // Then: 현금 = 15,000원 (UUID 기준)
  });

  test('자동수집과 공유 결제수단 혼합 시나리오', () async {
    // Given: 자동수집 KB국민카드 30,000원 (합산), 공유 현금 15,000원
    // When: getPaymentMethodStatistics 호출
    // Then: 총 2개 항목 (KB국민카드, 현금)
  });

  test('결제수단 없는 거래는 미지정으로 표시', () async {
    // Given: payment_method_id가 null인 거래
    // When: getPaymentMethodStatistics 호출
    // Then: '미지정' 항목으로 표시
  });
});
```

### 5.2 통합 테스트 시나리오

| 시나리오 | 입력 데이터 | 예상 결과 |
|----------|-------------|-----------|
| 기본 합산 | A: KB 10,000원, B: KB 20,000원 | KB국민카드 = 30,000원 |
| 혼합 | 자동수집 KB 30,000원 + 공유 현금 15,000원 | 2개 항목 |
| 개인 가계부 | 내 KB 10,000원, 내 현금 5,000원 | 2개 항목 (기존 동작) |
| 미지정 | payment_method_id = null | 미지정 표시 |

## 6. 엣지 케이스 처리

### 6.1 특수 문자 처리

그룹 키에 `auto_` 접두사를 사용하므로 결제수단 이름에 특수문자가 있어도 안전합니다.

```dart
// 예시
'KB국민카드' → 'auto_KB국민카드'
'현금 (생활비)' → 'auto_현금 (생활비)'
```

### 6.2 빈 이름 처리

```dart
if (canAutoSave && name != null && name.isNotEmpty) {
  return 'auto_$name';
}
```

`name`이 null이거나 빈 문자열이면 UUID 기준으로 처리됩니다.

### 6.3 색상/아이콘 일관성

합산된 결제수단의 색상/아이콘은 **첫 번째 발견된 값**을 사용합니다.
- 쿼리 결과의 순서에 따라 결정됨
- 대부분의 경우 같은 이름의 결제수단은 동일한 색상/아이콘을 가짐

## 7. 성능 고려사항

### 7.1 시간 복잡도
- 기존: O(n) - 모든 거래를 순회하며 그룹화
- 변경 후: O(n) - 동일 (추가 쿼리 없음)

### 7.2 공간 복잡도
- 기존: O(m) - m = 고유 payment_method_id 수
- 변경 후: O(m') - m' = 고유 그룹 키 수 (자동수집 합산으로 감소 가능)

## 8. UI 영향 분석

### 8.1 영향 없는 컴포넌트

| 컴포넌트 | 이유 |
|----------|------|
| `PaymentMethodList` | `PaymentMethodStatistics` 리스트를 그대로 렌더링 |
| `PaymentMethodDonutChart` | 동일한 데이터 구조 사용 |
| 뱃지 표시 | `canAutoSave` 필드 기존 활용 |

### 8.2 표시 결과 변화

| 항목 | 변경 전 | 변경 후 |
|------|---------|---------|
| 결제수단 수 | 3개 (A의 KB, B의 KB, 현금) | 2개 (KB, 현금) |
| 금액 | 개별 표시 | 합산 표시 |
| 비율 | 개별 비율 | 합산 비율 |

## 9. 롤백 계획

변경이 문제가 될 경우:

```dart
// 롤백: 기존 로직으로 복원
final groupKey = paymentMethodId ?? '_no_payment_method_';
```

## 10. 체크리스트

### 10.1 구현 전
- [x] Plan 문서 검토
- [x] 현재 코드 분석
- [x] Design 문서 작성

### 10.2 구현 중
- [ ] `_getPaymentMethodGroupKey()` 헬퍼 함수 추가
- [ ] `getPaymentMethodStatistics()` 그룹화 로직 수정
- [ ] 코드 포맷팅 및 린트 검사

### 10.3 구현 후
- [ ] 기본 시나리오 테스트
- [ ] 혼합 시나리오 테스트
- [ ] 엣지 케이스 테스트
- [ ] Gap 분석 실행

---

**작성일**: 2026-02-05
**상태**: Design 완료, Do 대기
**참조 Plan**: `statistics-payment-method-merge.plan.md`
