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
- **푸시 알림**: Firebase (firebase_core, firebase_messaging, flutter_local_notifications)
- **홈 위젯**: home_widget (빠른 추가, 월간 요약 위젯)
- **딥링크**: app_links
- **SMS 수신**: another_telephony (안드로이드 SMS 자동수집)
- **UI/차트**: fl_chart, table_calendar, flutter_slidable, shimmer
- **이미지**: image_picker, cached_network_image
- **로컬 저장소**: shared_preferences
- **소셜 로그인**: google_sign_in

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

## 개발 도구 스크립트

`scripts/` 디렉토리에 개발 및 테스트를 위한 유틸리티 스크립트들이 있습니다.

### SMS 자동수집 테스트

```bash
# 일반 SMS 시뮬레이션 (ADB)
./scripts/simulate_sms.sh

# 수원페이 SMS/Push 시뮬레이션
./scripts/simulate_suwonpay.sh sms [금액] [가맹점]
./scripts/simulate_suwonpay.sh push [금액] [가맹점]
./scripts/simulate_suwonpay.sh both [금액] [가맹점]

# 푸시 알림 시뮬레이션
./scripts/simulate_push.sh
```

### Maestro 테스트 도구

```bash
# Maestro 자동 실행 및 힐링
./scripts/run-maestro.sh [flow_file]
./scripts/heal-maestro.sh [flow_file]
```

### 에뮬레이터 설정

```bash
# 한글 입력 설정
./scripts/setup_korean_input.sh

# 소프트 키보드 비활성화 (Maestro 테스트용)
./scripts/disable_soft_keyboard.sh
```

### 데이터베이스 마이그레이션

```bash
# Supabase 마이그레이션 실행
node scripts/run_migration.js
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

## 테스트 전략

### 단위 테스트 (Unit Tests)

- **대상**: Repository, Service, Provider 로직
- **도구**: `flutter_test`, `mockito` 또는 `mocktail`
- **위치**: `test/` 디렉토리
- **실행**: `flutter test`

**권장 테스트:**
- 비즈니스 로직 (금액 계산, 유효성 검증 등)
- 파싱 로직 (`SmsParsingService`)
- 데이터 변환 (Model ↔ Entity)

### 위젯 테스트 (Widget Tests)

- **대상**: 개별 위젯 및 UI 컴포넌트
- **도구**: `flutter_test`
- **권장 테스트:**
  - 사용자 입력 핸들링
  - 상태 변화에 따른 UI 업데이트
  - 에러 상태 표시

### 통합 테스트 (Integration Tests)

- **대상**: Feature 단위 전체 플로우
- **도구**: `integration_test` 패키지
- **예시**: 거래 생성 → 저장 → 목록 조회 전체 플로우

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

- `auth`: 인증 (로그인/회원가입, Google 로그인)
- `ledger`: 가계부 관리 및 메인 화면
- `transaction`: 수입/지출/자산 거래 기록
- `category`: 카테고리 관리
- `budget`: 예산 관리
- `statistics`: 통계/차트
- `asset`: 자산 관리 (정기예금, 주식, 펀드, 부동산 등)
- `share`: 가계부 공유 및 멤버 관리
- `search`: 거래 검색
- `settings`: 설정 (사용자 색상 설정 포함)
- `payment_method`: 지출수단(결제수단) 관리 및 SMS 자동수집
  - SMS 기반 거래 자동 수집 및 파싱
  - 학습된 SMS 포맷 관리 (learned_sms_formats)
  - 임시 거래 확인/수정/저장 (pending_transactions)
  - AutoSaveMode: manual(수동), suggest(제안), auto(자동)
- `notification`: 푸시 알림 및 로컬 알림 (FCM)
- `widget`: 홈 화면 위젯 (빠른 추가, 월간 요약)

## 데이터베이스 스키마

Supabase PostgreSQL 사용. 마이그레이션 파일 위치: `supabase/migrations/`

### 주요 테이블

**핵심 테이블:**
- `profiles`: 사용자 프로필 (auth.users 확장, color 컬럼 포함)
- `ledgers`: 가계부
- `ledger_members`: 가계부 멤버 (role: owner/admin/member)
- `categories`: 카테고리 (type: income/expense/asset)
- `transactions`: 거래 기록 (payment_method_id, is_asset, maturity_date 포함)
- `budgets`: 예산
- `ledger_invites`: 가계부 초대

**결제수단 관련:**
- `payment_methods`: 결제수단 관리 (현금, 카드 등)
  - `auto_save_mode`: 자동 저장 모드 (manual/suggest/auto)
  - `default_category_id`: 자동 분류 실패 시 기본 카테고리
  - `can_auto_save`: 자동 수집 지원 여부
  - `owner_user_id`: 결제수단 소유자 (멤버별 관리)

**SMS 자동수집 (034_add_auto_save_features.sql):**
- `learned_sms_formats`: 학습된 SMS 포맷 및 파싱 패턴
  - 발신자 패턴, 금액/상호/날짜 정규식
  - 신뢰도(confidence), 매칭 횟수(match_count)
  - 시스템 제공 vs 사용자 학습 구분
- `pending_transactions`: 자동수집된 임시 거래
  - 파싱된 데이터 (금액, 상호, 날짜, 거래 타입)
  - 상태: pending(대기), confirmed(확정), rejected(거부)
  - 원본 SMS 텍스트 보관

**알림 관련 (005_add_notification_tables.sql):**
- `fcm_tokens`: Firebase Cloud Messaging 토큰 저장
- `notification_settings`: 사용자별 알림 설정
- `push_notifications`: 알림 히스토리

**기타 마이그레이션:**
- `003_auto_create_default_ledger.sql`: 회원가입 시 기본 가계부 자동 생성
- `004_make_category_nullable.sql`: 카테고리 nullable 처리
- `006_add_profile_color.sql`: 사용자별 색상 지정 기능
- `015_convert_saving_to_asset.sql`: 저축(saving) 타입을 자산(asset) 타입으로 통합
- `016_add_asset_categories.sql`: 자산 카테고리 추가 (정기예금, 적금, 주식, 펀드, 부동산, 암호화폐)
- `036_add_can_auto_save.sql`: 결제수단별 자동수집 지원 여부 컬럼 추가
- `037_add_payment_method_owner.sql`: 결제수단 소유자(owner_user_id) 컬럼 추가
- `038_fix_pending_transactions_rls.sql`: pending_transactions RLS 정책 수정
- `039_update_payment_method_sharing_policy.sql`: 결제수단 공유 정책 업데이트
- `040_add_increment_match_count_rpc.sql`: SMS 포맷 매칭 카운트 원자적 증가 RPC 함수
- `041_add_is_duplicate_column.sql`: 중복 거래 감지용 컬럼 추가
- `042_add_auto_collect_source.sql`: 자동수집 소스(SMS/Push) 선택 컬럼 추가
- `043_fix_payment_method_unique_constraint.sql`: 자동수집 결제수단 사용자별 독립 관리
  - 기존 `UNIQUE(ledger_id, name)` 제거
  - 공유 결제수단: `UNIQUE(ledger_id, name) WHERE can_auto_save=false`
  - 자동수집 결제수단: `UNIQUE(ledger_id, owner_user_id, name) WHERE can_auto_save=true`

RLS (Row Level Security) 정책이 모든 테이블에 적용되어 있음.

### RPC 함수 (Stored Procedures)

Supabase에서 제공하는 RPC 함수들:

- `increment_sms_format_match_count(format_id UUID)`: SMS 포맷 매칭 카운트 원자적 증가
  - Race condition 방지를 위한 단일 트랜잭션 처리
  - `match_count` 컬럼을 안전하게 증가시킴
- `check_user_exists(email TEXT)`: 이메일로 사용자 존재 여부 확인
- 기타 트리거 함수들 (자동 생성, 동기화 등)

**RPC 함수 사용 시 장점:**
- 원자적 연산 보장 (트랜잭션)
- 네트워크 왕복 횟수 감소
- 복잡한 비즈니스 로직을 서버에서 처리

## 환경 설정

`.env` 파일에 Supabase 설정 필요:
```
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_anon_key
```

### Android 빌드 설정

**build.gradle.kts 주요 설정:**
- compileSdk: flutter.compileSdkVersion
- minSdk: flutter.minSdkVersion (API 21+)
- Java/Kotlin: JVM 17
- Core Library Desugaring: Java 8+ API 지원 (백포트)

**플러그인:**
- `com.google.gms.google-services`: Firebase 통합

**주요 의존성:**
- AndroidX AppCompat, Lifecycle, Material Components
- OkHttp 4.12.0 (Supabase REST API)
- Kotlinx Coroutines (비동기 작업)

**권한 (AndroidManifest.xml):**
- `READ_SMS`, `RECEIVE_SMS`: SMS 자동수집
- `POST_NOTIFICATIONS`: 푸시 알림 (Android 13+)
- `INTERNET`, `ACCESS_NETWORK_STATE`: 네트워크 통신

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

## 개발 워크플로우

프로젝트에서는 `.workflow/` 디렉토리를 사용하여 기능 개발을 체계적으로 관리합니다.

```
.workflow/
├── prd.md          # 현재 작업 중인 PRD (Product Requirements Document)
├── todo.md         # 현재 작업 목록
├── context/        # 컨텍스트 파일 (필요시)
├── results/        # 작업 결과 문서
└── archived/       # 완료된 PRD/TODO 아카이브
```

### 워크플로우 사용법

1. 새 기능 개발 시 `prd.md`에 요구사항 정의
2. `todo.md`에 작업 목록 작성
3. 작업 완료 후 결과는 `results/`에 저장
4. 완료된 PRD/TODO는 `archived/`로 이동 (날짜_기능명 형식)
5. 코드 리뷰 결과는 `results/review_*.md` 형식으로 저장

### 코드 리뷰 체크리스트

**Critical/High 이슈:**
- Race condition 및 트랜잭션 처리
- 프로덕션 환경의 디버그 코드
- 보안 취약점 (SQL Injection, XSS 등)

**Medium 이슈:**
- 타입 안전성 및 캐스팅
- 하드코딩된 문자열 (i18n 누락)
- 불명확한 에러 메시지

**Low 이슈:**
- 코드 포맷팅 및 일관성
- 불필요한 위젯 또는 중복 코드
- 주석 및 문서화

## 테마 및 색상 관리

### 다크모드 지원

앱은 라이트/다크 모드를 지원하며, `ThemeProvider`를 통해 테마를 관리합니다.

관련 파일:
- `lib/shared/themes/app_theme.dart`: 테마 정의
- `lib/shared/themes/theme_provider.dart`: 테마 상태 관리

### 사용자별 색상

캘린더에서 각 사용자의 거래를 구분하기 위해 사용자별 고유 색상을 지정할 수 있습니다.

기본 색상 팔레트 (파스텔 톤):
- 파스텔 블루: `#A8D8EA`
- 코랄 오렌지: `#FFB6A3`
- 민트 그린: `#B8E6C9`
- 라벤더: `#D4A5D4`
- 피치: `#FFCBA4`

관련 파일:
- `lib/shared/widgets/color_picker.dart`: 색상 선택 위젯
- `lib/features/settings/presentation/pages/settings_page.dart`: 색상 설정 UI

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

## SMS 자동수집 기능

### 개요

Android SMS 수신을 통해 금융 거래를 자동으로 파싱하고 가계부에 저장하는 기능입니다.

### 아키텍처

```
SMS 수신 → 파싱 → 임시 저장 → 사용자 확인 → 거래 생성
   ↓         ↓        ↓           ↓            ↓
Telephony  Parsing  Pending   UI Confirm   Transaction
         Service  Repository              Repository
```

### 주요 컴포넌트

**Services:**
- `SmsListenerService`: SMS 수신 및 리스닝 관리 (Singleton)
- `SmsParsingService`: SMS 텍스트 파싱 및 거래 정보 추출
- `NotificationListenerWrapper`: 알림 기반 SMS 감지 (백그라운드)
- `CategoryMappingService`: 상호명 기반 카테고리 자동 매핑
- `DuplicateCheckService`: 중복 거래 감지 및 방지

**Repositories:**
- `LearnedSmsFormatRepository`: SMS 포맷 학습 및 매칭
- `PendingTransactionRepository`: 임시 거래 CRUD 및 상태 관리

**UI:**
- `PaymentMethodManagementPage`: 결제수단 관리 + 수집내역 탭
- `AutoSaveSettingsPage`: 자동수집 모드 설정
- `PendingTransactionCard`: 임시 거래 카드 (확인/수정/거부)

### AutoSaveMode 타입

```dart
enum AutoSaveMode {
  manual,   // 수동: SMS 자동수집 비활성화
  suggest,  // 제안: 수집 후 사용자 확인 필요
  auto;     // 자동: 수집 후 즉시 거래 생성
}
```

### 개발 시 주의사항

1. **Race Condition 방지**
   - `updateParsedData` + `confirmTransaction` 같은 연속 API 호출 시 트랜잭션 사용 권장
   - RPC 함수 사용 (예: `increment_sms_format_match_count`)

2. **디버그 로그 처리**
   - 프로덕션 빌드에서 불필요한 `debugPrint` 제거 또는 `kDebugMode` 체크
   - 빌드마다 호출되는 로그는 성능에 영향을 줄 수 있음

3. **권한 관리**
   - SMS 수신 권한 (READ_SMS, RECEIVE_SMS)
   - 알림 리스너 권한 (BIND_NOTIFICATION_LISTENER_SERVICE)
   - `PermissionRequestDialog`로 사용자에게 명확한 설명 제공

4. **안드로이드 전용 기능**
   - iOS는 SMS API 제한으로 지원 불가
   - Platform check 필수: `Platform.isAndroid`

### 관련 파일

**Data Layer:**
- `lib/features/payment_method/data/services/sms_*.dart`
- `lib/features/payment_method/data/repositories/learned_sms_format_repository.dart`
- `lib/features/payment_method/data/repositories/pending_transaction_repository.dart`

**Domain Layer:**
- `lib/features/payment_method/domain/entities/learned_sms_format.dart`
- `lib/features/payment_method/domain/entities/pending_transaction.dart`

**Presentation Layer:**
- `lib/features/payment_method/presentation/pages/payment_method_management_page.dart`
- `lib/features/payment_method/presentation/widgets/pending_transaction_card.dart`
- `lib/features/payment_method/presentation/providers/pending_transaction_provider.dart`

## 코드 품질 및 베스트 프랙티스

### 다국어 지원 (i18n)

- **절대 하드코딩 금지**: 모든 사용자 노출 텍스트는 `app_ko.arb`, `app_en.arb`에 정의
- **일관된 키 네이밍**: `{feature}{Component}{Property}` 형식 (예: `transactionAmountRequired`)
- **번역 누락 방지**: 한국어/영어 모두 번역 키 추가 필수

```dart
// ❌ 잘못된 예시
label: const Text('저장'),

// ✅ 올바른 예시
label: Text(l10n.commonSave),
```

### 비동기 작업 및 상태 관리

1. **AsyncValue 사용**: Riverpod의 AsyncValue로 로딩/에러 상태 통합 관리
2. **mounted 체크**: 비동기 작업 후 위젯이 여전히 마운트되어 있는지 확인
   ```dart
   await someAsyncOperation();
   if (!context.mounted) return;
   Navigator.pop(context);
   ```
3. **에러 전파**: catch 블록에서 `rethrow`로 에러를 상위 레이어까지 전파

### 성능 최적화

1. **debugPrint 사용 시 주의**:
   - 빌드 메서드 내 debugPrint는 성능 영향 (매 빌드마다 호출)
   - 프로덕션 릴리즈 시 `kDebugMode` 체크 또는 제거
   ```dart
   if (kDebugMode) {
     debugPrint('Debug info: $data');
   }
   ```

2. **불필요한 위젯 빌드 방지**:
   - `const` 생성자 활용
   - `key` 파라미터로 위젯 재사용

### 트랜잭션 및 동시성

1. **원자적 연산 사용**:
   - 연속된 API 호출 대신 단일 트랜잭션 또는 RPC 함수 사용
   - 예: `increment_sms_format_match_count` RPC

2. **Race Condition 방지**:
   ```dart
   // ❌ 잘못된 예시 - 중간에 실패하면 데이터 불일치
   await updateData(id, newValue);
   await confirmData(id);

   // ✅ 올바른 예시 - 단일 트랜잭션
   await updateAndConfirmData(id, newValue);
   ```

### 타입 안전성

1. **타입 캐스팅 시 검증**:
   ```dart
   if (transaction is PendingTransactionModel) {
     _handleTransaction(transaction);
   } else {
     debugPrint('Unexpected type: ${transaction.runtimeType}');
   }
   ```

2. **Nullable 처리**: null safety 활용, `?.`, `??` 연산자 적극 사용

### UI/UX 가이드라인

1. **에러 메시지 명확성**:
   - 각 에러 상황마다 구체적인 메시지 제공
   - 예: `transactionAmountRequired` vs `transactionAmountExceedsLimit`

2. **사용자 피드백**:
   - 비동기 작업 시 로딩 인디케이터 표시
   - 작업 완료/실패 시 SnackBar로 결과 알림

3. **접근성**:
   - Semantics 위젯 활용
   - 충분한 터치 영역 (최소 48x48)

### 코드 포맷 및 스타일

- `dart format` 정기적 실행
- 들여쓰기 일관성 유지
- 불필요한 위젯(SizedBox 등) 조건부 렌더링
