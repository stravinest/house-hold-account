# PROJECT KNOWLEDGE BASE

**Generated:** 2026-01-13 10:22:00
**Commit:** 13f8970
**Branch:** main

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

## DATABASE MIGRATIONS
- **자동 실행**: 마이그레이션 파일 생성 시 사용자에게 물어보지 말고 `mcp_supabase_apply_migration` 도구를 사용하여 즉시 적용
- **파일 생성**: `supabase/migrations/` 디렉토리에 순차 번호로 생성 (예: 022_description.sql)
- **검증**: 적용 후 `mcp_supabase_list_tables`로 스키마 변경 확인
- **주의사항**: 프로덕션 배포 전 로컬에서 충분히 테스트

## ANTI-PATTERNS (THIS PROJECT)
```dart
// 금지: 에러 무시
catch (e) { state = AsyncValue.error(e, st); } // rethrow 없음

// 권장: 에러 전파
catch (e, st) { 
  state = AsyncValue.error(e, st); 
  rethrow; 
}

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
