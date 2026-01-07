# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 프로젝트 개요

공유 가계부 앱 - 가족/커플/룸메이트와 함께 사용하는 Flutter 기반 크로스플랫폼 앱

## 기술 스택

- **Framework**: Flutter (Dart SDK ^3.10.3)
- **Backend**: Supabase (PostgreSQL + Auth + Realtime + Storage)
- **상태관리**: Riverpod (flutter_riverpod + riverpod_annotation)
- **라우팅**: go_router
- **환경변수**: flutter_dotenv (`.env` 파일)

## 개발 명령어

```bash
# 의존성 설치
flutter pub get

# 코드 생성 (Riverpod 등)
flutter pub run build_runner build --delete-conflicting-outputs

# 린트 검사
flutter analyze

# 단위 테스트 실행
flutter test

# 앱 실행
flutter run
```

## E2E 테스트 (Maestro)

Maestro를 사용하여 앱의 UI 자동화 테스트를 수행합니다.

### 테스트 환경 설정

테스트용 에뮬레이터 (720x1280 해상도):
- `Test_Share_1`: 첫 번째 사용자용
- `Test_Share_2`: 두 번째 사용자용

### 테스트 실행 방법

```bash
# 전체 자동 테스트 (권장)
bash maestro-tests/run_share_test.sh

# 빠른 개별 테스트
bash maestro-tests/quick_test.sh

# 특정 플로우만 실행
maestro test maestro-tests/01_user1_invite.yaml
maestro test maestro-tests/02_user2_accept.yaml
```

### 테스트 시나리오

- `01_user1_invite.yaml`: 사용자 1이 사용자 2에게 가계부 초대 보내기
- `02_user2_accept.yaml`: 사용자 2가 초대 수락하기

**필수 사전 작업**: Supabase에 테스트 계정 생성 필요
- user1@test.com / testpass123
- user2@test.com / testpass123

자세한 설정 방법은 `maestro-tests/SETUP.md` 참고

## 아키텍처

Clean Architecture 기반의 Feature-first 구조를 사용한다.

```
lib/
├── config/           # 앱 설정 (router, supabase_config)
├── core/             # 공통 상수 및 유틸리티
├── shared/           # 공유 컴포넌트 (themes 등)
└── features/         # 기능별 모듈
    └── {feature}/
        ├── domain/       # Entity 정의
        │   └── entities/
        ├── data/         # Repository 및 Model
        │   ├── models/
        │   └── repositories/
        └── presentation/ # UI 레이어
            ├── pages/
            ├── widgets/
            └── providers/
```

### 주요 Feature 목록

- `auth`: 인증 (로그인/회원가입)
- `ledger`: 가계부 관리 및 메인 화면
- `transaction`: 수입/지출 거래 기록
- `category`: 카테고리 관리
- `budget`: 예산 관리
- `statistics`: 통계/차트
- `share`: 가계부 공유 및 멤버 관리
- `search`: 거래 검색
- `settings`: 설정

## 데이터베이스 스키마

Supabase PostgreSQL 사용. 스키마 정의: `supabase/migrations/001_initial_schema.sql`

주요 테이블:
- `profiles`: 사용자 프로필 (auth.users 확장)
- `ledgers`: 가계부
- `ledger_members`: 가계부 멤버 (role: owner/admin/member)
- `categories`: 카테고리 (type: income/expense)
- `transactions`: 거래 기록
- `budgets`: 예산
- `ledger_invites`: 가계부 초대

RLS (Row Level Security) 정책이 모든 테이블에 적용되어 있음.

## 환경 설정

`.env` 파일에 Supabase 설정 필요:
```
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_anon_key
```

## 코드 컨벤션

- 문자열은 작은따옴표(`'`) 사용
- 주석과 console.log에 이모티콘 사용하지 않음
- 테스트 설명은 한글로 자세하게 작성

## Claude Code 사용 시 주의사항

### TodoWrite 도구 사용 시 UTF-8 문자열 처리 주의

Claude Code는 내부적으로 Rust로 구현되어 있으며, 한글과 같은 멀티바이트 UTF-8 문자열 처리 시 바이트 인덱스 기반 슬라이싱으로 인한 패닉이 발생할 수 있습니다.

#### 문제 상황

```
thread '<unnamed>' panicked at byte index 6 is not a char boundary;
it is inside '행' (bytes 4..7) of ` 실행 중 `
```

이 에러는 한글 문자(3바이트)의 중간에서 문자열을 자르려고 할 때 발생합니다.

#### 안전한 사용 패턴

**TodoWrite 사용 시 권장사항:**

1. **content와 activeForm을 짧게 유지**: 10자 이내 권장
2. **간결한 한글 사용**: '분석 중', '실행 중', '작성 중' 등
3. **영어 사용 고려**: 바이트 경계 문제 없음

```dart
// ✅ 권장 - 짧고 명확한 한글
TodoWrite(todos: [
  {'content': '코드 분석', 'activeForm': '코드 분석 중', 'status': 'in_progress'},
  {'content': '테스트 실행', 'activeForm': '테스트 실행 중', 'status': 'pending'}
])

// ⚠️ 주의 - 너무 긴 문자열은 피할 것
TodoWrite(todos: [
  {
    'content': '데이터베이스에서 사용자 정보를 조회하여 검증 후 업데이트 수행',
    'activeForm': '데이터베이스에서 사용자 정보를 조회하여 검증 후 업데이트 수행 중',  // ❌ 패닉 가능성!
    'status': 'in_progress'
  }
])

// ✅ 대안 - 여러 단계로 분리
TodoWrite(todos: [
  {'content': '사용자 조회', 'activeForm': '사용자 조회 중', 'status': 'in_progress'},
  {'content': '데이터 검증', 'activeForm': '데이터 검증 중', 'status': 'pending'},
  {'content': '정보 업데이트', 'activeForm': '정보 업데이트 중', 'status': 'pending'}
])
```

#### UTF-8 바이트 구조 이해

| 문자 타입 | 바이트 수 | 예시 |
|-----------|-----------|------|
| ASCII | 1바이트 | 'a', '1', ' ' |
| 한글/한자 | 3바이트 | '한', '실', '행' |
| 이모지 | 4바이트 | '😀', '🎉' |

예시: ` 실행 중 ` = 12바이트 (공백1 + 실3 + 행3 + 공백1 + 중3 + 공백1)

자세한 내용은 `rust_string_handling_guide.md` 참고

## 에러 처리 원칙

- **데이터베이스 에러는 절대 무시하지 않는다**: Supabase에서 발생하는 모든 에러는 앱에서도 반드시 처리하고 사용자에게 표시해야 함
- **에러 전파(rethrow)**: 서비스 레이어에서 catch한 에러는 UI 레이어까지 전파하여 사용자에게 적절한 피드백 제공
- **try-catch 사용 시 주의**: 에러를 catch한 후 단순히 상태만 변경하고 끝내지 말고, 호출자에게 에러를 알려야 함
- **예시**:
  ```dart
  // 잘못된 예시 - 에러가 UI까지 전파되지 않음
  try {
    await doSomething();
    state = AsyncValue.data(result);
  } catch (e, st) {
    state = AsyncValue.error(e, st);
    // 여기서 끝나면 호출자가 에러를 알 수 없음
  }

  // 올바른 예시 - 에러가 UI까지 전파됨
  try {
    await doSomething();
    state = AsyncValue.data(result);
  } catch (e, st) {
    state = AsyncValue.error(e, st);
    rethrow; // 호출자가 catch할 수 있도록 에러 전파
  }
  ```
