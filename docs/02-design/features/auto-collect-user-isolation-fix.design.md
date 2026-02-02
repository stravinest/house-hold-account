# Design: 자동수집 사용자 격리 완전 수정

**Feature ID**: `auto-collect-user-isolation-fix`
**작성일**: 2026-02-02
**PDCA Phase**: Design
**Plan 문서**: [auto-collect-user-isolation-fix.plan.md](../../01-plan/features/auto-collect-user-isolation-fix.plan.md)

---

## 1. 설계 개요

### 1.1 목표
- `learnedFormatsCache`에 사용자 격리 적용
- `matchingFormat` 매칭 시 소유자 검증 추가
- 설정 변경 시 Kotlin 캐시 즉시 무효화

### 1.2 핵심 원칙
> **"모든 캐시 데이터는 반드시 현재 사용자의 것만 포함해야 한다."**

---

## 2. 수정 대상 파일

| 순서 | 파일 | 변경 내용 |
|:----:|------|----------|
| 1 | `SupabaseHelper.kt` | `getLearnedPushFormats` 시그니처 및 쿼리 수정 |
| 2 | `FinancialNotificationListener.kt` | `refreshFormatsCache` 호출부 수정 |
| 3 | `FinancialNotificationListener.kt` | `matchingFormat` 검증 로직 추가 |
| 4 | `FinancialNotificationListener.kt` | `invalidateCache` 함수 추가 |
| 5 | `MainActivity.kt` | MethodChannel 핸들러 추가 |
| 6 | Flutter `notification_listener_wrapper.dart` | 캐시 무효화 호출 추가 |

---

## 3. 상세 설계

### 3.1 [C-1] SupabaseHelper.kt - getLearnedPushFormats 수정

**파일 경로**: `android/app/src/main/kotlin/com/household/shared/shared_household_account/SupabaseHelper.kt`

**Before** (Line 478):
```kotlin
suspend fun getLearnedPushFormats(ledgerId: String): List<LearnedPushFormat> = withContext(Dispatchers.IO) {
```

**After**:
```kotlin
suspend fun getLearnedPushFormats(ledgerId: String, ownerUserId: String): List<LearnedPushFormat> = withContext(Dispatchers.IO) {
```

**Before** (Line 484):
```kotlin
val url = "$baseUrl/rest/v1/learned_push_formats?select=*,payment_methods!inner(ledger_id)&payment_methods.ledger_id=eq.$ledgerId"
```

**After**:
```kotlin
val url = "$baseUrl/rest/v1/learned_push_formats?select=*,payment_methods!inner(ledger_id,owner_user_id)&payment_methods.ledger_id=eq.$ledgerId&payment_methods.owner_user_id=eq.$ownerUserId"
```

**Before** (Line 517):
```kotlin
Log.d(TAG, "Loaded ${formats.size} push formats for ledger $ledgerId")
```

**After**:
```kotlin
Log.d(TAG, "Loaded ${formats.size} push formats for ledger $ledgerId, user $ownerUserId")
```

---

### 3.2 FinancialNotificationListener.kt - refreshFormatsCache 호출부 수정

**Before** (Line 361):
```kotlin
learnedFormatsCache = supabaseHelper.getLearnedPushFormats(ledgerId)
```

**After**:
```kotlin
learnedFormatsCache = supabaseHelper.getLearnedPushFormats(ledgerId, userId)
```

---

### 3.3 [H-1] FinancialNotificationListener.kt - matchingFormat 검증 로직 추가

**Before** (Line 249-254):
```kotlin
val matchingFormat = learnedFormatsCache.find { format ->
    format.packageName.equals(packageName, ignoreCase = true) ||
    format.appKeywords.any { keyword ->
        combinedContent.contains(keyword, ignoreCase = true)
    }
}
```

**After**:
```kotlin
val matchingFormat = learnedFormatsCache.find { format ->
    // 패키지명 또는 키워드 매칭
    val contentMatches = format.packageName.equals(packageName, ignoreCase = true) ||
        format.appKeywords.any { keyword ->
            combinedContent.contains(keyword, ignoreCase = true)
        }
    // 추가 검증: 해당 포맷의 paymentMethodId가 현재 사용자 캐시에 존재하는지
    val isOwnedByCurrentUser = paymentMethodsCache.any { pm -> pm.id == format.paymentMethodId }
    contentMatches && isOwnedByCurrentUser
}
```

---

### 3.4 [H-2] FinancialNotificationListener.kt - invalidateCache 함수 추가

**위치**: companion object 아래, 클래스 내부 (Line 120 부근)

**추가 코드**:
```kotlin
/**
 * Flutter에서 결제수단 설정 변경 시 호출
 * 다음 알림 처리 시 캐시를 강제로 새로고침
 */
fun invalidateCache() {
    lastFormatsFetchTime = 0
    Log.d(TAG, "Cache invalidated by external request")
}
```

**주의**: `lastFormatsFetchTime`을 `private var`에서 접근 가능하도록 유지

---

### 3.5 [H-2] MainActivity.kt - MethodChannel 핸들러 추가

**파일 경로**: `android/app/src/main/kotlin/com/household/shared/shared_household_account/MainActivity.kt`

**위치**: 기존 MethodChannel 핸들러가 있는 곳 (configureFlutterEngine 내부)

**추가 코드**:
```kotlin
// 기존 notification_channel 핸들러에 추가
"invalidateNotificationCache" -> {
    FinancialNotificationListener.instance?.invalidateCache()
    result.success(true)
}
```

---

### 3.6 [H-2] Flutter - 캐시 무효화 호출

**파일 경로**: `lib/features/payment_method/data/services/notification_listener_wrapper.dart`

**위치**: 클래스 상단에 채널 정의 추가

**추가 코드**:
```dart
import 'package:flutter/services.dart';

// 클래스 내부 상단
static const _notificationChannel = MethodChannel('notification_channel');

/// Kotlin 서비스의 캐시를 무효화
/// 결제수단 설정 변경 후 호출해야 함
static Future<void> invalidateNativeCache() async {
  if (!Platform.isAndroid) return;

  try {
    await _notificationChannel.invokeMethod('invalidateNotificationCache');
    if (kDebugMode) {
      debugPrint('[NotificationWrapper] Native cache invalidated');
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[NotificationWrapper] Failed to invalidate native cache: $e');
    }
  }
}
```

**PaymentMethodRepository 수정** (`payment_method_repository.dart`):

`updateAutoSaveSettings` 함수 끝에 추가:
```dart
// 설정 변경 후 Kotlin 캐시 무효화
await NotificationListenerWrapper.invalidateNativeCache();
```

---

## 4. 변경 요약표

| 파일 | 라인 | 변경 전 | 변경 후 |
|------|:----:|---------|---------|
| `SupabaseHelper.kt` | 478 | `getLearnedPushFormats(ledgerId)` | `getLearnedPushFormats(ledgerId, ownerUserId)` |
| `SupabaseHelper.kt` | 484 | 쿼리에 owner 필터 없음 | `&payment_methods.owner_user_id=eq.$ownerUserId` 추가 |
| `SupabaseHelper.kt` | 517 | 로그에 user 없음 | 로그에 user 추가 |
| `FinancialNotificationListener.kt` | 361 | `getLearnedPushFormats(ledgerId)` | `getLearnedPushFormats(ledgerId, userId)` |
| `FinancialNotificationListener.kt` | 249-254 | 소유자 검증 없음 | `isOwnedByCurrentUser` 검증 추가 |
| `FinancialNotificationListener.kt` | 신규 | 없음 | `invalidateCache()` 함수 추가 |
| `MainActivity.kt` | 핸들러 | 없음 | `invalidateNotificationCache` 핸들러 추가 |
| `notification_listener_wrapper.dart` | 신규 | 없음 | `invalidateNativeCache()` 함수 추가 |
| `payment_method_repository.dart` | updateAutoSaveSettings | 캐시 무효화 없음 | 캐시 무효화 호출 추가 |

---

## 5. 데이터 흐름 다이어그램 (수정 후)

```
알림 수신 (혀니 기기)
    ↓
refreshFormatsCache(ledgerId, userId)
    ↓
learnedFormatsCache = getLearnedPushFormats(ledgerId, userId) ← [수정] owner 필터 추가
paymentMethodsCache = getPaymentMethodsByLedger(ledgerId, userId) ← 기존 수정됨
    ↓
matchingFormat = learnedFormatsCache.find {
    contentMatches && isOwnedByCurrentUser  ← [수정] 소유자 검증 추가
}
    ↓
paymentMethodId = matchingFormat?.paymentMethodId ← 현재 사용자 것 보장
    ↓
fallback: paymentMethodsCache.find(...) ← 기존 수정됨
    ↓
올바른 사용자의 결제수단에만 저장
```

---

## 6. 구현 순서

1. `SupabaseHelper.kt` - `getLearnedPushFormats` 시그니처 변경
2. `SupabaseHelper.kt` - 쿼리에 owner 필터 추가
3. `SupabaseHelper.kt` - 로그 업데이트
4. `FinancialNotificationListener.kt` - `refreshFormatsCache` 호출부 수정
5. `FinancialNotificationListener.kt` - `matchingFormat` 검증 로직 추가
6. `FinancialNotificationListener.kt` - `invalidateCache` 함수 추가
7. `MainActivity.kt` - MethodChannel 핸들러 추가
8. Flutter - `invalidateNativeCache` 함수 추가
9. Flutter - `updateAutoSaveSettings`에 캐시 무효화 호출 추가

---

## 7. 테스트 계획

### 7.1 사용자 격리 테스트

| ID | 시나리오 | 검증 항목 |
|----|----------|----------|
| T-1 | 혀니 기기에서 KB Pay 알림, 두 사용자 모두 KB Pay 포맷 학습됨 | 혀니의 포맷만 매칭, 혀니의 결제수단에 저장 |
| T-2 | stravinest 기기에서 KB Pay 알림 | stravinest의 포맷만 매칭, stravinest의 결제수단에 저장 |

### 7.2 캐시 무효화 테스트

| ID | 시나리오 | 검증 항목 |
|----|----------|----------|
| T-3 | 혀니가 SMS→Push 변경 후 5초 내 알림 | 변경된 설정(Push)으로 처리 |
| T-4 | 혀니가 suggest→auto 변경 후 5초 내 알림 | 자동 저장으로 처리 |

---

## 8. 롤백 계획

- Kotlin 2개 파일 + Flutter 2개 파일 변경
- 데이터베이스 스키마 변경 없음
- Git revert로 즉시 롤백 가능

---

**Design 문서 작성 완료**
작성일: 2026-02-02
