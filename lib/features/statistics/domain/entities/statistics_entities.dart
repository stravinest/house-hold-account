// 지출 유형 필터 (전체/고정비/변동비)
enum ExpenseTypeFilter { all, fixed, variable }

// 추이 기간 타입
enum TrendPeriod { monthly, yearly }

// 월 비교 데이터
class MonthComparisonData {
  final int currentTotal;
  final int previousTotal;
  final int difference;
  final double percentageChange;

  const MonthComparisonData({
    required this.currentTotal,
    required this.previousTotal,
    required this.difference,
    required this.percentageChange,
  });

  bool get isIncrease => difference > 0;
  bool get isDecrease => difference < 0;
  bool get isUnchanged => difference == 0;

  factory MonthComparisonData.empty() {
    return const MonthComparisonData(
      currentTotal: 0,
      previousTotal: 0,
      difference: 0,
      percentageChange: 0,
    );
  }
}

// 연별 통계
class YearlyStatistics {
  final int year;
  final int income;
  final int expense;
  final int saving;

  const YearlyStatistics({
    required this.year,
    required this.income,
    required this.expense,
    required this.saving,
  });

  int get balance => income - expense;
  String get yearLabel => '$year년';
}

// 결제수단별 통계
class PaymentMethodStatistics {
  final String paymentMethodId;
  final String paymentMethodName;
  final String paymentMethodIcon;
  final String paymentMethodColor;
  final bool canAutoSave;
  final int amount;
  final double percentage;

  const PaymentMethodStatistics({
    required this.paymentMethodId,
    required this.paymentMethodName,
    required this.paymentMethodIcon,
    required this.paymentMethodColor,
    this.canAutoSave = false,
    required this.amount,
    required this.percentage,
  });

  PaymentMethodStatistics copyWith({
    String? paymentMethodId,
    String? paymentMethodName,
    String? paymentMethodIcon,
    String? paymentMethodColor,
    bool? canAutoSave,
    int? amount,
    double? percentage,
  }) {
    return PaymentMethodStatistics(
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      paymentMethodName: paymentMethodName ?? this.paymentMethodName,
      paymentMethodIcon: paymentMethodIcon ?? this.paymentMethodIcon,
      paymentMethodColor: paymentMethodColor ?? this.paymentMethodColor,
      canAutoSave: canAutoSave ?? this.canAutoSave,
      amount: amount ?? this.amount,
      percentage: percentage ?? this.percentage,
    );
  }
}

// 월별 추이 통계 (평균 포함)
class TrendStatisticsData {
  final List<dynamic> data; // MonthlyStatistics 또는 YearlyStatistics
  final int averageIncome;
  final int averageExpense;
  final int averageAsset;

  const TrendStatisticsData({
    required this.data,
    required this.averageIncome,
    required this.averageExpense,
    required this.averageAsset,
  });

  int getAverageByType(String type) {
    switch (type) {
      case 'income':
        return averageIncome;
      case 'asset':
        return averageAsset;
      default:
        return averageExpense;
    }
  }
}
