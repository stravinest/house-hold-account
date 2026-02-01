# Design: 자동수집 제안 모드 버그 수정

## 1. 설계 개요

### 참조 문서
- **Plan**: `docs/01-plan/features/auto-collect-suggest-mode-bug.plan.md`
- **조사 결과**: 데이터베이스 조회 및 코드 분석 완료 (2026-02-01)

### 확인된 근본 원인

#### 문제: `getAutoSaveEnabledPaymentMethods`가 owner 필터링 없음

**현재 코드** (`payment_method_repository.dart:255-268`):
```dart
Future<List<PaymentMethodModel>> getAutoSaveEnabledPaymentMethods(
  String ledgerId,
) async {
  final response = await _client
      .from('payment_methods')
      .select()
      .eq('ledger_id', ledgerId)
      .neq('auto_save_mode', 'manual')
      .order('sort_order');  // ⚠️ owner_user_id 필터링 없음!

  return (response as List)
      .map((json) => PaymentMethodModel.fromJson(json))
      .toList();
}
```

**버그 시나리오**:

```
가계부 ID: 4cb99897-9d54-4620-b57d-d527c3ec278f
  ├─ 사용자 aa8b0aa2 (로그인 사용자)
  │   └─ 수원페이 (suggest 모드)  ← 사용자가 설정한 것
  │
  └─ 사용자 a183b04e (공유 멤버)
      └─ 수원페이 (auto 모드)  ← 다른 사용자의 것

알림 수신 시:
1. _loadAutoSavePaymentMethods() → 2개의 "수원페이" 로드
2. _findMatchingPaymentMethod() → Fallback 매칭
3. "수원페이"라는 이름으로 매칭 시도
4. sort_order에 따라 auto 모드가 먼저 매칭됨!
5. shouldAutoSave = true → 자동 저장됨 ❌
```

**데이터베이스 증거**:

| payment_method_id | owner | auto_save_mode | 최근 거래 status |
|-------------------|-------|----------------|------------------|
| 2d32fdd0... | a183b04e | **auto** | confirmed ❌ |
| 845c49c5... | aa8b0aa2 | suggest | (없음) |

### 설계 목표

1. **owner 필터링 추가**: 자기 결제수단만 로드
2. **Fallback 매칭 개선**: owner 검증 추가
3. **로그 강화**: 디버깅 용이성 향상
4. **Realtime 동기화**: 설정 변경 즉시 반영

## 2. 상세 설계

### 수정 1: `getAutoSaveEnabledPaymentMethods` owner 필터링 추가

#### 목적
- **공유 가계부에서 자기 결제수단만** 자동수집 대상으로 로드
- 다른 사용자의 결제수단이 매칭되는 것을 원천 차단

#### 수정 대상
- `lib/features/payment_method/data/repositories/payment_method_repository.dart`

#### AS-IS (Before)

```dart
Future<List<PaymentMethodModel>> getAutoSaveEnabledPaymentMethods(
  String ledgerId,
) async {
  final response = await _client
      .from('payment_methods')
      .select()
      .eq('ledger_id', ledgerId)
      .neq('auto_save_mode', 'manual')
      .order('sort_order');

  return (response as List)
      .map((json) => PaymentMethodModel.fromJson(json))
      .toList();
}
```

#### TO-BE (After)

```dart
Future<List<PaymentMethodModel>> getAutoSaveEnabledPaymentMethods(
  String ledgerId,
  String ownerUserId,  // ✅ 추가
) async {
  final response = await _client
      .from('payment_methods')
      .select()
      .eq('ledger_id', ledgerId)
      .eq('owner_user_id', ownerUserId)  // ✅ 추가: 자기 결제수단만
      .neq('auto_save_mode', 'manual')
      .order('sort_order');

  return (response as List)
      .map((json) => PaymentMethodModel.fromJson(json))
      .toList();
}
```

#### 영향 범위

**호출 위치**: `notification_listener_wrapper.dart:330-339`

**AS-IS**:
```dart
Future<void> _loadAutoSavePaymentMethods() async {
  if (_currentLedgerId == null) return;

  try {
    _autoSavePaymentMethods = await _paymentMethodRepository
        .getAutoSaveEnabledPaymentMethods(_currentLedgerId!);
  } catch (e) {
    debugPrint('Failed to load auto-save payment methods: $e');
    _autoSavePaymentMethods = [];
  }
}
```

**TO-BE**:
```dart
Future<void> _loadAutoSavePaymentMethods() async {
  if (_currentLedgerId == null || _currentUserId == null) return;  // ✅ userId 체크 추가

  try {
    _autoSavePaymentMethods = await _paymentMethodRepository
        .getAutoSaveEnabledPaymentMethods(
          _currentLedgerId!,
          _currentUserId!,  // ✅ 추가
        );
  } catch (e) {
    debugPrint('Failed to load auto-save payment methods: $e');
    _autoSavePaymentMethods = [];
  }
}
```

#### 동작 검증

**Before**:
```sql
SELECT * FROM payment_methods
WHERE ledger_id = '4cb99897-9d54-4620-b57d-d527c3ec278f'
  AND auto_save_mode != 'manual'
ORDER BY sort_order;

-- 결과: 2개의 "수원페이" (aa8b0aa2, a183b04e)
```

**After**:
```sql
SELECT * FROM payment_methods
WHERE ledger_id = '4cb99897-9d54-4620-b57d-d527c3ec278f'
  AND owner_user_id = 'aa8b0aa2-0160-4e33-a863-55ed41e98f24'  -- ✅
  AND auto_save_mode != 'manual'
ORDER BY sort_order;

-- 결과: 1개의 "수원페이" (aa8b0aa2만)
```

### 수정 2: Fallback 매칭 시 owner 검증 추가 (2차 방어선)

#### 목적
- 만약 캐시에 잘못된 데이터가 남아있어도 **매칭 시점에서 한 번 더 검증**
- Defense in Depth (심층 방어) 전략

#### 수정 대상
- `lib/features/payment_method/data/services/notification_listener_wrapper.dart`

#### AS-IS (line 604-618)

```dart
// 2. Fallback: 결제수단 이름이 내용에 포함되어 있는지 확인 (이름이 2자 이상인 경우만)
final pmName = pm.name.toLowerCase();
final nameMatches = pmName.length >= 2 && contentLower.contains(pmName);
if (kDebugMode) {
  debugPrint(
    '[Matching] Fallback: pmName="$pmName", matches=$nameMatches',
  );
}
if (nameMatches) {
  if (kDebugMode) {
    debugPrint('[Matching] Matched by payment method name!');
  }
  return _PaymentMethodMatchResult(paymentMethod: pm);
}
```

#### TO-BE

```dart
// 2. Fallback: 결제수단 이름이 내용에 포함되어 있는지 확인 (이름이 2자 이상인 경우만)
final pmName = pm.name.toLowerCase();
final nameMatches = pmName.length >= 2 && contentLower.contains(pmName);

// ✅ owner 검증 추가
final isOwner = pm.ownerUserId == _currentUserId;

if (kDebugMode) {
  debugPrint(
    '[Matching] Fallback: pmName="$pmName", matches=$nameMatches, isOwner=$isOwner',
  );
}

// ✅ 이름 매칭 + owner 일치 모두 확인
if (nameMatches && isOwner) {
  if (kDebugMode) {
    debugPrint('[Matching] Matched by payment method name!');
  }
  return _PaymentMethodMatchResult(paymentMethod: pm);
} else if (nameMatches && !isOwner) {
  // ✅ 이름은 일치하지만 owner가 다른 경우 경고 로그
  if (kDebugMode) {
    debugPrint('[Matching] WARNING: Name matched but owner mismatch!');
    debugPrint('  PM ID: ${pm.id}');
    debugPrint('  PM Owner: ${pm.ownerUserId}');
    debugPrint('  Current User: $_currentUserId');
  }
}
```

#### 효과

- **수정 1 실패 시에도** 잘못된 매칭 방지
- 디버깅 시 owner 불일치 문제를 명확히 확인 가능

### 수정 3: autoSaveMode 로그 강화

#### 목적
- 실제 사용된 autoSaveMode 값을 명확히 추적
- 캐시 상태와 최종 결정을 한눈에 확인

#### 수정 대상
- `lib/features/payment_method/data/services/notification_listener_wrapper.dart`

#### AS-IS (line 695-706)

```dart
// 캐시에서 최신 autoSaveMode 확인 (refreshPaymentMethods()로 동기화됨)
final cachedPaymentMethod = _autoSavePaymentMethods
    .where((pm) => pm.id == paymentMethod.id)
    .firstOrNull;
final autoSaveModeStr =
    cachedPaymentMethod?.autoSaveMode.toJson() ??
    paymentMethod.autoSaveMode.toJson();
if (kDebugMode) {
  debugPrint(
    'Notification matched: mode=$autoSaveModeStr (from cache), pm=${paymentMethod.name}',
  );
}
```

#### TO-BE

```dart
// 캐시에서 최신 autoSaveMode 확인 (refreshPaymentMethods()로 동기화됨)
final cachedPaymentMethod = _autoSavePaymentMethods
    .where((pm) => pm.id == paymentMethod.id)
    .firstOrNull;
final autoSaveModeStr =
    cachedPaymentMethod?.autoSaveMode.toJson() ??
    paymentMethod.autoSaveMode.toJson();

if (kDebugMode) {
  debugPrint('=== AutoSaveMode Decision ===');
  debugPrint('  PM ID: ${paymentMethod.id}');
  debugPrint('  PM Name: ${paymentMethod.name}');
  debugPrint('  PM Owner: ${paymentMethod.ownerUserId}');  // ✅ 추가
  debugPrint('  Current User: $_currentUserId');  // ✅ 추가
  debugPrint('  Original mode: ${paymentMethod.autoSaveMode.toJson()}');
  debugPrint('  Cached mode: ${cachedPaymentMethod?.autoSaveMode.toJson() ?? "not found"}');
  debugPrint('  Final mode: $autoSaveModeStr');
  debugPrint('  shouldAutoSave: ${!duplicateResult.isDuplicate && autoSaveModeStr == "auto"}');  // ✅ 미리 계산
  debugPrint('  isDuplicate: ${duplicateResult.isDuplicate}');
  debugPrint('=============================');
}
```

#### 로그 예시

**수정 전**:
```
Notification matched: mode=auto (from cache), pm=수원페이
```

**수정 후**:
```
=== AutoSaveMode Decision ===
  PM ID: 2d32fdd0-811b-4aec-ab79-eeca839cad1b
  PM Name: 수원페이
  PM Owner: a183b04e-0f56-41a0-98be-8b57ffb932f1  ← 다른 사용자!
  Current User: aa8b0aa2-0160-4e33-a863-55ed41e98f24
  Original mode: auto
  Cached mode: auto
  Final mode: auto
  shouldAutoSave: true
  isDuplicate: false
=============================
```

이 로그를 보면 **즉시 owner 불일치를 발견**할 수 있습니다!

### 수정 4: 학습된 포맷 검증 로직 추가

#### 목적
- 학습된 포맷의 `payment_method_id`가 올바른지 검증
- 잘못된 포맷으로 인한 오매칭 방지

#### 수정 대상
- `lib/features/payment_method/data/services/notification_listener_wrapper.dart`

#### AS-IS (line 586-602)

```dart
// 1. 학습된 포맷으로 먼저 매칭 시도
if (formats != null && formats.isNotEmpty) {
  for (final format in formats) {
    if (kDebugMode) {
      debugPrint('[Matching] Checking format: ${format.packageName}');
    }

    if (format.matchesNotification(packageLower, contentLower)) {
      if (kDebugMode) {
        debugPrint('[Matching] Matched by format!');
      }
      return _PaymentMethodMatchResult(
        paymentMethod: pm,
        learnedFormat: format.toEntity(),
      );
    }
  }
}
```

#### TO-BE

```dart
// 1. 학습된 포맷으로 먼저 매칭 시도
if (formats != null && formats.isNotEmpty) {
  for (final format in formats) {
    if (kDebugMode) {
      debugPrint('[Matching] Checking format: ${format.packageName}');
    }

    // ✅ payment_method_id 일치 여부 검증
    if (format.paymentMethodId != pm.id) {
      if (kDebugMode) {
        debugPrint('[Matching] WARNING: Format payment_method_id mismatch!');
        debugPrint('  Format ID: ${format.id}');
        debugPrint('  Format PM ID: ${format.paymentMethodId}');
        debugPrint('  Current PM ID: ${pm.id}');
      }
      continue; // 불일치하면 스킵
    }

    if (format.matchesNotification(packageLower, contentLower)) {
      if (kDebugMode) {
        debugPrint('[Matching] Matched by format!');
      }
      return _PaymentMethodMatchResult(
        paymentMethod: pm,
        learnedFormat: format.toEntity(),
      );
    }
  }
}
```

#### 효과

- 학습된 포맷 데이터 무결성 보장
- 잘못된 포맷으로 인한 매칭 오류 방지

### 수정 5: Realtime 동기화 개선

#### 목적
- 설정 변경 시 모든 기기에서 즉시 캐시 갱신
- Race Condition 방지

#### 수정 대상
1. `lib/features/payment_method/data/repositories/payment_method_repository.dart` - Realtime subscription 추가
2. `lib/features/payment_method/data/services/notification_listener_wrapper.dart` - subscription 연결

#### 구현: PaymentMethodRepository

```dart
/// payment_methods 테이블 변경 감지
RealtimeChannel subscribePaymentMethodChanges({
  required String ledgerId,
  required String userId,
  required void Function() onChanged,
}) {
  return _client
      .channel('payment_methods_changes_${ledgerId}_$userId')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'house',
        table: 'payment_methods',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'ledger_id',
          value: ledgerId,
        ),
        callback: (payload) {
          // owner_user_id 필터링 (클라이언트 측)
          final recordData = payload.newRecord ?? payload.oldRecord;
          if (recordData['owner_user_id'] != userId) {
            return;
          }
          onChanged();
        },
      )
      .subscribe();
}
```

#### 구현: NotificationListenerWrapper

```dart
class NotificationListenerWrapper {
  // ...
  RealtimeChannel? _paymentMethodSubscription;

  Future<void> initialize({
    required String userId,
    required String ledgerId,
  }) async {
    // ... 기존 코드 ...

    // Realtime 구독 추가
    _subscribeToPaymentMethodChanges();
  }

  void _subscribeToPaymentMethodChanges() {
    if (_currentLedgerId == null || _currentUserId == null) return;

    try {
      _paymentMethodSubscription = _paymentMethodRepository
          .subscribePaymentMethodChanges(
            ledgerId: _currentLedgerId!,
            userId: _currentUserId!,
            onChanged: () {
              if (kDebugMode) {
                debugPrint('[PaymentMethod] Realtime change detected, refreshing...');
              }
              refreshPaymentMethods();
            },
          );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[PaymentMethod] Realtime subscribe failed: $e');
      }
    }
  }

  void dispose() {
    // ...
    _paymentMethodSubscription?.unsubscribe();
    _paymentMethodSubscription = null;
  }
}
```

#### 동작 시나리오

```
기기 A (사용자 aa8b0aa2):
1. 수원페이 설정 변경: suggest → auto
2. DB 업데이트 완료
3. Realtime 이벤트 발생

기기 B (사용자 aa8b0aa2, 다른 폰):
1. Realtime 이벤트 수신
2. refreshPaymentMethods() 자동 호출
3. 최신 설정으로 캐시 갱신
4. 다음 알림부터 auto 모드로 동작 ✅
```

### 수정 6: 설정 변경 후 즉시 캐시 갱신

#### 목적
- UI에서 설정 변경 시 즉시 캐시 갱신
- Realtime 구독 전까지의 지연 시간 최소화

#### 수정 대상
- `lib/features/payment_method/presentation/pages/payment_method_management_page.dart`

#### 구현

**설정 저장 후 콜백 추가**:

```dart
// AutoSaveMode 변경 후
await ref.read(paymentMethodRepositoryProvider).updateAutoSaveMode(
  id: paymentMethod.id,
  mode: newMode,
);

// ✅ 즉시 캐시 갱신 (Android만)
if (Platform.isAndroid) {
  await NotificationListenerWrapper.instance.refreshPaymentMethods();

  if (kDebugMode) {
    debugPrint('[Settings] Payment method cache refreshed after mode change');
  }
}

// UI 업데이트
ref.invalidate(paymentMethodsProvider);
```

### 수정 7: SMS 자동수집에도 동일한 owner 필터링 적용

#### 목적
- **Push뿐만 아니라 SMS 자동수집에도** owner 필터링 적용
- 공유 가계부에서 SMS 수집 시에도 동일한 버그 방지

#### 수정 대상
- `lib/features/payment_method/data/services/sms_listener_service.dart`

#### 현재 상황

SMS 자동수집도 동일한 `_autoSavePaymentMethods` 캐시를 사용하므로, **수정 1**이 적용되면 자동으로 해결됩니다.

#### 검증 필요

```dart
// SMS 매칭 시에도 owner 검증 (Fallback)
// notification_listener_wrapper.dart와 동일한 로직 적용
if (nameMatches && pm.ownerUserId == _currentUserId) {
  return _PaymentMethodMatchResult(paymentMethod: pm);
}
```

### 수정 8: 자동수집 알림 전송 로직 추가

#### 목적
- **제안 모드(suggest)와 자동 모드(auto) 모두** 알림 전송
- 사용자 알림 설정(`notification_settings`)에 따라 전송 여부 결정

#### 알림 타입

```dart
enum NotificationType {
  autoCollectSuggested('auto_collect_suggested'),  // 제안 모드: 확인 필요
  autoCollectSaved('auto_collect_saved');          // 자동 모드: 자동 저장됨
}
```

#### 수정 대상
- `lib/features/payment_method/data/services/notification_listener_wrapper.dart`

#### AS-IS (line 714-750)

```dart
try {
  // 항상 pending 상태로 먼저 생성 (원자성 보장)
  await _createPendingTransaction(
    packageName: packageName,
    content: content,
    timestamp: timestamp,
    paymentMethod: paymentMethod,
    parsedResult: parsedResult,
    categoryId: categoryId,
    duplicateHash: duplicateResult.duplicateHash,
    isDuplicate: duplicateResult.isDuplicate,
    shouldAutoSave: shouldAutoSave,
    isViewed: false,
    sourceType: sourceType,
  );
} catch (e) {
  // ...
}

_onNotificationProcessedController.add(
  NotificationProcessedEvent(
    packageName: packageName,
    content: content,
    success: true,
    autoSaveMode: autoSaveModeStr,
    parsedAmount: parsedResult.amount,
    parsedMerchant: parsedResult.merchant,
  ),
);
```

#### TO-BE

```dart
String? createdPendingId;
String? createdTransactionId;

try {
  // 항상 pending 상태로 먼저 생성 (원자성 보장)
  final pendingTx = await _createPendingTransaction(
    packageName: packageName,
    content: content,
    timestamp: timestamp,
    paymentMethod: paymentMethod,
    parsedResult: parsedResult,
    categoryId: categoryId,
    duplicateHash: duplicateResult.duplicateHash,
    isDuplicate: duplicateResult.isDuplicate,
    shouldAutoSave: shouldAutoSave,
    isViewed: false,
    sourceType: sourceType,
  );

  createdPendingId = pendingTx.id;

  // ✅ 자동 저장된 경우 transaction_id 저장
  if (shouldAutoSave && pendingTx.status == PendingTransactionStatus.confirmed) {
    // 최근 생성된 거래 조회 (임시 - 향후 createTransaction에서 ID 반환하도록 개선)
    createdTransactionId = await _getLatestTransactionId(
      paymentMethodId: paymentMethod.id,
    );
  }
} catch (e) {
  // ...
}

// ✅ 자동수집 알림 전송
await _sendAutoCollectNotification(
  userId: _currentUserId!,
  autoSaveMode: autoSaveModeStr,
  amount: parsedResult.amount,
  merchant: parsedResult.merchant,
  pendingId: createdPendingId,
  transactionId: createdTransactionId,
);

_onNotificationProcessedController.add(
  NotificationProcessedEvent(
    packageName: packageName,
    content: content,
    success: true,
    autoSaveMode: autoSaveModeStr,
    parsedAmount: parsedResult.amount,
    parsedMerchant: parsedResult.merchant,
  ),
);
```

#### 알림 전송 메서드 추가

```dart
/// 자동수집 알림 전송
Future<void> _sendAutoCollectNotification({
  required String userId,
  required String autoSaveMode,
  int? amount,
  String? merchant,
  String? pendingId,
  String? transactionId,
}) async {
  if (amount == null) return;

  try {
    final notificationService = NotificationService();
    final formattedAmount = NumberFormat('#,###').format(amount);

    if (autoSaveMode == 'suggest') {
      // 제안 모드: 확인 필요
      await notificationService.sendAutoCollectNotification(
        userId: userId,
        type: NotificationType.autoCollectSuggested,
        title: '자동수집 거래 확인',
        body: '$merchant ${formattedAmount}원이 수집되었습니다. 확인해주세요.',
        data: {
          'pending_id': pendingId,
          'type': 'auto_collect_suggested',
        },
      );
    } else if (autoSaveMode == 'auto') {
      // 자동 모드: 자동 저장됨
      await notificationService.sendAutoCollectNotification(
        userId: userId,
        type: NotificationType.autoCollectSaved,
        title: '자동수집 거래 저장',
        body: '$merchant ${formattedAmount}원이 자동으로 저장되었습니다.',
        data: {
          'pending_id': pendingId,
          'transaction_id': transactionId,
          'type': 'auto_collect_saved',
        },
      );
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[AutoCollect] Failed to send notification: $e');
    }
    // 알림 전송 실패는 치명적 에러가 아니므로 무시
  }
}
```

#### NotificationService import 추가

```dart
import '../../../notification/data/services/notification_service.dart';
import '../../../notification/domain/entities/notification_type.dart';
import 'package:intl/intl.dart';
```

#### 동작 시나리오

**제안 모드 (suggest)**:
```
1. Push 알림 수신: "수원페이 5000원 결제"
2. pending_transactions 생성 (status: pending)
3. ✅ 로컬 알림 전송: "자동수집 거래 확인"
4. 사용자가 앱에서 확인 → 거래 생성 or 거부
```

**자동 모드 (auto)**:
```
1. Push 알림 수신: "수원페이 5000원 결제"
2. pending_transactions 생성 (status: pending)
3. transactions 생성 → status 업데이트 (confirmed)
4. ✅ 로컬 알림 전송: "자동수집 거래 저장"
5. 사용자가 앱에서 확인 (이미 저장됨)
```

#### 알림 설정 확인

`NotificationService.sendAutoCollectNotification`은 내부적으로 다음을 확인:
1. `notification_settings` 테이블 조회
2. `auto_collect_suggested` 또는 `auto_collect_saved` enabled 여부 확인
3. **enabled = true일 때만** 로컬 알림 전송

#### 알림 설정 UI

`lib/features/notification/presentation/pages/notification_settings_page.dart`에 이미 구현되어 있음:

```dart
// 자동수집 알림 설정
SwitchListTile(
  title: Text('자동수집 제안'),
  subtitle: Text('SMS/Push로 수집된 거래 알림'),
  value: settings[NotificationType.autoCollectSuggested] ?? false,
  onChanged: (value) {
    ref.read(notificationSettingsProvider.notifier).updateSetting(
      NotificationType.autoCollectSuggested,
      value,
    );
  },
),
SwitchListTile(
  title: Text('자동수집 저장'),
  subtitle: Text('자동으로 저장된 거래 알림'),
  value: settings[NotificationType.autoCollectSaved] ?? false,
  onChanged: (value) {
    ref.read(notificationSettingsProvider.notifier).updateSetting(
      NotificationType.autoCollectSaved,
      value,
    );
  },
),
```

## 3. 데이터 흐름도

### 수정 전 (Before)

```
┌─────────────────────────────────────────────────────┐
│ 1. getAutoSaveEnabledPaymentMethods(ledgerId)       │
│    → 모든 사용자의 결제수단 로드                      │
└─────────────────────────────────────────────────────┘
                       ↓
┌─────────────────────────────────────────────────────┐
│ 2. _autoSavePaymentMethods 캐시                     │
│    [수원페이(suggest, aa8b0aa2),                    │
│     수원페이(auto, a183b04e)]  ← 2개!               │
└─────────────────────────────────────────────────────┘
                       ↓
┌─────────────────────────────────────────────────────┐
│ 3. Push 알림 수신: "수원페이"                        │
└─────────────────────────────────────────────────────┘
                       ↓
┌─────────────────────────────────────────────────────┐
│ 4. Fallback 매칭: "수원페이" 이름으로 검색          │
│    → auto 모드 수원페이(a183b04e) 매칭 ❌           │
└─────────────────────────────────────────────────────┘
                       ↓
┌─────────────────────────────────────────────────────┐
│ 5. shouldAutoSave = true                            │
│    → 거래 자동 생성 ❌                               │
└─────────────────────────────────────────────────────┘
```

### 수정 후 (After)

```
┌─────────────────────────────────────────────────────┐
│ 1. getAutoSaveEnabledPaymentMethods(ledgerId,       │
│                                     ownerUserId)    │
│    → 자기 결제수단만 로드 ✅                         │
└─────────────────────────────────────────────────────┘
                       ↓
┌─────────────────────────────────────────────────────┐
│ 2. _autoSavePaymentMethods 캐시                     │
│    [수원페이(suggest, aa8b0aa2)]  ← 1개만! ✅       │
└─────────────────────────────────────────────────────┘
                       ↓
┌─────────────────────────────────────────────────────┐
│ 3. Push 알림 수신: "수원페이"                        │
└─────────────────────────────────────────────────────┘
                       ↓
┌─────────────────────────────────────────────────────┐
│ 4. Fallback 매칭:                                   │
│    - 이름 일치: "수원페이" ✅                        │
│    - owner 일치: aa8b0aa2 == aa8b0aa2 ✅           │
│    → suggest 모드 수원페이 매칭 ✅                   │
└─────────────────────────────────────────────────────┘
                       ↓
┌─────────────────────────────────────────────────────┐
│ 5. shouldAutoSave = false                           │
│    → pending 상태로만 저장 ✅                        │
└─────────────────────────────────────────────────────┘
```

## 4. 테스트 설계

### 단위 테스트 (Unit Tests)

#### Test 1: `getAutoSaveEnabledPaymentMethods` owner 필터링

```dart
test('getAutoSaveEnabledPaymentMethods는 자기 결제수단만 반환해야 함', () async {
  // Given
  final ledgerId = 'test-ledger-id';
  final ownerUserId = 'user-a';

  // When
  final result = await repository.getAutoSaveEnabledPaymentMethods(
    ledgerId,
    ownerUserId,
  );

  // Then
  expect(result.every((pm) => pm.ownerUserId == ownerUserId), true);
  expect(result.every((pm) => pm.autoSaveMode != AutoSaveMode.manual), true);
});
```

#### Test 2: Fallback 매칭 시 owner 검증

```dart
test('Fallback 매칭 시 owner가 다르면 매칭 실패해야 함', () {
  // Given
  final currentUserId = 'user-a';
  final paymentMethods = [
    PaymentMethodModel(
      id: 'pm-1',
      ownerUserId: 'user-b',  // 다른 사용자
      name: '수원페이',
      autoSaveMode: AutoSaveMode.auto,
    ),
  ];

  // When
  final result = _findMatchingPaymentMethod(
    packageName: 'test',
    content: '수원페이 결제 완료',
  );

  // Then
  expect(result, isNull);  // 매칭 실패
});
```

### 통합 테스트 (Integration Tests)

#### Test 3: 공유 가계부에서 자동수집

```dart
testWidgets('공유 가계부에서 자기 결제수단만 자동수집', (tester) async {
  // Given: 2명의 사용자가 같은 이름의 결제수단 소유
  await setupSharedLedger(
    users: ['user-a', 'user-b'],
    paymentMethods: {
      'user-a': [PaymentMethod(name: '수원페이', mode: AutoSaveMode.suggest)],
      'user-b': [PaymentMethod(name: '수원페이', mode: AutoSaveMode.auto)],
    },
  );

  // When: user-a로 로그인 후 수원페이 알림 수신
  await loginAs('user-a');
  await simulatePushNotification(
    packageName: 'gov.gyeonggi.ggcard',
    content: '수원페이 결제 완료 5000원',
  );

  // Then: pending 상태로 저장 (auto가 아님!)
  final pending = await getPendingTransactions();
  expect(pending.length, 1);
  expect(pending.first.status, PendingTransactionStatus.pending);

  // And: 거래가 자동 생성되지 않음
  final transactions = await getTransactions();
  expect(transactions, isEmpty);
});
```

### 시나리오 테스트

#### 시나리오 1: 수원페이 suggest 모드 (사용자 aa8b0aa2)

**Given**:
- 로그인: aa8b0aa2
- 가계부: 4cb99897
- 결제수단: 수원페이 (suggest 모드)

**When**:
- 수원페이 실제 결제 5000원

**Then**:
- `_loadAutoSavePaymentMethods()` 호출 시:
  - Query: `owner_user_id = 'aa8b0aa2'`
  - Result: 수원페이 (suggest) 1개만 로드 ✅
- `_findMatchingPaymentMethod()` 호출 시:
  - Fallback 매칭: "수원페이" + owner 일치 ✅
  - Result: suggest 모드 수원페이 반환
- `shouldAutoSave = false` ✅
- `pending_transactions.status = 'pending'` ✅
- 거래 자동 생성 안됨 ✅

#### 시나리오 2: KB국민카드 suggest 모드 (대조군)

**Given**:
- 로그인: aa8b0aa2
- 가계부: 4cb99897
- 결제수단: KB국민카드 (suggest 모드, push 소스)

**When**:
- KB Pay 실제 결제 30000원

**Then**:
- 시나리오 1과 동일하게 동작 ✅

#### 시나리오 3: 설정 변경 후 즉시 반영

**Given**:
- 로그인: aa8b0aa2
- 수원페이: suggest 모드

**When**:
1. 설정 변경: suggest → auto
2. `refreshPaymentMethods()` 즉시 호출 ✅
3. 2초 후 수원페이 결제

**Then**:
- `_autoSavePaymentMethods` 캐시에 auto 모드로 로드됨 ✅
- `shouldAutoSave = true` ✅
- 거래 자동 생성 ✅

#### 시나리오 4: Realtime 동기화 (다중 기기)

**Given**:
- 기기 A, B 모두 로그인: aa8b0aa2
- 수원페이: suggest 모드

**When**:
1. 기기 A에서 설정 변경: suggest → auto
2. 기기 B에서 5초 대기
3. 기기 B에서 수원페이 결제

**Then**:
- 기기 B의 Realtime 이벤트 수신 ✅
- 기기 B의 `refreshPaymentMethods()` 자동 호출 ✅
- 기기 B에서 auto 모드로 동작 ✅

## 5. 보안 고려사항

### 5.1 RLS (Row Level Security) 검증

**확인 사항**:
- `payment_methods` 테이블의 RLS 정책이 `owner_user_id` 기반으로 올바르게 설정되어 있는지 확인

**예상 정책**:
```sql
-- SELECT 정책: 자기 결제수단 또는 공유 결제수단만 조회 가능
CREATE POLICY "Users can view their own or shared payment methods"
  ON payment_methods
  FOR SELECT
  USING (
    owner_user_id = auth.uid() OR
    (can_auto_save = false AND ledger_id IN (
      SELECT ledger_id FROM ledger_members WHERE user_id = auth.uid()
    ))
  );

-- UPDATE 정책: 자기 결제수단만 수정 가능
CREATE POLICY "Users can update only their own payment methods"
  ON payment_methods
  FOR UPDATE
  USING (owner_user_id = auth.uid());
```

### 5.2 학습된 포맷 데이터 무결성

**위험**:
- 악의적으로 조작된 학습된 포맷이 다른 사용자의 거래를 가로챌 수 있음

**완화 방안**:
- 학습된 포맷의 `payment_method_id` 검증 (수정 4)
- 학습된 포맷 생성 시 `owner_user_id` 기록 (향후 개선)

## 6. 성능 고려사항

### 6.1 Realtime 구독 오버헤드

**영향**:
- 모든 사용자가 `payment_methods` 변경을 구독
- 가계부 멤버가 많을수록 이벤트 수 증가

**완화 방안**:
- 클라이언트 측에서 `owner_user_id` 필터링
- 구독 채널에 `ledgerId_userId` 포함하여 격리

### 6.2 refreshPaymentMethods() 중복 호출 방지

**문제**:
- UI 설정 변경 + Realtime 이벤트로 2번 호출될 수 있음

**해결**:
```dart
DateTime? _lastRefreshTime;
static const _refreshThrottle = Duration(seconds: 1);

Future<void> refreshPaymentMethods() async {
  final now = DateTime.now();
  if (_lastRefreshTime != null &&
      now.difference(_lastRefreshTime!) < _refreshThrottle) {
    if (kDebugMode) {
      debugPrint('[PaymentMethod] Refresh throttled');
    }
    return;
  }

  _lastRefreshTime = now;
  await _loadAutoSavePaymentMethods();
  await _loadLearnedFormats();
}
```

## 7. 롤백 계획

### 롤백 트리거

다음 상황 발생 시 즉시 롤백:
1. **자기 결제수단이 로드되지 않음** (owner 필터링 과다)
2. **정상 매칭이 실패** (Fallback 매칭 로직 오류)
3. **성능 저하** (Realtime 구독 오버헤드)

### 롤백 절차

#### 단계 1: 긴급 Feature Flag

```dart
// feature_flags.dart
class FeatureFlags {
  static const bool enableOwnerFiltering = true;  // ✅ false로 변경
  static const bool enableFallbackOwnerCheck = true;  // ✅ false로 변경
}

// 사용
if (FeatureFlags.enableOwnerFiltering) {
  query = query.eq('owner_user_id', ownerUserId);
}
```

#### 단계 2: Git Revert

```bash
# 마지막 커밋 롤백
git revert HEAD --no-edit

# 특정 커밋 롤백
git revert <commit-hash> --no-edit

# 푸시
git push origin main
```

#### 단계 3: Hot Fix 배포

```bash
# 긴급 빌드
flutter build apk --release

# 배포 (Firebase App Distribution 등)
firebase appdistribution:distribute \
  build/app/outputs/flutter-apk/app-release.apk
```

## 8. 변경 사항 요약

### 파일 변경 목록

| 파일 | 변경 내용 | 영향도 |
|------|-----------|--------|
| `payment_method_repository.dart` | owner 필터링 추가 | 중간 |
| `notification_listener_wrapper.dart` | Fallback 매칭 개선, 로그 강화 | 높음 |
| `notification_listener_wrapper.dart` | 학습된 포맷 검증 | 낮음 |
| `payment_method_repository.dart` | Realtime 구독 추가 | 중간 |
| `payment_method_management_page.dart` | 설정 변경 후 캐시 갱신 | 낮음 |

### API 변경 사항

#### Breaking Change

```dart
// Before
Future<List<PaymentMethodModel>> getAutoSaveEnabledPaymentMethods(
  String ledgerId,
)

// After
Future<List<PaymentMethodModel>> getAutoSaveEnabledPaymentMethods(
  String ledgerId,
  String ownerUserId,  // ✅ 추가
)
```

**영향 범위**: 1개 호출 위치 (`notification_listener_wrapper.dart:334`)

## 9. 구현 순서

### Phase 1: 핵심 수정 (1-2시간)

1. ✅ `getAutoSaveEnabledPaymentMethods` owner 파라미터 추가
2. ✅ `_loadAutoSavePaymentMethods` 호출 시 userId 전달
3. ✅ Fallback 매칭 owner 검증 추가

### Phase 2: 로그 및 검증 (30분)

4. ✅ autoSaveMode 로그 강화
5. ✅ 학습된 포맷 검증 로직 추가

### Phase 3: 동기화 개선 (1시간)

6. ✅ Realtime 구독 추가
7. ✅ 설정 변경 후 캐시 갱신

### Phase 4: 테스트 (2시간)

8. ✅ 단위 테스트 작성
9. ✅ 시나리오 테스트 실행
10. ✅ 실제 기기 검증

## 10. 성공 메트릭

### 기능 메트릭

| 메트릭 | 목표 | 측정 방법 |
|--------|------|-----------|
| owner 필터링 정확도 | 100% | 자기 결제수단만 로드되는지 확인 |
| Fallback 매칭 정확도 | 100% | owner 불일치 시 매칭 실패 |
| 캐시 갱신 지연 시간 | < 2초 | 설정 변경 후 캐시 갱신 시간 |
| Realtime 동기화 지연 | < 5초 | 다른 기기에서 반영되는 시간 |

### 버그 메트릭

| 메트릭 | 목표 |
|--------|------|
| suggest 모드에서 자동 저장 | 0건 |
| owner 불일치 매칭 | 0건 |
| 캐시 동기화 실패 | < 1% |

## 11. 문서화

### 코드 주석

**중요 로직에 주석 추가**:

```dart
/// 자동수집 활성화된 결제수단 조회
///
/// **중요**: 공유 가계부에서 다른 사용자의 결제수단이
/// 잘못 매칭되는 것을 방지하기 위해 반드시 owner 필터링 필요
///
/// [ledgerId] 가계부 ID
/// [ownerUserId] 결제수단 소유자 ID (현재 로그인한 사용자)
///
/// Returns: 자기 결제수단 중 auto_save_mode가 manual이 아닌 것들
Future<List<PaymentMethodModel>> getAutoSaveEnabledPaymentMethods(
  String ledgerId,
  String ownerUserId,
) async {
  // ...
}
```

### CLAUDE.md 업데이트

```markdown
## 자동수집 기능 주의사항

### 공유 가계부에서의 owner 필터링

- **문제**: 같은 이름의 결제수단이 여러 사용자에게 있을 경우,
  다른 사용자의 auto 모드 결제수단이 매칭될 수 있음
- **해결**: `getAutoSaveEnabledPaymentMethods`에 owner 필터링 추가
- **날짜**: 2026-02-01 수정 완료
```

---

## 변경 이력

| 날짜 | 작성자 | 변경 내용 |
|------|--------|-----------|
| 2026-02-01 | Claude | 초기 작성 (조사 결과 반영) |
