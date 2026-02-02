# Plan: 자동수집 푸시알림 미발송 버그 수정

**Feature ID**: `auto-collect-notification-fix`
**작성일**: 2026-02-02
**PDCA Phase**: Plan
**선행 작업**: `auto-collect-user-isolation-fix` (100% 완료)

---

## 1. 배경 및 문제 정의

### 1.1 문제 현상

자동수집(SMS/Push) 기능으로 거래가 수집되어 `pending_transactions` 테이블에 정상 저장되지만, **사용자에게 푸시알림이 표시되지 않음**.

### 1.2 사용자 시나리오

- 사용자 A가 KB Pay로 결제 → 금융 Push 알림 수신
- `FinancialNotificationListener`가 백그라운드에서 수집 → Supabase에 저장 ✅
- 사용자 A의 핸드폰에 "자동수집 거래 확인" 알림이 **표시되지 않음** ❌

### 1.3 DB 분석 결과

| 테이블 | 결과 |
|--------|------|
| `pending_transactions` | 자동수집 데이터 정상 저장 ✅ |
| `notification_settings` | 모든 사용자 `auto_collect_*_enabled = true` ✅ |
| `push_notifications` | `auto_collect_suggested/saved` 타입 기록 **없음** ❌ |

---

## 2. 원인 분석

### 2.1 코드 흐름 분석

```
[백그라운드] 금융 Push 알림 수신
        ↓
FinancialNotificationListener.onNotificationPosted()
        ↓
processNotification() - Kotlin 코드
        ↓
supabaseHelper.createPendingTransaction() - Supabase 저장 ✅
        ↓
notifyFlutter(packageName) - Flutter에 이벤트 전달 시도
        ↓
eventSink == null (Flutter 미실행)
        ↓
❌ 사용자 알림 없음
```

### 2.2 근본 원인

**Kotlin 네이티브 코드(`FinancialNotificationListener.kt`)에서 Supabase 저장 후, Android `NotificationManager`를 통한 Local Notification 생성 로직이 없음.**

| 상황 | eventSink | 알림 발송 |
|------|-----------|----------|
| 앱 포그라운드 | 활성 | Flutter `LocalNotificationService` 가능 (이론상) |
| 앱 백그라운드/종료 | **null** | **불가능** |

### 2.3 관련 파일

| 파일 | 역할 | 문제점 |
|------|------|--------|
| `FinancialNotificationListener.kt` | 백그라운드 Push 수집 | Local Notification 미구현 |
| `MainActivity.kt` | Flutter-Kotlin 브릿지 | `eventSink == null`일 때 무시 |
| `NotificationService.dart` | Flutter 알림 발송 | 백그라운드에서 실행 안 됨 |
| `LocalNotificationService.dart` | 로컬 알림 표시 | Flutter 엔진 필요 |

---

## 3. 수정 범위

### 3.1 수정 대상 파일

| 파일 | 변경 내용 |
|------|----------|
| `FinancialNotificationListener.kt` | Android NotificationManager로 Local Notification 생성 |
| `notification_settings` 조회 로직 | Kotlin에서 사용자 알림 설정 확인 |

### 3.2 수정하지 않는 항목

- Flutter `NotificationService`, `LocalNotificationService`: 포그라운드용으로 유지
- DB 스키마: 변경 없음

---

## 4. 상세 수정 계획

### 4.1 [Critical] Kotlin에서 Local Notification 생성

**수정 위치**: `FinancialNotificationListener.kt`

**현재 코드** (`processNotification` 함수 마지막):
```kotlin
if (success) {
    Log.d(TAG, "Notification saved to Supabase, marking SQLite as synced")
    storageHelper.markAsSynced(listOf(sqliteId))
}
notifyFlutter(packageName)
```

**수정 후**:
```kotlin
if (success) {
    Log.d(TAG, "Notification saved to Supabase, marking SQLite as synced")
    storageHelper.markAsSynced(listOf(sqliteId))

    // 사용자 알림 설정 확인 후 Local Notification 생성
    val shouldShowNotification = checkNotificationSetting(userId, settings?.isAutoMode == true)
    if (shouldShowNotification) {
        showAutoCollectNotification(
            isAutoMode = settings?.isAutoMode == true,
            amount = parsed.amount,
            merchant = parsed.merchant
        )
    }
}
notifyFlutter(packageName)
```

### 4.2 [Critical] 알림 설정 조회 함수

**추가 위치**: `SupabaseHelper.kt`

```kotlin
/**
 * 사용자의 자동수집 알림 설정 조회
 */
suspend fun getAutoCollectNotificationSetting(userId: String, isAutoMode: Boolean): Boolean {
    val settingColumn = if (isAutoMode)
        "auto_collect_saved_enabled"
    else
        "auto_collect_suggested_enabled"

    val url = "$baseUrl/rest/v1/notification_settings?select=$settingColumn&user_id=eq.$userId"
    // ... HTTP 요청 및 파싱
    return result ?: true  // 기본값: 알림 활성화
}
```

### 4.3 [Critical] Local Notification 표시 함수

**추가 위치**: `FinancialNotificationListener.kt`

```kotlin
private fun showAutoCollectNotification(
    isAutoMode: Boolean,
    amount: Int?,
    merchant: String?
) {
    val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    // Android 8.0+ 채널 생성
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
        val channel = NotificationChannel(
            "auto_collect_channel",
            "자동수집 알림",
            NotificationManager.IMPORTANCE_DEFAULT
        )
        notificationManager.createNotificationChannel(channel)
    }

    val title = if (isAutoMode) "자동수집 거래 저장" else "자동수집 거래 확인"
    val body = buildString {
        if (amount != null) append("${amount.formatWithComma()}원")
        if (merchant != null) append(" $merchant")
        if (isEmpty()) append("새로운 거래가 수집되었습니다.")
    }

    // 딥링크 Intent (앱 열기 + 대기중/확인됨 탭 이동)
    val intent = Intent(this, MainActivity::class.java).apply {
        flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        putExtra("targetTab", if (isAutoMode) "confirmed" else "pending")
    }
    val pendingIntent = PendingIntent.getActivity(
        this, 0, intent,
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
    )

    val notification = NotificationCompat.Builder(this, "auto_collect_channel")
        .setSmallIcon(R.mipmap.ic_launcher)
        .setContentTitle(title)
        .setContentText(body)
        .setContentIntent(pendingIntent)
        .setAutoCancel(true)
        .build()

    notificationManager.notify(System.currentTimeMillis().toInt(), notification)
}
```

### 4.4 [High] 알림 히스토리 저장

**추가 위치**: `SupabaseHelper.kt`

```kotlin
/**
 * 알림 히스토리 저장 (push_notifications 테이블)
 */
suspend fun savePushNotificationHistory(
    userId: String,
    type: String,  // "auto_collect_suggested" or "auto_collect_saved"
    title: String,
    body: String,
    data: Map<String, Any?>
): Boolean {
    // ... HTTP POST 요청
}
```

---

## 5. 구현 순서

1. `SupabaseHelper.kt` - `getAutoCollectNotificationSetting` 함수 추가
2. `SupabaseHelper.kt` - `savePushNotificationHistory` 함수 추가
3. `FinancialNotificationListener.kt` - `showAutoCollectNotification` 함수 추가
4. `FinancialNotificationListener.kt` - `processNotification`에서 알림 생성 호출
5. Android Manifest - 알림 채널 관련 설정 확인

---

## 6. 테스트 시나리오

### 6.1 알림 표시 테스트

| ID | 시나리오 | 예상 결과 |
|----|----------|----------|
| T-1 | 앱 종료 상태에서 KB Pay 결제 | 상단바에 "자동수집 거래 확인" 알림 |
| T-2 | 앱 백그라운드에서 수원페이 결제 | 상단바에 알림 + Flutter EventChannel |
| T-3 | 앱 포그라운드에서 결제 | 상단바에 알림 + 앱 내 UI 갱신 |

### 6.2 알림 설정 연동 테스트

| ID | 시나리오 | 예상 결과 |
|----|----------|----------|
| T-4 | `auto_collect_suggested_enabled = false` 설정 후 결제 | 알림 표시 안 됨, DB 저장만 |
| T-5 | `auto_collect_saved_enabled = false` 설정 후 자동저장 결제 | 알림 표시 안 됨, DB 저장만 |

### 6.3 딥링크 테스트

| ID | 시나리오 | 예상 결과 |
|----|----------|----------|
| T-6 | suggest 모드 알림 탭 | 앱 열림 → 결제수단 관리 → 대기중 탭 |
| T-7 | auto 모드 알림 탭 | 앱 열림 → 결제수단 관리 → 확인됨 탭 |

---

## 7. 롤백 계획

- Kotlin 파일 수정만 포함 (3개 파일)
- DB 스키마 변경 없음
- Git revert로 즉시 롤백 가능
- 롤백 시 기존 동작 유지 (알림 없음, 수집은 정상)

---

## 8. 성공 기준

- [ ] 백그라운드에서 자동수집 시 Local Notification 표시
- [ ] 알림 설정 (enabled/disabled) 연동
- [ ] `push_notifications` 테이블에 히스토리 저장
- [ ] 알림 탭 시 적절한 화면으로 딥링크
- [ ] 빌드 성공
- [ ] 기존 자동수집 기능 정상 동작

---

**Plan 문서 작성 완료**
작성일: 2026-02-02
