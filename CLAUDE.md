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

# 테스트 실행
flutter test

# 앱 실행
flutter run
```

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
