import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_household_account/features/ledger/domain/entities/ledger.dart';
import 'package:shared_household_account/features/ledger/presentation/providers/ledger_provider.dart';
import 'package:shared_household_account/features/share/presentation/providers/share_provider.dart';
import 'package:shared_household_account/features/statistics/data/repositories/statistics_repository.dart';
import 'package:shared_household_account/features/statistics/domain/entities/statistics_entities.dart';
import 'package:shared_household_account/features/statistics/presentation/providers/statistics_provider.dart';

import '../../../../helpers/mock_repositories.dart';
import '../../../../helpers/test_helpers.dart';

void main() {
  late MockStatisticsRepository mockRepository;

  setUp(() {
    mockRepository = MockStatisticsRepository();
    registerFallbackValue(ExpenseTypeFilter.all);
    registerFallbackValue(DateTime.now());
  });

  // ignore: unused_element
  LedgerMember _makeMember(String userId, {String? displayName, String? color}) {
    return LedgerMember(
      id: 'member-$userId',
      ledgerId: 'ledger-1',
      userId: userId,
      role: 'member',
      joinedAt: DateTime(2026, 1, 1),
      displayName: displayName,
      color: color,
    );
  }

  group('SharedStatisticsState 모델 테스트', () {
    test('기본 생성자로 생성 시 overlay 모드로 초기화된다', () {
      // Given & When
      const state = SharedStatisticsState();

      // Then
      expect(state.mode, SharedStatisticsMode.overlay);
      expect(state.selectedUserId, isNull);
    });

    test('combined 모드로 생성할 수 있다', () {
      // Given & When
      const state = SharedStatisticsState(mode: SharedStatisticsMode.combined);

      // Then
      expect(state.mode, SharedStatisticsMode.combined);
    });

    test('singleUser 모드로 생성하면 selectedUserId가 설정된다', () {
      // Given & When
      const state = SharedStatisticsState(
        mode: SharedStatisticsMode.singleUser,
        selectedUserId: 'user-123',
      );

      // Then
      expect(state.mode, SharedStatisticsMode.singleUser);
      expect(state.selectedUserId, 'user-123');
    });

    test('copyWith로 mode만 변경할 수 있다', () {
      // Given
      const original = SharedStatisticsState(
        mode: SharedStatisticsMode.overlay,
        selectedUserId: 'user-1',
      );

      // When
      final updated = original.copyWith(mode: SharedStatisticsMode.combined);

      // Then
      expect(updated.mode, SharedStatisticsMode.combined);
      expect(updated.selectedUserId, isNull); // selectedUserId는 null로 리셋됨
    });

    test('copyWith로 selectedUserId를 변경할 수 있다', () {
      // Given
      const original = SharedStatisticsState(
        mode: SharedStatisticsMode.singleUser,
        selectedUserId: 'user-1',
      );

      // When
      final updated = original.copyWith(selectedUserId: 'user-2');

      // Then
      expect(updated.selectedUserId, 'user-2');
    });
  });

  group('statisticsTabIndexProvider 테스트', () {
    test('초기 탭 인덱스는 0이다', () {
      // Given
      final container = createContainer();

      // When
      final tabIndex = container.read(statisticsTabIndexProvider);

      // Then
      expect(tabIndex, 0);

      container.dispose();
    });

    test('탭 인덱스를 변경할 수 있다', () {
      // Given
      final container = createContainer();

      // When
      container.read(statisticsTabIndexProvider.notifier).state = 2;

      // Then
      expect(container.read(statisticsTabIndexProvider), 2);

      container.dispose();
    });
  });

  group('selectedStatisticsTypeProvider 테스트', () {
    test('초기 타입은 expense이다', () {
      // Given
      final container = createContainer();

      // When
      final type = container.read(selectedStatisticsTypeProvider);

      // Then
      expect(type, 'expense');

      container.dispose();
    });

    test('income 타입으로 변경할 수 있다', () {
      // Given
      final container = createContainer();

      // When
      container.read(selectedStatisticsTypeProvider.notifier).state = 'income';

      // Then
      expect(container.read(selectedStatisticsTypeProvider), 'income');

      container.dispose();
    });

    test('asset 타입으로 변경할 수 있다', () {
      // Given
      final container = createContainer();

      // When
      container.read(selectedStatisticsTypeProvider.notifier).state = 'asset';

      // Then
      expect(container.read(selectedStatisticsTypeProvider), 'asset');

      container.dispose();
    });
  });

  group('selectedExpenseTypeFilterProvider 테스트', () {
    test('초기 필터는 all이다', () {
      // Given
      final container = createContainer();

      // When
      final filter = container.read(selectedExpenseTypeFilterProvider);

      // Then
      expect(filter, ExpenseTypeFilter.all);

      container.dispose();
    });

    test('fixed 필터로 변경할 수 있다', () {
      // Given
      final container = createContainer();

      // When
      container.read(selectedExpenseTypeFilterProvider.notifier).state =
          ExpenseTypeFilter.fixed;

      // Then
      expect(
        container.read(selectedExpenseTypeFilterProvider),
        ExpenseTypeFilter.fixed,
      );

      container.dispose();
    });

    test('variable 필터로 변경할 수 있다', () {
      // Given
      final container = createContainer();

      // When
      container.read(selectedExpenseTypeFilterProvider.notifier).state =
          ExpenseTypeFilter.variable;

      // Then
      expect(
        container.read(selectedExpenseTypeFilterProvider),
        ExpenseTypeFilter.variable,
      );

      container.dispose();
    });
  });

  group('trendPeriodProvider 테스트', () {
    test('초기 기간은 monthly이다', () {
      // Given
      final container = createContainer();

      // When
      final period = container.read(trendPeriodProvider);

      // Then
      expect(period, TrendPeriod.monthly);

      container.dispose();
    });

    test('yearly 기간으로 변경할 수 있다', () {
      // Given
      final container = createContainer();

      // When
      container.read(trendPeriodProvider.notifier).state = TrendPeriod.yearly;

      // Then
      expect(container.read(trendPeriodProvider), TrendPeriod.yearly);

      container.dispose();
    });
  });

  group('statisticsSelectedDateProvider 테스트', () {
    test('초기 날짜는 현재 날짜이다', () {
      // Given
      final container = createContainer();
      final now = DateTime.now();

      // When
      final date = container.read(statisticsSelectedDateProvider);

      // Then
      expect(date.year, now.year);
      expect(date.month, now.month);

      container.dispose();
    });

    test('날짜를 변경할 수 있다', () {
      // Given
      final container = createContainer();
      final newDate = DateTime(2026, 3, 1);

      // When
      container.read(statisticsSelectedDateProvider.notifier).state = newDate;

      // Then
      final date = container.read(statisticsSelectedDateProvider);
      expect(date.year, 2026);
      expect(date.month, 3);

      container.dispose();
    });
  });

  group('categoryExpenseStatisticsProvider 테스트', () {
    test('ledgerId가 null이면 빈 리스트를 반환한다', () async {
      // Given
      final container = createContainer(
        overrides: [
          statisticsRepositoryProvider.overrideWith((ref) => mockRepository),
          selectedLedgerIdProvider.overrideWith((ref) => null),
        ],
      );

      // When
      final result = await container.read(categoryExpenseStatisticsProvider.future);

      // Then
      expect(result, isEmpty);

      container.dispose();
    });

    test('ledgerId가 있으면 repository에서 데이터를 가져온다', () async {
      // Given
      final mockData = [
        const CategoryStatistics(
          categoryId: 'cat-1',
          categoryName: '식비',
          categoryIcon: 'restaurant',
          categoryColor: '#FF5733',
          amount: 100000,
        ),
      ];

      when(() => mockRepository.getCategoryStatistics(
            ledgerId: any(named: 'ledgerId'),
            year: any(named: 'year'),
            month: any(named: 'month'),
            type: any(named: 'type'),
            expenseTypeFilter: any(named: 'expenseTypeFilter'),
          )).thenAnswer((_) async => mockData);

      final container = createContainer(
        overrides: [
          statisticsRepositoryProvider.overrideWith((ref) => mockRepository),
          selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
          statisticsSelectedDateProvider.overrideWith((ref) => DateTime(2026, 2, 1)),
        ],
      );

      // When
      final result = await container.read(categoryExpenseStatisticsProvider.future);

      // Then
      expect(result.length, 1);
      expect(result[0].categoryName, '식비');

      container.dispose();
    });
  });

  group('totalStatisticsProvider 테스트', () {
    test('지출과 수입 합계를 올바르게 계산한다', () async {
      // Given
      final expenseData = [
        const CategoryStatistics(
          categoryId: 'cat-1',
          categoryName: '식비',
          categoryIcon: '',
          categoryColor: '#FF5733',
          amount: 100000,
        ),
        const CategoryStatistics(
          categoryId: 'cat-2',
          categoryName: '교통비',
          categoryIcon: '',
          categoryColor: '#33C1FF',
          amount: 50000,
        ),
      ];
      final incomeData = [
        const CategoryStatistics(
          categoryId: 'cat-3',
          categoryName: '급여',
          categoryIcon: '',
          categoryColor: '#4CAF50',
          amount: 3000000,
        ),
      ];

      when(() => mockRepository.getCategoryStatistics(
            ledgerId: any(named: 'ledgerId'),
            year: any(named: 'year'),
            month: any(named: 'month'),
            type: 'expense',
            expenseTypeFilter: any(named: 'expenseTypeFilter'),
          )).thenAnswer((_) async => expenseData);

      when(() => mockRepository.getCategoryStatistics(
            ledgerId: any(named: 'ledgerId'),
            year: any(named: 'year'),
            month: any(named: 'month'),
            type: 'income',
            expenseTypeFilter: any(named: 'expenseTypeFilter'),
          )).thenAnswer((_) async => incomeData);

      when(() => mockRepository.getCategoryStatistics(
            ledgerId: any(named: 'ledgerId'),
            year: any(named: 'year'),
            month: any(named: 'month'),
            type: 'asset',
            expenseTypeFilter: any(named: 'expenseTypeFilter'),
          )).thenAnswer((_) async => []);

      final container = createContainer(
        overrides: [
          statisticsRepositoryProvider.overrideWith((ref) => mockRepository),
          selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
          statisticsSelectedDateProvider.overrideWith((ref) => DateTime(2026, 2, 1)),
          selectedExpenseTypeFilterProvider.overrideWith((ref) => ExpenseTypeFilter.all),
        ],
      );

      // 비동기 데이터 로딩 대기
      await container.read(categoryExpenseStatisticsProvider.future);
      await container.read(categoryIncomeStatisticsProvider.future);

      // When
      final totals = container.read(totalStatisticsProvider);

      // Then
      expect(totals['expense'], 150000);
      expect(totals['income'], 3000000);
      expect(totals['balance'], 2850000);

      container.dispose();
    });
  });

  group('categoryDetailStateProvider 테스트', () {
    test('초기 상태는 isOpen=false이다', () {
      // Given
      final container = createContainer();

      // When
      final state = container.read(categoryDetailStateProvider);

      // Then
      expect(state.isOpen, false);
      expect(state.categoryId, '');

      container.dispose();
    });

    test('상태를 업데이트할 수 있다', () {
      // Given
      final container = createContainer();

      // When
      container.read(categoryDetailStateProvider.notifier).state =
          const CategoryDetailState(
            isOpen: true,
            categoryId: 'cat-1',
            categoryName: '식비',
            categoryColor: '#FF5722',
            categoryIcon: 'restaurant',
            categoryPercentage: 35.0,
            type: 'expense',
            totalAmount: 100000,
          );

      // Then
      final state = container.read(categoryDetailStateProvider);
      expect(state.isOpen, true);
      expect(state.categoryId, 'cat-1');
      expect(state.categoryName, '식비');

      container.dispose();
    });
  });

  group('paymentMethodDetailStateProvider 테스트', () {
    test('초기 상태는 isOpen=false이다', () {
      // Given
      final container = createContainer();

      // When
      final state = container.read(paymentMethodDetailStateProvider);

      // Then
      expect(state.isOpen, false);
      expect(state.paymentMethodId, '');

      container.dispose();
    });

    test('상태를 업데이트할 수 있다', () {
      // Given
      final container = createContainer();

      // When
      container.read(paymentMethodDetailStateProvider.notifier).state =
          const PaymentMethodDetailState(
            isOpen: true,
            paymentMethodId: 'pm-1',
            paymentMethodName: '신한카드',
            paymentMethodIcon: 'credit_card',
            paymentMethodColor: '#4A90E2',
            canAutoSave: false,
            percentage: 40.0,
            totalAmount: 200000,
          );

      // Then
      final state = container.read(paymentMethodDetailStateProvider);
      expect(state.isOpen, true);
      expect(state.paymentMethodId, 'pm-1');
      expect(state.paymentMethodName, '신한카드');

      container.dispose();
    });
  });

  group('categoryTopTransactionsProvider 테스트', () {
    test('isOpen=false이면 빈 결과를 반환한다', () async {
      // Given
      final container = createContainer(
        overrides: [
          statisticsRepositoryProvider.overrideWith((ref) => mockRepository),
          selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
          statisticsSelectedDateProvider.overrideWith((ref) => DateTime(2026, 2, 1)),
          categoryDetailStateProvider.overrideWith(
            (ref) => const CategoryDetailState(isOpen: false),
          ),
          selectedExpenseTypeFilterProvider.overrideWith(
            (ref) => ExpenseTypeFilter.all,
          ),
        ],
      );

      // When
      final result = await container.read(categoryTopTransactionsProvider.future);

      // Then
      expect(result.items, isEmpty);
      expect(result.totalAmount, 0);

      container.dispose();
    });

    test('categoryId가 비어있으면 빈 결과를 반환한다', () async {
      // Given
      final container = createContainer(
        overrides: [
          statisticsRepositoryProvider.overrideWith((ref) => mockRepository),
          selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
          statisticsSelectedDateProvider.overrideWith((ref) => DateTime(2026, 2, 1)),
          categoryDetailStateProvider.overrideWith(
            (ref) => const CategoryDetailState(isOpen: true, categoryId: ''),
          ),
          selectedExpenseTypeFilterProvider.overrideWith(
            (ref) => ExpenseTypeFilter.all,
          ),
        ],
      );

      // When
      final result = await container.read(categoryTopTransactionsProvider.future);

      // Then
      expect(result.items, isEmpty);
      expect(result.totalAmount, 0);

      container.dispose();
    });
  });

  group('PaymentMethodDetailState 모델 테스트', () {
    test('기본 생성자로 생성 시 모든 속성이 기본값으로 초기화된다', () {
      // Given & When
      const state = PaymentMethodDetailState();

      // Then
      expect(state.isOpen, false);
      expect(state.paymentMethodId, '');
      expect(state.paymentMethodName, '');
      expect(state.paymentMethodIcon, '');
      expect(state.paymentMethodColor, '');
      expect(state.canAutoSave, false);
      expect(state.percentage, 0);
      expect(state.totalAmount, 0);
      expect(state.selectedUserId, isNull);
      expect(state.isFixedExpenseFilter, false);
    });

    test('named 파라미터로 생성 시 지정된 값이 저장된다', () {
      // Given & When
      const state = PaymentMethodDetailState(
        isOpen: true,
        paymentMethodId: 'pm-1',
        paymentMethodName: '신한카드',
        paymentMethodIcon: 'credit_card',
        paymentMethodColor: '#4A90E2',
        canAutoSave: true,
        percentage: 45.0,
        totalAmount: 300000,
        selectedUserId: 'user-1',
        isFixedExpenseFilter: true,
      );

      // Then
      expect(state.isOpen, true);
      expect(state.paymentMethodId, 'pm-1');
      expect(state.paymentMethodName, '신한카드');
      expect(state.paymentMethodIcon, 'credit_card');
      expect(state.paymentMethodColor, '#4A90E2');
      expect(state.canAutoSave, true);
      expect(state.percentage, 45.0);
      expect(state.totalAmount, 300000);
      expect(state.selectedUserId, 'user-1');
      expect(state.isFixedExpenseFilter, true);
    });
  });

  group('sharedStatisticsStateProvider 테스트', () {
    test('초기 모드는 overlay이다', () {
      // Given
      final container = createContainer();

      // When
      final state = container.read(sharedStatisticsStateProvider);

      // Then
      expect(state.mode, SharedStatisticsMode.overlay);

      container.dispose();
    });

    test('combined 모드로 변경할 수 있다', () {
      // Given
      final container = createContainer();

      // When
      container.read(sharedStatisticsStateProvider.notifier).state =
          const SharedStatisticsState(mode: SharedStatisticsMode.combined);

      // Then
      final state = container.read(sharedStatisticsStateProvider);
      expect(state.mode, SharedStatisticsMode.combined);

      container.dispose();
    });
  });

  group('monthlyTrendWithAverageProvider 테스트', () {
    test('ledgerId가 null이면 빈 TrendStatisticsData를 반환한다', () async {
      // Given
      final container = createContainer(
        overrides: [
          statisticsRepositoryProvider.overrideWith((ref) => mockRepository),
          selectedLedgerIdProvider.overrideWith((ref) => null),
          statisticsSelectedDateProvider.overrideWith((ref) => DateTime(2026, 2, 1)),
          selectedStatisticsTypeProvider.overrideWith((ref) => 'expense'),
          selectedExpenseTypeFilterProvider.overrideWith((ref) => ExpenseTypeFilter.all),
        ],
      );

      // When
      final result = await container.read(monthlyTrendWithAverageProvider.future);

      // Then
      expect(result.data, isEmpty);
      expect(result.averageIncome, 0);
      expect(result.averageExpense, 0);

      container.dispose();
    });

    test('ledgerId가 있으면 repository에서 데이터를 가져온다', () async {
      // Given
      final mockData = TrendStatisticsData(
        data: [
          MonthlyStatistics(
            year: 2026,
            month: 2,
            income: 3000000,
            expense: 150000,
            saving: 0,
          ),
        ],
        averageIncome: 3000000,
        averageExpense: 150000,
        averageAsset: 0,
      );

      when(() => mockRepository.getMonthlyTrendWithAverage(
            ledgerId: any(named: 'ledgerId'),
            baseDate: any(named: 'baseDate'),
            months: any(named: 'months'),
            expenseTypeFilter: any(named: 'expenseTypeFilter'),
          )).thenAnswer((_) async => mockData);

      final container = createContainer(
        overrides: [
          statisticsRepositoryProvider.overrideWith((ref) => mockRepository),
          selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
          statisticsSelectedDateProvider.overrideWith((ref) => DateTime(2026, 2, 1)),
          selectedStatisticsTypeProvider.overrideWith((ref) => 'expense'),
          selectedExpenseTypeFilterProvider.overrideWith((ref) => ExpenseTypeFilter.all),
        ],
      );

      // When
      final result = await container.read(monthlyTrendWithAverageProvider.future);

      // Then
      expect(result.data.length, 1);
      expect(result.averageExpense, 150000);

      container.dispose();
    });
  });

  group('yearlyTrendWithAverageProvider 테스트', () {
    test('ledgerId가 null이면 빈 TrendStatisticsData를 반환한다', () async {
      // Given
      final container = createContainer(
        overrides: [
          statisticsRepositoryProvider.overrideWith((ref) => mockRepository),
          selectedLedgerIdProvider.overrideWith((ref) => null),
          statisticsSelectedDateProvider.overrideWith((ref) => DateTime(2026, 2, 1)),
          selectedStatisticsTypeProvider.overrideWith((ref) => 'expense'),
          selectedExpenseTypeFilterProvider.overrideWith((ref) => ExpenseTypeFilter.all),
        ],
      );

      // When
      final result = await container.read(yearlyTrendWithAverageProvider.future);

      // Then
      expect(result.data, isEmpty);
      expect(result.averageIncome, 0);
      expect(result.averageExpense, 0);

      container.dispose();
    });

    test('수입 타입에서는 expenseTypeFilter를 적용하지 않는다', () async {
      // Given
      final mockData = const TrendStatisticsData(
        data: [],
        averageIncome: 0,
        averageExpense: 0,
        averageAsset: 0,
      );

      when(() => mockRepository.getYearlyTrendWithAverage(
            ledgerId: any(named: 'ledgerId'),
            baseDate: any(named: 'baseDate'),
            years: any(named: 'years'),
            expenseTypeFilter: any(named: 'expenseTypeFilter'),
          )).thenAnswer((_) async => mockData);

      final container = createContainer(
        overrides: [
          statisticsRepositoryProvider.overrideWith((ref) => mockRepository),
          selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
          statisticsSelectedDateProvider.overrideWith((ref) => DateTime(2026, 2, 1)),
          selectedStatisticsTypeProvider.overrideWith((ref) => 'income'),
          selectedExpenseTypeFilterProvider.overrideWith((ref) => ExpenseTypeFilter.fixed),
        ],
      );

      // When
      await container.read(yearlyTrendWithAverageProvider.future);

      // Then - income 타입에서 expenseTypeFilter=null로 호출되어야 함
      verify(() => mockRepository.getYearlyTrendWithAverage(
            ledgerId: any(named: 'ledgerId'),
            baseDate: any(named: 'baseDate'),
            years: any(named: 'years'),
            expenseTypeFilter: null,
          )).called(1);

      container.dispose();
    });
  });

  group('categoryStatisticsProvider 타입별 데이터 로딩 테스트', () {
    test('expense 타입이면 categoryExpenseStatisticsProvider 데이터를 반환한다', () async {
      // Given
      final expenseData = [
        const CategoryStatistics(
          categoryId: 'cat-1',
          categoryName: '식비',
          categoryIcon: '',
          categoryColor: '#FF5733',
          amount: 100000,
        ),
      ];

      when(() => mockRepository.getCategoryStatistics(
            ledgerId: any(named: 'ledgerId'),
            year: any(named: 'year'),
            month: any(named: 'month'),
            type: any(named: 'type'),
            expenseTypeFilter: any(named: 'expenseTypeFilter'),
          )).thenAnswer((_) async => expenseData);

      final container = createContainer(
        overrides: [
          statisticsRepositoryProvider.overrideWith((ref) => mockRepository),
          selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
          statisticsSelectedDateProvider.overrideWith((ref) => DateTime(2026, 2, 1)),
          selectedStatisticsTypeProvider.overrideWith((ref) => 'expense'),
          selectedExpenseTypeFilterProvider.overrideWith((ref) => ExpenseTypeFilter.all),
        ],
      );

      // When
      final result = await container.read(categoryStatisticsProvider.future);

      // Then
      expect(result.length, 1);
      expect(result[0].categoryName, '식비');

      container.dispose();
    });

    test('income 타입이면 categoryIncomeStatisticsProvider 데이터를 반환한다', () async {
      // Given
      final incomeData = [
        const CategoryStatistics(
          categoryId: 'cat-3',
          categoryName: '급여',
          categoryIcon: '',
          categoryColor: '#4CAF50',
          amount: 3000000,
        ),
      ];

      when(() => mockRepository.getCategoryStatistics(
            ledgerId: any(named: 'ledgerId'),
            year: any(named: 'year'),
            month: any(named: 'month'),
            type: any(named: 'type'),
            expenseTypeFilter: any(named: 'expenseTypeFilter'),
          )).thenAnswer((_) async => incomeData);

      final container = createContainer(
        overrides: [
          statisticsRepositoryProvider.overrideWith((ref) => mockRepository),
          selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
          statisticsSelectedDateProvider.overrideWith((ref) => DateTime(2026, 2, 1)),
          selectedStatisticsTypeProvider.overrideWith((ref) => 'income'),
          selectedExpenseTypeFilterProvider.overrideWith((ref) => ExpenseTypeFilter.all),
        ],
      );

      // When
      final result = await container.read(categoryStatisticsProvider.future);

      // Then
      expect(result.length, 1);
      expect(result[0].categoryName, '급여');

      container.dispose();
    });

    test('asset 타입이면 categoryAssetStatisticsProvider 데이터를 반환한다', () async {
      // Given
      final assetData = [
        const CategoryStatistics(
          categoryId: 'cat-4',
          categoryName: '예금',
          categoryIcon: '',
          categoryColor: '#2196F3',
          amount: 1000000,
        ),
      ];

      when(() => mockRepository.getCategoryStatistics(
            ledgerId: any(named: 'ledgerId'),
            year: any(named: 'year'),
            month: any(named: 'month'),
            type: any(named: 'type'),
            expenseTypeFilter: any(named: 'expenseTypeFilter'),
          )).thenAnswer((_) async => assetData);

      final container = createContainer(
        overrides: [
          statisticsRepositoryProvider.overrideWith((ref) => mockRepository),
          selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
          statisticsSelectedDateProvider.overrideWith((ref) => DateTime(2026, 2, 1)),
          selectedStatisticsTypeProvider.overrideWith((ref) => 'asset'),
          selectedExpenseTypeFilterProvider.overrideWith((ref) => ExpenseTypeFilter.all),
        ],
      );

      // When
      final result = await container.read(categoryStatisticsProvider.future);

      // Then
      expect(result.length, 1);
      expect(result[0].categoryName, '예금');

      container.dispose();
    });
  });

  group('categoryIncomeStatisticsProvider 테스트', () {
    test('ledgerId가 null이면 빈 리스트를 반환한다', () async {
      // Given
      final container = createContainer(
        overrides: [
          statisticsRepositoryProvider.overrideWith((ref) => mockRepository),
          selectedLedgerIdProvider.overrideWith((ref) => null),
          statisticsSelectedDateProvider.overrideWith((ref) => DateTime(2026, 2, 1)),
        ],
      );

      // When
      final result = await container.read(categoryIncomeStatisticsProvider.future);

      // Then
      expect(result, isEmpty);

      container.dispose();
    });

    test('ledgerId가 있으면 수입 통계를 가져온다', () async {
      // Given
      final incomeData = [
        const CategoryStatistics(
          categoryId: 'cat-1',
          categoryName: '급여',
          categoryIcon: '',
          categoryColor: '#4CAF50',
          amount: 3000000,
        ),
      ];

      when(() => mockRepository.getCategoryStatistics(
            ledgerId: any(named: 'ledgerId'),
            year: any(named: 'year'),
            month: any(named: 'month'),
            type: any(named: 'type'),
            expenseTypeFilter: any(named: 'expenseTypeFilter'),
          )).thenAnswer((_) async => incomeData);

      final container = createContainer(
        overrides: [
          statisticsRepositoryProvider.overrideWith((ref) => mockRepository),
          selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
          statisticsSelectedDateProvider.overrideWith((ref) => DateTime(2026, 2, 1)),
        ],
      );

      // When
      final result = await container.read(categoryIncomeStatisticsProvider.future);

      // Then
      expect(result.length, 1);
      expect(result[0].categoryName, '급여');

      container.dispose();
    });
  });

  group('categoryAssetStatisticsProvider 테스트', () {
    test('ledgerId가 null이면 빈 리스트를 반환한다', () async {
      // Given
      final container = createContainer(
        overrides: [
          statisticsRepositoryProvider.overrideWith((ref) => mockRepository),
          selectedLedgerIdProvider.overrideWith((ref) => null),
          statisticsSelectedDateProvider.overrideWith((ref) => DateTime(2026, 2, 1)),
        ],
      );

      // When
      final result = await container.read(categoryAssetStatisticsProvider.future);

      // Then
      expect(result, isEmpty);

      container.dispose();
    });

    test('ledgerId가 있으면 자산 통계를 가져온다', () async {
      // Given
      final assetData = [
        const CategoryStatistics(
          categoryId: 'cat-1',
          categoryName: '예금',
          categoryIcon: '',
          categoryColor: '#2196F3',
          amount: 5000000,
        ),
      ];

      when(() => mockRepository.getCategoryStatistics(
            ledgerId: any(named: 'ledgerId'),
            year: any(named: 'year'),
            month: any(named: 'month'),
            type: any(named: 'type'),
            expenseTypeFilter: any(named: 'expenseTypeFilter'),
          )).thenAnswer((_) async => assetData);

      final container = createContainer(
        overrides: [
          statisticsRepositoryProvider.overrideWith((ref) => mockRepository),
          selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
          statisticsSelectedDateProvider.overrideWith((ref) => DateTime(2026, 2, 1)),
        ],
      );

      // When
      final result = await container.read(categoryAssetStatisticsProvider.future);

      // Then
      expect(result.length, 1);
      expect(result[0].categoryName, '예금');

      container.dispose();
    });
  });

  group('monthComparisonProvider 테스트', () {
    test('ledgerId가 null이면 empty MonthComparisonData를 반환한다', () async {
      // Given
      final container = createContainer(
        overrides: [
          statisticsRepositoryProvider.overrideWith((ref) => mockRepository),
          selectedLedgerIdProvider.overrideWith((ref) => null),
          statisticsSelectedDateProvider.overrideWith((ref) => DateTime(2026, 2, 1)),
          selectedStatisticsTypeProvider.overrideWith((ref) => 'expense'),
          selectedExpenseTypeFilterProvider.overrideWith((ref) => ExpenseTypeFilter.all),
        ],
      );

      // When
      final result = await container.read(monthComparisonProvider.future);

      // Then
      expect(result.currentTotal, 0);
      expect(result.previousTotal, 0);

      container.dispose();
    });

    test('expense 타입이면 expenseTypeFilter가 적용된다', () async {
      // Given
      when(() => mockRepository.getMonthComparison(
            ledgerId: any(named: 'ledgerId'),
            year: any(named: 'year'),
            month: any(named: 'month'),
            type: any(named: 'type'),
            expenseTypeFilter: any(named: 'expenseTypeFilter'),
          )).thenAnswer((_) async => const MonthComparisonData(
            currentTotal: 100000,
            previousTotal: 80000,
            difference: 20000,
            percentageChange: 25.0,
          ));

      final container = createContainer(
        overrides: [
          statisticsRepositoryProvider.overrideWith((ref) => mockRepository),
          selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
          statisticsSelectedDateProvider.overrideWith((ref) => DateTime(2026, 2, 1)),
          selectedStatisticsTypeProvider.overrideWith((ref) => 'expense'),
          selectedExpenseTypeFilterProvider.overrideWith((ref) => ExpenseTypeFilter.fixed),
        ],
      );

      // When
      final result = await container.read(monthComparisonProvider.future);

      // Then
      expect(result.currentTotal, 100000);
      expect(result.previousTotal, 80000);

      container.dispose();
    });

    test('income 타입이면 expenseTypeFilter를 적용하지 않는다', () async {
      // Given
      when(() => mockRepository.getMonthComparison(
            ledgerId: any(named: 'ledgerId'),
            year: any(named: 'year'),
            month: any(named: 'month'),
            type: any(named: 'type'),
            expenseTypeFilter: any(named: 'expenseTypeFilter'),
          )).thenAnswer((_) async => const MonthComparisonData(
            currentTotal: 3000000,
            previousTotal: 2800000,
            difference: 200000,
            percentageChange: 7.1,
          ));

      final container = createContainer(
        overrides: [
          statisticsRepositoryProvider.overrideWith((ref) => mockRepository),
          selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
          statisticsSelectedDateProvider.overrideWith((ref) => DateTime(2026, 2, 1)),
          selectedStatisticsTypeProvider.overrideWith((ref) => 'income'),
          selectedExpenseTypeFilterProvider.overrideWith((ref) => ExpenseTypeFilter.fixed),
        ],
      );

      // When
      await container.read(monthComparisonProvider.future);

      // Then - income 타입에서는 expenseTypeFilter=null로 호출
      verify(() => mockRepository.getMonthComparison(
            ledgerId: any(named: 'ledgerId'),
            year: any(named: 'year'),
            month: any(named: 'month'),
            type: any(named: 'type'),
            expenseTypeFilter: null,
          )).called(1);

      container.dispose();
    });
  });

  group('paymentMethodStatisticsProvider 테스트', () {
    test('ledgerId가 null이면 빈 리스트를 반환한다', () async {
      // Given
      final container = createContainer(
        overrides: [
          statisticsRepositoryProvider.overrideWith((ref) => mockRepository),
          selectedLedgerIdProvider.overrideWith((ref) => null),
          statisticsSelectedDateProvider.overrideWith((ref) => DateTime(2026, 2, 1)),
          selectedPaymentMethodExpenseTypeFilterProvider.overrideWith((ref) => ExpenseTypeFilter.all),
          paymentMethodSharedStatisticsStateProvider.overrideWith(
            (ref) => const SharedStatisticsState(mode: SharedStatisticsMode.combined),
          ),
          currentLedgerMembersProvider.overrideWith((ref) async => []),
        ],
      );

      // When
      final result = await container.read(paymentMethodStatisticsProvider.future);

      // Then
      expect(result, isEmpty);

      container.dispose();
    });

    test('combined 모드에서 userId 없이 데이터를 가져온다', () async {
      // Given
      final pmData = [
        const PaymentMethodStatistics(
          paymentMethodId: 'pm-1',
          paymentMethodName: '신한카드',
          paymentMethodIcon: '💳',
          paymentMethodColor: '#4A90E2',
          amount: 100000,
          percentage: 100.0,
        ),
      ];

      when(() => mockRepository.getPaymentMethodStatistics(
            ledgerId: any(named: 'ledgerId'),
            year: any(named: 'year'),
            month: any(named: 'month'),
            type: any(named: 'type'),
            expenseTypeFilter: any(named: 'expenseTypeFilter'),
            userId: any(named: 'userId'),
          )).thenAnswer((_) async => pmData);

      final container = createContainer(
        overrides: [
          statisticsRepositoryProvider.overrideWith((ref) => mockRepository),
          selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
          statisticsSelectedDateProvider.overrideWith((ref) => DateTime(2026, 2, 1)),
          selectedPaymentMethodExpenseTypeFilterProvider.overrideWith((ref) => ExpenseTypeFilter.all),
          paymentMethodSharedStatisticsStateProvider.overrideWith(
            (ref) => const SharedStatisticsState(mode: SharedStatisticsMode.combined),
          ),
          currentLedgerMembersProvider.overrideWith((ref) async => []),
        ],
      );

      // When
      final result = await container.read(paymentMethodStatisticsProvider.future);

      // Then
      expect(result.length, 1);
      expect(result[0].paymentMethodName, '신한카드');

      container.dispose();
    });

    test('singleUser 모드에서 유효한 userId로 필터링된다', () async {
      // Given
      final member = LedgerMember(
        id: 'member-1',
        ledgerId: 'ledger-1',
        userId: 'user-1',
        role: 'member',
        joinedAt: DateTime(2026, 1, 1),
        displayName: '홍길동',
      );

      final pmData = [
        const PaymentMethodStatistics(
          paymentMethodId: 'pm-1',
          paymentMethodName: '신한카드',
          paymentMethodIcon: '💳',
          paymentMethodColor: '#4A90E2',
          amount: 50000,
          percentage: 100.0,
        ),
      ];

      when(() => mockRepository.getPaymentMethodStatistics(
            ledgerId: any(named: 'ledgerId'),
            year: any(named: 'year'),
            month: any(named: 'month'),
            type: any(named: 'type'),
            expenseTypeFilter: any(named: 'expenseTypeFilter'),
            userId: any(named: 'userId'),
          )).thenAnswer((_) async => pmData);

      final container = createContainer(
        overrides: [
          statisticsRepositoryProvider.overrideWith((ref) => mockRepository),
          selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
          statisticsSelectedDateProvider.overrideWith((ref) => DateTime(2026, 2, 1)),
          selectedPaymentMethodExpenseTypeFilterProvider.overrideWith((ref) => ExpenseTypeFilter.all),
          paymentMethodSharedStatisticsStateProvider.overrideWith(
            (ref) => const SharedStatisticsState(
              mode: SharedStatisticsMode.singleUser,
              selectedUserId: 'user-1',
            ),
          ),
          currentLedgerMembersProvider.overrideWith((ref) async => [member]),
        ],
      );

      // When
      final result = await container.read(paymentMethodStatisticsProvider.future);

      // Then
      expect(result.length, 1);

      container.dispose();
    });

    test('singleUser 모드에서 멤버가 나간 경우 combined로 폴백된다', () async {
      // Given - paymentMethodStatisticsProvider가 내부에서 sharedState를 변경하면
      // provider 재실행 순환이 발생하므로, combined 모드로 직접 오버라이드하여
      // 폴백 후의 결과(userId=null로 결제수단 통계 조회)를 검증한다
      when(() => mockRepository.getPaymentMethodStatistics(
            ledgerId: any(named: 'ledgerId'),
            year: any(named: 'year'),
            month: any(named: 'month'),
            type: any(named: 'type'),
            expenseTypeFilter: any(named: 'expenseTypeFilter'),
            userId: any(named: 'userId'),
          )).thenAnswer((_) async => <PaymentMethodStatistics>[]);

      final container = createContainer(
        overrides: [
          statisticsRepositoryProvider.overrideWith((ref) => mockRepository),
          selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
          statisticsSelectedDateProvider.overrideWith((ref) => DateTime(2026, 2, 1)),
          selectedPaymentMethodExpenseTypeFilterProvider.overrideWith((ref) => ExpenseTypeFilter.all),
          // 폴백 이후 상태(combined)로 직접 오버라이드 - 순환 재실행 방지
          paymentMethodSharedStatisticsStateProvider.overrideWith(
            (ref) => const SharedStatisticsState(
              mode: SharedStatisticsMode.combined,
            ),
          ),
          currentLedgerMembersProvider.overrideWith((ref) async => []),
        ],
      );

      // When - combined 모드이므로 userId=null로 조회
      final result = await container.read(paymentMethodStatisticsProvider.future);

      // Then - 빈 결과 반환
      expect(result, isEmpty);

      container.dispose();
    });
  });

  group('paymentMethodStatisticsByUserProvider 테스트', () {
    test('ledgerId가 null이면 빈 맵을 반환한다', () async {
      // Given
      final container = createContainer(
        overrides: [
          statisticsRepositoryProvider.overrideWith((ref) => mockRepository),
          selectedLedgerIdProvider.overrideWith((ref) => null),
          statisticsSelectedDateProvider.overrideWith((ref) => DateTime(2026, 2, 1)),
          selectedPaymentMethodExpenseTypeFilterProvider.overrideWith((ref) => ExpenseTypeFilter.all),
          currentLedgerMembersProvider.overrideWith((ref) async => []),
        ],
      );

      // When
      final result = await container.read(paymentMethodStatisticsByUserProvider.future);

      // Then
      expect(result, isEmpty);

      container.dispose();
    });

    test('거래가 없는 멤버도 0원으로 포함된다', () async {
      // Given
      final member1 = LedgerMember(
        id: 'member-1',
        ledgerId: 'ledger-1',
        userId: 'user-1',
        role: 'member',
        joinedAt: DateTime(2026, 1, 1),
        displayName: '홍길동',
        color: '#A8D8EA',
      );
      final member2 = LedgerMember(
        id: 'member-2',
        ledgerId: 'ledger-1',
        userId: 'user-2',
        role: 'member',
        joinedAt: DateTime(2026, 1, 1),
        displayName: null, // displayName 없음
        email: 'kim@test.com',
        color: null, // color 없음
      );

      // user-1만 거래가 있고 user-2는 없음
      when(() => mockRepository.getPaymentMethodStatisticsByUser(
            ledgerId: any(named: 'ledgerId'),
            year: any(named: 'year'),
            month: any(named: 'month'),
            type: any(named: 'type'),
            expenseTypeFilter: any(named: 'expenseTypeFilter'),
          )).thenAnswer((_) async => {
            'user-1': UserPaymentMethodStatistics(
              userId: 'user-1',
              userName: '홍길동',
              userColor: '#A8D8EA',
              totalAmount: 50000,
              paymentMethods: {},
            ),
          });

      final container = createContainer(
        overrides: [
          statisticsRepositoryProvider.overrideWith((ref) => mockRepository),
          selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
          statisticsSelectedDateProvider.overrideWith((ref) => DateTime(2026, 2, 1)),
          selectedPaymentMethodExpenseTypeFilterProvider.overrideWith((ref) => ExpenseTypeFilter.all),
          currentLedgerMembersProvider.overrideWith((ref) async => [member1, member2]),
        ],
      );

      // When
      final result = await container.read(paymentMethodStatisticsByUserProvider.future);

      // Then - 두 멤버 모두 포함, user-2는 0원
      expect(result.keys.length, 2);
      expect(result['user-1']!.totalAmount, 50000);
      expect(result['user-2']!.totalAmount, 0);

      container.dispose();
    });
  });

  group('categoryStatisticsByUserProvider 테스트', () {
    test('ledgerId가 null이면 빈 맵을 반환한다', () async {
      // Given
      final container = createContainer(
        overrides: [
          statisticsRepositoryProvider.overrideWith((ref) => mockRepository),
          selectedLedgerIdProvider.overrideWith((ref) => null),
          statisticsSelectedDateProvider.overrideWith((ref) => DateTime(2026, 2, 1)),
          selectedStatisticsTypeProvider.overrideWith((ref) => 'expense'),
          selectedExpenseTypeFilterProvider.overrideWith((ref) => ExpenseTypeFilter.all),
          currentLedgerMembersProvider.overrideWith((ref) async => []),
        ],
      );

      // When
      final result = await container.read(categoryStatisticsByUserProvider.future);

      // Then
      expect(result, isEmpty);

      container.dispose();
    });

    test('거래가 없는 멤버도 0원으로 포함된다', () async {
      // Given
      final member1 = LedgerMember(
        id: 'member-1',
        ledgerId: 'ledger-1',
        userId: 'user-1',
        role: 'member',
        joinedAt: DateTime(2026, 1, 1),
        displayName: '홍길동',
        color: '#A8D8EA',
      );
      final member2 = LedgerMember(
        id: 'member-2',
        ledgerId: 'ledger-1',
        userId: 'user-2',
        role: 'member',
        joinedAt: DateTime(2026, 1, 1),
        displayName: null,
        email: 'kim@test.com',
        color: null,
      );

      when(() => mockRepository.getCategoryStatisticsByUser(
            ledgerId: any(named: 'ledgerId'),
            year: any(named: 'year'),
            month: any(named: 'month'),
            type: any(named: 'type'),
            expenseTypeFilter: any(named: 'expenseTypeFilter'),
          )).thenAnswer((_) async => {
            'user-1': UserCategoryStatistics(
              userId: 'user-1',
              userName: '홍길동',
              userColor: '#A8D8EA',
              totalAmount: 100000,
              categories: {},
            ),
          });

      final container = createContainer(
        overrides: [
          statisticsRepositoryProvider.overrideWith((ref) => mockRepository),
          selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
          statisticsSelectedDateProvider.overrideWith((ref) => DateTime(2026, 2, 1)),
          selectedStatisticsTypeProvider.overrideWith((ref) => 'expense'),
          selectedExpenseTypeFilterProvider.overrideWith((ref) => ExpenseTypeFilter.all),
          currentLedgerMembersProvider.overrideWith((ref) async => [member1, member2]),
        ],
      );

      // When
      final result = await container.read(categoryStatisticsByUserProvider.future);

      // Then - 두 멤버 모두 포함, user-2는 0원
      expect(result.keys.length, 2);
      expect(result['user-1']!.totalAmount, 100000);
      expect(result['user-2']!.totalAmount, 0);

      container.dispose();
    });

    test('income 타입에서는 expenseTypeFilter를 적용하지 않는다', () async {
      // Given
      when(() => mockRepository.getCategoryStatisticsByUser(
            ledgerId: any(named: 'ledgerId'),
            year: any(named: 'year'),
            month: any(named: 'month'),
            type: any(named: 'type'),
            expenseTypeFilter: any(named: 'expenseTypeFilter'),
          )).thenAnswer((_) async => {});

      final container = createContainer(
        overrides: [
          statisticsRepositoryProvider.overrideWith((ref) => mockRepository),
          selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
          statisticsSelectedDateProvider.overrideWith((ref) => DateTime(2026, 2, 1)),
          selectedStatisticsTypeProvider.overrideWith((ref) => 'income'),
          selectedExpenseTypeFilterProvider.overrideWith((ref) => ExpenseTypeFilter.fixed),
          currentLedgerMembersProvider.overrideWith((ref) async => []),
        ],
      );

      // When
      await container.read(categoryStatisticsByUserProvider.future);

      // Then - income 타입에서 expenseTypeFilter=null로 호출
      verify(() => mockRepository.getCategoryStatisticsByUser(
            ledgerId: any(named: 'ledgerId'),
            year: any(named: 'year'),
            month: any(named: 'month'),
            type: any(named: 'type'),
            expenseTypeFilter: null,
          )).called(1);

      container.dispose();
    });
  });

  group('yearlyTrendProvider / monthlyTrendProvider 레거시 테스트', () {
    test('yearlyTrendProvider - ledgerId가 null이면 빈 리스트를 반환한다', () async {
      // Given
      final container = createContainer(
        overrides: [
          statisticsRepositoryProvider.overrideWith((ref) => mockRepository),
          selectedLedgerIdProvider.overrideWith((ref) => null),
        ],
      );

      // When
      final result = await container.read(yearlyTrendProvider.future);

      // Then
      expect(result, isEmpty);

      container.dispose();
    });

    test('yearlyTrendProvider - ledgerId가 있으면 데이터를 가져온다', () async {
      // Given
      final yearlyData = [
        YearlyStatistics(year: 2026, income: 10000000, expense: 5000000, saving: 0),
        YearlyStatistics(year: 2025, income: 9000000, expense: 4500000, saving: 0),
        YearlyStatistics(year: 2024, income: 8000000, expense: 4000000, saving: 0),
      ];

      when(() => mockRepository.getYearlyTrend(
            ledgerId: any(named: 'ledgerId'),
            years: any(named: 'years'),
          )).thenAnswer((_) async => yearlyData);

      final container = createContainer(
        overrides: [
          statisticsRepositoryProvider.overrideWith((ref) => mockRepository),
          selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
        ],
      );

      // When
      final result = await container.read(yearlyTrendProvider.future);

      // Then
      expect(result.length, 3);
      expect(result[0].year, 2026);

      container.dispose();
    });

    test('monthlyTrendProvider - ledgerId가 null이면 빈 리스트를 반환한다', () async {
      // Given
      final container = createContainer(
        overrides: [
          statisticsRepositoryProvider.overrideWith((ref) => mockRepository),
          selectedLedgerIdProvider.overrideWith((ref) => null),
        ],
      );

      // When
      final result = await container.read(monthlyTrendProvider.future);

      // Then
      expect(result, isEmpty);

      container.dispose();
    });

    test('monthlyTrendProvider - ledgerId가 있으면 데이터를 가져온다', () async {
      // Given
      final now = DateTime.now();
      final monthlyData = List.generate(6, (i) => MonthlyStatistics(
        year: now.year,
        month: now.month - i,
        income: 3000000,
        expense: 1500000,
        saving: 0,
      ));

      when(() => mockRepository.getMonthlyTrend(
            ledgerId: any(named: 'ledgerId'),
            months: any(named: 'months'),
          )).thenAnswer((_) async => monthlyData);

      final container = createContainer(
        overrides: [
          statisticsRepositoryProvider.overrideWith((ref) => mockRepository),
          selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
        ],
      );

      // When
      final result = await container.read(monthlyTrendProvider.future);

      // Then
      expect(result.length, 6);

      container.dispose();
    });
  });

  group('sharedTotalAmountProvider 테스트', () {
    test('userStats가 null이면 0을 반환한다', () {
      // Given
      final container = createContainer(
        overrides: [
          statisticsRepositoryProvider.overrideWith((ref) => mockRepository),
          selectedLedgerIdProvider.overrideWith((ref) => null),
          statisticsSelectedDateProvider.overrideWith((ref) => DateTime(2026, 2, 1)),
          selectedStatisticsTypeProvider.overrideWith((ref) => 'expense'),
          selectedExpenseTypeFilterProvider.overrideWith((ref) => ExpenseTypeFilter.all),
          currentLedgerMembersProvider.overrideWith((ref) async => []),
        ],
      );

      // When - categoryStatisticsByUserProvider가 아직 로딩 중이므로 valueOrNull은 null
      final total = container.read(sharedTotalAmountProvider);

      // Then
      expect(total, 0);

      container.dispose();
    });

    test('userStats가 있으면 총 금액 합계를 반환한다', () async {
      // Given
      final member1 = LedgerMember(
        id: 'member-1',
        ledgerId: 'ledger-1',
        userId: 'user-1',
        role: 'member',
        joinedAt: DateTime(2026, 1, 1),
        displayName: '홍길동',
        color: '#A8D8EA',
      );
      final member2 = LedgerMember(
        id: 'member-2',
        ledgerId: 'ledger-1',
        userId: 'user-2',
        role: 'member',
        joinedAt: DateTime(2026, 1, 1),
        displayName: '김철수',
        color: '#FFB6A3',
      );

      when(() => mockRepository.getCategoryStatisticsByUser(
            ledgerId: any(named: 'ledgerId'),
            year: any(named: 'year'),
            month: any(named: 'month'),
            type: any(named: 'type'),
            expenseTypeFilter: any(named: 'expenseTypeFilter'),
          )).thenAnswer((_) async => {
            'user-1': UserCategoryStatistics(
              userId: 'user-1',
              userName: '홍길동',
              userColor: '#A8D8EA',
              totalAmount: 100000,
              categories: {},
            ),
            'user-2': UserCategoryStatistics(
              userId: 'user-2',
              userName: '김철수',
              userColor: '#FFB6A3',
              totalAmount: 80000,
              categories: {},
            ),
          });

      final container = createContainer(
        overrides: [
          statisticsRepositoryProvider.overrideWith((ref) => mockRepository),
          selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
          statisticsSelectedDateProvider.overrideWith((ref) => DateTime(2026, 2, 1)),
          selectedStatisticsTypeProvider.overrideWith((ref) => 'expense'),
          selectedExpenseTypeFilterProvider.overrideWith((ref) => ExpenseTypeFilter.all),
          currentLedgerMembersProvider.overrideWith((ref) async => [member1, member2]),
        ],
      );

      // 데이터 로딩 대기
      await container.read(categoryStatisticsByUserProvider.future);

      // When
      final total = container.read(sharedTotalAmountProvider);

      // Then
      expect(total, 180000);

      container.dispose();
    });
  });
}
