import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/transaction/presentation/widgets/installment_input_widget.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';

void main() {
  group('InstallmentInputWidget 위젯 테스트', () {
    testWidgets('초기 상태에서 할부 스위치가 꺼진 상태로 렌더링된다', (tester) async {
      // Given
      final startDate = DateTime.now();
      var modeChanged = false;
      InstallmentResult? appliedResult;

      // When
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: InstallmentInputWidget(
              startDate: startDate,
              onModeChanged: (value) {
                modeChanged = value;
              },
              onApplied: (result) {
                appliedResult = result;
              },
            ),
          ),
        ),
      );

      // Then: Switch가 렌더링되고 초기 상태는 off
      expect(find.byType(Switch), findsOneWidget);
      final switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.value, false);
      expect(modeChanged, false);
    });

    testWidgets('할부 스위치를 켜면 입력 폼이 표시된다', (tester) async {
      // Given
      final startDate = DateTime.now();
      var modeChanged = false;

      // When
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: InstallmentInputWidget(
              startDate: startDate,
              onModeChanged: (value) {
                modeChanged = value;
              },
              onApplied: (result) {},
            ),
          ),
        ),
      );

      // Switch 탭
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      // Then: TextFormField가 2개 표시되어야 함 (총 금액, 개월 수)
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(modeChanged, true);
    });

    testWidgets('enabled가 false일 때 스위치가 비활성화된다', (tester) async {
      // Given
      final startDate = DateTime.now();

      // When
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: InstallmentInputWidget(
              startDate: startDate,
              enabled: false,
              onModeChanged: (value) {},
              onApplied: (result) {},
            ),
          ),
        ),
      );

      // Then: Switch의 onChanged가 null이어야 함
      final switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.onChanged, isNull);
    });

    testWidgets('ListTile과 Column이 올바르게 렌더링된다', (tester) async {
      // Given
      final startDate = DateTime.now();

      // When
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: InstallmentInputWidget(
              startDate: startDate,
              onModeChanged: (value) {},
              onApplied: (result) {},
            ),
          ),
        ),
      );

      // Then: ListTile과 Column이 렌더링되어야 함
      expect(find.byType(ListTile), findsOneWidget);
      expect(find.byType(Column), findsWidgets);
    });
  });

  group('InstallmentResult 계산 테스트', () {
    test('할부 계산이 올바르게 동작한다 - 나누어 떨어지는 경우', () {
      // Given: 120만원을 6개월로 나눔
      final result = InstallmentResult.calculate(
        totalAmount: 1200000,
        months: 6,
        startDate: DateTime(2024, 1, 15),
      );

      // Then
      expect(result.totalAmount, 1200000);
      expect(result.months, 6);
      expect(result.baseAmount, 200000);
      expect(result.firstMonthAmount, 200000);
      expect(result.monthlyAmounts.length, 6);
      expect(result.monthlyAmounts.every((amount) => amount == 200000), true);
    });

    test('할부 계산이 올바르게 동작한다 - 나누어 떨어지지 않는 경우', () {
      // Given: 100만원을 3개월로 나눔
      final result = InstallmentResult.calculate(
        totalAmount: 1000000,
        months: 3,
        startDate: DateTime(2024, 1, 15),
      );

      // Then: 첫 달에 나머지 포함
      expect(result.totalAmount, 1000000);
      expect(result.months, 3);
      expect(result.baseAmount, 333333);
      expect(result.firstMonthAmount, 333334); // 333333 + 1
      expect(result.monthlyAmounts[0], 333334);
      expect(result.monthlyAmounts[1], 333333);
      expect(result.monthlyAmounts[2], 333333);
    });

    test('종료일이 올바르게 계산된다', () {
      // Given: 2024년 1월 15일부터 6개월
      final result = InstallmentResult.calculate(
        totalAmount: 600000,
        months: 6,
        startDate: DateTime(2024, 1, 15),
      );

      // Then: 2024년 6월 15일에 종료
      expect(result.endDate.year, 2024);
      expect(result.endDate.month, 6);
      expect(result.endDate.day, 15);
    });
  });
}
