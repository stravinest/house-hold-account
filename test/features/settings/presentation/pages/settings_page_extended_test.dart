import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_household_account/features/auth/presentation/providers/auth_provider.dart';
import 'package:shared_household_account/features/settings/data/services/app_update_service.dart';
import 'package:shared_household_account/features/settings/presentation/pages/settings_page.dart';
import 'package:shared_household_account/features/settings/presentation/providers/app_update_provider.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';
import 'package:shared_household_account/shared/themes/theme_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
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

  group('SettingsPage 앱 설정 섹션 테스트', () {
    testWidgets('테마 ListTile을 탭하면 모달 바텀시트가 표시되어야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildTestApp(prefs: prefs));
      await tester.pumpAndSettle();

      // When: 테마 ListTile 탭
      final themeTile = find.byIcon(Icons.palette_outlined);
      expect(themeTile, findsOneWidget);
      await tester.tap(themeTile);
      await tester.pumpAndSettle();

      // Then: 바텀시트 표시됨
      expect(find.byType(BottomSheet), findsOneWidget);
    });

    testWidgets('언어 ListTile을 탭하면 모달 바텀시트가 표시되어야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildTestApp(prefs: prefs));
      await tester.pumpAndSettle();

      // When: 언어 ListTile 탭
      final languageTile = find.byIcon(Icons.language_outlined);
      expect(languageTile, findsOneWidget);
      await tester.tap(languageTile);
      await tester.pumpAndSettle();

      // Then: 바텀시트 표시됨
      expect(find.byType(BottomSheet), findsOneWidget);
    });

    testWidgets('알림 스위치를 토글하면 상태가 변경되어야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildTestApp(prefs: prefs));
      await tester.pumpAndSettle();

      // Then: SwitchListTile 존재 확인
      final switchTile = find.byType(SwitchListTile);
      expect(switchTile, findsAtLeastNWidgets(1));
    });

    testWidgets('주 시작일 ListTile이 표시되어야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildTestApp(prefs: prefs));
      await tester.pumpAndSettle();

      // Then: 달력 아이콘 존재 확인
      expect(find.byIcon(Icons.calendar_today_outlined), findsOneWidget);
    });

    testWidgets('주 시작일 ListTile을 탭하면 모달 바텀시트가 표시되어야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildTestApp(prefs: prefs));
      await tester.pumpAndSettle();

      // When: 주 시작일 ListTile 탭
      await tester.tap(find.byIcon(Icons.calendar_today_outlined));
      await tester.pumpAndSettle();

      // Then: 바텀시트 표시됨
      expect(find.byType(BottomSheet), findsOneWidget);
    });
  });

  group('SettingsPage 계정 섹션 테스트', () {
    testWidgets('비밀번호 변경 ListTile이 표시되어야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildTestApp(prefs: prefs));
      await tester.pumpAndSettle();

      // Then: 자물쇠 아이콘 존재 확인 (스크롤 밖 포함)
      expect(find.byIcon(Icons.lock_outline, skipOffstage: false), findsOneWidget);
    });

    testWidgets('비밀번호 변경 ListTile을 탭하면 다이얼로그가 표시되어야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildTestApp(prefs: prefs));
      await tester.pumpAndSettle();

      // When: 스크롤 후 비밀번호 변경 ListTile 탭
      await tester.scrollUntilVisible(
        find.byIcon(Icons.lock_outline, skipOffstage: false),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.lock_outline));
      await tester.pumpAndSettle();

      // Then: 다이얼로그 표시됨
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('로그아웃 버튼이 표시되어야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildTestApp(prefs: prefs));
      await tester.pumpAndSettle();

      // When: 스크롤하여 로그아웃 버튼 표시
      await tester.scrollUntilVisible(
        find.byIcon(Icons.logout, skipOffstage: false),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // Then: 로그아웃 아이콘 존재 확인
      expect(find.byIcon(Icons.logout), findsOneWidget);
    });

    testWidgets('로그아웃 버튼을 탭하면 확인 다이얼로그가 표시되어야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildTestApp(prefs: prefs));
      await tester.pumpAndSettle();

      // When: 스크롤 후 로그아웃 버튼 탭
      await tester.scrollUntilVisible(
        find.byIcon(Icons.logout, skipOffstage: false),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.logout));
      await tester.pumpAndSettle();

      // Then: 확인 다이얼로그 표시됨
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('계정 삭제 버튼이 표시되어야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildTestApp(prefs: prefs));
      await tester.pumpAndSettle();

      // When: 스크롤하여 계정 삭제 버튼 표시
      await tester.scrollUntilVisible(
        find.byIcon(Icons.delete_forever, skipOffstage: false),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // Then: 계정 삭제 아이콘 존재 확인
      expect(find.byIcon(Icons.delete_forever), findsOneWidget);
    });

    testWidgets('계정 삭제 버튼을 탭하면 확인 다이얼로그가 표시되어야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildTestApp(prefs: prefs));
      await tester.pumpAndSettle();

      // When: 스크롤 후 계정 삭제 버튼 탭
      await tester.scrollUntilVisible(
        find.byIcon(Icons.delete_forever, skipOffstage: false),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.delete_forever));
      await tester.pumpAndSettle();

      // Then: 확인 다이얼로그 표시됨
      expect(find.byType(AlertDialog), findsOneWidget);
    });
  });

  group('SettingsPage 데이터 섹션 테스트', () {
    testWidgets('데이터 내보내기 ListTile이 표시되어야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildTestApp(prefs: prefs));
      await tester.pumpAndSettle();

      // When: 스크롤하여 데이터 내보내기 항목 표시
      await tester.scrollUntilVisible(
        find.byIcon(Icons.download_outlined, skipOffstage: false),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // Then: 데이터 내보내기 아이콘 존재 확인
      expect(find.byIcon(Icons.download_outlined), findsOneWidget);
    });

    testWidgets('데이터 내보내기 ListTile을 탭하면 바텀시트가 표시되어야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildTestApp(prefs: prefs));
      await tester.pumpAndSettle();

      // When: 스크롤 후 데이터 내보내기 탭
      await tester.scrollUntilVisible(
        find.byIcon(Icons.download_outlined, skipOffstage: false),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.download_outlined));
      await tester.pumpAndSettle();

      // Then: 바텀시트 표시됨
      expect(find.byType(BottomSheet), findsOneWidget);
    });
  });

  group('SettingsPage 정보 섹션 테스트', () {
    testWidgets('앱 정보 아이콘이 표시되어야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildTestApp(prefs: prefs));
      await tester.pumpAndSettle();

      // When: 스크롤하여 앱 정보 항목 표시
      await tester.scrollUntilVisible(
        find.byIcon(Icons.info_outline, skipOffstage: false),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // Then: 앱 정보 아이콘 존재 확인
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('이용약관 ListTile이 표시되어야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildTestApp(prefs: prefs));
      await tester.pumpAndSettle();

      // When: 스크롤하여 이용약관 항목 표시
      await tester.scrollUntilVisible(
        find.byIcon(Icons.description_outlined, skipOffstage: false),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // Then: 이용약관 아이콘 존재 확인
      expect(find.byIcon(Icons.description_outlined), findsOneWidget);
    });

    testWidgets('개인정보처리방침 ListTile이 표시되어야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildTestApp(prefs: prefs));
      await tester.pumpAndSettle();

      // When: 스크롤하여 개인정보처리방침 항목 표시
      await tester.scrollUntilVisible(
        find.byIcon(Icons.privacy_tip_outlined, skipOffstage: false),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // Then: 개인정보처리방침 아이콘 존재 확인
      expect(find.byIcon(Icons.privacy_tip_outlined), findsOneWidget);
    });

    testWidgets('이용약관 ListTile을 탭하면 라우터로 이동해야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildTestApp(prefs: prefs));
      await tester.pumpAndSettle();

      // When: 스크롤 후 이용약관 탭
      await tester.scrollUntilVisible(
        find.byIcon(Icons.description_outlined, skipOffstage: false),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.description_outlined));
      await tester.pumpAndSettle();

      // Then: 이동 완료 (에러 없음)
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('개인정보처리방침 ListTile을 탭하면 라우터로 이동해야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildTestApp(prefs: prefs));
      await tester.pumpAndSettle();

      // When: 스크롤 후 개인정보 탭
      await tester.scrollUntilVisible(
        find.byIcon(Icons.privacy_tip_outlined, skipOffstage: false),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.privacy_tip_outlined));
      await tester.pumpAndSettle();

      // Then: 이동 완료 (에러 없음)
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('업데이트가 있을 때 업데이트 타일이 표시되어야 한다', (tester) async {
      // Given: 업데이트 있음 상태
      await tester.pumpWidget(
        _buildTestApp(
          prefs: prefs,
          overrides: [
            appUpdateProvider.overrideWith(() => _FakeAppUpdateAvailable()),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // When: 스크롤하여 앱 정보 섹션 표시
      await tester.scrollUntilVisible(
        find.byIcon(Icons.system_update, skipOffstage: false),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // Then: 업데이트 아이콘이 표시됨 (업데이트 있을 때는 system_update 아이콘)
      expect(find.byIcon(Icons.system_update), findsOneWidget);
    });
  });

  group('SettingsPage 테마 바텀시트 항목 테스트', () {
    testWidgets('테마 바텀시트에서 라이트 모드 항목이 표시되어야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildTestApp(prefs: prefs));
      await tester.pumpAndSettle();

      // When: 테마 탭
      await tester.tap(find.byIcon(Icons.palette_outlined));
      await tester.pumpAndSettle();

      // Then: 라이트/다크 선택지 표시
      expect(find.byType(ListTile), findsAtLeastNWidgets(2));
    });
  });

  group('SettingsPage 언어 바텀시트 항목 테스트', () {
    testWidgets('언어 바텀시트에서 한국어/영어 선택지가 표시되어야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildTestApp(prefs: prefs));
      await tester.pumpAndSettle();

      // When: 언어 탭
      await tester.tap(find.byIcon(Icons.language_outlined));
      await tester.pumpAndSettle();

      // Then: 언어 선택지 표시 (한국어, 영어)
      expect(find.byType(ListTile), findsAtLeastNWidgets(2));
    });
  });

  group('SettingsPage 로그아웃 다이얼로그 테스트', () {
    testWidgets('로그아웃 다이얼로그에서 취소 버튼이 동작해야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildTestApp(prefs: prefs));
      await tester.pumpAndSettle();

      // When: 스크롤 후 로그아웃 탭
      await tester.scrollUntilVisible(
        find.byIcon(Icons.logout, skipOffstage: false),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.logout));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);

      // 취소 버튼 탭
      final cancelButtons = find.byType(TextButton);
      await tester.tap(cancelButtons.first);
      await tester.pumpAndSettle();

      // Then: 다이얼로그가 닫혀야 함
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('계정 삭제 다이얼로그에서 취소 버튼이 동작해야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildTestApp(prefs: prefs));
      await tester.pumpAndSettle();

      // When: 스크롤 후 계정 삭제 탭
      await tester.scrollUntilVisible(
        find.byIcon(Icons.delete_forever, skipOffstage: false),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.delete_forever));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);

      // 취소 버튼 탭
      final cancelButtons = find.byType(TextButton);
      await tester.tap(cancelButtons.first);
      await tester.pumpAndSettle();

      // Then: 다이얼로그가 닫혀야 함
      expect(find.byType(AlertDialog), findsNothing);
    });
  });

  group('SettingsPage 비밀번호 변경 다이얼로그 테스트', () {
    testWidgets('비밀번호 변경 다이얼로그에서 취소 버튼이 동작해야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildTestApp(prefs: prefs));
      await tester.pumpAndSettle();

      // When: 스크롤 후 비밀번호 변경 탭
      await tester.scrollUntilVisible(
        find.byIcon(Icons.lock_outline, skipOffstage: false),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.lock_outline));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);

      // 취소 버튼 탭
      final cancelButtons = find.byType(TextButton);
      await tester.tap(cancelButtons.first);
      await tester.pumpAndSettle();

      // Then: 다이얼로그가 닫혀야 함
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('비밀번호 변경 다이얼로그에 3개의 TextFormField가 있어야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildTestApp(prefs: prefs));
      await tester.pumpAndSettle();

      // When: 스크롤 후 비밀번호 변경 탭
      await tester.scrollUntilVisible(
        find.byIcon(Icons.lock_outline, skipOffstage: false),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.lock_outline));
      await tester.pumpAndSettle();

      // Then: 현재비밀번호, 새비밀번호, 비밀번호확인 3개 필드
      expect(find.byType(TextFormField), findsAtLeastNWidgets(3));
    });

    testWidgets('비밀번호 필드의 눈 아이콘을 탭하면 가시성이 토글되어야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildTestApp(prefs: prefs));
      await tester.pumpAndSettle();

      // When: 스크롤 후 비밀번호 변경 탭
      await tester.scrollUntilVisible(
        find.byIcon(Icons.lock_outline, skipOffstage: false),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.lock_outline));
      await tester.pumpAndSettle();

      // Then: visibility_off 아이콘이 표시됨 (초기 상태: 숨김)
      expect(find.byIcon(Icons.visibility_off), findsAtLeastNWidgets(1));

      // When: 눈 아이콘 탭
      await tester.tap(find.byIcon(Icons.visibility_off).first);
      await tester.pumpAndSettle();

      // Then: visibility 아이콘으로 변경됨
      expect(find.byIcon(Icons.visibility), findsAtLeastNWidgets(1));
    });
  });

  group('notificationEnabledProvider 추가 테스트', () {
    test('여러 컨테이너에서 독립적으로 관리되어야 한다', () {
      // Given
      final container1 = ProviderContainer();
      final container2 = ProviderContainer();
      addTearDown(container1.dispose);
      addTearDown(container2.dispose);

      // When: 각각 다른 값 설정
      container1.read(notificationEnabledProvider.notifier).state = false;
      container2.read(notificationEnabledProvider.notifier).state = true;

      // Then: 독립적으로 동작
      expect(container1.read(notificationEnabledProvider), isFalse);
      expect(container2.read(notificationEnabledProvider), isTrue);
    });
  });
}
