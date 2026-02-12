import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/asset/presentation/widgets/asset_goal_progress_bar.dart';

void main() {
  group('AssetGoalProgressBar 위젯 테스트', () {
    testWidgets('진행도 0%일 때 올바르게 렌더링된다', (tester) async {
      // Given: 진행도 0%
      const progress = 0.0;

      // When
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AssetGoalProgressBar(progress: progress),
          ),
        ),
      );

      // Then: 0.0%가 표시되어야 함
      expect(find.text('0.0%'), findsOneWidget);
      expect(find.text('0%'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
    });

    testWidgets('진행도 50%일 때 올바르게 렌더링된다', (tester) async {
      // Given: 진행도 50%
      const progress = 0.5;

      // When
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AssetGoalProgressBar(progress: progress),
          ),
        ),
      );

      // Then: 50.0%가 표시되어야 함
      expect(find.text('50.0%'), findsOneWidget);
    });

    testWidgets('진행도 75%일 때 올바르게 렌더링된다', (tester) async {
      // Given: 진행도 75%
      const progress = 0.75;

      // When
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AssetGoalProgressBar(progress: progress),
          ),
        ),
      );

      // Then: 75.0%가 표시되어야 함
      expect(find.text('75.0%'), findsOneWidget);
    });

    testWidgets('진행도 100% 이상일 때 올바르게 렌더링된다', (tester) async {
      // Given: 진행도 120%
      const progress = 1.2;

      // When
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AssetGoalProgressBar(progress: progress),
          ),
        ),
      );

      // Then: 120.0%가 표시되어야 함
      expect(find.text('120.0%'), findsOneWidget);
    });

    testWidgets('onTap이 제공되면 탭 동작이 작동한다', (tester) async {
      // Given
      var tapped = false;

      // When
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AssetGoalProgressBar(
              progress: 0.5,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      // Then: InkWell이 렌더링되어야 함
      expect(find.byType(InkWell), findsOneWidget);

      // When: 탭
      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      // Then: 콜백이 호출되어야 함
      expect(tapped, true);
    });

    testWidgets('Column, Stack, Row가 올바른 구조로 렌더링된다', (tester) async {
      // Given
      const progress = 0.6;

      // When
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AssetGoalProgressBar(progress: progress),
          ),
        ),
      );

      // Then: 위젯 구조가 올바르게 렌더링되어야 함
      expect(find.byType(Column), findsWidgets);
      expect(find.byType(Stack), findsWidgets);
      expect(find.byType(Row), findsWidgets);
      expect(find.byType(LayoutBuilder), findsOneWidget);
    });

    testWidgets('FractionallySizedBox가 렌더링된다', (tester) async {
      // Given
      const progress = 0.3;

      // When
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AssetGoalProgressBar(progress: progress),
          ),
        ),
      );

      // Then: FractionallySizedBox가 렌더링되어야 함
      expect(find.byType(FractionallySizedBox), findsOneWidget);
      final fractionWidget = tester.widget<FractionallySizedBox>(
        find.byType(FractionallySizedBox),
      );
      expect(fractionWidget.widthFactor, 0.3);
    });
  });
}
