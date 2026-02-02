# Plan: 자동수집 사용자 격리 완전 수정

**Feature ID**: `auto-collect-user-isolation-fix`
**작성일**: 2026-02-02
**PDCA Phase**: Plan
**선행 작업**: `sms-push-source-filtering-bug` (100% 완료)

---

## 1. 배경 및 문제 정의

### 1.1 발견된 문제 (코드 리뷰 결과)

이전 수정 (`sms-push-source-filtering-bug`)에서 `paymentMethodsCache`의 사용자 격리는 완료했으나, 추가적인 보안 취약점이 발견됨.

### 1.2 이슈 목록

| 우선순위 | ID | 문제 | 영향도 |
|:--------:|:--:|------|--------|
| **Critical** | C-1 | `learnedFormatsCache`에 owner 필터 없음 | 다른 사용자 포맷으로 매칭 가능 |
| **High** | H-1 | `matchingFormat`의 `paymentMethodId`가 다른 사용자 것일 수 있음 | 잘못된 결제수단 매칭 |
| **High** | H-2 | 캐시 갱신 타이밍 이슈 (설정 변경 반영 지연) | 설정 변경 후 오동작 |
| **High** | H-3 | `getPaymentMethodAutoSettings`에 소유자 검증 없음 | 다른 사용자 설정 조회 가능 |
| **Medium** | M-1 | JWT 파싱 반복 (성능) | 불필요한 CPU 사용 |
| **Medium** | M-2 | `paymentMethodsCache` 전체 순회 (성능) | O(n) 검색 비용 |

---

## 2. 수정 범위

### 2.1 수정 대상 파일

| 파일 | 변경 내용 |
|------|----------|
| `SupabaseHelper.kt` | `getLearnedPushFormats`에 owner 필터 추가 |
| `FinancialNotificationListener.kt` | `matchingFormat` 검증 로직 추가 |
| `FinancialNotificationListener.kt` | 캐시 강제 무효화 메커니즘 |
| `MainActivity.kt` | Flutter → Kotlin 캐시 무효화 채널 |

### 2.2 수정하지 않는 항목

- M-1, M-2 (성능 이슈): 현재 사용량에서 문제 없음, 추후 최적화

---

## 3. 상세 수정 계획

### 3.1 [Critical] C-1: `learnedFormatsCache` owner 필터 추가

**현재 코드** (`SupabaseHelper.kt:484`):
```kotlin
val url = "$baseUrl/rest/v1/learned_push_formats?select=*,payment_methods!inner(ledger_id)&payment_methods.ledger_id=eq.$ledgerId"
```

**문제**: `ledgerId`만 필터링하여 가계부 전체 포맷 조회

**수정 방향**:
```kotlin
suspend fun getLearnedPushFormats(ledgerId: String, ownerUserId: String): List<LearnedPushFormat>

// 쿼리 변경
val url = "$baseUrl/rest/v1/learned_push_formats?select=*,payment_methods!inner(ledger_id,owner_user_id)&payment_methods.ledger_id=eq.$ledgerId&payment_methods.owner_user_id=eq.$ownerUserId"
```

**호출부 수정** (`FinancialNotificationListener.kt:361`):
```kotlin
learnedFormatsCache = supabaseHelper.getLearnedPushFormats(ledgerId, userId)
```

---

### 3.2 [High] H-1: `matchingFormat` 소유자 검증

**현재 코드** (`FinancialNotificationListener.kt:249-254`):
```kotlin
val matchingFormat = learnedFormatsCache.find { format ->
    format.packageName.equals(packageName, ignoreCase = true) ||
    format.appKeywords.any { keyword ->
        combinedContent.contains(keyword, ignoreCase = true)
    }
}
```

**문제**: 매칭된 포맷의 `paymentMethodId`가 현재 사용자 것인지 검증 안 함

**수정 방향**:
```kotlin
// C-1 수정으로 learnedFormatsCache가 이미 현재 사용자 것만 포함
// 추가 검증: matchingFormat의 paymentMethodId가 paymentMethodsCache에 존재하는지 확인
val matchingFormat = learnedFormatsCache.find { format ->
    (format.packageName.equals(packageName, ignoreCase = true) ||
     format.appKeywords.any { keyword ->
         combinedContent.contains(keyword, ignoreCase = true)
     }) &&
    // 추가 검증: 현재 사용자의 결제수단인지 확인
    paymentMethodsCache.any { pm -> pm.id == format.paymentMethodId }
}
```

---

### 3.3 [High] H-2: 캐시 강제 무효화 메커니즘

**현재 문제**:
- Flutter에서 설정 변경 → Realtime으로 Flutter 캐시 갱신
- Kotlin 서비스는 `FORMAT_CACHE_DURATION_MS` 만료까지 갱신 안 됨

**수정 방향**:

1. **Flutter → Kotlin 캐시 무효화 채널 추가**

`MainActivity.kt`:
```kotlin
// MethodChannel 핸들러 추가
"invalidateNotificationCache" -> {
    FinancialNotificationListener.instance?.invalidateCache()
    result.success(true)
}
```

`FinancialNotificationListener.kt`:
```kotlin
fun invalidateCache() {
    lastFormatsFetchTime = 0  // 다음 알림 시 캐시 강제 갱신
    Log.d(TAG, "Cache invalidated by Flutter request")
}
```

2. **Flutter에서 설정 변경 시 호출**

`payment_method_repository.dart` 또는 `auto_save_settings_page.dart`:
```dart
// 설정 저장 후
await MethodChannel('notification_channel').invokeMethod('invalidateNotificationCache');
```

---

### 3.4 [High] H-3: `getPaymentMethodAutoSettings` 소유자 검증

**현재 코드** (`SupabaseHelper.kt:641-675`):
```kotlin
suspend fun getPaymentMethodAutoSettings(paymentMethodId: String): PaymentMethodAutoSettings?
```

**문제**: `paymentMethodId`만으로 조회, 소유자 검증 없음

**수정 방향** (2가지 옵션):

**옵션 A: 함수 제거 (권장)**
- `matchedPaymentMethod`가 있으면 이미 캐시에서 설정 가져옴
- `matchingFormat`으로만 매칭된 경우, C-1 수정으로 이미 현재 사용자 포맷만 포함
- 추가 API 호출 불필요

**옵션 B: 소유자 파라미터 추가**
```kotlin
suspend fun getPaymentMethodAutoSettings(paymentMethodId: String, ownerUserId: String): PaymentMethodAutoSettings?
// 쿼리에 owner_user_id=eq.$ownerUserId 추가
```

**채택**: 옵션 A (코드 단순화)

---

## 4. 구현 순서

1. `SupabaseHelper.kt` - `getLearnedPushFormats` 시그니처 및 쿼리 수정
2. `FinancialNotificationListener.kt` - `refreshFormatsCache` 호출부 수정
3. `FinancialNotificationListener.kt` - `matchingFormat` 검증 로직 추가
4. `FinancialNotificationListener.kt` - `invalidateCache` 함수 추가
5. `MainActivity.kt` - MethodChannel 핸들러 추가
6. Flutter - 설정 변경 시 캐시 무효화 호출

---

## 5. 테스트 시나리오

### 5.1 사용자 격리 테스트

| ID | 시나리오 | 예상 결과 |
|----|----------|----------|
| T-1 | 혀니 기기에서 KB Pay 알림, stravinest도 KB Pay 포맷 학습됨 | 혀니의 포맷/결제수단만 매칭 |
| T-2 | stravinest 기기에서 KB Pay 알림 | stravinest의 포맷/결제수단만 매칭 |
| T-3 | 공유 가계부에서 동시 알림 수신 | 각자의 결제수단에만 저장 |

### 5.2 캐시 무효화 테스트

| ID | 시나리오 | 예상 결과 |
|----|----------|----------|
| T-4 | 혀니가 SMS→Push 변경 후 즉시 알림 | Push로 처리됨 |
| T-5 | 혀니가 suggest→auto 변경 후 즉시 알림 | 자동 저장됨 |

---

## 6. 롤백 계획

- 변경 범위가 Kotlin 2-3개 파일로 제한
- 데이터베이스 스키마 변경 없음
- Git revert로 즉시 롤백 가능

---

## 7. 성공 기준

- [ ] Critical 이슈 (C-1) 해결: `learnedFormatsCache` 사용자 격리
- [ ] High 이슈 (H-1, H-2, H-3) 해결
- [ ] 빌드 성공
- [ ] 기존 자동수집 기능 정상 동작

---

**Plan 문서 작성 완료**
작성일: 2026-02-02
