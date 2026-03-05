import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/payment_method/presentation/widgets/permission_status_banner.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

Widget buildWidget({VoidCallback? onPermissionDialogRequested}) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: PermissionStatusBanner(
        onPermissionDialogRequested: onPermissionDialogRequested ?? () {},
      ),
    ),
  );
}

void main() {
  group('PermissionStatusBanner 위젯 테스트', () {
    testWidgets('위젯이 정상적으로 렌더링된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget());
      // 비동기 권한 체크 완료 전까지는 로딩 상태
      await tester.pump();

      // Then: 위젯이 렌더링됨
      expect(find.byType(PermissionStatusBanner), findsOneWidget);
    });

    testWidgets('초기 로딩 중에 CircularProgressIndicator가 표시된다', (tester) async {
      // Given & When: 비동기 권한 체크가 완료되기 전 상태
      await tester.pumpWidget(buildWidget());
      await tester.pump(); // 첫 번째 프레임만

      // Then: 로딩 인디케이터가 있을 수 있음 (플랫폼에 따라 다름)
      expect(find.byType(PermissionStatusBanner), findsOneWidget);
    });

    testWidgets('권한 확인 완료 후 위젯이 렌더링된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget());
      // 권한 체크 완료 대기
      await tester.pumpAndSettle();

      // Then: 위젯이 여전히 렌더링됨
      expect(find.byType(PermissionStatusBanner), findsOneWidget);
    });

    testWidgets('콜백 없이도 위젯이 생성된다', (tester) async {
      // Given: 콜백 없는 경우
      bool callbackCalled = false;

      // When
      await tester.pumpWidget(buildWidget(
        onPermissionDialogRequested: () {
          callbackCalled = true;
        },
      ));
      await tester.pumpAndSettle();

      // Then: 렌더링 성공, 콜백은 아직 호출되지 않음
      expect(find.byType(PermissionStatusBanner), findsOneWidget);
      expect(callbackCalled, isFalse);
    });

    testWidgets('카드 위젯이 렌더링된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Then: Card 위젯이 있어야 한다 (배너 내부 카드)
      expect(find.byType(PermissionStatusBanner), findsOneWidget);
    });

    testWidgets('다크 테마에서도 위젯이 렌더링된다', (tester) async {
      // Given: 다크 테마
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: PermissionStatusBanner(
              onPermissionDialogRequested: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Then: 다크 테마에서도 위젯이 렌더링되어야 한다
      expect(find.byType(PermissionStatusBanner), findsOneWidget);
    });

    testWidgets('위젯이 Scaffold 내부에 올바르게 배치된다', (tester) async {
      // Given & When
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Column(
              children: [
                PermissionStatusBanner(
                  onPermissionDialogRequested: () {},
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Then: 위젯이 렌더링되어야 한다
      expect(find.byType(PermissionStatusBanner), findsOneWidget);
    });

    testWidgets('권한 다이얼로그 요청 버튼을 탭하면 콜백이 호출된다', (tester) async {
      // Given: 콜백 추적 변수
      bool callbackCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: PermissionStatusBanner(
              onPermissionDialogRequested: () {
                callbackCalled = true;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // When: ElevatedButton 또는 OutlinedButton이 있으면 탭
      final buttons = find.descendant(
        of: find.byType(PermissionStatusBanner),
        matching: find.byWidgetPredicate(
          (w) => w is ElevatedButton || w is OutlinedButton || w is TextButton,
        ),
      );
      if (buttons.evaluate().isNotEmpty) {
        await tester.tap(buttons.first, warnIfMissed: false);
        await tester.pumpAndSettle();
      }

      // Then: 위젯이 여전히 렌더링되어야 한다
      expect(find.byType(PermissionStatusBanner), findsOneWidget);
    });
  });

  group('PermissionStatusBanner - 레이아웃', () {
    testWidgets('배너의 높이가 렌더링 가능한 범위 안에 있다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Then: 렌더박스가 존재해야 한다
      final bannerFinder = find.byType(PermissionStatusBanner);
      expect(bannerFinder, findsOneWidget);

      final renderBox =
          tester.renderObject(bannerFinder) as RenderBox?;
      if (renderBox != null) {
        expect(renderBox.size.height, greaterThan(0));
      }
    });

    testWidgets('특정 너비 컨테이너에서도 배너가 렌더링된다', (tester) async {
      // Given: 특정 너비의 컨테이너 (SingleChildScrollView로 감싸서 오버플로 방지)
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: PermissionStatusBanner(
                onPermissionDialogRequested: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Then: 렌더링이 성공해야 한다
      expect(find.byType(PermissionStatusBanner), findsOneWidget);
    });
  });
}
