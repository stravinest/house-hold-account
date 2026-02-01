---
description: ADB로 앱 데이터 초기화 - 테스트용 클린 상태 만들기
---

# ADB Clear App Data

Android 디바이스/에뮬레이터에서 앱 데이터를 완전히 초기화합니다.

## 사용 시점

- 새로운 기능 테스트 시작 전
- 로그인 상태 초기화 필요 시
- SharedPreferences 초기화 시
- SMS 자동수집 테스트 초기화 시

## 명령어

### 1. 기본 데이터 초기화 (앱 유지)

```bash
adb shell pm clear com.household.shared.shared_household_account
```

### 2. 앱 완전 삭제 후 재설치

```bash
# 앱 삭제
adb uninstall com.household.shared.shared_household_account

# 앱 재설치 및 실행
flutter install -d <device-id>
```

### 3. 로그캣 초기화 (로그 확인용)

```bash
# 로그 초기화
adb logcat -c

# 새 로그 확인
adb logcat | grep -i flutter
```

## 특정 디바이스 지정

```bash
# 디바이스 목록 확인
adb devices

# 특정 디바이스에 명령 실행
adb -s emulator-5554 shell pm clear com.household.shared.shared_household_account
```

## 주의사항

- 모든 로컬 데이터가 삭제됨 (로그인 정보, 설정 등)
- Supabase 서버 데이터는 그대로 유지됨
- 테스트 계정으로 다시 로그인 필요
