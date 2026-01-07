# Maestro 테스트 가이드

## 개요

Maestro를 사용하여 공유 가계부 앱의 공유 기능을 자동으로 테스트합니다.

## 사전 준비

### 1. 테스트 계정 생성

Supabase 대시보드에서 두 개의 테스트 계정을 생성합니다:

1. [Supabase 대시보드](https://app.supabase.com) 접속
2. 프로젝트 선택
3. 왼쪽 메뉴에서 `Authentication` > `Users`
4. `Add user` 버튼 클릭하여 아래 계정 생성:
   - **계정 1**: user1@test.com / testpass123
   - **계정 2**: user2@test.com / testpass123

### 2. 에뮬레이터 준비

테스트용 에뮬레이터 2개가 생성되어 있습니다:
- `Test_Share_1`: 사용자 1용 (720x1280)
- `Test_Share_2`: 사용자 2용 (720x1280)

## 테스트 실행 방법

### 방법 1: 단계별 실행 (권장)

#### Step 1: 첫 번째 에뮬레이터 실행 및 앱 빌드

```bash
# 현재 실행 중인 에뮬레이터 종료
adb -s emulator-5554 emu kill

# 첫 번째 테스트 에뮬레이터 실행
/Users/eungyu/Library/Android/sdk/emulator/emulator -avd Test_Share_1 &

# 에뮬레이터 부팅 대기 (약 30초)
sleep 30

# 앱 빌드 및 설치
cd /Users/eungyu/Desktop/개인/project/house-hold-account
flutter build apk --debug
flutter install -d emulator-5554
```

#### Step 2: 사용자 1 플로우 실행 (초대 보내기)

```bash
maestro test maestro-tests/01_user1_invite.yaml
```

#### Step 3: 두 번째 에뮬레이터로 전환

```bash
# 첫 번째 에뮬레이터 종료
adb -s emulator-5554 emu kill

# 두 번째 테스트 에뮬레이터 실행
/Users/eungyu/Library/Android/sdk/emulator/emulator -avd Test_Share_2 &

# 에뮬레이터 부팅 대기
sleep 30

# 앱 설치
flutter install -d emulator-5554
```

#### Step 4: 사용자 2 플로우 실행 (초대 수락)

```bash
maestro test maestro-tests/02_user2_accept.yaml
```

### 방법 2: 자동화 스크립트 실행

전체 과정을 자동화한 스크립트를 실행합니다:

```bash
bash maestro-tests/run_share_test.sh
```

## 테스트 시나리오

### 01_user1_invite.yaml
- 사용자 1로 로그인
- 가계부 생성 (없는 경우)
- 공유 탭으로 이동
- 사용자 2에게 초대 보내기
- 스크린샷 캡처

### 02_user2_accept.yaml
- 사용자 2로 로그인
- 공유 탭 > 받은 초대 확인
- 초대 수락
- 멤버 목록에서 사용자 1 확인
- 스크린샷 캡처

## 주의사항

1. **에뮬레이터 해상도**: 테스트 에뮬레이터는 720x1280 해상도로 설정되어 있습니다. Claude API의 이미지 크기 제한(2000픽셀)을 준수합니다.

2. **Supabase 계정**: 테스트 전 Supabase에 user1@test.com과 user2@test.com 계정이 생성되어 있어야 합니다.

3. **앱 초기화**: 테스트 전 앱 데이터를 초기화하려면:
   ```bash
   adb shell pm clear com.household.shared.shared_household_account
   ```

4. **네트워크**: 에뮬레이터가 인터넷에 연결되어 있어야 Supabase와 통신할 수 있습니다.

## 문제 해결

### 에뮬레이터가 시작되지 않음
```bash
# ADB 재시작
adb kill-server
adb start-server
```

### 앱이 설치되지 않음
```bash
# 빌드 캐시 삭제 후 재빌드
flutter clean
flutter pub get
flutter build apk --debug
```

### Maestro 명령어가 실행되지 않음
```bash
# Maestro 버전 확인
maestro --version

# Maestro 업데이트
curl -Ls "https://get.maestro.mobile.dev" | bash
```

### 화면 요소를 찾지 못함
- `maestro studio` 명령어로 UI 요소를 직접 확인하며 테스트할 수 있습니다:
  ```bash
  maestro studio
  ```

## 스크린샷

테스트 실행 중 캡처된 스크린샷은 `maestro-tests/screenshots/` 디렉토리에 저장됩니다:
- `user1_invite_sent.png`: 사용자 1이 초대를 보낸 화면
- `user2_invite_accepted.png`: 사용자 2가 초대를 수락한 화면

## 참고 링크

- [Maestro 공식 문서](https://maestro.mobile.dev/)
- [Flutter 테스트 가이드](https://docs.flutter.dev/testing)
- [Supabase 문서](https://supabase.com/docs)
