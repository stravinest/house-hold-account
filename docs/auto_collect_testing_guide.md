# 자동수집 테스트 및 디버깅 가이드

SMS/Push 자동수집 기능의 테스트 및 디버깅을 위한 종합 가이드입니다.

## 목차

1. [네 가지 수집 모드](#1-네-가지-수집-모드)
2. [테스트 환경 구성](#2-테스트-환경-구성)
3. [에뮬레이터 SMS 테스트](#3-에뮬레이터-sms-테스트)
4. [에뮬레이터 Push 테스트](#4-에뮬레이터-push-테스트)
5. [앱 내 디버그 테스트](#5-앱-내-디버그-테스트)
6. [로그 모니터링](#6-로그-모니터링)
7. [실제 기기 테스트](#7-실제-기기-테스트)
8. [문제 해결](#8-문제-해결)

---

## 1. 네 가지 수집 모드

결제수단별로 수집 소스(`auto_collect_source`)와 저장 모드(`auto_save_mode`)를 설정할 수 있습니다.

### DB 컬럼

| 컬럼 | 값 | 설명 |
|------|-----|------|
| `auto_collect_source` | `'sms'` | SMS로 수집 |
| `auto_collect_source` | `'push'` | Push 알림으로 수집 |
| `auto_save_mode` | `'suggest'` | 제안 모드 (사용자 확인 필요) |
| `auto_save_mode` | `'auto'` | 자동 모드 (바로 거래로 저장) |

### 네 가지 조합

| 모드 | auto_collect_source | auto_save_mode | 동작 |
|------|---------------------|----------------|------|
| 문자 + 제안 | `sms` | `suggest` | SMS 수집 → `pending_transactions` (status='pending') |
| 문자 + 자동 | `sms` | `auto` | SMS 수집 → `pending_transactions` (status='confirmed') + `transactions` |
| 푸쉬 + 제안 | `push` | `suggest` | Push 수집 → `pending_transactions` (status='pending') |
| 푸쉬 + 자동 | `push` | `auto` | Push 수집 → `pending_transactions` (status='confirmed') + `transactions` |

### 수집 분리 동작

- **SMS 수신 시**: `auto_collect_source = 'sms'`인 결제수단만 처리, `'push'`이면 스킵
- **Push 수신 시**: `auto_collect_source = 'push'`인 결제수단만 처리, `'sms'`이면 스킵

### 결제수단 설정 변경 (SQL)

```sql
-- SMS + 제안 모드로 설정
UPDATE house.payment_methods 
SET auto_collect_source = 'sms', auto_save_mode = 'suggest'
WHERE id = '<payment_method_id>';

-- Push + 자동 모드로 설정
UPDATE house.payment_methods 
SET auto_collect_source = 'push', auto_save_mode = 'auto'
WHERE id = '<payment_method_id>';
```

---

## 2. 테스트 환경 구성

### 필수 조건

- Android 에뮬레이터 또는 실제 기기 (USB 디버깅 활성화)
- Flutter 디버그 빌드
- ADB 설치 (Android Studio 포함)
- Supabase 연결 (앱에서 로그인 완료)

### 에뮬레이터 설정

```bash
# 에뮬레이터 시작 (AVD Manager에서 생성 후)
emulator -avd <avd_name>

# 연결 확인
adb devices
```

### 실제 기기 설정

1. 핸드폰 설정 → 개발자 옵션 활성화
2. USB 디버깅 활성화
3. USB 케이블로 연결
4. "USB 디버깅 허용" 팝업 승인

---

## 3. 에뮬레이터 SMS 테스트

에뮬레이터에서는 **telnet을 통해 실제 SMS 수신**을 시뮬레이션할 수 있습니다.
이 방법은 `SmsBroadcastReceiver`를 실제로 트리거합니다.

### 통합 테스트 스크립트

```bash
# 사용 가능한 템플릿 확인
./scripts/test_financial_sms.sh --help

# KB국민카드 SMS 전송
./scripts/test_financial_sms.sh kb

# 금액/가맹점 지정
./scripts/test_financial_sms.sh -a 50000 -m 스타벅스 kb

# 모든 템플릿 순차 테스트 (3초 간격)
./scripts/test_financial_sms.sh all

# 딜레이 조정
./scripts/test_financial_sms.sh -d 5 all
```

### 지원 템플릿

| 템플릿 | 설명 |
|--------|------|
| `kb` | KB국민카드 승인 |
| `shinhan` | 신한카드 승인 |
| `samsung` | 삼성카드 승인 |
| `hyundai` | 현대카드 승인 |
| `lotte` | 롯데카드 승인 |
| `woori` | 우리카드 승인 |
| `hana` | 하나카드 승인 |
| `kakao` | 카카오페이 결제 |
| `naver` | 네이버페이 결제 |
| `toss` | 토스 입금 |
| `income` | 입금 알림 |

### 예상 결과

1. 에뮬레이터 메시지 앱에 SMS 표시
2. `SmsContentObserver` 트리거
3. 결제수단 설정 확인 (`auto_collect_source = 'sms'`인지)
4. `auto_save_mode`에 따라:
   - `suggest`: `pending_transactions` (status='pending')에 저장
   - `auto`: `pending_transactions` (status='confirmed') + `transactions`에 저장

### 로그 확인

```bash
# SMS 수집 로그 모니터링
adb logcat | grep -E "(FinancialSmsObserver|Auto mode|Suggest mode|SMS mode|push mode)"
```

**예상 로그 (SMS + 제안 모드)**:
```
FinancialSmsObserver: Processing SMS: [KB국민카드] ...
FinancialSmsObserver: Found matching payment method: KB국민카드
FinancialSmsObserver: Suggest mode, creating pending transaction
```

**예상 로그 (SMS + 자동 모드)**:
```
FinancialSmsObserver: Processing SMS: [KB국민카드] ...
FinancialSmsObserver: Auto mode enabled for payment method: ..., creating confirmed transaction
```

**예상 로그 (Push 모드로 설정된 경우)**:
```
FinancialSmsObserver: Payment method is set to push mode, skipping SMS collection
```

---

## 4. 에뮬레이터 Push 테스트

Push 알림을 ADB를 통해 시뮬레이션할 수 있습니다.

### 필수 조건

- **DEBUG 빌드 필수**: Release 빌드에서는 `com.android.shell` 패키지가 금융 앱 목록에 없음
- **알림 리스너 권한**: 설정 > 알림 > 알림 접근 > 앱 활성화

### 통합 테스트 스크립트

```bash
# KB Pay 형식 Push 전송
./scripts/simulate_kbpay.sh 50000 '스타벅스'

# 금액/가맹점/카드번호 지정
./scripts/simulate_kbpay.sh 65000 '시크릿모' 1004

# 기본 Push 시뮬레이션
./scripts/simulate_push.sh "KB국민카드" "승인 홍*동 50,000원 일시불 스타벅스 01/21 14:30"
```

### 수동 Push 전송

```bash
# ADB 명령으로 직접 Push 전송
adb shell "cmd notification post -t 'KB Pay' 'test_tag' 'KB국민카드1004승인 전*규님 50,000원 일시불 01/30 14:30 스타벅스 누적500,000원'"
```

### 사전 설정 (Push 모드로 변경)

```sql
-- 결제수단을 Push 모드로 설정
UPDATE house.payment_methods 
SET auto_collect_source = 'push', auto_save_mode = 'suggest'
WHERE id = '<payment_method_id>';
```

### 로그 확인

```bash
# Push 수집 로그 모니터링
adb logcat | grep -E "(FinancialPushListener|Auto mode|Suggest mode|SMS mode|push mode)"
```

**예상 로그 (Push + 제안 모드)**:
```
FinancialPushListener: Financial notification received from: com.android.shell
FinancialPushListener: Suggest mode for payment method: ..., creating pending transaction
```

**예상 로그 (Push + 자동 모드)**:
```
FinancialPushListener: Financial notification received from: com.android.shell
FinancialPushListener: Auto mode enabled for payment method: ..., creating confirmed transaction
```

**예상 로그 (SMS 모드로 설정된 경우)**:
```
FinancialPushListener: Payment method is set to SMS mode, skipping push notification collection
```

### 지원 스크립트

| 스크립트 | 용도 |
|---------|------|
| `scripts/simulate_push.sh` | 기본 Push 시뮬레이션 |
| `scripts/simulate_kbpay.sh` | KB Pay 형식 Push |
| `scripts/simulate_suwonpay.sh` | 수원페이 형식 Push |
| `scripts/simulate_push_to_device.sh` | 실제 디바이스용 |

---

## 5. 앱 내 디버그 테스트

**디버그 빌드에서만 사용 가능합니다.**

### 접근 방법

설정 → 개발자 옵션 → 자동수집 디버그

### 기능

#### 상태 탭
- SQLite 대기/실패 건수
- Supabase 연결 상태
- NotificationListener 상태
- 토큰 유효성

#### SMS 탭
- 템플릿 선택 (KB, 신한, 현대, 카카오페이 등)
- 금액/가맹점 입력
- 전송 버튼 → Kotlin에서 직접 처리
- 미리보기 확인

#### Push 탭
- 템플릿 선택 (KB Pay, 경기지역화폐, 카카오페이 등)
- 금액/가맹점 입력
- 전송 버튼 → Kotlin에서 직접 처리

#### 파싱 탭
- 임의의 메시지 내용 입력
- 파싱 테스트 실행
- 결과 확인 (금액, 유형, 가맹점, 신뢰도)

### 앱 내 테스트 장점

| 장점 | 설명 |
|------|------|
| 실제 파이프라인 | Kotlin 파싱 → Supabase 저장 전체 흐름 |
| ADB 제한 우회 | 실제 기기에서도 테스트 가능 |
| 즉시 확인 | UI에서 결과 즉시 확인 |

---

## 6. 로그 모니터링

### 통합 모니터링 스크립트

```bash
# 모든 자동수집 로그
./scripts/monitor_auto_collect.sh

# SMS 관련 로그만
./scripts/monitor_auto_collect.sh -s

# Push 관련 로그만
./scripts/monitor_auto_collect.sh -p

# DB 저장 관련 로그만
./scripts/monitor_auto_collect.sh -d

# 에러만
./scripts/monitor_auto_collect.sh -e

# 테스트 채널 로그만
./scripts/monitor_auto_collect.sh -t

# 특정 기기 지정
./scripts/monitor_auto_collect.sh R3CT90TAG8Z
./scripts/monitor_auto_collect.sh -s R3CT90TAG8Z
```

### 로그 색상 가이드

| 색상 | 의미 |
|------|------|
| 청록 `[SMS]` | SMS 수신/처리 |
| 파랑 `[PUSH]` | Push 알림 수신/처리 |
| 노랑 `[SQLITE]` | SQLite 저장 |
| 초록 `[DB]` | Supabase 저장 성공 |
| 흰색 `[PARSE]` | 파싱 결과 |
| 보라 `[TEST]` | 테스트 채널 |
| 빨강 `[ERROR]` | 에러 |

### 직접 로그 확인

```bash
# 전체 로그 (필터 없음)
adb logcat

# 자동수집 관련 태그만
adb logcat -s FinancialSmsReceiver:D FinancialPushListener:D SupabaseHelper:D NotificationStorage:D

# 특정 기기
adb -s <device_id> logcat | grep -E "Sms|Push|Supabase"
```

---

## 7. 실제 기기 테스트

### ADB의 한계

| 방법 | SMS | Push | 비고 |
|------|-----|------|------|
| 에뮬레이터 telnet | ✅ 실제 수신 트리거 | ❌ 불가 | SMS 테스트에 권장 |
| `content insert` | ❌ DB만 삽입 | - | ContentObserver 미트리거 |
| `cmd notification post` | - | ✅ DEBUG 빌드에서만 | `com.android.shell` 패키지 사용 |
| 앱 내 디버그 | ✅ 전체 파이프라인 | ✅ 전체 파이프라인 | 실제 기기에서 권장 |

> **참고**: `cmd notification post`는 DEBUG 빌드에서만 동작합니다. Release 빌드에서는 `com.android.shell` 패키지가 금융 앱 목록에 포함되지 않습니다.

### 권장 테스트 방법

#### 1. 앱 내 디버그 (가장 쉬움)
```
설정 → 개발자 옵션 → 자동수집 디버그
```

#### 2. 실제 결제 (가장 정확함)
- 소액 결제 진행
- 실제 SMS/Push 수신 확인

#### 3. 다른 폰에서 SMS 전송
- 금융 SMS 형식으로 직접 발송
- `[Web발신] KB국민카드 1234승인...`

### 권한 확인

```bash
# 알림 리스너 권한 확인
adb -s <device_id> shell dumpsys notification | grep -A5 "NotificationListenerService"

# SMS 권한 확인
adb -s <device_id> shell dumpsys package com.household.shared.shared_household_account | grep permission
```

---

## 8. 문제 해결

### SMS가 감지되지 않음

1. **권한 확인**
   ```bash
   adb shell pm grant com.household.shared.shared_household_account android.permission.RECEIVE_SMS
   ```

2. **앱 재시작**
   - BroadcastReceiver 재등록

3. **금융 키워드 확인**
   - 발신자가 금융 발신자 목록에 있는지
   - 내용에 "원", "승인", "결제" 등 키워드가 있는지

### Push가 감지되지 않음

1. **알림 액세스 권한**
   ```
   설정 → 알림 → 알림 액세스 → 앱 활성화
   ```

2. **패키지명 확인**
   ```bash
   adb shell pm list packages | grep -i <앱이름>
   ```
   - 패키지명이 `FinancialNotificationListener.FINANCIAL_APP_PACKAGES`에 있는지

3. **NotificationListener 상태**
   - 앱 내 디버그 → 상태 탭에서 확인

### Supabase 저장 실패

1. **토큰 확인**
   - 앱 내 디버그 → 상태 탭 → 토큰 유효 여부

2. **가계부 ID 확인**
   - 앱에서 가계부가 선택되어 있는지

3. **네트워크 확인**
   - Supabase API 연결 상태

### 파싱 실패

1. **파싱 테스트**
   - 앱 내 디버그 → 파싱 탭에서 직접 테스트

2. **정규식 패턴**
   - `FinancialMessageParser.kt` 확인
   - 금액 패턴: `([0-9,]+)\s*원`

---

## 참고 파일

### Kotlin (Android)
- `SmsContentObserver.kt` - SMS 수신 (ContentObserver 기반)
- `FinancialNotificationListener.kt` - Push 수신 (NotificationListenerService)
- `FinancialMessageParser.kt` - 메시지 파싱
- `SupabaseHelper.kt` - Supabase 통신 (`getPaymentMethodAutoSettings`, `createConfirmedTransaction`)
- `NotificationStorageHelper.kt` - SQLite 저장
- `MainActivity.kt` - Flutter 채널 및 테스트 메서드
- `SmsObserverForegroundService.kt` - SMS Observer 백그라운드 동작 보장

### Flutter
- `debug_test_service.dart` - 디버그 테스트 서비스
- `debug_test_page.dart` - 디버그 UI
- `notification_listener_wrapper.dart` - Push 처리 래퍼

### 스크립트
- `scripts/test_financial_sms.sh` - SMS 통합 테스트
- `scripts/monitor_auto_collect.sh` - 로그 모니터링
- `scripts/simulate_kbpay.sh` - KB Pay Push 시뮬레이션
- `scripts/simulate_push.sh` - 기본 Push 시뮬레이션
- `scripts/simulate_push_to_device.sh` - 실제 디바이스용 Push 시뮬레이션

---

## 빠른 테스트 체크리스트

### SMS 테스트 (문자 수집)

```bash
# 1. 에뮬레이터 시작 확인
adb devices

# 2. 결제수단이 SMS 모드인지 확인 (Supabase)
# auto_collect_source = 'sms' 확인

# 3. 로그 모니터링 시작 (새 터미널)
adb logcat | grep -E "(FinancialSmsObserver|Auto mode|Suggest mode)"

# 4. 앱 실행 (디버그 빌드)
flutter run

# 5. 앱에서 로그인 → 가계부 선택

# 6. SMS 테스트 전송
./scripts/test_financial_sms.sh -a 50000 -m 스타벅스 kb

# 7. 로그에서 결과 확인
# - "Suggest mode, creating pending transaction" 또는
# - "Auto mode enabled..., creating confirmed transaction"

# 8. Supabase 확인
# - pending_transactions 테이블 (status='pending' 또는 'confirmed')
# - auto 모드면 transactions 테이블에도 레코드 생성
```

### Push 테스트 (푸쉬 수집)

```bash
# 1. 에뮬레이터 시작 확인 (DEBUG 빌드 필수!)
adb devices

# 2. 결제수단을 Push 모드로 변경 (Supabase)
# UPDATE house.payment_methods SET auto_collect_source = 'push' WHERE ...

# 3. 알림 리스너 권한 확인
# 설정 > 알림 > 알림 접근 > 앱 활성화

# 4. 로그 모니터링 시작 (새 터미널)
adb logcat | grep -E "(FinancialPushListener|Auto mode|Suggest mode)"

# 5. 앱 실행 (디버그 빌드)
flutter run

# 6. 앱에서 로그인 → 가계부 선택

# 7. Push 테스트 전송
./scripts/simulate_kbpay.sh 50000 '스타벅스'

# 8. 로그에서 결과 확인
# - "Financial notification received from: com.android.shell"
# - "Suggest mode for payment method..." 또는
# - "Auto mode enabled for payment method..."

# 9. Supabase 확인
# - pending_transactions 테이블 (status='pending' 또는 'confirmed')
# - auto 모드면 transactions 테이블에도 레코드 생성
```

### 모드별 예상 결과

| 모드 | pending_transactions | transactions | status |
|------|---------------------|--------------|--------|
| suggest | O | X | pending |
| auto | O | O | confirmed |
