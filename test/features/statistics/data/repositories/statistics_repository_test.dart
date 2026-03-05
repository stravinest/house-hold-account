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

    test('고정비 거래도 원래 카테고리 이름으로 표시된다', () async {
      final mockData = [
        {
          'amount': 50000,
          'category_id': 'cat-1',
          'is_fixed_expense': true,
          'fixed_expense_category_id': 'fcat-1',
          'categories': {
            'name': '관리비',
            'icon': '🏠',
            'color': '#FF9800',
          },
          'fixed_expense_categories': {
            'name': '관리비',
            'icon': '🏠',
            'color': '#FF9800',
          },
        },
        {
          'amount': 30000,
          'category_id': 'cat-2',
          'is_fixed_expense': false,
          'fixed_expense_category_id': null,
          'categories': {
            'name': '식비',
            'icon': '🍔',
            'color': '#FF5733',
          },
          'fixed_expense_categories': null,
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
      expect(result[0].categoryName, '관리비');
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

  group('StatisticsRepository - getCategoryTopTransactions', () {
    const ledgerId = 'ledger-123';
    const year = 2026;
    const month = 2;
    const type = 'expense';
    const limit = 5;

    test('정상 카테고리 ID로 조회 시 상위 거래를 금액 내림차순으로 반환한다', () async {
      // Given: 정상 카테고리 ID와 해당 거래들
      const categoryId = 'category-abc';
      final mockTransactions = [
        {
          'id': 'tx-1',
          'title': '편의점',
          'amount': 50000,
          'date': '2026-02-15',
          'user_id': 'user-1',
          'profiles': {'display_name': '홍길동', 'color': '#FF5722'},
        },
        {
          'id': 'tx-2',
          'title': '마트',
          'amount': 30000,
          'date': '2026-02-14',
          'user_id': 'user-2',
          'profiles': {'display_name': '김철수', 'color': '#4CAF50'},
        },
        {
          'id': 'tx-3',
          'title': '카페',
          'amount': 20000,
          'date': '2026-02-13',
          'user_id': 'user-1',
          'profiles': {'display_name': '홍길동', 'color': '#FF5722'},
        },
      ];

      when(() => mockClient.from('transactions')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(selectData: mockTransactions),
      );

      // When
      final result = await repository.getCategoryTopTransactions(
        ledgerId: ledgerId,
        year: year,
        month: month,
        type: type,
        categoryId: categoryId,
        limit: limit,
      );

      // Then: CategoryTopResult 구조 검증
      expect(result.items.length, 3);
      expect(result.totalAmount, 100000); // 50000 + 30000 + 20000

      // 금액 내림차순 정렬 검증
      expect(result.items[0].rank, 1);
      expect(result.items[0].title, '편의점');
      expect(result.items[0].amount, 50000);
      expect(result.items[0].userName, '홍길동');
      expect(result.items[0].userColor, '#FF5722');
      expect(result.items[1].rank, 2);
      expect(result.items[1].title, '마트');
      expect(result.items[1].amount, 30000);
      expect(result.items[2].rank, 3);
      expect(result.items[2].title, '카페');

      // 날짜 포맷 검증
      expect(result.items[0].date, contains('2월 15일'));
      expect(result.items[1].date, contains('2월 14일'));
    });

    test('퍼센티지가 총액 대비 올바르게 계산된다', () async {
      // Given: 총액 80,000원 중 각 거래 비율
      const categoryId = 'category-abc';
      final mockTransactions = [
        {
          'id': 'tx-1',
          'title': '거래1',
          'amount': 50000,
          'date': '2026-02-10',
          'user_id': 'user-1',
          'profiles': {'display_name': '홍길동', 'color': '#A8D8EA'},
        },
        {
          'id': 'tx-2',
          'title': '거래2',
          'amount': 30000,
          'date': '2026-02-11',
          'user_id': 'user-1',
          'profiles': {'display_name': '홍길동', 'color': '#A8D8EA'},
        },
      ];

      when(() => mockClient.from('transactions')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(selectData: mockTransactions),
      );

      // When
      final result = await repository.getCategoryTopTransactions(
        ledgerId: ledgerId,
        year: year,
        month: month,
        type: type,
        categoryId: categoryId,
        limit: limit,
      );

      // Then: 퍼센티지 검증 (50000/80000 = 62.5%, 30000/80000 = 37.5%)
      expect(result.items.length, 2);
      expect(result.totalAmount, 80000);
      expect(result.items[0].percentage, closeTo(62.5, 0.1));
      expect(result.items[1].percentage, closeTo(37.5, 0.1));
    });

    test('미지정 카테고리(_uncategorized_)로 조회 시 category_id가 null인 거래만 반환한다',
        () async {
      // Given: 미지정 카테고리 ID
      const categoryId = '_uncategorized_';
      final mockTransactions = [
        {
          'id': 'tx-1',
          'title': '기타 지출',
          'amount': 10000,
          'date': '2026-02-10',
          'user_id': 'user-1',
          'profiles': {'display_name': '홍길동', 'color': '#A8D8EA'},
        },
      ];

      when(() => mockClient.from('transactions')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(selectData: mockTransactions),
      );

      // When
      final result = await repository.getCategoryTopTransactions(
        ledgerId: ledgerId,
        year: year,
        month: month,
        type: type,
        categoryId: categoryId,
        limit: limit,
      );

      // Then
      expect(result.items.length, 1);
      expect(result.totalAmount, 10000);
      expect(result.items[0].title, '기타 지출');
      expect(result.items[0].amount, 10000);
      expect(result.items[0].percentage, 100.0); // 총액 대비 100%
    });

    test('고정비 카테고리(_fixed_expense_)로 조회 시 is_fixed_expense가 true인 거래만 반환한다',
        () async {
      // Given: 고정비 카테고리 ID
      const categoryId = '_fixed_expense_';
      final mockTransactions = [
        {
          'id': 'tx-1',
          'title': '월세',
          'amount': 500000,
          'date': '2026-02-01',
          'user_id': 'user-1',
          'profiles': {'display_name': '홍길동', 'color': '#FF9800'},
        },
        {
          'id': 'tx-2',
          'title': '통신비',
          'amount': 50000,
          'date': '2026-02-05',
          'user_id': 'user-1',
          'profiles': {'display_name': '홍길동', 'color': '#FF9800'},
        },
      ];

      when(() => mockClient.from('transactions')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(selectData: mockTransactions),
      );

      // When
      final result = await repository.getCategoryTopTransactions(
        ledgerId: ledgerId,
        year: year,
        month: month,
        type: type,
        categoryId: categoryId,
        limit: limit,
      );

      // Then: 고정비 거래만 포함
      expect(result.items.length, 2);
      expect(result.totalAmount, 550000);
      expect(result.items[0].title, '월세');
      expect(result.items[0].amount, 500000);
      expect(result.items[1].title, '통신비');
      expect(result.items[1].amount, 50000);

      // 퍼센티지 검증 (500000 / 550000 ≈ 90.9%)
      expect(result.items[0].percentage, closeTo(90.9, 0.1));
      expect(result.items[1].percentage, closeTo(9.1, 0.1));
    });

    test('거래가 없는 경우 빈 리스트를 반환한다', () async {
      // Given: 거래가 없는 카테고리
      const categoryId = 'empty-category';
      final mockTransactions = <Map<String, dynamic>>[];

      when(() => mockClient.from('transactions')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(selectData: mockTransactions),
      );

      // When
      final result = await repository.getCategoryTopTransactions(
        ledgerId: ledgerId,
        year: year,
        month: month,
        type: type,
        categoryId: categoryId,
        limit: limit,
      );

      // Then
      expect(result.items, isEmpty);
      expect(result.totalAmount, 0);
    });

    test('limit 파라미터만큼만 거래를 반환한다', () async {
      // Given: 10개 거래가 있지만 limit=3으로 설정
      const categoryId = 'category-abc';
      const customLimit = 3;
      final mockTransactions = [
        {
          'id': 'tx-1',
          'title': '거래1',
          'amount': 10000,
          'date': '2026-02-10',
          'user_id': 'user-1',
          'profiles': {'display_name': '홍길동', 'color': '#A8D8EA'},
        },
        {
          'id': 'tx-2',
          'title': '거래2',
          'amount': 9000,
          'date': '2026-02-11',
          'user_id': 'user-1',
          'profiles': {'display_name': '홍길동', 'color': '#A8D8EA'},
        },
        {
          'id': 'tx-3',
          'title': '거래3',
          'amount': 8000,
          'date': '2026-02-12',
          'user_id': 'user-1',
          'profiles': {'display_name': '홍길동', 'color': '#A8D8EA'},
        },
        {
          'id': 'tx-4',
          'title': '거래4',
          'amount': 7000,
          'date': '2026-02-13',
          'user_id': 'user-1',
          'profiles': {'display_name': '홍길동', 'color': '#A8D8EA'},
        },
      ];

      when(() => mockClient.from('transactions')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(selectData: mockTransactions),
      );

      // When
      final result = await repository.getCategoryTopTransactions(
        ledgerId: ledgerId,
        year: year,
        month: month,
        type: type,
        categoryId: categoryId,
        limit: customLimit,
      );

      // Then: limit만큼만 반환, rank 순서 검증
      expect(result.items.length, customLimit);
      expect(result.totalAmount, 34000); // 전체 합계
      expect(result.items[0].rank, 1);
      expect(result.items[1].rank, 2);
      expect(result.items[2].rank, 3);
    });

    test('사용자 정보가 없는 경우 기본값을 사용한다', () async {
      // Given: profiles가 null이고 title도 null인 거래
      const categoryId = 'category-abc';
      final mockTransactions = [
        {
          'id': 'tx-1',
          'title': null,
          'amount': null,
          'date': '2026-02-10',
          'user_id': 'user-1',
          'profiles': null,
        },
      ];

      when(() => mockClient.from('transactions')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(selectData: mockTransactions),
      );

      // When
      final result = await repository.getCategoryTopTransactions(
        ledgerId: ledgerId,
        year: year,
        month: month,
        type: type,
        categoryId: categoryId,
        limit: limit,
      );

      // Then: 기본값 검증
      expect(result.items.length, 1);
      expect(result.totalAmount, 0);
      expect(result.items[0].title, ''); // title이 null이면 빈 문자열
      expect(result.items[0].amount, 0); // amount가 null이면 0
      expect(result.items[0].userName, ''); // profiles가 null이면 빈 문자열
      expect(result.items[0].userColor, '#A8D8EA'); // 기본 파스텔 블루 색상
    });

    test('날짜 포맷이 올바르게 변환된다 (월, 일, 요일)', () async {
      // Given: 다양한 요일의 거래 (2026-02-15는 일요일, 2026-02-16은 월요일)
      const categoryId = 'category-abc';
      final mockTransactions = [
        {
          'id': 'tx-1',
          'title': '일요일 거래',
          'amount': 10000,
          'date': '2026-02-15',
          'user_id': 'user-1',
          'profiles': {'display_name': '홍길동', 'color': '#A8D8EA'},
        },
        {
          'id': 'tx-2',
          'title': '월요일 거래',
          'amount': 9000,
          'date': '2026-02-16',
          'user_id': 'user-1',
          'profiles': {'display_name': '홍길동', 'color': '#A8D8EA'},
        },
        {
          'id': 'tx-3',
          'title': '토요일 거래',
          'amount': 8000,
          'date': '2026-02-14',
          'user_id': 'user-1',
          'profiles': {'display_name': '홍길동', 'color': '#A8D8EA'},
        },
      ];

      when(() => mockClient.from('transactions')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(selectData: mockTransactions),
      );

      // When
      final result = await repository.getCategoryTopTransactions(
        ledgerId: ledgerId,
        year: year,
        month: month,
        type: type,
        categoryId: categoryId,
        limit: limit,
      );

      // Then: 날짜 포맷 검증 (M월 D일 (요일) 형식)
      expect(result.items.length, 3);
      expect(result.items[0].date, '2월 15일 (일)');
      expect(result.items[1].date, '2월 16일 (월)');
      expect(result.items[2].date, '2월 14일 (토)');
    });

    test('변동비 필터로 미지정 카테고리 조회 시 고정비 거래가 제외되어야 한다', () async {
      // Given: 변동비 필터 + 미지정 카테고리 조회
      // mock은 필터를 무시하므로, 변동비만 포함된 데이터를 준비
      const categoryId = '_uncategorized_';
      final mockTransactions = [
        {
          'id': 'tx-1',
          'title': '기타 변동비',
          'amount': 15000,
          'date': '2026-02-10',
          'user_id': 'user-1',
          'profiles': {'display_name': '홍길동', 'color': '#A8D8EA'},
        },
      ];

      when(() => mockClient.from('transactions')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(selectData: mockTransactions),
      );

      // When: expenseTypeFilter=variable로 조회
      final result = await repository.getCategoryTopTransactions(
        ledgerId: ledgerId,
        year: year,
        month: month,
        type: type,
        categoryId: categoryId,
        expenseTypeFilter: ExpenseTypeFilter.variable,
        limit: limit,
      );

      // Then: 변동비 거래만 반환되어야 함 (고정비는 Supabase 쿼리 레벨에서 제외됨)
      expect(result.items.length, 1);
      expect(result.items[0].title, '기타 변동비');
      expect(result.totalAmount, 15000);
    });

    test('고정비 필터로 미지정 카테고리 조회 시 fixed_expense_category_id가 null인 거래만 반환한다', () async {
      // Given: 고정비 필터 + 미지정 카테고리 (isFixedExpenseFilter=true)
      const categoryId = '_uncategorized_';
      final mockTransactions = [
        {
          'id': 'tx-1',
          'title': '미분류 고정비',
          'amount': 30000,
          'date': '2026-02-05',
          'user_id': 'user-1',
          'profiles': {'display_name': '홍길동', 'color': '#FF9800'},
        },
      ];

      when(() => mockClient.from('transactions')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(selectData: mockTransactions),
      );

      // When: isFixedExpenseFilter=true로 조회 (fixed_expense_category_id IS NULL 쿼리 사용)
      final result = await repository.getCategoryTopTransactions(
        ledgerId: ledgerId,
        year: year,
        month: month,
        type: type,
        categoryId: categoryId,
        isFixedExpenseFilter: true,
        expenseTypeFilter: ExpenseTypeFilter.fixed,
        limit: limit,
      );

      // Then: fixed_expense_category_id가 null인 고정비 거래만 반환
      expect(result.items.length, 1);
      expect(result.items[0].title, '미분류 고정비');
      expect(result.totalAmount, 30000);
    });

    test('고정비 필터로 특정 카테고리 조회 시 fixed_expense_category_id로 매칭한다', () async {
      // Given: 고정비 필터 + 특정 카테고리 ID (isFixedExpenseFilter=true)
      const categoryId = 'fixed-cat-1';
      final mockTransactions = [
        {
          'id': 'tx-1',
          'title': '월세',
          'amount': 500000,
          'date': '2026-02-01',
          'user_id': 'user-1',
          'profiles': {'display_name': '홍길동', 'color': '#FF9800'},
        },
        {
          'id': 'tx-2',
          'title': '관리비',
          'amount': 100000,
          'date': '2026-02-01',
          'user_id': 'user-1',
          'profiles': {'display_name': '홍길동', 'color': '#FF9800'},
        },
      ];

      when(() => mockClient.from('transactions')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(selectData: mockTransactions),
      );

      // When: isFixedExpenseFilter=true, 특정 카테고리 ID로 조회
      final result = await repository.getCategoryTopTransactions(
        ledgerId: ledgerId,
        year: year,
        month: month,
        type: type,
        categoryId: categoryId,
        isFixedExpenseFilter: true,
        expenseTypeFilter: ExpenseTypeFilter.fixed,
        limit: limit,
      );

      // Then: fixed_expense_category_id가 categoryId인 거래만 반환
      expect(result.items.length, 2);
      expect(result.totalAmount, 600000);
      expect(result.items[0].title, '월세');
      expect(result.items[1].title, '관리비');
    });

    test('전체 필터(all)로 미지정 카테고리 조회 시 모든 거래가 포함된다', () async {
      // Given: 전체 필터 + 미지정 카테고리
      const categoryId = '_uncategorized_';
      final mockTransactions = [
        {
          'id': 'tx-1',
          'title': '미분류 변동비',
          'amount': 10000,
          'date': '2026-02-10',
          'user_id': 'user-1',
          'profiles': {'display_name': '홍길동', 'color': '#A8D8EA'},
        },
        {
          'id': 'tx-2',
          'title': '미분류 고정비',
          'amount': 20000,
          'date': '2026-02-12',
          'user_id': 'user-1',
          'profiles': {'display_name': '홍길동', 'color': '#A8D8EA'},
        },
      ];

      when(() => mockClient.from('transactions')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(selectData: mockTransactions),
      );

      // When: expenseTypeFilter=all로 조회
      final result = await repository.getCategoryTopTransactions(
        ledgerId: ledgerId,
        year: year,
        month: month,
        type: type,
        categoryId: categoryId,
        expenseTypeFilter: ExpenseTypeFilter.all,
        limit: limit,
      );

      // Then: 고정비/변동비 관계없이 category_id가 null인 모든 거래 포함
      expect(result.items.length, 2);
      expect(result.totalAmount, 30000);
    });

    test('expenseTypeFilter가 null인 경우 기존 동작과 동일하게 동작한다', () async {
      // Given: expenseTypeFilter 미지정
      const categoryId = 'category-abc';
      final mockTransactions = [
        {
          'id': 'tx-1',
          'title': '일반 거래',
          'amount': 25000,
          'date': '2026-02-10',
          'user_id': 'user-1',
          'profiles': {'display_name': '홍길동', 'color': '#A8D8EA'},
        },
      ];

      when(() => mockClient.from('transactions')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(selectData: mockTransactions),
      );

      // When: expenseTypeFilter를 전달하지 않음
      final result = await repository.getCategoryTopTransactions(
        ledgerId: ledgerId,
        year: year,
        month: month,
        type: type,
        categoryId: categoryId,
        limit: limit,
      );

      // Then: 기존과 동일하게 category_id 기준으로 조회
      expect(result.items.length, 1);
      expect(result.items[0].title, '일반 거래');
      expect(result.totalAmount, 25000);
    });

    test('총액이 0인 경우에도 퍼센티지를 0으로 반환한다', () async {
      // Given: amount가 모두 0인 거래들
      const categoryId = 'category-abc';
      final mockTransactions = [
        {
          'id': 'tx-1',
          'title': '무료 거래',
          'amount': 0,
          'date': '2026-02-10',
          'user_id': 'user-1',
          'profiles': {'display_name': '홍길동', 'color': '#A8D8EA'},
        },
      ];

      when(() => mockClient.from('transactions')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(selectData: mockTransactions),
      );

      // When
      final result = await repository.getCategoryTopTransactions(
        ledgerId: ledgerId,
        year: year,
        month: month,
        type: type,
        categoryId: categoryId,
        limit: limit,
      );

      // Then: 총액이 0이면 퍼센티지도 0
      expect(result.items.length, 1);
      expect(result.totalAmount, 0);
      expect(result.items[0].amount, 0);
      expect(result.items[0].percentage, 0.0);
    });
  });

  group('StatisticsRepository - getCategoryStatistics ExpenseTypeFilter', () {
    test('ExpenseTypeFilter.fixed 필터가 적용되면 고정비 카테고리로 그룹화된다', () async {
      final mockData = [
        {
          'amount': 50000,
          'fixed_expense_category_id': 'fcat-1',
          'is_fixed_expense': true,
          'fixed_expense_categories': {
            'name': '월세',
            'icon': '🏠',
            'color': '#FF9800',
          },
        },
        {
          'amount': 30000,
          'fixed_expense_category_id': 'fcat-1',
          'is_fixed_expense': true,
          'fixed_expense_categories': {
            'name': '월세',
            'icon': '🏠',
            'color': '#FF9800',
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
        expenseTypeFilter: ExpenseTypeFilter.fixed,
      );

      expect(result.length, 1);
      expect(result[0].categoryName, '월세');
      expect(result[0].amount, 80000);
    });

    test('ExpenseTypeFilter.variable 필터가 적용된다', () async {
      final mockData = [
        {
          'amount': 20000,
          'category_id': 'cat-1',
          'is_fixed_expense': false,
          'fixed_expense_category_id': null,
          'categories': {
            'name': '식비',
            'icon': '🍔',
            'color': '#FF5733',
          },
          'fixed_expense_categories': null,
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
        expenseTypeFilter: ExpenseTypeFilter.variable,
      );

      expect(result.length, 1);
      expect(result[0].categoryName, '식비');
      expect(result[0].amount, 20000);
    });

    test('ExpenseTypeFilter.all 필터가 적용된다', () async {
      final mockData = [
        {
          'amount': 10000,
          'category_id': 'cat-1',
          'is_fixed_expense': false,
          'fixed_expense_category_id': null,
          'categories': {
            'name': '교통비',
            'icon': '🚗',
            'color': '#33C1FF',
          },
          'fixed_expense_categories': null,
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
        expenseTypeFilter: ExpenseTypeFilter.all,
      );

      expect(result.length, 1);
      expect(result[0].categoryName, '교통비');
    });

    test('고정비 카테고리가 없으면 일반 카테고리로 폴백된다', () async {
      final mockData = [
        {
          'amount': 30000,
          'category_id': 'cat-1',
          'is_fixed_expense': true,
          'fixed_expense_category_id': null,
          'categories': {
            'name': '기타',
            'icon': '📦',
            'color': '#9E9E9E',
          },
          'fixed_expense_categories': null,
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
      expect(result[0].categoryName, '기타');
      expect(result[0].amount, 30000);
    });
  });

  group('StatisticsRepository - getCategoryStatisticsByUser ExpenseTypeFilter', () {
    test('ExpenseTypeFilter.fixed 필터가 적용된다', () async {
      final mockData = [
        {
          'amount': 40000,
          'category_id': 'cat-1',
          'user_id': 'user-1',
          'is_fixed_expense': true,
          'fixed_expense_category_id': 'fcat-1',
          'categories': null,
          'fixed_expense_categories': {
            'name': '통신비',
            'icon': '📱',
            'color': '#2196F3',
          },
          'profiles': {
            'display_name': '홍길동',
            'email': 'hong@test.com',
            'color': '#A8D8EA',
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
        expenseTypeFilter: ExpenseTypeFilter.fixed,
      );

      expect(result.keys.length, 1);
      expect(result['user-1']!.totalAmount, 40000);
    });

    test('ExpenseTypeFilter.variable 필터가 적용된다', () async {
      final mockData = [
        {
          'amount': 15000,
          'category_id': 'cat-2',
          'user_id': 'user-2',
          'is_fixed_expense': false,
          'fixed_expense_category_id': null,
          'categories': {
            'name': '외식',
            'icon': '🍽️',
            'color': '#E91E63',
          },
          'fixed_expense_categories': null,
          'profiles': {
            'display_name': '김철수',
            'email': 'kim@test.com',
            'color': '#FFB6A3',
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
        expenseTypeFilter: ExpenseTypeFilter.variable,
      );

      expect(result.keys.length, 1);
      expect(result['user-2']!.totalAmount, 15000);
    });

    test('ExpenseTypeFilter.all 필터가 적용된다', () async {
      final mockData = [
        {
          'amount': 25000,
          'category_id': 'cat-1',
          'user_id': 'user-1',
          'is_fixed_expense': false,
          'fixed_expense_category_id': null,
          'categories': {
            'name': '쇼핑',
            'icon': '🛍️',
            'color': '#9C27B0',
          },
          'fixed_expense_categories': null,
          'profiles': {
            'display_name': '이영희',
            'email': 'lee@test.com',
            'color': '#D4A5D4',
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
        expenseTypeFilter: ExpenseTypeFilter.all,
      );

      expect(result.keys.length, 1);
      expect(result['user-1']!.totalAmount, 25000);
    });

    test('고정비 거래에서 fixed_expense_category_id가 null이면 미지정으로 분류된다', () async {
      final mockData = [
        {
          'amount': 10000,
          'category_id': null,
          'user_id': 'user-1',
          'is_fixed_expense': true,
          'fixed_expense_category_id': null,
          'categories': null,
          'fixed_expense_categories': null,
          'profiles': {
            'display_name': '홍길동',
            'email': 'hong@test.com',
            'color': '#A8D8EA',
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

      expect(result.keys.length, 1);
      expect(result['user-1']!.totalAmount, 10000);
    });
  });

  group('StatisticsRepository - getMonthComparison ExpenseTypeFilter', () {
    test('ExpenseTypeFilter.fixed 필터가 적용된다', () async {
      final mockData = [
        {
          'amount': 60000,
          'is_fixed_expense': true,
          'date': '2026-02-10',
        },
        {
          'amount': 40000,
          'is_fixed_expense': true,
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
        expenseTypeFilter: ExpenseTypeFilter.fixed,
      );

      expect(result.currentTotal, 60000);
      expect(result.previousTotal, 40000);
    });

    test('ExpenseTypeFilter.variable 필터가 적용된다', () async {
      final mockData = [
        {
          'amount': 30000,
          'is_fixed_expense': false,
          'date': '2026-02-05',
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
        expenseTypeFilter: ExpenseTypeFilter.variable,
      );

      expect(result.currentTotal, 30000);
    });

    test('ExpenseTypeFilter.all 필터가 적용된다', () async {
      final mockData = [
        {
          'amount': 50000,
          'is_fixed_expense': false,
          'date': '2026-02-20',
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
        expenseTypeFilter: ExpenseTypeFilter.all,
      );

      expect(result.currentTotal, 50000);
    });
  });

  group('StatisticsRepository - getPaymentMethodStatisticsByUser', () {
    test('사용자별 결제수단 통계를 반환한다', () async {
      final mockData = [
        {
          'amount': 50000,
          'payment_method_id': 'pm-1',
          'user_id': 'user-1',
          'is_fixed_expense': false,
          'payment_methods': {
            'name': '신한카드',
            'icon': '💳',
            'color': '#4A90E2',
            'can_auto_save': false,
          },
          'profiles': {
            'display_name': '홍길동',
            'email': 'hong@test.com',
            'color': '#A8D8EA',
          },
        },
        {
          'amount': 30000,
          'payment_method_id': 'pm-2',
          'user_id': 'user-2',
          'is_fixed_expense': false,
          'payment_methods': {
            'name': 'KB카드',
            'icon': '💳',
            'color': '#F4A261',
            'can_auto_save': false,
          },
          'profiles': {
            'display_name': '김철수',
            'email': 'kim@test.com',
            'color': '#FFB6A3',
          },
        },
      ];

      when(() => mockClient.from('transactions')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(selectData: mockData),
      );

      final result = await repository.getPaymentMethodStatisticsByUser(
        ledgerId: 'ledger-1',
        year: 2026,
        month: 2,
        type: 'expense',
      );

      expect(result.keys.length, 2);
      expect(result['user-1']!.totalAmount, 50000);
      expect(result['user-2']!.totalAmount, 30000);
    });

    test('결제수단이 없는 거래는 미지정으로 그룹화된다', () async {
      final mockData = [
        {
          'amount': 20000,
          'payment_method_id': null,
          'user_id': 'user-1',
          'is_fixed_expense': false,
          'payment_methods': null,
          'profiles': {
            'display_name': '홍길동',
            'email': 'hong@test.com',
            'color': '#A8D8EA',
          },
        },
      ];

      when(() => mockClient.from('transactions')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(selectData: mockData),
      );

      final result = await repository.getPaymentMethodStatisticsByUser(
        ledgerId: 'ledger-1',
        year: 2026,
        month: 2,
        type: 'expense',
      );

      expect(result.keys.length, 1);
      expect(result['user-1']!.totalAmount, 20000);
    });

    test('ExpenseTypeFilter.fixed 필터가 적용된다', () async {
      final mockData = [
        {
          'amount': 45000,
          'payment_method_id': 'pm-1',
          'user_id': 'user-1',
          'is_fixed_expense': true,
          'payment_methods': {
            'name': '신한카드',
            'icon': '💳',
            'color': '#4A90E2',
            'can_auto_save': false,
          },
          'profiles': {
            'display_name': '홍길동',
            'email': 'hong@test.com',
            'color': '#A8D8EA',
          },
        },
      ];

      when(() => mockClient.from('transactions')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(selectData: mockData),
      );

      final result = await repository.getPaymentMethodStatisticsByUser(
        ledgerId: 'ledger-1',
        year: 2026,
        month: 2,
        type: 'expense',
        expenseTypeFilter: ExpenseTypeFilter.fixed,
      );

      expect(result.keys.length, 1);
      expect(result['user-1']!.totalAmount, 45000);
    });

    test('ExpenseTypeFilter.variable 필터가 적용된다', () async {
      final mockData = [
        {
          'amount': 12000,
          'payment_method_id': 'pm-2',
          'user_id': 'user-2',
          'is_fixed_expense': false,
          'payment_methods': {
            'name': '현금',
            'icon': '💵',
            'color': '#4CAF50',
            'can_auto_save': false,
          },
          'profiles': {
            'display_name': '김철수',
            'email': 'kim@test.com',
            'color': '#FFB6A3',
          },
        },
      ];

      when(() => mockClient.from('transactions')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(selectData: mockData),
      );

      final result = await repository.getPaymentMethodStatisticsByUser(
        ledgerId: 'ledger-1',
        year: 2026,
        month: 2,
        type: 'expense',
        expenseTypeFilter: ExpenseTypeFilter.variable,
      );

      expect(result.keys.length, 1);
      expect(result['user-2']!.totalAmount, 12000);
    });

    test('ExpenseTypeFilter.all 필터가 적용된다', () async {
      final mockData = [
        {
          'amount': 35000,
          'payment_method_id': 'pm-1',
          'user_id': 'user-1',
          'is_fixed_expense': false,
          'payment_methods': {
            'name': '토스',
            'icon': '💸',
            'color': '#0064FF',
            'can_auto_save': false,
          },
          'profiles': {
            'display_name': '이영희',
            'email': 'lee@test.com',
            'color': '#D4A5D4',
          },
        },
      ];

      when(() => mockClient.from('transactions')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(selectData: mockData),
      );

      final result = await repository.getPaymentMethodStatisticsByUser(
        ledgerId: 'ledger-1',
        year: 2026,
        month: 2,
        type: 'expense',
        expenseTypeFilter: ExpenseTypeFilter.all,
      );

      expect(result.keys.length, 1);
      expect(result['user-1']!.totalAmount, 35000);
    });

    test('자동수집 결제수단은 이름 기준으로 그룹화된다', () async {
      final mockData = [
        {
          'amount': 10000,
          'payment_method_id': 'pm-1',
          'user_id': 'user-1',
          'is_fixed_expense': false,
          'payment_methods': {
            'name': 'KB Pay',
            'icon': '💳',
            'color': '#FFB300',
            'can_auto_save': true,
          },
          'profiles': {
            'display_name': '홍길동',
            'email': 'hong@test.com',
            'color': '#A8D8EA',
          },
        },
        {
          'amount': 15000,
          'payment_method_id': 'pm-3',
          'user_id': 'user-1',
          'is_fixed_expense': false,
          'payment_methods': {
            'name': 'KB Pay',
            'icon': '💳',
            'color': '#FFB300',
            'can_auto_save': true,
          },
          'profiles': {
            'display_name': '홍길동',
            'email': 'hong@test.com',
            'color': '#A8D8EA',
          },
        },
      ];

      when(() => mockClient.from('transactions')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(selectData: mockData),
      );

      final result = await repository.getPaymentMethodStatisticsByUser(
        ledgerId: 'ledger-1',
        year: 2026,
        month: 2,
        type: 'expense',
      );

      expect(result.keys.length, 1);
      expect(result['user-1']!.totalAmount, 25000);
      expect(result['user-1']!.paymentMethods.length, 1);
    });

    test('user_id가 null인 거래는 건너뛴다', () async {
      final mockData = [
        {
          'amount': 10000,
          'payment_method_id': 'pm-1',
          'user_id': null,
          'is_fixed_expense': false,
          'payment_methods': {
            'name': '신한카드',
            'icon': '💳',
            'color': '#4A90E2',
            'can_auto_save': false,
          },
          'profiles': null,
        },
      ];

      when(() => mockClient.from('transactions')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(selectData: mockData),
      );

      final result = await repository.getPaymentMethodStatisticsByUser(
        ledgerId: 'ledger-1',
        year: 2026,
        month: 2,
        type: 'expense',
      );

      expect(result, isEmpty);
    });
  });

  group('StatisticsRepository - getPaymentMethodStatistics ExpenseTypeFilter', () {
    test('ExpenseTypeFilter.fixed 필터가 적용된다', () async {
      final mockData = [
        {
          'amount': 100000,
          'payment_method_id': 'pm-1',
          'payment_methods': {
            'name': '신한카드',
            'icon': '💳',
            'color': '#4A90E2',
            'can_auto_save': false,
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
        expenseTypeFilter: ExpenseTypeFilter.fixed,
      );

      expect(result.length, 1);
      expect(result[0].amount, 100000);
    });

    test('ExpenseTypeFilter.variable 필터가 적용된다', () async {
      final mockData = [
        {
          'amount': 25000,
          'payment_method_id': 'pm-2',
          'payment_methods': {
            'name': '현금',
            'icon': '💵',
            'color': '#4CAF50',
            'can_auto_save': false,
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
        expenseTypeFilter: ExpenseTypeFilter.variable,
      );

      expect(result.length, 1);
      expect(result[0].amount, 25000);
    });

    test('ExpenseTypeFilter.all 필터가 적용된다', () async {
      final mockData = [
        {
          'amount': 80000,
          'payment_method_id': 'pm-1',
          'payment_methods': {
            'name': '카카오페이',
            'icon': '💛',
            'color': '#FEE500',
            'can_auto_save': false,
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
        expenseTypeFilter: ExpenseTypeFilter.all,
      );

      expect(result.length, 1);
      expect(result[0].amount, 80000);
    });
  });

  group('StatisticsRepository - getMonthlyTrendWithAverage ExpenseTypeFilter', () {
    test('ExpenseTypeFilter.fixed 필터가 적용된다', () async {
      final now = DateTime(2026, 2, 12);
      final mockData = [
        {
          'amount': 70000,
          'type': 'expense',
          'date': DateTime(2026, 2, 10).toIso8601String(),
          'is_fixed_expense': true,
        },
      ];

      when(() => mockClient.from('transactions')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(selectData: mockData),
      );

      final result = await repository.getMonthlyTrendWithAverage(
        ledgerId: 'ledger-1',
        baseDate: now,
        months: 3,
        expenseTypeFilter: ExpenseTypeFilter.fixed,
      );

      expect(result.data.length, 3);
      expect(result.averageExpense, 70000);
    });

    test('ExpenseTypeFilter.variable 필터가 적용된다', () async {
      final now = DateTime(2026, 2, 12);
      final mockData = [
        {
          'amount': 45000,
          'type': 'expense',
          'date': DateTime(2026, 2, 5).toIso8601String(),
          'is_fixed_expense': false,
        },
      ];

      when(() => mockClient.from('transactions')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(selectData: mockData),
      );

      final result = await repository.getMonthlyTrendWithAverage(
        ledgerId: 'ledger-1',
        baseDate: now,
        months: 3,
        expenseTypeFilter: ExpenseTypeFilter.variable,
      );

      expect(result.data.length, 3);
      expect(result.averageExpense, 45000);
    });

    test('ExpenseTypeFilter.all 필터가 적용된다', () async {
      final now = DateTime(2026, 2, 12);
      final mockData = [
        {
          'amount': 55000,
          'type': 'expense',
          'date': DateTime(2026, 2, 8).toIso8601String(),
          'is_fixed_expense': false,
        },
      ];

      when(() => mockClient.from('transactions')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(selectData: mockData),
      );

      final result = await repository.getMonthlyTrendWithAverage(
        ledgerId: 'ledger-1',
        baseDate: now,
        months: 3,
        expenseTypeFilter: ExpenseTypeFilter.all,
      );

      expect(result.data.length, 3);
      expect(result.averageExpense, 55000);
    });
  });

  group('CategoryTopTransaction 모델', () {
    test('모든 속성이 올바르게 저장된다', () {
      // Given & When: 모든 속성을 가진 CategoryTopTransaction 생성
      const transaction = CategoryTopTransaction(
        rank: 1,
        title: '스타벅스',
        amount: 5000,
        percentage: 25.5,
        date: '2월 16일 (일)',
        userName: '홍길동',
        userColor: '#FF5722',
      );

      // Then: 모든 속성 검증
      expect(transaction.rank, 1);
      expect(transaction.title, '스타벅스');
      expect(transaction.amount, 5000);
      expect(transaction.percentage, 25.5);
      expect(transaction.date, '2월 16일 (일)');
      expect(transaction.userName, '홍길동');
      expect(transaction.userColor, '#FF5722');
    });

    test('퍼센티지가 소수점 첫째 자리까지 정확하게 표현된다', () {
      // Given: 다양한 퍼센티지 값
      const transaction1 = CategoryTopTransaction(
        rank: 1,
        title: '거래1',
        amount: 33333,
        percentage: 33.3,
        date: '2월 16일 (일)',
        userName: '홍길동',
        userColor: '#A8D8EA',
      );

      const transaction2 = CategoryTopTransaction(
        rank: 2,
        title: '거래2',
        amount: 50000,
        percentage: 50.0,
        date: '2월 17일 (월)',
        userName: '김철수',
        userColor: '#4CAF50',
      );

      const transaction3 = CategoryTopTransaction(
        rank: 3,
        title: '거래3',
        amount: 16667,
        percentage: 16.7,
        date: '2월 18일 (화)',
        userName: '이영희',
        userColor: '#FFB6A3',
      );

      // Then: 퍼센티지 검증
      expect(transaction1.percentage, 33.3);
      expect(transaction2.percentage, 50.0);
      expect(transaction3.percentage, 16.7);

      // 합계가 100%에 가까운지 확인
      final totalPercentage =
          transaction1.percentage + transaction2.percentage + transaction3.percentage;
      expect(totalPercentage, closeTo(100.0, 0.1));
    });

    test('rank가 순서대로 증가하고 amount는 내림차순이다', () {
      // Given: 금액 순서대로 정렬된 거래 목록
      final transactions = [
        const CategoryTopTransaction(
          rank: 1,
          title: '1위',
          amount: 100000,
          percentage: 40.0,
          date: '2월 16일 (일)',
          userName: '홍길동',
          userColor: '#A8D8EA',
        ),
        const CategoryTopTransaction(
          rank: 2,
          title: '2위',
          amount: 50000,
          percentage: 20.0,
          date: '2월 16일 (일)',
          userName: '김철수',
          userColor: '#4CAF50',
        ),
        const CategoryTopTransaction(
          rank: 3,
          title: '3위',
          amount: 30000,
          percentage: 12.0,
          date: '2월 16일 (일)',
          userName: '이영희',
          userColor: '#FFB6A3',
        ),
        const CategoryTopTransaction(
          rank: 4,
          title: '4위',
          amount: 20000,
          percentage: 8.0,
          date: '2월 16일 (일)',
          userName: '박민수',
          userColor: '#D4A5D4',
        ),
        const CategoryTopTransaction(
          rank: 5,
          title: '5위',
          amount: 10000,
          percentage: 4.0,
          date: '2월 16일 (일)',
          userName: '최수지',
          userColor: '#FFCBA4',
        ),
      ];

      // Then: rank 순서와 amount 내림차순 검증
      for (int i = 0; i < transactions.length; i++) {
        expect(transactions[i].rank, i + 1, reason: 'rank는 1부터 순서대로 증가해야 한다');
      }

      for (int i = 0; i < transactions.length - 1; i++) {
        expect(
          transactions[i].amount >= transactions[i + 1].amount,
          true,
          reason: 'amount는 내림차순으로 정렬되어야 한다',
        );
      }
    });
  });

  group('StatisticsRepository - getPaymentMethodTopTransactions', () {
    const ledgerId = 'ledger-123';
    const year = 2026;
    const month = 2;
    const type = 'expense';

    test('일반 결제수단 UUID 기준으로 상위 거래를 금액 내림차순으로 반환한다', () async {
      // Given: 일반 결제수단 UUID 기준 거래
      const paymentMethodId = 'pm-uuid-123';
      final mockData = [
        {
          'id': 'tx-1',
          'title': '마트 장보기',
          'amount': 80000,
          'date': '2026-02-10',
          'user_id': 'user-1',
          'payment_method_id': paymentMethodId,
          'profiles': {'display_name': '홍길동', 'color': '#FF5722'},
          'payment_methods': {'name': '신한카드', 'can_auto_save': false},
        },
        {
          'id': 'tx-2',
          'title': '카페',
          'amount': 12000,
          'date': '2026-02-12',
          'user_id': 'user-1',
          'payment_method_id': paymentMethodId,
          'profiles': {'display_name': '홍길동', 'color': '#FF5722'},
          'payment_methods': {'name': '신한카드', 'can_auto_save': false},
        },
      ];

      when(() => mockClient.from('transactions')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(selectData: mockData),
      );

      // When: canAutoSave=false, 일반 UUID 기준 조회
      final result = await repository.getPaymentMethodTopTransactions(
        ledgerId: ledgerId,
        year: year,
        month: month,
        type: type,
        paymentMethodId: paymentMethodId,
        paymentMethodName: '신한카드',
        canAutoSave: false,
      );

      // Then: 금액 내림차순으로 반환
      expect(result.items.length, 2);
      expect(result.totalAmount, 92000);
      expect(result.items[0].rank, 1);
      expect(result.items[0].title, '마트 장보기');
      expect(result.items[0].amount, 80000);
      expect(result.items[1].rank, 2);
      expect(result.items[1].title, '카페');
      expect(result.items[1].amount, 12000);
    });

    test('미지정 결제수단(_no_payment_method_)으로 payment_method_id가 null인 거래를 조회한다',
        () async {
      // Given: payment_method_id가 null인 거래들
      const paymentMethodId = '_no_payment_method_';
      final mockData = [
        {
          'id': 'tx-1',
          'title': '현금 결제',
          'amount': 30000,
          'date': '2026-02-05',
          'user_id': 'user-1',
          'payment_method_id': null,
          'profiles': {'display_name': '홍길동', 'color': '#A8D8EA'},
          'payment_methods': null,
        },
        {
          'id': 'tx-2',
          'title': '현금 지출',
          'amount': 15000,
          'date': '2026-02-08',
          'user_id': 'user-1',
          'payment_method_id': null,
          'profiles': {'display_name': '홍길동', 'color': '#A8D8EA'},
          'payment_methods': null,
        },
      ];

      when(() => mockClient.from('transactions')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(selectData: mockData),
      );

      // When: _no_payment_method_ 기준 조회 (canAutoSave는 false로 전달)
      final result = await repository.getPaymentMethodTopTransactions(
        ledgerId: ledgerId,
        year: year,
        month: month,
        type: type,
        paymentMethodId: paymentMethodId,
        paymentMethodName: '미지정',
        canAutoSave: false,
      );

      // Then: payment_method_id가 null인 거래만 반환
      expect(result.items.length, 2);
      expect(result.totalAmount, 45000);
      expect(result.items[0].title, '현금 결제');
      expect(result.items[0].amount, 30000);
      expect(result.items[1].title, '현금 지출');
      expect(result.items[1].amount, 15000);
    });

    test('자동수집 결제수단(canAutoSave=true)은 이름 기준으로 조회하고 빈 payment_methods를 필터링한다',
        () async {
      // Given: canAutoSave=true, 일부 행은 payment_methods가 빈 객체(필터 대상)
      const paymentMethodId = 'pm-auto-111';
      final mockData = [
        {
          'id': 'tx-1',
          'title': 'KB Pay 결제',
          'amount': 50000,
          'date': '2026-02-14',
          'user_id': 'user-1',
          'payment_method_id': paymentMethodId,
          'profiles': {'display_name': '홍길동', 'color': '#A8D8EA'},
          'payment_methods': {'name': 'KB카드', 'can_auto_save': true},
        },
        {
          'id': 'tx-2',
          'title': 'KB Pay 결제2',
          'amount': 20000,
          'date': '2026-02-15',
          'user_id': 'user-2',
          'payment_method_id': 'pm-auto-222',
          'profiles': {'display_name': '김철수', 'color': '#FFB6A3'},
          'payment_methods': {'name': 'KB카드', 'can_auto_save': true},
        },
        {
          // payment_methods가 빈 객체 - 필터링되어야 함
          'id': 'tx-3',
          'title': '다른 카드 결제',
          'amount': 10000,
          'date': '2026-02-16',
          'user_id': 'user-1',
          'payment_method_id': 'pm-other-333',
          'profiles': {'display_name': '홍길동', 'color': '#A8D8EA'},
          'payment_methods': <String, dynamic>{},
        },
      ];

      when(() => mockClient.from('transactions')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(selectData: mockData),
      );

      // When: canAutoSave=true, 이름 기준 조회
      final result = await repository.getPaymentMethodTopTransactions(
        ledgerId: ledgerId,
        year: year,
        month: month,
        type: type,
        paymentMethodId: paymentMethodId,
        paymentMethodName: 'KB카드',
        canAutoSave: true,
      );

      // Then: payment_methods가 비어있지 않은 행(2개)만 반환
      expect(result.items.length, 2);
      expect(result.totalAmount, 70000);
      expect(result.items[0].amount, 50000);
      expect(result.items[1].amount, 20000);
    });

    test('userId 필터가 적용되면 해당 사용자의 거래만 반환한다', () async {
      // Given: 두 사용자의 거래 데이터
      const paymentMethodId = 'pm-uuid-123';
      final mockData = [
        {
          'id': 'tx-1',
          'title': '사용자1 거래',
          'amount': 60000,
          'date': '2026-02-10',
          'user_id': 'user-1',
          'payment_method_id': paymentMethodId,
          'profiles': {'display_name': '홍길동', 'color': '#FF5722'},
          'payment_methods': {'name': '신한카드', 'can_auto_save': false},
        },
      ];

      when(() => mockClient.from('transactions')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(selectData: mockData),
      );

      // When: userId 필터 적용
      final result = await repository.getPaymentMethodTopTransactions(
        ledgerId: ledgerId,
        year: year,
        month: month,
        type: type,
        paymentMethodId: paymentMethodId,
        paymentMethodName: '신한카드',
        canAutoSave: false,
        userId: 'user-1',
      );

      // Then: user-1의 거래만 반환
      expect(result.items.length, 1);
      expect(result.items[0].title, '사용자1 거래');
      expect(result.items[0].amount, 60000);
      expect(result.items[0].userName, '홍길동');
    });

    test('expenseTypeFilter.fixed 필터가 적용되면 고정비만 반환한다', () async {
      // Given: 고정비 거래 데이터
      const paymentMethodId = 'pm-uuid-456';
      final mockData = [
        {
          'id': 'tx-1',
          'title': '월세',
          'amount': 500000,
          'date': '2026-02-01',
          'user_id': 'user-1',
          'payment_method_id': paymentMethodId,
          'profiles': {'display_name': '홍길동', 'color': '#FF9800'},
          'payment_methods': {'name': '국민카드', 'can_auto_save': false},
        },
      ];

      when(() => mockClient.from('transactions')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(selectData: mockData),
      );

      // When: expenseTypeFilter=fixed
      final result = await repository.getPaymentMethodTopTransactions(
        ledgerId: ledgerId,
        year: year,
        month: month,
        type: type,
        paymentMethodId: paymentMethodId,
        paymentMethodName: '국민카드',
        canAutoSave: false,
        expenseTypeFilter: ExpenseTypeFilter.fixed,
      );

      // Then: 고정비 거래 반환
      expect(result.items.length, 1);
      expect(result.items[0].title, '월세');
      expect(result.items[0].amount, 500000);
    });

    test('expenseTypeFilter.variable 필터가 적용된다', () async {
      // Given: 변동비 거래
      const paymentMethodId = 'pm-uuid-789';
      final mockData = [
        {
          'id': 'tx-1',
          'title': '카페',
          'amount': 8000,
          'date': '2026-02-15',
          'user_id': 'user-1',
          'payment_method_id': paymentMethodId,
          'profiles': {'display_name': '홍길동', 'color': '#A8D8EA'},
          'payment_methods': {'name': '토스카드', 'can_auto_save': false},
        },
      ];

      when(() => mockClient.from('transactions')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(selectData: mockData),
      );

      // When: expenseTypeFilter=variable
      final result = await repository.getPaymentMethodTopTransactions(
        ledgerId: ledgerId,
        year: year,
        month: month,
        type: type,
        paymentMethodId: paymentMethodId,
        paymentMethodName: '토스카드',
        canAutoSave: false,
        expenseTypeFilter: ExpenseTypeFilter.variable,
      );

      // Then: 변동비 거래 반환
      expect(result.items.length, 1);
      expect(result.items[0].title, '카페');
    });

    test('expenseTypeFilter.all 필터가 적용되면 모든 거래를 반환한다', () async {
      // Given: 고정비 + 변동비 거래 모두
      const paymentMethodId = 'pm-uuid-all';
      final mockData = [
        {
          'id': 'tx-1',
          'title': '고정비 거래',
          'amount': 100000,
          'date': '2026-02-01',
          'user_id': 'user-1',
          'payment_method_id': paymentMethodId,
          'profiles': {'display_name': '홍길동', 'color': '#A8D8EA'},
          'payment_methods': {'name': '하나카드', 'can_auto_save': false},
        },
        {
          'id': 'tx-2',
          'title': '변동비 거래',
          'amount': 50000,
          'date': '2026-02-10',
          'user_id': 'user-1',
          'payment_method_id': paymentMethodId,
          'profiles': {'display_name': '홍길동', 'color': '#A8D8EA'},
          'payment_methods': {'name': '하나카드', 'can_auto_save': false},
        },
      ];

      when(() => mockClient.from('transactions')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(selectData: mockData),
      );

      // When: expenseTypeFilter=all
      final result = await repository.getPaymentMethodTopTransactions(
        ledgerId: ledgerId,
        year: year,
        month: month,
        type: type,
        paymentMethodId: paymentMethodId,
        paymentMethodName: '하나카드',
        canAutoSave: false,
        expenseTypeFilter: ExpenseTypeFilter.all,
      );

      // Then: 모든 거래 반환
      expect(result.items.length, 2);
      expect(result.totalAmount, 150000);
    });

    test('거래가 없으면 빈 결과를 반환한다', () async {
      // Given: 빈 데이터
      const paymentMethodId = 'pm-empty';

      when(() => mockClient.from('transactions')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(selectData: []),
      );

      // When
      final result = await repository.getPaymentMethodTopTransactions(
        ledgerId: ledgerId,
        year: year,
        month: month,
        type: type,
        paymentMethodId: paymentMethodId,
        paymentMethodName: '미사용 카드',
        canAutoSave: false,
      );

      // Then: 빈 결과
      expect(result.items, isEmpty);
      expect(result.totalAmount, 0);
    });

    test('퍼센티지가 총액 대비 올바르게 계산된다', () async {
      // Given: 총액 100,000원 중 각 거래 비율
      const paymentMethodId = 'pm-pct';
      final mockData = [
        {
          'id': 'tx-1',
          'title': '거래A',
          'amount': 75000,
          'date': '2026-02-10',
          'user_id': 'user-1',
          'payment_method_id': paymentMethodId,
          'profiles': {'display_name': '홍길동', 'color': '#A8D8EA'},
          'payment_methods': {'name': '삼성카드', 'can_auto_save': false},
        },
        {
          'id': 'tx-2',
          'title': '거래B',
          'amount': 25000,
          'date': '2026-02-11',
          'user_id': 'user-1',
          'payment_method_id': paymentMethodId,
          'profiles': {'display_name': '홍길동', 'color': '#A8D8EA'},
          'payment_methods': {'name': '삼성카드', 'can_auto_save': false},
        },
      ];

      when(() => mockClient.from('transactions')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(selectData: mockData),
      );

      // When
      final result = await repository.getPaymentMethodTopTransactions(
        ledgerId: ledgerId,
        year: year,
        month: month,
        type: type,
        paymentMethodId: paymentMethodId,
        paymentMethodName: '삼성카드',
        canAutoSave: false,
      );

      // Then: 퍼센티지 검증 (75%, 25%)
      expect(result.totalAmount, 100000);
      expect(result.items[0].percentage, closeTo(75.0, 0.1));
      expect(result.items[1].percentage, closeTo(25.0, 0.1));
    });

    test('날짜 포맷이 올바르게 변환된다', () async {
      // Given
      const paymentMethodId = 'pm-date';
      final mockData = [
        {
          'id': 'tx-1',
          'title': '금요일 결제',
          'amount': 30000,
          'date': '2026-02-20',
          'user_id': 'user-1',
          'payment_method_id': paymentMethodId,
          'profiles': {'display_name': '홍길동', 'color': '#A8D8EA'},
          'payment_methods': {'name': '롯데카드', 'can_auto_save': false},
        },
      ];

      when(() => mockClient.from('transactions')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(selectData: mockData),
      );

      // When
      final result = await repository.getPaymentMethodTopTransactions(
        ledgerId: ledgerId,
        year: year,
        month: month,
        type: type,
        paymentMethodId: paymentMethodId,
        paymentMethodName: '롯데카드',
        canAutoSave: false,
      );

      // Then: 2026-02-20은 금요일
      expect(result.items[0].date, '2월 20일 (금)');
    });

    test('limit 파라미터만큼만 거래를 반환한다', () async {
      // Given: 4개 거래가 있지만 limit=2
      const paymentMethodId = 'pm-limit';
      final mockData = [
        {
          'id': 'tx-1',
          'title': '거래1',
          'amount': 40000,
          'date': '2026-02-10',
          'user_id': 'user-1',
          'payment_method_id': paymentMethodId,
          'profiles': {'display_name': '홍길동', 'color': '#A8D8EA'},
          'payment_methods': {'name': '현대카드', 'can_auto_save': false},
        },
        {
          'id': 'tx-2',
          'title': '거래2',
          'amount': 30000,
          'date': '2026-02-11',
          'user_id': 'user-1',
          'payment_method_id': paymentMethodId,
          'profiles': {'display_name': '홍길동', 'color': '#A8D8EA'},
          'payment_methods': {'name': '현대카드', 'can_auto_save': false},
        },
        {
          'id': 'tx-3',
          'title': '거래3',
          'amount': 20000,
          'date': '2026-02-12',
          'user_id': 'user-1',
          'payment_method_id': paymentMethodId,
          'profiles': {'display_name': '홍길동', 'color': '#A8D8EA'},
          'payment_methods': {'name': '현대카드', 'can_auto_save': false},
        },
      ];

      when(() => mockClient.from('transactions')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(selectData: mockData),
      );

      // When: limit=2
      final result = await repository.getPaymentMethodTopTransactions(
        ledgerId: ledgerId,
        year: year,
        month: month,
        type: type,
        paymentMethodId: paymentMethodId,
        paymentMethodName: '현대카드',
        canAutoSave: false,
        limit: 2,
      );

      // Then: 2개만 반환, 전체 totalAmount는 3개 합계
      expect(result.items.length, 2);
      expect(result.totalAmount, 90000); // 전체 합계
      expect(result.items[0].title, '거래1');
      expect(result.items[1].title, '거래2');
    });

    test('사용자 정보가 null이면 기본값이 사용된다', () async {
      // Given: profiles가 null
      const paymentMethodId = 'pm-null-profile';
      final mockData = [
        {
          'id': 'tx-1',
          'title': null,
          'amount': null,
          'date': '2026-02-10',
          'user_id': 'user-1',
          'payment_method_id': paymentMethodId,
          'profiles': null,
          'payment_methods': {'name': '우리카드', 'can_auto_save': false},
        },
      ];

      when(() => mockClient.from('transactions')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(selectData: mockData),
      );

      // When
      final result = await repository.getPaymentMethodTopTransactions(
        ledgerId: ledgerId,
        year: year,
        month: month,
        type: type,
        paymentMethodId: paymentMethodId,
        paymentMethodName: '우리카드',
        canAutoSave: false,
      );

      // Then: null일 때 기본값 사용
      expect(result.items.length, 1);
      expect(result.items[0].title, ''); // null이면 빈 문자열
      expect(result.items[0].amount, 0); // null이면 0
      expect(result.items[0].userName, ''); // null이면 빈 문자열
      expect(result.items[0].userColor, '#A8D8EA'); // 기본 색상
    });
  });
}
