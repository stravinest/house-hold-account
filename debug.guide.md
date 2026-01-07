# 공유 가계부 앱 디버깅 가이드

개발 경험이 없어도 따라할 수 있는 앱 테스트 및 디버깅 가이드입니다.

---

## 목차

1. [사전 준비](#1-사전-준비)
2. [에뮬레이터 실행하기](#2-에뮬레이터-실행하기)
3. [앱 실행하기](#3-앱-실행하기)
4. [공유 기능 테스트하기](#4-공유-기능-테스트하기)
5. [로그 확인하기](#5-로그-확인하기)
6. [자주 발생하는 문제 해결](#6-자주-발생하는-문제-해결)

---

## 1. 사전 준비

### 1.1 필요한 프로그램

| 프로그램 | 용도 | 설치 확인 방법 |
|---------|------|---------------|
| Flutter | 앱 개발 도구 | 터미널에서 `flutter --version` 입력 |
| Android Studio | 안드로이드 에뮬레이터 | 앱 실행 확인 |
| VS Code (선택) | 코드 편집기 | 앱 실행 확인 |

### 1.2 터미널 열기

**Mac에서 터미널 여는 방법:**
1. `Cmd + Space` 눌러서 Spotlight 검색 열기
2. "터미널" 입력 후 Enter

**Windows에서 터미널 여는 방법:**
1. `Win + R` 눌러서 실행 창 열기
2. "cmd" 입력 후 Enter

### 1.3 프로젝트 폴더로 이동

터미널에 다음 명령어를 입력하세요:

```bash
cd ~/Desktop/개인/project/house-hold-account
```

> 팁: 폴더 경로를 모르겠으면 Finder(Mac) 또는 탐색기(Windows)에서 폴더를 찾아 터미널로 드래그하세요.

---

## 2. 에뮬레이터 실행하기

에뮬레이터는 컴퓨터에서 스마트폰을 가상으로 실행하는 프로그램입니다.

### 2.1 Android 에뮬레이터 실행 (권장)

#### 방법 1: Android Studio에서 실행

1. **Android Studio** 앱을 실행합니다
2. 상단 메뉴에서 `Tools` > `Device Manager` 클릭
3. 목록에서 원하는 가상 기기 옆의 **재생 버튼(▶)** 클릭
4. 에뮬레이터가 뜰 때까지 기다립니다 (1-2분 소요)

#### 방법 2: 터미널에서 실행

```bash
# 사용 가능한 에뮬레이터 목록 보기
flutter emulators

# 에뮬레이터 실행 (예: Pixel_6_API_33)
flutter emulators --launch Pixel_6_API_33
```

### 2.2 iOS 시뮬레이터 실행 (Mac 전용)

```bash
# 시뮬레이터 열기
open -a Simulator
```

또는 Xcode 앱 실행 > 상단 메뉴 `Xcode` > `Open Developer Tool` > `Simulator`

### 2.3 에뮬레이터가 잘 실행되었는지 확인

```bash
flutter devices
```

**정상 출력 예시:**
```
2 connected devices:

sdk gphone64 arm64 (mobile) • emulator-5554 • android-arm64  • Android 13 (API 33)
macOS (desktop)             • macos         • darwin-arm64   • macOS 14.0
```

> `emulator-5554` 같은 기기가 보이면 성공입니다!

---

## 3. 앱 실행하기

### 3.1 의존성 설치 (처음 한 번만)

```bash
flutter pub get
```

> 이 명령어는 앱에 필요한 라이브러리를 다운로드합니다.

### 3.2 환경 설정 확인

`.env` 파일이 프로젝트 폴더에 있는지 확인하세요:

```bash
ls -la .env
```

파일이 없다면 다음 내용으로 `.env` 파일을 생성해야 합니다:

```
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_anon_key
```

### 3.3 앱 실행

```bash
# 디버그 모드로 앱 실행 (로그 확인 가능)
flutter run
```

**여러 기기가 연결된 경우:**
```bash
# 특정 기기에서 실행
flutter run -d emulator-5554
```

**실행 성공 시 화면:**
```
Launching lib/main.dart on sdk gphone64 arm64 in debug mode...
Running Gradle task 'assembleDebug'...
✓ Built build/app/outputs/flutter-apk/app-debug.apk.
Installing build/app/outputs/flutter-apk/app-debug.apk...
Syncing files to device sdk gphone64 arm64...
Flutter run key commands.
r Hot reload.
R Hot restart.
q Quit.
```

> `r` 키를 누르면 코드 수정 후 앱을 빠르게 새로고침할 수 있습니다!

---

## 4. 공유 기능 테스트하기

### 4.1 테스트 시나리오

공유 가계부 기능을 테스트하려면 **2개의 계정**이 필요합니다.

#### 시나리오 1: 가계부 초대하기

1. **계정 A**로 로그인
2. 가계부 생성 또는 선택
3. 하단 메뉴에서 **공유** 탭 선택
4. **멤버 초대** 버튼 클릭
5. 계정 B의 이메일 입력
6. 초대 전송

#### 시나리오 2: 초대 수락하기

1. **계정 B**로 로그인 (다른 기기 또는 로그아웃 후 재로그인)
2. 알림 또는 초대 목록 확인
3. 초대 수락
4. 공유된 가계부 확인

### 4.2 테스트용 계정 만들기

Supabase 대시보드에서 테스트 계정을 생성할 수 있습니다:

1. [Supabase 대시보드](https://app.supabase.com) 접속
2. 프로젝트 선택
3. 왼쪽 메뉴에서 `Authentication` > `Users`
4. `Add user` 버튼 클릭
5. 이메일/비밀번호 입력 후 생성

### 4.3 공유 기능 관련 화면

| 화면 | 경로 | 기능 |
|------|------|------|
| 공유 관리 | `lib/features/share/presentation/pages/share_management_page.dart` | 멤버 관리, 초대 |
| 공유 Provider | `lib/features/share/presentation/providers/share_provider.dart` | 공유 상태 관리 |
| 공유 Repository | `lib/features/share/data/repositories/share_repository.dart` | Supabase 연동 |

---

## 5. 로그 확인하기

로그는 앱에서 어떤 일이 일어나는지 확인하는 메시지입니다.

### 5.1 로그 보는 방법

#### 방법 1: flutter run 터미널에서 보기 (가장 쉬움)

`flutter run` 명령어를 실행한 터미널에 로그가 자동으로 표시됩니다.

```
I/flutter ( 1234): 사용자 로그인 성공: user@email.com
I/flutter ( 1234): 가계부 목록 로드 중...
I/flutter ( 1234): 가계부 3개 로드 완료
```

#### 방법 2: Android Logcat 사용 (더 자세한 로그)

```bash
# 새 터미널 창에서 실행
adb logcat | grep -i flutter
```

#### 방법 3: VS Code 디버그 콘솔

1. VS Code에서 프로젝트 열기
2. `F5` 키 또는 상단 메뉴 `Run` > `Start Debugging`
3. 하단 `DEBUG CONSOLE` 탭에서 로그 확인

### 5.2 로그 직접 찍는 방법

코드에서 로그를 추가하고 싶다면:

#### 위치 찾기

테스트하고 싶은 기능의 코드 파일을 엽니다.

예: 공유 기능 디버깅 → `lib/features/share/presentation/providers/share_provider.dart`

#### 로그 추가하기

```dart
// 파일 상단에 추가
import 'dart:developer' as developer;

// 원하는 위치에 로그 추가
developer.log('여기까지 실행됨');
developer.log('변수 값: $변수이름');
developer.log('가계부 ID: ${ledger.id}');
```

#### print vs developer.log 차이

| 방법 | 사용법 | 장점 |
|------|--------|------|
| `print('메시지')` | 간단한 출력 | 가장 쉬움 |
| `developer.log('메시지')` | 상세 로그 | 시간, 위치 정보 포함 |
| `debugPrint('메시지')` | 긴 문자열 출력 | 잘리지 않음 |

### 5.3 로그 레벨별 사용

```dart
// 일반 정보
developer.log('정보: 사용자 로그인 시도');

// 경고
developer.log('경고: 네트워크 느림', level: 500);

// 에러
developer.log('에러: 데이터 로드 실패', level: 1000);
```

### 5.4 공유 기능에 로그 추가 예시

`lib/features/share/data/repositories/share_repository.dart` 파일을 열고:

```dart
import 'dart:developer' as developer;

class ShareRepository {
  Future<void> inviteMember(String ledgerId, String email) async {
    developer.log('초대 시작 - 가계부: $ledgerId, 이메일: $email');

    try {
      // 기존 코드...
      final response = await supabase
          .from('ledger_invites')
          .insert({...});

      developer.log('초대 성공: ${response.toString()}');
    } catch (e, stackTrace) {
      developer.log('초대 실패: $e', level: 1000);
      developer.log('스택트레이스: $stackTrace', level: 1000);
      rethrow;
    }
  }
}
```

### 5.5 로그 필터링

터미널에 너무 많은 로그가 나올 때:

```bash
# 특정 키워드만 필터링
flutter run 2>&1 | grep "초대"

# 에러만 보기
flutter run 2>&1 | grep -i "error"
```

---

## 6. 자주 발생하는 문제 해결

### 6.1 에뮬레이터가 안 뜨는 경우

**증상:** `flutter devices`에 기기가 안 보임

**해결 방법:**
```bash
# Android Studio에서 에뮬레이터 재실행
# 또는 ADB 재시작
adb kill-server
adb start-server
flutter devices
```

### 6.2 앱이 실행되지 않는 경우

**증상:** `flutter run` 실행 시 에러 발생

**해결 방법:**
```bash
# 캐시 정리 후 재시도
flutter clean
flutter pub get
flutter run
```

### 6.3 Supabase 연결 오류

**증상:** "Failed to connect to Supabase" 에러

**확인 사항:**
1. `.env` 파일이 있는지 확인
2. `SUPABASE_URL`과 `SUPABASE_ANON_KEY` 값이 올바른지 확인
3. 인터넷 연결 확인

**로그로 확인:**
```dart
developer.log('Supabase URL: ${dotenv.env["SUPABASE_URL"]}');
```

### 6.4 공유 기능이 작동하지 않는 경우

**확인 순서:**

1. **로그인 상태 확인**
   ```dart
   developer.log('현재 사용자: ${supabase.auth.currentUser?.email}');
   ```

2. **가계부 권한 확인**
   ```dart
   developer.log('가계부 멤버 역할: ${member.role}');
   ```

3. **Supabase 대시보드에서 데이터 확인**
   - `ledger_members` 테이블에서 멤버 확인
   - `ledger_invites` 테이블에서 초대 상태 확인

### 6.5 핫 리로드가 안 되는 경우

**증상:** `r` 키를 눌러도 변경사항이 반영 안 됨

**해결 방법:**
- `R` (대문자) 키를 눌러 Hot Restart 실행
- 또는 앱 종료 후 `flutter run` 다시 실행

---

## 빠른 참조표

### 자주 사용하는 명령어

| 명령어 | 설명 |
|--------|------|
| `flutter run` | 앱 실행 |
| `flutter devices` | 연결된 기기 목록 |
| `flutter emulators` | 사용 가능한 에뮬레이터 목록 |
| `flutter emulators --launch 이름` | 에뮬레이터 실행 |
| `flutter clean` | 빌드 캐시 삭제 |
| `flutter pub get` | 의존성 설치 |
| `r` | Hot Reload (코드 변경 후) |
| `R` | Hot Restart (완전 재시작) |
| `q` | 앱 종료 |

### 로그 찍기 빠른 참조

```dart
// 파일 상단
import 'dart:developer' as developer;

// 사용
developer.log('메시지');
developer.log('변수: $변수');
developer.log('에러: $e', level: 1000);
```

### 주요 파일 위치

| 기능 | 파일 경로 |
|------|----------|
| 앱 시작점 | `lib/main.dart` |
| 라우터 설정 | `lib/config/router.dart` |
| 홈 화면 | `lib/features/ledger/presentation/pages/home_page.dart` |
| 공유 관리 | `lib/features/share/presentation/pages/share_management_page.dart` |
| 공유 로직 | `lib/features/share/data/repositories/share_repository.dart` |

---

## 7. 앱 테스트 자동화 오류 해결

### 7.1 API Error 400 - 이미지 크기 초과

**증상:**
```
API Error: 400
messages.3.content.79.image.source.base64.data: At least one of the image dimensions exceed max allowed size for many-image requests: 2000 pixels
```

**원인:**
- 에뮬레이터 해상도가 너무 높음 (예: 1080x2400 픽셀)
- Claude API의 many-image 요청 제한: 이미지의 최대 크기는 2000픽셀
- 앱 테스트 워크플로우에서 여러 스크린샷을 찍을 때, 세로 2400픽셀이 제한(2000픽셀)을 초과

**해결 방법 1: 낮은 해상도 에뮬레이터 생성 (권장)**

1. Android Studio에서 AVD Manager 열기
   - `Tools` > `Device Manager`

2. 새 가상 기기 생성
   - `Create Device` 클릭
   - Phone 카테고리에서 작은 화면 선택 (예: Pixel 3a)
   - 시스템 이미지 선택 (API 34 이상 권장)
   - `Show Advanced Settings` 클릭
   - 다음 해상도로 변경:
     - Width: 720
     - Height: 1280
     - DPI: 320
   - `Finish` 클릭

3. 새로운 에뮬레이터로 테스트 실행

**해결 방법 2: 명령줄로 낮은 해상도 에뮬레이터 생성**

```bash
# 사용 가능한 시스템 이미지 확인
/Users/eungyu/Library/Android/sdk/cmdline-tools/latest/bin/sdkmanager --list | grep system-images

# AVD 생성 (720x1280 해상도)
/Users/eungyu/Library/Android/sdk/cmdline-tools/latest/bin/avdmanager create avd \
  -n "Test_Phone_HD" \
  -k "system-images;android-34;google_apis;arm64-v8a" \
  -d "pixel_3a"

# 생성된 AVD 실행
flutter emulators --launch Test_Phone_HD
```

**해결 방법 3: iOS 시뮬레이터 사용 (Mac만 가능)**

iOS 시뮬레이터는 일반적으로 해상도가 낮습니다:
```bash
flutter emulators --launch apple_ios_simulator
```

**해결 방법 4: 테스트에서 스크린샷 최소화**

불필요한 스크린샷을 제거하여 API 요청의 이미지 수를 줄입니다:

`test_flow.yaml` 수정:
```yaml
appId: com.household.shared.shared_household_account
---
- launchApp
- tapOn: '더보기'
# - takeScreenshot: test_more_menu  # 필요한 경우만 주석 해제
```

**확인 방법:**

```bash
# 1. 디바이스 목록 확인
flutter emulators

# 2. 새 에뮬레이터 실행
flutter emulators --launch Test_Phone_HD

# 3. 화면 크기 확인 (세로가 2000 이하여야 함)
flutter devices

# 4. 앱 테스트 실행
# Claude Code에서: /app-test-workflow
```

**권장 테스트 환경:**
- 에뮬레이터 이름: Test_Phone_HD
- 해상도: 720x1280 (세로 1280 < 2000 제한)
- API Level: 34 이상
- 용도: 자동화 테스트 전용

---

## 도움이 필요하면?

1. 터미널에 나온 에러 메시지를 복사
2. 해당 에러로 Google 검색
3. Stack Overflow 또는 Flutter 공식 문서 참고

**유용한 링크:**
- [Flutter 공식 문서](https://docs.flutter.dev)
- [Supabase 문서](https://supabase.com/docs)
- [Flutter 한국어 커뮤니티](https://flutter-ko.dev)
