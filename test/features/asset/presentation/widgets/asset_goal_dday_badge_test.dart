import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/asset/presentation/widgets/asset_goal_dday_badge.dart';

void main() {
  group('AssetGoalDDayBadge 위젯 테스트', () {
    testWidgets('남은 일수가 30일 이상일 때 기본 스타일로 표시된다', (tester) async {
      // Given: 남은 일수 50일
      const remainingDays = 50;

      // When
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AssetGoalDDayBadge(remainingDays: remainingDays),
          ),
        ),
      );

      // Then: D-50 텍스트가 표시되고 timer 아이콘이 있어야 함
      expect(find.text('D-50'), findsOneWidget);
      expect(find.byIcon(Icons.timer_outlined), findsOneWidget);
    });

    testWidgets('남은 일수가 30일 미만일 때 긴급 스타일로 표시된다', (tester) async {
      // Given: 남은 일수 10일 (긴급)
      const remainingDays = 10;

      // When
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AssetGoalDDayBadge(remainingDays: remainingDays),
          ),
        ),
      );

      // Then: D-10 텍스트가 표시되고 timer 아이콘이 있어야 함
      expect(find.text('D-10'), findsOneWidget);
      expect(find.byIcon(Icons.timer_outlined), findsOneWidget);
    });

    testWidgets('남은 일수가 0일일 때 오늘 표시된다', (tester) async {
      // Given: 남은 일수 0일 (오늘)
      const remainingDays = 0;

      // When
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AssetGoalDDayBadge(remainingDays: remainingDays),
          ),
        ),
      );

      // Then: D-0 텍스트가 표시되어야 함
      expect(find.text('D-0'), findsOneWidget);
    });

    testWidgets('남은 일수가 음수일 때 지난 일수로 표시된다', (tester) async {
      // Given: 5일 지남
      const remainingDays = -5;

      // When
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AssetGoalDDayBadge(remainingDays: remainingDays),
          ),
        ),
      );

      // Then: D+5 텍스트가 표시되고 schedule 아이콘이 있어야 함
      expect(find.text('D+5'), findsOneWidget);
      expect(find.byIcon(Icons.schedule), findsOneWidget);
    });

    testWidgets('Container와 Row가 올바른 구조로 렌더링된다', (tester) async {
      // Given
      const remainingDays = 15;

      // When
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AssetGoalDDayBadge(remainingDays: remainingDays),
          ),
        ),
      );

      // Then: Container와 Row가 렌더링되어야 함
      expect(find.byType(Container), findsWidgets);
      expect(find.byType(Row), findsOneWidget);
    });
  });
}
