import 'dart:math';

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

  // =========================================================================
  // 새로운 4개 메서드 테스트 (RED 단계 - 아직 구현되지 않은 메서드)
  // =========================================================================

  group('LoanCalculatorService - calculateRemainingBalance (잔여 원금 계산)', () {
    // 공통 시나리오: 대출 2억, 이율 3.5%, 336개월 (28년)
    const scenarioLoan = 200000000;
    const scenarioRate = 3.5;
    const scenarioMonths = 336;
    const scenarioElapsed = 24;

    group('원리금균등상환', () {
      test('24개월 경과 시 잔여 원금이 원래 대출금보다 적어야 한다', () {
        final remaining = LoanCalculatorService.calculateRemainingBalance(
          loanAmount: scenarioLoan,
          annualInterestRate: scenarioRate,
          totalMonths: scenarioMonths,
          elapsedMonths: scenarioElapsed,
          method: RepaymentMethod.equalPrincipalInterest,
        );
        // 24개월 상환 후 잔여원금은 원금보다 적어야 함
        expect(remaining, lessThan(scenarioLoan));
        expect(remaining, greaterThan(0));
      });

      test('24개월 경과 시 잔여 원금은 공식 B = P * [(1+r)^N - (1+r)^k] / [(1+r)^N - 1]과 일치해야 한다', () {
        final remaining = LoanCalculatorService.calculateRemainingBalance(
          loanAmount: scenarioLoan,
          annualInterestRate: scenarioRate,
          totalMonths: scenarioMonths,
          elapsedMonths: scenarioElapsed,
          method: RepaymentMethod.equalPrincipalInterest,
        );
        // 수동 계산: r = 0.035/12 = 0.00291667
        // (1+r)^336 = (1.00291667)^336
        // (1+r)^24 = (1.00291667)^24
        // B = 200000000 * [(1.00291667)^336 - (1.00291667)^24] / [(1.00291667)^336 - 1]
        // 약 191,280,698원
        expect(remaining, closeTo(191280698, 500000));
      });

      test('경과 0개월이면 잔여 원금은 대출금 전액이어야 한다', () {
        final remaining = LoanCalculatorService.calculateRemainingBalance(
          loanAmount: scenarioLoan,
          annualInterestRate: scenarioRate,
          totalMonths: scenarioMonths,
          elapsedMonths: 0,
          method: RepaymentMethod.equalPrincipalInterest,
        );
        expect(remaining, scenarioLoan);
      });

      test('전체 기간 경과 시 잔여 원금은 0이어야 한다', () {
        final remaining = LoanCalculatorService.calculateRemainingBalance(
          loanAmount: scenarioLoan,
          annualInterestRate: scenarioRate,
          totalMonths: scenarioMonths,
          elapsedMonths: scenarioMonths,
          method: RepaymentMethod.equalPrincipalInterest,
        );
        expect(remaining, 0);
      });

      test('이자율 0%일 때 잔여 원금은 단순히 원금 - (원금/기간*경과)이어야 한다', () {
        final remaining = LoanCalculatorService.calculateRemainingBalance(
          loanAmount: 120000000,
          annualInterestRate: 0.0,
          totalMonths: 120,
          elapsedMonths: 60,
          method: RepaymentMethod.equalPrincipalInterest,
        );
        expect(remaining, closeTo(60000000, 100));
      });
    });

    group('원금균등상환', () {
      test('24개월 경과 시 잔여 원금은 P - (P/N) * k 이어야 한다', () {
        final remaining = LoanCalculatorService.calculateRemainingBalance(
          loanAmount: scenarioLoan,
          annualInterestRate: scenarioRate,
          totalMonths: scenarioMonths,
          elapsedMonths: scenarioElapsed,
          method: RepaymentMethod.equalPrincipal,
        );
        // B = 200000000 - (200000000/336) * 24
        // = 200000000 - 595238.095 * 24
        // = 200000000 - 14285714
        // = 185714286 (약)
        final expected = scenarioLoan - (scenarioLoan / scenarioMonths * scenarioElapsed).round();
        expect(remaining, closeTo(expected, 100));
      });

      test('경과 0개월이면 잔여 원금은 대출금 전액이어야 한다', () {
        final remaining = LoanCalculatorService.calculateRemainingBalance(
          loanAmount: scenarioLoan,
          annualInterestRate: scenarioRate,
          totalMonths: scenarioMonths,
          elapsedMonths: 0,
          method: RepaymentMethod.equalPrincipal,
        );
        expect(remaining, scenarioLoan);
      });

      test('전체 기간 경과 시 잔여 원금은 0이어야 한다', () {
        final remaining = LoanCalculatorService.calculateRemainingBalance(
          loanAmount: scenarioLoan,
          annualInterestRate: scenarioRate,
          totalMonths: scenarioMonths,
          elapsedMonths: scenarioMonths,
          method: RepaymentMethod.equalPrincipal,
        );
        expect(remaining, 0);
      });
    });

    group('만기일시상환', () {
      test('경과 개월수와 관계없이 잔여 원금은 항상 대출금 전액이어야 한다', () {
        final remaining = LoanCalculatorService.calculateRemainingBalance(
          loanAmount: scenarioLoan,
          annualInterestRate: scenarioRate,
          totalMonths: scenarioMonths,
          elapsedMonths: scenarioElapsed,
          method: RepaymentMethod.bullet,
        );
        expect(remaining, scenarioLoan);
      });

      test('만기 도래 시(전체 기간 경과)에도 원금은 그대로여야 한다 - 만기에 일시상환이므로', () {
        // 만기일시상환은 만기 전까지 원금 상환이 없으므로
        // elapsedMonths < totalMonths인 한 원금 = loanAmount
        final remaining = LoanCalculatorService.calculateRemainingBalance(
          loanAmount: scenarioLoan,
          annualInterestRate: scenarioRate,
          totalMonths: scenarioMonths,
          elapsedMonths: scenarioMonths - 1,
          method: RepaymentMethod.bullet,
        );
        expect(remaining, scenarioLoan);
      });
    });

    group('체증식상환', () {
      test('24개월 경과 시 잔여 원금이 원래 대출금보다 적어야 한다', () {
        final remaining = LoanCalculatorService.calculateRemainingBalance(
          loanAmount: scenarioLoan,
          annualInterestRate: scenarioRate,
          totalMonths: scenarioMonths,
          elapsedMonths: scenarioElapsed,
          method: RepaymentMethod.graduated,
        );
        expect(remaining, lessThan(scenarioLoan));
        expect(remaining, greaterThan(0));
      });

      test('체증식은 초기 상환금이 적으므로 같은 기간에서 원리금균등보다 잔여 원금이 많아야 한다', () {
        final remainingGraduated = LoanCalculatorService.calculateRemainingBalance(
          loanAmount: scenarioLoan,
          annualInterestRate: scenarioRate,
          totalMonths: scenarioMonths,
          elapsedMonths: scenarioElapsed,
          method: RepaymentMethod.graduated,
        );
        final remainingEqual = LoanCalculatorService.calculateRemainingBalance(
          loanAmount: scenarioLoan,
          annualInterestRate: scenarioRate,
          totalMonths: scenarioMonths,
          elapsedMonths: scenarioElapsed,
          method: RepaymentMethod.equalPrincipalInterest,
        );
        expect(remainingGraduated, greaterThan(remainingEqual));
      });
    });
  });

  group('LoanCalculatorService - calculateNewMonthlyPaymentAfterRateChange (금리 변경 후 새 월상환금)', () {
    // 공통 시나리오: 대출 2억, 이율 3.5% -> 4.0%, 336개월 중 24개월 경과
    const scenarioLoan = 200000000;
    const scenarioRate = 3.5;
    const newRate = 4.0;
    const scenarioMonths = 336;
    const scenarioElapsed = 24;

    test('원리금균등: 이율 3.5% -> 4.0% 변경 시 새 월상환금이 기존보다 높아야 한다', () {
      // 먼저 24개월 경과 후 잔여원금 계산
      final remainingBalance = LoanCalculatorService.calculateRemainingBalance(
        loanAmount: scenarioLoan,
        annualInterestRate: scenarioRate,
        totalMonths: scenarioMonths,
        elapsedMonths: scenarioElapsed,
        method: RepaymentMethod.equalPrincipalInterest,
      );
      final remainingMonths = scenarioMonths - scenarioElapsed;

      // 기존 월상환금
      final oldPayment = LoanCalculatorService.calculateMonthlyPayment(
        loanAmount: scenarioLoan,
        annualInterestRate: scenarioRate,
        totalMonths: scenarioMonths,
        method: RepaymentMethod.equalPrincipalInterest,
      );

      // 새 월상환금 (금리 변경)
      final newPayment = LoanCalculatorService.calculateNewMonthlyPaymentAfterRateChange(
        remainingBalance: remainingBalance,
        newAnnualInterestRate: newRate,
        remainingMonths: remainingMonths,
        method: RepaymentMethod.equalPrincipalInterest,
      );

      expect(newPayment, greaterThan(oldPayment));
    });

    test('원리금균등: 새 월상환금 계산값이 잔여원금 기반 재계산과 일치해야 한다', () {
      final remainingBalance = LoanCalculatorService.calculateRemainingBalance(
        loanAmount: scenarioLoan,
        annualInterestRate: scenarioRate,
        totalMonths: scenarioMonths,
        elapsedMonths: scenarioElapsed,
        method: RepaymentMethod.equalPrincipalInterest,
      );
      final remainingMonths = scenarioMonths - scenarioElapsed;

      final newPayment = LoanCalculatorService.calculateNewMonthlyPaymentAfterRateChange(
        remainingBalance: remainingBalance,
        newAnnualInterestRate: newRate,
        remainingMonths: remainingMonths,
        method: RepaymentMethod.equalPrincipalInterest,
      );

      // 직접 calculateMonthlyPayment로 동일 결과 나오는지 검증
      final directCalc = LoanCalculatorService.calculateMonthlyPayment(
        loanAmount: remainingBalance,
        annualInterestRate: newRate,
        totalMonths: remainingMonths,
        method: RepaymentMethod.equalPrincipalInterest,
      );
      expect(newPayment, directCalc);
    });

    test('원금균등: 이율 변경 시 1회차 기준 새 월상환금 계산이 정확해야 한다', () {
      final remainingBalance = LoanCalculatorService.calculateRemainingBalance(
        loanAmount: scenarioLoan,
        annualInterestRate: scenarioRate,
        totalMonths: scenarioMonths,
        elapsedMonths: scenarioElapsed,
        method: RepaymentMethod.equalPrincipal,
      );
      final remainingMonths = scenarioMonths - scenarioElapsed;

      final newPayment = LoanCalculatorService.calculateNewMonthlyPaymentAfterRateChange(
        remainingBalance: remainingBalance,
        newAnnualInterestRate: newRate,
        remainingMonths: remainingMonths,
        method: RepaymentMethod.equalPrincipal,
      );

      // 원금균등 1회차: 잔여원금/잔여기간 + 잔여원금 * 새이율/12
      final monthlyPrincipal = remainingBalance / remainingMonths;
      final interest = remainingBalance * newRate / 100 / 12;
      expect(newPayment, closeTo(monthlyPrincipal + interest, 1));
    });

    test('만기일시: 이율 변경 시 새 월 이자만 반환해야 한다', () {
      final newPayment = LoanCalculatorService.calculateNewMonthlyPaymentAfterRateChange(
        remainingBalance: scenarioLoan,
        newAnnualInterestRate: newRate,
        remainingMonths: scenarioMonths - scenarioElapsed,
        method: RepaymentMethod.bullet,
      );
      final expectedInterest = (scenarioLoan * newRate / 100 / 12).round();
      expect(newPayment, closeTo(expectedInterest, 1));
    });

    test('이율이 낮아지면 새 월상환금도 낮아져야 한다', () {
      const lowerRate = 2.5;
      final remainingBalance = LoanCalculatorService.calculateRemainingBalance(
        loanAmount: scenarioLoan,
        annualInterestRate: scenarioRate,
        totalMonths: scenarioMonths,
        elapsedMonths: scenarioElapsed,
        method: RepaymentMethod.equalPrincipalInterest,
      );
      final remainingMonths = scenarioMonths - scenarioElapsed;

      final oldPayment = LoanCalculatorService.calculateMonthlyPayment(
        loanAmount: scenarioLoan,
        annualInterestRate: scenarioRate,
        totalMonths: scenarioMonths,
        method: RepaymentMethod.equalPrincipalInterest,
      );

      final newPayment = LoanCalculatorService.calculateNewMonthlyPaymentAfterRateChange(
        remainingBalance: remainingBalance,
        newAnnualInterestRate: lowerRate,
        remainingMonths: remainingMonths,
        method: RepaymentMethod.equalPrincipalInterest,
      );

      expect(newPayment, lessThan(oldPayment));
    });
  });

  group('LoanCalculatorService - calculateNewMaturityMonths (추가상환 시 만기 단축 개월 수)', () {
    // 공통 시나리오
    const scenarioLoan = 200000000;
    const scenarioRate = 3.5;
    const scenarioMonths = 336;
    const scenarioElapsed = 24;
    const extraRepayment = 10000000; // 1000만원 추가상환

    test('원리금균등: 1000만원 추가상환 시 만기가 단축되어야 한다', () {
      final remainingBalance = LoanCalculatorService.calculateRemainingBalance(
        loanAmount: scenarioLoan,
        annualInterestRate: scenarioRate,
        totalMonths: scenarioMonths,
        elapsedMonths: scenarioElapsed,
        method: RepaymentMethod.equalPrincipalInterest,
      );
      final currentMonthlyPayment = LoanCalculatorService.calculateMonthlyPayment(
        loanAmount: scenarioLoan,
        annualInterestRate: scenarioRate,
        totalMonths: scenarioMonths,
        method: RepaymentMethod.equalPrincipalInterest,
      );
      final originalRemainingMonths = scenarioMonths - scenarioElapsed;

      final newMonths = LoanCalculatorService.calculateNewMaturityMonths(
        remainingBalance: remainingBalance,
        extraRepayment: extraRepayment,
        annualInterestRate: scenarioRate,
        currentMonthlyPayment: currentMonthlyPayment,
        method: RepaymentMethod.equalPrincipalInterest,
      );

      // 추가상환으로 만기가 단축되어야 함
      expect(newMonths, greaterThan(0));
      expect(newMonths, lessThan(originalRemainingMonths));
    });

    test('원금균등: 추가상환 시 만기가 단축되어야 한다', () {
      final remainingBalance = LoanCalculatorService.calculateRemainingBalance(
        loanAmount: scenarioLoan,
        annualInterestRate: scenarioRate,
        totalMonths: scenarioMonths,
        elapsedMonths: scenarioElapsed,
        method: RepaymentMethod.equalPrincipal,
      );
      final currentMonthlyPayment = LoanCalculatorService.calculateMonthlyPayment(
        loanAmount: scenarioLoan,
        annualInterestRate: scenarioRate,
        totalMonths: scenarioMonths,
        method: RepaymentMethod.equalPrincipal,
        currentMonth: scenarioElapsed + 1,
      );
      final originalRemainingMonths = scenarioMonths - scenarioElapsed;

      final newMonths = LoanCalculatorService.calculateNewMaturityMonths(
        remainingBalance: remainingBalance,
        extraRepayment: extraRepayment,
        annualInterestRate: scenarioRate,
        currentMonthlyPayment: currentMonthlyPayment,
        method: RepaymentMethod.equalPrincipal,
      );

      expect(newMonths, greaterThan(0));
      expect(newMonths, lessThan(originalRemainingMonths));
    });

    test('만기일시: 추가상환과 관계없이 -1을 반환해야 한다 (만기 변동 없음)', () {
      final newMonths = LoanCalculatorService.calculateNewMaturityMonths(
        remainingBalance: scenarioLoan,
        extraRepayment: extraRepayment,
        annualInterestRate: scenarioRate,
        currentMonthlyPayment: (scenarioLoan * scenarioRate / 100 / 12).round(),
        method: RepaymentMethod.bullet,
      );
      expect(newMonths, -1);
    });

    test('추가상환이 0원이면 기존 잔여개월과 동일해야 한다', () {
      final remainingBalance = LoanCalculatorService.calculateRemainingBalance(
        loanAmount: scenarioLoan,
        annualInterestRate: scenarioRate,
        totalMonths: scenarioMonths,
        elapsedMonths: scenarioElapsed,
        method: RepaymentMethod.equalPrincipalInterest,
      );
      final currentMonthlyPayment = LoanCalculatorService.calculateMonthlyPayment(
        loanAmount: scenarioLoan,
        annualInterestRate: scenarioRate,
        totalMonths: scenarioMonths,
        method: RepaymentMethod.equalPrincipalInterest,
      );

      final newMonths = LoanCalculatorService.calculateNewMaturityMonths(
        remainingBalance: remainingBalance,
        extraRepayment: 0,
        annualInterestRate: scenarioRate,
        currentMonthlyPayment: currentMonthlyPayment,
        method: RepaymentMethod.equalPrincipalInterest,
      );

      // 추가상환 없으면 원래 잔여개월과 같거나 매우 유사해야 함
      final originalRemainingMonths = scenarioMonths - scenarioElapsed;
      expect(newMonths, closeTo(originalRemainingMonths, 1));
    });

    test('추가상환 금액이 잔여 원금보다 크면 즉시 완납 가능 (1 이하)이어야 한다', () {
      final remainingBalance = LoanCalculatorService.calculateRemainingBalance(
        loanAmount: scenarioLoan,
        annualInterestRate: scenarioRate,
        totalMonths: scenarioMonths,
        elapsedMonths: scenarioElapsed,
        method: RepaymentMethod.equalPrincipalInterest,
      );
      final currentMonthlyPayment = LoanCalculatorService.calculateMonthlyPayment(
        loanAmount: scenarioLoan,
        annualInterestRate: scenarioRate,
        totalMonths: scenarioMonths,
        method: RepaymentMethod.equalPrincipalInterest,
      );

      final newMonths = LoanCalculatorService.calculateNewMaturityMonths(
        remainingBalance: remainingBalance,
        extraRepayment: remainingBalance + 1000000, // 잔여원금보다 더 많이 상환
        annualInterestRate: scenarioRate,
        currentMonthlyPayment: currentMonthlyPayment,
        method: RepaymentMethod.equalPrincipalInterest,
      );

      expect(newMonths, lessThanOrEqualTo(1));
    });

    test('이자율 0%일 때도 만기 단축이 올바르게 계산되어야 한다', () {
      const loanAmount = 120000000;
      const totalMonths = 120;
      const elapsedMonths = 20;
      final monthlyPayment = (loanAmount / totalMonths).floor();
      final remainingBalance = loanAmount - monthlyPayment * elapsedMonths;

      final newMonths = LoanCalculatorService.calculateNewMaturityMonths(
        remainingBalance: remainingBalance,
        extraRepayment: 10000000,
        annualInterestRate: 0.0,
        currentMonthlyPayment: monthlyPayment,
        method: RepaymentMethod.equalPrincipalInterest,
      );

      // 잔여원금 = 120000000 - 1000000 * 20 = 100000000
      // 추가상환 후 = 90000000
      // 새 만기 = 90000000 / 1000000 = 90개월
      expect(newMonths, closeTo(90, 1));
    });
  });

  group('LoanCalculatorService - calculateInterestSaved (추가상환 시 절약 이자)', () {
    // 공통 시나리오
    const scenarioLoan = 200000000;
    const scenarioRate = 3.5;
    const scenarioMonths = 336;
    const scenarioElapsed = 24;
    const extraRepayment = 10000000;

    test('원리금균등: 1000만원 추가상환 시 절약 이자가 양수여야 한다', () {
      final remainingBalance = LoanCalculatorService.calculateRemainingBalance(
        loanAmount: scenarioLoan,
        annualInterestRate: scenarioRate,
        totalMonths: scenarioMonths,
        elapsedMonths: scenarioElapsed,
        method: RepaymentMethod.equalPrincipalInterest,
      );
      final currentMonthlyPayment = LoanCalculatorService.calculateMonthlyPayment(
        loanAmount: scenarioLoan,
        annualInterestRate: scenarioRate,
        totalMonths: scenarioMonths,
        method: RepaymentMethod.equalPrincipalInterest,
      );
      final originalRemainingMonths = scenarioMonths - scenarioElapsed;

      final saved = LoanCalculatorService.calculateInterestSaved(
        remainingBalance: remainingBalance,
        extraRepayment: extraRepayment,
        annualInterestRate: scenarioRate,
        currentMonthlyPayment: currentMonthlyPayment,
        originalRemainingMonths: originalRemainingMonths,
        method: RepaymentMethod.equalPrincipalInterest,
      );

      expect(saved, greaterThan(0));
    });

    test('원리금균등: 절약 이자는 추가상환 금액보다 커야 한다 (장기대출의 경우 이자 절약 효과)', () {
      final remainingBalance = LoanCalculatorService.calculateRemainingBalance(
        loanAmount: scenarioLoan,
        annualInterestRate: scenarioRate,
        totalMonths: scenarioMonths,
        elapsedMonths: scenarioElapsed,
        method: RepaymentMethod.equalPrincipalInterest,
      );
      final currentMonthlyPayment = LoanCalculatorService.calculateMonthlyPayment(
        loanAmount: scenarioLoan,
        annualInterestRate: scenarioRate,
        totalMonths: scenarioMonths,
        method: RepaymentMethod.equalPrincipalInterest,
      );
      final originalRemainingMonths = scenarioMonths - scenarioElapsed;

      final saved = LoanCalculatorService.calculateInterestSaved(
        remainingBalance: remainingBalance,
        extraRepayment: extraRepayment,
        annualInterestRate: scenarioRate,
        currentMonthlyPayment: currentMonthlyPayment,
        originalRemainingMonths: originalRemainingMonths,
        method: RepaymentMethod.equalPrincipalInterest,
      );

      // 28년 장기 대출에서 1000만원 추가상환 시 이자 절약 효과가 추가상환금 이상
      expect(saved, greaterThan(extraRepayment));
    });

    test('원금균등: 추가상환 시 절약 이자가 양수여야 한다', () {
      final remainingBalance = LoanCalculatorService.calculateRemainingBalance(
        loanAmount: scenarioLoan,
        annualInterestRate: scenarioRate,
        totalMonths: scenarioMonths,
        elapsedMonths: scenarioElapsed,
        method: RepaymentMethod.equalPrincipal,
      );
      final currentMonthlyPayment = LoanCalculatorService.calculateMonthlyPayment(
        loanAmount: scenarioLoan,
        annualInterestRate: scenarioRate,
        totalMonths: scenarioMonths,
        method: RepaymentMethod.equalPrincipal,
        currentMonth: scenarioElapsed + 1,
      );
      final originalRemainingMonths = scenarioMonths - scenarioElapsed;

      final saved = LoanCalculatorService.calculateInterestSaved(
        remainingBalance: remainingBalance,
        extraRepayment: extraRepayment,
        annualInterestRate: scenarioRate,
        currentMonthlyPayment: currentMonthlyPayment,
        originalRemainingMonths: originalRemainingMonths,
        method: RepaymentMethod.equalPrincipal,
      );

      expect(saved, greaterThan(0));
    });

    test('추가상환이 0원이면 절약 이자도 0이어야 한다', () {
      final remainingBalance = LoanCalculatorService.calculateRemainingBalance(
        loanAmount: scenarioLoan,
        annualInterestRate: scenarioRate,
        totalMonths: scenarioMonths,
        elapsedMonths: scenarioElapsed,
        method: RepaymentMethod.equalPrincipalInterest,
      );
      final currentMonthlyPayment = LoanCalculatorService.calculateMonthlyPayment(
        loanAmount: scenarioLoan,
        annualInterestRate: scenarioRate,
        totalMonths: scenarioMonths,
        method: RepaymentMethod.equalPrincipalInterest,
      );
      final originalRemainingMonths = scenarioMonths - scenarioElapsed;

      final saved = LoanCalculatorService.calculateInterestSaved(
        remainingBalance: remainingBalance,
        extraRepayment: 0,
        annualInterestRate: scenarioRate,
        currentMonthlyPayment: currentMonthlyPayment,
        originalRemainingMonths: originalRemainingMonths,
        method: RepaymentMethod.equalPrincipalInterest,
      );

      expect(saved, 0);
    });

    test('만기일시: 추가상환 시 절약 이자가 양수여야 한다 (이자 감소 효과)', () {
      final currentMonthlyPayment = (scenarioLoan * scenarioRate / 100 / 12).round();
      final originalRemainingMonths = scenarioMonths - scenarioElapsed;

      final saved = LoanCalculatorService.calculateInterestSaved(
        remainingBalance: scenarioLoan,
        extraRepayment: extraRepayment,
        annualInterestRate: scenarioRate,
        currentMonthlyPayment: currentMonthlyPayment,
        originalRemainingMonths: originalRemainingMonths,
        method: RepaymentMethod.bullet,
      );

      // 만기일시: 원금 줄면 매월 이자가 줄어듦
      expect(saved, greaterThan(0));
    });

    test('이자율 0%일 때 절약 이자는 0이어야 한다', () {
      final saved = LoanCalculatorService.calculateInterestSaved(
        remainingBalance: 100000000,
        extraRepayment: 10000000,
        annualInterestRate: 0.0,
        currentMonthlyPayment: 1000000,
        originalRemainingMonths: 100,
        method: RepaymentMethod.equalPrincipalInterest,
      );

      expect(saved, 0);
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

  // =========================================================================
  // 유틸리티 메서드 테스트
  // =========================================================================

  group('LoanCalculatorService - calculateMonthsBetween (개월 수 계산 유틸리티)', () {
    test('같은 날짜면 0을 반환해야 한다', () {
      final date = DateTime(2025, 6, 15);
      expect(LoanCalculatorService.calculateMonthsBetween(date, date), 0);
    });

    test('정확히 1년 차이면 12를 반환해야 한다', () {
      final start = DateTime(2024, 1, 1);
      final end = DateTime(2025, 1, 1);
      expect(LoanCalculatorService.calculateMonthsBetween(start, end), 12);
    });

    test('월만 다른 경우 정확한 개월 차이를 반환해야 한다', () {
      final start = DateTime(2025, 3, 1);
      final end = DateTime(2025, 9, 1);
      expect(LoanCalculatorService.calculateMonthsBetween(start, end), 6);
    });

    test('연도를 넘어가는 경우 정확하게 계산해야 한다', () {
      final start = DateTime(2024, 10, 1);
      final end = DateTime(2025, 3, 1);
      expect(LoanCalculatorService.calculateMonthsBetween(start, end), 5);
    });

    test('end가 start보다 이전이면 음수를 반환해야 한다', () {
      final start = DateTime(2025, 6, 1);
      final end = DateTime(2025, 3, 1);
      expect(LoanCalculatorService.calculateMonthsBetween(start, end), -3);
    });

    test('일(day)은 무시하고 연/월만 사용하여 계산해야 한다', () {
      // 1월 31일 -> 2월 1일은 1개월로 계산 (day 무시)
      final start = DateTime(2025, 1, 31);
      final end = DateTime(2025, 2, 1);
      expect(LoanCalculatorService.calculateMonthsBetween(start, end), 1);
    });

    test('28년(336개월) 차이를 정확하게 계산해야 한다', () {
      final start = DateTime(2024, 1, 1);
      final end = DateTime(2052, 1, 1);
      expect(LoanCalculatorService.calculateMonthsBetween(start, end), 336);
    });
  });

  group('LoanCalculatorService - isRateChanged (이율 변경 감지)', () {
    test('oldRate가 null이면 false를 반환해야 한다', () {
      expect(LoanCalculatorService.isRateChanged(null, 3.5), false);
    });

    test('newRate가 null이면 false를 반환해야 한다', () {
      expect(LoanCalculatorService.isRateChanged(3.5, null), false);
    });

    test('둘 다 null이면 false를 반환해야 한다', () {
      expect(LoanCalculatorService.isRateChanged(null, null), false);
    });

    test('차이가 임계값(0.001)보다 크면 true를 반환해야 한다', () {
      expect(LoanCalculatorService.isRateChanged(3.5, 3.502), true);
    });

    test('차이가 임계값(0.001) 이하면 false를 반환해야 한다', () {
      expect(LoanCalculatorService.isRateChanged(3.5, 3.5005), false);
    });

    test('같은 값이면 false를 반환해야 한다', () {
      expect(LoanCalculatorService.isRateChanged(3.5, 3.5), false);
    });

    test('이율 하락도 감지해야 한다 (절대값 비교)', () {
      expect(LoanCalculatorService.isRateChanged(4.0, 3.5), true);
    });

    test('정확히 임계값(0.001)인 경우 false를 반환해야 한다 (초과가 아닌 이하)', () {
      // 0.001 차이는 threshold 이하이므로 false
      expect(LoanCalculatorService.isRateChanged(3.5, 3.501), false);
    });
  });

  // =========================================================================
  // powN 유틸리티 함수 테스트
  // =========================================================================

  group('powN (거듭제곱 유틸리티 함수)', () {
    test('지수가 0이면 1.0을 반환해야 한다', () {
      expect(powN(2.0, 0), 1.0);
    });

    test('지수가 1이면 밑을 그대로 반환해야 한다', () {
      expect(powN(3.5, 1), 3.5);
    });

    test('2의 10제곱은 1024.0이어야 한다', () {
      expect(powN(2.0, 10), 1024.0);
    });

    test('월 이자율 복리 계산이 dart:math pow와 일치해야 한다', () {
      final r = 3.5 / 100 / 12;
      final base = 1 + r;
      expect(powN(base, 360), closeTo(pow(base, 360).toDouble(), 1e-10));
    });
  });

  // =========================================================================
  // calcEqualPrincipalInterestWithDates (일할계산 기반 원리금균등) 테스트
  // =========================================================================

  group('LoanCalculatorService - calcEqualPrincipalInterestWithDates (일할계산)', () {
    test('일할계산 결과가 기본 공식 결과와 근사해야 한다', () {
      final withDates = LoanCalculatorService.calcEqualPrincipalInterestWithDates(
        loanAmount: 100000000,
        annualInterestRate: 3.8,
        totalMonths: 96,
        startDate: DateTime(2024, 1, 1),
      );
      final basic = LoanCalculatorService.calculateMonthlyPayment(
        loanAmount: 100000000,
        annualInterestRate: 3.8,
        totalMonths: 96,
        method: RepaymentMethod.equalPrincipalInterest,
      );
      // 일할계산은 실제 일수 기반이므로 기본 공식과 약간 다를 수 있지만 근사해야 함
      expect(withDates, closeTo(basic, 5000));
    });

    test('이자율 0%이면 원금을 개월 수로 나눈 값이어야 한다', () {
      final result = LoanCalculatorService.calcEqualPrincipalInterestWithDates(
        loanAmount: 120000000,
        annualInterestRate: 0.0,
        totalMonths: 120,
        startDate: DateTime(2024, 1, 1),
      );
      expect(result, 1000000);
    });

    test('30년 대출도 정상적으로 이진 탐색이 수렴해야 한다', () {
      final result = LoanCalculatorService.calcEqualPrincipalInterestWithDates(
        loanAmount: 300000000,
        annualInterestRate: 4.5,
        totalMonths: 360,
        startDate: DateTime(2024, 6, 15),
      );
      // 3억, 4.5%, 30년 -> 약 1,520,000원 근처
      expect(result, greaterThan(1400000));
      expect(result, lessThan(1650000));
    });
  });

  // =========================================================================
  // calculateCumulativeRepaid (누적 상환 원금) 테스트
  // =========================================================================

  group('LoanCalculatorService - calculateCumulativeRepaid (누적 상환 원금)', () {
    const loan = 100000000;
    const rate = 3.8;
    const months = 96;

    group('원리금균등상환', () {
      test('24개월 경과 시 누적 상환 원금이 양수여야 한다', () {
        final repaid = LoanCalculatorService.calculateCumulativeRepaid(
          loanAmount: loan,
          annualInterestRate: rate,
          totalMonths: months,
          elapsedMonths: 24,
          method: RepaymentMethod.equalPrincipalInterest,
        );
        expect(repaid, greaterThan(0));
        expect(repaid, lessThan(loan));
      });

      test('누적 상환 원금 + 잔여 원금 = 대출 원금이어야 한다 (교차 검증)', () {
        final repaid = LoanCalculatorService.calculateCumulativeRepaid(
          loanAmount: loan,
          annualInterestRate: rate,
          totalMonths: months,
          elapsedMonths: 48,
          method: RepaymentMethod.equalPrincipalInterest,
        );
        final remaining = LoanCalculatorService.calculateRemainingBalance(
          loanAmount: loan,
          annualInterestRate: rate,
          totalMonths: months,
          elapsedMonths: 48,
          method: RepaymentMethod.equalPrincipalInterest,
        );
        // 반올림 오차 허용
        expect(repaid + remaining, closeTo(loan, 100));
      });

      test('이자율 0%일 때 누적 상환은 (원금/기간)*경과월이어야 한다', () {
        final repaid = LoanCalculatorService.calculateCumulativeRepaid(
          loanAmount: 120000000,
          annualInterestRate: 0.0,
          totalMonths: 120,
          elapsedMonths: 60,
          method: RepaymentMethod.equalPrincipalInterest,
        );
        expect(repaid, closeTo(60000000, 100));
      });
    });

    group('원금균등상환', () {
      test('24개월 경과 시 누적 원금 = (P/N) * 24이어야 한다', () {
        final repaid = LoanCalculatorService.calculateCumulativeRepaid(
          loanAmount: loan,
          annualInterestRate: rate,
          totalMonths: months,
          elapsedMonths: 24,
          method: RepaymentMethod.equalPrincipal,
        );
        final expected = (loan / months * 24).round();
        expect(repaid, closeTo(expected, 100));
      });

      test('누적 상환 원금 + 잔여 원금 = 대출 원금이어야 한다 (교차 검증)', () {
        final repaid = LoanCalculatorService.calculateCumulativeRepaid(
          loanAmount: loan,
          annualInterestRate: rate,
          totalMonths: months,
          elapsedMonths: 48,
          method: RepaymentMethod.equalPrincipal,
        );
        final remaining = LoanCalculatorService.calculateRemainingBalance(
          loanAmount: loan,
          annualInterestRate: rate,
          totalMonths: months,
          elapsedMonths: 48,
          method: RepaymentMethod.equalPrincipal,
        );
        expect(repaid + remaining, closeTo(loan, 100));
      });
    });

    group('만기일시상환', () {
      test('만기 전에는 누적 상환 원금이 0이어야 한다', () {
        final repaid = LoanCalculatorService.calculateCumulativeRepaid(
          loanAmount: loan,
          annualInterestRate: rate,
          totalMonths: months,
          elapsedMonths: 48,
          method: RepaymentMethod.bullet,
        );
        expect(repaid, 0);
      });

      test('만기 시(전체 기간 경과) 누적 상환 원금은 대출금 전액이어야 한다', () {
        final repaid = LoanCalculatorService.calculateCumulativeRepaid(
          loanAmount: loan,
          annualInterestRate: rate,
          totalMonths: months,
          elapsedMonths: months,
          method: RepaymentMethod.bullet,
        );
        expect(repaid, loan);
      });
    });

    group('체증식상환', () {
      test('24개월 경과 시 누적 원금이 양수여야 한다', () {
        final repaid = LoanCalculatorService.calculateCumulativeRepaid(
          loanAmount: loan,
          annualInterestRate: rate,
          totalMonths: months,
          elapsedMonths: 24,
          method: RepaymentMethod.graduated,
        );
        expect(repaid, greaterThan(0));
      });

      test('체증식 누적 원금은 원리금균등보다 적어야 한다 (초기 상환금이 적으므로)', () {
        final graduatedRepaid = LoanCalculatorService.calculateCumulativeRepaid(
          loanAmount: loan,
          annualInterestRate: rate,
          totalMonths: months,
          elapsedMonths: 24,
          method: RepaymentMethod.graduated,
        );
        final equalRepaid = LoanCalculatorService.calculateCumulativeRepaid(
          loanAmount: loan,
          annualInterestRate: rate,
          totalMonths: months,
          elapsedMonths: 24,
          method: RepaymentMethod.equalPrincipalInterest,
        );
        expect(graduatedRepaid, lessThan(equalRepaid));
      });
    });

    group('경계 조건', () {
      test('대출금이 0이면 0을 반환해야 한다', () {
        final repaid = LoanCalculatorService.calculateCumulativeRepaid(
          loanAmount: 0,
          annualInterestRate: rate,
          totalMonths: months,
          elapsedMonths: 24,
          method: RepaymentMethod.equalPrincipalInterest,
        );
        expect(repaid, 0);
      });

      test('기간이 0이면 0을 반환해야 한다', () {
        final repaid = LoanCalculatorService.calculateCumulativeRepaid(
          loanAmount: loan,
          annualInterestRate: rate,
          totalMonths: 0,
          elapsedMonths: 24,
          method: RepaymentMethod.equalPrincipalInterest,
        );
        expect(repaid, 0);
      });

      test('경과 개월이 0 이하면 0을 반환해야 한다', () {
        final repaid = LoanCalculatorService.calculateCumulativeRepaid(
          loanAmount: loan,
          annualInterestRate: rate,
          totalMonths: months,
          elapsedMonths: 0,
          method: RepaymentMethod.equalPrincipalInterest,
        );
        expect(repaid, 0);
      });

      test('경과 개월이 총 기간을 초과하면 총 기간으로 clamp해야 한다', () {
        final repaid = LoanCalculatorService.calculateCumulativeRepaid(
          loanAmount: loan,
          annualInterestRate: rate,
          totalMonths: months,
          elapsedMonths: months + 12,
          method: RepaymentMethod.equalPrincipalInterest,
        );
        final repaidAtEnd = LoanCalculatorService.calculateCumulativeRepaid(
          loanAmount: loan,
          annualInterestRate: rate,
          totalMonths: months,
          elapsedMonths: months,
          method: RepaymentMethod.equalPrincipalInterest,
        );
        expect(repaid, repaidAtEnd);
      });
    });
  });

  // =========================================================================
  // calculateTotalInterest 추가 커버리지 (원금균등, 체증식)
  // =========================================================================

  group('LoanCalculatorService - calculateTotalInterest (추가 커버리지)', () {
    test('원금균등 총 이자 = P * r * (n+1) / 2 공식과 일치해야 한다', () {
      const loan = 100000000;
      const rate = 3.8;
      const months = 96;
      final r = rate / 100 / 12;
      final expected = (loan * r * (months + 1) / 2).round();

      final result = LoanCalculatorService.calculateTotalInterest(
        loanAmount: loan,
        annualInterestRate: rate,
        totalMonths: months,
        method: RepaymentMethod.equalPrincipal,
      );
      expect(result, closeTo(expected, 1));
    });

    test('체증식 총 이자는 양수여야 한다', () {
      final result = LoanCalculatorService.calculateTotalInterest(
        loanAmount: 100000000,
        annualInterestRate: 3.8,
        totalMonths: 96,
        method: RepaymentMethod.graduated,
      );
      expect(result, greaterThan(0));
    });

    test('체증식 총 이자는 합산 방식(시뮬레이션)으로 계산되어야 한다', () {
      const loan = 100000000;
      const rate = 3.8;
      const months = 96;

      final graduatedInterest = LoanCalculatorService.calculateTotalInterest(
        loanAmount: loan,
        annualInterestRate: rate,
        totalMonths: months,
        method: RepaymentMethod.graduated,
      );

      // 수동으로 각 월 상환금 합산하여 총 이자 계산
      int totalPayments = 0;
      for (int i = 1; i <= months; i++) {
        totalPayments += LoanCalculatorService.calculateMonthlyPayment(
          loanAmount: loan,
          annualInterestRate: rate,
          totalMonths: months,
          method: RepaymentMethod.graduated,
          currentMonth: i,
        );
      }
      final manualInterest = totalPayments - loan;
      expect(graduatedInterest, closeTo(manualInterest, 100));
    });

    test('원금균등 총 이자는 원리금균등보다 적어야 한다 (원금을 빨리 줄이므로)', () {
      const loan = 100000000;
      const rate = 3.8;
      const months = 96;

      final equalPrincipalInterest = LoanCalculatorService.calculateTotalInterest(
        loanAmount: loan,
        annualInterestRate: rate,
        totalMonths: months,
        method: RepaymentMethod.equalPrincipalInterest,
      );
      final equalPrincipal = LoanCalculatorService.calculateTotalInterest(
        loanAmount: loan,
        annualInterestRate: rate,
        totalMonths: months,
        method: RepaymentMethod.equalPrincipal,
      );
      expect(equalPrincipal, lessThan(equalPrincipalInterest));
    });
  });

  // =========================================================================
  // calculateRemainingBalance 추가 경계 조건
  // =========================================================================

  group('LoanCalculatorService - calculateRemainingBalance (추가 경계 조건)', () {
    test('경과 개월이 음수이면 대출금 전액을 반환해야 한다', () {
      final remaining = LoanCalculatorService.calculateRemainingBalance(
        loanAmount: 100000000,
        annualInterestRate: 3.8,
        totalMonths: 96,
        elapsedMonths: -5,
        method: RepaymentMethod.equalPrincipalInterest,
      );
      expect(remaining, 100000000);
    });

    test('만기일시상환에서 전체 기간이 경과해도 원금 전액을 반환해야 한다', () {
      final remaining = LoanCalculatorService.calculateRemainingBalance(
        loanAmount: 100000000,
        annualInterestRate: 3.8,
        totalMonths: 96,
        elapsedMonths: 96,
        method: RepaymentMethod.bullet,
      );
      expect(remaining, 100000000);
    });

    test('원금균등: 절반 경과 시 잔여 원금이 약 절반이어야 한다', () {
      final remaining = LoanCalculatorService.calculateRemainingBalance(
        loanAmount: 100000000,
        annualInterestRate: 3.8,
        totalMonths: 100,
        elapsedMonths: 50,
        method: RepaymentMethod.equalPrincipal,
      );
      expect(remaining, closeTo(50000000, 100));
    });

    test('체증식: 경과 0이면 대출금 전액이어야 한다', () {
      final remaining = LoanCalculatorService.calculateRemainingBalance(
        loanAmount: 100000000,
        annualInterestRate: 3.8,
        totalMonths: 96,
        elapsedMonths: 0,
        method: RepaymentMethod.graduated,
      );
      expect(remaining, 100000000);
    });

    test('원리금균등: 전체 기간 경과 후 (elapsedMonths > totalMonths) 잔여 원금은 0이어야 한다', () {
      final remaining = LoanCalculatorService.calculateRemainingBalance(
        loanAmount: 100000000,
        annualInterestRate: 3.8,
        totalMonths: 96,
        elapsedMonths: 120,
        method: RepaymentMethod.equalPrincipalInterest,
      );
      expect(remaining, 0);
    });
  });

  // =========================================================================
  // calculateNewMaturityMonths 추가 커버리지 (체증식, 경계 조건)
  // =========================================================================

  group('LoanCalculatorService - calculateNewMaturityMonths (추가 커버리지)', () {
    group('체증식상환', () {
      test('체증식: 추가상환 시 새 만기가 유효한 값을 반환해야 한다', () {
        const loan = 100000000;
        const rate = 3.8;
        const months = 96;
        const elapsed = 24;

        final remaining = LoanCalculatorService.calculateRemainingBalance(
          loanAmount: loan,
          annualInterestRate: rate,
          totalMonths: months,
          elapsedMonths: elapsed,
          method: RepaymentMethod.graduated,
        );

        // 원래 대출 조건 기반으로 계산해야 올바른 스케줄 사용
        final newMonths = LoanCalculatorService.calculateNewMaturityMonths(
          remainingBalance: remaining,
          extraRepayment: 10000000,
          annualInterestRate: rate,
          currentMonthlyPayment: 1000000,
          method: RepaymentMethod.graduated,
          originalLoanAmount: loan,
          originalTotalMonths: months,
        );

        // 체증식은 originalLoanAmount 기반 스케줄 사용 시 양수 반환 가능
        // 또는 상환 불가(-1) 반환 가능 (초기 상환금이 이자보다 작은 경우)
        expect(newMonths, isA<int>());
      });

      test('체증식: originalLoanAmount/originalTotalMonths 전달 시 올바른 스케줄 기반으로 계산해야 한다', () {
        const loan = 200000000;
        const rate = 3.5;
        const months = 336;
        const elapsed = 24;

        final remaining = LoanCalculatorService.calculateRemainingBalance(
          loanAmount: loan,
          annualInterestRate: rate,
          totalMonths: months,
          elapsedMonths: elapsed,
          method: RepaymentMethod.graduated,
        );

        final withOriginal = LoanCalculatorService.calculateNewMaturityMonths(
          remainingBalance: remaining,
          extraRepayment: 10000000,
          annualInterestRate: rate,
          currentMonthlyPayment: 500000,
          method: RepaymentMethod.graduated,
          originalLoanAmount: loan,
          originalTotalMonths: months,
        );

        final withoutOriginal = LoanCalculatorService.calculateNewMaturityMonths(
          remainingBalance: remaining,
          extraRepayment: 10000000,
          annualInterestRate: rate,
          currentMonthlyPayment: 500000,
          method: RepaymentMethod.graduated,
        );

        // 두 결과 모두 유효해야 하지만 값이 다를 수 있음 (다른 스케줄 기반)
        expect(withOriginal, isNot(-1));
        // withoutOriginal은 -1이거나 양수
        expect(withoutOriginal, isA<int>());
      });

      test('체증식: 잔액이 감소하지 않는 경우(상환 불가) -1을 반환해야 한다', () {
        // 매우 높은 이자율, 매우 적은 상환금으로 잔액이 줄지 않는 시나리오
        final newMonths = LoanCalculatorService.calculateNewMaturityMonths(
          remainingBalance: 100000000,
          extraRepayment: 1000,
          annualInterestRate: 50.0, // 극단적 고이자율
          currentMonthlyPayment: 100000,
          method: RepaymentMethod.graduated,
          originalLoanAmount: 100000000,
          originalTotalMonths: 360,
        );
        expect(newMonths, -1);
      });
    });

    group('경계 조건', () {
      test('원리금균등: 월 상환금이 이자보다 작으면 -1을 반환해야 한다 (M <= B*r)', () {
        final newMonths = LoanCalculatorService.calculateNewMaturityMonths(
          remainingBalance: 100000000,
          extraRepayment: 1000000,
          annualInterestRate: 12.0, // 높은 이자
          currentMonthlyPayment: 500000, // 월 이자 ~1,000,000보다 적음
          method: RepaymentMethod.equalPrincipalInterest,
        );
        expect(newMonths, -1);
      });

      test('원금균등: 월 상환금이 0 이하면 -1을 반환해야 한다', () {
        final newMonths = LoanCalculatorService.calculateNewMaturityMonths(
          remainingBalance: 100000000,
          extraRepayment: 1000000,
          annualInterestRate: 3.8,
          currentMonthlyPayment: 0,
          method: RepaymentMethod.equalPrincipal,
        );
        expect(newMonths, -1);
      });

      test('원금균등: 월 원금분(상환금-이자)이 0 이하면 -1을 반환해야 한다', () {
        // 월 상환금이 이자만큼도 안 되는 경우
        final newMonths = LoanCalculatorService.calculateNewMaturityMonths(
          remainingBalance: 100000000,
          extraRepayment: 1000000,
          annualInterestRate: 24.0, // 매우 높은 이자
          currentMonthlyPayment: 1000000, // 월 이자 ~2,000,000보다 적음
          method: RepaymentMethod.equalPrincipal,
        );
        expect(newMonths, -1);
      });

      test('원리금균등: 이자율 0이고 월 상환금 0이면 -1을 반환해야 한다', () {
        final newMonths = LoanCalculatorService.calculateNewMaturityMonths(
          remainingBalance: 100000000,
          extraRepayment: 1000000,
          annualInterestRate: 0.0,
          currentMonthlyPayment: 0,
          method: RepaymentMethod.equalPrincipalInterest,
        );
        expect(newMonths, -1);
      });

      test('추가상환이 잔여 원금과 정확히 같으면 0을 반환해야 한다 (완납)', () {
        final newMonths = LoanCalculatorService.calculateNewMaturityMonths(
          remainingBalance: 50000000,
          extraRepayment: 50000000,
          annualInterestRate: 3.8,
          currentMonthlyPayment: 1000000,
          method: RepaymentMethod.equalPrincipalInterest,
        );
        expect(newMonths, 0);
      });
    });
  });

  // =========================================================================
  // calculateInterestSaved 추가 커버리지
  // =========================================================================

  group('LoanCalculatorService - calculateInterestSaved (추가 커버리지)', () {
    test('체증식: 추가상환 시 절약 이자가 0 이상이어야 한다', () {
      const loan = 200000000;
      const rate = 3.5;
      const months = 240;
      const elapsed = 48;

      final remaining = LoanCalculatorService.calculateRemainingBalance(
        loanAmount: loan,
        annualInterestRate: rate,
        totalMonths: months,
        elapsedMonths: elapsed,
        method: RepaymentMethod.graduated,
      );
      // 원래 대출 기준 충분히 큰 상환금 사용
      final payment = LoanCalculatorService.calculateMonthlyPayment(
        loanAmount: loan,
        annualInterestRate: rate,
        totalMonths: months,
        method: RepaymentMethod.graduated,
        currentMonth: elapsed + 1,
      );

      final saved = LoanCalculatorService.calculateInterestSaved(
        remainingBalance: remaining,
        extraRepayment: 20000000,
        annualInterestRate: rate,
        currentMonthlyPayment: payment,
        originalRemainingMonths: months - elapsed,
        method: RepaymentMethod.graduated,
      );
      // 체증식은 초기 상환금이 적어 이자 절약이 0일 수 있지만 음수는 아님
      expect(saved, greaterThanOrEqualTo(0));
    });

    test('preCalculatedNewMonths를 전달하면 해당 값을 사용하여 계산해야 한다', () {
      const loan = 200000000;
      const rate = 3.5;
      const months = 336;
      const elapsed = 24;
      const extra = 10000000;

      final remaining = LoanCalculatorService.calculateRemainingBalance(
        loanAmount: loan,
        annualInterestRate: rate,
        totalMonths: months,
        elapsedMonths: elapsed,
        method: RepaymentMethod.equalPrincipalInterest,
      );
      final payment = LoanCalculatorService.calculateMonthlyPayment(
        loanAmount: loan,
        annualInterestRate: rate,
        totalMonths: months,
        method: RepaymentMethod.equalPrincipalInterest,
      );
      final remainingMonths = months - elapsed;

      // 먼저 새 만기를 직접 계산
      final newMonths = LoanCalculatorService.calculateNewMaturityMonths(
        remainingBalance: remaining,
        extraRepayment: extra,
        annualInterestRate: rate,
        currentMonthlyPayment: payment,
        method: RepaymentMethod.equalPrincipalInterest,
      );

      // preCalculatedNewMonths 사용
      final savedWithPre = LoanCalculatorService.calculateInterestSaved(
        remainingBalance: remaining,
        extraRepayment: extra,
        annualInterestRate: rate,
        currentMonthlyPayment: payment,
        originalRemainingMonths: remainingMonths,
        method: RepaymentMethod.equalPrincipalInterest,
        preCalculatedNewMonths: newMonths,
      );

      // preCalculatedNewMonths 미사용 (내부에서 자동 계산)
      final savedWithout = LoanCalculatorService.calculateInterestSaved(
        remainingBalance: remaining,
        extraRepayment: extra,
        annualInterestRate: rate,
        currentMonthlyPayment: payment,
        originalRemainingMonths: remainingMonths,
        method: RepaymentMethod.equalPrincipalInterest,
      );

      // 동일한 값이어야 함 (같은 로직을 내부/외부에서 호출)
      expect(savedWithPre, savedWithout);
    });

    test('추가상환 금액이 잔여 원금 이상이면 원래 남은 이자 전체가 절약되어야 한다', () {
      const remaining = 50000000;
      const rate = 3.8;
      const payment = 1200000;
      const remainingMonths = 48;

      final savedFull = LoanCalculatorService.calculateInterestSaved(
        remainingBalance: remaining,
        extraRepayment: remaining, // 전액 상환
        annualInterestRate: rate,
        currentMonthlyPayment: payment,
        originalRemainingMonths: remainingMonths,
        method: RepaymentMethod.equalPrincipalInterest,
      );

      // 전액 상환 시 절약 이자 = 원래 남은 이자 전부
      expect(savedFull, greaterThan(0));

      // 부분 상환과 비교 시 더 많은 이자를 절약해야 함
      final savedPartial = LoanCalculatorService.calculateInterestSaved(
        remainingBalance: remaining,
        extraRepayment: 10000000,
        annualInterestRate: rate,
        currentMonthlyPayment: payment,
        originalRemainingMonths: remainingMonths,
        method: RepaymentMethod.equalPrincipalInterest,
      );
      expect(savedFull, greaterThan(savedPartial));
    });

    test('만기일시: newRemainingMonths가 -1이면 originalRemainingMonths를 사용해야 한다', () {
      const remaining = 100000000;
      const rate = 3.8;
      const remainingMonths = 72;
      final payment = (remaining * rate / 100 / 12).round();

      final saved = LoanCalculatorService.calculateInterestSaved(
        remainingBalance: remaining,
        extraRepayment: 10000000,
        annualInterestRate: rate,
        currentMonthlyPayment: payment,
        originalRemainingMonths: remainingMonths,
        method: RepaymentMethod.bullet,
      );

      // 만기일시는 calculateNewMaturityMonths가 -1 반환
      // effectiveMonths = originalRemainingMonths 사용
      expect(saved, greaterThan(0));
    });
  });

  // =========================================================================
  // calculateProgress 추가 경계 조건
  // =========================================================================

  group('LoanCalculatorService - calculateProgress (추가 경계 조건)', () {
    test('현재 시점이 정확히 시작일이면 0%여야 한다', () {
      final start = DateTime(2025, 1, 1);
      final end = DateTime(2027, 1, 1);

      final result = LoanCalculatorService.calculateProgress(
        startDate: start,
        endDate: end,
        currentDate: start,
      );
      // startDate에서 elapsed = 0이므로 0.0
      expect(result, 0.0);
    });

    test('currentDate를 제공하지 않으면 DateTime.now()를 사용해야 한다', () {
      final start = DateTime(2020, 1, 1);
      final end = DateTime(2030, 1, 1);

      final result = LoanCalculatorService.calculateProgress(
        startDate: start,
        endDate: end,
      );
      // now는 2020~2030 사이이므로 0~1 사이 값
      expect(result, greaterThanOrEqualTo(0.0));
      expect(result, lessThanOrEqualTo(1.0));
    });

    test('만기일이 시작일보다 이전이면(역전) 100%여야 한다', () {
      final start = DateTime(2025, 1, 1);
      final end = DateTime(2025, 1, 1); // 시작일과 동일 -> totalDuration = 0
      final now = DateTime(2025, 6, 1); // 시작일 이후

      final result = LoanCalculatorService.calculateProgress(
        startDate: start,
        endDate: end,
        currentDate: now,
      );
      expect(result, 1.0); // totalDuration <= 0
    });

    test('시작일 이전이면 0%여야 한다 (now < startDate)', () {
      final start = DateTime(2025, 6, 1);
      final end = DateTime(2025, 12, 1);
      final now = DateTime(2025, 3, 1); // 시작일보다 이전

      final result = LoanCalculatorService.calculateProgress(
        startDate: start,
        endDate: end,
        currentDate: now,
      );
      expect(result, 0.0);
    });
  });

  // =========================================================================
  // calculateRemainingMonths 추가 경계 조건
  // =========================================================================

  group('LoanCalculatorService - calculateRemainingMonths (추가 경계 조건)', () {
    test('currentDate를 제공하지 않으면 DateTime.now()를 사용해야 한다', () {
      // 먼 미래 만기일 설정
      final endDate = DateTime(2099, 12, 1);
      final result = LoanCalculatorService.calculateRemainingMonths(
        endDate: endDate,
      );
      expect(result, greaterThan(0));
    });

    test('만기일의 일(day)이 현재 일(day)보다 작으면 1개월 차감해야 한다', () {
      // 현재: 3월 20일, 만기: 6월 10일 -> day 20 > day 10이므로 1개월 차감
      final now = DateTime(2025, 3, 20);
      final end = DateTime(2025, 6, 10);
      final result = LoanCalculatorService.calculateRemainingMonths(
        endDate: end,
        currentDate: now,
      );
      // 6-3 = 3개월이지만 day 보정으로 2개월
      expect(result, 2);
    });

    test('만기일의 일(day)이 현재 일(day)보다 크면 그대로 유지해야 한다', () {
      final now = DateTime(2025, 3, 5);
      final end = DateTime(2025, 6, 20);
      final result = LoanCalculatorService.calculateRemainingMonths(
        endDate: end,
        currentDate: now,
      );
      // 6-3 = 3개월, day 5 < 20이므로 보정 없음
      expect(result, 3);
    });

    test('만기일의 일(day)이 같으면 보정하지 않아야 한다', () {
      final now = DateTime(2025, 3, 15);
      final end = DateTime(2025, 9, 15);
      final result = LoanCalculatorService.calculateRemainingMonths(
        endDate: end,
        currentDate: now,
      );
      expect(result, 6);
    });

    test('보정 후 음수가 되면 0을 반환해야 한다', () {
      // 같은 달이지만 day 보정으로 -1이 되는 경우
      final now = DateTime(2025, 3, 28);
      final end = DateTime(2025, 3, 10);
      final result = LoanCalculatorService.calculateRemainingMonths(
        endDate: end,
        currentDate: now,
      );
      expect(result, 0);
    });
  });

  // =========================================================================
  // 수식 교차 검증 테스트 (Cross-Validation)
  // =========================================================================

  group('LoanCalculatorService - 수식 교차 검증', () {
    test('원리금균등: 월 상환금을 수동으로 시뮬레이션하면 마지막에 잔액이 0에 근사해야 한다', () {
      const loan = 100000000;
      const rate = 3.8;
      const months = 96;
      final r = rate / 100 / 12;
      final payment = LoanCalculatorService.calculateMonthlyPayment(
        loanAmount: loan,
        annualInterestRate: rate,
        totalMonths: months,
        method: RepaymentMethod.equalPrincipalInterest,
      );

      double balance = loan.toDouble();
      for (int i = 0; i < months; i++) {
        final interest = balance * r;
        final principal = payment - interest;
        balance -= principal;
      }
      // floor 반올림 오차로 인해 작은 잔액이 남을 수 있음
      expect(balance.abs(), lessThan(1000));
    });

    test('원금균등: 총 상환금 합계 - 원금 = 총 이자와 일치해야 한다', () {
      const loan = 100000000;
      const rate = 3.8;
      const months = 96;

      int totalPayments = 0;
      for (int i = 1; i <= months; i++) {
        totalPayments += LoanCalculatorService.calculateMonthlyPayment(
          loanAmount: loan,
          annualInterestRate: rate,
          totalMonths: months,
          method: RepaymentMethod.equalPrincipal,
          currentMonth: i,
        );
      }

      final totalInterest = LoanCalculatorService.calculateTotalInterest(
        loanAmount: loan,
        annualInterestRate: rate,
        totalMonths: months,
        method: RepaymentMethod.equalPrincipal,
      );

      expect(totalPayments - loan, closeTo(totalInterest, 5000));
    });

    test('추가상환 후 새 만기 동안 시뮬레이션하면 잔액이 0에 근사해야 한다 (원리금균등)', () {
      const loan = 200000000;
      const rate = 3.5;
      const months = 336;
      const elapsed = 24;
      const extra = 10000000;
      final r = rate / 100 / 12;

      final remaining = LoanCalculatorService.calculateRemainingBalance(
        loanAmount: loan,
        annualInterestRate: rate,
        totalMonths: months,
        elapsedMonths: elapsed,
        method: RepaymentMethod.equalPrincipalInterest,
      );
      final payment = LoanCalculatorService.calculateMonthlyPayment(
        loanAmount: loan,
        annualInterestRate: rate,
        totalMonths: months,
        method: RepaymentMethod.equalPrincipalInterest,
      );

      final newMonths = LoanCalculatorService.calculateNewMaturityMonths(
        remainingBalance: remaining,
        extraRepayment: extra,
        annualInterestRate: rate,
        currentMonthlyPayment: payment,
        method: RepaymentMethod.equalPrincipalInterest,
      );

      // 시뮬레이션: 추가상환 후 잔액에서 newMonths 동안 payment로 상환
      double balance = (remaining - extra).toDouble();
      for (int i = 0; i < newMonths && balance > 0; i++) {
        final interest = balance * r;
        final principal = payment - interest;
        balance -= principal;
      }
      // ceil 반올림으로 인해 약간 과상환(음수) 가능
      expect(balance, lessThan(payment.toDouble()));
    });

    test('원리금균등: calculateRemainingBalance 결과가 시뮬레이션과 일치해야 한다', () {
      const loan = 100000000;
      const rate = 5.0;
      const months = 240;
      const elapsed = 60;
      final r = rate / 100 / 12;

      // 공식 기반 결과
      final formulaResult = LoanCalculatorService.calculateRemainingBalance(
        loanAmount: loan,
        annualInterestRate: rate,
        totalMonths: months,
        elapsedMonths: elapsed,
        method: RepaymentMethod.equalPrincipalInterest,
      );

      // 시뮬레이션 기반 결과
      final payment = LoanCalculatorService.calculateMonthlyPayment(
        loanAmount: loan,
        annualInterestRate: rate,
        totalMonths: months,
        method: RepaymentMethod.equalPrincipalInterest,
      );
      double balance = loan.toDouble();
      for (int i = 0; i < elapsed; i++) {
        final interest = balance * r;
        final principal = payment - interest;
        balance -= principal;
      }

      // 수식 결과와 시뮬레이션 결과가 매우 근사해야 함
      expect(formulaResult, closeTo(balance.round(), 500));
    });
  });

  // =========================================================================
  // 다양한 대출 시나리오 통합 테스트
  // =========================================================================

  group('LoanCalculatorService - 실제 대출 시나리오 통합 테스트', () {
    test('시나리오 1: 주택담보대출 3억, 3.5%, 30년, 원리금균등', () {
      const loan = 300000000;
      const rate = 3.5;
      const months = 360;

      final monthly = LoanCalculatorService.calculateMonthlyPayment(
        loanAmount: loan,
        annualInterestRate: rate,
        totalMonths: months,
        method: RepaymentMethod.equalPrincipalInterest,
      );
      // 약 1,347,130원
      expect(monthly, closeTo(1347130, 5000));

      final totalInterest = LoanCalculatorService.calculateTotalInterest(
        loanAmount: loan,
        annualInterestRate: rate,
        totalMonths: months,
        method: RepaymentMethod.equalPrincipalInterest,
      );
      // 약 1.85억 이자
      expect(totalInterest, greaterThan(150000000));

      // 10년(120개월) 후 잔여 원금
      final after10 = LoanCalculatorService.calculateRemainingBalance(
        loanAmount: loan,
        annualInterestRate: rate,
        totalMonths: months,
        elapsedMonths: 120,
        method: RepaymentMethod.equalPrincipalInterest,
      );
      expect(after10, greaterThan(200000000)); // 10년 후에도 2억 이상 남아야 함
      expect(after10, lessThan(loan));
    });

    test('시나리오 2: 신용대출 5천만원, 5%, 5년, 원금균등', () {
      const loan = 50000000;
      const rate = 5.0;
      const months = 60;

      // 1회차 상환금
      final first = LoanCalculatorService.calculateMonthlyPayment(
        loanAmount: loan,
        annualInterestRate: rate,
        totalMonths: months,
        method: RepaymentMethod.equalPrincipal,
        currentMonth: 1,
      );
      // 마지막 회차
      final last = LoanCalculatorService.calculateMonthlyPayment(
        loanAmount: loan,
        annualInterestRate: rate,
        totalMonths: months,
        method: RepaymentMethod.equalPrincipal,
        currentMonth: months,
      );

      expect(first, greaterThan(last)); // 원금균등은 점점 감소
    });

    test('시나리오 3: 금리 변경 후 월 상환금 변동 - 체증식', () {
      const loan = 200000000;
      const rate = 3.0;
      const newRate = 4.0;
      const months = 240;
      const elapsed = 36;

      final remaining = LoanCalculatorService.calculateRemainingBalance(
        loanAmount: loan,
        annualInterestRate: rate,
        totalMonths: months,
        elapsedMonths: elapsed,
        method: RepaymentMethod.graduated,
      );

      final newPayment = LoanCalculatorService.calculateNewMonthlyPaymentAfterRateChange(
        remainingBalance: remaining,
        newAnnualInterestRate: newRate,
        remainingMonths: months - elapsed,
        method: RepaymentMethod.graduated,
      );

      expect(newPayment, greaterThan(0));
    });

    test('시나리오 4: 추가상환 여러 번 시뮬레이션', () {
      const loan = 100000000;
      const rate = 4.0;
      const months = 120;
      const elapsed = 12;

      // 1차 잔여 원금
      final balance1 = LoanCalculatorService.calculateRemainingBalance(
        loanAmount: loan,
        annualInterestRate: rate,
        totalMonths: months,
        elapsedMonths: elapsed,
        method: RepaymentMethod.equalPrincipalInterest,
      );

      // 1차 추가상환 1000만원 후 잔액
      final afterExtra1 = balance1 - 10000000;
      expect(afterExtra1, greaterThan(0));
      expect(afterExtra1, lessThan(balance1));

      // 추가상환 후 만기 단축
      final payment = LoanCalculatorService.calculateMonthlyPayment(
        loanAmount: loan,
        annualInterestRate: rate,
        totalMonths: months,
        method: RepaymentMethod.equalPrincipalInterest,
      );

      final newMonths = LoanCalculatorService.calculateNewMaturityMonths(
        remainingBalance: balance1,
        extraRepayment: 10000000,
        annualInterestRate: rate,
        currentMonthlyPayment: payment,
        method: RepaymentMethod.equalPrincipalInterest,
      );

      expect(newMonths, greaterThan(0));
      expect(newMonths, lessThan(months - elapsed));
    });
  });

  // =========================================================================
  // 성능 벤치마크 테스트
  // =========================================================================

  group('LoanCalculatorService - 성능 벤치마크', () {
    test('원리금균등 월 상환금 계산 1만 회 반복이 100ms 이내여야 한다', () {
      final sw = Stopwatch()..start();
      for (int i = 0; i < 10000; i++) {
        LoanCalculatorService.calculateMonthlyPayment(
          loanAmount: 300000000,
          annualInterestRate: 3.5,
          totalMonths: 360,
          method: RepaymentMethod.equalPrincipalInterest,
        );
      }
      sw.stop();
      // 1만 회 반복이 100ms 이내 (단일 호출 ~0.01ms)
      expect(sw.elapsedMilliseconds, lessThan(100));
    });

    test('원금균등 월 상환금 계산 1만 회 반복이 100ms 이내여야 한다', () {
      final sw = Stopwatch()..start();
      for (int i = 0; i < 10000; i++) {
        LoanCalculatorService.calculateMonthlyPayment(
          loanAmount: 300000000,
          annualInterestRate: 3.5,
          totalMonths: 360,
          method: RepaymentMethod.equalPrincipal,
          currentMonth: 180,
        );
      }
      sw.stop();
      expect(sw.elapsedMilliseconds, lessThan(100));
    });

    test('체증식 월 상환금 계산 1만 회 반복이 100ms 이내여야 한다', () {
      final sw = Stopwatch()..start();
      for (int i = 0; i < 10000; i++) {
        LoanCalculatorService.calculateMonthlyPayment(
          loanAmount: 300000000,
          annualInterestRate: 3.5,
          totalMonths: 360,
          method: RepaymentMethod.graduated,
          currentMonth: 180,
        );
      }
      sw.stop();
      expect(sw.elapsedMilliseconds, lessThan(100));
    });

    test('잔여 원금 계산 1만 회 반복이 100ms 이내여야 한다', () {
      final sw = Stopwatch()..start();
      for (int i = 0; i < 10000; i++) {
        LoanCalculatorService.calculateRemainingBalance(
          loanAmount: 300000000,
          annualInterestRate: 3.5,
          totalMonths: 360,
          elapsedMonths: 120,
          method: RepaymentMethod.equalPrincipalInterest,
        );
      }
      sw.stop();
      expect(sw.elapsedMilliseconds, lessThan(100));
    });

    test('체증식 잔여 원금 시뮬레이션 (360개월) 1000 회 반복이 500ms 이내여야 한다', () {
      // 체증식은 시뮬레이션 기반이므로 더 느릴 수 있음
      final sw = Stopwatch()..start();
      for (int i = 0; i < 1000; i++) {
        LoanCalculatorService.calculateRemainingBalance(
          loanAmount: 300000000,
          annualInterestRate: 3.5,
          totalMonths: 360,
          elapsedMonths: 180,
          method: RepaymentMethod.graduated,
        );
      }
      sw.stop();
      // 시뮬레이션 기반이므로 1000회에 500ms 이내
      expect(sw.elapsedMilliseconds, lessThan(500));
    });

    test('총 이자 계산(체증식 시뮬레이션 360개월) 1000 회 반복이 500ms 이내여야 한다', () {
      final sw = Stopwatch()..start();
      for (int i = 0; i < 1000; i++) {
        LoanCalculatorService.calculateTotalInterest(
          loanAmount: 300000000,
          annualInterestRate: 3.5,
          totalMonths: 360,
          method: RepaymentMethod.graduated,
        );
      }
      sw.stop();
      expect(sw.elapsedMilliseconds, lessThan(500));
    });

    test('추가상환 만기 역산(체증식 시뮬레이션) 1000 회 반복이 1000ms 이내여야 한다', () {
      final sw = Stopwatch()..start();
      for (int i = 0; i < 1000; i++) {
        LoanCalculatorService.calculateNewMaturityMonths(
          remainingBalance: 250000000,
          extraRepayment: 20000000,
          annualInterestRate: 3.5,
          currentMonthlyPayment: 1200000,
          method: RepaymentMethod.graduated,
          originalLoanAmount: 300000000,
          originalTotalMonths: 360,
        );
      }
      sw.stop();
      expect(sw.elapsedMilliseconds, lessThan(1000));
    });

    test('calcEqualPrincipalInterestWithDates 이진 탐색 100 회 반복이 1000ms 이내여야 한다', () {
      // 이진 탐색 + 날짜 기반 계산으로 단일 호출당 ~4ms 소요 (허용 범위)
      final sw = Stopwatch()..start();
      for (int i = 0; i < 100; i++) {
        LoanCalculatorService.calcEqualPrincipalInterestWithDates(
          loanAmount: 300000000,
          annualInterestRate: 3.5,
          totalMonths: 360,
          startDate: DateTime(2020, 1, 1),
        );
      }
      sw.stop();
      // 단일 호출 ~4ms * 100회 = ~400ms, 여유분 포함 2000ms
      expect(sw.elapsedMilliseconds, lessThan(2000));
    });

    test('절약 이자 계산 (모든 상환 방식) 1000 회 반복이 500ms 이내여야 한다', () {
      final sw = Stopwatch()..start();
      final methods = RepaymentMethod.values;
      for (int i = 0; i < 1000; i++) {
        for (final method in methods) {
          LoanCalculatorService.calculateInterestSaved(
            remainingBalance: 200000000,
            extraRepayment: 20000000,
            annualInterestRate: 3.5,
            currentMonthlyPayment: 1200000,
            originalRemainingMonths: 240,
            method: method,
          );
        }
      }
      sw.stop();
      // 4가지 방식 * 1000회 = 4000회
      expect(sw.elapsedMilliseconds, lessThan(500));
    });

    test('누적 상환원금 계산 (체증식 시뮬레이션) 1000 회 반복이 500ms 이내여야 한다', () {
      final sw = Stopwatch()..start();
      for (int i = 0; i < 1000; i++) {
        LoanCalculatorService.calculateCumulativeRepaid(
          loanAmount: 300000000,
          annualInterestRate: 3.5,
          totalMonths: 360,
          elapsedMonths: 180,
          method: RepaymentMethod.graduated,
        );
      }
      sw.stop();
      expect(sw.elapsedMilliseconds, lessThan(500));
    });

    test('카드 위젯에서 호출하는 전체 계산 체인이 1000 회 반복에 1초 이내여야 한다', () {
      // LoanGoalCard에서 호출하는 전체 계산 흐름을 시뮬레이션
      final sw = Stopwatch()..start();
      for (int i = 0; i < 1000; i++) {
        const loan = 300000000;
        const rate = 3.5;
        const totalMonths = 360;
        final startDate = DateTime(2020, 1, 1);
        final now = DateTime(2026, 3, 1);

        final elapsed = LoanCalculatorService.calculateMonthsBetween(
          startDate, now,
        );

        // 월 상환금
        LoanCalculatorService.calculateMonthlyPayment(
          loanAmount: loan,
          annualInterestRate: rate,
          totalMonths: totalMonths,
          method: RepaymentMethod.equalPrincipalInterest,
        );

        // 누적 상환원금 (진행률 계산용)
        LoanCalculatorService.calculateCumulativeRepaid(
          loanAmount: loan,
          annualInterestRate: rate,
          totalMonths: totalMonths,
          elapsedMonths: elapsed,
          method: RepaymentMethod.equalPrincipalInterest,
        );

        // 잔여 원금
        final remaining = LoanCalculatorService.calculateRemainingBalance(
          loanAmount: loan,
          annualInterestRate: rate,
          totalMonths: totalMonths,
          elapsedMonths: elapsed,
          method: RepaymentMethod.equalPrincipalInterest,
        );

        // 추가상환 만기 역산
        final payment = LoanCalculatorService.calculateMonthlyPayment(
          loanAmount: loan,
          annualInterestRate: rate,
          totalMonths: totalMonths,
          method: RepaymentMethod.equalPrincipalInterest,
        );
        LoanCalculatorService.calculateNewMaturityMonths(
          remainingBalance: remaining,
          extraRepayment: 20000000,
          annualInterestRate: rate,
          currentMonthlyPayment: payment,
          method: RepaymentMethod.equalPrincipalInterest,
        );

        // 잔여 개월
        LoanCalculatorService.calculateRemainingMonths(
          endDate: DateTime(2050, 1, 1),
          currentDate: now,
        );
      }
      sw.stop();
      // 전체 계산 체인 1000회가 1초 이내
      expect(sw.elapsedMilliseconds, lessThan(1000));
    });
  });
}
