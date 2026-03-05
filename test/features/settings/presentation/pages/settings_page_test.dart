import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_household_account/features/settings/presentation/pages/settings_page.dart';
import 'package:shared_household_account/features/settings/presentation/providers/app_update_provider.dart';
import 'package:shared_household_account/features/settings/data/services/app_update_service.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';
import 'package:shared_household_account/shared/themes/theme_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _buildTestApp({
  List<Override> overrides = const [],
  SharedPreferences? prefs,
}) {
  final router = GoRouter(
    initialLocation: '/settings',
    routes: [
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: '/guide',
        builder: (context, state) => const Scaffold(body: Text('가이드')),
      ),
      GoRoute(
        path: '/category',
        builder: (context, state) => const Scaffold(body: Text('카테고리')),
      ),
      GoRoute(
        path: '/ledger-manage',
        builder: (context, state) => const Scaffold(body: Text('가계부 관리')),
      ),
      GoRoute(
        path: '/fixed-expense',
        builder: (context, state) => const Scaffold(body: Text('고정비')),
      ),
      GoRoute(
        path: '/recurring-templates',
        builder: (context, state) => const Scaffold(body: Text('반복거래')),
      ),
      GoRoute(
        path: '/payment-method',
        builder: (context, state) => const Scaffold(body: Text('결제수단')),
      ),
      GoRoute(
        path: '/settings/pending-transactions',
        builder: (context, state) => const Scaffold(body: Text('수집내역')),
      ),
      GoRoute(
        path: '/terms-of-service',
        builder: (context, state) => const Scaffold(body: Text('이용약관')),
      ),
      GoRoute(
        path: '/privacy-policy',
        builder: (context, state) => const Scaffold(body: Text('개인정보')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      if (prefs != null) sharedPreferencesProvider.overrideWithValue(prefs),
      appUpdateProvider.overrideWith(() => _FakeAppUpdate()),
      packageInfoProvider.overrideWith(
        (ref) async => PackageInfo(
          appName: '가계부',
          packageName: 'com.test.app',
          version: '1.0.0',
          buildNumber: '1',
          buildSignature: '',
        ),
      ),
      ...overrides,
    ],
    child: MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ko'),
    ),
  );
}

// 업데이트 없음 상태로 고정하는 Fake notifier
class _FakeAppUpdate extends AppUpdate {
  @override
  Future<AppVersionInfo?> build() async => null;
}

void main() {
  group('notificationEnabledProvider 테스트', () {
    test('초기 상태가 true이어야 한다', () {
      // Given
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // When
      final value = container.read(notificationEnabledProvider);

      // Then
      expect(value, isTrue);
    });

    test('값을 false로 변경할 수 있어야 한다', () {
      // Given
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // When
      container.read(notificationEnabledProvider.notifier).state = false;

      // Then
      expect(container.read(notificationEnabledProvider), isFalse);
    });
  });

  group('SettingsPage 위젯 테스트', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    testWidgets('기본 구조가 렌더링되어야 한다', (tester) async {
      // When
      await tester.pumpWidget(_buildTestApp(prefs: prefs));
      await tester.pump();

      // Then
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('ListView가 포함되어야 한다', (tester) async {
      // When
      await tester.pumpWidget(_buildTestApp(prefs: prefs));
      await tester.pump();

      // Then
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('테마 설정 ListTile이 포함되어야 한다', (tester) async {
      // When
      await tester.pumpWidget(_buildTestApp(prefs: prefs));
      await tester.pumpAndSettle();

      // Then
      expect(find.byIcon(Icons.palette_outlined), findsOneWidget);
    });

    testWidgets('언어 설정 ListTile이 포함되어야 한다', (tester) async {
      // When
      await tester.pumpWidget(_buildTestApp(prefs: prefs));
      await tester.pumpAndSettle();

      // Then
      expect(find.byIcon(Icons.language_outlined), findsOneWidget);
    });

    testWidgets('알림 SwitchListTile이 포함되어야 한다', (tester) async {
      // When
      await tester.pumpWidget(_buildTestApp(prefs: prefs));
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(SwitchListTile), findsAtLeastNWidgets(1));
    });

    testWidgets('SettingsPage는 ConsumerWidget 타입이어야 한다', (tester) async {
      // Then
      expect(const SettingsPage(), isA<ConsumerWidget>());
    });
  });
}
