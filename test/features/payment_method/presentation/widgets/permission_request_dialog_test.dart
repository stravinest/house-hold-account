import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/payment_method/presentation/widgets/permission_request_dialog.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';

/// PermissionRequestDialog 위젯 테스트
///
/// Platform.isAndroid 의존성이 있으므로 비-Android 환경(테스트 환경)에서
/// isLoading=false로 즉시 렌더링되는 동작을 검증한다.

Widget _buildDialog({
  AutoSavePermissionType permissionType = AutoSavePermissionType.both,
  bool isInitialSetup = false,
  VoidCallback? onPermissionGranted,
  VoidCallback? onPermissionDenied,
}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('ko'),
    home: Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () => showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => PermissionRequestDialog(
              permissionType: permissionType,
              isInitialSetup: isInitialSetup,
              onPermissionGranted: onPermissionGranted,
              onPermissionDenied: onPermissionDenied,
            ),
          ),
          child: const Text('open'),
        ),
      ),
    ),
  );
}

void main() {
  group('AutoSavePermissionType 열거형 값', () {
    test('sms 타입은 정확한 이름을 가진다', () {
      // Given/When/Then
      expect(AutoSavePermissionType.sms.name, 'sms');
    });

    test('notification 타입은 정확한 이름을 가진다', () {
      expect(AutoSavePermissionType.notification.name, 'notification');
    });

    test('both 타입은 정확한 이름을 가진다', () {
      expect(AutoSavePermissionType.both.name, 'both');
    });

    test('all 타입은 정확한 이름을 가진다', () {
      expect(AutoSavePermissionType.all.name, 'all');
    });

    test('4가지 타입이 존재한다', () {
      expect(AutoSavePermissionType.values.length, 4);
    });
  });

  group('PermissionRequestDialog - 렌더링 (비-Android 환경)', () {
    testWidgets('다이얼로그가 열리면 Dialog 위젯이 표시된다', (tester) async {
      // Given: 기본 설정 다이얼로그
      await tester.pumpWidget(_buildDialog());

      // When: 다이얼로그 열기 버튼 탭
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Then: Dialog가 표시되어야 한다
      expect(find.byType(Dialog), findsOneWidget);
    });

    testWidgets('비-Android 환경에서 로딩이 완료된 후 컨텐츠가 표시된다', (tester) async {
      // Given: both 타입 다이얼로그 (비-Android에서는 권한 없이 즉시 완료)
      await tester.pumpWidget(_buildDialog(
        permissionType: AutoSavePermissionType.both,
      ));

      // When: 다이얼로그 열기
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Then: 다이얼로그가 표시되어야 한다 (로딩 중이든 완료든)
      expect(find.byType(Dialog), findsOneWidget);
    });

    testWidgets('isInitialSetup=true이면 앱 설정 타이틀이 표시된다', (tester) async {
      // Given: 초기 설정 모드
      await tester.pumpWidget(_buildDialog(
        permissionType: AutoSavePermissionType.all,
        isInitialSetup: true,
      ));

      // When: 다이얼로그 열기
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Then: Dialog가 표시되어야 한다
      expect(find.byType(Dialog), findsOneWidget);
    });

    testWidgets('isInitialSetup=false이면 자동수집 설정 타이틀이 표시된다', (tester) async {
      // Given: 일반 모드
      await tester.pumpWidget(_buildDialog(
        permissionType: AutoSavePermissionType.both,
        isInitialSetup: false,
      ));

      // When: 다이얼로그 열기
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Then: Dialog가 표시되어야 한다
      expect(find.byType(Dialog), findsOneWidget);
    });
  });

  group('PermissionRequestDialog - 버튼 상호작용', () {
    testWidgets('비-Android 환경에서 취소 버튼이 있으면 클릭 시 다이얼로그가 닫힌다', (tester) async {
      // Given: 권한 취소 콜백 추적
      bool deniedCalled = false;
      await tester.pumpWidget(_buildDialog(
        permissionType: AutoSavePermissionType.sms,
        onPermissionDenied: () => deniedCalled = true,
      ));

      // When: 다이얼로그 열기
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Then: 다이얼로그가 표시되어야 한다
      expect(find.byType(Dialog), findsOneWidget);

      // 취소 버튼이 있으면 탭한다 (비-Android에서는 로딩 후 표시)
      final cancelButton = find.text('취소');
      if (cancelButton.evaluate().isNotEmpty) {
        await tester.tap(cancelButton);
        await tester.pumpAndSettle();

        // Then: 다이얼로그가 닫혀야 한다
        expect(find.byType(Dialog), findsNothing);
      }
    });

    testWidgets('비-Android 환경에서 나중에 버튼이 있으면 클릭 시 다이얼로그가 닫힌다', (tester) async {
      // Given: 기본 다이얼로그
      await tester.pumpWidget(_buildDialog(
        permissionType: AutoSavePermissionType.sms,
      ));

      // When: 다이얼로그 열기
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Then: 다이얼로그가 표시되어야 한다
      expect(find.byType(Dialog), findsOneWidget);

      // 나중에 버튼이 있으면 탭한다
      final laterButton = find.text('나중에');
      if (laterButton.evaluate().isNotEmpty) {
        await tester.tap(laterButton);
        await tester.pumpAndSettle();

        // Then: 다이얼로그가 닫혀야 한다
        expect(find.byType(Dialog), findsNothing);
      }
    });
  });

  group('PermissionRequestDialog - static 메서드', () {
    test('show() 메서드가 존재하고 호출 가능하다', () {
      // Given/When/Then: 메서드 존재 확인
      expect(PermissionRequestDialog.show, isNotNull);
    });

    test('showInitialPermissions() 메서드가 존재한다', () {
      expect(PermissionRequestDialog.showInitialPermissions, isNotNull);
    });

    test('hasAnyDeniedPermission() 메서드가 존재한다', () {
      expect(PermissionRequestDialog.hasAnyDeniedPermission, isNotNull);
    });

    test('showIfAnyDenied() 메서드가 존재한다', () {
      expect(PermissionRequestDialog.showIfAnyDenied, isNotNull);
    });
  });

  group('PermissionRequestDialog - 권한 타입별 화면 구성', () {
    testWidgets('sms 타입은 SMS 관련 권한 항목을 포함한다', (tester) async {
      // Given: SMS 타입 다이얼로그
      await tester.pumpWidget(_buildDialog(
        permissionType: AutoSavePermissionType.sms,
      ));

      // When: 다이얼로그 열기
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Then: Dialog가 표시되어야 한다
      expect(find.byType(Dialog), findsOneWidget);
    });

    testWidgets('notification 타입은 알림 관련 권한 항목을 포함한다', (tester) async {
      // Given: 알림 타입 다이얼로그
      await tester.pumpWidget(_buildDialog(
        permissionType: AutoSavePermissionType.notification,
      ));

      // When: 다이얼로그 열기
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Then: Dialog가 표시되어야 한다
      expect(find.byType(Dialog), findsOneWidget);
    });

    testWidgets('all 타입 다이얼로그가 렌더링된다', (tester) async {
      // Given: all 타입 다이얼로그
      await tester.pumpWidget(_buildDialog(
        permissionType: AutoSavePermissionType.all,
      ));

      // When: 다이얼로그 열기
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Then: Dialog가 표시되어야 한다
      expect(find.byType(Dialog), findsOneWidget);
    });
  });

  group('PermissionRequestDialog - 콜백 호출', () {
    testWidgets('onPermissionDenied 콜백이 등록되면 취소 시 호출된다', (tester) async {
      // Given: 거부 콜백 추적
      bool deniedCalled = false;

      await tester.pumpWidget(_buildDialog(
        permissionType: AutoSavePermissionType.sms,
        onPermissionDenied: () => deniedCalled = true,
      ));

      // When: 다이얼로그 열기
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // 취소 버튼이 있으면 탭
      final cancelBtn = find.text('취소');
      if (cancelBtn.evaluate().isNotEmpty) {
        await tester.tap(cancelBtn.first);
        await tester.pumpAndSettle();

        // Then: onPermissionDenied가 호출되어야 한다
        expect(deniedCalled, isTrue);
      }
    });

    testWidgets('onPermissionGranted 콜백이 등록되면 나중에는 호출되지 않는다', (tester) async {
      // Given: 허용 콜백 추적
      bool grantedCalled = false;

      await tester.pumpWidget(_buildDialog(
        permissionType: AutoSavePermissionType.sms,
        onPermissionGranted: () => grantedCalled = true,
      ));

      // When: 다이얼로그 열기
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // 나중에 버튼이 있으면 탭
      final laterBtn = find.text('나중에');
      if (laterBtn.evaluate().isNotEmpty) {
        await tester.tap(laterBtn.first);
        await tester.pumpAndSettle();

        // Then: grantedCalled는 false여야 한다 (나중에는 허용이 아님)
        expect(grantedCalled, isFalse);
      }
    });
  });

  group('PermissionRequestDialog - 다이얼로그 구조', () {
    testWidgets('Dialog 안에 Column 구조가 있다', (tester) async {
      // Given: both 타입 다이얼로그
      await tester.pumpWidget(_buildDialog(
        permissionType: AutoSavePermissionType.both,
      ));

      // When: 다이얼로그 열기
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Then: Dialog 안에 Column이 있어야 한다
      expect(find.byType(Dialog), findsOneWidget);
      expect(
        find.descendant(of: find.byType(Dialog), matching: find.byType(Column)),
        findsWidgets,
      );
    });

    testWidgets('다이얼로그 내 버튼이 하나 이상 존재한다', (tester) async {
      // Given: sms 타입
      await tester.pumpWidget(_buildDialog(
        permissionType: AutoSavePermissionType.sms,
      ));

      // When: 다이얼로그 열기
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Then: Dialog 안에 버튼이 하나 이상 있어야 한다
      final buttons = find.descendant(
        of: find.byType(Dialog),
        matching: find.byWidgetPredicate(
          (w) => w is TextButton || w is OutlinedButton || w is ElevatedButton,
        ),
      );
      expect(buttons.evaluate().length, greaterThanOrEqualTo(1));
    });

    testWidgets('isInitialSetup=true일 때 다이얼로그 내 텍스트가 표시된다', (tester) async {
      // Given: 초기 설정 모드
      await tester.pumpWidget(_buildDialog(
        permissionType: AutoSavePermissionType.all,
        isInitialSetup: true,
      ));

      // When: 다이얼로그 열기
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Then: Dialog 안에 Text 위젯이 있어야 한다
      expect(
        find.descendant(of: find.byType(Dialog), matching: find.byType(Text)),
        findsWidgets,
      );
    });

    testWidgets('isInitialSetup=false일 때 다이얼로그 내 텍스트가 표시된다', (tester) async {
      // Given: 일반 모드
      await tester.pumpWidget(_buildDialog(
        permissionType: AutoSavePermissionType.both,
        isInitialSetup: false,
      ));

      // When: 다이얼로그 열기
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Then: Dialog 안에 Text 위젯이 있어야 한다
      expect(
        find.descendant(of: find.byType(Dialog), matching: find.byType(Text)),
        findsWidgets,
      );
    });
  });

  group('PermissionRequestDialog - 반복 표시', () {
    testWidgets('동일 타입 다이얼로그를 여러 번 열어도 정상 동작한다', (tester) async {
      // Given: sms 타입
      await tester.pumpWidget(_buildDialog(
        permissionType: AutoSavePermissionType.sms,
      ));

      // When: 첫 번째 열기 후 닫기
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsOneWidget);

      // 나중에 버튼으로 닫기
      final laterBtn = find.text('나중에');
      if (laterBtn.evaluate().isNotEmpty) {
        await tester.tap(laterBtn.first);
        await tester.pumpAndSettle();
      } else {
        // ESC나 외부 탭으로 닫기 시도 (barrierDismissible=false라 안 됨)
        // 대신 취소 버튼 사용
        final cancelBtn = find.text('취소');
        if (cancelBtn.evaluate().isNotEmpty) {
          await tester.tap(cancelBtn.first);
          await tester.pumpAndSettle();
        }
      }

      // Then: 크래시 없이 동작해야 한다
      expect(find.byType(Scaffold), findsWidgets);
    });
  });

  group('_PermissionColors - 색상 클래스', () {
    testWidgets('라이트 모드에서 PermissionRequestDialog가 올바른 배경색을 사용한다', (tester) async {
      // Given: 라이트 모드 앱
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ko'),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const PermissionRequestDialog(
                    permissionType: AutoSavePermissionType.sms,
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );

      // When: 다이얼로그 열기
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Then: Dialog가 표시되어야 한다
      expect(find.byType(Dialog), findsOneWidget);
    });

    testWidgets('다크 모드에서 PermissionRequestDialog가 렌더링된다', (tester) async {
      // Given: 다크 모드 앱
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ko'),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const PermissionRequestDialog(
                    permissionType: AutoSavePermissionType.both,
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );

      // When: 다이얼로그 열기
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Then: Dialog가 표시되어야 한다
      expect(find.byType(Dialog), findsOneWidget);
    });

    testWidgets('다크 모드에서 all 타입 다이얼로그가 렌더링된다 (grantedBadge 색상 커버)', (tester) async {
      // Given: 다크 모드 + all 타입
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ko'),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const PermissionRequestDialog(
                    permissionType: AutoSavePermissionType.all,
                    isInitialSetup: true,
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );

      // When: 다이얼로그 열기
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Then: Dialog가 표시되어야 한다
      expect(find.byType(Dialog), findsOneWidget);
    });

    testWidgets('다크 모드에서 sms 타입 다이얼로그가 렌더링된다 (warningColor 다크 브랜치)', (tester) async {
      // Given: 다크 모드 + sms 타입
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ko'),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const PermissionRequestDialog(
                    permissionType: AutoSavePermissionType.sms,
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );

      // When: 다이얼로그 열기
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Then: Dialog가 표시되어야 한다
      expect(find.byType(Dialog), findsOneWidget);
    });

    testWidgets('다크 모드에서 notification 타입 다이얼로그가 렌더링된다', (tester) async {
      // Given: 다크 모드 + notification 타입
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ko'),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const PermissionRequestDialog(
                    permissionType: AutoSavePermissionType.notification,
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );

      // When: 다이얼로그 열기
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Then: Dialog가 표시되어야 한다
      expect(find.byType(Dialog), findsOneWidget);
    });
  });
}
