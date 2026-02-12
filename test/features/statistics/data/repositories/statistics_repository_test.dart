import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_household_account/features/statistics/data/repositories/statistics_repository.dart';
import 'package:shared_household_account/features/statistics/domain/entities/statistics_entities.dart';

import '../../../../helpers/mock_supabase.dart';

void main() {
  late MockSupabaseClient mockClient;
  late StatisticsRepository repository;

  setUp(() {
    mockClient = MockSupabaseClient();
    repository = StatisticsRepository(client: mockClient);
  });

  group('StatisticsRepository - getCategoryStatistics', () {
    test('카테고리별 지출 통계를 금액 기준 내림차순으로 반환한다', () async {
      final mockData = [
        {
          'amount': 50000,
          'category_id': 'cat-1',
          'is_fixed_expense': false,
          'categories': {
            'name': '식비',
            'icon': '🍔',
            'color': '#FF5733',
          },
        },
        {
          'amount': 30000,
          'category_id': 'cat-2',
          'is_fixed_expense': false,
          'categories': {
            'name': '교통비',
            'icon': '🚗',
            'color': '#33C1FF',
          },
        },
        {
          'amount': 70000,
          'category_id': 'cat-1',
          'is_fixed_expense': false,
          'categories': {
            'name': '식비',
            'icon': '🍔',
            'color': '#FF5733',
          },
        },
      ];

      when(() => mockClient.from('transactions')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(selectData: mockData),
      );

      final result = await repository.getCategoryStatistics(
        ledgerId: 'ledger-1',
        year: 2026,
        month: 2,
        type: 'expense',
      );

      expect(result.length, 2);
      expect(result[0].categoryName, '식비');
      expect(result[0].amount, 120000);
      expect(result[1].categoryName, '교통비');
      expect(result[1].amount, 30000);
    });

    test('카테고리가 null인 거래는 미지정으로 그룹화된다', () async {
      final mockData = [
        {
          'amount': 10000,
          'category_id': null,
          'is_fixed_expense': false,
          'categories': null,
        },
        {
          'amount': 20000,
          'category_id': null,
          'is_fixed_expense': false,
          'categories': null,
        },
      ];

      when(() => mockClient.from('transactions')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(selectData: mockData),
      );

      final result = await repository.getCategoryStatistics(
        ledgerId: 'ledger-1',
        year: 2026,
        month: 2,
        type: 'expense',
      );

      expect(result.length, 1);
      expect(result[0].categoryName, '미지정');
      expect(result[0].amount, 30000);
    });

    test('고정비를 지출에 편입하는 경우 고정비 카테고리로 별도 그룹화된다', () async {
      final mockData = [
        {
          'amount': 50000,
          'category_id': 'cat-1',
          'is_fixed_expense': true,
          'categories': {
            'name': '관리비',
            'icon': '🏠',
            'color': '#FF9800',
          },
        },
        {
          'amount': 30000,
          'category_id': 'cat-2',
          'is_fixed_expense': false,
          'categories': {
            'name': '식비',
            'icon': '🍔',
            'color': '#FF5733',
          },
        },
      ];

      when(() => mockClient.from('transactions')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(selectData: mockData),
      );

      final result = await repository.getCategoryStatistics(
        ledgerId: 'ledger-1',
        year: 2026,
        month: 2,
        type: 'expense',
        includeFixedExpenseInExpense: true,
      );

      expect(result.length, 2);
      expect(result[0].categoryName, '고정비');
      expect(result[0].amount, 50000);
      expect(result[1].categoryName, '식비');
      expect(result[1].amount, 30000);
    });

    test('빈 데이터인 경우 빈 리스트를 반환한다', () async {
      when(() => mockClient.from('transactions')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(selectData: []),
      );

      final result = await repository.getCategoryStatistics(
        ledgerId: 'ledger-1',
        year: 2026,
        month: 2,
        type: 'expense',
      );

      expect(result, isEmpty);
    });
  });

  group('StatisticsRepository - getCategoryStatisticsByUser', () {
    test('사용자별 카테고리 통계를 반환한다', () async {
      final mockData = [
        {
          'amount': 50000,
          'category_id': 'cat-1',
          'user_id': 'user-1',
          'is_fixed_expense': false,
          'categories': {
            'name': '식비',
            'icon': '🍔',
            'color': '#FF5733',
          },
          'profiles': {
            'display_name': 'User One',
            'email': 'user1@example.com',
            'color': '#4CAF50',
          },
        },
        {
          'amount': 30000,
          'category_id': 'cat-2',
          'user_id': 'user-2',
          'is_fixed_expense': false,
          'categories': {
            'name': '교통비',
            'icon': '🚗',
            'color': '#33C1FF',
          },
          'profiles': {
            'display_name': 'User Two',
            'email': 'user2@example.com',
            'color': '#2196F3',
          },
        },
      ];

      when(() => mockClient.from('transactions')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(selectData: mockData),
      );

      final result = await repository.getCategoryStatisticsByUser(
        ledgerId: 'ledger-1',
        year: 2026,
        month: 2,
        type: 'expense',
      );

      expect(result.keys.length, 2);
      expect(result.containsKey('user-1'), true);
      expect(result.containsKey('user-2'), true);
      expect(result['user-1']!.totalAmount, 50000);
      expect(result['user-2']!.totalAmount, 30000);
    });
  });

  group('StatisticsRepository - getMonthlyTrend', () {
    test('최근 N개월의 월별 추세를 반환한다', () async {
      final now = DateTime.now();
      final mockData = [
        {
          'amount': 100000,
          'type': 'income',
          'date': DateTime(now.year, now.month, 15).toIso8601String(),
        },
        {
          'amount': 50000,
          'type': 'expense',
          'date': DateTime(now.year, now.month, 20).toIso8601String(),
        },
        {
          'amount': 80000,
          'type': 'income',
          'date': DateTime(now.year, now.month - 1, 10).toIso8601String(),
        },
      ];

      when(() => mockClient.from('transactions')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(selectData: mockData),
      );

      final result = await repository.getMonthlyTrend(
        ledgerId: 'ledger-1',
        months: 3,
      );

      expect(result.length, 3);
      expect(result.any((m) => m.year == now.year && m.month == now.month), true);
    });

    test('데이터가 없는 월은 0원으로 초기화된다', () async {
      when(() => mockClient.from('transactions')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(selectData: []),
      );

      final result = await repository.getMonthlyTrend(
        ledgerId: 'ledger-1',
        months: 6,
      );

      expect(result.length, 6);
      expect(result.every((m) => m.income == 0 && m.expense == 0), true);
    });
  });

  group('StatisticsRepository - getMonthComparison', () {
    test('현재 월과 이전 월의 비교 데이터를 반환한다', () async {
      final mockData = [
        {
          'amount': 100000,
          'is_fixed_expense': false,
          'date': '2026-02-15',
        },
        {
          'amount': 80000,
          'is_fixed_expense': false,
          'date': '2026-01-15',
        },
      ];

      when(() => mockClient.from('transactions')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(selectData: mockData),
      );

      final result = await repository.getMonthComparison(
        ledgerId: 'ledger-1',
        year: 2026,
        month: 2,
        type: 'expense',
      );

      expect(result.currentTotal, 100000);
      expect(result.previousTotal, 80000);
      expect(result.difference, 20000);
    });

    test('이전 월 데이터가 0인 경우 백분율 변화는 100 또는 0을 반환한다', () async {
      final mockData = [
        {
          'amount': 50000,
          'is_fixed_expense': false,
          'date': '2026-02-10',
        },
      ];

      when(() => mockClient.from('transactions')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(selectData: mockData),
      );

      final result = await repository.getMonthComparison(
        ledgerId: 'ledger-1',
        year: 2026,
        month: 2,
        type: 'expense',
      );

      expect(result.currentTotal, 50000);
      expect(result.previousTotal, 0);
      expect(result.percentageChange, 100.0);
    });
  });

  group('StatisticsRepository - getPaymentMethodStatistics', () {
    test('결제수단별 통계를 반환한다', () async {
      final mockData = [
        {
          'amount': 50000,
          'payment_method_id': 'pm-1',
          'payment_methods': {
            'name': '신한카드',
            'icon': '💳',
            'color': '#4A90E2',
            'can_auto_save': false,
          },
        },
        {
          'amount': 30000,
          'payment_method_id': 'pm-2',
          'payment_methods': {
            'name': 'KB카드',
            'icon': '💳',
            'color': '#F4A261',
            'can_auto_save': true,
          },
        },
        {
          'amount': 20000,
          'payment_method_id': 'pm-2',
          'payment_methods': {
            'name': 'KB카드',
            'icon': '💳',
            'color': '#F4A261',
            'can_auto_save': true,
          },
        },
      ];

      when(() => mockClient.from('transactions')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(selectData: mockData),
      );

      final result = await repository.getPaymentMethodStatistics(
        ledgerId: 'ledger-1',
        year: 2026,
        month: 2,
        type: 'expense',
      );

      expect(result.length, 2);
      expect(result.any((pm) => pm.amount == 50000), true);
      expect(result.any((pm) => pm.amount == 50000), true);
    });

    test('자동수집 결제수단은 이름 기준으로 그룹화된다', () async {
      final mockData = [
        {
          'amount': 10000,
          'payment_method_id': 'pm-1',
          'payment_methods': {
            'name': '신한카드',
            'icon': '💳',
            'color': '#4A90E2',
            'can_auto_save': true,
          },
        },
        {
          'amount': 20000,
          'payment_method_id': 'pm-2',
          'payment_methods': {
            'name': '신한카드',
            'icon': '💳',
            'color': '#4A90E2',
            'can_auto_save': true,
          },
        },
      ];

      when(() => mockClient.from('transactions')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(selectData: mockData),
      );

      final result = await repository.getPaymentMethodStatistics(
        ledgerId: 'ledger-1',
        year: 2026,
        month: 2,
        type: 'expense',
      );

      expect(result.length, 1);
      expect(result[0].amount, 30000);
      expect(result[0].paymentMethodName, '신한카드');
    });

    test('결제수단이 없는 거래는 미지정으로 그룹화된다', () async {
      final mockData = [
        {
          'amount': 15000,
          'payment_method_id': null,
          'payment_methods': null,
        },
      ];

      when(() => mockClient.from('transactions')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(selectData: mockData),
      );

      final result = await repository.getPaymentMethodStatistics(
        ledgerId: 'ledger-1',
        year: 2026,
        month: 2,
        type: 'expense',
      );

      expect(result.length, 1);
      expect(result[0].paymentMethodName, '미지정');
    });
  });

  group('StatisticsRepository - getYearlyTrend', () {
    test('최근 N년의 연도별 추세를 반환한다', () async {
      final mockData = [
        {
          'amount': 1000000,
          'type': 'income',
          'date': '2026-05-15',
        },
        {
          'amount': 500000,
          'type': 'expense',
          'date': '2026-06-20',
        },
        {
          'amount': 800000,
          'type': 'income',
          'date': '2025-03-10',
        },
      ];

      when(() => mockClient.from('transactions')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(selectData: mockData),
      );

      final result = await repository.getYearlyTrend(
        ledgerId: 'ledger-1',
        years: 3,
      );

      expect(result.length, 3);
      expect(result.any((y) => y.year == 2026), true);
      expect(result.any((y) => y.year == 2025), true);
    });
  });

  group('StatisticsRepository - getMonthlyTrendWithAverage', () {
    test('월별 추세와 평균값을 함께 반환한다', () async {
      final now = DateTime(2026, 2, 12);
      final mockData = [
        {
          'amount': 100000,
          'type': 'income',
          'date': DateTime(2026, 2, 15).toIso8601String(),
          'is_fixed_expense': false,
        },
        {
          'amount': 80000,
          'type': 'income',
          'date': DateTime(2026, 1, 10).toIso8601String(),
          'is_fixed_expense': false,
        },
      ];

      when(() => mockClient.from('transactions')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(selectData: mockData),
      );

      final result = await repository.getMonthlyTrendWithAverage(
        ledgerId: 'ledger-1',
        baseDate: now,
        months: 6,
      );

      expect(result.data.length, 6);
      expect(result.averageIncome, 90000);
    });

    test('0원 데이터는 평균 계산에서 제외된다', () async {
      final now = DateTime(2026, 2, 12);
      final mockData = [
        {
          'amount': 100000,
          'type': 'expense',
          'date': DateTime(2026, 2, 15).toIso8601String(),
          'is_fixed_expense': false,
        },
      ];

      when(() => mockClient.from('transactions')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(selectData: mockData),
      );

      final result = await repository.getMonthlyTrendWithAverage(
        ledgerId: 'ledger-1',
        baseDate: now,
        months: 6,
      );

      expect(result.averageExpense, 100000);
      expect(result.averageIncome, 0);
    });
  });

  group('StatisticsRepository - getYearlyTrendWithAverage', () {
    test('연도별 추세와 평균값을 함께 반환한다', () async {
      final now = DateTime(2026, 2, 12);
      final mockData = [
        {
          'amount': 1000000,
          'type': 'income',
          'date': '2026-05-15',
          'is_fixed_expense': false,
        },
        {
          'amount': 800000,
          'type': 'income',
          'date': '2025-03-10',
          'is_fixed_expense': false,
        },
      ];

      when(() => mockClient.from('transactions')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(selectData: mockData),
      );

      final result = await repository.getYearlyTrendWithAverage(
        ledgerId: 'ledger-1',
        baseDate: now,
        years: 6,
      );

      expect(result.data.length, 6);
      expect(result.averageIncome, 900000);
    });

    test('고정비 필터가 적용된 경우 해당 거래만 집계된다', () async {
      final now = DateTime(2026, 2, 12);
      final mockData = [
        {
          'amount': 50000,
          'type': 'expense',
          'date': '2026-05-15',
          'is_fixed_expense': true,
        },
        {
          'amount': 30000,
          'type': 'expense',
          'date': '2026-06-10',
          'is_fixed_expense': false,
        },
      ];

      when(() => mockClient.from('transactions')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(selectData: mockData),
      );

      final result = await repository.getYearlyTrendWithAverage(
        ledgerId: 'ledger-1',
        baseDate: now,
        years: 3,
        expenseTypeFilter: ExpenseTypeFilter.fixed,
      );

      expect(result.averageExpense, 50000);
    });
  });
}
