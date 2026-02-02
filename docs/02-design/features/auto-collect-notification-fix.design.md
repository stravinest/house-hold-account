# Design: 자동수집 푸시알림 미발송 버그 수정

**Feature ID**: `auto-collect-notification-fix`
**작성일**: 2026-02-02
**PDCA Phase**: Design
**Plan 문서**: `docs/01-plan/features/auto-collect-notification-fix.plan.md`

---

## 1. 설계 개요

### 1.1 목표

Kotlin 네이티브 코드(`FinancialNotificationListener`)에서 백그라운드 자동수집 시 Android NotificationManager를 사용하여 사용자에게 Local Notification을 표시한다.

### 1.2 설계 원칙

- **최소 변경**: 기존 Supabase 저장 로직 유지, 알림 표시 로직만 추가
- **설정 연동**: DB의 `notification_settings` 테이블 설정 반영
- **성능 고려**: 알림 설정 조회 시 불필요한 API 호출 최소화
- **일관성**: Flutter 로컬 알림과 동일한 채널 ID 사용

---

## 2. 아키텍처 설계

### 2.1 전체 흐름

```
┌─────────────────────────────────────────────────────────────────────┐
│                  FinancialNotificationListener                       │
│                                                                      │
│  onNotificationPosted()                                              │
│         ↓                                                            │
│  processNotification()                                               │
│         ↓                                                            │
│  supabaseHelper.createPendingTransaction() ─────────────────────┐    │
│         ↓                                                        │   │
│  ┌─────────────────────────────────────────┐                     │   │
│  │ [NEW] 알림 표시 로직                     │                     │   │
│  │                                          │                     │   │
│  │  1. 사용자 알림 설정 확인                │                     │   │
│  │     supabaseHelper.getNotificationSetting│                     │   │
│  │              ↓                           │                     │   │
│  │  2. 설정이 true면 알림 표시              │                     │   │
│  │     showAutoCollectNotification()        │                     │   │
│  │              ↓                           │                     │   │
│  │  3. 알림 히스토리 저장                   │                     │   │
│  │     supabaseHelper.savePushNotification  │                     │   │
│  └─────────────────────────────────────────┘                     │   │
│         ↓                                                        │   │
│  notifyFlutter() ← eventSink null이어도 알림은 이미 표시됨        │   │
│                                                                  ↓   │
└─────────────────────────────────────────────────────────────────────┘
                                                                   │
                                                      ┌────────────┘
                                                      ↓
                                           Supabase (house schema)
                                           ├── pending_transactions
                                           ├── notification_settings (read)
                                           └── push_notifications (write)
```

### 2.2 컴포넌트 설계

| 컴포넌트 | 파일 | 역할 |
|----------|------|------|
| `SupabaseHelper` | `SupabaseHelper.kt` | 알림 설정 조회, 히스토리 저장 |
| `FinancialNotificationListener` | `FinancialNotificationListener.kt` | 알림 표시 로직 |

---

## 3. 상세 설계

### 3.1 SupabaseHelper - 알림 설정 조회

**함수 시그니처**:
```kotlin
suspend fun getAutoCollectNotificationSetting(
    userId: String,
    isAutoMode: Boolean
): Boolean
```

**API 요청**:
```
GET /rest/v1/notification_settings
    ?select={column}
    &user_id=eq.{userId}

Headers:
    Authorization: Bearer {token}
    apikey: {anonKey}
    Accept-Profile: house
```

**컬럼 매핑**:
| isAutoMode | 조회 컬럼 |
|------------|----------|
| true | `auto_collect_saved_enabled` |
| false | `auto_collect_suggested_enabled` |

**반환값**:
- DB 값 존재 시: 해당 컬럼 값 (true/false)
- DB 값 없음/에러 시: `true` (기본값 - 알림 활성화)

**코드**:
```kotlin
suspend fun getAutoCollectNotificationSetting(
    userId: String,
    isAutoMode: Boolean
): Boolean = withContext(Dispatchers.IO) {
    try {
        val baseUrl = supabaseUrl ?: return@withContext true
        val apiKey = anonKey ?: return@withContext true
        val token = getValidToken() ?: return@withContext true

        val column = if (isAutoMode)
            "auto_collect_saved_enabled"
        else
            "auto_collect_suggested_enabled"

        val url = "$baseUrl/rest/v1/notification_settings?select=$column&user_id=eq.$userId"

        val request = Request.Builder()
            .url(url)
            .get()
            .addHeader("Authorization", "Bearer $token")
            .addHeader("apikey", apiKey)
            .addHeader("Accept-Profile", SCHEMA)
            .build()

        val response = client.newCall(request).execute()

        if (response.isSuccessful) {
            val responseBody = response.body?.string() ?: return@withContext true
            val jsonArray = JSONArray(responseBody)
            if (jsonArray.length() > 0) {
                val setting = jsonArray.getJSONObject(0)
                return@withContext setting.optBoolean(column, true)
            }
        }
        true  // 기본값: 알림 활성화
    } catch (e: Exception) {
        Log.e(TAG, "Error getting notification setting", e)
        true  // 에러 시에도 알림 표시 (보수적 접근)
    }
}
```

---

### 3.2 SupabaseHelper - 알림 히스토리 저장

**함수 시그니처**:
```kotlin
suspend fun savePushNotificationHistory(
    userId: String,
    type: String,
    title: String,
    body: String,
    data: Map<String, Any?>
): Boolean
```

**API 요청**:
```
POST /rest/v1/push_notifications

Headers:
    Authorization: Bearer {token}
    apikey: {anonKey}
    Content-Type: application/json
    Content-Profile: house
    Prefer: return=minimal

Body:
{
    "user_id": "{userId}",
    "type": "{type}",
    "title": "{title}",
    "body": "{body}",
    "data": {...},
    "is_read": false
}
```

**코드**:
```kotlin
suspend fun savePushNotificationHistory(
    userId: String,
    type: String,
    title: String,
    body: String,
    data: Map<String, Any?>
): Boolean = withContext(Dispatchers.IO) {
    try {
        val baseUrl = supabaseUrl ?: return@withContext false
        val apiKey = anonKey ?: return@withContext false
        val token = getValidToken() ?: return@withContext false

        val json = JSONObject().apply {
            put("user_id", userId)
            put("type", type)
            put("title", title)
            put("body", body)
            put("data", JSONObject(data))
            put("is_read", false)
        }

        val requestBody = json.toString().toRequestBody("application/json".toMediaType())

        val request = Request.Builder()
            .url("$baseUrl/rest/v1/push_notifications")
            .post(requestBody)
            .addHeader("Authorization", "Bearer $token")
            .addHeader("apikey", apiKey)
            .addHeader("Content-Type", "application/json")
            .addHeader("Content-Profile", SCHEMA)
            .addHeader("Prefer", "return=minimal")
            .build()

        val response = client.newCall(request).execute()
        response.isSuccessful
    } catch (e: Exception) {
        Log.e(TAG, "Error saving push notification history", e)
        false
    }
}
```

---

### 3.3 FinancialNotificationListener - 알림 표시

**함수 시그니처**:
```kotlin
private fun showAutoCollectNotification(
    isAutoMode: Boolean,
    amount: Int?,
    merchant: String?,
    paymentMethodName: String?
)
```

**알림 채널 설정**:
| 속성 | 값 |
|------|---|
| Channel ID | `household_account_channel` (Flutter와 동일) |
| Channel Name | `공유 가계부 알림` |
| Importance | `IMPORTANCE_DEFAULT` |

**알림 내용**:
| isAutoMode | 제목 | 본문 예시 |
|------------|------|----------|
| false (suggest) | 자동수집 거래 확인 | 13,530원 컬리 - KB국민카드 |
| true (auto) | 자동수집 거래 저장 | 6,000원 아성다이소 - KB국민카드 |

**딥링크 Intent**:
```kotlin
Intent(context, MainActivity::class.java).apply {
    flags = FLAG_ACTIVITY_NEW_TASK or FLAG_ACTIVITY_CLEAR_TOP
    putExtra("targetTab", if (isAutoMode) "confirmed" else "pending")
    putExtra("route", "/payment-method-management")
}
```

**코드**:
```kotlin
private fun showAutoCollectNotification(
    isAutoMode: Boolean,
    amount: Int?,
    merchant: String?,
    paymentMethodName: String?
) {
    val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    // Android 8.0+ 채널 생성 (Flutter와 동일한 채널 사용)
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
        val existingChannel = notificationManager.getNotificationChannel("household_account_channel")
        if (existingChannel == null) {
            val channel = NotificationChannel(
                "household_account_channel",
                "공유 가계부 알림",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "공유 가계부 관련 알림 채널"
                enableVibration(true)
            }
            notificationManager.createNotificationChannel(channel)
        }
    }

    val title = if (isAutoMode) "자동수집 거래 저장" else "자동수집 거래 확인"
    val body = buildString {
        if (amount != null) {
            append(String.format("%,d", amount))
            append("원")
        }
        if (!merchant.isNullOrBlank()) {
            if (isNotEmpty()) append(" ")
            append(merchant)
        }
        if (!paymentMethodName.isNullOrBlank()) {
            if (isNotEmpty()) append(" - ")
            append(paymentMethodName)
        }
        if (isEmpty()) {
            append("새로운 거래가 수집되었습니다.")
        }
    }

    // 딥링크 Intent
    val intent = Intent(this, MainActivity::class.java).apply {
        flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        putExtra("targetTab", if (isAutoMode) "confirmed" else "pending")
        putExtra("route", "/payment-method-management")
    }

    val pendingIntent = PendingIntent.getActivity(
        this,
        System.currentTimeMillis().toInt(),
        intent,
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
    )

    val notification = NotificationCompat.Builder(this, "household_account_channel")
        .setSmallIcon(R.mipmap.ic_launcher)
        .setContentTitle(title)
        .setContentText(body)
        .setContentIntent(pendingIntent)
        .setAutoCancel(true)
        .setPriority(NotificationCompat.PRIORITY_DEFAULT)
        .build()

    notificationManager.notify(System.currentTimeMillis().toInt(), notification)
    Log.d(TAG, "Auto-collect notification shown: $title - $body")
}
```

---

### 3.4 processNotification 수정

**수정 위치**: `processNotification()` 함수 내, Supabase 저장 성공 후

**수정 전** (357-364줄):
```kotlin
if (success) {
    Log.d(TAG, "Notification saved to Supabase, marking SQLite as synced")
    storageHelper.markAsSynced(listOf(sqliteId))
} else {
    Log.d(TAG, "Supabase save failed, keeping in SQLite for later sync")
}

notifyFlutter(packageName)
```

**수정 후**:
```kotlin
if (success) {
    Log.d(TAG, "Notification saved to Supabase, marking SQLite as synced")
    storageHelper.markAsSynced(listOf(sqliteId))

    // 사용자 알림 설정 확인 후 Local Notification 표시
    val isAutoMode = settings?.isAutoMode == true
    val shouldShowNotification = supabaseHelper.getAutoCollectNotificationSetting(userId, isAutoMode)

    if (shouldShowNotification) {
        // 결제수단 이름 가져오기
        val paymentMethodName = matchedPaymentMethod?.name
            ?: paymentMethodsCache.find { it.id == paymentMethodId }?.name

        showAutoCollectNotification(
            isAutoMode = isAutoMode,
            amount = parsed.amount,
            merchant = parsed.merchant,
            paymentMethodName = paymentMethodName
        )

        // 알림 히스토리 저장
        val notificationType = if (isAutoMode) "auto_collect_saved" else "auto_collect_suggested"
        supabaseHelper.savePushNotificationHistory(
            userId = userId,
            type = notificationType,
            title = if (isAutoMode) "자동수집 거래 저장" else "자동수집 거래 확인",
            body = buildNotificationBody(parsed.amount, parsed.merchant, paymentMethodName),
            data = mapOf(
                "targetTab" to if (isAutoMode) "confirmed" else "pending",
                "paymentMethodId" to paymentMethodId,
                "amount" to parsed.amount,
                "merchant" to parsed.merchant
            )
        )
    }
} else {
    Log.d(TAG, "Supabase save failed, keeping in SQLite for later sync")
}

notifyFlutter(packageName)
```

---

## 4. 필요한 Import 추가

**FinancialNotificationListener.kt**:
```kotlin
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
```

---

## 5. 테스트 케이스

### 5.1 알림 표시 테스트

| ID | 시나리오 | 검증 항목 | 예상 결과 |
|----|----------|----------|----------|
| T-1 | suggest 모드, 앱 종료 상태 | 알림 표시 | "자동수집 거래 확인" 알림 |
| T-2 | auto 모드, 앱 종료 상태 | 알림 표시 | "자동수집 거래 저장" 알림 |
| T-3 | 앱 백그라운드 상태 | 알림 + EventChannel | 둘 다 동작 |

### 5.2 설정 연동 테스트

| ID | 설정 | 결과 |
|----|------|------|
| T-4 | suggested_enabled = false | 알림 없음, DB 저장만 |
| T-5 | saved_enabled = false | 알림 없음, DB 저장만 |
| T-6 | 설정 레코드 없음 | 알림 표시 (기본값 true) |

### 5.3 DB 연동 테스트

| ID | 검증 항목 | 예상 결과 |
|----|----------|----------|
| T-7 | push_notifications 테이블 | 알림 히스토리 저장 |
| T-8 | type 컬럼 | "auto_collect_suggested" or "auto_collect_saved" |

---

## 6. 구현 순서

1. **SupabaseHelper.kt**
   - [ ] `getAutoCollectNotificationSetting()` 함수 추가
   - [ ] `savePushNotificationHistory()` 함수 추가

2. **FinancialNotificationListener.kt**
   - [ ] Import 추가
   - [ ] `showAutoCollectNotification()` 함수 추가
   - [ ] `buildNotificationBody()` 헬퍼 함수 추가
   - [ ] `processNotification()` 수정

3. **빌드 및 테스트**
   - [ ] `flutter build apk --debug`
   - [ ] 에뮬레이터/실기기 테스트

---

## 7. 성공 기준

- [ ] 백그라운드에서 자동수집 시 Android 상단바에 알림 표시
- [ ] 알림 설정 (enabled/disabled) DB 값 연동
- [ ] `push_notifications` 테이블에 히스토리 정상 저장
- [ ] 알림 탭 시 앱 열림 → 결제수단 관리 → 적절한 탭 이동
- [ ] 빌드 성공
- [ ] 기존 자동수집 기능 정상 동작

---

**Design 문서 작성 완료**
작성일: 2026-02-02
