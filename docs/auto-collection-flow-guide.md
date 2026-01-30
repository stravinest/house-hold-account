# 자동수집 플로우 가이드

> 이 문서는 SMS/Push 알림에서 결제 내역을 자동으로 수집하는 시스템의 플로우를 설명합니다.
> 초보 개발자도 쉽게 이해할 수 있도록 단계별로 상세히 설명합니다.

## 목차
1. [개요](#개요)
2. [네 가지 수집 모드](#네-가지-수집-모드)
3. [아키텍처](#아키텍처)
4. [SMS 플로우](#sms-플로우)
5. [Push 플로우](#push-플로우)
6. [디버그 방법](#디버그-방법)
7. [트러블슈팅](#트러블슈팅)

---

## 개요

### 목적
금융 앱(KB카드, 신한카드, 카카오페이 등)에서 발송하는 SMS/Push 알림을 자동으로 감지하여 가계부에 지출 내역을 자동 등록합니다.

### 주요 기능
- SMS 결제 알림 자동 감지 및 파싱
- Push 알림(앱 알림) 자동 감지 및 파싱
- 금액, 가맹점명, 거래 유형 자동 추출
- 중복 거래 자동 필터링
- 앱 종료 상태에서도 SMS/Push 알림 수집 (Kotlin 네이티브)
- **수집 소스 분리**: 결제수단별로 SMS 또는 Push 중 선택
- **저장 모드 분리**: 제안(사용자 확인) 또는 자동(바로 저장) 선택

---

## 네 가지 수집 모드

결제수단별로 수집 소스와 저장 모드를 설정할 수 있습니다.

### DB 컬럼 (payment_methods 테이블)

| 컬럼 | 타입 | 값 | 설명 |
|------|------|-----|------|
| `auto_collect_source` | text | `'sms'` | SMS로 수집 |
| `auto_collect_source` | text | `'push'` | Push 알림으로 수집 |
| `auto_save_mode` | text | `'suggest'` | 제안 모드 (사용자 확인 필요) |
| `auto_save_mode` | text | `'auto'` | 자동 모드 (바로 거래로 저장) |

### 네 가지 조합

| 모드 | auto_collect_source | auto_save_mode | 동작 |
|------|---------------------|----------------|------|
| **문자 + 제안** | `sms` | `suggest` | SMS 수집 → `pending_transactions` (status='pending') |
| **문자 + 자동** | `sms` | `auto` | SMS 수집 → `pending_transactions` (status='confirmed') + `transactions` |
| **푸쉬 + 제안** | `push` | `suggest` | Push 수집 → `pending_transactions` (status='pending') |
| **푸쉬 + 자동** | `push` | `auto` | Push 수집 → `pending_transactions` (status='confirmed') + `transactions` |

### 수집 소스 분리 동작

```
SMS 수신 시:
├── auto_collect_source = 'sms' → 처리 계속
└── auto_collect_source = 'push' → 스킵 ("Payment method is set to push mode")

Push 수신 시:
├── auto_collect_source = 'push' → 처리 계속
└── auto_collect_source = 'sms' → 스킵 ("Payment method is set to SMS mode")
```

### 저장 모드 분리 동작

```
suggest 모드:
└── pending_transactions (status='pending') 저장
    └── 사용자가 확인 후 transactions로 이동

auto 모드:
├── pending_transactions (status='confirmed') 저장 (히스토리용)
└── transactions 저장 (실제 거래 기록)
```

---

## 아키텍처

### 현재 구조 (2024.01 업데이트)

```
SMS 수집: Kotlin (SmsContentObserver) → 파싱 → Supabase 직접 저장
Push 수집: Kotlin (NotificationListenerService) → 파싱 → Supabase 직접 저장

공통 흐름:
1. 알림 수신 (Kotlin)
2. 금융 앱/발신자 필터링
3. 결제수단 매칭 + auto_collect_source 확인
4. 메시지 파싱 (FinancialMessageParser)
5. auto_save_mode에 따라 저장:
   - suggest: pending_transactions (pending)
   - auto: pending_transactions (confirmed) + transactions
```

### 핵심 파일 위치

| 역할 | 파일 경로 |
|------|----------|
| **SMS 수집** | `android/.../SmsContentObserver.kt` |
| **SMS 백그라운드 서비스** | `android/.../SmsObserverForegroundService.kt` |
| **Push 수집** | `android/.../FinancialNotificationListener.kt` |
| **메시지 파싱** | `android/.../FinancialMessageParser.kt` |
| **Supabase 통신** | `android/.../SupabaseHelper.kt` |
| **SQLite 캐싱** | `android/.../NotificationStorageHelper.kt` |
| **Flutter Push 래퍼** | `lib/.../notification_listener_wrapper.dart` |
| **Flutter 디버그 UI** | `lib/.../debug_test_page.dart` |

---

## SMS 플로우

SMS 결제 알림이 도착했을 때의 처리 플로우입니다.
**모든 처리는 Kotlin에서 수행되며, Flutter 없이도 동작합니다.**

```
SMS 수신 → 금융 발신자 필터링 → 결제수단 매칭 → 소스 확인 → 파싱 → 모드별 저장
```

### STEP 1: SMS 수신 (Kotlin)

**파일**: `android/.../SmsContentObserver.kt`
**메서드**: `onChange()`

```kotlin
// ContentObserver가 SMS DB 변경을 감지하면 호출
override fun onChange(selfChange: Boolean, uri: Uri?) {
    // SMS content://sms/inbox 테이블에서 최신 메시지 조회
    val cursor = context.contentResolver.query(
        Uri.parse("content://sms/inbox"),
        arrayOf("address", "body", "date"),
        null, null, "date DESC LIMIT 1"
    )
}
```

**입력**: SMS { address, body, date }
**로그 태그**: `FinancialSmsObserver`

---

### STEP 2: 금융 발신자 필터링 (Kotlin)

**파일**: `android/.../SmsContentObserver.kt`
**메서드**: `isFinancialSender()`

```kotlin
// 발신자 번호 또는 SMS 내용으로 금융사 판별
private fun isFinancialSender(sender: String, content: String): Boolean {
    val financialSenders = listOf(
        "15881688", "KB국민", "KB카드",      // KB국민카드
        "15447200", "신한카드",              // 신한카드
        "15882700", "삼성카드",              // 삼성카드
        // ...
    )
    return financialSenders.any { 
        sender.contains(it) || content.contains(it) 
    }
}
```

**결과**: 금융 SMS가 아니면 여기서 종료
**로그**: `"Not a financial SMS, skipping"`

---

### STEP 3: 결제수단 매칭 + 소스 확인 (Kotlin)

**파일**: `android/.../SmsContentObserver.kt`, `SupabaseHelper.kt`

```kotlin
// 1. 학습된 SMS 포맷에서 결제수단 찾기
val matchingFormat = learnedFormatsCache.find { format ->
    format.senderPatterns.any { sender.contains(it) } ||
    format.smsKeywords.any { content.contains(it) }
}
val paymentMethodId = matchingFormat?.paymentMethodId ?: ""

// 2. 결제수단의 auto_collect_source 확인
val settings = supabaseHelper.getPaymentMethodAutoSettings(paymentMethodId)

// 3. SMS 소스가 아니면 스킵
if (settings != null && !settings.isSmsSource) {
    Log.d(TAG, "Payment method is set to push mode, skipping SMS collection")
    return
}
```

**핵심 로직**: `auto_collect_source = 'push'`이면 SMS 수집 스킵
**로그**: `"Payment method is set to push mode, skipping SMS collection"`

---

### STEP 4: 메시지 파싱 (Kotlin)

**파일**: `android/.../FinancialMessageParser.kt`
**메서드**: `parse()`

```kotlin
// SMS 본문에서 금액, 가맹점, 거래 유형 추출
fun parse(sender: String, content: String): ParsedResult {
    val amount = parseAmount(content)           // 금액 추출
    val transactionType = parseType(content)    // 지출/수입
    val merchant = parseMerchant(content)       // 가맹점명
    
    return ParsedResult(
        amount = amount,           // 예: 50000
        transactionType = transactionType,  // 예: "expense"
        merchant = merchant,       // 예: "스타벅스"
        isParsed = amount != null
    )
}
```

**추출 항목**: 금액, 거래유형(expense/income), 가맹점명
**로그**: `"Parsed result: amount=50000, type=expense, merchant=스타벅스"`

---

### STEP 5: 모드별 저장 (Kotlin)

**파일**: `android/.../SupabaseHelper.kt`
**메서드**: `createPendingTransaction()`, `createConfirmedTransaction()`

```kotlin
// auto_save_mode에 따라 분기
val success = if (settings?.isAutoMode == true) {
    // 자동 모드: pending_transactions (confirmed) + transactions 동시 저장
    Log.d(TAG, "Auto mode enabled, creating confirmed transaction")
    supabaseHelper.createConfirmedTransaction(
        ledgerId = ledgerId,
        userId = userId,
        paymentMethodId = paymentMethodId,
        sourceType = "sms",
        sourceContent = content,
        parsedAmount = parsed.amount,
        parsedMerchant = parsed.merchant,
        // ...
    )
} else {
    // 제안 모드: pending_transactions (pending)만 저장
    Log.d(TAG, "Suggest mode, creating pending transaction")
    supabaseHelper.createPendingTransaction(
        status = "pending",
        // ...
    )
}
```

**저장 결과**:

| 모드 | pending_transactions | transactions | status |
|------|---------------------|--------------|--------|
| `suggest` | O | X | pending |
| `auto` | O | O | confirmed |

**로그**:
- 제안 모드: `"Suggest mode, creating pending transaction"`
- 자동 모드: `"Auto mode enabled..., creating confirmed transaction"`

---

### STEP 6: Flutter UI 갱신

**파일**: `lib/.../pending_transaction_provider.dart`

```dart
// Supabase Realtime으로 변경 감지
_client.channel('pending_transactions_changes')
  .onPostgresChanges(
    event: PostgresChangeEvent.all,
    table: 'pending_transactions',
    callback: (payload) {
      loadPendingTransactions(silent: true);
    },
  )
  .subscribe();
```

**결과**: Flutter UI의 pending 목록 자동 갱신

---

## Push 플로우

Push 알림이 도착했을 때의 처리 플로우입니다.
**앱이 종료되어도 Kotlin NotificationListenerService가 백그라운드에서 동작합니다.**

```
Push 수신 → 금융 앱 필터링 → 키워드 필터링 → 결제수단 매칭 → 소스 확인 → 파싱 → 모드별 저장
```

### STEP 1: Push 알림 수신 (Kotlin)

**파일**: `android/.../FinancialNotificationListener.kt`
**메서드**: `onNotificationPosted()`

```kotlin
// NotificationListenerService가 알림을 수신하면 호출
override fun onNotificationPosted(sbn: StatusBarNotification?) {
    val packageName = sbn.packageName  // 예: "com.kbcard.cxh.appcard"
    val title = extras.getCharSequence(Notification.EXTRA_TITLE)
    val content = extras.getCharSequence(Notification.EXTRA_TEXT)
    val bigText = extras.getCharSequence(Notification.EXTRA_BIG_TEXT)
}
```

**입력**: `StatusBarNotification { packageName, title, content }`
**로그 태그**: `FinancialPushListener`

---

### STEP 2: 금융 앱 필터링 (Kotlin)

**파일**: `android/.../FinancialNotificationListener.kt`
**메서드**: `isFinancialApp()`

```kotlin
// 금융 앱 패키지인지 확인
private fun isFinancialApp(packageName: String): Boolean {
    return FINANCIAL_APP_PACKAGES.contains(packageName.lowercase())
}

// 금융 앱 목록 (35개+)
private val FINANCIAL_APP_PACKAGES = buildSet {
    add("com.kbcard.cxh.appcard")      // KB Pay
    add("com.shcard.smartpay")          // 신한 SOL페이
    add("com.samsung.android.spay")     // 삼성페이
    add("com.kakaopay.app")             // 카카오페이
    add("viva.republica.toss")          // 토스
    // ...
    
    // DEBUG 빌드에서만 테스트용 패키지 포함
    if (BuildConfig.DEBUG) {
        add("com.android.shell")  // cmd notification post 테스트용
    }
}
```

**결과**: 금융 앱이 아니면 여기서 종료
**로그**: `"Financial notification received from: com.kbcard.cxh.appcard"`

---

### STEP 3: 키워드 필터링 (Kotlin)

**파일**: `android/.../FinancialNotificationListener.kt`
**메서드**: `containsPaymentKeyword()`

```kotlin
// 결제 관련 키워드 포함 여부 확인
private val PAYMENT_KEYWORDS = listOf(
    "원", "won", "krw",
    "승인", "결제", "사용", "출금", "입금", "이체", "충전",
    "취소", "환불",
    "카드", "체크", "신용",
    "계좌", "통장", "잔액",
    "지역화폐", "페이", "pay"
)

private fun containsPaymentKeyword(text: String): Boolean {
    return PAYMENT_KEYWORDS.any { text.lowercase().contains(it) }
}
```

**결과**: 키워드가 없으면 여기서 종료
**로그**: `"Notification does not contain payment keywords, skipping"`

---

### STEP 4: SQLite 캐싱 (Kotlin)

**파일**: `android/.../NotificationStorageHelper.kt`
**메서드**: `insertNotification()`

```kotlin
// SQLite에 알림 저장 (Flutter 동기화 및 중복 체크용)
fun insertNotification(
    packageName: String,
    title: String?,
    text: String,
    receivedAt: Long
): Long {
    val values = ContentValues().apply {
        put("package_name", packageName)
        put("title", title)
        put("text", text)
        put("received_at", receivedAt)
        put("is_synced", 0)
    }
    return db.insert("cached_notifications", null, values)
}
```

**저장 위치**: `databases/financial_notifications.db`
**로그**: `"Notification saved to SQLite with id: 123"`

---

### STEP 5: 결제수단 매칭 + 소스 확인 (Kotlin)

**파일**: `android/.../FinancialNotificationListener.kt`, `SupabaseHelper.kt`

```kotlin
// 1. 학습된 Push 포맷에서 결제수단 찾기
val matchingFormat = learnedFormatsCache.find { format ->
    format.packageName.equals(packageName, ignoreCase = true) ||
    format.appKeywords.any { combinedContent.contains(it, ignoreCase = true) }
}
val paymentMethodId = matchingFormat?.paymentMethodId ?: ""

// 2. 결제수단의 auto_collect_source 확인
val settings = supabaseHelper.getPaymentMethodAutoSettings(paymentMethodId)

// 3. Push 소스가 아니면 스킵
if (settings != null && !settings.isPushSource) {
    Log.d(TAG, "Payment method is set to SMS mode, skipping push notification collection")
    return
}
```

**핵심 로직**: `auto_collect_source = 'sms'`이면 Push 수집 스킵
**로그**: `"Payment method is set to SMS mode, skipping push notification collection"`

---

### STEP 6: 메시지 파싱 (Kotlin)

**파일**: `android/.../FinancialMessageParser.kt`
**메서드**: `parse()`, `parseWithFormat()`

```kotlin
// Push 내용에서 금액, 가맹점, 거래 유형 추출
val parsed = if (matchingFormat != null) {
    FinancialMessageParser.parseWithFormat(combinedContent, matchingFormat)
} else {
    FinancialMessageParser.parse(packageName, combinedContent)
}
```

**추출 항목**: 금액, 거래유형(expense/income), 가맹점명
**로그**: `"Parsed result: amount=50000, type=expense, merchant=스타벅스"`

---

### STEP 7: 모드별 저장 (Kotlin)

**파일**: `android/.../SupabaseHelper.kt`

```kotlin
// auto_save_mode에 따라 분기
val success = if (settings?.isAutoMode == true) {
    Log.d(TAG, "Auto mode enabled for payment method: $paymentMethodId, creating confirmed transaction")
    supabaseHelper.createConfirmedTransaction(
        ledgerId = ledgerId,
        userId = userId,
        paymentMethodId = paymentMethodId,
        sourceType = "notification",  // Push는 "notification"
        sourceSender = packageName,
        sourceContent = combinedContent,
        parsedAmount = parsed.amount,
        parsedMerchant = parsed.merchant,
        // ...
    )
} else {
    Log.d(TAG, "Suggest mode for payment method: $paymentMethodId, creating pending transaction")
    supabaseHelper.createPendingTransaction(
        status = "pending",
        // ...
    )
}
```

**저장 결과**:

| 모드 | pending_transactions | transactions | status |
|------|---------------------|--------------|--------|
| `suggest` | O | X | pending |
| `auto` | O | O | confirmed |

**로그**:
- 제안 모드: `"Suggest mode for payment method: ..., creating pending transaction"`
- 자동 모드: `"Auto mode enabled for payment method: ..., creating confirmed transaction"`

---

### STEP 8: SQLite 동기화 표시 + Flutter 알림

```kotlin
// Supabase 저장 성공 시 SQLite에서 동기화됨으로 표시
if (success) {
    storageHelper.markAsSynced(listOf(sqliteId))
}

// Flutter에 이벤트 전달 (UI 갱신용)
MainActivity.notifyNewNotification(packageName, pendingCount)
```

**로그**: `"Notification saved to Supabase, marking SQLite as synced"`

---

## 디버그 방법

### 로그 필터링 명령어

```bash
# SMS 수집 로그
adb logcat | grep -E "FinancialSmsObserver"

# Push 수집 로그
adb logcat | grep -E "FinancialPushListener"

# 모드 확인 로그 (가장 유용!)
adb logcat | grep -E "(Auto mode|Suggest mode|SMS mode|push mode)"

# Supabase 저장 로그
adb logcat | grep -E "SupabaseHelper"

# 파싱 로그
adb logcat | grep -E "FinancialMessageParser|Parsed"

# 에러만
adb logcat | grep -E "(Error|Exception|Failed)" | grep -i financial

# 전체 자동수집 로그
adb logcat | grep -E "(FinancialSms|FinancialPush|SupabaseHelper)"
```

### 테스트 스크립트

```bash
# SMS 테스트
./scripts/test_financial_sms.sh -a 50000 -m 스타벅스 kb

# Push 테스트 (KB Pay)
./scripts/simulate_kbpay.sh 50000 '스타벅스'

# Push 테스트 (기본)
./scripts/simulate_push.sh "KB국민카드" "승인 50,000원 스타벅스"
```

### 수동 Push 테스트 (ADB)

```bash
# DEBUG 빌드에서만 동작!
adb shell "cmd notification post -t 'KB Pay' 'test' 'KB국민카드1004승인 전*규님 50,000원 스타벅스'"
```

### SQLite 확인 (Push 캐시)

```bash
# 캐싱된 알림 수 확인
adb shell run-as com.household.shared.shared_household_account \
  sqlite3 databases/financial_notifications.db \
  "SELECT COUNT(*) FROM cached_notifications WHERE is_synced = 0"

# 최근 알림 확인
adb shell run-as com.household.shared.shared_household_account \
  sqlite3 databases/financial_notifications.db \
  "SELECT package_name, title, substr(text, 1, 30) FROM cached_notifications ORDER BY received_at DESC LIMIT 5"
```

### 결제수단 설정 확인 (SQL)

```sql
-- 결제수단별 자동수집 설정 확인
SELECT name, auto_collect_source, auto_save_mode 
FROM house.payment_methods 
WHERE user_id = '<user_id>';
```

---

## 트러블슈팅

### SMS가 수집되지 않음

**증상**: SMS를 받았는데 pending_transactions에 저장되지 않음

**확인 사항**:

1. **금융 발신자인지 확인**
   ```bash
   adb logcat | grep -E "FinancialSmsObserver.*Not a financial"
   ```
   - 로그가 보이면 발신자가 금융 목록에 없음
   - 해결: `SmsContentObserver.kt`에 발신자 패턴 추가

2. **auto_collect_source 확인**
   ```bash
   adb logcat | grep -E "push mode, skipping SMS"
   ```
   - 로그가 보이면 결제수단이 Push 모드로 설정됨
   - 해결: `auto_collect_source = 'sms'`로 변경

3. **결제수단 매칭 실패**
   ```bash
   adb logcat | grep -E "No matching payment method"
   ```
   - 해결: 학습된 SMS 포맷 추가

---

### Push가 수집되지 않음

**증상**: Push 알림을 받았는데 pending_transactions에 저장되지 않음

**확인 사항**:

1. **금융 앱인지 확인**
   ```bash
   adb logcat | grep -E "FinancialPushListener.*Financial notification"
   ```
   - 로그가 없으면 패키지가 금융 앱 목록에 없음
   - 해결: `FinancialNotificationListener.kt`에 패키지 추가

2. **auto_collect_source 확인**
   ```bash
   adb logcat | grep -E "SMS mode, skipping push"
   ```
   - 로그가 보이면 결제수단이 SMS 모드로 설정됨
   - 해결: `auto_collect_source = 'push'`로 변경

3. **알림 리스너 권한**
   - 설정 > 알림 > 알림 접근 > 앱 활성화 확인

4. **DEBUG 빌드 확인 (ADB 테스트 시)**
   - Release 빌드에서는 `com.android.shell` 패키지가 금융 앱 목록에 없음
   - 해결: DEBUG 빌드로 테스트

---

### 자동 모드인데 transactions에 저장 안됨

**증상**: `auto_save_mode = 'auto'`인데 transactions 테이블에 레코드가 없음

**확인 사항**:

1. **모드 확인 로그**
   ```bash
   adb logcat | grep -E "(Auto mode|Suggest mode)"
   ```
   - "Suggest mode" 로그가 보이면 설정이 잘못됨

2. **DB 설정 확인**
   ```sql
   SELECT name, auto_save_mode, auto_collect_source 
   FROM house.payment_methods 
   WHERE id = '<payment_method_id>';
   ```

3. **createConfirmedTransaction 에러**
   ```bash
   adb logcat | grep -E "SupabaseHelper.*error|Exception"
   ```

---

### 파싱 실패 (금액/가맹점 없음)

**증상**: pending_transactions에 `parsed_amount = null`

**확인 사항**:

1. **원본 메시지 확인**
   ```bash
   adb logcat | grep -E "sourceContent|Processing SMS|combinedContent"
   ```

2. **파싱 결과 확인**
   ```bash
   adb logcat | grep -E "Parsed|isParsed"
   ```

3. **해결**: `FinancialMessageParser.kt`에 새 패턴 추가

---

### Supabase 저장 실패

**증상**: 파싱은 성공했는데 DB에 저장 안됨

**확인 사항**:

1. **토큰 확인**
   ```bash
   adb logcat | grep -E "getValidToken|token"
   ```

2. **ledgerId 확인**
   ```bash
   adb logcat | grep -E "ledgerId|No ledger"
   ```

3. **RLS 정책**
   - Supabase Dashboard > Logs에서 에러 확인
   - `user_id = auth.uid()` 조건 확인

---

## 관련 문서

- [자동수집 테스트 가이드](./auto_collect_testing_guide.md)
- [Supabase 가이드](./supabase_guide.md)
