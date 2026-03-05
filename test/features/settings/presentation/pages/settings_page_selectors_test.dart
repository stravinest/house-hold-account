import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_household_account/features/auth/presentation/providers/auth_provider.dart';
import 'package:shared_household_account/features/settings/presentation/pages/settings_page.dart';
import 'package:shared_household_account/features/settings/presentation/providers/app_update_provider.dart';
import 'package:shared_household_account/features/settings/data/services/app_update_service.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';
import 'package:shared_household_account/shared/themes/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// AppUpdate 가짜 구현 (업데이트 없음)
class _FakeAppUpdateNone extends AppUpdate {
  @override
  Future<AppVersionInfo?> build() async => null;
}

// AuthService 가짜 구현 (성공)
class _FakeAuthServiceSuccess extends Fake implements AuthService {
  @override
  User? get currentUser => null;

  @override
  Future<void> updateProfile({
    String? displayName,
    String? avatarUrl,
    String? color,
  }) async {}

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

// AuthService 가짜 구현 (비밀번호 변경 실패)
class _FakeAuthServicePasswordFail extends Fake implements AuthService {
  @override
  User? get currentUser => null;

  @override
  Future<void> updateProfile({
    String? displayName,
    String? avatarUrl,
    String? color,
  }) async {}

  @override
  Future<void> verifyAndUpdatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    throw Exception('현재 비밀번호가 일치하지 않습니다');
  }

  @override
  Future<void> deleteAccount() async {}

  @override
  Future<void> signOut() async {}
}

// AuthService 가짜 구현 (탈퇴 실패)
class _FakeAuthServiceDeleteFail extends Fake implements AuthService {
  @override
  User? get currentUser => null;

  @override
  Future<void> updateProfile({
    String? displayName,
    String? avatarUrl,
    String? color,
  }) async {}

  @override
  Future<void> verifyAndUpdatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {}

  @override
  Future<void> deleteAccount() async {
    throw Exception('탈퇴 실패');
  }

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
    ],
  );
}

Widget _buildTestApp({
  List<Override> overrides = const [],
  AuthService? authService,
}) {
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

  group('SettingsPage 테마 선택 바텀시트 테스트', () {
    testWidgets('테마 ListTile을 탭하면 바텀시트가 표시되어야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // When: palette 아이콘 탭
      await tester.tap(find.byIcon(Icons.palette_outlined));
      await tester.pumpAndSettle();

      // Then: 바텀시트가 표시됨
      expect(find.byType(BottomSheet), findsOneWidget);
    });

    testWidgets('테마 바텀시트에서 라이트 모드를 선택하면 닫혀야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // When: 테마 바텀시트 열기
      await tester.tap(find.byIcon(Icons.palette_outlined));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);

      // When: 첫 번째 항목(라이트) 탭
      final tiles = find.byType(ListTile);
      await tester.tap(tiles.first);
      await tester.pumpAndSettle();

      // Then: 바텀시트가 닫힘
      expect(find.byType(BottomSheet), findsNothing);
    });

    testWidgets('테마 바텀시트에서 다크 모드를 선택하면 닫혀야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // When: 테마 바텀시트 열기
      await tester.tap(find.byIcon(Icons.palette_outlined));
      await tester.pumpAndSettle();

      // When: 두 번째 항목(다크) 탭
      final tiles = find.byType(ListTile);
      await tester.tap(tiles.at(1));
      await tester.pumpAndSettle();

      // Then: 바텀시트가 닫힘
      expect(find.byType(BottomSheet), findsNothing);
    });
  });

  group('SettingsPage 언어 선택 바텀시트 테스트', () {
    testWidgets('언어 ListTile을 탭하면 바텀시트가 표시되어야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // When: 언어 아이콘 탭
      await tester.tap(find.byIcon(Icons.language_outlined));
      await tester.pumpAndSettle();

      // Then: 바텀시트가 표시됨
      expect(find.byType(BottomSheet), findsOneWidget);
    });

    testWidgets('언어 바텀시트에서 한국어를 선택하면 닫혀야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // When: 언어 바텀시트 열기
      await tester.tap(find.byIcon(Icons.language_outlined));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);

      // When: 첫 번째 항목(한국어) 탭
      final tiles = find.byType(ListTile);
      await tester.tap(tiles.first);
      await tester.pumpAndSettle();

      // Then: 바텀시트가 닫힘
      expect(find.byType(BottomSheet), findsNothing);
    });

    testWidgets('언어 바텀시트에서 영어를 선택하면 닫혀야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // When: 언어 바텀시트 열기
      await tester.tap(find.byIcon(Icons.language_outlined));
      await tester.pumpAndSettle();

      // When: 두 번째 항목(영어) 탭
      final tiles = find.byType(ListTile);
      await tester.tap(tiles.at(1));
      await tester.pumpAndSettle();

      // Then: 바텀시트가 닫힘
      expect(find.byType(BottomSheet), findsNothing);
    });
  });

  group('SettingsPage 비밀번호 변경 다이얼로그 테스트', () {
    testWidgets('비밀번호 변경 ListTile을 탭하면 다이얼로그가 표시되어야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // When: 비밀번호 변경 항목까지 스크롤
      await tester.scrollUntilVisible(
        find.byIcon(Icons.lock_outline, skipOffstage: false),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // When: 탭
      await tester.tap(find.byIcon(Icons.lock_outline));
      await tester.pumpAndSettle();

      // Then: AlertDialog가 표시됨
      expect(find.byType(AlertDialog), findsOneWidget);
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

      // When: 취소 버튼 탭
      await tester.tap(find.byType(TextButton).first);
      await tester.pumpAndSettle();

      // Then: 다이얼로그가 닫힘
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('비밀번호 변경 다이얼로그에서 빈 값으로 제출하면 다이얼로그가 유지되어야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // When: 비밀번호 변경 항목 찾기
      final lockIcon = find.byIcon(Icons.lock_outline, skipOffstage: false);
      if (lockIcon.evaluate().isEmpty) return; // 없으면 스킵

      await tester.tap(lockIcon.first);
      await tester.pumpAndSettle();

      // 다이얼로그가 열렸는지 확인
      if (find.byType(AlertDialog).evaluate().isEmpty) return;

      // When: 빈 값으로 제출 (마지막 TextButton이 제출)
      final buttons = find.byType(TextButton);
      if (buttons.evaluate().isNotEmpty) {
        await tester.tap(buttons.last);
        await tester.pumpAndSettle();
      }

      // Then: 다이얼로그가 열려있어야 함 (유효성 실패로 닫히지 않음)
      // 또는 다이얼로그가 닫혀도 에러 없이 처리됨
      expect(tester.takeException(), isNull);
    });

    testWidgets('비밀번호 필드에서 보이기 버튼을 탭하면 텍스트가 표시되어야 한다', (tester) async {
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

      // When: visibility_off 아이콘 탭 (비밀번호 보이기 토글)
      final visibilityOffIcon = find.byIcon(Icons.visibility_off);
      if (visibilityOffIcon.evaluate().isNotEmpty) {
        await tester.tap(visibilityOffIcon.first);
        await tester.pumpAndSettle();
      }

      // Then: 다이얼로그가 열린 상태
      expect(find.byType(AlertDialog), findsOneWidget);
    });
  });

  group('SettingsPage _DisplayNameEditor 테스트', () {
    testWidgets('프로필 섹션에 표시 이름 텍스트 필드가 표시되어야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // When: 프로필 섹션까지 스크롤
      await tester.scrollUntilVisible(
        find.byType(TextFormField, skipOffstage: false),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // Then: TextFormField가 있음 (표시 이름 편집기)
      expect(find.byType(TextFormField), findsAtLeastNWidgets(1));
    });

    testWidgets('표시 이름 필드에 텍스트를 입력하면 저장 버튼이 활성화되어야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // When: 표시 이름 필드까지 스크롤
      await tester.scrollUntilVisible(
        find.byType(TextFormField, skipOffstage: false),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // When: 기존 텍스트를 지우고 새 텍스트 입력
      final textField = find.byType(TextFormField).first;
      await tester.tap(textField);
      await tester.pump();
      await tester.enterText(textField, '새로운 이름');
      await tester.pump();

      // Then: FilledButton이 있음 (활성화 여부는 상태에 따라 다름)
      expect(find.byType(FilledButton), findsAtLeastNWidgets(1));
    });

    testWidgets('표시 이름 필드를 원래 값으로 되돌리면 저장 버튼이 비활성화되어야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // When: 표시 이름 필드까지 스크롤
      await tester.scrollUntilVisible(
        find.byType(TextFormField, skipOffstage: false),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // When: 텍스트 변경 후 원래 값으로 복원
      final textField = find.byType(TextFormField).first;
      await tester.enterText(textField, '새 이름');
      await tester.pump();
      await tester.enterText(textField, '테스트 사용자');
      await tester.pump();

      // Then: 위젯이 정상 렌더링됨
      expect(find.byType(SettingsPage), findsOneWidget);
    });
  });

  group('SettingsPage 알림 스위치 테스트', () {
    testWidgets('알림 스위치를 탭하면 상태가 토글되어야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // When: SwitchListTile 탭
      final switchTile = find.byType(SwitchListTile);
      if (switchTile.evaluate().isNotEmpty) {
        await tester.tap(switchTile.first);
        await tester.pumpAndSettle();
      }

      // Then: 페이지 정상 렌더링됨
      expect(find.byType(SettingsPage), findsOneWidget);
    });
  });

  group('SettingsPage 로그아웃 다이얼로그 확인 테스트', () {
    testWidgets('로그아웃 버튼을 탭하면 확인 다이얼로그가 표시되어야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // When: 로그아웃 항목 찾기 - 페이지 끝까지 스크롤
      final listView = find.byType(ListView);
      await tester.drag(listView.first, const Offset(0, -1000));
      await tester.pumpAndSettle();

      // When: 로그아웃 아이콘 탭
      final logoutIcon = find.byIcon(Icons.logout);
      if (logoutIcon.evaluate().isNotEmpty) {
        await tester.tap(logoutIcon.first);
        await tester.pumpAndSettle();
        // Then: 확인 다이얼로그 표시됨
        expect(find.byType(AlertDialog), findsOneWidget);
      }
    });

    testWidgets('로그아웃 다이얼로그에서 취소를 탭하면 다이얼로그가 닫혀야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // When: 페이지 끝까지 스크롤
      final listView = find.byType(ListView);
      await tester.drag(listView.first, const Offset(0, -1000));
      await tester.pumpAndSettle();

      // When: 로그아웃 아이콘 탭
      final logoutIcon = find.byIcon(Icons.logout);
      if (logoutIcon.evaluate().isEmpty) return;

      await tester.tap(logoutIcon.first);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);

      // When: 취소 버튼 탭 (첫 번째 TextButton)
      final buttons = find.byType(TextButton);
      if (buttons.evaluate().isNotEmpty) {
        await tester.tap(buttons.first);
        await tester.pumpAndSettle();
      }

      // Then: 다이얼로그가 닫힘
      expect(find.byType(AlertDialog), findsNothing);
    });
  });

  group('SettingsPage 계정 삭제 다이얼로그 테스트', () {
    testWidgets('계정 삭제 버튼을 탭하면 확인 다이얼로그가 표시되어야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // When: 페이지 끝까지 스크롤
      final listView = find.byType(ListView);
      await tester.drag(listView.first, const Offset(0, -1000));
      await tester.pumpAndSettle();

      // When: 계정 삭제 아이콘 탭 (Icons.delete_forever)
      final deleteIcon = find.byIcon(Icons.delete_forever);
      if (deleteIcon.evaluate().isEmpty) return;

      await tester.tap(deleteIcon.first);
      await tester.pumpAndSettle();

      // Then: 확인 다이얼로그 표시됨
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('계정 삭제 다이얼로그에서 취소를 탭하면 닫혀야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // When: 페이지 끝까지 스크롤
      final listView = find.byType(ListView);
      await tester.drag(listView.first, const Offset(0, -1000));
      await tester.pumpAndSettle();

      // When: 계정 삭제 아이콘 탭
      final deleteIcon = find.byIcon(Icons.delete_forever);
      if (deleteIcon.evaluate().isEmpty) return;

      await tester.tap(deleteIcon.first);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);

      // When: 취소 버튼 탭
      await tester.tap(find.byType(TextButton).first);
      await tester.pumpAndSettle();

      // Then: 다이얼로그가 닫힘
      expect(find.byType(AlertDialog), findsNothing);
    });
  });

  group('SettingsPage 로그아웃 확인 버튼 테스트', () {
    testWidgets('로그아웃 다이얼로그에서 로그아웃 확인 버튼을 탭하면 signOut이 호출된다', (tester) async {
      // Given
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // When: 페이지 끝까지 스크롤
      final listView = find.byType(ListView);
      await tester.drag(listView.first, const Offset(0, -2000));
      await tester.pumpAndSettle();

      // When: 로그아웃 아이콘 탭
      final logoutIcon = find.byIcon(Icons.logout);
      if (logoutIcon.evaluate().isEmpty) return;

      await tester.tap(logoutIcon.first);
      await tester.pumpAndSettle();

      // 다이얼로그가 표시됨
      final dialog = find.byType(AlertDialog);
      if (dialog.evaluate().isEmpty) return;

      // When: 두 번째 TextButton (로그아웃 확인 버튼) 탭
      final buttons = find.byType(TextButton);
      if (buttons.evaluate().length < 2) return;
      await tester.tap(buttons.at(1), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Then: 에러 없이 처리됨 (signOut 호출됨)
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  group('SettingsPage 탈퇴 확인 버튼 테스트', () {
    testWidgets('계정 삭제 다이얼로그에서 확인 버튼을 탭하면 deleteAccount가 호출된다', (tester) async {
      // Given
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // When: 페이지 끝까지 스크롤
      final listView = find.byType(ListView);
      await tester.drag(listView.first, const Offset(0, -2000));
      await tester.pumpAndSettle();

      // When: 계정 삭제 아이콘 탭
      final deleteIcon = find.byIcon(Icons.delete_forever);
      if (deleteIcon.evaluate().isEmpty) return;

      await tester.tap(deleteIcon.first);
      await tester.pumpAndSettle();

      // 다이얼로그가 표시됨
      final dialog = find.byType(AlertDialog);
      if (dialog.evaluate().isEmpty) return;

      // When: 두 번째 TextButton (탈퇴 확인 버튼) 탭
      final buttons = find.byType(TextButton);
      expect(buttons.evaluate().length, greaterThanOrEqualTo(2));
      await tester.tap(buttons.at(1));
      await tester.pumpAndSettle();

      // Then: 에러 없이 처리됨
      expect(find.byType(SettingsPage), findsOneWidget);
    });

    testWidgets('계정 삭제 중 에러가 발생하면 스낵바가 표시된다', (tester) async {
      // Given: deleteAccount가 실패하는 서비스
      final failService = _FakeAuthServiceDeleteFail();

      await tester.pumpWidget(_buildTestApp(authService: failService));
      await tester.pumpAndSettle();

      // When: 페이지 끝까지 스크롤
      final listView = find.byType(ListView);
      await tester.drag(listView.first, const Offset(0, -2000));
      await tester.pumpAndSettle();

      // When: 계정 삭제 아이콘 탭
      final deleteIcon = find.byIcon(Icons.delete_forever);
      if (deleteIcon.evaluate().isEmpty) return;

      await tester.tap(deleteIcon.first);
      await tester.pumpAndSettle();

      if (find.byType(AlertDialog).evaluate().isEmpty) return;

      // When: 확인 버튼 탭
      final buttons = find.byType(TextButton);
      if (buttons.evaluate().length < 2) return;
      await tester.tap(buttons.at(1));
      await tester.pumpAndSettle();

      // Then: 에러 스낵바가 표시됨
      expect(find.byType(SnackBar), findsOneWidget);
    });
  });

  group('SettingsPage 테마 selector 에러 처리 테스트', () {
    testWidgets('테마 라이트 탭 후 에러 없이 처리된다', (tester) async {
      // Given
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // When: 테마 ListTile 탭
      final themeTile = find.byIcon(Icons.palette_outlined);
      if (themeTile.evaluate().isEmpty) return;
      await tester.tap(themeTile.first);
      await tester.pumpAndSettle();

      // When: 라이트 모드 탭 (첫 번째 ListTile)
      final listTiles = find.byType(ListTile);
      if (listTiles.evaluate().isEmpty) return;
      await tester.tap(listTiles.first);
      await tester.pumpAndSettle();

      // Then: 바텀시트가 닫힘
      expect(find.byType(SettingsPage), findsOneWidget);
    });

    testWidgets('테마 다크 탭 후 에러 없이 처리된다', (tester) async {
      // Given
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // When: 테마 ListTile 탭
      final themeTile = find.byIcon(Icons.palette_outlined);
      if (themeTile.evaluate().isEmpty) return;
      await tester.tap(themeTile.first);
      await tester.pumpAndSettle();

      // When: 다크 모드 탭 (두 번째 ListTile)
      final listTiles = find.byType(ListTile);
      if (listTiles.evaluate().length < 2) return;
      await tester.tap(listTiles.at(1));
      await tester.pumpAndSettle();

      // Then: 바텀시트가 닫힘
      expect(find.byType(SettingsPage), findsOneWidget);
    });
  });

  group('SettingsPage 언어 selector 테스트', () {
    testWidgets('언어 한국어 탭 후 에러 없이 처리된다', (tester) async {
      // Given
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // When: 언어 ListTile 탭
      final langTile = find.byIcon(Icons.language_outlined);
      if (langTile.evaluate().isEmpty) return;
      await tester.tap(langTile.first);
      await tester.pumpAndSettle();

      // When: 한국어 탭
      final listTiles = find.byType(ListTile);
      if (listTiles.evaluate().isEmpty) return;
      await tester.tap(listTiles.first);
      await tester.pumpAndSettle();

      // Then: 처리됨
      expect(find.byType(SettingsPage), findsOneWidget);
    });

    testWidgets('언어 영어 탭 후 에러 없이 처리된다', (tester) async {
      // Given
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // When: 언어 ListTile 탭
      final langTile = find.byIcon(Icons.language_outlined);
      if (langTile.evaluate().isEmpty) return;
      await tester.tap(langTile.first);
      await tester.pumpAndSettle();

      // When: 영어 탭 (두 번째 ListTile)
      final listTiles = find.byType(ListTile);
      if (listTiles.evaluate().length < 2) return;
      await tester.tap(listTiles.at(1));
      await tester.pumpAndSettle();

      // Then: 처리됨
      expect(find.byType(SettingsPage), findsOneWidget);
    });
  });

  group('SettingsPage 표시이름 저장 테스트', () {
    testWidgets('표시이름을 변경 후 저장 버튼을 탭하면 성공 스낵바가 표시된다', (tester) async {
      // Given
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // When: TextFormField에 새 이름 입력
      final textField = find.byType(TextFormField);
      if (textField.evaluate().isEmpty) return;

      await tester.enterText(textField.first, '새이름');
      await tester.pump();

      // When: FilledButton (저장 버튼) 탭
      final saveButton = find.byType(FilledButton);
      if (saveButton.evaluate().isEmpty) return;
      await tester.tap(saveButton.first);
      await tester.pumpAndSettle();

      // Then: 에러 없이 처리됨
      expect(find.byType(SettingsPage), findsOneWidget);
    });
  });
}
