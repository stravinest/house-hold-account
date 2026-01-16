import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme_provider.dart';

/// Locale 상태 관리를 위한 Provider
///
/// 사용 방법:
/// ```dart
/// // 현재 로케일 읽기
/// final locale = ref.watch(localeProvider);
///
/// // 로케일 변경
/// ref.read(localeProvider.notifier).setLocale(const Locale('en', 'US'));
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

// 지원하는 로케일 목록
class SupportedLocales {
  static const Locale korean = Locale('ko', 'KR');
  static const Locale english = Locale('en', 'US');

  static const List<Locale> all = [korean, english];

  // 기본 로케일
  static const Locale defaultLocale = korean;
}

// Locale 상태 관리 Notifier
class LocaleNotifier extends StateNotifier<Locale> {
  static const String _storageKey = 'app_locale';
  final SharedPreferences _prefs;

  LocaleNotifier(this._prefs) : super(SupportedLocales.defaultLocale) {
    _loadInitialLocale();
  }

  // 저장된 로케일 로드
  void _loadInitialLocale() {
    final savedValue = _prefs.getString(_storageKey);
    if (savedValue != null) {
      state = _stringToLocale(savedValue);
    }
  }

  // 로케일 변경 및 저장
  Future<void> setLocale(Locale locale) async {
    state = locale;
    try {
      await _prefs.setString(_storageKey, _localeToString(locale));
    } catch (e) {
      // SharedPreferences 저장 실패 시 UI 레이어로 에러 전파
      // 사용자에게 적절한 피드백을 제공하기 위함
      rethrow;
    }
  }

  // Locale to String 변환
  String _localeToString(Locale locale) {
    return '${locale.languageCode}_${locale.countryCode ?? ''}';
  }

  // String to Locale 변환 (잘못된 값은 기본값으로 fallback)
  Locale _stringToLocale(String value) {
    switch (value) {
      case 'ko_KR':
        return SupportedLocales.korean;
      case 'en_US':
        return SupportedLocales.english;
      default:
        // 잘못된 값이 저장되어 있으면 기본값으로 fallback
        return SupportedLocales.defaultLocale;
    }
  }

  // 현재 로케일이 한국어인지 확인
  bool get isKorean => state.languageCode == 'ko';

  // 현재 로케일이 영어인지 확인
  bool get isEnglish => state.languageCode == 'en';
}

// Locale Provider
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocaleNotifier(prefs);
});

/// BuildContext에서 쉽게 AppLocalizations에 접근하기 위한 Extension
///
/// 사용 예시:
/// ```dart
/// Text(context.l10n.appTitle)
/// ```
extension LocalizationExtension on BuildContext {
  // l10n getter는 main.dart에서 AppLocalizations import 후 사용
  // AppLocalizations.of(this)!로 접근
}
