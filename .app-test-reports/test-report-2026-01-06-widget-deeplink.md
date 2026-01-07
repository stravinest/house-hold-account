# 앱 테스트 완료 보고서

## 테스트 개요
- **테스트 대상**: Android 홈 화면 위젯 딥링크 기능
- **테스트 일시**: 2026-01-06
- **테스트 디바이스**: Android Emulator (emulator-5554)
- **앱 패키지명**: com.household.shared.shared_household_account

## 테스트 항목

### 위젯 종류
1. **QuickAddWidget**: 빠른 거래 추가 위젯
   - 지출 추가 버튼 (`sharedhousehold://add-expense`)
   - 수입 추가 버튼 (`sharedhousehold://add-income`)

2. **MonthlySummaryWidget**: 월간 요약 위젯
   - 위젯 전체 탭 시 홈 이동 (`sharedhousehold://home`)

## 테스트 결과

| 시나리오 | 딥링크 | 결과 | 재시도 | 비고 |
|----------|--------|------|--------|------|
| 지출 추가 딥링크 | `sharedhousehold://add-expense` | PASS | 4 | 버그 수정 후 통과 |
| 수입 추가 딥링크 | `sharedhousehold://add-income` | PASS | 0 | - |
| 홈 이동 딥링크 | `sharedhousehold://home` | PASS | 0 | - |

## 발견된 버그 및 수정 내역

### 버그 1: 딥링크 처리 로직 미구현
- **증상**: AndroidManifest.xml에 intent-filter는 있으나 Flutter 앱에서 딥링크 수신/처리 로직이 없음
- **원인**: `app_links` 패키지 미설치 및 딥링크 핸들러 미구현
- **수정 파일**:
  - `pubspec.yaml` - `app_links: ^6.3.3` 추가
  - `lib/main.dart` - 딥링크 처리 로직 구현

### 버그 2: 동일 위젯 라우트 변경 시 재렌더링 안됨
- **증상**: `/home`에서 `/add-expense`로 이동해도 `initState`가 호출되지 않음
- **원인**: 같은 `HomePage` 위젯을 사용하여 Flutter가 동일 위젯으로 인식
- **수정 파일**:
  - `lib/config/router.dart` - 각 라우트에 `ValueKey(state.matchedLocation)` 추가

### 버그 3: 라우터 리다이렉트로 인한 딥링크 무시
- **증상**: 딥링크로 `/add-expense` 이동 후 즉시 `/home`으로 리다이렉트
- **원인**: `authStateProvider` watch로 인한 라우터 리빌드
- **수정 파일**:
  - `lib/config/router.dart` - `ref.watch` -> `ref.read` 변경, 딥링크 라우트 예외 처리 추가

### 버그 4: 거래 추가 시트가 열렸다가 바로 닫힘
- **증상**: 딥링크로 진입 시 AddTransactionSheet가 잠깐 열렸다가 사라짐
- **원인**: `_initializeLedger()`와 `_handleInitialTransactionType()`의 타이밍 충돌
- **수정 파일**:
  - `lib/features/ledger/presentation/pages/home_page.dart` - 시트 열기 전 100ms 딜레이 추가

## 수정된 파일 목록

| 파일 | 수정 내용 |
|------|----------|
| `pubspec.yaml` | `app_links: ^6.3.3` 의존성 추가 |
| `lib/main.dart` | 딥링크 수신/처리 로직 구현 (`_initDeepLinks`, `_handleDeepLink`) |
| `lib/config/router.dart` | ValueKey 추가, 딥링크 라우트 리다이렉트 예외 처리, ref.watch -> ref.read |
| `lib/features/ledger/presentation/pages/home_page.dart` | 거래 시트 열기 타이밍 수정 (100ms 딜레이) |

## 테스트 방법

ADB를 사용한 딥링크 테스트 명령어:
```bash
# 지출 추가
adb -s emulator-5554 shell am start -a android.intent.action.VIEW -d "sharedhousehold://add-expense" com.household.shared.shared_household_account

# 수입 추가
adb -s emulator-5554 shell am start -a android.intent.action.VIEW -d "sharedhousehold://add-income" com.household.shared.shared_household_account

# 홈 이동
adb -s emulator-5554 shell am start -a android.intent.action.VIEW -d "sharedhousehold://home" com.household.shared.shared_household_account
```

## 추가 권장 사항

1. **위젯 UI 테스트**: 실제 홈 화면에 위젯 추가 후 버튼 탭 테스트 권장
2. **앱 종료 상태 테스트**: 앱이 완전히 종료된 상태에서 딥링크 실행 테스트
3. **에러 처리**: 로그인되지 않은 상태에서 딥링크 접근 시 로그인 후 원래 목적지로 이동하는 로직 고려

## 결론

모든 위젯 딥링크 테스트가 성공적으로 완료되었습니다. 총 4개의 버그를 발견하고 수정하였으며, 최종적으로 세 가지 딥링크 시나리오 모두 정상 동작합니다.
