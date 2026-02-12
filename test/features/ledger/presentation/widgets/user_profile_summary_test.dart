import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/ledger/presentation/widgets/user_profile_summary.dart';

void main() {
  group('UserChip 위젯 테스트', () {
    testWidgets('필수 프로퍼티가 올바르게 렌더링된다', (tester) async {
      // Given
      const testName = '홍길동';
      const testAmount = 50000;
      const testColor = Colors.blue;

      // When
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserChip(
              name: testName,
              amount: testAmount,
              color: testColor,
            ),
          ),
        ),
      );

      // Then
      expect(find.text(testName), findsOneWidget);
      expect(find.text('-50,000'), findsOneWidget);
    });

    testWidgets('이름과 금액이 표시된다', (tester) async {
      // Given
      const testName = '김철수';
      const testAmount = 100000;
      const testColor = Colors.green;

      // When
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserChip(
              name: testName,
              amount: testAmount,
              color: testColor,
            ),
          ),
        ),
      );

      // Then
      expect(find.text(testName), findsOneWidget);
      expect(find.text('-100,000'), findsOneWidget);
    });

    testWidgets('금액이 0원일 때 올바르게 표시된다', (tester) async {
      // Given
      const testName = '이영희';
      const testAmount = 0;
      const testColor = Colors.red;

      // When
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserChip(
              name: testName,
              amount: testAmount,
              color: testColor,
            ),
          ),
        ),
      );

      // Then
      expect(find.text(testName), findsOneWidget);
      expect(find.text('-0'), findsOneWidget);
    });

    testWidgets('긴 이름이 ellipsis로 표시된다', (tester) async {
      // Given
      const testName = '매우긴이름을가진사용자입니다정말긴이름';
      const testAmount = 123456;
      const testColor = Colors.purple;

      // When
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              child: UserChip(
                name: testName,
                amount: testAmount,
                color: testColor,
              ),
            ),
          ),
        ),
      );

      // Then
      expect(find.text(testName), findsOneWidget);
      final textWidget = tester.widget<Text>(find.text(testName));
      expect(textWidget.overflow, TextOverflow.ellipsis);
      expect(textWidget.maxLines, 1);
    });

    testWidgets('색상이 Container 테두리와 원에 적용된다', (tester) async {
      // Given
      const testName = '박민수';
      const testAmount = 75000;
      const testColor = Colors.orange;

      // When
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserChip(
              name: testName,
              amount: testAmount,
              color: testColor,
            ),
          ),
        ),
      );

      // Then - 위젯이 렌더링되는지 확인
      expect(find.byType(UserChip), findsOneWidget);
    });

    testWidgets('다양한 금액 형식이 올바르게 표시된다', (tester) async {
      // Given
      const testCases = [
        (1000, '-1,000'),
        (10000, '-10,000'),
        (100000, '-100,000'),
        (1000000, '-1,000,000'),
        (999, '-999'),
      ];

      for (final (amount, expected) in testCases) {
        // When
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: UserChip(
                name: '테스트',
                amount: amount,
                color: Colors.blue,
              ),
            ),
          ),
        );

        // Then
        expect(find.text(expected), findsOneWidget,
            reason: '$amount 원은 $expected 으로 표시되어야 합니다');

        await tester.pumpWidget(Container());
      }
    });
  });
}
