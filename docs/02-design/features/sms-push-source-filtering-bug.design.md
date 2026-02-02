# Design: SMS/Push 소스 필터링 버그 수정

**Feature ID**: `sms-push-source-filtering-bug`
**작성일**: 2026-02-02
**PDCA Phase**: Design
**Plan 문서**: [sms-push-source-filtering-bug.plan.md](../../01-plan/features/sms-push-source-filtering-bug.plan.md)

---

## 1. 설계 개요

### 1.1 목표
- 각 사용자는 **자신의 결제수단만** 매칭/저장 가능하도록 수정
- `sourceType`(SMS/Push)에 맞는 `autoCollectSource` 결제수단만 매칭되도록 수정

### 1.2 핵심 원칙
> **"혀니는 무조건 혀니의 결제수단만 검색해야 하고, stravinest는 stravinest의 결제수단만 검색해야 한다."**

---

## 2. 수정 대상 파일

| 순서 | 파일 | 변경 내용 |
|:----:|------|----------|
| 1 | `SupabaseHelper.kt` | PaymentMethodInfo에 ownerUserId 필드 추가 |
| 2 | `SupabaseHelper.kt` | getPaymentMethodsByLedger 함수 시그니처 및 쿼리 수정 |
| 3 | `FinancialNotificationListener.kt` | refreshFormatsCache에서 userId 전달 |
| 4 | `FinancialNotificationListener.kt` | Fallback 매칭 로직에 sourceType 필터 추가 |

---

## 3. 상세 설계

### 3.1 SupabaseHelper.kt - PaymentMethodInfo 클래스 수정

**파일 경로**: `android/app/src/main/kotlin/com/household/shared/shared_household_account/SupabaseHelper.kt`

**위치**: Line 589-594

**Before**:
```kotlin
data class PaymentMethodInfo(
    val id: String,
    val name: String,
    val autoSaveMode: String,
    val autoCollectSource: String
)
```

**After**:
```kotlin
data class PaymentMethodInfo(
    val id: String,
    val name: String,
    val autoSaveMode: String,
    val autoCollectSource: String,
    val ownerUserId: String
)
```

---

### 3.2 SupabaseHelper.kt - getPaymentMethodsByLedger 함수 수정

**위치**: Line 596-637

**Before** (Line 596):
```kotlin
suspend fun getPaymentMethodsByLedger(ledgerId: String): List<PaymentMethodInfo> = withContext(Dispatchers.IO) {
```

**After**:
```kotlin
suspend fun getPaymentMethodsByLedger(ledgerId: String, ownerUserId: String): List<PaymentMethodInfo> = withContext(Dispatchers.IO) {
```

**Before** (Line 603):
```kotlin
.url("$baseUrl/rest/v1/payment_methods?ledger_id=eq.$ledgerId&select=id,name,auto_save_mode,auto_collect_source")
```

**After**:
```kotlin
.url("$baseUrl/rest/v1/payment_methods?ledger_id=eq.$ledgerId&owner_user_id=eq.$ownerUserId&select=id,name,auto_save_mode,auto_collect_source,owner_user_id")
```

**Before** (Line 619-624):
```kotlin
methods.add(PaymentMethodInfo(
    id = item.getString("id"),
    name = item.getString("name"),
    autoSaveMode = item.optString("auto_save_mode", "suggest"),
    autoCollectSource = item.optString("auto_collect_source", "sms")
))
```

**After**:
```kotlin
methods.add(PaymentMethodInfo(
    id = item.getString("id"),
    name = item.getString("name"),
    autoSaveMode = item.optString("auto_save_mode", "suggest"),
    autoCollectSource = item.optString("auto_collect_source", "sms"),
    ownerUserId = item.optString("owner_user_id", "")
))
```

**Before** (Line 627):
```kotlin
Log.d(TAG, "Loaded ${methods.size} payment methods for ledger $ledgerId")
```

**After**:
```kotlin
Log.d(TAG, "Loaded ${methods.size} payment methods for ledger $ledgerId, user $ownerUserId")
```

---

### 3.3 FinancialNotificationListener.kt - refreshFormatsCache 수정

**파일 경로**: `android/app/src/main/kotlin/com/household/shared/shared_household_account/FinancialNotificationListener.kt`

**위치**: Line 352-366

**Before** (Line 352):
```kotlin
private suspend fun refreshFormatsCache(ledgerId: String) {
```

**After**:
```kotlin
private suspend fun refreshFormatsCache(ledgerId: String, userId: String) {
```

**Before** (Line 360):
```kotlin
paymentMethodsCache = supabaseHelper.getPaymentMethodsByLedger(ledgerId)
```

**After**:
```kotlin
paymentMethodsCache = supabaseHelper.getPaymentMethodsByLedger(ledgerId, userId)
```

---

### 3.4 FinancialNotificationListener.kt - refreshFormatsCache 호출부 수정

**위치**: Line 247 (processNotification 함수 내부)

**호출부 검색**: `refreshFormatsCache(ledgerId)` → `refreshFormatsCache(ledgerId, userId)`

---

### 3.5 FinancialNotificationListener.kt - Fallback 매칭 로직 수정

**위치**: Line 271-280

**Before**:
```kotlin
// learned_push_formats에서 매칭 안 되면 결제수단 이름으로 fallback 매칭
if (paymentMethodId.isEmpty()) {
    matchedPaymentMethod = paymentMethodsCache.find { pm ->
        pm.autoCollectSource == "push" && combinedContent.contains(pm.name, ignoreCase = true)
    }
    if (matchedPaymentMethod != null) {
        paymentMethodId = matchedPaymentMethod.id
        Log.d(TAG, "Fallback matched by payment method name: ${matchedPaymentMethod.name}")
    }
}
```

**After**:
```kotlin
// learned_push_formats에서 매칭 안 되면 결제수단 이름으로 fallback 매칭
// sourceType에 맞는 결제수단만 매칭 (SMS -> sms, notification -> push)
if (paymentMethodId.isEmpty()) {
    val expectedSource = if (sourceType == "sms") "sms" else "push"
    matchedPaymentMethod = paymentMethodsCache.find { pm ->
        pm.autoCollectSource == expectedSource && combinedContent.contains(pm.name, ignoreCase = true)
    }
    if (matchedPaymentMethod != null) {
        paymentMethodId = matchedPaymentMethod.id
        Log.d(TAG, "Fallback matched by payment method name: ${matchedPaymentMethod.name} (source: $expectedSource)")
    }
}
```

---

## 4. 변경 요약표

| 파일 | 라인 | 변경 전 | 변경 후 |
|------|:----:|---------|---------|
| `SupabaseHelper.kt` | 589-594 | `PaymentMethodInfo` 4개 필드 | 5개 필드 (+ownerUserId) |
| `SupabaseHelper.kt` | 596 | `getPaymentMethodsByLedger(ledgerId)` | `getPaymentMethodsByLedger(ledgerId, ownerUserId)` |
| `SupabaseHelper.kt` | 603 | 쿼리에 owner 필터 없음 | `&owner_user_id=eq.$ownerUserId` 추가 |
| `SupabaseHelper.kt` | 619-624 | ownerUserId 없음 | `ownerUserId = item.optString(...)` 추가 |
| `SupabaseHelper.kt` | 627 | 로그에 user 없음 | 로그에 user 추가 |
| `FinancialNotificationListener.kt` | 352 | `refreshFormatsCache(ledgerId)` | `refreshFormatsCache(ledgerId, userId)` |
| `FinancialNotificationListener.kt` | 360 | userId 전달 안 함 | userId 전달 |
| `FinancialNotificationListener.kt` | 247 | `refreshFormatsCache(ledgerId)` | `refreshFormatsCache(ledgerId, userId)` |
| `FinancialNotificationListener.kt` | 273-274 | `autoCollectSource == "push"` | `autoCollectSource == expectedSource` |

---

## 5. 데이터 흐름 다이어그램

### 5.1 수정 전 (버그)
```
알림 수신 (혀니 기기)
    ↓
refreshFormatsCache(ledgerId)
    ↓
getPaymentMethodsByLedger(ledgerId)
    ↓
★ 가계부 전체 결제수단 로드 (혀니 + stravinest)
    ↓
Fallback: autoCollectSource == "push" 검색
    ↓
★ stravinest의 Push 모드 결제수단 매칭 (버그)
    ↓
잘못된 결제수단에 저장
```

### 5.2 수정 후 (정상)
```
알림 수신 (혀니 기기)
    ↓
refreshFormatsCache(ledgerId, userId)
    ↓
getPaymentMethodsByLedger(ledgerId, ownerUserId)
    ↓
★ 혀니의 결제수단만 로드
    ↓
Fallback: autoCollectSource == expectedSource 검색
    ↓
★ sourceType에 맞는 혀니의 결제수단 매칭 (정상)
    ↓
올바른 결제수단에 저장
```

---

## 6. 테스트 계획

### 6.1 단위 테스트

| Test ID | 시나리오 | 검증 항목 | 우선순위 |
|---------|----------|----------|----------|
| T-1 | SMS 수신 + SMS 모드 결제수단 | SMS 모드 결제수단 매칭 | Critical |
| T-2 | Push 수신 + Push 모드 결제수단 | Push 모드 결제수단 매칭 | Critical |
| T-3 | SMS 수신 + Push 모드만 존재 | 매칭 실패, 스킵 | High |
| T-4 | Push 수신 + SMS 모드만 존재 | 매칭 실패, 스킵 | High |

### 6.2 통합 테스트

| Test ID | 시나리오 | 검증 항목 | 우선순위 |
|---------|----------|----------|----------|
| T-5 | 혀니 기기에서 SMS/Push 동시 수신 | SMS 모드 결제수단에 SMS만 저장 | Critical |
| T-6 | 동일 이름 결제수단 (혀니:SMS, stravinest:Push) | 각자의 결제수단에만 저장 | Critical |

### 6.3 방어 테스트

| Test ID | 시나리오 | 검증 항목 | 우선순위 |
|---------|----------|----------|----------|
| T-7 | 혀니 기기에서 stravinest 결제수단 접근 시도 | 캐시에 없으므로 매칭 불가 | High |

---

## 7. 구현 순서

1. **SupabaseHelper.kt** - PaymentMethodInfo 클래스에 ownerUserId 추가
2. **SupabaseHelper.kt** - getPaymentMethodsByLedger 함수 시그니처 변경
3. **SupabaseHelper.kt** - 쿼리에 owner_user_id 필터 추가
4. **SupabaseHelper.kt** - JSON 파싱에 ownerUserId 추가
5. **FinancialNotificationListener.kt** - refreshFormatsCache 시그니처 변경
6. **FinancialNotificationListener.kt** - refreshFormatsCache 호출부 수정
7. **FinancialNotificationListener.kt** - Fallback 매칭 로직 수정

---

## 8. 롤백 계획

문제 발생 시 Git revert로 즉시 롤백 가능:
- 변경 범위가 Kotlin 2개 파일로 제한됨
- 데이터베이스 스키마 변경 없음
- 기존 API와 호환성 유지 (owner_user_id 필터만 추가)

---

**Design 문서 작성 완료**
작성일: 2026-02-02
