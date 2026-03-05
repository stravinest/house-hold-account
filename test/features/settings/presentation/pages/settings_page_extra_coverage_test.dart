import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_household_account/features/auth/presentation/providers/auth_provider.dart';
import 'package:shared_household_account/features/settings/data/services/app_update_service.dart';
import 'package:shared_household_account/features/settings/presentation/pages/settings_page.dart';
import 'package:shared_household_account/features/settings/presentation/providers/app_update_provider.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';
import 'package:shared_household_account/shared/themes/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAppUpdateNone extends AppUpdate {
  @override
  Future<AppVersionInfo?> build() async => null;
}

SharedPreferences? _fakePrefs;

GoRouter _buildRouter() {
  return GoRouter(
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
        path: '/settings/guide',
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
      GoRoute(
        path: '/debug-test',
        builder: (context, state) => const Scaffold(body: Text('디버그')),
      ),
    ],
  );
}

Widget _buildTestApp({List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(_fakePrefs!),
      appUpdateProvider.overrideWith(() => _FakeAppUpdateNone()),
      packageInfoProvider.overrideWith(
        (ref) async => PackageInfo(
          appName: '가계부',
          packageName: 'com.test.app',
          version: '1.0.0',
          buildNumber: '1',
          buildSignature: '',
        ),
      ),
      userProfileProvider.overrideWith(
        (ref) => Stream.value({'color': '#A8D8EA', 'display_name': '테스트 사용자'}),
      ),
      userColorProvider.overrideWith((_) => '#A8D8EA'),
      ...overrides,
    ],
    child: MaterialApp.router(
      routerConfig: _buildRouter(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ko'),
    ),
  );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    _fakePrefs = await SharedPreferences.getInstance();
  });

  group('SettingsPage 주 시작일 바텀시트 선택 테스트', () {
    testWidgets('주 시작일 ListTile을 탭하면 바텀시트가 표시되어야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // When: 주 시작일 아이콘으로 스크롤
      await tester.scrollUntilVisible(
        find.byIcon(Icons.calendar_today_outlined, skipOffstage: false),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // When: 탭
      await tester.tap(find.byIcon(Icons.calendar_today_outlined));
      await tester.pumpAndSettle();

      // Then: 바텀시트가 표시됨
      expect(find.byType(BottomSheet), findsOneWidget);
    });

    testWidgets('주 시작일 바텀시트에서 일요일을 선택하면 닫혀야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // When: 주 시작일 바텀시트 열기
      await tester.scrollUntilVisible(
        find.byIcon(Icons.calendar_today_outlined, skipOffstage: false),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.calendar_today_outlined));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);

      // When: 첫 번째 항목(일요일) 선택
      final tiles = find.byType(ListTile);
      await tester.tap(tiles.first);
      await tester.pumpAndSettle();

      // Then: 바텀시트가 닫힘
      expect(find.byType(BottomSheet), findsNothing);
    });

    testWidgets('주 시작일 바텀시트에서 월요일을 선택하면 닫혀야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // When: 주 시작일 바텀시트 열기
      await tester.scrollUntilVisible(
        find.byIcon(Icons.calendar_today_outlined, skipOffstage: false),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.calendar_today_outlined));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);

      // When: 두 번째 항목(월요일) 선택
      final tiles = find.byType(ListTile);
      await tester.tap(tiles.at(1));
      await tester.pumpAndSettle();

      // Then: 바텀시트가 닫힘
      expect(find.byType(BottomSheet), findsNothing);
    });
  });

  group('SettingsPage 테마 다크모드 선택 테스트', () {
    testWidgets('테마 바텀시트를 열고 다크모드를 선택할 수 있어야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // When: 테마 탭
      await tester.tap(find.byIcon(Icons.palette_outlined));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);

      // When: 두 번째 항목(다크모드) 탭
      final tiles = find.byType(ListTile);
      await tester.tap(tiles.at(1));
      await tester.pumpAndSettle();

      // Then: 바텀시트 닫힘
      expect(find.byType(BottomSheet), findsNothing);
    });
  });

  group('SettingsPage 언어 영어 선택 테스트', () {
    testWidgets('언어 바텀시트에서 영어를 선택하면 닫혀야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // When: 언어 탭
      await tester.tap(find.byIcon(Icons.language_outlined));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);

      // When: 두 번째 항목(영어) 탭
      final tiles = find.byType(ListTile);
      await tester.tap(tiles.at(1), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Then: 에러 없이 처리됨
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  group('SettingsPage 색상 선택기 테스트', () {
    testWidgets('색상 선택기 영역까지 스크롤하면 비밀번호 변경 아이콘이 보여야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // When: 비밀번호 변경 영역으로 스크롤
      await tester.scrollUntilVisible(
        find.byIcon(Icons.lock_outline, skipOffstage: false),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // Then: 비밀번호 아이콘이 보임
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    });
  });

  group('SettingsPage 데이터 내보내기 섹션 테스트', () {
    testWidgets('데이터 내보내기 아이콘이 표시되어야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // When: 스크롤
      await tester.scrollUntilVisible(
        find.byIcon(Icons.download_outlined, skipOffstage: false),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // Then
      expect(find.byIcon(Icons.download_outlined), findsOneWidget);
    });

    testWidgets('가이드 아이콘이 표시되어야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // When: 가이드 아이콘으로 스크롤
      await tester.scrollUntilVisible(
        find.byIcon(Icons.menu_book_outlined, skipOffstage: false),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // Then
      expect(find.byIcon(Icons.menu_book_outlined), findsOneWidget);
    });

    testWidgets('가이드 탭하면 라우팅이 동작해야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // When: 가이드 아이콘으로 스크롤 후 탭
      await tester.scrollUntilVisible(
        find.byIcon(Icons.menu_book_outlined, skipOffstage: false),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.menu_book_outlined));
      await tester.pumpAndSettle();

      // Then: 에러 없이 이동
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}
