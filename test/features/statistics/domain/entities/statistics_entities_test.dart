import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/statistics/domain/entities/statistics_entities.dart';

void main() {
  group('ExpenseTypeFilter enum', () {
    test('all, fixed, variable 세 가지 값이 모두 존재해야 한다', () {
      expect(ExpenseTypeFilter.values, contains(ExpenseTypeFilter.all));
      expect(ExpenseTypeFilter.values, contains(ExpenseTypeFilter.fixed));
      expect(ExpenseTypeFilter.values, contains(ExpenseTypeFilter.variable));
    });

    test('values 리스트의 길이가 3이어야 한다', () {
      expect(ExpenseTypeFilter.values.length, equals(3));
    });
  });

  group('TrendPeriod enum', () {
    test('monthly, yearly 두 가지 값이 모두 존재해야 한다', () {
      expect(TrendPeriod.values, contains(TrendPeriod.monthly));
      expect(TrendPeriod.values, contains(TrendPeriod.yearly));
    });
  });

  group('MonthComparisonData', () {
    test('생성자가 모든 필드를 올바르게 초기화해야 한다', () {
      const data = MonthComparisonData(
        currentTotal: 500000,
        previousTotal: 400000,
        difference: 100000,
        percentageChange: 25.0,
      );

      expect(data.currentTotal, equals(500000));
      expect(data.previousTotal, equals(400000));
      expect(data.difference, equals(100000));
      expect(data.percentageChange, equals(25.0));
    });

    test('isIncrease - 차이가 양수일 때 true를 반환해야 한다', () {
      const data = MonthComparisonData(
        currentTotal: 500000,
        previousTotal: 400000,
        difference: 100000,
        percentageChange: 25.0,
      );

      expect(data.isIncrease, isTrue);
      expect(data.isDecrease, isFalse);
      expect(data.isUnchanged, isFalse);
    });

    test('isDecrease - 차이가 음수일 때 true를 반환해야 한다', () {
      const data = MonthComparisonData(
        currentTotal: 300000,
        previousTotal: 400000,
        difference: -100000,
        percentageChange: -25.0,
      );

      expect(data.isDecrease, isTrue);
      expect(data.isIncrease, isFalse);
      expect(data.isUnchanged, isFalse);
    });

    test('isUnchanged - 차이가 0일 때 true를 반환해야 한다', () {
      const data = MonthComparisonData(
        currentTotal: 400000,
        previousTotal: 400000,
        difference: 0,
        percentageChange: 0.0,
      );

      expect(data.isUnchanged, isTrue);
      expect(data.isIncrease, isFalse);
      expect(data.isDecrease, isFalse);
    });

    test('empty 팩토리가 모든 숫자 필드를 0으로 초기화해야 한다', () {
      final data = MonthComparisonData.empty();

      expect(data.currentTotal, equals(0));
      expect(data.previousTotal, equals(0));
      expect(data.difference, equals(0));
      expect(data.percentageChange, equals(0.0));
    });

    test('empty 팩토리로 생성한 데이터의 isUnchanged가 true여야 한다', () {
      final data = MonthComparisonData.empty();

      expect(data.isUnchanged, isTrue);
    });

    test('큰 금액에서도 차이 비교가 올바르게 동작해야 한다', () {
      const data = MonthComparisonData(
        currentTotal: 10000000,
        previousTotal: 9000000,
        difference: 1000000,
        percentageChange: 11.11,
      );

      expect(data.isIncrease, isTrue);
      expect(data.difference, equals(1000000));
    });

    test('음수 금액이 포함된 경우에도 차이 비교가 올바르게 동작해야 한다', () {
      const data = MonthComparisonData(
        currentTotal: -100000,
        previousTotal: 100000,
        difference: -200000,
        percentageChange: -200.0,
      );

      expect(data.isDecrease, isTrue);
      expect(data.difference, equals(-200000));
    });
  });

  group('YearlyStatistics', () {
    test('생성자가 모든 필드를 올바르게 초기화해야 한다', () {
      const stats = YearlyStatistics(
        year: 2024,
        income: 5000000,
        expense: 3000000,
        saving: 500000,
      );

      expect(stats.year, equals(2024));
      expect(stats.income, equals(5000000));
      expect(stats.expense, equals(3000000));
      expect(stats.saving, equals(500000));
    });

    test('balance가 income에서 expense를 뺀 값을 정확히 반환해야 한다', () {
      const stats = YearlyStatistics(
        year: 2024,
        income: 5000000,
        expense: 3000000,
        saving: 500000,
      );

      expect(stats.balance, equals(2000000));
    });

    test('yearLabel이 연도 뒤에 "년"을 붙인 형식으로 반환해야 한다', () {
      const stats = YearlyStatistics(
        year: 2024,
        income: 1000000,
        expense: 800000,
        saving: 0,
      );

      expect(stats.yearLabel, equals('2024년'));
    });

    test('income이 expense보다 작으면 balance가 음수여야 한다', () {
      const stats = YearlyStatistics(
        year: 2024,
        income: 2000000,
        expense: 3000000,
        saving: 0,
      );

      expect(stats.balance, isNegative);
      expect(stats.balance, equals(-1000000));
    });

    test('income과 expense가 같으면 balance가 0이어야 한다', () {
      const stats = YearlyStatistics(
        year: 2024,
        income: 3000000,
        expense: 3000000,
        saving: 0,
      );

      expect(stats.balance, equals(0));
    });
  });

  group('PaymentMethodStatistics', () {
    const baseStats = PaymentMethodStatistics(
      paymentMethodId: 'pm-001',
      paymentMethodName: 'KB국민카드',
      paymentMethodIcon: 'credit_card',
      paymentMethodColor: '#FF5733',
      amount: 1500000,
      percentage: 35.5,
    );

    test('생성자가 모든 필드를 올바르게 초기화해야 한다', () {
      expect(baseStats.paymentMethodId, equals('pm-001'));
      expect(baseStats.paymentMethodName, equals('KB국민카드'));
      expect(baseStats.paymentMethodIcon, equals('credit_card'));
      expect(baseStats.paymentMethodColor, equals('#FF5733'));
      expect(baseStats.amount, equals(1500000));
      expect(baseStats.percentage, equals(35.5));
    });

    test('canAutoSave의 기본값이 false여야 한다', () {
      expect(baseStats.canAutoSave, isFalse);
    });

    test('copyWith - 특정 필드만 변경하면 해당 필드만 바뀌어야 한다', () {
      final updated = baseStats.copyWith(amount: 2000000);

      expect(updated.amount, equals(2000000));
      expect(updated.paymentMethodId, equals('pm-001'));
      expect(updated.paymentMethodName, equals('KB국민카드'));
      expect(updated.paymentMethodIcon, equals('credit_card'));
      expect(updated.paymentMethodColor, equals('#FF5733'));
      expect(updated.percentage, equals(35.5));
      expect(updated.canAutoSave, isFalse);
    });

    test('copyWith - 모든 필드를 변경하면 모든 필드가 새 값으로 바뀌어야 한다', () {
      final updated = baseStats.copyWith(
        paymentMethodId: 'pm-002',
        paymentMethodName: '신한카드',
        paymentMethodIcon: 'payment',
        paymentMethodColor: '#3357FF',
        canAutoSave: true,
        amount: 800000,
        percentage: 20.0,
      );

      expect(updated.paymentMethodId, equals('pm-002'));
      expect(updated.paymentMethodName, equals('신한카드'));
      expect(updated.paymentMethodIcon, equals('payment'));
      expect(updated.paymentMethodColor, equals('#3357FF'));
      expect(updated.canAutoSave, isTrue);
      expect(updated.amount, equals(800000));
      expect(updated.percentage, equals(20.0));
    });

    test('copyWith에 아무 파라미터도 전달하지 않으면 동일한 값을 유지해야 한다', () {
      final copy = baseStats.copyWith();

      expect(copy.paymentMethodId, equals(baseStats.paymentMethodId));
      expect(copy.paymentMethodName, equals(baseStats.paymentMethodName));
      expect(copy.paymentMethodIcon, equals(baseStats.paymentMethodIcon));
      expect(copy.paymentMethodColor, equals(baseStats.paymentMethodColor));
      expect(copy.canAutoSave, equals(baseStats.canAutoSave));
      expect(copy.amount, equals(baseStats.amount));
      expect(copy.percentage, equals(baseStats.percentage));
    });
  });

  group('TrendStatisticsData', () {
    const trendData = TrendStatisticsData(
      data: [],
      averageIncome: 3000000,
      averageExpense: 2000000,
      averageAsset: 500000,
    );

    test('생성자가 모든 필드를 올바르게 초기화해야 한다', () {
      expect(trendData.averageIncome, equals(3000000));
      expect(trendData.averageExpense, equals(2000000));
      expect(trendData.averageAsset, equals(500000));
      expect(trendData.data, isEmpty);
    });

    test('getAverageByType("income")은 averageIncome을 반환해야 한다', () {
      expect(trendData.getAverageByType('income'), equals(3000000));
    });

    test('getAverageByType("asset")은 averageAsset을 반환해야 한다', () {
      expect(trendData.getAverageByType('asset'), equals(500000));
    });

    test('getAverageByType("expense")은 averageExpense를 반환해야 한다', () {
      expect(trendData.getAverageByType('expense'), equals(2000000));
    });

    test('getAverageByType에 알 수 없는 타입을 전달하면 기본값으로 averageExpense를 반환해야 한다', () {
      expect(trendData.getAverageByType('unknown'), equals(2000000));
      expect(trendData.getAverageByType(''), equals(2000000));
      expect(trendData.getAverageByType('saving'), equals(2000000));
    });

    test('빈 data 리스트를 가진 경우에도 평균값 조회가 정상 동작해야 한다', () {
      const emptyData = TrendStatisticsData(
        data: [],
        averageIncome: 0,
        averageExpense: 0,
        averageAsset: 0,
      );

      expect(emptyData.data, isEmpty);
      expect(emptyData.getAverageByType('income'), equals(0));
      expect(emptyData.getAverageByType('expense'), equals(0));
      expect(emptyData.getAverageByType('asset'), equals(0));
    });
  });
}
