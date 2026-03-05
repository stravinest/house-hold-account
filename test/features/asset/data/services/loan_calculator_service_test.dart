import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/asset/data/services/loan_calculator_service.dart';
import 'package:shared_household_account/features/asset/domain/entities/asset_goal.dart';

void main() {
  group('LoanCalculatorService - 원리금균등상환', () {
    test('1억원, 연 3.8%, 96개월일 때 월 상환금이 약 1,209,646원이어야 한다', () {
      final result = LoanCalculatorService.calculateMonthlyPayment(
        loanAmount: 100000000,
        annualInterestRate: 3.8,
        totalMonths: 96,
        method: RepaymentMethod.equalPrincipalInterest,
      );
      expect(result, closeTo(1209646, 1000));
    });

    test('5천만원, 연 5%, 240개월일 때 월 상환금이 약 330,000원이어야 한다', () {
      final result = LoanCalculatorService.calculateMonthlyPayment(
        loanAmount: 50000000,
        annualInterestRate: 5.0,
        totalMonths: 240,
        method: RepaymentMethod.equalPrincipalInterest,
      );
      expect(result, closeTo(329980, 1000));
    });

    test('대출금액이 0이면 월 상환금도 0이어야 한다', () {
      final result = LoanCalculatorService.calculateMonthlyPayment(
        loanAmount: 0,
        annualInterestRate: 3.8,
        totalMonths: 96,
        method: RepaymentMethod.equalPrincipalInterest,
      );
      expect(result, 0);
    });

    test('이자율이 0이면 원금을 개월 수로 나눈 값이어야 한다', () {
      final result = LoanCalculatorService.calculateMonthlyPayment(
        loanAmount: 120000000,
        annualInterestRate: 0.0,
        totalMonths: 120,
        method: RepaymentMethod.equalPrincipalInterest,
      );
      expect(result, closeTo(1000000, 1));
    });
  });

  group('LoanCalculatorService - 원금균등상환', () {
    test('1억원, 연 3.8%, 96개월, 1회차 상환금 계산이 정확해야 한다', () {
      final result = LoanCalculatorService.calculateMonthlyPayment(
        loanAmount: 100000000,
        annualInterestRate: 3.8,
        totalMonths: 96,
        method: RepaymentMethod.equalPrincipal,
        currentMonth: 1,
      );
      // 1회차: 원금 100000000/96 + 100000000 * (3.8/100/12)
      // 원금 = 1,041,667, 이자 = 316,667 -> 합계 약 1,358,333
      expect(result, closeTo(1358333, 1000));
    });

    test('1회차는 원금 1,041,667 + 이자 316,667 = 약 1,358,333원이어야 한다', () {
      final monthlyPrincipal = (100000000 / 96).round();
      final monthlyInterest = (100000000 * (3.8 / 100 / 12)).round();
      final expected = monthlyPrincipal + monthlyInterest;

      final result = LoanCalculatorService.calculateMonthlyPayment(
        loanAmount: 100000000,
        annualInterestRate: 3.8,
        totalMonths: 96,
        method: RepaymentMethod.equalPrincipal,
        currentMonth: 1,
      );
      expect(result, closeTo(expected, 10));
    });

    test('마지막 회차에는 이자가 거의 0에 가까워야 한다', () {
      final lastMonthPayment = LoanCalculatorService.calculateMonthlyPayment(
        loanAmount: 100000000,
        annualInterestRate: 3.8,
        totalMonths: 96,
        method: RepaymentMethod.equalPrincipal,
        currentMonth: 96,
      );
      final monthlyPrincipal = (100000000 / 96).round();
      // 96회차: 남은 잔액 = 원금 * (1 - 95/96) -> 이자가 매우 작음
      // 마지막 회차 상환금은 원금만큼에 근접해야 함
      expect(lastMonthPayment, closeTo(monthlyPrincipal, 50000));
    });

    test('currentMonth를 생략하면 1회차 평균값을 반환해야 한다', () {
      final withDefault = LoanCalculatorService.calculateMonthlyPayment(
        loanAmount: 100000000,
        annualInterestRate: 3.8,
        totalMonths: 96,
        method: RepaymentMethod.equalPrincipal,
      );
      final withFirst = LoanCalculatorService.calculateMonthlyPayment(
        loanAmount: 100000000,
        annualInterestRate: 3.8,
        totalMonths: 96,
        method: RepaymentMethod.equalPrincipal,
        currentMonth: 1,
      );
      expect(withDefault, closeTo(withFirst, 1));
    });
  });

  group('LoanCalculatorService - 만기일시상환', () {
    test('1억원, 연 3.8%일 때 월 이자가 약 316,667원이어야 한다', () {
      final result = LoanCalculatorService.calculateMonthlyPayment(
        loanAmount: 100000000,
        annualInterestRate: 3.8,
        totalMonths: 96,
        method: RepaymentMethod.bullet,
      );
      // 월 이자 = 1억 * 3.8% / 12 = 316,666.67 -> 반올림 316,667
      expect(result, closeTo(316667, 10));
    });

    test('월 상환금은 이자만 포함해야 한다 (원금 제외)', () {
      const loanAmount = 100000000;
      const annualRate = 3.8;
      final expectedInterestOnly = (loanAmount * annualRate / 100 / 12).round();

      final result = LoanCalculatorService.calculateMonthlyPayment(
        loanAmount: loanAmount,
        annualInterestRate: annualRate,
        totalMonths: 96,
        method: RepaymentMethod.bullet,
      );
      expect(result, expectedInterestOnly);
    });
  });

  group('LoanCalculatorService - 체증식상환', () {
    test('초기 상환금이 원리금균등보다 낮아야 한다', () {
      final equalPayment = LoanCalculatorService.calculateMonthlyPayment(
        loanAmount: 100000000,
        annualInterestRate: 3.8,
        totalMonths: 96,
        method: RepaymentMethod.equalPrincipalInterest,
      );
      final graduatedInitial = LoanCalculatorService.calculateMonthlyPayment(
        loanAmount: 100000000,
        annualInterestRate: 3.8,
        totalMonths: 96,
        method: RepaymentMethod.graduated,
        currentMonth: 1,
      );
      expect(graduatedInitial, lessThan(equalPayment));
    });

    test('상환금이 시간이 지날수록 증가해야 한다', () {
      final payment1 = LoanCalculatorService.calculateMonthlyPayment(
        loanAmount: 100000000,
        annualInterestRate: 3.8,
        totalMonths: 96,
        method: RepaymentMethod.graduated,
        currentMonth: 1,
      );
      final payment24 = LoanCalculatorService.calculateMonthlyPayment(
        loanAmount: 100000000,
        annualInterestRate: 3.8,
        totalMonths: 96,
        method: RepaymentMethod.graduated,
        currentMonth: 24,
      );
      final payment48 = LoanCalculatorService.calculateMonthlyPayment(
        loanAmount: 100000000,
        annualInterestRate: 3.8,
        totalMonths: 96,
        method: RepaymentMethod.graduated,
        currentMonth: 48,
      );
      expect(payment24, greaterThan(payment1));
      expect(payment48, greaterThan(payment24));
    });
  });

  group('LoanCalculatorService - 총 이자 계산', () {
    test('원리금균등 총 이자는 월 납부금 * 개월 수 - 원금이어야 한다', () {
      const loanAmount = 100000000;
      const annualRate = 3.8;
      const totalMonths = 96;
      final monthlyPayment = LoanCalculatorService.calculateMonthlyPayment(
        loanAmount: loanAmount,
        annualInterestRate: annualRate,
        totalMonths: totalMonths,
        method: RepaymentMethod.equalPrincipalInterest,
      );
      final expectedTotalInterest = monthlyPayment * totalMonths - loanAmount;
      final result = LoanCalculatorService.calculateTotalInterest(
        loanAmount: loanAmount,
        annualInterestRate: annualRate,
        totalMonths: totalMonths,
        method: RepaymentMethod.equalPrincipalInterest,
      );
      expect(result, closeTo(expectedTotalInterest, 1000));
    });

    test('만기일시상환 총 이자는 월 이자 * 개월 수이어야 한다', () {
      const loanAmount = 100000000;
      const annualRate = 3.8;
      const totalMonths = 96;
      final monthlyInterest = (loanAmount * annualRate / 100 / 12).round();
      final expectedTotal = monthlyInterest * totalMonths;

      final result = LoanCalculatorService.calculateTotalInterest(
        loanAmount: loanAmount,
        annualInterestRate: annualRate,
        totalMonths: totalMonths,
        method: RepaymentMethod.bullet,
      );
      expect(result, closeTo(expectedTotal, 10));
    });
  });

  group('LoanCalculatorService - 진행률 계산', () {
    test('시작일과 만기일 사이의 중간 지점이면 50%여야 한다', () {
      final start = DateTime(2024, 1, 1);
      final end = DateTime(2026, 1, 1);
      final middle = DateTime(2025, 1, 1);

      final result = LoanCalculatorService.calculateProgress(
        startDate: start,
        endDate: end,
        currentDate: middle,
      );
      expect(result, closeTo(0.5, 0.01));
    });

    test('만기가 지났으면 100%여야 한다', () {
      final start = DateTime(2020, 1, 1);
      final end = DateTime(2022, 1, 1);
      final now = DateTime(2023, 1, 1);

      final result = LoanCalculatorService.calculateProgress(
        startDate: start,
        endDate: end,
        currentDate: now,
      );
      expect(result, 1.0);
    });

    test('시작 전이면 0%여야 한다', () {
      final start = DateTime(2025, 1, 1);
      final end = DateTime(2027, 1, 1);
      final now = DateTime(2024, 1, 1);

      final result = LoanCalculatorService.calculateProgress(
        startDate: start,
        endDate: end,
        currentDate: now,
      );
      expect(result, 0.0);
    });

    test('시작일과 만기일이 같으면 100%여야 한다', () {
      final date = DateTime(2025, 1, 1);
      final result = LoanCalculatorService.calculateProgress(
        startDate: date,
        endDate: date,
        currentDate: date,
      );
      expect(result, 1.0);
    });
  });

  group('LoanCalculatorService - 남은 개월 수', () {
    test('만기가 12개월 남았으면 12를 반환해야 한다', () {
      final endDate = DateTime(2026, 3, 1);
      final now = DateTime(2025, 3, 1);
      final result = LoanCalculatorService.calculateRemainingMonths(
        endDate: endDate,
        currentDate: now,
      );
      expect(result, 12);
    });

    test('만기가 지났으면 0을 반환해야 한다', () {
      final endDate = DateTime(2024, 1, 1);
      final now = DateTime(2026, 1, 1);
      final result = LoanCalculatorService.calculateRemainingMonths(
        endDate: endDate,
        currentDate: now,
      );
      expect(result, 0);
    });

    test('만기가 오늘이면 0을 반환해야 한다', () {
      final today = DateTime(2026, 3, 4);
      final result = LoanCalculatorService.calculateRemainingMonths(
        endDate: today,
        currentDate: today,
      );
      expect(result, 0);
    });

    test('만기가 6개월 15일 남았으면 6을 반환해야 한다', () {
      final now = DateTime(2025, 1, 1);
      final endDate = DateTime(2025, 7, 16);
      final result = LoanCalculatorService.calculateRemainingMonths(
        endDate: endDate,
        currentDate: now,
      );
      expect(result, 6);
    });
  });

  group('LoanCalculatorService - 상환 방식 문자열 변환', () {
    test('RepaymentMethod를 문자열로 변환할 수 있어야 한다', () {
      expect(
        LoanCalculatorService.repaymentMethodToString(
          RepaymentMethod.equalPrincipalInterest,
        ),
        'equal_principal_interest',
      );
      expect(
        LoanCalculatorService.repaymentMethodToString(
          RepaymentMethod.equalPrincipal,
        ),
        'equal_principal',
      );
      expect(
        LoanCalculatorService.repaymentMethodToString(RepaymentMethod.bullet),
        'bullet',
      );
      expect(
        LoanCalculatorService.repaymentMethodToString(
          RepaymentMethod.graduated,
        ),
        'graduated',
      );
    });

    test('문자열을 RepaymentMethod로 변환할 수 있어야 한다', () {
      expect(
        LoanCalculatorService.repaymentMethodFromString(
          'equal_principal_interest',
        ),
        RepaymentMethod.equalPrincipalInterest,
      );
      expect(
        LoanCalculatorService.repaymentMethodFromString('equal_principal'),
        RepaymentMethod.equalPrincipal,
      );
      expect(
        LoanCalculatorService.repaymentMethodFromString('bullet'),
        RepaymentMethod.bullet,
      );
      expect(
        LoanCalculatorService.repaymentMethodFromString('graduated'),
        RepaymentMethod.graduated,
      );
    });

    test('알 수 없는 문자열은 기본값(원리금균등)을 반환해야 한다', () {
      expect(
        LoanCalculatorService.repaymentMethodFromString('unknown'),
        RepaymentMethod.equalPrincipalInterest,
      );
    });
  });
}
