# Maestro 테스트 환경 설정 가이드

## 1. 테스트 계정 생성 (필수)

Maestro 테스트를 실행하기 전에 Supabase에 테스트 계정 2개를 생성해야 합니다.

### 방법 1: Supabase 대시보드에서 생성

1. [Supabase 대시보드](https://app.supabase.com) 접속
2. 프로젝트 선택
3. 왼쪽 메뉴: `Authentication` > `Users` 클릭
4. `Add user` 버튼 클릭
5. 다음 정보로 사용자 생성:

**계정 1:**
- Email: `user1@test.com`
- Password: `testpass123`
- Email Confirm: ✅ 체크

**계정 2:**
- Email: `user2@test.com`
- Password: `testpass123`
- Email Confirm: ✅ 체크

### 방법 2: SQL로 직접 생성

Supabase 대시보드 > SQL Editor에서 다음 쿼리 실행:

```sql
-- 주의: auth.users 테이블에 직접 삽입하는 것은 권장되지 않습니다.
-- 대신 Supabase 대시보드 UI를 사용하세요.
```

## 2. 에뮬레이터 확인

테스트용 에뮬레이터가 생성되었는지 확인:

```bash
flutter emulators
```

다음 에뮬레이터가 목록에 있어야 합니다:
- `Test_Share_1` (720x1280)
- `Test_Share_2` (720x1280)

## 3. 앱 빌드 확인

앱이 정상적으로 빌드되는지 확인:

```bash
cd /Users/eungyu/Desktop/개인/project/house-hold-account
flutter pub get
flutter build apk --debug
```

## 4. 환경 변수 확인

`.env` 파일에 Supabase 설정이 올바른지 확인:

```bash
cat .env
```

다음 값들이 설정되어 있어야 합니다:
```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

## 5. 테스트 실행

### 옵션 A: 전체 자동 테스트 (권장)

```bash
bash maestro-tests/run_share_test.sh
```

이 스크립트는 다음 작업을 자동으로 수행합니다:
1. 첫 번째 에뮬레이터 실행
2. 앱 빌드 및 설치
3. 사용자 1 플로우 실행 (초대 보내기)
4. 에뮬레이터 전환
5. 두 번째 에뮬레이터 실행
6. 사용자 2 플로우 실행 (초대 수락)
7. 결과 확인

**예상 실행 시간:** 약 5-7분

### 옵션 B: 수동 단계별 테스트

#### Step 1: 첫 번째 에뮬레이터 실행

```bash
# 에뮬레이터 실행
flutter emulators --launch Test_Share_1

# 에뮬레이터 부팅 대기 (약 30초)
# 부팅이 완료되면 다음 명령어 실행
```

#### Step 2: 앱 설치

```bash
flutter build apk --debug
flutter install
```

#### Step 3: 사용자 1 테스트 실행

```bash
maestro test maestro-tests/01_user1_invite.yaml
```

#### Step 4: 두 번째 에뮬레이터로 전환

```bash
# 첫 번째 에뮬레이터 종료
adb emu kill

# 두 번째 에뮬레이터 실행
flutter emulators --launch Test_Share_2

# 부팅 대기 후 앱 설치
flutter install
```

#### Step 5: 사용자 2 테스트 실행

```bash
maestro test maestro-tests/02_user2_accept.yaml
```

### 옵션 C: 빠른 개별 테스트

현재 실행 중인 에뮬레이터에서 개별 플로우만 테스트:

```bash
bash maestro-tests/quick_test.sh
```

## 6. 결과 확인

테스트가 성공적으로 완료되면 다음 위치에 스크린샷이 저장됩니다:

```
maestro-tests/screenshots/
├── user1_invite_sent.png       # 사용자 1이 초대를 보낸 화면
└── user2_invite_accepted.png   # 사용자 2가 초대를 수락한 화면
```

## 7. 트러블슈팅

### 문제: 테스트 계정으로 로그인이 안 됨

**원인:** Supabase에 계정이 생성되지 않았거나 이메일 확인이 안 됨

**해결:**
1. Supabase 대시보드에서 `Authentication` > `Users` 확인
2. 해당 사용자의 `Email Confirmed` 상태 확인
3. 확인되지 않았다면 사용자 클릭 > `Confirm email` 실행

### 문제: Maestro가 UI 요소를 찾지 못함

**원인:** UI 텍스트가 변경되었거나 화면 로딩이 완료되지 않음

**해결:**
1. `maestro studio` 실행하여 UI 요소 확인
2. YAML 파일의 텍스트를 실제 UI와 일치하도록 수정
3. `extendedWaitUntil` 시간을 늘림

### 문제: 에뮬레이터가 너무 느림

**원인:** 시스템 리소스 부족

**해결:**
1. Android Studio 및 다른 무거운 프로그램 종료
2. 에뮬레이터 RAM 설정 확인 (권장: 2048MB)
3. 하드웨어 가속 활성화 확인

### 문제: 앱이 Supabase에 연결되지 않음

**원인:** 네트워크 설정 또는 환경 변수 문제

**해결:**
1. `.env` 파일 확인
2. 에뮬레이터 인터넷 연결 확인
3. Supabase 프로젝트가 활성 상태인지 확인

## 8. 고급 설정

### Maestro Studio 사용

UI 요소를 실시간으로 확인하며 플로우를 작성할 수 있습니다:

```bash
maestro studio
```

브라우저에서 `http://localhost:9999`를 열어 인터랙티브하게 테스트 작성 가능

### 디버그 모드로 실행

Maestro 테스트를 디버그 모드로 실행하여 더 많은 로그 확인:

```bash
maestro test --debug maestro-tests/01_user1_invite.yaml
```

### 스크린샷 설정 변경

YAML 파일에서 스크린샷 위치 및 이름 변경:

```yaml
- takeScreenshot: custom/path/screenshot_name
```

## 9. CI/CD 통합 (선택사항)

GitHub Actions에서 Maestro 테스트를 실행하려면:

```yaml
# .github/workflows/maestro-test.yml
name: Maestro Tests

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - uses: mobile-dev-inc/action-maestro-cloud@v1
        with:
          api-key: ${{ secrets.MAESTRO_CLOUD_API_KEY }}
          app-file: build/app/outputs/flutter-apk/app-debug.apk
          flows: maestro-tests/
```

## 참고 자료

- [Maestro 공식 문서](https://maestro.mobile.dev/getting-started/introduction)
- [Maestro CLI 명령어](https://maestro.mobile.dev/cli/commands)
- [Maestro Cloud](https://cloud.mobile.dev/) - 클라우드에서 테스트 실행
