# SMS Auto-Collection Research Learnings

## Android 14+ 백그라운드 SMS 감지 연구 (2026-01-31)

### 핵심 발견사항

1. **Android 14 제약사항**
   - SMS_RECEIVED 브로드캐스트는 기본 SMS 앱만 수신 가능
   - ContentObserver는 앱 프로세스가 살아있을 때만 작동
   - Foreground Service는 타입 선언 필수 (dataSync, remoteMessaging 등)

2. **SmsRetriever API 한계**
   - Google 권장 방식이지만 OTP 전용
   - SMS에 앱 해시 코드 포함 필요 → 금융 거래 SMS에는 부적합
   - 5분 타임아웃 제한

3. **WorkManager 특성**
   - 최소 15분 간격 (실제로는 1시간 권장)
   - Doze 모드에서 지연 가능
   - 배터리 효율적이지만 실시간성 없음

4. **Foreground Service 문제점**
   - 지속적인 알림 필수 (사용자 경험 저하)
   - 배터리 소모 큼
   - Android 14+에서 서비스 타입 제한

### 권장 솔루션

**금융 거래 SMS 자동 수집의 경우:**

**Option A: WorkManager 주기적 스캔 (권장)**
- 1시간 간격으로 SMS ContentProvider 쿼리
- 배터리 효율적, Android 14+ 호환
- 실시간성 포기 가능한 경우 최적

**Option B: 하이브리드 접근**
- 기본: WorkManager 1시간 스캔
- 옵션: 사용자 선택 시 Foreground Service 활성화
- 앱 사용 중일 때만 실시간 모니터링

### 구현 시 주의사항

1. **권한 처리**
   - READ_SMS 권한 필수
   - Android 14+에서 FOREGROUND_SERVICE_DATA_SYNC 권한 필요

2. **배터리 최적화**
   - WorkManager 간격을 너무 짧게 설정하지 말 것
   - Foreground Service는 사용자 동의 하에만 사용

3. **사용자 경험**
   - 실시간 모니터링 시 알림 표시 안내
   - 배터리 소모 경고 제공

### 참고 자료

- [Android 14 Foreground Service Types](https://developer.android.com/about/versions/14/changes/fgs-types-required)
- [WorkManager Guide](https://developer.android.com/develop/background-work/background-tasks/persistent/getting-started)
- [SmsRetriever API](https://developers.google.com/identity/sms-retriever/overview)
- [Stack Overflow: Android 14 Background SMS](https://stackoverflow.com/questions/79521715/how-to-read-sms-via-background-service-in-android-14)

### 결론

**Android 14+에서는 완벽한 백그라운드 실시간 SMS 감지가 불가능합니다.**
배터리 효율과 실시간성 사이의 트레이드오프를 고려하여 WorkManager 주기적 스캔을 권장합니다.

## ContentObserver 백그라운드 동작 연구 (2026-01-31)

### 핵심 발견사항

**ContentObserver는 앱 프로세스 종료 시 작동하지 않음 (확정)**

#### 공식 문서 증거
- ContentObserver는 앱 프로세스 내에서 실행되는 객체
- `ContentResolver.registerContentObserver()`로 등록
- 프로세스 종료 시 모든 객체가 메모리에서 제거됨

#### 시나리오별 동작
| 시나리오 | 작동 여부 | 조건 |
|---------|----------|------|
| 앱 포그라운드 | ✅ YES | 항상 작동 |
| 앱 백그라운드 | ✅ YES | 프로세스 살아있을 때만 |
| 앱 프로세스 종료 | ❌ NO | 절대 작동 안 함 |
| 기기 재부팅 | ❌ NO | 재등록 필요 |

#### Stack Overflow 실제 사례 (2017-2019)
1. "ContentObserver registered in service is killed when app killed"
   - 결론: 프로세스 종속, Foreground Service 필요
2. "Content Observer Detecting Change after Activity Destroyed"
   - START_STICKY Service도 앱 종료 시 함께 종료됨
   - Foreground Service만 유일한 해결책

### SMS 자동 수집을 위한 권장 솔루션

#### 1순위: BroadcastReceiver (가장 권장)
```kotlin
// Manifest
<receiver android:name=".SmsReceiver"
    android:permission="android.permission.BROADCAST_SMS"
    android:exported="true">
    <intent-filter android:priority="999">
        <action android:name="android.provider.Telephony.SMS_RECEIVED" />
    </intent-filter>
</receiver>

// 구현
class SmsReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Telephony.Sms.Intents.SMS_RECEIVED_ACTION) {
            val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent)
            // SMS 처리
        }
    }
}
```

**장점:**
- 시스템 레벨 컴포넌트
- 앱 종료 상태에서도 작동
- 시스템이 앱 프로세스 자동 시작
- 배터리 효율적
- 알림 불필요

#### 2순위: WorkManager + ContentUriTriggers
```kotlin
val constraints = Constraints.Builder()
    .addContentUriTrigger(Telephony.Sms.CONTENT_URI, true)
    .build()

val workRequest = OneTimeWorkRequestBuilder<SmsWorker>()
    .setConstraints(constraints)
    .build()

WorkManager.getInstance(context).enqueue(workRequest)
```

**장점:**
- 시스템 관리 백그라운드 작업
- 앱 종료 후에도 작동
- 배터리 최적화 고려

**단점:**
- 즉각 반응 보장 안 됨 (지연 가능)
- API 24+ 필요

#### 3순위: Foreground Service + ContentObserver
**장점:**
- 가장 확실한 방법
- 실시간 모니터링

**단점:**
- 영구 알림 필수 (사용자 불만)
- Android 14+ Foreground Service Type 필수
- 배터리 소모 증가

### 실제 프로젝트 사례

**Immich (사진 백업 앱)**
- ContentObserver 직접 사용 안 함
- WorkManager ContentUriTriggers 사용
- 앱 종료 후에도 작동

**NekoSMS (SMS 필터 앱)**
- Service에서 ContentObserver 등록
- 앱 실행 중에만 작동
- 백그라운드 지속성 없음

### 결론

**현재 구현 (SmsContentObserver)의 문제점:**
- 앱 프로세스 종료 시 작동 중단
- 사용자가 앱을 스와이프하면 SMS 자동 수집 중단
- 신뢰할 수 없는 백그라운드 동작

**권장 변경사항:**
1. BroadcastReceiver로 전환 (가장 권장)
2. 또는 WorkManager ContentUriTriggers 사용
3. Foreground Service는 최후의 수단

### 참고 자료
- [ContentObserver API Reference](https://developer.android.com/reference/android/database/ContentObserver)
- [Stack Overflow - ContentObserver killed when app killed](https://stackoverflow.com/questions/41920447)
- [Immich ContentObserverWorker](https://github.com/immich-app/immich/blob/main/mobile/android/app/src/main/kotlin/app/alextran/immich/ContentObserverWorker.kt)
