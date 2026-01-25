# 푸시 알림 자동수집 문제 해결 가이드

## 문제 상황

실제 KB Pay, 경기지역화폐 앱의 푸시 알림이 자동수집에서 감지되지 않고, 대기 중 리스트에도 표시되지 않는 문제

## 원인 분석

### 1. 패키지명 필터링

`notification_listener_wrapper.dart`의 `_financialAppPackagesLower`에 해당 앱의 패키지명이 등록되어 있지 않으면 알림이 필터링됩니다.

```dart
// 소문자로 사전 변환하여 비교 최적화
static final Set<String> _financialAppPackagesLower = {
  'com.kbcard.cxh.appcard',  // KB국민카드 앱
  'com.kbpay',               // KB Pay (추가됨)
  // ...
};
```

### 2. 금융사 패턴 인식

알림 필터링 로직:

```dart
final isFinancial = _isFinancialApp(packageName);  // 패키지명 체크
final isFinancialSender = FinancialSmsSenders.isFinancialSender(title, content);  // 내용 체크

if (!isFinancial && !isFinancialSender) {
  return;  // 두 조건 모두 실패하면 무시됨
}
```

**KB Pay 문제:**
- 제목: 'KB Pay'
- 기존 패턴: 'KB국민카드', 'KB카드', '국민카드'
- 'KB Pay'는 별도 패턴으로 인식되지 않음

**경기지역화폐 문제:**
- 제목: '경기지역화폐'
- 패턴에는 '수원페이', '경기지역화폐'가 있지만
- 앱 패키지명이 `_financialAppPackagesLower`에 없으면 필터링됨

### 3. 자동수집 소스 설정

결제수단 설정에서 `autoCollectSource`가 올바르게 설정되어 있어야 합니다:

```dart
// Push 소스로 설정된 결제수단만 매칭
if (pm.autoCollectSource != AutoCollectSource.push) {
  continue;  // SMS로 설정된 결제수단은 무시
}
```

## 해결 방법

### 1단계: 실제 패키지명 확인

```bash
# 연결된 기기 확인
adb devices

# 금융 앱 패키지 확인
./scripts/check_device_packages.sh [기기ID]

# 또는 직접 확인
adb -s R3CT90TAG8Z shell pm list packages | grep -i kb
adb -s R3CT90TAG8Z shell pm list packages | grep -E 'ggc|suwon|gyeonggi'
```

### 2단계: 패키지명 추가

`notification_listener_wrapper.dart` 파일 수정:

```dart
static final Set<String> _financialAppPackagesLower = {
  // 기존 코드...
  'com.kbpay',              // KB Pay (확인된 패키지명으로 교체)
  'kr.or.ggc',              // 경기지역화폐 (확인된 패키지명으로 교체)
  'kr.suwon.pay',           // 수원페이 (확인된 패키지명으로 교체)
};
```

### 3단계: 금융사 패턴 추가

`sms_parsing_service.dart` 파일의 `senderPatterns` 수정:

```dart
static const Map<String, List<String>> senderPatterns = {
  'KB Pay': ['KB Pay', 'KBPay', 'KB페이'],  // 이미 추가됨
  // ...
};
```

### 4단계: 결제수단 설정 확인

앱에서 결제수단 관리 페이지로 이동:
1. KB Pay 결제수단 선택
2. 자동수집 소스: **Push**로 설정
3. 자동수집 모드: **제안** 또는 **자동**으로 설정

### 5단계: 권한 확인

1. 앱 설정 -> 알림 액세스 권한 확인
2. 핸드폰 설정 -> 알림 -> 알림 액세스 -> [앱 이름] 활성화

### 6단계: 로그 확인

실제 알림 수신 시 로그 확인:

```bash
# 실시간 로그 모니터링
adb -s R3CT90TAG8Z logcat | grep -E 'NotificationListener|AutoSave'

# 또는 특정 필터
adb -s R3CT90TAG8Z logcat *:S NotificationListener:D
```

## 시뮬레이션 테스트

### 에뮬레이터 테스트

```bash
# KB Pay
./scripts/simulate_kbpay.sh 65000 시크릿모 1004

# 경기지역화폐
./scripts/simulate_suwonpay.sh push 2650 파리바게뜨
```

### 실물 핸드폰 테스트

```bash
# KB Pay (R3CT90TAG8Z 기기)
./scripts/simulate_push_to_device.sh kbpay 65000 시크릿모 R3CT90TAG8Z

# 경기지역화폐
./scripts/simulate_push_to_device.sh suwonpay 2650 파리바게뜨 R3CT90TAG8Z
```

**주의:** `cmd notification post`로 보낸 시스템 테스트 알림은 실제 앱 패키지명으로 전송되지 않습니다. 따라서 NotificationListener가 감지하지 못할 수 있습니다.

## 디버깅 체크리스트

- [ ] 알림 액세스 권한이 활성화되어 있는가?
- [ ] 실제 앱의 패키지명을 확인했는가?
- [ ] `_financialAppPackagesLower`에 패키지명을 추가했는가?
- [ ] `FinancialSmsSenders.senderPatterns`에 발신자 패턴을 추가했는가?
- [ ] 결제수단 설정에서 자동수집 소스가 'Push'로 설정되어 있는가?
- [ ] 결제수단 설정에서 자동수집 모드가 'manual'이 아닌가?
- [ ] 앱을 재시작했는가? (코드 변경 후 필수)
- [ ] 로그에서 알림 수신이 확인되는가?

## 실제 알림 vs 시뮬레이션 차이

### 실제 알림
- 앱의 실제 패키지명으로 전송됨 (예: `com.kbpay.android`)
- NotificationListenerService가 감지 가능
- 앱 아이콘, 색상 등 완전한 알림 스타일 적용

### 시뮬레이션 알림
- `cmd notification post`는 시스템 테스트 알림
- 패키지명이 `com.android.shell` 또는 비어있음
- 디버그 모드에서만 일부 감지 가능하도록 설정됨

## 추가 확인 사항

### 1. 학습된 SMS 포맷 확인

대기 중 리스트에 표시되려면:
1. 알림이 감지되어야 함
2. 파싱이 성공해야 함 (금액, 타입 추출)
3. pending_transaction에 저장되어야 함

### 2. 결제수단 매칭 확인

로그에서 다음을 확인:

```
[NotificationListener] Processing: com.kbpay.android
[NotificationListener] Auto-save PM count: 1
  - KB Pay (mode: suggest, source: push)
[Matching] Searching for payment method match...
[Matching] Matched by payment method name!
```

### 3. 파싱 결과 확인

```
Notification matched: mode=suggest, pm=KB Pay
ParsedSmsResult(amount: 65000, type: expense, merchant: 시크릿모, confidence: 0.9)
```

## 참고 파일

- `lib/features/payment_method/data/services/notification_listener_wrapper.dart`: 알림 수신 및 필터링
- `lib/features/payment_method/data/services/sms_parsing_service.dart`: 파싱 패턴 정의
- `scripts/simulate_kbpay.sh`: KB Pay 시뮬레이션
- `scripts/simulate_suwonpay.sh`: 경기지역화폐 시뮬레이션
- `scripts/simulate_push_to_device.sh`: 실물 기기 시뮬레이션
- `scripts/check_device_packages.sh`: 패키지명 확인 도구
