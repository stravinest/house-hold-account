import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/asset/presentation/widgets/goal_type_selector.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';

void main() {
  group('GoalTypeSelector 위젯 테스트', () {
    Widget buildApp({Widget? child}) {
      return MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child ?? const SizedBox()),
      );
    }

    testWidgets('showGoalTypeSelector 호출 시 BottomSheet가 표시된다', (tester) async {
      // Given
      await tester.pumpWidget(
        buildApp(
          child: Builder(
            builder: (context) => TextButton(
              onPressed: () => showGoalTypeSelector(context),
              child: const Text('열기'),
            ),
          ),
        ),
      );

      // When: 버튼 탭으로 BottomSheet 열기
      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();

      // Then: BottomSheet 내 아이콘들이 표시되어야 함
      expect(find.byIcon(Icons.trending_up), findsOneWidget);
      expect(find.byIcon(Icons.account_balance), findsOneWidget);
    });

    testWidgets('자산 목표 옵션을 탭하면 GoalType.asset을 반환한다', (tester) async {
      // Given
      await tester.pumpWidget(
        buildApp(
          child: Builder(
            builder: (context) => TextButton(
              onPressed: () => showGoalTypeSelector(context),
              child: const Text('열기'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();

      // When: 자산 목표 옵션 탭 (trending_up 아이콘이 있는 카드)
      await tester.tap(find.byIcon(Icons.trending_up));
      await tester.pumpAndSettle();

      // Then: BottomSheet가 닫혀야 함
      expect(find.byIcon(Icons.trending_up), findsNothing);
    });

    testWidgets('대출 목표 옵션을 탭하면 BottomSheet가 닫힌다', (tester) async {
      // Given
      await tester.pumpWidget(
        buildApp(
          child: Builder(
            builder: (context) => TextButton(
              onPressed: () => showGoalTypeSelector(context),
              child: const Text('열기'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();

      // When: 대출 목표 옵션 탭 (account_balance 아이콘이 있는 카드)
      await tester.tap(find.byIcon(Icons.account_balance));
      await tester.pumpAndSettle();

      // Then: BottomSheet가 닫혀야 함
      expect(find.byIcon(Icons.account_balance), findsNothing);
    });

    testWidgets('BottomSheet에 핸들 바와 제목이 표시된다', (tester) async {
      // Given
      await tester.pumpWidget(
        buildApp(
          child: Builder(
            builder: (context) => TextButton(
              onPressed: () => showGoalTypeSelector(context),
              child: const Text('열기'),
            ),
          ),
        ),
      );

      // When
      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();

      // Then: Divider가 표시되어야 함
      expect(find.byType(Divider), findsOneWidget);
      // chevron_right 아이콘이 각 옵션에 있어야 함
      expect(find.byIcon(Icons.chevron_right), findsNWidgets(2));
    });
  });
}
