# PROJECT KNOWLEDGE BASE

**Generated:** 2026-01-14 10:06:37
**Commit:** (latest)
**Branch:** main

## AI 협업 지침

이 프로젝트에서 AI 에이전트와 협업할 때 필수적으로 따라야 할 지침입니다.

### 필수 지침 (전역 적용)
1. **한국어 답변** - 모든 응답은 한국어로 제공합니다
2. **모호성 제거** - 불명확한 요구사항은 추가 질문을 통해 구체화합니다
3. **아키텍처 리뷰** - 설계 결정이 필요한 경우 반드시 질문하고 확인 후 진행합니다

이 지침은 모든 작업, 모든 프로젝트에서 전역적으로 적용됩니다.

## OVERVIEW
공유 가계부 앱 - Flutter/Supabase 기반 크로스플랫폼 앱으로 가족/커플/룸메이트와 재정 공유.

## STRUCTURE
```
./
├── lib/
│   ├── main.dart              # 앱 진입점 (Supabase/Firebase 초기화)
│   ├── config/                # 라우터, 백엔드 설정
│   ├── core/                  # 공통 상수/유틸리티
│   ├── shared/                # 공유 테마/위젯
│   └── features/              # 14개 기능 모듈 (Clean Architecture)
├── supabase/migrations/       # 19개 DB 마이그레이션 파일
├── maestro-tests/             # E2E 자동화 테스트 (Maestro)
├── flows/                     # UI 플로우 다이어그램
├── scripts/                   # 빌드/테스트 자동화 스크립트
├── .workflow/                 # PRD/작업 관리 (아카이브 17개)
├── .claude/                   # AI 에이전트 17개, 스킬 8개
└── .codebase/                 # 아키텍처 문서
```

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| 앱 초기화 로직 | `lib/main.dart` | Supabase, Firebase, 딥링크 설정 |
| 라우팅 설정 | `lib/config/router.dart` | GoRouter, 인증 리다이렉트 |
| 기능 추가 | `lib/features/{feature}/` | Clean Arch: domain/data/presentation |
| 디자인 토큰 | `lib/shared/themes/design_tokens.dart` | Spacing, BorderRadius, Elevation 등 |
| 공통 위젯 | `lib/shared/widgets/` | EmptyState, SectionHeader, AppCard |
| 테마 설정 | `lib/shared/themes/app_theme.dart` | Material 3 ColorScheme |
| DB 마이그레이션 | `supabase/migrations/` | 순차적 001-019 |
| 테스트 작성 | `test/` | 소스 구조 미러링, 한글 설명 |
| E2E 테스트 | `maestro-tests/` | Maestro YAML, 자동 복구 스크립트 |
| 개발 워크플로우 | `.workflow/prd.md` | 현재 작업 PRD |
| 복잡한 통계 로직 | `lib/features/statistics/` | 차트, 집계, 트렌드 분석 |
| 알림 시스템 | `lib/features/notification/` | FCM, 로컬 알림, 토큰 관리 |
| 자산 관리 | `lib/features/asset/` | 정기예금, 주식, 펀드, 목표 |

## CONVENTIONS
- **문자열**: 작은따옴표(`'`) 사용
- **테스트 설명**: 한글로 자세하게 작성
- **에러 처리**: 모든 Supabase 에러는 `rethrow`로 전파
- **이모티콘**: 주석/로그에 절대 사용 금지
- **Provider 수정**: `invalidate()` 사용, 직접 state 변경 금지
- **생성 파일**: `.g.dart` 파일 수동 수정 금지
- **환경변수**: `.env` 파일 커밋 금지
- **디자인 시스템**: 디자인 토큰 필수 사용, 하드코딩 금지
- **바텀시트 하단 패딩**: 네비게이션 바 고려하여 `MediaQuery.of(context).viewPadding.bottom` 추가 필수

## DATABASE MIGRATIONS
- **자동 실행**: 마이그레이션 파일 생성 시 사용자에게 물어보지 말고 `mcp_supabase_apply_migration` 도구를 사용하여 즉시 적용
- **파일 생성**: `supabase/migrations/` 디렉토리에 순차 번호로 생성 (예: 022_description.sql)
- **검증**: 적용 후 `mcp_supabase_list_tables`로 스키마 변경 확인
- **주의사항**: 프로덕션 배포 전 로컬에서 충분히 테스트

## SUPABASE CONFIGURATION

> 상세 설정 가이드: [docs/supabase_guide.md](docs/supabase_guide.md)

### 프로젝트 정보
- **Project ID**: qcpjxxgnqdbngyepevmt
- **Dashboard**: https://supabase.com/dashboard/project/qcpjxxgnqdbngyepevmt
- **API URL**: https://qcpjxxgnqdbngyepevmt.supabase.co
- **Schema**: `house`

### Edge Functions
| 함수명 | 용도 |
|--------|------|
| `send-invite-notification` | 가계부 초대 시 푸시 알림 발송 |
| `send-push-notification` | 거래 변경 시 공유 멤버에게 푸시 알림 발송 |

### 필수 Secret
- `FIREBASE_SERVICE_ACCOUNT`: Firebase Service Account JSON (Edge Function용)

### 핵심 테이블
`profiles`, `ledgers`, `ledger_members`, `categories`, `transactions`, `budgets`, `ledger_invites`, `fcm_tokens`, `notification_settings`, `push_notifications`, `payment_methods`, `fixed_expenses`, `assets`, `asset_goals`

### 변경 시 문서화
Supabase 설정 변경 시 `docs/supabase_guide.md`에 반드시 기록할 것.

## DESIGN SYSTEM

### 디자인 토큰 (`lib/shared/themes/design_tokens.dart`)
모든 하드코딩된 값 대신 디자인 토큰을 사용하세요.

**Spacing (간격)**
- `Spacing.xs` = 4.0 - 매우 작은 간격
- `Spacing.sm` = 8.0 - 작은 간격
- `Spacing.md` = 16.0 - 기본 간격 (가장 많이 사용)
- `Spacing.lg` = 24.0 - 큰 간격
- `Spacing.xl` = 32.0 - 매우 큰 간격
- `Spacing.xxl` = 48.0 - 특별히 큰 간격

**BorderRadiusToken (테두리 반경)**
- `BorderRadiusToken.xs` = 4.0 - 매우 작은 요소 (태그, 배지)
- `BorderRadiusToken.sm` = 8.0 - 작은 요소 (SnackBar, 진행률 표시)
- `BorderRadiusToken.md` = 12.0 - 기본 요소 (Card, Button, Input) - **가장 많이 사용**
- `BorderRadiusToken.lg` = 16.0 - 큰 요소 (FAB, 큰 컨테이너)
- `BorderRadiusToken.xl` = 20.0 - 매우 큰 요소 (시트 상단)

**Elevation (그림자)**
- `Elevation.none` = 0.0 - 그림자 없음
- `Elevation.low` = 1.0 - 매우 낮은 그림자
- `Elevation.medium` = 2.0 - 기본 그림자
- `Elevation.high` = 4.0 - 높은 그림자
- `Elevation.veryHigh` = 8.0 - 매우 높은 그림자

**IconSize (아이콘 크기)**
- `IconSize.xs` = 16.0 - 매우 작은 아이콘
- `IconSize.sm` = 20.0 - 작은 아이콘
- `IconSize.md` = 24.0 - 기본 아이콘 (Material 기본값)
- `IconSize.lg` = 32.0 - 큰 아이콘
- `IconSize.xl` = 48.0 - 매우 큰 아이콘
- `IconSize.xxl` = 64.0 - 특별히 큰 아이콘 (빈 상태)

### 색상 시스템 (Material 3 ColorScheme)
**하드코딩된 색상 사용 금지!** Material 3 ColorScheme을 필수로 사용하세요.

| 하드코딩 (금지) | ColorScheme (필수) | 용도 |
|----------------|-------------------|------|
| `Colors.grey[400]` | `colorScheme.onSurfaceVariant` | 보조 텍스트/아이콘 |
| `Colors.grey[600]` | `colorScheme.onSurface.withValues(alpha: 0.6)` | 주요 보조 텍스트 |
| `Colors.grey` | `colorScheme.onSurface.withValues(alpha: 0.38)` | 비활성 요소 |
| `Colors.red` | `colorScheme.error` | 에러/삭제/지출 |
| `Colors.blue` | `colorScheme.primary` | 수입/주요 액션 |
| `Colors.green` | `colorScheme.tertiary` | 자산/성공 |
| `Colors.grey.shade300` | `colorScheme.surfaceContainerHighest` | 배경/구분선 |

**효과**: 다크 모드 자동 대응, WCAG AA 대비율 자동 보장

### 공통 위젯 (`lib/shared/widgets/`)
중복 코드 방지를 위해 공통 위젯을 사용하세요.

**EmptyState** - 빈 상태 표시
```dart
EmptyState(
  icon: Icons.account_balance_wallet_outlined,
  message: '가계부가 없습니다',
  subtitle: '가계부를 생성하여 시작하세요', // 선택
  action: ElevatedButton(...), // 선택
)
```

**SectionHeader** - 섹션 헤더
```dart
SectionHeader(
  icon: Icons.settings, // 선택
  title: '설정',
  trailing: IconButton(...), // 선택
)
```

**AppCard** - 표준 카드
```dart
AppCard(
  onTap: () {}, // 선택 (탭 가능 카드)
  padding: EdgeInsets.all(Spacing.md), // 기본값
  elevation: Elevation.none, // 기본값
  child: YourWidget(),
)
```

### 사용 예시

```dart
// ❌ 하드코딩 (금지)
Padding(
  padding: EdgeInsets.all(16),
  child: Container(
    decoration: BoxDecoration(
      color: Colors.grey[300],
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text('Hello', style: TextStyle(color: Colors.grey[600])),
  ),
)

// ✅ 디자인 토큰 사용 (권장)
Padding(
  padding: EdgeInsets.all(Spacing.md),
  child: Container(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(BorderRadiusToken.md),
    ),
    child: Text(
      'Hello',
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
      ),
    ),
  ),
)
```

## ANTI-PATTERNS (THIS PROJECT)
```dart
// 금지: 에러 무시
catch (e) { state = AsyncValue.error(e, st); } // rethrow 없음

// 권장: 에러 전파
catch (e, st) { 
  state = AsyncValue.error(e, st); 
  rethrow; 
}

// 금지: 하드코딩된 색상
Colors.grey[400]  // colorScheme.onSurfaceVariant 사용
Colors.red        // colorScheme.error 사용

// 권장: ColorScheme 사용
Theme.of(context).colorScheme.onSurfaceVariant
Theme.of(context).colorScheme.error

// 금지: 하드코딩된 간격/반경
padding: EdgeInsets.all(16)           // Spacing.md 사용
borderRadius: BorderRadius.circular(12)  // BorderRadiusToken.md 사용

// 권장: 디자인 토큰 사용
padding: EdgeInsets.all(Spacing.md)
borderRadius: BorderRadius.circular(BorderRadiusToken.md)

// 금지: 중복 EmptyState/SectionHeader 구현
Center(child: Column(...))  // EmptyState 위젯 사용

// 권장: 공통 위젯 사용
EmptyState(icon: Icons.xxx, message: '...')

// 금지: 자신에게 초대 보내기 (share_repository.dart)
// 금지: 멤버 제한 초과 (최대 2명)
// 금지: 생성 코드 수정 (*.g.dart)
```

## UNIQUE STYLES
- **Feature-first**: 기능별 독립 모듈 (14개)
- **Maestro 자동 복구**: 실패 시 Claude healer-agent 자동 호출
- **워크플로우 추적**: `.workflow/`로 PRD→작업→아카이브 관리
- **MCP 통합**: Supabase/Mobile/Maestro MCP 서버 활용
- **사용자별 색상**: 파스텔 톤 5색 (#A8D8EA, #FFB6A3, #B8E6C9, #D4A5D4, #FFCBA4)
- **테스트 에뮬레이터**: 720x1280 해상도 (Claude API 이미지 제한)

## COMMANDS
```bash
# 의존성 설치
flutter pub get

# 코드 생성 (Riverpod)
flutter pub run build_runner build --delete-conflicting-outputs

# 린트 검사
flutter analyze

# 단위 테스트
flutter test

# E2E 테스트 (전체)
bash maestro-tests/run_share_test.sh

# E2E 테스트 (빠른)
bash maestro-tests/quick_test.sh

# Supabase 로컬 시작
supabase start

# 앱 실행
flutter run
```

## NOTES
- **UTF-8 주의**: TodoWrite 한글은 10자 이내 (Rust 바이트 경계 패닉 방지)
- **RLS 정책**: 모든 테이블에 적용, 우회 금지
- **Firebase 선택**: `.env`에 설정 시 활성화
- **멤버 제한**: 가계부당 최대 2명 (트리거로 강제)
- **saving → asset**: 015 마이그레이션에서 타입 통합
- **빌드 CI/CD**: GitHub Actions 없음 (로컬/수동)
- **대형 파일**: add_transaction_sheet.dart (1232줄), calendar_view.dart (885줄) 리팩토링 고려
- **디자인 리뷰**: `.kombai/resources/design-review-app-consistency-1705123456.md` 참조
