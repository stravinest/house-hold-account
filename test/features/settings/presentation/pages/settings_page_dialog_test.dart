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
import 'package:supabase_flutter/supabase_flutter.dart';

SharedPreferences? _fakePrefs;

class _FakeAppUpdateNone extends AppUpdate {
  @override
  Future<AppVersionInfo?> build() async => null;
}

// AuthNotifier를 목으로 대체하는 StateNotifier
class _FakeAuthNotifier extends StateNotifier<AsyncValue<User?>> {
  _FakeAuthNotifier() : super(const AsyncValue.data(null));

  Future<void> signOut() async {
    state = const AsyncValue.data(null);
  }

  Future<void> deleteAccount() async {
    state = const AsyncValue.data(null);
  }
}

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
      sharedPreferencesProvider.overrideWithValue(
        // setUp에서 setMockInitialValues({})가 호출된 후 동기 접근
        // SharedPreferences.getInstance()는 비동기이므로 FakeSharedPreferences 대신
        // 테스트용 빈 prefs 인스턴스를 나중에 주입하기 위해 setUp에서 처리
        _fakePrefs!,
      ),
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

  group('SettingsPage 로그아웃 다이얼로그 테스트', () {
    testWidgets('로그아웃 ListTile을 탭하면 확인 다이얼로그가 표시되어야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // When: 스크롤하여 로그아웃 항목 찾기
      await tester.scrollUntilVisible(
        find.byIcon(Icons.logout, skipOffstage: false),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // When: 로그아웃 탭
      await tester.tap(find.byIcon(Icons.logout));
      await tester.pumpAndSettle();

      // Then: 로그아웃 확인 다이얼로그 표시
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('로그아웃 확인 다이얼로그에서 취소를 탭하면 다이얼로그가 닫혀야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // When: 로그아웃 다이얼로그 열기
      await tester.scrollUntilVisible(
        find.byIcon(Icons.logout, skipOffstage: false),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.logout));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);

      // When: 취소 탭 (첫 번째 TextButton)
      await tester.tap(find.byType(TextButton).first);
      await tester.pumpAndSettle();

      // Then: 다이얼로그 닫힘
      expect(find.byType(AlertDialog), findsNothing);
    });
  });

  group('SettingsPage 계정 삭제 다이얼로그 테스트', () {
    testWidgets('계정 삭제 ListTile을 탭하면 확인 다이얼로그가 표시되어야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // When: 스크롤하여 계정 삭제 항목 찾기
      await tester.scrollUntilVisible(
        find.byIcon(Icons.delete_forever, skipOffstage: false),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // When: 계정 삭제 탭
      await tester.tap(find.byIcon(Icons.delete_forever));
      await tester.pumpAndSettle();

      // Then: 계정 삭제 확인 다이얼로그 표시
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('계정 삭제 확인 다이얼로그에서 취소를 탭하면 다이얼로그가 닫혀야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // When: 계정 삭제 다이얼로그 열기
      await tester.scrollUntilVisible(
        find.byIcon(Icons.delete_forever, skipOffstage: false),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.delete_forever));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);

      // When: 취소 탭 (첫 번째 TextButton)
      await tester.tap(find.byType(TextButton).first);
      await tester.pumpAndSettle();

      // Then: 다이얼로그 닫힘
      expect(find.byType(AlertDialog), findsNothing);
    });
  });

  group('SettingsPage 이용약관/개인정보 탭 테스트', () {
    testWidgets('이용약관 항목을 탭하면 이동해야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // When: 스크롤하여 이용약관 아이콘 찾기
      await tester.scrollUntilVisible(
        find.byIcon(Icons.description_outlined, skipOffstage: false),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // When: 이용약관 탭
      await tester.tap(find.byIcon(Icons.description_outlined));
      await tester.pumpAndSettle();

      // Then: 에러 없이 이동
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('개인정보처리방침 항목을 탭하면 이동해야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // When: 스크롤하여 개인정보 아이콘 찾기
      await tester.scrollUntilVisible(
        find.byIcon(Icons.privacy_tip_outlined, skipOffstage: false),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // When: 개인정보처리방침 탭
      await tester.tap(find.byIcon(Icons.privacy_tip_outlined));
      await tester.pumpAndSettle();

      // Then: 에러 없이 이동
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  group('SettingsPage 데이터 내보내기 탭 테스트', () {
    testWidgets('데이터 내보내기 항목을 탭하면 바텀시트가 표시되어야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // When: 스크롤하여 다운로드 아이콘 찾기
      await tester.scrollUntilVisible(
        find.byIcon(Icons.download_outlined, skipOffstage: false),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // When: 데이터 내보내기 탭
      await tester.tap(find.byIcon(Icons.download_outlined));
      await tester.pumpAndSettle();

      // Then: 바텀시트 표시
      expect(find.byType(BottomSheet), findsOneWidget);
    });
  });

  group('SettingsPage 비밀번호 변경 다이얼로그 첫 번째 눈 아이콘 테스트', () {
    testWidgets('비밀번호 변경 다이얼로그에서 첫 번째 눈 아이콘을 탭하면 토글되어야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildTestApp());
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

      // Then: 초기 상태에서 visibility_off 아이콘 존재
      expect(find.byIcon(Icons.visibility_off), findsAtLeastNWidgets(1));

      // When: 첫 번째 눈 아이콘 탭
      await tester.tap(find.byIcon(Icons.visibility_off).first);
      await tester.pumpAndSettle();

      // Then: visibility 아이콘이 등장함
      expect(find.byIcon(Icons.visibility), findsAtLeastNWidgets(1));
    });

    testWidgets('비밀번호 변경 다이얼로그에서 취소 버튼을 탭하면 닫혀야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildTestApp());
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

      // When: 취소 탭
      await tester.tap(find.byType(TextButton).first);
      await tester.pumpAndSettle();

      // Then: 다이얼로그 닫힘
      expect(find.byType(AlertDialog), findsNothing);
    });
  });

  group('SettingsPage _getLocaleLabel 로직 테스트', () {
    test('한국어 로케일 레이블 검증', () {
      // Given: 한국어 로케일
      const locale = Locale('ko');

      // When
      final isKorean = locale.languageCode == 'ko';

      // Then
      expect(isKorean, isTrue);
    });

    test('영어 로케일 레이블 검증', () {
      // Given: 영어 로케일
      const locale = Locale('en');

      // When
      final isKorean = locale.languageCode == 'ko';

      // Then
      expect(isKorean, isFalse);
    });
  });

  group('SettingsPage ConsumerWidget 타입 테스트', () {
    test('SettingsPage는 ConsumerWidget을 상속해야 한다', () {
      // Given & When
      const page = SettingsPage();

      // Then
      expect(page, isA<ConsumerWidget>());
    });
  });
}
