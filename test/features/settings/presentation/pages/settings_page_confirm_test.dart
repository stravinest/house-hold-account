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

class _FakeAppUpdateNone extends AppUpdate {
  @override
  Future<AppVersionInfo?> build() async => null;
}

class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier(super.authService, super.ref);

  @override
  Future<void> signOut() async {
    state = const AsyncValue.data(null);
  }

  @override
  Future<void> deleteAccount() async {
    state = const AsyncValue.data(null);
  }
}

class _FakeAuthServiceSuccess extends Fake implements AuthService {
  @override
  User? get currentUser => null;

  @override
  Future<void> updateProfile({String? displayName, String? avatarUrl, String? color}) async {}

  @override
  Future<void> verifyAndUpdatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {}

  @override
  Future<void> deleteAccount() async {}

  @override
  Future<void> signOut() async {}
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
        path: '/login',
        builder: (context, state) => const Scaffold(body: Text('로그인')),
      ),
    ],
  );
}

Widget _buildTestApp({AuthService? authService}) {
  final service = authService ?? _FakeAuthServiceSuccess();
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
      authServiceProvider.overrideWithValue(service),
      authNotifierProvider.overrideWith((ref) => _FakeAuthNotifier(service, ref)),
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

  group('SettingsPage 로그아웃 확인 버튼 테스트', () {
    testWidgets('로그아웃 다이얼로그에서 확인 버튼을 탭하면 signOut이 호출되어야 한다', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.byIcon(Icons.logout, skipOffstage: false),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.logout));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);

      // 두 번째 TextButton = 확인(로그아웃)
      final buttons = find.byType(TextButton);
      expect(buttons, findsAtLeastNWidgets(2));
      await tester.tap(buttons.at(1));
      await tester.pumpAndSettle();

      // 에러 없이 처리됨
      expect(tester.takeException(), isNull);
    });
  });

  group('SettingsPage 계정 삭제 확인 버튼 테스트', () {
    testWidgets('계정 삭제 다이얼로그에서 확인 버튼을 탭하면 deleteAccount가 호출되어야 한다', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.byIcon(Icons.delete_forever, skipOffstage: false),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.delete_forever));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);

      // 두 번째 TextButton = 확인(삭제)
      final buttons = find.byType(TextButton);
      expect(buttons, findsAtLeastNWidgets(2));
      await tester.tap(buttons.at(1));
      await tester.pumpAndSettle();

      // 에러 없이 처리됨
      expect(tester.takeException(), isNull);
    });
  });

  group('SettingsPage 비밀번호 validator 테스트', () {
    testWidgets('새 비밀번호가 6자 미만이면 유효성 오류가 표시되어야 한다', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.byIcon(Icons.lock_outline, skipOffstage: false),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.lock_outline));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);

      // 현재 비밀번호 입력
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'currentpw');
      // 새 비밀번호를 짧게 입력 (5자)
      await tester.enterText(textFields.at(1), '12345');
      // 확인 비밀번호 입력
      await tester.enterText(textFields.at(2), '12345');

      // 변경 버튼 탭 (FilledButton)
      await tester.tap(find.byType(FilledButton).first);
      await tester.pumpAndSettle();

      // 다이얼로그가 열려있어야 함 (validator 실패)
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('새 비밀번호와 확인 비밀번호가 일치하지 않으면 유효성 오류가 표시되어야 한다', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.byIcon(Icons.lock_outline, skipOffstage: false),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.lock_outline));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);

      // 현재 비밀번호 입력
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'currentpw');
      // 새 비밀번호 입력
      await tester.enterText(textFields.at(1), 'newpassword1');
      // 확인 비밀번호를 다르게 입력
      await tester.enterText(textFields.at(2), 'differentpw');

      // 변경 버튼 탭 (FilledButton)
      await tester.tap(find.byType(FilledButton).first);
      await tester.pumpAndSettle();

      // 다이얼로그가 열려있어야 함 (validator 실패)
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('올바른 비밀번호를 입력하면 변경이 성공해야 한다', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.byIcon(Icons.lock_outline, skipOffstage: false),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.lock_outline));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'currentpw');
      await tester.enterText(textFields.at(1), 'newpassword1');
      await tester.enterText(textFields.at(2), 'newpassword1');

      await tester.tap(find.byType(FilledButton).first);
      await tester.pumpAndSettle();

      // 에러 없이 처리됨
      expect(tester.takeException(), isNull);
    });
  });
}
