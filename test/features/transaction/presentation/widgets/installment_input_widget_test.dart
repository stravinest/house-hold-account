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
              isInstallmentMode: false,
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
              isInstallmentMode: false,
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
              isInstallmentMode: false,
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
              isInstallmentMode: false,
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

    test('총액 120000원, 6개월 할부는 baseAmount 20000원, firstMonth 20000원을 반환한다', () {
      // Given: 120000원을 6개월로 나누면 딱 떨어짐
      final startDate = DateTime(2026, 1, 15);

      // When
      final result = InstallmentResult.calculate(
        totalAmount: 120000,
        months: 6,
        startDate: startDate,
      );

      // Then: 나머지가 없으므로 모든 달이 20000원
      expect(result.totalAmount, 120000);
      expect(result.months, 6);
      expect(result.baseAmount, 20000);
      expect(result.firstMonthAmount, 20000);
      expect(result.monthlyAmounts.length, 6);
      expect(result.monthlyAmounts, [20000, 20000, 20000, 20000, 20000, 20000]);
    });

    test('총액 100000원, 3개월 할부는 baseAmount 33333원, firstMonth 33334원을 반환한다 (나머지 1원)', () {
      // Given: 100000원을 3으로 나누면 나머지 1원 발생
      final startDate = DateTime(2026, 1, 15);

      // When
      final result = InstallmentResult.calculate(
        totalAmount: 100000,
        months: 3,
        startDate: startDate,
      );

      // Then: 나머지 1원은 첫 달에 포함
      expect(result.totalAmount, 100000);
      expect(result.months, 3);
      expect(result.baseAmount, 33333);
      expect(result.firstMonthAmount, 33334);
      expect(result.monthlyAmounts.length, 3);
      expect(result.monthlyAmounts, [33334, 33333, 33333]);

      // 합계 검증
      final sum = result.monthlyAmounts.reduce((a, b) => a + b);
      expect(sum, 100000);
    });

    test('총액 10000원, 7개월 할부는 baseAmount 1428원, firstMonth 1432원을 반환한다 (나머지 4원)', () {
      // Given: 10000원을 7로 나누면 나머지 4원 발생
      final startDate = DateTime(2026, 1, 15);

      // When
      final result = InstallmentResult.calculate(
        totalAmount: 10000,
        months: 7,
        startDate: startDate,
      );

      // Then: 나머지 4원은 첫 달에 포함
      expect(result.totalAmount, 10000);
      expect(result.months, 7);
      expect(result.baseAmount, 1428);
      expect(result.firstMonthAmount, 1432);
      expect(result.monthlyAmounts.length, 7);
      expect(result.monthlyAmounts, [1432, 1428, 1428, 1428, 1428, 1428, 1428]);

      // 합계 검증
      final sum = result.monthlyAmounts.reduce((a, b) => a + b);
      expect(sum, 10000);
    });

    test('endDate 계산이 정확하다 (2026-01-15 시작, 6개월 → 2026-06-15 종료)', () {
      // Given
      final startDate = DateTime(2026, 1, 15);

      // When
      final result = InstallmentResult.calculate(
        totalAmount: 120000,
        months: 6,
        startDate: startDate,
      );

      // Then: 1월 포함하여 6개월이면 6월 15일 종료
      expect(result.endDate, DateTime(2026, 6, 15));
    });

    test('endDate 계산이 정확하다 (2026-01-31 시작, 3개월 → 2026-03-31 종료)', () {
      // Given: 월말 시작
      final startDate = DateTime(2026, 1, 31);

      // When
      final result = InstallmentResult.calculate(
        totalAmount: 90000,
        months: 3,
        startDate: startDate,
      );

      // Then: 1월 31일 포함하여 3개월이면 3월 31일 종료
      expect(result.endDate, DateTime(2026, 3, 31));
    });

    test('endDate 계산 시 월말 날짜가 없으면 해당 월의 마지막 날로 조정한다 (1월31일 시작, 2개월 → 2월28일 종료)', () {
      // Given: 1월 31일 시작 (2월은 28일까지)
      final startDate = DateTime(2026, 1, 31);

      // When
      final result = InstallmentResult.calculate(
        totalAmount: 60000,
        months: 2,
        startDate: startDate,
      );

      // Then: 2월은 28일까지만 있으므로 2월 28일로 조정
      expect(result.endDate, DateTime(2026, 2, 28));
    });

    test('연도를 넘어가는 할부의 endDate도 정확하게 계산한다 (2025-11-15 시작, 4개월 → 2026-02-15 종료)', () {
      // Given: 연도 경계를 넘는 할부
      final startDate = DateTime(2025, 11, 15);

      // When
      final result = InstallmentResult.calculate(
        totalAmount: 80000,
        months: 4,
        startDate: startDate,
      );

      // Then: 11월, 12월, 1월, 2월
      expect(result.endDate, DateTime(2026, 2, 15));
    });

    test('12개월 이상 할부도 정확하게 계산한다 (2026-01-15 시작, 18개월 → 2027-06-15 종료)', () {
      // Given: 1년 이상의 장기 할부
      final startDate = DateTime(2026, 1, 15);

      // When
      final result = InstallmentResult.calculate(
        totalAmount: 360000,
        months: 18,
        startDate: startDate,
      );

      // Then
      expect(result.endDate, DateTime(2027, 6, 15));
      expect(result.baseAmount, 20000);
      expect(result.firstMonthAmount, 20000);
      expect(result.monthlyAmounts.length, 18);
    });

    test('1개월 할부는 시작일과 종료일이 같다', () {
      // Given: 1개월 할부
      final startDate = DateTime(2026, 1, 15);

      // When
      final result = InstallmentResult.calculate(
        totalAmount: 50000,
        months: 1,
        startDate: startDate,
      );

      // Then
      expect(result.endDate, DateTime(2026, 1, 15));
      expect(result.baseAmount, 50000);
      expect(result.firstMonthAmount, 50000);
      expect(result.monthlyAmounts, [50000]);
    });
  });
}
