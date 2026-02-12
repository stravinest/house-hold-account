import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/ledger/presentation/widgets/calendar_month_summary.dart';

void main() {
  group('UserAmountIndicator 위젯 테스트', () {
    testWidgets('필수 프로퍼티가 올바르게 렌더링된다', (tester) async {
      // Given
      const testColor = Colors.blue;
      const testAmount = 10000;

      // When
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserAmountIndicator(
              color: testColor,
              amount: testAmount,
            ),
          ),
        ),
      );

      // Then
      expect(find.byType(UserAmountIndicator), findsOneWidget);
      expect(find.text('10,000'), findsOneWidget);
    });

    testWidgets('음수 금액이 올바르게 표시된다', (tester) async {
      // Given
      const testColor = Colors.red;
      const testAmount = -5000;

      // When
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserAmountIndicator(
              color: testColor,
              amount: testAmount,
            ),
          ),
        ),
      );

      // Then
      expect(find.text('-5,000'), findsOneWidget);
    });

    testWidgets('0원일 때 올바르게 표시된다', (tester) async {
      // Given
      const testColor = Colors.green;
      const testAmount = 0;

      // When
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserAmountIndicator(
              color: testColor,
              amount: testAmount,
            ),
          ),
        ),
      );

      // Then
      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('큰 금액이 올바르게 포맷된다', (tester) async {
      // Given
      const testColor = Colors.orange;
      const testAmount = 1234567;

      // When
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserAmountIndicator(
              color: testColor,
              amount: testAmount,
            ),
          ),
        ),
      );

      // Then
      expect(find.text('1,234,567'), findsOneWidget);
    });

    testWidgets('색상 원이 표시된다', (tester) async {
      // Given
      const testColor = Colors.purple;
      const testAmount = 1000;

      // When
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserAmountIndicator(
              color: testColor,
              amount: testAmount,
            ),
          ),
        ),
      );

      // Then - Container가 렌더링되는지 확인
      expect(find.byType(UserAmountIndicator), findsOneWidget);
      expect(find.byType(Row), findsOneWidget);
    });
  });

  group('SummaryColumn 위젯 테스트', () {
    testWidgets('수입 타입으로 렌더링된다', (tester) async {
      // Given
      const label = '수입';
      const totalAmount = 100000;

      // When
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SummaryColumn(
              label: label,
              totalAmount: totalAmount,
              color: Colors.blue,
              users: const {},
              type: SummaryType.income,
              memberCount: 1,
            ),
          ),
        ),
      );

      // Then
      expect(find.text(label), findsOneWidget);
      expect(find.text('100,000'), findsOneWidget);
    });

    testWidgets('지출 타입으로 렌더링된다', (tester) async {
      // Given
      const label = '지출';
      const totalAmount = 50000;

      // When
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SummaryColumn(
              label: label,
              totalAmount: totalAmount,
              color: Colors.red,
              users: const {},
              type: SummaryType.expense,
              memberCount: 1,
            ),
          ),
        ),
      );

      // Then
      expect(find.text(label), findsOneWidget);
      expect(find.text('50,000'), findsOneWidget);
    });

    testWidgets('합계 타입으로 렌더링된다', (tester) async {
      // Given
      const label = '합계';
      const totalAmount = 30000;

      // When
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SummaryColumn(
              label: label,
              totalAmount: totalAmount,
              color: Colors.black,
              users: const {},
              type: SummaryType.balance,
              memberCount: 1,
            ),
          ),
        ),
      );

      // Then
      expect(find.text(label), findsOneWidget);
      expect(find.text('30,000'), findsOneWidget);
    });

    testWidgets('음수 금액이 마이너스 부호와 함께 표시된다', (tester) async {
      // Given
      const label = '합계';
      const totalAmount = -20000;

      // When
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SummaryColumn(
              label: label,
              totalAmount: totalAmount,
              color: Colors.red,
              users: const {},
              type: SummaryType.balance,
              memberCount: 1,
            ),
          ),
        ),
      );

      // Then
      expect(find.text('-20,000'), findsOneWidget);
    });

    testWidgets('멤버가 1명일 때 사용자 인디케이터가 표시되지 않는다', (tester) async {
      // Given
      const label = '수입';
      const totalAmount = 100000;

      // When
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SummaryColumn(
              label: label,
              totalAmount: totalAmount,
              color: Colors.blue,
              users: const {},
              type: SummaryType.income,
              memberCount: 1,
            ),
          ),
        ),
      );

      // Then - UserAmountIndicator가 없어야 함
      expect(find.byType(UserAmountIndicator), findsNothing);
    });

    testWidgets('멤버가 2명 이상일 때 사용자 인디케이터가 표시된다', (tester) async {
      // Given
      const label = '지출';
      const totalAmount = 50000;
      final users = {
        'user1': {
          'displayName': '사용자1',
          'income': 0,
          'expense': 30000,
          'color': '#A8D8EA',
        },
        'user2': {
          'displayName': '사용자2',
          'income': 0,
          'expense': 20000,
          'color': '#FFB6A3',
        },
      };

      // When
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SummaryColumn(
              label: label,
              totalAmount: totalAmount,
              color: Colors.red,
              users: users,
              type: SummaryType.expense,
              memberCount: 2,
            ),
          ),
        ),
      );

      // Then - 2개의 UserAmountIndicator가 있어야 함
      expect(find.byType(UserAmountIndicator), findsNWidgets(2));
    });
  });
}
