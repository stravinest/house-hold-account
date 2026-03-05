import 'dart:math';

import '../../domain/entities/asset_goal.dart';

class LoanCalculatorService {
  // 상수
  static const int _maxSimulationMonths = 1200; // 시뮬레이션 최대 개월 수 (100년)
  static const double _rateChangeThreshold = 0.001; // 이율 변경 감지 임계값

  // 두 날짜 간 개월 수 계산 유틸리티
  static int calculateMonthsBetween(DateTime start, DateTime end) {
    return (end.year - start.year) * 12 + (end.month - start.month);
  }

  // 이율 변경 여부 판단
  static bool isRateChanged(double? oldRate, double? newRate) {
    if (oldRate == null || newRate == null) return false;
    return (oldRate - newRate).abs() > _rateChangeThreshold;
  }

  // 월 상환금 계산
  // currentMonth: 원금균등/체증식에서 몇 회차인지 (기본값 1)
  static int calculateMonthlyPayment({
    required int loanAmount,
    required double annualInterestRate,
    required int totalMonths,
    required RepaymentMethod method,
    int currentMonth = 1,
  }) {
    if (loanAmount == 0) return 0;

    switch (method) {
      case RepaymentMethod.equalPrincipalInterest:
        return _calcEqualPrincipalInterest(
          loanAmount,
          annualInterestRate,
          totalMonths,
        );
      case RepaymentMethod.equalPrincipal:
        return _calcEqualPrincipal(
          loanAmount,
          annualInterestRate,
          totalMonths,
          currentMonth,
        );
      case RepaymentMethod.bullet:
        return _calcBullet(loanAmount, annualInterestRate);
      case RepaymentMethod.graduated:
        return _calcGraduated(
          loanAmount,
          annualInterestRate,
          totalMonths,
          currentMonth,
        );
    }
  }

  // 원리금균등상환 (일할계산 actual/365 방식)
  // startDate가 제공되면 실제 일수 기반으로 계산 (은행 방식)
  // startDate가 없으면 기존 수학 공식 사용
  static int calcEqualPrincipalInterestWithDates({
    required int loanAmount,
    required double annualInterestRate,
    required int totalMonths,
    required DateTime startDate,
  }) {
    if (annualInterestRate == 0) {
      return (loanAmount / totalMonths).floor();
    }

    // 이진 탐색으로 월 상환금 결정
    // 상한: 기존 공식 결과의 1.1배, 하한: 원금/개월수
    final r = annualInterestRate / 100 / 12;
    final base = 1 + r;
    final compounded = powN(base, totalMonths);
    final approx = loanAmount * r * compounded / (compounded - 1);

    int lo = (loanAmount / totalMonths).floor();
    int hi = (approx * 1.1).ceil();

    // 특정 월 상환금으로 상환 시뮬레이션 후 잔액 반환
    double simulate(int monthlyPayment) {
      double remaining = loanAmount.toDouble();
      final dailyRate = annualInterestRate / 100 / 365;
      DateTime current = startDate;

      for (int i = 0; i < totalMonths; i++) {
        final nextMonth = DateTime(
          current.year + (current.month == 12 ? 1 : 0),
          current.month == 12 ? 1 : current.month + 1,
          current.day,
        );
        // 실제 일수 계산
        final days = nextMonth.difference(current).inDays;
        final interest = (remaining * dailyRate * days).floorToDouble();
        final principal = monthlyPayment - interest;
        remaining -= principal;
        current = nextMonth;
      }
      return remaining;
    }

    // 이진 탐색: 잔액이 0에 가장 가까운 월 상환금 찾기
    while (lo < hi) {
      final mid = (lo + hi) ~/ 2;
      final remain = simulate(mid);
      if (remain > 0) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }

    return lo;
  }

  // 원리금균등상환: M = P * r * (1+r)^n / ((1+r)^n - 1)
  static int _calcEqualPrincipalInterest(
    int loanAmount,
    double annualInterestRate,
    int totalMonths,
  ) {
    if (annualInterestRate == 0) {
      return (loanAmount / totalMonths).floor();
    }
    final r = annualInterestRate / 100 / 12;
    final base = 1 + r;
    final compounded = powN(base, totalMonths);
    final monthly = loanAmount * r * compounded / (compounded - 1);
    return monthly.floor();
  }

  // 원금균등상환: k회차 상환금 = 월 원금 + (잔액 * 월 이자율)
  static int _calcEqualPrincipal(
    int loanAmount,
    double annualInterestRate,
    int totalMonths,
    int currentMonth,
  ) {
    final monthlyPrincipal = loanAmount / totalMonths;
    final remainingPrincipal =
        loanAmount - monthlyPrincipal * (currentMonth - 1);
    final r = annualInterestRate / 100 / 12;
    final interest = remainingPrincipal * r;
    return (monthlyPrincipal + interest).round();
  }

  // 만기일시상환: 월 이자만 납부
  static int _calcBullet(int loanAmount, double annualInterestRate) {
    final r = annualInterestRate / 100 / 12;
    return (loanAmount * r).round();
  }

  // 체증식상환: 초기 상환금 = 원리금균등의 70%, 매년 증가
  static int _calcGraduated(
    int loanAmount,
    double annualInterestRate,
    int totalMonths,
    int currentMonth,
  ) {
    final basePayment = _calcEqualPrincipalInterest(
      loanAmount,
      annualInterestRate,
      totalMonths,
    );
    // 초기 상환금은 원리금균등의 70%에서 시작
    final initialPayment = basePayment * 0.7;
    // 연 단위로 증가율 적용 (총합이 P + 총이자에 근사하도록)
    // 근사: 매년 약 7% 증가 적용
    const yearlyIncreaseRate = 1.07;
    final year = ((currentMonth - 1) ~/ 12);
    final payment = initialPayment * pow(yearlyIncreaseRate, year.toDouble());
    return payment.round();
  }

  // 총 이자 계산
  static int calculateTotalInterest({
    required int loanAmount,
    required double annualInterestRate,
    required int totalMonths,
    required RepaymentMethod method,
  }) {
    switch (method) {
      case RepaymentMethod.equalPrincipalInterest:
        final monthly = _calcEqualPrincipalInterest(
          loanAmount,
          annualInterestRate,
          totalMonths,
        );
        return monthly * totalMonths - loanAmount;
      case RepaymentMethod.equalPrincipal:
        // 총 이자 = 합산(k회차 이자) = P * r * (n+1) / 2
        final r = annualInterestRate / 100 / 12;
        return (loanAmount * r * (totalMonths + 1) / 2).round();
      case RepaymentMethod.bullet:
        final monthly = _calcBullet(loanAmount, annualInterestRate);
        return monthly * totalMonths;
      case RepaymentMethod.graduated:
        int total = 0;
        for (int i = 1; i <= totalMonths; i++) {
          total += _calcGraduated(
            loanAmount,
            annualInterestRate,
            totalMonths,
            i,
          );
        }
        return total - loanAmount;
    }
  }

  // 시작일부터 현재까지 누적 상환 원금 계산
  static int calculateCumulativeRepaid({
    required int loanAmount,
    required double annualInterestRate,
    required int totalMonths,
    required int elapsedMonths,
    required RepaymentMethod method,
  }) {
    if (loanAmount <= 0 || totalMonths <= 0 || elapsedMonths <= 0) return 0;
    final months = elapsedMonths.clamp(0, totalMonths);

    switch (method) {
      case RepaymentMethod.equalPrincipalInterest:
        if (annualInterestRate == 0) {
          return ((loanAmount / totalMonths) * months).round();
        }
        final r = annualInterestRate / 100 / 12;
        final compounded = powN(1 + r, totalMonths);
        // k개월 후 잔액 = P * [(1+r)^n - (1+r)^k] / [(1+r)^n - 1]
        final compoundedK = powN(1 + r, months);
        final remaining =
            loanAmount * (compounded - compoundedK) / (compounded - 1);
        return (loanAmount - remaining).round();

      case RepaymentMethod.equalPrincipal:
        // 매월 원금 = P / n, k개월 누적 = (P / n) * k
        return ((loanAmount / totalMonths) * months).round();

      case RepaymentMethod.bullet:
        // 만기일시상환: 만기 전까지 원금 상환 없음
        if (months >= totalMonths) return loanAmount;
        return 0;

      case RepaymentMethod.graduated:
        // 체증식: 각 월 상환금에서 이자를 빼고 원금 부분 합산
        final r = annualInterestRate / 100 / 12;
        double remainingPrincipal = loanAmount.toDouble();
        double totalRepaid = 0;
        for (int i = 1; i <= months; i++) {
          final payment = _calcGraduated(
            loanAmount,
            annualInterestRate,
            totalMonths,
            i,
          );
          final interest = remainingPrincipal * r;
          final principal = payment - interest;
          totalRepaid += principal > 0 ? principal : 0;
          remainingPrincipal -= principal > 0 ? principal : 0;
          if (remainingPrincipal < 0) remainingPrincipal = 0;
        }
        return totalRepaid.round();
    }
  }

  // 대출 진행률 계산 (0.0 ~ 1.0)
  static double calculateProgress({
    required DateTime startDate,
    required DateTime endDate,
    DateTime? currentDate,
  }) {
    final now = currentDate ?? DateTime.now();
    if (!now.isAfter(startDate) && now != startDate) {
      if (now.isBefore(startDate)) return 0.0;
    }
    final totalDuration = endDate.difference(startDate).inMilliseconds;
    if (totalDuration <= 0) return 1.0;
    final elapsed = now.difference(startDate).inMilliseconds;
    if (elapsed <= 0) return 0.0;
    return (elapsed / totalDuration).clamp(0.0, 1.0);
  }

  // 남은 개월 수 계산 (0 이상)
  static int calculateRemainingMonths({
    required DateTime endDate,
    DateTime? currentDate,
  }) {
    final now = currentDate ?? DateTime.now();
    if (!endDate.isAfter(now)) return 0;
    final years = endDate.year - now.year;
    final months = endDate.month - now.month;
    int totalMonths = years * 12 + months;
    // 일 단위 보정: 같은 날짜이거나 만기일의 일이 더 크면 온전한 개월로 카운트
    // 현재 날짜의 일이 만기일의 일보다 크면 아직 한 달이 완성되지 않음
    if (now.day > endDate.day) {
      totalMonths -= 1;
    }
    return totalMonths < 0 ? 0 : totalMonths;
  }

  // 잔여 원금 계산
  // B = P * [(1+r)^N - (1+r)^k] / [(1+r)^N - 1] (원리금균등)
  // B = P - (P/N) * k (원금균등)
  // B = P (만기일시)
  // 체증식: 시뮬레이션으로 각 월 원금상환분 합산 후 차감
  static int calculateRemainingBalance({
    required int loanAmount,
    required double annualInterestRate,
    required int totalMonths,
    required int elapsedMonths,
    required RepaymentMethod method,
  }) {
    if (elapsedMonths <= 0) return loanAmount;
    if (elapsedMonths >= totalMonths) {
      if (method == RepaymentMethod.bullet) return loanAmount;
      return 0;
    }

    switch (method) {
      case RepaymentMethod.equalPrincipalInterest:
        if (annualInterestRate == 0) {
          return (loanAmount - (loanAmount / totalMonths) * elapsedMonths)
              .round();
        }
        final r = annualInterestRate / 100 / 12;
        final compoundedN = powN(1 + r, totalMonths);
        final compoundedK = powN(1 + r, elapsedMonths);
        final remaining =
            loanAmount * (compoundedN - compoundedK) / (compoundedN - 1);
        return remaining.round();

      case RepaymentMethod.equalPrincipal:
        final repaid = (loanAmount / totalMonths) * elapsedMonths;
        return (loanAmount - repaid).round();

      case RepaymentMethod.bullet:
        return loanAmount;

      case RepaymentMethod.graduated:
        final r = annualInterestRate / 100 / 12;
        double remainingPrincipal = loanAmount.toDouble();
        for (int i = 1; i <= elapsedMonths; i++) {
          final payment = _calcGraduated(
            loanAmount,
            annualInterestRate,
            totalMonths,
            i,
          );
          final interest = remainingPrincipal * r;
          final principal = payment - interest;
          remainingPrincipal -= principal > 0 ? principal : 0;
          if (remainingPrincipal < 0) remainingPrincipal = 0;
        }
        return remainingPrincipal.round();
    }
  }

  // 금리 변경 후 새 월상환금 계산
  // 잔여원금 기반으로 새 이율에 따른 월상환금 재계산
  static int calculateNewMonthlyPaymentAfterRateChange({
    required int remainingBalance,
    required double newAnnualInterestRate,
    required int remainingMonths,
    required RepaymentMethod method,
  }) {
    return calculateMonthlyPayment(
      loanAmount: remainingBalance,
      annualInterestRate: newAnnualInterestRate,
      totalMonths: remainingMonths,
      method: method,
    );
  }

  // 추가상환 시 새 만기 개월 수 계산
  // 원리금균등: n = -ln(1 - B_actual*r/M) / ln(1+r)
  // 원금균등: ceil(B_actual / 월원금)
  // 만기일시: -1 (만기 변동 없음)
  // 체증식: 시뮬레이션 역산 (originalLoanAmount 기반 스케줄 사용)
  // 계산 불가 시 -1 반환
  static int calculateNewMaturityMonths({
    required int remainingBalance,
    required int extraRepayment,
    required double annualInterestRate,
    required int currentMonthlyPayment,
    required RepaymentMethod method,
    int? originalLoanAmount,
    int? originalTotalMonths,
  }) {
    final actualBalance = remainingBalance - extraRepayment;
    if (actualBalance <= 0) return 0;

    switch (method) {
      case RepaymentMethod.equalPrincipalInterest:
        if (annualInterestRate == 0) {
          if (currentMonthlyPayment <= 0) return -1;
          return (actualBalance / currentMonthlyPayment).ceil();
        }
        final r = annualInterestRate / 100 / 12;
        final m = currentMonthlyPayment.toDouble();
        // M > B_actual * r 이어야 계산 가능
        if (m <= actualBalance * r) return -1;
        final n = -log(1 - actualBalance * r / m) / log(1 + r);
        return n.ceil();

      case RepaymentMethod.equalPrincipal:
        if (currentMonthlyPayment <= 0) return -1;
        // 원금균등에서 월 원금분 = 원래 잔여원금 기준 월 원금
        // 기존 월상환금에서 이자를 제외한 원금부분 추정
        final r = annualInterestRate / 100 / 12;
        final interest = remainingBalance * r;
        final monthlyPrincipal = currentMonthlyPayment - interest;
        if (monthlyPrincipal <= 0) return -1;
        return (actualBalance / monthlyPrincipal).ceil();

      case RepaymentMethod.bullet:
        return -1;

      case RepaymentMethod.graduated:
        // 시뮬레이션으로 역산 (원래 대출 조건 기반 스케줄 사용)
        final r = annualInterestRate / 100 / 12;
        double remaining = actualBalance.toDouble();
        final loanBase = originalLoanAmount ?? remainingBalance;
        final monthBase = originalTotalMonths ?? _maxSimulationMonths;
        double prevRemaining = remaining;
        int month = 0;
        while (remaining > 0 && month < _maxSimulationMonths) {
          month++;
          final payment = _calcGraduated(
            loanBase,
            annualInterestRate,
            monthBase,
            month,
          );
          final interestPart = remaining * r;
          final principal = payment - interestPart;
          remaining -= principal > 0 ? principal : 0;
          // 잔액이 증가하면 상환 불가 - 조기 탈출
          if (month > 1 && remaining >= prevRemaining) return -1;
          prevRemaining = remaining;
        }
        return month >= _maxSimulationMonths ? -1 : month;
    }
  }

  // 추가상환 시 절약되는 이자 계산
  // 원래 잔여이자 - 추가상환 후 잔여이자
  // preCalculatedNewMonths: 외부에서 이미 계산한 새 만기 개월 수 (중복 계산 방지)
  static int calculateInterestSaved({
    required int remainingBalance,
    required int extraRepayment,
    required double annualInterestRate,
    required int currentMonthlyPayment,
    required int originalRemainingMonths,
    required RepaymentMethod method,
    int? preCalculatedNewMonths,
  }) {
    if (extraRepayment <= 0 || annualInterestRate == 0) return 0;

    // 원래 잔여이자 계산 (시뮬레이션)
    final originalInterest = _simulateTotalInterest(
      remainingBalance,
      annualInterestRate,
      currentMonthlyPayment,
      originalRemainingMonths,
      method,
    );

    // 추가상환 후 잔여이자 계산
    final actualBalance = remainingBalance - extraRepayment;
    if (actualBalance <= 0) return originalInterest;

    final newRemainingMonths = preCalculatedNewMonths ?? calculateNewMaturityMonths(
      remainingBalance: remainingBalance,
      extraRepayment: extraRepayment,
      annualInterestRate: annualInterestRate,
      currentMonthlyPayment: currentMonthlyPayment,
      method: method,
    );

    final effectiveMonths = newRemainingMonths > 0
        ? newRemainingMonths
        : originalRemainingMonths;

    final newInterest = _simulateTotalInterest(
      actualBalance,
      annualInterestRate,
      currentMonthlyPayment,
      effectiveMonths,
      method,
    );

    final saved = originalInterest - newInterest;
    return saved > 0 ? saved : 0;
  }

  // 잔여이자 시뮬레이션 (내부 헬퍼)
  static int _simulateTotalInterest(
    int balance,
    double annualInterestRate,
    int monthlyPayment,
    int months,
    RepaymentMethod method,
  ) {
    final r = annualInterestRate / 100 / 12;
    double remaining = balance.toDouble();
    double totalInterest = 0;

    switch (method) {
      case RepaymentMethod.equalPrincipalInterest:
        for (int i = 0; i < months && remaining > 0; i++) {
          final interest = remaining * r;
          totalInterest += interest;
          final principal = monthlyPayment - interest;
          remaining -= principal;
          if (remaining < 0) remaining = 0;
        }
        return totalInterest.round();

      case RepaymentMethod.equalPrincipal:
        final monthlyPrincipal = balance / months;
        for (int i = 0; i < months && remaining > 0; i++) {
          final interest = remaining * r;
          totalInterest += interest;
          remaining -= monthlyPrincipal;
          if (remaining < 0) remaining = 0;
        }
        return totalInterest.round();

      case RepaymentMethod.bullet:
        // 매월 이자만 납부
        return (balance * r * months).round();

      case RepaymentMethod.graduated:
        for (int i = 1; i <= months && remaining > 0; i++) {
          final interest = remaining * r;
          totalInterest += interest;
          final payment = _calcGraduated(
            balance,
            annualInterestRate,
            months,
            i,
          );
          final principal = payment - interest;
          remaining -= principal > 0 ? principal : 0;
          if (remaining < 0) remaining = 0;
        }
        return totalInterest.round();
    }
  }

  // RepaymentMethod -> 문자열
  static String repaymentMethodToString(RepaymentMethod method) {
    return method.toJson();
  }

  // 문자열 -> RepaymentMethod
  static RepaymentMethod repaymentMethodFromString(String value) {
    return RepaymentMethodExtension.fromJson(value);
  }
}

// dart:math pow 래퍼 (double 반환)
double powN(double base, int exp) {
  return pow(base, exp).toDouble();
}
