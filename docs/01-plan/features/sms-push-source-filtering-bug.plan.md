# Plan: SMS/Push 소스 필터링 버그 수정

**Feature ID**: `sms-push-source-filtering-bug`
**작성일**: 2026-02-02
**PDCA Phase**: Plan

---

## 1. 문제 상황

### 1.1 사용자 제보
- KB국민카드를 **SMS 자동 저장 모드**로 설정
- KB국민카드 Push 메시지와 SMS 메시지가 **20:20에 동시 도착**
- **기대 동작**: SMS만 자동 저장, Push는 스킵, 수집내역에 SMS 1건만 존재
- **실제 동작**: SMS와 Push가 **둘 다** 수집내역 대기중에 2건으로 쌓임

### 1.2 데이터베이스 상태 확인

**결제수단 설정** (가계부 `4cb99897-9d54-4620-b57d-d527c3ec278f`):
| 사용자 | 결제수단 | auto_collect_source | auto_save_mode |
|--------|----------|---------------------|----------------|
| stravinest | KB국민카드 | **push** | suggest |
| 혀니 | KB국민카드 | **sms** | auto |

**실제 저장된 데이터** (20:20):
| source_type | payment_method_id | owner | created_at |
|-------------|-------------------|-------|------------|
| notification | stravinest의 KB국민카드 | stravinest | 11:20:21.652 |
| sms | stravinest의 KB국민카드 | stravinest | 11:20:21.926 |

**문제**: 혀니의 기기에서 생성된 SMS 데이터가 **stravinest의 Push 모드 결제수단**에 저장됨

### 1.3 추가 데이터 분석 (2026-01-28)

| 필드 | 값 |
|------|-----|
| `source_type` | notification (Push) |
| `user_id` | 혀니 |
| `payment_method_id` | **null** |
| `status` | rejected |

**원인 분석**:
- 혀니의 KB국민카드는 **SMS 모드**
- Push 알림이 도착했으나 Fallback 매칭에서 `autoCollectSource == "push"` 조건만 검색
- 혀니의 SMS 모드 결제수단은 **매칭 대상에서 제외**
- 2026-01-28 시점에는 stravinest의 Push 모드 KB국민카드가 캐시에 없었음
- 결과: **매칭 실패 → payment_method_id = null로 저장**

### 1.4 문제 패턴 요약

| 날짜 | 상황 | 결과 |
|------|------|------|
| 01-28 | Push 도착, stravinest Push 캐시 없음 | `payment_method_id = null` |
| 02-02 | SMS/Push 도착, stravinest Push 캐시 있음 | `payment_method_id = stravinest의 것` (잘못됨) |

**근본 원인**: Fallback 매칭이 `sourceType`과 무관하게 Push 모드 결제수단만 검색하고, **현재 사용자의 결제수단만 검색하지 않음**

---

## 2. 원인 분석

### 2.1 근본 원인: 결제수단 캐시 로드 문제

**파일**: `SupabaseHelper.kt` Line 596-637

```kotlin
suspend fun getPaymentMethodsByLedger(ledgerId: String): List<PaymentMethodInfo>
```

**현재 쿼리**:
```
/rest/v1/payment_methods?ledger_id=eq.$ledgerId&select=id,name,auto_save_mode,auto_collect_source
```

**문제점**:
1. ❌ **가계부 전체의 결제수단**을 가져옴 (모든 멤버의 결제수단 포함)
2. ❌ `owner_user_id` 필터가 **없음**
3. ❌ `PaymentMethodInfo` 클래스에 `ownerUserId` 필드 **없음**

### 2.2 추가 원인: Fallback 매칭 로직 문제

**파일**: `FinancialNotificationListener.kt` Line 273-280

```kotlin
matchedPaymentMethod = paymentMethodsCache.find { pm ->
    pm.autoCollectSource == "push" && combinedContent.contains(pm.name, ignoreCase = true)
}
```

**문제점**:
1. ❌ **sourceType과 무관하게** `autoCollectSource == "push"`만 검색
2. ❌ SMS가 들어와도 Push 모드 결제수단만 매칭
3. ❌ 소유자(owner) 검증 로직 **없음**

---

## 3. 핵심 원칙 (사용자 요구사항)

> **"혀니는 무조건 혀니의 결제수단만 검색해야 하고, stravinest는 stravinest의 결제수단만 검색해야 한다."**

- 자동수집 결제수단은 **절대 공유 불가**
- 각 사용자는 **자신의 결제수단만** 매칭/저장 가능
- 같은 이름의 결제수단이 여러 멤버에게 있어도 **각자의 것만** 처리

---

## 4. 해결 방안

### 4.1 [필수] PaymentMethodInfo 클래스에 ownerUserId 추가

**파일**: `SupabaseHelper.kt`

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
    val ownerUserId: String  // 추가
)
```

### 4.2 [필수] 쿼리에 owner_user_id 필터 추가

**파일**: `SupabaseHelper.kt` - `getPaymentMethodsByLedger` 함수

**옵션 A: 현재 사용자의 결제수단만 로드 (권장)**

함수 시그니처 변경:
```kotlin
suspend fun getPaymentMethodsByLedger(ledgerId: String, ownerUserId: String): List<PaymentMethodInfo>
```

쿼리 변경:
```kotlin
.url("$baseUrl/rest/v1/payment_methods?ledger_id=eq.$ledgerId&owner_user_id=eq.$ownerUserId&select=id,name,auto_save_mode,auto_collect_source,owner_user_id")
```

**옵션 B: 전체 로드 후 매칭 시 필터 (비효율적, 비권장)**

### 4.3 [필수] FinancialNotificationListener 호출 부분 수정

**파일**: `FinancialNotificationListener.kt`

캐시 로드 시 userId 전달:
```kotlin
// Before
paymentMethodsCache = supabaseHelper.getPaymentMethodsByLedger(ledgerId)

// After
paymentMethodsCache = supabaseHelper.getPaymentMethodsByLedger(ledgerId, userId)
```

### 4.4 [필수] Fallback 매칭 로직에 sourceType 필터 추가

**파일**: `FinancialNotificationListener.kt` Line 273-280

**Before**:
```kotlin
matchedPaymentMethod = paymentMethodsCache.find { pm ->
    pm.autoCollectSource == "push" && combinedContent.contains(pm.name, ignoreCase = true)
}
```

**After**:
```kotlin
// sourceType에 맞는 결제수단만 매칭
val expectedSource = if (sourceType == "sms") "sms" else "push"
matchedPaymentMethod = paymentMethodsCache.find { pm ->
    pm.autoCollectSource == expectedSource &&
    combinedContent.contains(pm.name, ignoreCase = true)
}
```

**참고**: 4.2에서 이미 현재 사용자의 결제수단만 로드하므로 ownerUserId 체크는 불필요

---

## 5. 수정 대상 파일 요약

| 파일 | 변경 내용 | 중요도 |
|------|----------|--------|
| `SupabaseHelper.kt` | PaymentMethodInfo에 ownerUserId 추가 | 필수 |
| `SupabaseHelper.kt` | getPaymentMethodsByLedger에 owner 필터 추가 | 필수 |
| `FinancialNotificationListener.kt` | 캐시 로드 시 userId 전달 | 필수 |
| `FinancialNotificationListener.kt` | Fallback 매칭에 sourceType 필터 추가 | 필수 |

---

## 6. 테스트 시나리오

### 6.1 기본 테스트
| 시나리오 | 예상 결과 |
|---------|----------|
| 혀니 기기 + SMS 수신 + SMS 모드 설정 | 혀니의 SMS 모드 결제수단에 저장 |
| stravinest 기기 + Push 수신 + Push 모드 설정 | stravinest의 Push 모드 결제수단에 저장 |

### 6.2 핵심 Edge Case 테스트
| 시나리오 | 예상 결과 |
|---------|----------|
| 혀니 기기 + SMS/Push 동시 수신 | SMS 모드 결제수단에 SMS만 저장, Push 스킵 |
| 혀니 기기 + Push 수신 + SMS 모드 설정 | Push 스킵 (매칭되는 Push 모드 결제수단 없음) |
| 동일 이름 결제수단 (혀니:SMS, stravinest:Push) | 각자의 결제수단에만 저장 |

### 6.3 방어 테스트
| 시나리오 | 예상 결과 |
|---------|----------|
| 혀니 기기에서 stravinest 결제수단 매칭 시도 | 캐시에 stravinest 결제수단 없음, 매칭 실패 |

---

## 7. 다음 단계

1. `/pdca design sms-push-source-filtering-bug` - 상세 설계 문서 작성
2. `/pdca do sms-push-source-filtering-bug` - 구현
3. `/pdca analyze sms-push-source-filtering-bug` - 검증

---

**Plan 문서 작성 완료**
작성일: 2026-02-02
