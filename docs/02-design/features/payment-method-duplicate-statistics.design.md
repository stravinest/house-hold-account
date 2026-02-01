# Design: 결제수단 중복 관리 및 통계 표시 개선

**Feature ID**: `payment-method-duplicate-statistics`
**작성일**: 2026-02-01
**작성자**: AI Assistant
**PDCA Phase**: Design
**Plan 문서**: [payment-method-duplicate-statistics.plan.md](../../01-plan/features/payment-method-duplicate-statistics.plan.md)

---

## 1. 아키텍처 설계 (Architecture Design)

### 1.1 레이어 구조

```
┌─────────────────────────────────────────────────────┐
│ Presentation Layer (UI)                             │
│  - payment_method_list.dart                         │
│  - payment_method_donut_chart.dart                  │
│  - _PaymentMethodBadge 위젯 (신규)                  │
└─────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────┐
│ Domain Layer (Entities)                             │
│  - PaymentMethodStatistics (수정)                   │
│    + canAutoSave: bool 필드 추가                    │
└─────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────┐
│ Data Layer (Repository)                             │
│  - StatisticsRepository                             │
│    - getPaymentMethodStatistics() 수정              │
│      + can_auto_save 필드 조회 추가                 │
└─────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────┐
│ Database (Supabase)                                 │
│  - payment_methods.can_auto_save (기존 컬럼)        │
└─────────────────────────────────────────────────────┘
```

### 1.2 데이터 흐름

```
1. 사용자가 통계 탭 진입
   ↓
2. StatisticsRepository.getPaymentMethodStatistics() 호출
   ↓
3. Supabase 쿼리: payment_methods(name, icon, color, can_auto_save) 조회
   ↓
4. PaymentMethodStatistics 엔티티 생성 (canAutoSave 포함)
   ↓
5. PaymentMethodList 위젯에서 뱃지 표시
   - canAutoSave == true → '자동수집' 뱃지
   - canAutoSave == false → '공유' 뱃지
```

---

## 2. 데이터 모델 설계 (Data Model Design)

### 2.1 PaymentMethodStatistics 엔티티 수정

**파일**: `lib/features/statistics/domain/entities/statistics_entities.dart`

**현재 코드** (Line 51-85):
```dart
class PaymentMethodStatistics {
  final String paymentMethodId;
  final String paymentMethodName;
  final String paymentMethodIcon;
  final String paymentMethodColor;
  final int amount;
  final double percentage;

  const PaymentMethodStatistics({
    required this.paymentMethodId,
    required this.paymentMethodName,
    required this.paymentMethodIcon,
    required this.paymentMethodColor,
    required this.amount,
    required this.percentage,
  });

  PaymentMethodStatistics copyWith({
    String? paymentMethodId,
    String? paymentMethodName,
    String? paymentMethodIcon,
    String? paymentMethodColor,
    int? amount,
    double? percentage,
  }) {
    return PaymentMethodStatistics(
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      paymentMethodName: paymentMethodName ?? this.paymentMethodName,
      paymentMethodIcon: paymentMethodIcon ?? this.paymentMethodIcon,
      paymentMethodColor: paymentMethodColor ?? this.paymentMethodColor,
      amount: amount ?? this.amount,
      percentage: percentage ?? this.percentage,
    );
  }
}
```

**수정 후**:
```dart
class PaymentMethodStatistics {
  final String paymentMethodId;
  final String paymentMethodName;
  final String paymentMethodIcon;
  final String paymentMethodColor;
  final bool canAutoSave; // ✅ 추가
  final int amount;
  final double percentage;

  const PaymentMethodStatistics({
    required this.paymentMethodId,
    required this.paymentMethodName,
    required this.paymentMethodIcon,
    required this.paymentMethodColor,
    this.canAutoSave = false, // ✅ 기본값: false (공유 결제수단)
    required this.amount,
    required this.percentage,
  });

  PaymentMethodStatistics copyWith({
    String? paymentMethodId,
    String? paymentMethodName,
    String? paymentMethodIcon,
    String? paymentMethodColor,
    bool? canAutoSave, // ✅ 추가
    int? amount,
    double? percentage,
  }) {
    return PaymentMethodStatistics(
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      paymentMethodName: paymentMethodName ?? this.paymentMethodName,
      paymentMethodIcon: paymentMethodIcon ?? this.paymentMethodIcon,
      paymentMethodColor: paymentMethodColor ?? this.paymentMethodColor,
      canAutoSave: canAutoSave ?? this.canAutoSave, // ✅ 추가
      amount: amount ?? this.amount,
      percentage: percentage ?? this.percentage,
    );
  }
}
```

**변경 사항**:
1. `canAutoSave` 필드 추가 (기본값: `false`)
2. `copyWith()` 메서드에 `canAutoSave` 파라미터 추가
3. 기본값 설정으로 기존 코드와 호환성 유지

---

## 3. Repository 설계 (Repository Design)

### 3.1 StatisticsRepository.getPaymentMethodStatistics() 수정

**파일**: `lib/features/statistics/data/repositories/statistics_repository.dart`

**현재 코드** (Line 408-477):
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
      .select('amount, payment_method_id, payment_methods(name, icon, color)')
      .eq('ledger_id', ledgerId)
      .eq('type', type)
      .gte('date', startDate.toIso8601String().split('T').first)
      .lte('date', endDate.toIso8601String().split('T').first);

  // ... 그룹화 로직
}
```

**수정 후**:
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
      .select('amount, payment_method_id, payment_methods(name, icon, color, can_auto_save)') // ✅ can_auto_save 추가
      .eq('ledger_id', ledgerId)
      .eq('type', type)
      .gte('date', startDate.toIso8601String().split('T').first)
      .lte('date', endDate.toIso8601String().split('T').first);

  // 결제수단별로 그룹화
  final Map<String, PaymentMethodStatistics> grouped = {};
  int totalAmount = 0;

  for (final row in response as List) {
    final rowMap = row as Map<String, dynamic>;
    final paymentMethodId = rowMap['payment_method_id'].toString();
    final amount = (rowMap['amount'] as num?)?.toInt() ?? 0;
    final paymentMethod = rowMap['payment_methods'] as Map<String, dynamic>?;

    totalAmount += amount;

    final groupKey = paymentMethodId ?? '_no_payment_method_';

    // 결제수단 정보 추출
    String pmName = '미지정';
    String pmIcon = '';
    String pmColor = '#9E9E9E';
    bool canAutoSave = false; // ✅ 추가

    if (paymentMethod != null) {
      pmName = paymentMethod['name'].toString() ?? '미지정';
      pmIcon = paymentMethod['icon'].toString() ?? '';
      pmColor = paymentMethod['color'].toString() ?? '#9E9E9E';
      canAutoSave = paymentMethod['can_auto_save'] == true; // ✅ 추가
    }

    if (grouped.containsKey(groupKey)) {
      grouped[groupKey] = grouped[groupKey]!.copyWith(
        amount: grouped[groupKey]!.amount + amount,
      );
    } else {
      grouped[groupKey] = PaymentMethodStatistics(
        paymentMethodId: groupKey,
        paymentMethodName: pmName,
        paymentMethodIcon: pmIcon,
        paymentMethodColor: pmColor,
        canAutoSave: canAutoSave, // ✅ 추가
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

**변경 사항**:
1. Supabase 쿼리에 `can_auto_save` 필드 추가
2. `canAutoSave` 변수 선언 및 파싱 로직 추가
3. `PaymentMethodStatistics` 생성 시 `canAutoSave` 전달

---

## 4. UI 컴포넌트 설계 (UI Component Design)

### 4.1 PaymentMethodBadge 위젯 설계

**파일**: `lib/features/statistics/presentation/widgets/payment_method_tab/payment_method_list.dart`

**새로운 위젯 추가**:

```dart
/// 결제수단 유형 뱃지 (자동수집 / 공유)
class _PaymentMethodBadge extends StatelessWidget {
  final bool canAutoSave;
  final AppLocalizations l10n;

  const _PaymentMethodBadge({
    required this.canAutoSave,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 뱃지 색상 및 텍스트 결정
    final badgeColor = canAutoSave
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerHighest;

    final textColor = canAutoSave
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurfaceVariant;

    final badgeText = canAutoSave
        ? l10n.statisticsPaymentMethodAutoSave
        : l10n.statisticsPaymentMethodShared;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        badgeText,
        style: theme.textTheme.labelSmall?.copyWith(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
```

**디자인 토큰 준수**:
- 간격: `horizontal: 6px, vertical: 2px` (커스텀, 뱃지용)
- 모서리 반경: `4px` ($--radius-xs)
- 색상: `primaryContainer` (자동수집), `surfaceContainerHighest` (공유)
- 폰트 크기: `10px` (작은 뱃지)

### 4.2 PaymentMethodList 수정

**파일**: `lib/features/statistics/presentation/widgets/payment_method_tab/payment_method_list.dart`

**현재 코드** (Line 92-97):
```dart
// 결제수단명
Expanded(
  child: Text(
    item.paymentMethodName,
    style: theme.textTheme.bodyLarge,
  ),
),
```

**수정 후**:
```dart
// 결제수단명 + 뱃지
Expanded(
  child: Row(
    children: [
      // 결제수단명
      Flexible(
        child: Text(
          item.paymentMethodName,
          style: theme.textTheme.bodyLarge,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      const SizedBox(width: 4),
      // 뱃지
      _PaymentMethodBadge(
        canAutoSave: item.canAutoSave,
        l10n: l10n,
      ),
    ],
  ),
),
```

**변경 사항**:
1. `Text` 위젯을 `Row`로 감싸서 뱃지와 나란히 배치
2. 결제수단명을 `Flexible`로 감싸서 긴 이름 처리
3. `SizedBox(width: 4)`: 결제수단명과 뱃지 사이 간격
4. `_PaymentMethodBadge` 위젯 추가

### 4.3 레이아웃 구조

```
┌─────────────────────────────────────────────────────┐
│ [순위] [결제수단명] [뱃지]    [비율]    [금액]      │
│  1    수원페이    [자동수집]   40%    150,000원     │
│  2    KB Pay                  27%    100,000원     │
│  3    수원페이    [공유]       13%     50,000원     │
└─────────────────────────────────────────────────────┘
```

---

## 5. 다국어 지원 (i18n)

### 5.1 번역 키 추가

**파일**: `lib/l10n/app_ko.arb`

```json
{
  "statisticsPaymentMethodAutoSave": "자동수집",
  "@statisticsPaymentMethodAutoSave": {
    "description": "통계 화면 - 자동수집 결제수단 뱃지"
  },
  "statisticsPaymentMethodShared": "공유",
  "@statisticsPaymentMethodShared": {
    "description": "통계 화면 - 공유 결제수단 뱃지"
  }
}
```

**파일**: `lib/l10n/app_en.arb`

```json
{
  "statisticsPaymentMethodAutoSave": "Auto",
  "@statisticsPaymentMethodAutoSave": {
    "description": "Statistics screen - Auto-collect payment method badge"
  },
  "statisticsPaymentMethodShared": "Shared",
  "@statisticsPaymentMethodShared": {
    "description": "Statistics screen - Shared payment method badge"
  }
}
```

**번역 전략**:
- 한국어: '자동수집', '공유' (명확하고 간결)
- 영어: 'Auto', 'Shared' (짧게 유지, 뱃지 공간 고려)

---

## 6. 디자인 시스템 준수 (Design System Compliance)

### 6.1 색상 토큰

```dart
// 자동수집 뱃지
backgroundColor: theme.colorScheme.primaryContainer  // $--primary-container: #A8DAB5
textColor: theme.colorScheme.onPrimaryContainer      // $--on-primary-container: #00210B

// 공유 뱃지
backgroundColor: theme.colorScheme.surfaceContainerHighest // $--surface-container-highest: #E3E3DB
textColor: theme.colorScheme.onSurfaceVariant              // $--on-surface-variant: #44483E
```

### 6.2 간격 및 크기

```dart
뱃지 padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2)
뱃지-결제수단명 간격: SizedBox(width: 4)  // $--spacing-xs
모서리 반경: BorderRadius.circular(4)     // $--radius-xs
```

### 6.3 타이포그래피

```dart
뱃지 텍스트: theme.textTheme.labelSmall
  - fontSize: 10
  - fontWeight: FontWeight.w500
```

### 6.4 다크모드 호환성

- `theme.colorScheme.*` 사용으로 자동 대응
- 라이트/다크 모드 모두에서 충분한 대비 확보

---

## 7. 예외 처리 및 엣지 케이스 (Error Handling & Edge Cases)

### 7.1 예외 상황

| 상황 | 처리 방안 |
|------|-----------|
| `can_auto_save` 필드가 null | 기본값 `false`로 처리 (공유 결제수단으로 간주) |
| 결제수단명이 매우 긴 경우 | `Flexible` + `overflow: TextOverflow.ellipsis` |
| 뱃지가 화면 밖으로 나가는 경우 | `Expanded` 사용으로 레이아웃 조정 |
| Supabase 쿼리 실패 | 기존 에러 핸들링 유지 (`AsyncValue.error`) |

### 7.2 데이터 검증

```dart
// Repository 단에서 안전하게 파싱
canAutoSave = paymentMethod['can_auto_save'] == true;

// null 또는 다른 값이면 false로 처리
```

---

## 8. 성능 고려사항 (Performance Considerations)

### 8.1 쿼리 최적화

**변경 전**:
```sql
SELECT amount, payment_method_id, payment_methods(name, icon, color)
```

**변경 후**:
```sql
SELECT amount, payment_method_id, payment_methods(name, icon, color, can_auto_save)
```

**영향 분석**:
- 필드 1개 추가: 성능 영향 미미 (boolean 타입)
- 인덱스 영향 없음 (`can_auto_save`는 WHERE 조건이 아님)
- 네트워크 트래픽 증가: 무시할 수준

### 8.2 UI 렌더링

- 뱃지 위젯은 매우 가벼움 (단순 Container + Text)
- 리스트 아이템당 1개씩 추가되지만 성능 문제 없음
- `const` 생성자 활용으로 최적화

---

## 9. 테스트 시나리오 (Test Scenarios)

### 9.1 단위 테스트

**PaymentMethodStatistics 엔티티 테스트**:
```dart
test('PaymentMethodStatistics는 canAutoSave 기본값이 false여야 한다', () {
  final stats = PaymentMethodStatistics(
    paymentMethodId: 'pm1',
    paymentMethodName: '테스트',
    paymentMethodIcon: '💳',
    paymentMethodColor: '#000000',
    amount: 10000,
    percentage: 50.0,
  );

  expect(stats.canAutoSave, false);
});

test('copyWith()는 canAutoSave를 올바르게 복사해야 한다', () {
  final stats = PaymentMethodStatistics(
    paymentMethodId: 'pm1',
    paymentMethodName: '테스트',
    paymentMethodIcon: '💳',
    paymentMethodColor: '#000000',
    canAutoSave: true,
    amount: 10000,
    percentage: 50.0,
  );

  final copied = stats.copyWith(amount: 20000);
  expect(copied.canAutoSave, true);
  expect(copied.amount, 20000);
});
```

### 9.2 통합 테스트

**통계 Repository 테스트**:
```dart
test('getPaymentMethodStatistics는 can_auto_save를 올바르게 파싱해야 한다', () async {
  // Given: 자동수집 결제수단과 공유 결제수단이 DB에 존재
  // When: getPaymentMethodStatistics() 호출
  // Then: canAutoSave 필드가 올바르게 설정됨
});
```

### 9.3 UI 테스트

**뱃지 표시 테스트**:
```dart
testWidgets('자동수집 결제수단은 자동수집 뱃지를 표시해야 한다', (tester) async {
  // Given: canAutoSave = true인 PaymentMethodStatistics
  // When: PaymentMethodList 렌더링
  // Then: '자동수집' 텍스트가 표시됨
});

testWidgets('공유 결제수단은 공유 뱃지를 표시해야 한다', (tester) async {
  // Given: canAutoSave = false인 PaymentMethodStatistics
  // When: PaymentMethodList 렌더링
  // Then: '공유' 텍스트가 표시됨
});
```

### 9.4 E2E 테스트 시나리오

1. **시나리오 1: 자동수집 결제수단만 존재**
   - Given: '수원페이' 자동수집 결제수단 1개
   - When: 통계 탭 진입
   - Then: '수원페이 [자동수집]' 표시

2. **시나리오 2: 공유 결제수단만 존재**
   - Given: 'KB Pay' 공유 결제수단 1개
   - When: 통계 탭 진입
   - Then: 'KB Pay [공유]' 표시

3. **시나리오 3: 동일 이름의 중복 결제수단**
   - Given: '수원페이' 자동수집 + '수원페이' 공유
   - When: 통계 탭 진입
   - Then:
     - '수원페이 [자동수집] - 150,000원'
     - '수원페이 [공유] - 50,000원'
     - 두 개가 별도로 표시되며 뱃지로 구분 가능

---

## 10. 구현 순서 (Implementation Order)

### Phase 1: 데이터 모델 수정 ✅

1. `statistics_entities.dart` 수정
   - `PaymentMethodStatistics`에 `canAutoSave` 필드 추가
   - `copyWith()` 메서드 업데이트

### Phase 2: Repository 수정 ✅

2. `statistics_repository.dart` 수정
   - `getPaymentMethodStatistics()` 쿼리에 `can_auto_save` 추가
   - 파싱 로직 추가

### Phase 3: UI 컴포넌트 개발 ✅

3. `payment_method_list.dart` 수정
   - `_PaymentMethodBadge` 위젯 생성
   - `_PaymentMethodItem`에 뱃지 추가

### Phase 4: 다국어 지원 ✅

4. `app_ko.arb`, `app_en.arb` 수정
   - 번역 키 추가

### Phase 5: 테스트 (선택사항)

5. 단위 테스트 작성
6. 위젯 테스트 작성
7. E2E 테스트 실행

---

## 11. 파일 변경 목록 (File Change List)

| 파일 경로 | 변경 유형 | 설명 |
|----------|----------|------|
| `lib/features/statistics/domain/entities/statistics_entities.dart` | 수정 | `PaymentMethodStatistics`에 `canAutoSave` 필드 추가 |
| `lib/features/statistics/data/repositories/statistics_repository.dart` | 수정 | `getPaymentMethodStatistics()` 쿼리 수정 |
| `lib/features/statistics/presentation/widgets/payment_method_tab/payment_method_list.dart` | 수정 | `_PaymentMethodBadge` 위젯 추가, `_PaymentMethodItem` 수정 |
| `lib/l10n/app_ko.arb` | 수정 | 번역 키 추가 |
| `lib/l10n/app_en.arb` | 수정 | 번역 키 추가 |

**총 5개 파일 수정**

---

## 12. 승인 및 검토 (Approval)

### 12.1 설계 체크리스트

- [x] 아키텍처 레이어 분리 준수
- [x] 데이터 모델 설계 완료
- [x] UI 컴포넌트 설계 완료
- [x] 디자인 시스템 준수
- [x] 다국어 지원 설계
- [x] 예외 처리 고려
- [x] 성능 영향 분석
- [x] 테스트 시나리오 작성

### 12.2 리스크 평가

| 리스크 | 확률 | 영향도 | 대응 방안 |
|--------|------|--------|-----------|
| 기존 코드 호환성 문제 | 낮음 | 중 | 기본값 설정으로 해결 |
| UI 레이아웃 깨짐 | 낮음 | 하 | Flexible + overflow 처리 |
| 성능 저하 | 매우 낮음 | 하 | 필드 1개 추가로 영향 미미 |

### 12.3 다음 단계

**Do 단계**: 구현 시작
```bash
/pdca do payment-method-duplicate-statistics
```

---

**Design 문서 작성 완료**
작성일: 2026-02-01
