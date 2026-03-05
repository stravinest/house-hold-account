import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shared_household_account/shared/themes/theme_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ThemeModeNotifier 기본 동작', () {
    test('저장된 값이 없을 때 ThemeMode.light를 기본값으로 반환한다', () async {
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      final state = container.read(themeModeProvider);

      expect(state, ThemeMode.light);
    });

    test('light 테마로 변경하고 SharedPreferences에 저장한다', () async {
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(themeModeProvider.notifier);

      await notifier.setThemeMode(ThemeMode.light);

      final state = container.read(themeModeProvider);
      expect(state, ThemeMode.light);
      expect(prefs.getString('theme_mode'), 'light');
    });

    test('dark 테마로 변경하고 SharedPreferences에 저장한다', () async {
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(themeModeProvider.notifier);

      await notifier.setThemeMode(ThemeMode.dark);

      final state = container.read(themeModeProvider);
      expect(state, ThemeMode.dark);
      expect(prefs.getString('theme_mode'), 'dark');
    });

    test('system 테마로 변경하고 SharedPreferences에 저장한다', () async {
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(themeModeProvider.notifier);

      await notifier.setThemeMode(ThemeMode.system);

      final state = container.read(themeModeProvider);
      expect(state, ThemeMode.system);
      expect(prefs.getString('theme_mode'), 'system');
    });
  });

  group('ThemeModeNotifier SharedPreferences 로드', () {
    test('SharedPreferences에 light가 저장되어 있으면 light 테마로 초기화한다', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'light'});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      final state = container.read(themeModeProvider);

      expect(state, ThemeMode.light);
    });

    test('SharedPreferences에 dark가 저장되어 있으면 dark 테마로 초기화한다', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      final state = container.read(themeModeProvider);

      expect(state, ThemeMode.dark);
    });

    test('SharedPreferences에 system이 저장되어 있으면 light 테마로 마이그레이션한다', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'system'});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      final state = container.read(themeModeProvider);

      expect(state, ThemeMode.light);
    });
  });

  group('ThemeModeNotifier 에러 처리', () {
    test('잘못된 값이 저장되어 있으면 기본값 ThemeMode.light로 fallback한다', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'invalid_value'});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      final state = container.read(themeModeProvider);

      expect(state, ThemeMode.light);
    });

    test('빈 문자열이 저장되어 있으면 기본값 ThemeMode.light로 fallback한다', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': ''});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      final state = container.read(themeModeProvider);

      expect(state, ThemeMode.light);
    });
  });

  group('ThemeModeNotifier 상태 전환', () {
    test('여러 번 테마를 변경해도 올바르게 동작한다', () async {
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(themeModeProvider.notifier);

      // light로 변경
      await notifier.setThemeMode(ThemeMode.light);
      expect(container.read(themeModeProvider), ThemeMode.light);
      expect(prefs.getString('theme_mode'), 'light');

      // dark로 변경
      await notifier.setThemeMode(ThemeMode.dark);
      expect(container.read(themeModeProvider), ThemeMode.dark);
      expect(prefs.getString('theme_mode'), 'dark');

      // system으로 변경
      await notifier.setThemeMode(ThemeMode.system);
      expect(container.read(themeModeProvider), ThemeMode.system);
      expect(prefs.getString('theme_mode'), 'system');
    });
  });

  group('sharedPreferencesProvider override 없이 사용 시 에러 발생', () {
    test('sharedPreferencesProvider를 override하지 않으면 UnimplementedError가 발생한다', () {
      // Given: override 없이 ProviderContainer 생성
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // When & Then: sharedPreferencesProvider를 읽으면 UnimplementedError 발생
      expect(
        () => container.read(sharedPreferencesProvider),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('sharedPreferencesProvider 에러 메시지에 main.dart 안내가 포함된다', () {
      // Given
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // When & Then
      try {
        container.read(sharedPreferencesProvider);
      } catch (e) {
        expect(e, isA<UnimplementedError>());
        expect(e.toString(), contains('main.dart'));
      }
    });
  });
}
