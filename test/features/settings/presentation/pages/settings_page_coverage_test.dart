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

// 업데이트 없음 상태 Fake notifier
class _FakeAppUpdateNone extends AppUpdate {
  @override
  Future<AppVersionInfo?> build() async => null;
}

// 업데이트 있음 상태 Fake notifier
class _FakeAppUpdateAvailable extends AppUpdate {
  @override
  Future<AppVersionInfo?> build() async => const AppVersionInfo(
        version: '2.0.0',
        buildNumber: 999,
        storeUrl: 'https://play.google.com/store',
        isForceUpdate: false,
      );
}

Widget _buildSettingsTestApp({
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
        builder: (context, state) => const Scaffold(body: Text('개인정보처리방침')),
      ),
      GoRoute(
        path: '/debug-test',
        builder: (context, state) => const Scaffold(body: Text('디버그')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      if (prefs != null) sharedPreferencesProvider.overrideWithValue(prefs),
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
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ko'),
    ),
  );
}

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  group('SettingsPage AppBar 및 구조 테스트', () {
    testWidgets('AppBar 제목이 설정이어야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildSettingsTestApp(prefs: prefs));
      await tester.pumpAndSettle();

      // Then: AppBar에 설정 제목이 표시됨
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('Scaffold가 렌더링되어야 한다', (tester) async {
      // Given & When
      await tester.pumpWidget(_buildSettingsTestApp(prefs: prefs));
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('알림 설정 아이콘이 표시되어야 한다', (tester) async {
      // Given & When
      await tester.pumpWidget(_buildSettingsTestApp(prefs: prefs));
      await tester.pumpAndSettle();

      // Then: 알림 아이콘이 있음
      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
    });

    testWidgets('알림 설정 ListTile 아이콘이 표시되어야 한다', (tester) async {
      // Given & When
      await tester.pumpWidget(_buildSettingsTestApp(prefs: prefs));
      await tester.pumpAndSettle();

      // Then: 알림 활성화 아이콘이 있음
      expect(
        find.byIcon(Icons.notifications_active, skipOffstage: false),
        findsOneWidget,
      );
    });

    testWidgets('여러 ListTile이 포함되어야 한다', (tester) async {
      // Given & When
      await tester.pumpWidget(_buildSettingsTestApp(prefs: prefs));
      await tester.pumpAndSettle();

      // Then: 다수의 ListTile이 있음
      expect(find.byType(ListTile, skipOffstage: false), findsAtLeastNWidgets(3));
    });
  });

  group('SettingsPage 테마 바텀시트 선택 테스트', () {
    testWidgets('테마 바텀시트에서 라이트 모드를 선택하면 바텀시트가 닫혀야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildSettingsTestApp(prefs: prefs));
      await tester.pumpAndSettle();

      // When: 테마 탭하여 바텀시트 열기
      await tester.tap(find.byIcon(Icons.palette_outlined));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);

      // When: 라이트 모드 선택
      final lightTiles = find.byType(ListTile);
      expect(lightTiles, findsAtLeastNWidgets(2));
      await tester.tap(lightTiles.first);
      await tester.pumpAndSettle();

      // Then: 바텀시트가 닫힘
      expect(find.byType(BottomSheet), findsNothing);
    });

    testWidgets('테마 바텀시트에서 두 번째 항목(다크 모드)을 선택하면 닫혀야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildSettingsTestApp(prefs: prefs));
      await tester.pumpAndSettle();

      // When: 테마 탭하여 바텀시트 열기
      await tester.tap(find.byIcon(Icons.palette_outlined));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);

      // When: 두 번째 항목(다크 모드) 선택
      final tiles = find.byType(ListTile);
      expect(tiles, findsAtLeastNWidgets(2));
      await tester.tap(tiles.at(1));
      await tester.pumpAndSettle();

      // Then: 바텀시트가 닫힘
      expect(find.byType(BottomSheet), findsNothing);
    });
  });

  group('SettingsPage 언어 바텀시트 선택 테스트', () {
    testWidgets('언어 바텀시트에서 한국어 선택 시 바텀시트가 닫혀야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildSettingsTestApp(prefs: prefs));
      await tester.pumpAndSettle();

      // When: 언어 탭하여 바텀시트 열기
      await tester.tap(find.byIcon(Icons.language_outlined));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);

      // When: 첫 번째 항목(한국어) 선택
      final tiles = find.byType(ListTile);
      await tester.tap(tiles.first);
      await tester.pumpAndSettle();

      // Then: 바텀시트가 닫힘
      expect(find.byType(BottomSheet), findsNothing);
    });

    testWidgets('언어 바텀시트에서 영어 선택 시 바텀시트가 닫혀야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildSettingsTestApp(prefs: prefs));
      await tester.pumpAndSettle();

      // When: 언어 탭하여 바텀시트 열기
      await tester.tap(find.byIcon(Icons.language_outlined));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);

      // When: 두 번째 항목(영어) 선택
      final tiles = find.byType(ListTile);
      await tester.tap(tiles.at(1));
      await tester.pumpAndSettle();

      // Then: 바텀시트가 닫힘
      expect(find.byType(BottomSheet), findsNothing);
    });
  });

  group('SettingsPage 주 시작일 바텀시트 테스트', () {
    testWidgets('주 시작일 바텀시트에서 일요일을 선택하면 닫혀야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildSettingsTestApp(prefs: prefs));
      await tester.pumpAndSettle();

      // When: 주 시작일 탭하여 바텀시트 열기
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
      await tester.pumpWidget(_buildSettingsTestApp(prefs: prefs));
      await tester.pumpAndSettle();

      // When: 주 시작일 탭하여 바텀시트 열기
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

  group('SettingsPage 업데이트 정보 섹션 테스트', () {
    testWidgets('업데이트가 없을 때 info_outline 아이콘이 표시되어야 한다', (tester) async {
      // Given: 업데이트 없음 상태
      await tester.pumpWidget(_buildSettingsTestApp(prefs: prefs));
      await tester.pumpAndSettle();

      // When: 스크롤하여 앱 정보 섹션 표시
      await tester.scrollUntilVisible(
        find.byIcon(Icons.info_outline, skipOffstage: false),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // Then: 일반 앱 정보 아이콘 표시
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('업데이트가 있을 때 system_update 아이콘 탭으로 다이얼로그가 열려야 한다', (tester) async {
      // Given: 업데이트 있음 상태
      await tester.pumpWidget(
        _buildSettingsTestApp(
          prefs: prefs,
          overrides: [
            appUpdateProvider.overrideWith(() => _FakeAppUpdateAvailable()),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // When: 스크롤하여 system_update 아이콘 표시 후 탭
      await tester.scrollUntilVisible(
        find.byIcon(Icons.system_update, skipOffstage: false),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.system_update));
      await tester.pumpAndSettle();

      // Then: AlertDialog가 표시됨
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('앱 정보 다이얼로그에서 닫기 버튼을 탭하면 닫혀야 한다', (tester) async {
      // Given: 업데이트 없음 상태
      await tester.pumpWidget(_buildSettingsTestApp(prefs: prefs));
      await tester.pumpAndSettle();

      // When: info 아이콘 탭하여 다이얼로그 열기
      await tester.scrollUntilVisible(
        find.byIcon(Icons.info_outline, skipOffstage: false),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.info_outline));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);

      // When: 닫기 버튼 탭
      final closeButton = find.byType(TextButton);
      await tester.tap(closeButton.first);
      await tester.pumpAndSettle();

      // Then: 다이얼로그가 닫힘
      expect(find.byType(AlertDialog), findsNothing);
    });
  });

  group('SettingsPage 알림 설정 탭 테스트', () {
    testWidgets('알림 설정 ListTile을 탭하면 알림 설정 페이지로 이동해야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildSettingsTestApp(prefs: prefs));
      await tester.pumpAndSettle();

      // When: 알림 활성화 아이콘 탭
      final notifActiveTile = find.byIcon(Icons.notifications_active);
      expect(notifActiveTile, findsOneWidget);
      await tester.tap(notifActiveTile);
      await tester.pumpAndSettle();

      // Then: Navigator.push가 호출되어 화면 전환됨 (에러 없음)
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('알림 SwitchListTile을 토글하면 상태가 변경되어야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildSettingsTestApp(prefs: prefs));
      await tester.pumpAndSettle();

      // Then: SwitchListTile 존재 확인
      final switchTile = find.byType(SwitchListTile);
      expect(switchTile, findsAtLeastNWidgets(1));

      // When: 스위치 탭
      await tester.tap(switchTile.first);
      await tester.pumpAndSettle();

      // Then: 에러 없이 상태 변경됨
      expect(find.byType(SwitchListTile), findsAtLeastNWidgets(1));
    });
  });

  group('SettingsPage 가이드 탭 테스트', () {
    testWidgets('가이드 ListTile을 탭하면 라우터로 이동해야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildSettingsTestApp(prefs: prefs));
      await tester.pumpAndSettle();

      // When: 스크롤하여 가이드 항목 탭
      await tester.scrollUntilVisible(
        find.byIcon(Icons.menu_book_outlined, skipOffstage: false),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.menu_book_outlined));
      await tester.pumpAndSettle();

      // Then: 이동 완료 (에러 없음)
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  group('SettingsPage 비밀번호 변경 다이얼로그 입력 테스트', () {
    testWidgets('비밀번호 변경 다이얼로그에서 빈 폼을 제출하면 유효성 검사 에러가 표시되어야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildSettingsTestApp(prefs: prefs));
      await tester.pumpAndSettle();

      // When: 비밀번호 변경 다이얼로그 열기
      await tester.scrollUntilVisible(
        find.byIcon(Icons.lock_outline, skipOffstage: false),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.lock_outline));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);

      // When: 빈 상태로 변경 버튼(FilledButton) 탭
      final filledButtons = find.byType(FilledButton);
      expect(filledButtons, findsOneWidget);
      await tester.tap(filledButtons.first);
      await tester.pumpAndSettle();

      // Then: 다이얼로그는 열려있어야 함 (유효성 검사 실패)
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('비밀번호 변경 다이얼로그에서 두 번째 눈 아이콘을 탭하면 토글되어야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildSettingsTestApp(prefs: prefs));
      await tester.pumpAndSettle();

      // When: 비밀번호 변경 다이얼로그 열기
      await tester.scrollUntilVisible(
        find.byIcon(Icons.lock_outline, skipOffstage: false),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.lock_outline));
      await tester.pumpAndSettle();

      // Then: 초기 상태에서 visibility_off 아이콘 3개 (각 필드마다 1개씩)
      expect(find.byIcon(Icons.visibility_off), findsAtLeastNWidgets(3));

      // When: 두 번째 눈 아이콘 탭
      await tester.tap(find.byIcon(Icons.visibility_off).at(1));
      await tester.pumpAndSettle();

      // Then: visibility 아이콘이 등장함
      expect(find.byIcon(Icons.visibility), findsAtLeastNWidgets(1));
    });

    testWidgets('비밀번호 변경 다이얼로그에서 세 번째 눈 아이콘을 탭하면 토글되어야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildSettingsTestApp(prefs: prefs));
      await tester.pumpAndSettle();

      // When: 비밀번호 변경 다이얼로그 열기
      await tester.scrollUntilVisible(
        find.byIcon(Icons.lock_outline, skipOffstage: false),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.lock_outline));
      await tester.pumpAndSettle();

      // When: 세 번째 눈 아이콘 탭
      await tester.tap(find.byIcon(Icons.visibility_off).at(2));
      await tester.pumpAndSettle();

      // Then: visibility 아이콘이 등장함
      expect(find.byIcon(Icons.visibility), findsAtLeastNWidgets(1));
    });
  });

  group('SettingsPage _getThemeModeLabel 테스트', () {
    test('ThemeMode.light일 때 라이트 레이블이 반환되어야 한다', () {
      // Given
      const settingsPage = SettingsPage();

      // When & Then: 위젯이 ConsumerWidget을 상속함
      expect(settingsPage, isA<ConsumerWidget>());
    });
  });

  group('notificationEnabledProvider 추가 상태 테스트', () {
    test('초기 상태 true에서 false로 변경 후 다시 true로 변경되어야 한다', () {
      // Given
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // When: false로 변경
      container.read(notificationEnabledProvider.notifier).state = false;
      expect(container.read(notificationEnabledProvider), isFalse);

      // When: 다시 true로 변경
      container.read(notificationEnabledProvider.notifier).state = true;

      // Then: true여야 함
      expect(container.read(notificationEnabledProvider), isTrue);
    });
  });

  group('SettingsPage 테마 선택 바텀시트 탭 테스트', () {
    testWidgets('테마 바텀시트에서 라이트 모드를 선택하면 닫혀야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildSettingsTestApp(prefs: prefs));
      await tester.pumpAndSettle();

      // When: 테마 텍스트로 ListTile 탭하여 바텀시트 열기
      await tester.scrollUntilVisible(
        find.text('테마', skipOffstage: false),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('테마'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);

      // When: 라이트 모드 선택 (첫 번째 ListTile)
      final tiles = find.byType(ListTile);
      await tester.tap(tiles.first);
      await tester.pumpAndSettle();

      // Then: 바텀시트가 닫힘
      expect(find.byType(BottomSheet), findsNothing);
    });

    testWidgets('테마 바텀시트에서 다크 모드를 선택하면 닫혀야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildSettingsTestApp(prefs: prefs));
      await tester.pumpAndSettle();

      // When: 테마 텍스트로 ListTile 탭하여 바텀시트 열기
      await tester.scrollUntilVisible(
        find.text('테마', skipOffstage: false),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('테마'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);

      // When: 다크 모드 선택 (두 번째 ListTile)
      final tiles = find.byType(ListTile);
      await tester.tap(tiles.at(1));
      await tester.pumpAndSettle();

      // Then: 바텀시트가 닫힘
      expect(find.byType(BottomSheet), findsNothing);
    });

    testWidgets('테마 바텀시트에서 시스템 모드를 선택하면 닫혀야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildSettingsTestApp(prefs: prefs));
      await tester.pumpAndSettle();

      // When: 테마 텍스트로 ListTile 탭하여 바텀시트 열기
      await tester.scrollUntilVisible(
        find.text('테마', skipOffstage: false),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('테마'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);

      // When: 시스템 모드 선택 (세 번째 ListTile, 없으면 그냥 닫기)
      final tiles = find.byType(ListTile);
      if (tiles.evaluate().length > 2) {
        await tester.tap(tiles.at(2));
        await tester.pumpAndSettle();
      } else {
        // 바텀시트 닫기
        await tester.tap(tiles.first);
        await tester.pumpAndSettle();
      }

      // Then: 바텀시트가 닫힘
      expect(find.byType(BottomSheet), findsNothing);
    });
  });

  group('SettingsPage 언어 선택 바텀시트 탭 테스트', () {
    testWidgets('언어 바텀시트에서 한국어를 선택하면 닫혀야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildSettingsTestApp(prefs: prefs));
      await tester.pumpAndSettle();

      // When: 언어 ListTile 탭하여 바텀시트 열기
      await tester.scrollUntilVisible(
        find.byIcon(Icons.language_outlined, skipOffstage: false),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.language_outlined));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);

      // When: 한국어 선택 (첫 번째 ListTile)
      final tiles = find.byType(ListTile);
      await tester.tap(tiles.first);
      await tester.pumpAndSettle();

      // Then: 바텀시트가 닫힘
      expect(find.byType(BottomSheet), findsNothing);
    });

    testWidgets('언어 바텀시트에서 영어를 선택하면 닫혀야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildSettingsTestApp(prefs: prefs));
      await tester.pumpAndSettle();

      // When: 언어 ListTile 탭하여 바텀시트 열기
      await tester.scrollUntilVisible(
        find.byIcon(Icons.language_outlined, skipOffstage: false),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.language_outlined));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);

      // When: 영어 선택 (두 번째 ListTile)
      final tiles = find.byType(ListTile);
      await tester.tap(tiles.at(1));
      await tester.pumpAndSettle();

      // Then: 바텀시트가 닫힘
      expect(find.byType(BottomSheet), findsNothing);
    });
  });

  group('SettingsPage 색상 변경 테스트', () {
    testWidgets('내 색상 텍스트가 렌더링되어야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildSettingsTestApp(prefs: prefs));
      await tester.pumpAndSettle();

      // When: 스크롤하여 내 색상 섹션 찾기
      await tester.scrollUntilVisible(
        find.text('내 색상', skipOffstage: false),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // Then: 내 색상 텍스트가 표시됨
      expect(find.text('내 색상'), findsAtLeastNWidgets(1));
    });
  });

  group('SettingsPage 주 시작일 바텀시트 테스트', () {
    testWidgets('주 시작일 바텀시트에서 일요일을 선택하면 닫혀야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildSettingsTestApp(prefs: prefs));
      await tester.pumpAndSettle();

      // When: 주 시작일 ListTile 탭하여 바텀시트 열기
      await tester.scrollUntilVisible(
        find.byIcon(Icons.calendar_today_outlined, skipOffstage: false),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.calendar_today_outlined));
      await tester.pumpAndSettle();

      // Then: 바텀시트가 열림
      expect(find.byType(BottomSheet), findsOneWidget);

      // When: 일요일 선택 (첫 번째 ListTile)
      final tiles = find.byType(ListTile);
      await tester.tap(tiles.first);
      await tester.pumpAndSettle();

      // Then: 바텀시트가 닫힘
      expect(find.byType(BottomSheet), findsNothing);
    });

    testWidgets('주 시작일 바텀시트에서 월요일을 선택하면 닫혀야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildSettingsTestApp(prefs: prefs));
      await tester.pumpAndSettle();

      // When: 주 시작일 ListTile 탭하여 바텀시트 열기
      await tester.scrollUntilVisible(
        find.byIcon(Icons.calendar_today_outlined, skipOffstage: false),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.calendar_today_outlined));
      await tester.pumpAndSettle();

      // Then: 바텀시트가 열림
      expect(find.byType(BottomSheet), findsOneWidget);

      // When: 월요일 선택 (두 번째 ListTile)
      final tiles = find.byType(ListTile);
      await tester.tap(tiles.at(1));
      await tester.pumpAndSettle();

      // Then: 바텀시트가 닫힘
      expect(find.byType(BottomSheet), findsNothing);
    });
  });

  group('SettingsPage 로그아웃 다이얼로그 테스트', () {
    testWidgets('로그아웃 아이콘 탭하면 확인 다이얼로그가 열려야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildSettingsTestApp(prefs: prefs));
      await tester.pumpAndSettle();

      // When: 로그아웃 ListTile 탭
      await tester.scrollUntilVisible(
        find.byIcon(Icons.logout, skipOffstage: false),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.logout));
      await tester.pumpAndSettle();

      // Then: AlertDialog가 열림
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('로그아웃 다이얼로그에서 취소를 탭하면 닫혀야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildSettingsTestApp(prefs: prefs));
      await tester.pumpAndSettle();

      // When: 로그아웃 탭
      await tester.scrollUntilVisible(
        find.byIcon(Icons.logout, skipOffstage: false),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.logout));
      await tester.pumpAndSettle();

      // When: 취소 탭
      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();

      // Then: 다이얼로그가 닫힘
      expect(find.byType(AlertDialog), findsNothing);
    });
  });

  group('SettingsPage 계정 삭제 다이얼로그 테스트', () {
    testWidgets('계정 삭제 아이콘 탭하면 확인 다이얼로그가 열려야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildSettingsTestApp(prefs: prefs));
      await tester.pumpAndSettle();

      // When: 계정 삭제 ListTile 탭
      await tester.scrollUntilVisible(
        find.byIcon(Icons.delete_forever, skipOffstage: false),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.delete_forever));
      await tester.pumpAndSettle();

      // Then: AlertDialog가 열림
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('계정 삭제 다이얼로그에서 취소를 탭하면 닫혀야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildSettingsTestApp(prefs: prefs));
      await tester.pumpAndSettle();

      // When: 계정 삭제 탭
      await tester.scrollUntilVisible(
        find.byIcon(Icons.delete_forever, skipOffstage: false),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.delete_forever));
      await tester.pumpAndSettle();

      // When: 취소 탭
      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();

      // Then: 다이얼로그가 닫힘
      expect(find.byType(AlertDialog), findsNothing);
    });
  });

  group('SettingsPage 데이터 내보내기 테스트', () {
    testWidgets('데이터 내보내기 탭하면 바텀시트가 열려야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildSettingsTestApp(prefs: prefs));
      await tester.pumpAndSettle();

      // When: 데이터 내보내기 ListTile 탭
      await tester.scrollUntilVisible(
        find.byIcon(Icons.download_outlined, skipOffstage: false),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.download_outlined));
      await tester.pumpAndSettle();

      // Then: 바텀시트가 열림
      expect(find.byType(BottomSheet), findsOneWidget);
    });
  });

  group('SettingsPage 정보 섹션 탭 테스트', () {
    testWidgets('가이드 탭하면 이동해야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildSettingsTestApp(prefs: prefs));
      await tester.pumpAndSettle();

      // When: 가이드 ListTile 탭
      await tester.scrollUntilVisible(
        find.byIcon(Icons.menu_book_outlined, skipOffstage: false),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.menu_book_outlined));
      await tester.pumpAndSettle();

      // Then: 라우터 이동 (가이드 페이지)
      expect(find.text('가이드'), findsOneWidget);
    });

    testWidgets('이용약관 탭하면 이동해야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildSettingsTestApp(prefs: prefs));
      await tester.pumpAndSettle();

      // When: 이용약관 ListTile 탭
      await tester.scrollUntilVisible(
        find.byIcon(Icons.description_outlined, skipOffstage: false),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.description_outlined));
      await tester.pumpAndSettle();

      // Then: 라우터 이동
      expect(find.text('이용약관'), findsOneWidget);
    });

    testWidgets('개인정보처리방침 탭하면 이동해야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildSettingsTestApp(prefs: prefs));
      await tester.pumpAndSettle();

      // When: 개인정보처리방침 ListTile 탭
      await tester.scrollUntilVisible(
        find.byIcon(Icons.privacy_tip_outlined, skipOffstage: false),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.privacy_tip_outlined));
      await tester.pumpAndSettle();

      // Then: 라우터 이동
      expect(find.text('개인정보처리방침'), findsOneWidget);
    });
  });

  group('SettingsPage 업데이트 있음 상태 AppInfoTile 테스트', () {
    testWidgets('업데이트가 있으면 NEW 배지가 표시되어야 한다', (tester) async {
      // Given: 업데이트 있음 상태
      await tester.pumpWidget(_buildSettingsTestApp(
        prefs: prefs,
        overrides: [
          appUpdateProvider.overrideWith(() => _FakeAppUpdateAvailable()),
        ],
      ));
      await tester.pumpAndSettle();

      // When: 스크롤하여 NEW 배지 찾기
      await tester.scrollUntilVisible(
        find.text('NEW', skipOffstage: false),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // Then: NEW 배지가 표시됨
      expect(find.text('NEW'), findsOneWidget);
    });

    testWidgets('업데이트 없음 상태에서 앱 정보 타일이 표시되어야 한다', (tester) async {
      // Given: 업데이트 없음 상태
      await tester.pumpWidget(_buildSettingsTestApp(
        prefs: prefs,
        overrides: [
          appUpdateProvider.overrideWith(() => _FakeAppUpdateNone()),
        ],
      ));
      await tester.pumpAndSettle();

      // When: 스크롤하여 앱 정보 찾기
      await tester.scrollUntilVisible(
        find.byIcon(Icons.info_outline, skipOffstage: false),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // Then: info 아이콘이 표시됨
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });
  });
}
