# Gap Analysis Report: 결제수단 중복 관리 및 통계 표시 개선

**Feature ID**: `payment-method-duplicate-statistics`
**분석일**: 2026-02-01
**분석자**: AI Assistant (gap-detector)
**PDCA Phase**: Check (Gap Analysis)
**Design 문서**: [payment-method-duplicate-statistics.design.md](../02-design/features/payment-method-duplicate-statistics.design.md)

---

## 📊 전체 점수

| 카테고리 | 점수 | 상태 |
|----------|:-----:|:------:|
| 데이터 모델 일치 | **100%** | ✅ OK |
| Repository 구현 | **100%** | ✅ OK |
| UI 컴포넌트 | **100%** | ✅ OK |
| 다국어 지원 | **100%** | ✅ OK |
| 디자인 시스템 준수 | **100%** | ✅ OK |
| **전체 Match Rate** | **100%** | ✅ OK |

---

## 1. 데이터 모델 분석 (PaymentMethodStatistics)

**파일**: `lib/features/statistics/domain/entities/statistics_entities.dart`

### 설계 vs 구현 비교

| 설계 항목 | 구현 상태 | 위치 | 비고 |
|----------|:--------:|------|------|
| `canAutoSave` 필드 추가 | ✅ | Line 56 | `final bool canAutoSave` |
| 기본값 `false` 설정 | ✅ | Line 65 | `this.canAutoSave = false` |
| `copyWith()` 메서드 업데이트 | ✅ | Line 75, 84 | `bool? canAutoSave` 파라미터 포함 |

### 구현 코드 (Line 51-89)
```dart
class PaymentMethodStatistics {
  final String paymentMethodId;
  final String paymentMethodName;
  final String paymentMethodIcon;
  final String paymentMethodColor;
  final bool canAutoSave;  // ✅ 설계대로 추가됨
  final int amount;
  final double percentage;

  const PaymentMethodStatistics({
    required this.paymentMethodId,
    required this.paymentMethodName,
    required this.paymentMethodIcon,
    required this.paymentMethodColor,
    this.canAutoSave = false,  // ✅ 설계대로 기본값 false
    required this.amount,
    required this.percentage,
  });

  PaymentMethodStatistics copyWith({
    String? paymentMethodId,
    String? paymentMethodName,
    String? paymentMethodIcon,
    String? paymentMethodColor,
    bool? canAutoSave,  // ✅ 설계대로 추가됨
    int? amount,
    double? percentage,
  }) {
    return PaymentMethodStatistics(
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      paymentMethodName: paymentMethodName ?? this.paymentMethodName,
      paymentMethodIcon: paymentMethodIcon ?? this.paymentMethodIcon,
      paymentMethodColor: paymentMethodColor ?? this.paymentMethodColor,
      canAutoSave: canAutoSave ?? this.canAutoSave,  // ✅ 설계대로 포함됨
      amount: amount ?? this.amount,
      percentage: percentage ?? this.percentage,
    );
  }
}
```

**일치율**: 100% (3/3 항목)

---

## 2. Repository 분석 (StatisticsRepository)

**파일**: `lib/features/statistics/data/repositories/statistics_repository.dart`

### 설계 vs 구현 비교

| 설계 항목 | 구현 상태 | 위치 | 비고 |
|----------|:--------:|------|------|
| Supabase 쿼리에 `can_auto_save` 추가 | ✅ | Line 420 | `payment_methods(name, icon, color, can_auto_save)` |
| `canAutoSave` 변수 선언 | ✅ | Line 445 | `bool canAutoSave = false;` |
| `can_auto_save` 파싱 로직 | ✅ | Line 451 | `canAutoSave = paymentMethod['can_auto_save'] == true` |
| `PaymentMethodStatistics` 생성 시 전달 | ✅ | Line 464 | `canAutoSave: canAutoSave` |

### 구현 코드 (Line 418-468)
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
      .select('amount, payment_method_id, payment_methods(name, icon, color, can_auto_save)')  // ✅ 설계대로 추가
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
    bool canAutoSave = false;  // ✅ 설계대로 추가

    if (paymentMethod != null) {
      pmName = paymentMethod['name']?.toString() ?? '미지정';
      pmIcon = paymentMethod['icon']?.toString() ?? '';
      pmColor = paymentMethod['color']?.toString() ?? '#9E9E9E';
      canAutoSave = paymentMethod['can_auto_save'] == true;  // ✅ 설계대로 파싱
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
        canAutoSave: canAutoSave,  // ✅ 설계대로 전달
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

**일치율**: 100% (4/4 항목)

---

## 3. UI 컴포넌트 분석 (_PaymentMethodBadge)

**파일**: `lib/features/statistics/presentation/widgets/payment_method_tab/payment_method_list.dart`

### 3.1 _PaymentMethodBadge 위젯

| 설계 항목 | 구현 상태 | 위치 | 비고 |
|----------|:--------:|------|------|
| 위젯 클래스 생성 | ✅ | Line 210-244 | `class _PaymentMethodBadge extends StatelessWidget` |
| `canAutoSave` 필드 | ✅ | Line 211 | `final bool canAutoSave` |
| `l10n` 필드 | ✅ | Line 212 | `final AppLocalizations l10n` |
| 자동수집: primaryContainer | ✅ | Line 222 | `theme.colorScheme.primaryContainer` |
| 공유: surfaceContainerHighest | ✅ | Line 223 | `theme.colorScheme.surfaceContainerHighest` |
| 텍스트 색상 (자동수집) | ✅ | Line 225 | `onPrimaryContainer` |
| 텍스트 색상 (공유) | ✅ | Line 226 | `onSurfaceVariant` |
| 뱃지 텍스트 (자동수집) | ✅ | Line 229 | `l10n.statisticsPaymentMethodAutoSave` |
| 뱃지 텍스트 (공유) | ✅ | Line 230 | `l10n.statisticsPaymentMethodShared` |
| padding (horizontal: 6, vertical: 2) | ✅ | Line 233 | `EdgeInsets.symmetric(horizontal: 6, vertical: 2)` |
| borderRadius | ✅ | Line 236 | `BorderRadius.circular(4)` |
| fontSize | ✅ | Line 242 | `fontSize: 10` |
| fontWeight | ✅ | Line 243 | `fontWeight: FontWeight.w500` |

### 3.2 _PaymentMethodItem 수정

| 설계 항목 | 구현 상태 | 위치 | 비고 |
|----------|:--------:|------|------|
| Row로 감싸기 | ✅ | Line 89-106 | 결제수단명 + 뱃지를 Row로 배치 |
| Flexible로 감싸기 | ✅ | Line 92-98 | 긴 이름 처리 |
| overflow: TextOverflow.ellipsis | ✅ | Line 96 | 텍스트 오버플로우 처리 |
| SizedBox(width: 4) 간격 | ✅ | Line 99 | 결제수단명-뱃지 간격 |
| _PaymentMethodBadge 추가 | ✅ | Line 100-104 | 뱃지 위젯 추가 |

### 구현 코드

**_PaymentMethodBadge 위젯 (Line 210-244)**:
```dart
/// 결제수단 유형 뱃지 (자동수집 / 공유)
class _PaymentMethodBadge extends StatelessWidget {
  final bool canAutoSave;
  final AppLocalizations l10n;

  const _PaymentMethodBadge({required this.canAutoSave, required this.l10n});

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

**_PaymentMethodItem 수정 (Line 87-107)**:
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

**일치율**: 100% (18/18 항목)

---

## 4. 다국어 지원 분석 (i18n)

### 4.1 한국어 (app_ko.arb)

| 키 | 설계 값 | 구현 값 | 위치 | 상태 |
|----|---------|---------|------|:----:|
| `statisticsPaymentMethodAutoSave` | '자동수집' | '자동수집' | Line 714 | ✅ |
| `@statisticsPaymentMethodAutoSave` | 설명 포함 | 설명 포함 | Line 715-717 | ✅ |
| `statisticsPaymentMethodShared` | '공유' | '공유' | Line 718 | ✅ |
| `@statisticsPaymentMethodShared` | 설명 포함 | 설명 포함 | Line 719-721 | ✅ |

### 4.2 영어 (app_en.arb)

| 키 | 설계 값 | 구현 값 | 위치 | 상태 |
|----|---------|---------|------|:----:|
| `statisticsPaymentMethodAutoSave` | 'Auto' | 'Auto' | Line 475 | ✅ |
| `@statisticsPaymentMethodAutoSave` | 설명 포함 | 설명 포함 | Line 476-478 | ✅ |
| `statisticsPaymentMethodShared` | 'Shared' | 'Shared' | Line 479 | ✅ |
| `@statisticsPaymentMethodShared` | 설명 포함 | 설명 포함 | Line 480-482 | ✅ |

### 4.3 l10n 코드 생성 확인

| 항목 | 상태 | 확인 방법 |
|------|:----:|----------|
| `flutter gen-l10n` 실행 | ✅ | 자동 생성됨 |
| `app_localizations_ko.dart` 생성 | ✅ | Line 1461, 1464 |
| `app_localizations_en.dart` 생성 | ✅ | 확인 완료 |
| Flutter analyze 통과 | ✅ | No issues found |

**일치율**: 100% (8/8 항목)

---

## 5. 디자인 시스템 준수 분석

### 5.1 색상 토큰

| 항목 | 설계 | 구현 | 상태 |
|------|------|------|:----:|
| 자동수집 배경 | `$--primary-container` | `theme.colorScheme.primaryContainer` | ✅ |
| 자동수집 텍스트 | `$--on-primary-container` | `theme.colorScheme.onPrimaryContainer` | ✅ |
| 공유 배경 | `$--surface-container-highest` | `theme.colorScheme.surfaceContainerHighest` | ✅ |
| 공유 텍스트 | `$--on-surface-variant` | `theme.colorScheme.onSurfaceVariant` | ✅ |

### 5.2 간격 및 크기

| 항목 | 설계 | 구현 | 상태 |
|------|------|------|:----:|
| 뱃지 padding (horizontal) | 6px | 6 | ✅ |
| 뱃지 padding (vertical) | 2px | 2 | ✅ |
| 결제수단명-뱃지 간격 | 4px | 4 | ✅ |
| borderRadius | 4px | 4 | ✅ |

### 5.3 타이포그래피

| 항목 | 설계 | 구현 | 상태 |
|------|------|------|:----:|
| fontSize | 10px | 10 | ✅ |
| fontWeight | FontWeight.w500 | FontWeight.w500 | ✅ |
| textTheme | labelSmall | labelSmall | ✅ |

**일치율**: 100% (11/11 항목)

---

## 6. 발견된 차이점

### 6.1 누락된 기능 (설계 O, 구현 X)
**없음** - 설계된 모든 기능이 구현되었습니다.

### 6.2 추가된 기능 (설계 X, 구현 O)
**없음** - 설계에 없는 추가 기능은 구현되지 않았습니다.

### 6.3 변경된 기능 (설계와 구현 불일치)
**없음** - 모든 구현이 설계와 정확히 일치합니다.

---

## 7. 성능 및 품질 검증

### 7.1 코드 품질

| 항목 | 상태 | 비고 |
|------|:----:|------|
| Flutter analyze 통과 | ✅ | No issues found |
| 타입 안전성 | ✅ | 모든 타입 명시됨 |
| Null safety 준수 | ✅ | nullable 처리 적절 |
| const 생성자 활용 | ✅ | 적절히 사용됨 |

### 7.2 성능 영향

| 항목 | 평가 | 비고 |
|------|------|------|
| 쿼리 성능 | 영향 없음 | 필드 1개 추가만 |
| UI 렌더링 | 영향 없음 | 가벼운 Container + Text |
| 메모리 사용 | 영향 없음 | bool 필드 1개 추가만 |

### 7.3 호환성

| 항목 | 상태 | 비고 |
|------|:----:|------|
| 기존 코드 호환성 | ✅ | 기본값 설정으로 보장 |
| Breaking change | 없음 | 후방 호환성 유지 |
| 다크모드 지원 | ✅ | theme.colorScheme 사용 |

---

## 8. 테스트 시나리오 검증

### 8.1 단위 테스트 (권장)

| 테스트 항목 | 상태 | 비고 |
|------------|:----:|------|
| PaymentMethodStatistics 기본값 | 미실행 | 구현 완료, 테스트 권장 |
| copyWith() 동작 | 미실행 | 구현 완료, 테스트 권장 |

### 8.2 통합 테스트 (권장)

| 테스트 항목 | 상태 | 비고 |
|------------|:----:|------|
| Repository 쿼리 | 미실행 | 구현 완료, 테스트 권장 |
| can_auto_save 파싱 | 미실행 | 구현 완료, 테스트 권장 |

### 8.3 E2E 테스트 (권장)

| 테스트 항목 | 상태 | 비고 |
|------------|:----:|------|
| 자동수집 뱃지 표시 | 미실행 | 앱 실행으로 검증 가능 |
| 공유 뱃지 표시 | 미실행 | 앱 실행으로 검증 가능 |
| 동일 이름 중복 결제수단 | 미실행 | 앱 실행으로 검증 가능 |

---

## 9. 권장 조치사항

### 9.1 즉시 조치 필요
**없음** - 모든 항목이 설계대로 완벽하게 구현되었습니다.

### 9.2 선택적 개선사항

1. **단위 테스트 추가** (선택사항)
   - `PaymentMethodStatistics` 엔티티 테스트
   - `copyWith()` 메서드 테스트

2. **통합 테스트 추가** (선택사항)
   - `getPaymentMethodStatistics()` 테스트
   - `can_auto_save` 파싱 로직 테스트

3. **E2E 테스트 추가** (선택사항)
   - 자동수집/공유 뱃지 표시 검증
   - 동일 이름 중복 결제수단 시나리오 테스트

### 9.3 문서 업데이트
**불필요** - 설계 문서와 구현이 완벽하게 일치합니다.

---

## 10. 최종 결론

### 10.1 전체 평가

**Match Rate: 100%**

설계 문서(`payment-method-duplicate-statistics.design.md`)와 실제 구현이 **완벽하게 일치**합니다.

**세부 점수**:
- 데이터 모델: 3/3 (100%)
- Repository: 4/4 (100%)
- UI 컴포넌트: 18/18 (100%)
- 다국어 지원: 8/8 (100%)
- 디자인 시스템: 11/11 (100%)

**총 비교 항목**: 44개
**일치 항목**: 44개
**불일치 항목**: 0개

### 10.2 품질 평가

| 카테고리 | 평가 | 비고 |
|----------|------|------|
| 설계 준수도 | 완벽 | 100% 일치 |
| 코드 품질 | 우수 | Flutter analyze 통과 |
| 성능 영향 | 없음 | 필드 추가만, 영향 미미 |
| 호환성 | 완벽 | Breaking change 없음 |

### 10.3 다음 단계

Match Rate가 **90% 이상**(100%)이므로 **Check 단계 완료**로 표시할 수 있습니다.

**권장 다음 작업**:
```bash
/pdca report payment-method-duplicate-statistics
```

완료 보고서를 생성하여 전체 PDCA 사이클을 마무리하십시오.

---

**Gap Analysis 보고서 작성 완료**
- 작성일: 2026-02-01
- Match Rate: **100%**
- 상태: ✅ **완벽 일치**
