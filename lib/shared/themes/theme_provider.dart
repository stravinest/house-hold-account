import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ThemeMode 상태 관리를 위한 Provider
///
/// 사용 방법:
/// ```dart
/// // 테마 읽기
/// final themeMode = ref.watch(themeModeProvider);
///
/// // 테마 변경
/// ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark);
/// ```
///
/// main.dart에서 SharedPreferences 초기화 필요:
/// ```dart
/// final prefs = await SharedPreferences.getInstance();
/// runApp(
///   ProviderScope(
///     overrides: [
///       sharedPreferencesProvider.overrideWithValue(prefs),
///     ],
///     child: MyApp(),
///   ),
/// );
/// ```

// ThemeMode 상태 관리 Notifier
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  static const String _storageKey = 'theme_mode';
  final SharedPreferences _prefs;

  ThemeModeNotifier(this._prefs) : super(ThemeMode.system) {
    _loadInitialTheme();
  }

  // 저장된 테마 로드
  void _loadInitialTheme() {
    final savedValue = _prefs.getString(_storageKey);
    if (savedValue != null) {
      state = _stringToThemeMode(savedValue);
    }
  }

  // 테마 변경 및 저장
  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    try {
      await _prefs.setString(_storageKey, _themeModeToString(mode));
    } catch (e) {
      // SharedPreferences 저장 실패 시 UI 레이어로 에러 전파
      // 사용자에게 적절한 피드백을 제공하기 위함
      rethrow;
    }
  }

  // ThemeMode to String 변환
  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  // String to ThemeMode 변환 (잘못된 값은 system으로 fallback)
  ThemeMode _stringToThemeMode(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        // 잘못된 값이 저장되어 있으면 기본값으로 fallback
        return ThemeMode.system;
    }
  }
}

// SharedPreferences Provider
// main.dart에서 ProviderScope를 초기화할 때 override해서 사용
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
      'sharedPreferencesProvider must be overridden in main.dart');
});

// ThemeMode Provider
final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeModeNotifier(prefs);
});
