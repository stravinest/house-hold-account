# Theme Provider 구현 결과

## 상태
완료

## 생성/수정 파일
- `lib/shared/themes/theme_provider.dart` (신규)
- `test/shared/themes/theme_provider_test.dart` (신규)
- `lib/main.dart` (수정)

## 요약 (3줄)
- TDD 방식으로 테마 상태 관리 Provider 구현 (테스트 10개 작성, 모두 통과)
- SharedPreferences를 사용한 테마 설정 영구 저장 및 에러 처리
- main.dart에 themeModeProvider 통합하여 앱 전체에서 테마 변경 가능

## 구현 내용

### 1. ThemeModeNotifier 클래스
- StateNotifier<ThemeMode>를 상속하여 테마 상태 관리
- SharedPreferences를 통한 테마 설정 영구 저장
- 저장 키: `theme_mode`
- 저장 값: `light`, `dark`, `system`
- 기본값: `ThemeMode.system`

### 2. 주요 메서드
- `_loadInitialTheme()`: 앱 시작 시 저장된 테마 자동 로드
- `setThemeMode(ThemeMode mode)`: 테마 변경 및 SharedPreferences에 저장
- `_themeModeToString(ThemeMode mode)`: ThemeMode → String 변환
- `_stringToThemeMode(String value)`: String → ThemeMode 변환 (잘못된 값은 system으로 fallback)

### 3. Provider 정의
- `sharedPreferencesProvider`: SharedPreferences 인스턴스를 제공하는 Provider
- `themeModeProvider`: ThemeModeNotifier를 제공하는 StateNotifierProvider

### 4. 에러 처리
- SharedPreferences 저장 실패 시: 메모리 상태만 변경 (사용자에게는 에러 표시 안 함)
- 잘못된 저장값 발견 시: 기본값(ThemeMode.system)으로 fallback
- 빈 문자열: 기본값으로 fallback

### 5. 테스트 커버리지
총 10개의 테스트 케이스:

**기본 동작 (4개)**
- 저장된 값이 없을 때 ThemeMode.system을 기본값으로 반환
- light 테마로 변경하고 SharedPreferences에 저장
- dark 테마로 변경하고 SharedPreferences에 저장
- system 테마로 변경하고 SharedPreferences에 저장

**SharedPreferences 로드 (3개)**
- light가 저장되어 있으면 light 테마로 초기화
- dark가 저장되어 있으면 dark 테마로 초기화
- system이 저장되어 있으면 system 테마로 초기화

**에러 처리 (2개)**
- 잘못된 값이 저장되어 있으면 기본값으로 fallback
- 빈 문자열이 저장되어 있으면 기본값으로 fallback

**상태 전환 (1개)**
- 여러 번 테마를 변경해도 올바르게 동작

### 6. main.dart 통합
```dart
// SharedPreferences 초기화
final sharedPreferences = await SharedPreferences.getInstance();

runApp(
  ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(sharedPreferences),
    ],
    child: const SharedHouseholdAccountApp(),
  ),
);
```

```dart
// MaterialApp에서 themeModeProvider 사용
final themeMode = ref.watch(themeModeProvider);

return MaterialApp.router(
  themeMode: themeMode,
  // ...
);
```

## 사용 방법

### 테마 읽기
```dart
final themeMode = ref.watch(themeModeProvider);
```

### 테마 변경
```dart
// Light 테마로 변경
ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light);

// Dark 테마로 변경
ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark);

// System 테마로 변경
ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.system);
```

### 예시: 설정 페이지에서 테마 토글
```dart
class SettingsPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return SwitchListTile(
      title: Text('다크 모드'),
      value: themeMode == ThemeMode.dark,
      onChanged: (value) {
        ref.read(themeModeProvider.notifier).setThemeMode(
          value ? ThemeMode.dark : ThemeMode.light,
        );
      },
    );
  }
}
```

## TDD 과정

### Red 단계
1. 테스트 파일 작성 (10개 테스트)
2. 테스트 실행 → 실패 확인 (theme_provider.dart 파일 없음)

### Green 단계
1. ThemeModeNotifier 클래스 구현
2. SharedPreferences 저장/로드 기능 구현
3. 에러 처리 및 fallback 로직 추가
4. Provider 정의
5. 테스트 실행 → 모두 통과

### Refactor 단계
1. sharedPreferencesProvider 추가 (DI 패턴)
2. 테스트 코드를 overrideWithValue 패턴으로 개선
3. 문서화 주석 추가
4. main.dart에 통합
5. 전체 테스트 재실행 → 모두 통과

## 검증 결과
- 단위 테스트: 10/10 통과
- 전체 테스트: 11/11 통과
- flutter analyze: 이슈 없음

## 다음 작업 정보
- `import 'package:shared_household_account/shared/themes/theme_provider.dart'`
- 주요 Provider: `themeModeProvider`, `sharedPreferencesProvider`
- 주요 클래스: `ThemeModeNotifier`
- 주요 메서드: `setThemeMode(ThemeMode mode)`
