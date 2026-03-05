import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/settings/presentation/widgets/guide_dialog.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';

Widget _buildTestApp({Widget? home}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('ko'),
    home: home ?? const Scaffold(body: GuideDialog()),
  );
}

void main() {
  group('GuideDialog 위젯 테스트', () {
    testWidgets('정상적으로 렌더링된다', (tester) async {
      // When
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      // Then
      expect(find.byType(Dialog), findsOneWidget);
      expect(find.text('환영합니다!'), findsOneWidget);
      expect(find.text('우리의 생활 공유 가계부'), findsOneWidget);
    });

    testWidgets('가이드 경로가 표시된다', (tester) async {
      // When
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      // Then
      expect(find.text('설정 > 정보 > 가이드'), findsOneWidget);
      expect(find.byIcon(Icons.lightbulb_outline), findsOneWidget);
    });

    testWidgets('확인 버튼이 표시된다', (tester) async {
      // When
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      // Then
      expect(find.text('확인'), findsOneWidget);
      expect(find.byType(TextButton), findsOneWidget);
    });

    testWidgets('확인 버튼을 탭하면 다이얼로그가 닫힌다', (tester) async {
      // Given
      await tester.pumpWidget(
        _buildTestApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (_) => const GuideDialog(),
                    );
                  },
                  child: const Text('다이얼로그 열기'),
                );
              },
            ),
          ),
        ),
      );
      await tester.pump();

      // When - 다이얼로그 열기
      await tester.tap(find.text('다이얼로그 열기'));
      await tester.pumpAndSettle();

      // Then - 다이얼로그가 열림
      expect(find.byType(GuideDialog), findsOneWidget);

      // When - 확인 버튼 탭
      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();

      // Then - 다이얼로그가 닫힘
      expect(find.byType(GuideDialog), findsNothing);
    });

    testWidgets('아이콘과 배경색이 올바르게 표시된다', (tester) async {
      // When
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      // Then
      expect(find.byIcon(Icons.favorite_outline), findsOneWidget);

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(GuideDialog),
          matching: find.byType(Container),
        ).first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, const Color(0xFFA8DAB5));
    });

    testWidgets('본문 텍스트가 올바르게 표시된다', (tester) async {
      // When
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      // Then
      expect(
        find.text('함께하는 가계부 관리!\n설정에서 가이드를 확인하고\n시작하는 방법을 알아보세요.'),
        findsOneWidget,
      );
    });

    testWidgets('구분선이 표시된다', (tester) async {
      // When
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      // Then
      expect(find.byType(Divider), findsOneWidget);
    });

    testWidgets('GuideDialog.show() 정적 메서드로 다이얼로그를 표시할 수 있다', (tester) async {
      // Given: 버튼을 탭하면 GuideDialog.show()를 호출하는 위젯
      await tester.pumpWidget(
        _buildTestApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () => GuideDialog.show(context),
                  child: const Text('가이드 열기'),
                );
              },
            ),
          ),
        ),
      );
      await tester.pump();

      // When: 버튼 탭
      await tester.tap(find.text('가이드 열기'));
      await tester.pumpAndSettle();

      // Then: 다이얼로그가 표시된다
      expect(find.byType(GuideDialog), findsOneWidget);
      expect(find.text('환영합니다!'), findsOneWidget);
    });

    testWidgets('GuideDialog.show()로 표시된 다이얼로그의 확인 버튼을 탭하면 닫힌다',
        (tester) async {
      // Given
      await tester.pumpWidget(
        _buildTestApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () => GuideDialog.show(context),
                  child: const Text('가이드 열기'),
                );
              },
            ),
          ),
        ),
      );
      await tester.pump();

      // When: 다이얼로그 열기
      await tester.tap(find.text('가이드 열기'));
      await tester.pumpAndSettle();
      expect(find.byType(GuideDialog), findsOneWidget);

      // When: 확인 버튼 탭
      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();

      // Then: 다이얼로그가 닫힌다
      expect(find.byType(GuideDialog), findsNothing);
    });

    testWidgets('barrierDismissible이 false이다 - 배경 탭으로 닫히지 않는다', (tester) async {
      // Given
      await tester.pumpWidget(
        _buildTestApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () => GuideDialog.show(context),
                  child: const Text('가이드 열기'),
                );
              },
            ),
          ),
        ),
      );
      await tester.pump();

      // When: 다이얼로그 열기
      await tester.tap(find.text('가이드 열기'));
      await tester.pumpAndSettle();
      expect(find.byType(GuideDialog), findsOneWidget);

      // When: 다이얼로그 바깥 영역 탭 (배경 탭)
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // Then: 다이얼로그가 여전히 표시된다 (barrierDismissible=false)
      expect(find.byType(GuideDialog), findsOneWidget);

      // 정리: 확인 버튼으로 닫기
      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();
    });
  });
}
