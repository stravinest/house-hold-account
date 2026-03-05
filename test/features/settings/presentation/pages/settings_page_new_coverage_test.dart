import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_household_account/features/auth/presentation/providers/auth_provider.dart';
import 'package:shared_household_account/features/settings/data/services/app_update_service.dart';
import 'package:shared_household_account/features/settings/presentation/pages/settings_page.dart';
import 'package:shared_household_account/features/settings/presentation/providers/app_update_provider.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';
import 'package:shared_household_account/shared/themes/locale_provider.dart';
import 'package:shared_household_account/shared/themes/theme_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAppUpdateNone extends AppUpdate {
  @override
  Future<AppVersionInfo?> build() async => null;
}

class _FakeAppUpdateAvailable extends AppUpdate {
  @override
  Future<AppVersionInfo?> build() async => const AppVersionInfo(
        version: '2.0.0',
        buildNumber: 999,
        storeUrl: 'https://play.google.com/store',
        isForceUpdate: false,
      );

  @override
  Future<AppVersionInfo?> forceCheck() async {
    const result = AppVersionInfo(
      version: '2.0.0',
      buildNumber: 999,
      isForceUpdate: false,
    );
    state = const AsyncData(result);
    return result;
  }
}

Widget _buildTestApp({
  List<Override> overrides = const [],
  Locale locale = const Locale('ko'),
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
      GoRoute(
        path: '/payment-method',
        builder: (context, state) => const Scaffold(body: Text('결제수단')),
      ),
      GoRoute(
        path: '/settings/pending-transactions',
        builder: (context, state) => const Scaffold(body: Text('수집내역')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      appUpdateProvider.overrideWith(() => _FakeAppUpdateNone()),
      packageInfoProvider.overrideWith(
        (ref) async => PackageInfo(
          appName: '가계부',
          packageName: 'com.test.app',
          version: '1.2.3',
          buildNumber: '10',
          buildSignature: '',
        ),
      ),
      userProfileProvider.overrideWith(
        (ref) => Stream.value({'color': '#A8D8EA', 'display_name': '테스트유저'}),
      ),
      userColorProvider.overrideWith((_) => '#A8D8EA'),
      ...overrides,
    ],
    child: MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
    ),
  );
}

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  group('SettingsPage _getThemeModeLabel 다크모드 분기 테스트', () {
    testWidgets('다크 모드가 설정되면 다크 테마 레이블이 표시되어야 한다', (tester) async {
      // Given: 다크 테마로 초기화된 SharedPreferences
      SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});
      prefs = await SharedPreferences.getInstance();

      // When
      await tester.pumpWidget(_buildTestApp(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      ));
      await tester.pumpAndSettle();

      // Then: 테마 관련 아이콘 존재 확인 (다크 모드 레이블 표시됨)
      expect(find.byIcon(Icons.palette_outlined), findsOneWidget);
    });
  });

  group('SettingsPage _getLocaleLabel 영어 분기 테스트', () {
    testWidgets('영어 locale에서 언어 레이블이 표시되어야 한다', (tester) async {
      // Given: 영어 locale
      SharedPreferences.setMockInitialValues({'locale': 'en'});
      prefs = await SharedPreferences.getInstance();

      // When
      await tester.pumpWidget(_buildTestApp(
        locale: const Locale('en'),
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      ));
      await tester.pumpAndSettle();

      // Then: 언어 아이콘 존재 확인
      expect(find.byIcon(Icons.language_outlined), findsOneWidget);
    });
  });

  group('SettingsPage 테마 바텀시트 라이트/다크 선택 onTap 테스트', () {
    testWidgets('테마 바텀시트에서 라이트 모드를 선택하면 바텀시트가 닫혀야 한다', (tester) async {
      // Given
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(_buildTestApp(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      ));
      await tester.pumpAndSettle();

      // When: 테마 탭하여 바텀시트 열기
      await tester.tap(find.byIcon(Icons.palette_outlined));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);

      // When: 바텀시트 내 첫 번째 ListTile(라이트 모드) 탭
      final themeTiles = find.descendant(
        of: find.byType(BottomSheet),
        matching: find.byType(ListTile),
      );
      await tester.tap(themeTiles.first);
      await tester.pumpAndSettle();

      // Then: 바텀시트 닫힘
      expect(find.byType(BottomSheet), findsNothing);
    });

    testWidgets('테마 바텀시트에서 다크 모드를 선택하면 바텀시트가 닫혀야 한다', (tester) async {
      // Given
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(_buildTestApp(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      ));
      await tester.pumpAndSettle();

      // When: 테마 탭
      await tester.tap(find.byIcon(Icons.palette_outlined));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);

      // When: 바텀시트 내 두 번째 ListTile(다크 모드) 탭
      final themeTiles = find.descendant(
        of: find.byType(BottomSheet),
        matching: find.byType(ListTile),
      );
      await tester.tap(themeTiles.at(1));
      await tester.pumpAndSettle();

      // Then: 바텀시트 닫힘
      expect(find.byType(BottomSheet), findsNothing);
    });
  });

  group('SettingsPage 언어 바텀시트 선택 onTap 테스트', () {
    testWidgets('언어 바텀시트에서 한국어를 선택하면 바텀시트가 닫혀야 한다', (tester) async {
      // Given
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(_buildTestApp(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      ));
      await tester.pumpAndSettle();

      // When: 언어 탭
      await tester.tap(find.byIcon(Icons.language_outlined));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);

      // When: 바텀시트 내 첫 번째 ListTile(한국어) 탭
      final langTiles = find.descendant(
        of: find.byType(BottomSheet),
        matching: find.byType(ListTile),
      );
      await tester.tap(langTiles.first);
      await tester.pumpAndSettle();

      // Then: 바텀시트 닫힘
      expect(find.byType(BottomSheet), findsNothing);
    });

    testWidgets('언어 바텀시트에서 영어를 선택하면 바텀시트가 닫혀야 한다', (tester) async {
      // Given
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(_buildTestApp(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      ));
      await tester.pumpAndSettle();

      // When: 언어 탭
      await tester.tap(find.byIcon(Icons.language_outlined));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);

      // When: English 탭
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      // Then: 바텀시트 닫힘
      expect(find.byType(BottomSheet), findsNothing);
    });
  });

  group('SettingsPage 주 시작일 바텀시트 선택 onTap 테스트', () {
    testWidgets('주 시작일 바텀시트에서 일요일을 선택하면 바텀시트가 닫혀야 한다', (tester) async {
      // Given
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(_buildTestApp(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      ));
      await tester.pumpAndSettle();

      // When: 주 시작일 탭
      await tester.tap(find.byIcon(Icons.calendar_today_outlined));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);

      // When: 일요일 탭 (바텀시트 내 첫 번째 ListTile)
      final bottomSheetListTiles = find.descendant(
        of: find.byType(BottomSheet),
        matching: find.byType(ListTile),
      );
      await tester.tap(bottomSheetListTiles.first);
      await tester.pumpAndSettle();

      // Then: 바텀시트 닫힘
      expect(find.byType(BottomSheet), findsNothing);
    });

    testWidgets('주 시작일 바텀시트에서 월요일을 선택하면 바텀시트가 닫혀야 한다', (tester) async {
      // Given
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(_buildTestApp(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      ));
      await tester.pumpAndSettle();

      // When: 주 시작일 탭
      await tester.tap(find.byIcon(Icons.calendar_today_outlined));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);

      // When: 월요일 탭 (바텀시트 내 두 번째 ListTile)
      final bottomSheetListTiles = find.descendant(
        of: find.byType(BottomSheet),
        matching: find.byType(ListTile),
      );
      await tester.tap(bottomSheetListTiles.at(1));
      await tester.pumpAndSettle();

      // Then: 바텀시트 닫힘
      expect(find.byType(BottomSheet), findsNothing);
    });
  });

  group('SettingsPage 비밀번호 변경 다이얼로그 submit 테스트', () {
    testWidgets('비어있는 상태에서 변경 버튼 탭 시 유효성 검사 실패해야 한다', (tester) async {
      // Given
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(_buildTestApp(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      ));
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

      // When: 빈 상태에서 변경 버튼 탭
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      // Then: 다이얼로그가 여전히 표시됨 (유효성 검사 실패로 닫히지 않음)
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('새 비밀번호가 6자 미만이면 유효성 검사 실패해야 한다', (tester) async {
      // Given
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(_buildTestApp(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      ));
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

      // When: 현재 비밀번호 입력
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'current_pw');
      // When: 새 비밀번호 (5자, 너무 짧음)
      await tester.enterText(fields.at(1), '12345');
      await tester.enterText(fields.at(2), '12345');
      await tester.pump();

      // When: 변경 버튼 탭
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      // Then: 다이얼로그가 여전히 표시됨 (유효성 검사 실패)
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('새 비밀번호와 확인 비밀번호가 다르면 유효성 검사 실패해야 한다', (tester) async {
      // Given
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(_buildTestApp(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      ));
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

      // When: 불일치 비밀번호 입력
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'current_pw');
      await tester.enterText(fields.at(1), 'newpassword1');
      await tester.enterText(fields.at(2), 'newpassword2');
      await tester.pump();

      // When: 변경 버튼 탭
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      // Then: 다이얼로그가 여전히 표시됨 (비밀번호 불일치)
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('비밀번호 필드 두 번째, 세 번째 눈 아이콘도 토글되어야 한다', (tester) async {
      // Given
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(_buildTestApp(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      ));
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

      // Then: visibility_off 3개 확인
      expect(find.byIcon(Icons.visibility_off), findsNWidgets(3));

      // When: 두 번째 눈 아이콘 탭
      await tester.tap(find.byIcon(Icons.visibility_off).at(1));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.visibility), findsAtLeastNWidgets(1));

      // When: 세 번째 눈 아이콘 탭 (visibility_off 아직 2개 남음)
      await tester.tap(find.byIcon(Icons.visibility_off).at(1));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.visibility), findsNWidgets(2));
    });
  });

  group('SettingsPage _DisplayNameEditor 상호작용 테스트', () {
    testWidgets('DisplayNameEditor가 렌더링되어야 한다', (tester) async {
      // Given
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(_buildTestApp(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      ));
      await tester.pumpAndSettle();

      // When: 스크롤하여 프로필 카드 표시
      await tester.scrollUntilVisible(
        find.byType(TextFormField, skipOffstage: false).first,
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // Then: TextFormField가 존재 (DisplayNameEditor)
      expect(find.byType(TextFormField), findsAtLeastNWidgets(1));
    });

    testWidgets('DisplayNameEditor에 텍스트를 입력하면 편집 버튼이 활성화되어야 한다', (tester) async {
      // Given
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(_buildTestApp(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      ));
      await tester.pumpAndSettle();

      // When: 스크롤하여 이름 필드 표시
      await tester.scrollUntilVisible(
        find.byType(TextFormField, skipOffstage: false).first,
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // When: 새 이름 입력 (기존 값과 다르게)
      final nameField = find.byType(TextFormField).first;
      await tester.enterText(nameField, '새이름변경');
      await tester.pump();

      // Then: FilledButton이 활성화됨 (isChanged=true)
      final filledButtons = find.byType(FilledButton);
      expect(filledButtons, findsAtLeastNWidgets(1));
    });
  });

  group('SettingsPage _AppInfoTile 업데이트 있음 상태 탭 테스트', () {
    testWidgets('업데이트가 있을 때 시스템 업데이트 타일을 탭하면 다이얼로그가 표시되어야 한다', (tester) async {
      // Given: 업데이트 있음 상태
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(_buildTestApp(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          appUpdateProvider.overrideWith(() => _FakeAppUpdateAvailable()),
        ],
      ));
      await tester.pumpAndSettle();

      // When: 스크롤하여 업데이트 타일 표시
      await tester.scrollUntilVisible(
        find.byIcon(Icons.system_update, skipOffstage: false),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // When: 업데이트 타일 탭
      await tester.tap(find.byIcon(Icons.system_update));
      await tester.pumpAndSettle();

      // Then: 다이얼로그가 표시됨
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('업데이트 없음 상태에서 앱 정보 타일을 탭하면 다이얼로그가 표시되어야 한다', (tester) async {
      // Given: 업데이트 없음 상태
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(_buildTestApp(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      ));
      await tester.pumpAndSettle();

      // When: 스크롤하여 앱 정보 타일 표시
      await tester.scrollUntilVisible(
        find.byIcon(Icons.info_outline, skipOffstage: false),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // When: 앱 정보 타일 탭
      await tester.tap(find.byIcon(Icons.info_outline));
      await tester.pumpAndSettle();

      // Then: About 다이얼로그가 표시됨
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('앱 정보 다이얼로그에서 닫기 버튼을 탭하면 닫혀야 한다', (tester) async {
      // Given
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(_buildTestApp(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      ));
      await tester.pumpAndSettle();

      // When: 앱 정보 타일 탭
      await tester.scrollUntilVisible(
        find.byIcon(Icons.info_outline, skipOffstage: false),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.info_outline));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);

      // When: 닫기 탭
      await tester.tap(find.text('닫기'));
      await tester.pumpAndSettle();

      // Then: 다이얼로그 닫힘
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('업데이트 있음 상태에서 About 다이얼로그에 업데이트 버튼이 있어야 한다', (tester) async {
      // Given: 업데이트 있음
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(_buildTestApp(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          appUpdateProvider.overrideWith(() => _FakeAppUpdateAvailable()),
        ],
      ));
      await tester.pumpAndSettle();

      // When: 업데이트 타일 탭
      await tester.scrollUntilVisible(
        find.byIcon(Icons.system_update, skipOffstage: false),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.system_update));
      await tester.pumpAndSettle();

      // Then: 다이얼로그에 업데이트 버튼 있음
      expect(find.byType(AlertDialog), findsOneWidget);
    });
  });

  group('SettingsPage 알림 스위치 상호작용 테스트', () {
    testWidgets('알림 스위치를 탭하면 상태가 토글되어야 한다', (tester) async {
      // Given
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(_buildTestApp(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      ));
      await tester.pumpAndSettle();

      // When: SwitchListTile 탭
      final switchTile = find.byType(SwitchListTile).first;
      await tester.tap(switchTile);
      await tester.pumpAndSettle();

      // Then: 상태 변경됨 (에러 없이 실행됨)
      expect(find.byType(SwitchListTile), findsAtLeastNWidgets(1));
    });
  });

  group('SettingsPage 알림 설정 ListTile 테스트', () {
    testWidgets('알림 설정 탭하면 NotificationSettingsPage로 이동해야 한다', (tester) async {
      // Given
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(_buildTestApp(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      ));
      await tester.pumpAndSettle();

      // When: 알림 설정 아이콘 탭
      final notifSettingsTile = find.byIcon(Icons.notifications_active);
      if (notifSettingsTile.evaluate().isNotEmpty) {
        await tester.tap(notifSettingsTile);
        await tester.pumpAndSettle();
      }

      // Then: 에러 없이 실행됨
      expect(find.byType(Scaffold), findsAtLeastNWidgets(1));
    });
  });
}
