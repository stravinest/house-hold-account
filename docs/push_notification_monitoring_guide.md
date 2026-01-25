# 푸시 알림 패키지명 확인 가이드

## 📋 개요

실제 KB Pay, 경기지역화폐 앱의 푸시 알림이 자동수집에서 감지되지 않는 문제를 해결하기 위해, 실제 앱의 패키지명을 확인하고 코드에 추가하는 방법을 안내합니다.

## 🔍 확인된 금융 앱 패키지명

### 실제 기기(R3CT90TAG8Z)에서 확인된 패키지

```bash
# 확인 명령어
adb -s R3CT90TAG8Z shell pm list packages | grep -E 'kb|pay|ggc|gyeonggi'
```

**확인된 금융 앱:**
- ✅ `gov.gyeonggi.ggcard` - **경기지역화폐 공식 앱**
- ✅ `com.kbcard.cxh.appcard` - KB국민카드
- ✅ `com.kbstar.kbbank` - KB국민은행
- ✅ `com.kakaopay.app` - 카카오페이
- ✅ `com.naverfin.payapp` - 네이버페이
- ✅ `com.komsco.kpay` - K-Pay
- ✅ `com.samsung.android.spay` - 삼성페이

**KB Pay 관련 참고사항:**
KB Pay는 별도 앱이 아니라 KB국민카드 앱(`com.kbcard.cxh.appcard`) 내의 기능으로, 해당 패키지명으로 알림이 발송됩니다.

## 🚀 실시간 로그 모니터링 방법

### 사전 준비

1. **기기 연결 확인**
   ```bash
   adb devices -l
   ```

   출력 예시:
   ```
   R3CT90TAG8Z    device usb:1-1 product:b0qksx model:SM_S908N device:b0q
   ```

2. **앱 설치 확인**
   ```bash
   adb -s R3CT90TAG8Z shell pm list packages | grep 'com.household.shared'
   ```

   출력:
   ```
   package:com.household.shared.shared_household_account
   ```

3. **알림 액세스 권한 확인**
   - 핸드폰: 설정 → 알림 → 알림 액세스
   - `공유 가계부` 앱 활성화 확인

### 방법 1: 자동 스크립트 사용 (권장 ⭐)

전체 과정을 가이드하는 자동화 스크립트:

```bash
./scripts/setup_notification_monitoring.sh R3CT90TAG8Z
```

**스크립트 기능:**
- 기기 연결 확인
- 앱 설치 확인
- 금융 앱 패키지 검색
- 실시간 로그 모니터링

### 방법 2: 빠른 모니터링

로그만 빠르게 확인하고 싶을 때:

```bash
./scripts/quick_monitor.sh
```

**특징:**
- R3CT90TAG8Z 기기 전용
- NotificationListener 로그만 필터링
- 이모지로 중요 정보 강조

### 방법 3: 수동 로그 확인

직접 adb 명령으로 확인:

```bash
# 로그 초기화 (선택사항)
adb -s R3CT90TAG8Z logcat -c

# 실시간 로그 모니터링
adb -s R3CT90TAG8Z logcat | grep NotificationListener
```

**상세 필터링:**
```bash
# NotificationListener 태그만
adb -s R3CT90TAG8Z logcat *:S NotificationListener:D

# 또는 여러 태그 동시에
adb -s R3CT90TAG8Z logcat | grep -E 'NotificationListener|AutoSave|PendingTransaction'
```

## 📱 테스트 절차

### 1단계: 앱 재빌드

코드 변경사항을 적용하기 위해 앱을 재빌드합니다:

```bash
# 실물 기기에 설치
flutter run -d R3CT90TAG8Z

# 또는 릴리즈 모드
flutter run -d R3CT90TAG8Z --release
```

**주의:** 디버그 모드에서만 상세 로그가 출력됩니다. 릴리즈 모드에서는 로그가 제한됩니다.

### 2단계: 로그 모니터링 시작

**새 터미널 창을 열고** 모니터링 스크립트를 실행:

```bash
./scripts/quick_monitor.sh
```

다음과 같은 화면이 표시됩니다:

```
================================================
푸시 알림 로그 모니터링
================================================
기기: R3CT90TAG8Z

지금 KB Pay나 경기지역화폐로 결제하세요!
알림이 오면 패키지명이 출력됩니다.

중단: Ctrl+C
================================================

로그 대기 중...
```

### 3단계: 실제 결제 진행

핸드폰에서 다음 중 하나를 진행:

#### 옵션 A: 경기지역화폐 결제
1. 경기지역화폐 앱(`gov.gyeonggi.ggcard`) 실행
2. 수원페이/용인페이 등으로 소액 결제 (1,000~2,000원)
3. 결제 완료 후 푸시 알림 확인

#### 옵션 B: KB카드 결제
1. KB국민카드 앱(`com.kbcard.cxh.appcard`) 실행
2. KB Pay 기능으로 결제
3. 결제 완료 후 푸시 알림 확인

### 4단계: 로그 확인

알림이 오면 터미널에 다음과 같이 출력됩니다:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔍   - 패키지명: gov.gyeonggi.ggcard
📌   - 제목: 경기지역화폐
  - 내용 미리보기: 결제 완료 2,650원...
  - 삭제됨: false
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[NotificationListener] isFinancialApp: true, isFinancialSender: true
[Matching] Searching for payment method match...
[Matching] Matched by payment method name!
[NotificationListener] Found match: 수원페이
[CreatePending] Creating pending transaction:
  - ledgerId: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
  - paymentMethodId: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
  - shouldAutoSave: false
  - isDuplicate: false
[CreatePending] Success! ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

## 📊 로그 분석

### 성공 시나리오

#### 1. 알림 감지됨
```
[NotificationListener] 알림 수신:
  - 패키지명: gov.gyeonggi.ggcard  ✅ 확인됨!
  - 제목: 경기지역화폐
```

#### 2. 금융 앱으로 인식됨
```
[NotificationListener] isFinancialApp: true ✅
[NotificationListener] isFinancialSender: true ✅
```

#### 3. 결제수단 매칭 성공
```
[Matching] Matched by payment method name!
[NotificationListener] Found match: 수원페이  ✅
```

#### 4. 대기 중 거래 생성됨
```
[CreatePending] Success! ID: xxx... ✅
```

### 실패 시나리오

#### 패키지명 미등록
```
[NotificationListener] 알림 수신:
  - 패키지명: com.unknown.app  ❌
[NotificationListener] isFinancialApp: false  ❌
[NotificationListener] isFinancialSender: false  ❌
[NotificationListener] Skipping non-financial: com.unknown.app
```

**해결:** `notification_listener_wrapper.dart`의 `_financialAppPackagesLower`에 패키지명 추가

#### 결제수단 미등록
```
[NotificationListener] Processing: gov.gyeonggi.ggcard
[NotificationListener] Auto-save PM count: 0  ❌
[NotificationListener] No matching payment method found
```

**해결:** 앱에서 결제수단 추가 및 자동수집 설정

#### 자동수집 소스 불일치
```
[Matching] Checking PM: 수원페이, source: sms  ❌
[Matching] Skipped - source is not push
```

**해결:** 결제수단 설정에서 자동수집 소스를 'Push'로 변경

## 🛠 문제 해결

### 로그가 전혀 출력되지 않는 경우

**원인 1: 알림 액세스 권한 없음**
```bash
# 권한 확인
adb -s R3CT90TAG8Z shell dumpsys notification_listener
```

해결: 핸드폰 설정 → 알림 → 알림 액세스 → 앱 활성화

**원인 2: NotificationListener 서비스 미실행**

로그 확인:
```bash
adb -s R3CT90TAG8Z logcat | grep "Notification listener"
```

예상 출력:
```
Notification listener started  ✅
```

해결: 앱 재시작 또는 재설치

### 패키지명은 보이는데 감지되지 않는 경우

**1단계: 패키지명 확인**
```
[NotificationListener] 알림 수신:
  - 패키지명: com.new.financial.app  👈 이 값 확인!
```

**2단계: 코드에 추가**

`lib/features/payment_method/data/services/notification_listener_wrapper.dart` 수정:

```dart
static final Set<String> _financialAppPackagesLower = {
  // 기존 코드...
  'com.new.financial.app',  // 👈 확인된 패키지명 추가
};
```

**3단계: 앱 재빌드**
```bash
flutter run -d R3CT90TAG8Z
```

### 중복 알림 문제

10초 이내 동일한 알림이 여러 번 오는 경우 중복 방지 로직이 작동합니다:

```
Duplicate notification detected (cached 3s ago) - ignoring
```

이는 정상 동작입니다.

## 📝 유용한 스크립트 정리

### 금융 앱 패키지 검색
```bash
./scripts/find_financial_packages.sh R3CT90TAG8Z
```

### 실시간 알림 모니터링
```bash
./scripts/monitor_notifications.sh R3CT90TAG8Z
```

### 빠른 모니터링 (R3CT90TAG8Z 전용)
```bash
./scripts/quick_monitor.sh
```

### 전체 설정 가이드
```bash
./scripts/setup_notification_monitoring.sh R3CT90TAG8Z
```

### 패키지명 확인
```bash
./scripts/check_device_packages.sh R3CT90TAG8Z
```

## 🎯 체크리스트

알림 자동수집이 작동하려면 다음 조건이 모두 충족되어야 합니다:

- [ ] 기기가 ADB로 연결되어 있음
- [ ] 앱이 설치되어 있음
- [ ] 알림 액세스 권한이 허용되어 있음
- [ ] 금융 앱의 패키지명이 `_financialAppPackagesLower`에 등록됨
- [ ] 결제수단이 앱에 등록되어 있음
- [ ] 결제수단의 자동수집 소스가 'Push'로 설정됨
- [ ] 결제수단의 자동수집 모드가 'manual'이 아님 (suggest 또는 auto)
- [ ] 실제 결제 후 푸시 알림이 발송됨

## 📚 참고 파일

### 코드 파일
- `lib/features/payment_method/data/services/notification_listener_wrapper.dart`
  - 알림 수신 및 필터링 로직
  - `_financialAppPackagesLower`: 패키지명 등록

- `lib/features/payment_method/data/services/sms_parsing_service.dart`
  - SMS/알림 파싱 로직
  - `FinancialSmsSenders.senderPatterns`: 발신자 패턴

### 스크립트 파일
- `scripts/setup_notification_monitoring.sh` - 전체 설정 가이드
- `scripts/monitor_notifications.sh` - 실시간 모니터링
- `scripts/quick_monitor.sh` - 빠른 모니터링 (R3CT90TAG8Z 전용)
- `scripts/find_financial_packages.sh` - 금융 앱 검색
- `scripts/check_device_packages.sh` - 패키지 확인

### 문서 파일
- `docs/notification_troubleshooting.md` - 상세 문제 해결 가이드
- `docs/push_notification_monitoring_guide.md` - 이 문서

## 🔧 다음 단계

1. **실제 패키지명 확인**
   ```bash
   ./scripts/quick_monitor.sh
   ```

2. **실제 결제로 테스트**
   - 경기지역화폐 또는 KB Pay로 소액 결제
   - 로그에서 패키지명 확인

3. **코드 업데이트**
   - 새로운 패키지명이 발견되면 코드에 추가
   - 앱 재빌드

4. **자동수집 확인**
   - 결제 후 앱의 대기 중 리스트 확인
   - 알림이 정상적으로 파싱되는지 확인

5. **문서 업데이트**
   - 새로운 패키지명을 이 문서에 추가
   - 팀원들과 공유

## 💡 팁

### 로그 저장하기
```bash
adb -s R3CT90TAG8Z logcat | grep NotificationListener > notification_logs.txt
```

### 특정 시간대 로그만 보기
```bash
adb -s R3CT90TAG8Z logcat -t '01-25 14:30:00.000' | grep NotificationListener
```

### 여러 기기 동시 모니터링
```bash
# 터미널 1
adb -s R3CT90TAG8Z logcat | grep NotificationListener

# 터미널 2
adb -s emulator-5554 logcat | grep NotificationListener
```

## ❓ FAQ

### Q1: 로그에 아무것도 출력되지 않아요
**A:** 앱이 디버그 모드로 실행되고 있는지 확인하세요. 릴리즈 모드에서는 로그가 제한됩니다.

### Q2: 패키지명은 보이는데 'Skipping non-financial'이라고 나와요
**A:** 해당 패키지명을 `_financialAppPackagesLower`에 추가하고 앱을 재빌드하세요.

### Q3: 알림은 감지되는데 대기 중 리스트에 안 떠요
**A:**
- 파싱 실패: 로그에서 `ParsedSmsResult` 확인
- 결제수단 미매칭: 로그에서 `No matching payment method` 확인
- 자동수집 소스 불일치: 결제수단 설정에서 소스를 'Push'로 변경

### Q4: KB Pay 알림이 안 잡혀요
**A:** KB Pay는 KB국민카드 앱(`com.kbcard.cxh.appcard`)의 기능입니다. 해당 패키지명으로 알림이 오는지 확인하세요.

## 📞 지원

문제가 지속되면 다음 정보를 포함하여 이슈를 등록하세요:

1. 기기 모델 및 Android 버전
2. 앱 버전
3. 로그 출력 전문 (`notification_logs.txt`)
4. 시도한 해결 방법
5. 스크린샷

---

**마지막 업데이트:** 2026-01-25
**테스트 기기:** R3CT90TAG8Z (Samsung SM_S908N)
**확인된 앱:** gov.gyeonggi.ggcard, com.kbcard.cxh.appcard
