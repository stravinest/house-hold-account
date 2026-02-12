import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/shared/themes/locale_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  group('SupportedLocales', () {
    test('한국어 로케일이 정의되어 있다', () {
      // When & Then
      expect(SupportedLocales.korean, equals(const Locale('ko', 'KR')));
    });

    test('영어 로케일이 정의되어 있다', () {
      // When & Then
      expect(SupportedLocales.english, equals(const Locale('en', 'US')));
    });

    test('지원하는 로케일 목록에 한국어와 영어가 포함되어 있다', () {
      // When & Then
      expect(SupportedLocales.all, contains(SupportedLocales.korean));
      expect(SupportedLocales.all, contains(SupportedLocales.english));
      expect(SupportedLocales.all.length, equals(2));
    });

    test('기본 로케일은 한국어다', () {
      // When & Then
      expect(SupportedLocales.defaultLocale, equals(SupportedLocales.korean));
    });
  });

  group('LocaleNotifier', () {
    late MockSharedPreferences mockPrefs;
    late LocaleNotifier notifier;

    setUp(() {
      mockPrefs = MockSharedPreferences();
      when(() => mockPrefs.getString(any())).thenReturn(null);
      when(() => mockPrefs.setString(any(), any()))
          .thenAnswer((_) async => true);
    });

    tearDown(() {
      if (notifier.mounted) {
        notifier.dispose();
      }
    });

    group('초기화', () {
      test('저장된 값이 없으면 기본 로케일로 초기화된다', () {
        // Given
        when(() => mockPrefs.getString('app_locale')).thenReturn(null);

        // When
        notifier = LocaleNotifier(mockPrefs);

        // Then
        expect(notifier.state, equals(SupportedLocales.defaultLocale));
        verify(() => mockPrefs.getString('app_locale')).called(1);
      });

      test('저장된 한국어 로케일을 불러온다', () {
        // Given
        when(() => mockPrefs.getString('app_locale')).thenReturn('ko_KR');

        // When
        notifier = LocaleNotifier(mockPrefs);

        // Then
        expect(notifier.state, equals(SupportedLocales.korean));
      });

      test('저장된 영어 로케일을 불러온다', () {
        // Given
        when(() => mockPrefs.getString('app_locale')).thenReturn('en_US');

        // When
        notifier = LocaleNotifier(mockPrefs);

        // Then
        expect(notifier.state, equals(SupportedLocales.english));
      });

      test('잘못된 값이 저장되어 있으면 기본 로케일로 fallback한다', () {
        // Given
        when(() => mockPrefs.getString('app_locale'))
            .thenReturn('invalid_locale');

        // When
        notifier = LocaleNotifier(mockPrefs);

        // Then
        expect(notifier.state, equals(SupportedLocales.defaultLocale));
      });

      test('빈 문자열이 저장되어 있으면 기본 로케일로 fallback한다', () {
        // Given
        when(() => mockPrefs.getString('app_locale')).thenReturn('');

        // When
        notifier = LocaleNotifier(mockPrefs);

        // Then
        expect(notifier.state, equals(SupportedLocales.defaultLocale));
      });
    });

    group('setLocale', () {
      setUp(() {
        when(() => mockPrefs.getString('app_locale')).thenReturn(null);
        notifier = LocaleNotifier(mockPrefs);
      });

      test('로케일을 변경하고 저장한다', () async {
        // Given
        const newLocale = SupportedLocales.english;

        // When
        await notifier.setLocale(newLocale);

        // Then
        expect(notifier.state, equals(newLocale));
        verify(() => mockPrefs.setString('app_locale', 'en_US')).called(1);
      });

      test('한국어로 변경 시 ko_KR로 저장한다', () async {
        // Given
        const newLocale = SupportedLocales.korean;

        // When
        await notifier.setLocale(newLocale);

        // Then
        expect(notifier.state, equals(newLocale));
        verify(() => mockPrefs.setString('app_locale', 'ko_KR')).called(1);
      });

      test('영어로 변경 시 en_US로 저장한다', () async {
        // Given
        const newLocale = SupportedLocales.english;

        // When
        await notifier.setLocale(newLocale);

        // Then
        expect(notifier.state, equals(newLocale));
        verify(() => mockPrefs.setString('app_locale', 'en_US')).called(1);
      });

      test('저장 실패 시 에러를 throw한다', () async {
        // Given
        when(() => mockPrefs.setString(any(), any()))
            .thenThrow(Exception('저장 실패'));

        // When & Then
        expect(
          () => notifier.setLocale(SupportedLocales.english),
          throwsException,
        );
      });

      test('저장 실패해도 상태는 변경된다', () async {
        // Given
        when(() => mockPrefs.setString(any(), any()))
            .thenThrow(Exception('저장 실패'));

        // When
        try {
          await notifier.setLocale(SupportedLocales.english);
        } catch (_) {}

        // Then
        expect(notifier.state, equals(SupportedLocales.english));
      });
    });

    group('isKorean / isEnglish', () {
      setUp(() {
        when(() => mockPrefs.getString('app_locale')).thenReturn(null);
        notifier = LocaleNotifier(mockPrefs);
      });

      test('한국어 로케일일 때 isKorean이 true다', () {
        // Given
        notifier.state = SupportedLocales.korean;

        // When & Then
        expect(notifier.isKorean, isTrue);
        expect(notifier.isEnglish, isFalse);
      });

      test('영어 로케일일 때 isEnglish가 true다', () {
        // Given
        notifier.state = SupportedLocales.english;

        // When & Then
        expect(notifier.isEnglish, isTrue);
        expect(notifier.isKorean, isFalse);
      });

      test('countryCode가 다르면 isKorean이 false다', () {
        // Given
        notifier.state = const Locale('ko', 'JP');

        // When & Then
        expect(notifier.isKorean, isTrue);
      });
    });

    group('Locale 변환 메서드', () {
      setUp(() {
        when(() => mockPrefs.getString('app_locale')).thenReturn(null);
        notifier = LocaleNotifier(mockPrefs);
      });

      test('countryCode가 없는 Locale도 변환할 수 있다', () async {
        // Given
        const localeWithoutCountry = Locale('ko');

        // When
        await notifier.setLocale(localeWithoutCountry);

        // Then
        verify(() => mockPrefs.setString('app_locale', 'ko_')).called(1);
      });

      test('잘못된 형식의 문자열은 기본 로케일로 변환한다', () {
        // Given
        when(() => mockPrefs.getString('app_locale')).thenReturn('ko-KR');

        // When
        final newNotifier = LocaleNotifier(mockPrefs);

        // Then
        expect(newNotifier.state, equals(SupportedLocales.defaultLocale));
        newNotifier.dispose();
      });

      test('알 수 없는 언어 코드는 기본 로케일로 변환한다', () {
        // Given
        when(() => mockPrefs.getString('app_locale')).thenReturn('fr_FR');

        // When
        final newNotifier = LocaleNotifier(mockPrefs);

        // Then
        expect(newNotifier.state, equals(SupportedLocales.defaultLocale));
        newNotifier.dispose();
      });
    });

    group('경계값 테스트', () {
      test('countryCode가 null인 Locale을 처리한다', () async {
        // Given
        when(() => mockPrefs.getString('app_locale')).thenReturn(null);
        notifier = LocaleNotifier(mockPrefs);
        const locale = Locale('en');

        // When
        await notifier.setLocale(locale);

        // Then
        expect(notifier.state, equals(locale));
        verify(() => mockPrefs.setString('app_locale', 'en_')).called(1);
      });

      test('동일한 로케일로 여러 번 변경해도 정상 동작한다', () async {
        // Given
        when(() => mockPrefs.getString('app_locale')).thenReturn(null);
        notifier = LocaleNotifier(mockPrefs);

        // When
        await notifier.setLocale(SupportedLocales.korean);
        await notifier.setLocale(SupportedLocales.korean);
        await notifier.setLocale(SupportedLocales.korean);

        // Then
        expect(notifier.state, equals(SupportedLocales.korean));
        verify(() => mockPrefs.setString('app_locale', 'ko_KR')).called(3);
      });

      test('저장 키가 정확히 app_locale이다', () async {
        // Given
        when(() => mockPrefs.getString('app_locale')).thenReturn(null);
        notifier = LocaleNotifier(mockPrefs);

        // When
        await notifier.setLocale(SupportedLocales.english);

        // Then
        verify(() => mockPrefs.setString('app_locale', any())).called(1);
      });
    });

    group('상태 관리', () {
      test('로케일 변경 시 리스너가 알림을 받는다', () async {
        // Given
        when(() => mockPrefs.getString('app_locale')).thenReturn(null);
        notifier = LocaleNotifier(mockPrefs);
        final states = <Locale>[];
        notifier.addListener((state) => states.add(state));

        // When
        await notifier.setLocale(SupportedLocales.english);
        await notifier.setLocale(SupportedLocales.korean);

        // Then
        expect(states, contains(SupportedLocales.english));
        expect(states, contains(SupportedLocales.korean));
      });

      test('dispose 후에는 mounted가 false다', () {
        // Given
        when(() => mockPrefs.getString('app_locale')).thenReturn(null);
        final testNotifier = LocaleNotifier(mockPrefs);

        // When
        testNotifier.dispose();

        // Then
        expect(testNotifier.mounted, isFalse);
      });
    });
  });
}
