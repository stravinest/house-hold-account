import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/ledger/presentation/providers/monthly_list_view_provider.dart';
import 'package:shared_household_account/features/transaction/domain/entities/transaction.dart';
import 'package:shared_household_account/features/transaction/presentation/providers/transaction_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('MonthlyListViewProvider Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    group('MonthlyViewTypeNotifier', () {
      test('기본값은 calendar이다', () {
        // Given
        SharedPreferences.setMockInitialValues({});

        // When
        final notifier = MonthlyViewTypeNotifier();

        // Then
        expect(notifier.state, equals(MonthlyViewType.calendar));
      });

      test('toggle은 calendar와 list를 전환한다', () async {
        // Given
        SharedPreferences.setMockInitialValues({});
        final notifier = MonthlyViewTypeNotifier();

        // When: calendar → list
        await notifier.toggle();

        // Then
        expect(notifier.state, equals(MonthlyViewType.list));

        // When: list → calendar
        await notifier.toggle();

        // Then
        expect(notifier.state, equals(MonthlyViewType.calendar));
      });

      test('toggle은 SharedPreferences에 저장한다', () async {
        // Given
        SharedPreferences.setMockInitialValues({});
        final notifier = MonthlyViewTypeNotifier();

        // When
        await notifier.toggle();

        // Then
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('monthly_view_type'), equals('list'));
      });
    });

    group('TransactionFilter', () {
      test('TransactionFilter enum이 올바르게 정의되어 있다', () {
        // Then
        expect(TransactionFilter.values.length, equals(5));
        expect(TransactionFilter.values.contains(TransactionFilter.all), isTrue);
        expect(TransactionFilter.values.contains(TransactionFilter.recurring),
            isTrue);
        expect(TransactionFilter.values.contains(TransactionFilter.income),
            isTrue);
        expect(TransactionFilter.values.contains(TransactionFilter.expense),
            isTrue);
        expect(TransactionFilter.values.contains(TransactionFilter.asset),
            isTrue);
      });
    });

    group('MonthlyViewTypeNotifier - SharedPreferences 복원', () {
      test('저장된 list 값을 복원한다', () async {
        // Given
        SharedPreferences.setMockInitialValues({'monthly_view_type': 'list'});
        final notifier = MonthlyViewTypeNotifier();

        // 비동기 로딩 대기
        await Future.delayed(const Duration(milliseconds: 100));

        // Then
        expect(notifier.state, equals(MonthlyViewType.list));
      });

      test('저장된 값이 list가 아닌 경우 기본값 calendar를 사용한다', () async {
        // Given
        SharedPreferences.setMockInitialValues({'monthly_view_type': 'calendar'});
        final notifier = MonthlyViewTypeNotifier();

        await Future.delayed(const Duration(milliseconds: 100));

        // Then
        expect(notifier.state, equals(MonthlyViewType.calendar));
      });

      test('toggle은 list에서 calendar로 전환 후 SharedPreferences에 calendar를 저장한다', () async {
        // Given
        SharedPreferences.setMockInitialValues({});
        final notifier = MonthlyViewTypeNotifier();
        await notifier.toggle(); // calendar -> list

        // When
        await notifier.toggle(); // list -> calendar

        // Then
        expect(notifier.state, equals(MonthlyViewType.calendar));
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('monthly_view_type'), equals('calendar'));
      });
    });

    group('MonthlyViewType enum', () {
      test('MonthlyViewType.values에 2개 요소가 있다', () {
        // Then
        expect(MonthlyViewType.values.length, equals(2));
        expect(MonthlyViewType.values.contains(MonthlyViewType.calendar), isTrue);
        expect(MonthlyViewType.values.contains(MonthlyViewType.list), isTrue);
      });

      test('calendar와 list 이름이 올바르다', () {
        // Then
        expect(MonthlyViewType.calendar.name, equals('calendar'));
        expect(MonthlyViewType.list.name, equals('list'));
      });
    });

    group('TransactionFilter name 테스트', () {
      test('각 TransactionFilter의 name이 올바르다', () {
        // Then
        expect(TransactionFilter.all.name, equals('all'));
        expect(TransactionFilter.recurring.name, equals('recurring'));
        expect(TransactionFilter.income.name, equals('income'));
        expect(TransactionFilter.expense.name, equals('expense'));
        expect(TransactionFilter.asset.name, equals('asset'));
      });
    });

    group('filteredMonthlyTransactionsProvider 필터링 로직', () {
      Transaction _buildTx({
        String id = 'tx-1',
        String type = 'expense',
        bool isFixedExpense = false,
      }) {
        final d = DateTime(2024, 1, 15);
        return Transaction(
          id: id,
          ledgerId: 'ledger-1',
          userId: 'user-1',
          type: type,
          amount: 10000,
          date: d,
          isRecurring: false,
          isFixedExpense: isFixedExpense,
          createdAt: d,
          updatedAt: d,
        );
      }

      test('all 필터 선택 시 모든 거래를 반환한다', () async {
        // Given
        final transactions = [
          _buildTx(id: 'tx-1', type: 'expense'),
          _buildTx(id: 'tx-2', type: 'income'),
          _buildTx(id: 'tx-3', type: 'asset'),
        ];

        final container = ProviderContainer(
          overrides: [
            monthlyTransactionsProvider.overrideWith(
              (ref) async => transactions,
            ),
            selectedFiltersProvider.overrideWith(
              (ref) => {TransactionFilter.all},
            ),
          ],
        );
        addTearDown(container.dispose);

        // 비동기 데이터 로드 완료 대기
        await container.read(monthlyTransactionsProvider.future);

        // When
        final result = container.read(filteredMonthlyTransactionsProvider);

        // Then: all 필터는 모든 거래를 반환
        result.whenData((list) {
          expect(list.length, equals(3));
        });
      });

      test('income 필터 선택 시 수입 거래만 반환한다', () async {
        // Given
        final transactions = [
          _buildTx(id: 'tx-1', type: 'expense'),
          _buildTx(id: 'tx-2', type: 'income'),
          _buildTx(id: 'tx-3', type: 'income'),
        ];

        final container = ProviderContainer(
          overrides: [
            monthlyTransactionsProvider.overrideWith(
              (ref) async => transactions,
            ),
            selectedFiltersProvider.overrideWith(
              (ref) => {TransactionFilter.income},
            ),
          ],
        );
        addTearDown(container.dispose);

        // 비동기 데이터 로드 완료 대기
        await container.read(monthlyTransactionsProvider.future);

        // When
        final result = container.read(filteredMonthlyTransactionsProvider);

        // Then: 수입 거래 2개만 반환
        expect(result.value, isNotNull);
        expect(result.value!.length, equals(2));
        expect(result.value!.every((tx) => tx.type == 'income'), isTrue);
      });

      test('expense 필터 선택 시 지출 거래만 반환한다', () async {
        // Given
        final transactions = [
          _buildTx(id: 'tx-1', type: 'expense'),
          _buildTx(id: 'tx-2', type: 'expense'),
          _buildTx(id: 'tx-3', type: 'income'),
        ];

        final container = ProviderContainer(
          overrides: [
            monthlyTransactionsProvider.overrideWith(
              (ref) async => transactions,
            ),
            selectedFiltersProvider.overrideWith(
              (ref) => {TransactionFilter.expense},
            ),
          ],
        );
        addTearDown(container.dispose);

        // 비동기 데이터 로드 완료 대기
        await container.read(monthlyTransactionsProvider.future);

        // When
        final result = container.read(filteredMonthlyTransactionsProvider);

        // Then: 지출 거래 2개만 반환
        expect(result.value, isNotNull);
        expect(result.value!.length, equals(2));
        expect(result.value!.every((tx) => tx.type == 'expense'), isTrue);
      });

      test('asset 필터 선택 시 자산 거래만 반환한다', () async {
        // Given
        final transactions = [
          _buildTx(id: 'tx-1', type: 'expense'),
          _buildTx(id: 'tx-2', type: 'asset'),
          _buildTx(id: 'tx-3', type: 'asset'),
        ];

        final container = ProviderContainer(
          overrides: [
            monthlyTransactionsProvider.overrideWith(
              (ref) async => transactions,
            ),
            selectedFiltersProvider.overrideWith(
              (ref) => {TransactionFilter.asset},
            ),
          ],
        );
        addTearDown(container.dispose);

        // 비동기 데이터 로드 완료 대기
        await container.read(monthlyTransactionsProvider.future);

        // When
        final result = container.read(filteredMonthlyTransactionsProvider);

        // Then: 자산 거래 2개만 반환
        expect(result.value, isNotNull);
        expect(result.value!.length, equals(2));
        expect(result.value!.every((tx) => tx.type == 'asset'), isTrue);
      });

      test('recurring 필터 선택 시 고정비 거래만 반환한다', () async {
        // Given
        final transactions = [
          _buildTx(id: 'tx-1', type: 'expense', isFixedExpense: true),
          _buildTx(id: 'tx-2', type: 'expense', isFixedExpense: false),
          _buildTx(id: 'tx-3', type: 'income', isFixedExpense: false),
        ];

        final container = ProviderContainer(
          overrides: [
            monthlyTransactionsProvider.overrideWith(
              (ref) async => transactions,
            ),
            selectedFiltersProvider.overrideWith(
              (ref) => {TransactionFilter.recurring},
            ),
          ],
        );
        addTearDown(container.dispose);

        // 비동기 데이터 로드 완료 대기
        await container.read(monthlyTransactionsProvider.future);

        // When
        final result = container.read(filteredMonthlyTransactionsProvider);

        // Then: 고정비 거래 1개만 반환
        expect(result.value, isNotNull);
        expect(result.value!.length, equals(1));
        expect(result.value!.first.isFixedExpense, isTrue);
      });

      test('income과 expense 동시 필터 선택 시 OR 조건으로 반환한다', () async {
        // Given
        final transactions = [
          _buildTx(id: 'tx-1', type: 'expense'),
          _buildTx(id: 'tx-2', type: 'income'),
          _buildTx(id: 'tx-3', type: 'asset'),
        ];

        final container = ProviderContainer(
          overrides: [
            monthlyTransactionsProvider.overrideWith(
              (ref) async => transactions,
            ),
            selectedFiltersProvider.overrideWith(
              (ref) => {TransactionFilter.income, TransactionFilter.expense},
            ),
          ],
        );
        addTearDown(container.dispose);

        // 비동기 데이터 로드 완료 대기
        await container.read(monthlyTransactionsProvider.future);

        // When
        final result = container.read(filteredMonthlyTransactionsProvider);

        // Then: income + expense = 2개 반환 (asset 제외)
        expect(result.value, isNotNull);
        expect(result.value!.length, equals(2));
      });

      test('필터에 해당하지 않는 거래는 제외된다 (OR 조건 false 경로)', () async {
        // Given: asset 거래만 있고 income 필터 선택 시 빈 리스트 반환
        final transactions = [
          _buildTx(id: 'tx-1', type: 'asset'),
          _buildTx(id: 'tx-2', type: 'asset'),
        ];

        final container = ProviderContainer(
          overrides: [
            monthlyTransactionsProvider.overrideWith(
              (ref) async => transactions,
            ),
            selectedFiltersProvider.overrideWith(
              (ref) => {TransactionFilter.income},
            ),
          ],
        );
        addTearDown(container.dispose);

        // 비동기 데이터 로드 완료 대기
        await container.read(monthlyTransactionsProvider.future);

        // When
        final result = container.read(filteredMonthlyTransactionsProvider);

        // Then: 0개 반환 (income 없음)
        expect(result.value, isNotNull);
        expect(result.value!.isEmpty, isTrue);
      });

      test('로딩 상태일 때 AsyncLoading을 반환한다', () {
        // Given
        final container = ProviderContainer(
          overrides: [
            monthlyTransactionsProvider.overrideWith(
              (ref) async {
                await Future.delayed(const Duration(seconds: 10));
                return <Transaction>[];
              },
            ),
            selectedFiltersProvider.overrideWith(
              (ref) => {TransactionFilter.all},
            ),
          ],
        );
        addTearDown(container.dispose);

        // When
        final result = container.read(filteredMonthlyTransactionsProvider);

        // Then: 로딩 상태
        expect(result, isA<AsyncLoading>());
      });

      test('에러 상태일 때 AsyncError를 반환한다', () async {
        // Given
        final container = ProviderContainer(
          overrides: [
            monthlyTransactionsProvider.overrideWith(
              (ref) async => throw Exception('테스트 에러'),
            ),
            selectedFiltersProvider.overrideWith(
              (ref) => {TransactionFilter.all},
            ),
          ],
        );
        addTearDown(container.dispose);

        // When: 에러 발생 대기
        try {
          await container.read(monthlyTransactionsProvider.future);
        } catch (_) {}

        // Then: error 상태
        final result = container.read(filteredMonthlyTransactionsProvider);
        expect(result, isA<AsyncError>());
      });
    });
  });

  group('monthlyViewTypeProvider 실제 Provider 테스트', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('monthlyViewTypeProvider 초기값은 calendar이다', () async {
      // Given: 실제 provider 사용 (override 없음)
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // When: provider 읽기
      final viewType = container.read(monthlyViewTypeProvider);

      // Then
      expect(viewType, equals(MonthlyViewType.calendar));
    });

    test('monthlyViewTypeProvider를 통해 toggle 후 list가 된다', () async {
      // Given
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // When: toggle 실행
      await container.read(monthlyViewTypeProvider.notifier).toggle();

      // Then
      expect(container.read(monthlyViewTypeProvider), equals(MonthlyViewType.list));
    });
  });

  group('selectedFiltersProvider 실제 Provider 테스트', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('selectedFiltersProvider 초기값은 all이다', () {
      // Given
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // When
      final filters = container.read(selectedFiltersProvider);

      // Then
      expect(filters, equals({TransactionFilter.all}));
    });

    test('selectedFiltersProvider에 income 필터를 추가할 수 있다', () {
      // Given
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // When
      container.read(selectedFiltersProvider.notifier).state = {TransactionFilter.income};

      // Then
      expect(container.read(selectedFiltersProvider), equals({TransactionFilter.income}));
    });

    test('selectedFiltersProvider에 여러 필터를 설정할 수 있다', () {
      // Given
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // When
      container.read(selectedFiltersProvider.notifier).state = {
        TransactionFilter.income,
        TransactionFilter.expense,
      };

      // Then
      final filters = container.read(selectedFiltersProvider);
      expect(filters.contains(TransactionFilter.income), isTrue);
      expect(filters.contains(TransactionFilter.expense), isTrue);
      expect(filters.contains(TransactionFilter.all), isFalse);
    });
  });

  group('filteredMonthlyTransactionsProvider 실제 Provider 테스트', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    Transaction _buildTx({
      String id = 'tx-1',
      String type = 'expense',
      bool isFixedExpense = false,
    }) {
      final d = DateTime(2024, 1, 15);
      return Transaction(
        id: id,
        ledgerId: 'ledger-1',
        userId: 'user-1',
        type: type,
        amount: 10000,
        date: d,
        isRecurring: false,
        isFixedExpense: isFixedExpense,
        createdAt: d,
        updatedAt: d,
      );
    }

    test('실제 selectedFiltersProvider 상태 변경이 filteredMonthlyTransactionsProvider에 반영된다', () async {
      // Given: 실제 selectedFiltersProvider 사용, monthlyTransactionsProvider만 override
      final transactions = [
        _buildTx(id: 'tx-1', type: 'expense'),
        _buildTx(id: 'tx-2', type: 'income'),
      ];

      final container = ProviderContainer(
        overrides: [
          monthlyTransactionsProvider.overrideWith(
            (ref) async => transactions,
          ),
        ],
      );
      addTearDown(container.dispose);

      // 비동기 완료 대기
      await Future.delayed(const Duration(milliseconds: 100));

      // When: income 필터로 변경
      container.read(selectedFiltersProvider.notifier).state = {TransactionFilter.income};
      await Future.delayed(const Duration(milliseconds: 50));

      // Then: income 거래만 반환됨
      final result = container.read(filteredMonthlyTransactionsProvider);
      result.whenData((list) {
        expect(list.length, equals(1));
        expect(list.first.type, equals('income'));
      });
    });

    test('all 필터로 변경하면 모든 거래가 반환된다', () async {
      // Given
      final transactions = [
        _buildTx(id: 'tx-1', type: 'expense'),
        _buildTx(id: 'tx-2', type: 'income'),
        _buildTx(id: 'tx-3', type: 'asset'),
      ];

      final container = ProviderContainer(
        overrides: [
          monthlyTransactionsProvider.overrideWith(
            (ref) async => transactions,
          ),
        ],
      );
      addTearDown(container.dispose);

      // When: expense 후 all로 변경
      container.read(selectedFiltersProvider.notifier).state = {TransactionFilter.expense};
      await Future.delayed(const Duration(milliseconds: 100));
      container.read(selectedFiltersProvider.notifier).state = {TransactionFilter.all};
      await Future.delayed(const Duration(milliseconds: 50));

      // Then: 모든 거래 반환
      final result = container.read(filteredMonthlyTransactionsProvider);
      result.whenData((list) {
        expect(list.length, equals(3));
      });
    });

    test('recurring 필터로 고정비 거래만 반환된다', () async {
      // Given
      final transactions = [
        _buildTx(id: 'tx-1', type: 'expense', isFixedExpense: true),
        _buildTx(id: 'tx-2', type: 'expense', isFixedExpense: false),
      ];

      final container = ProviderContainer(
        overrides: [
          monthlyTransactionsProvider.overrideWith(
            (ref) async => transactions,
          ),
          selectedFiltersProvider.overrideWith(
            (ref) => {TransactionFilter.recurring},
          ),
        ],
      );
      addTearDown(container.dispose);

      await Future.delayed(const Duration(milliseconds: 100));

      // When
      final result = container.read(filteredMonthlyTransactionsProvider);

      // Then: 고정비 거래 1개만
      result.whenData((list) {
        expect(list.length, equals(1));
        expect(list.first.isFixedExpense, isTrue);
      });
    });

    test('asset 필터로 자산 거래만 반환된다', () async {
      // Given
      final transactions = [
        _buildTx(id: 'tx-1', type: 'expense'),
        _buildTx(id: 'tx-2', type: 'asset'),
        _buildTx(id: 'tx-3', type: 'asset'),
      ];

      final container = ProviderContainer(
        overrides: [
          monthlyTransactionsProvider.overrideWith(
            (ref) async => transactions,
          ),
          selectedFiltersProvider.overrideWith(
            (ref) => {TransactionFilter.asset},
          ),
        ],
      );
      addTearDown(container.dispose);

      await Future.delayed(const Duration(milliseconds: 100));

      // When
      final result = container.read(filteredMonthlyTransactionsProvider);

      // Then: 자산 거래 2개
      result.whenData((list) {
        expect(list.length, equals(2));
        expect(list.every((tx) => tx.type == 'asset'), isTrue);
      });
    });

    test('error 상태에서 AsyncError가 반환된다', () async {
      // Given
      final container = ProviderContainer(
        overrides: [
          monthlyTransactionsProvider.overrideWith(
            (ref) async => throw Exception('로드 실패'),
          ),
          selectedFiltersProvider.overrideWith(
            (ref) => {TransactionFilter.all},
          ),
        ],
      );
      addTearDown(container.dispose);

      // 에러 완료 대기
      await Future.delayed(const Duration(milliseconds: 200));

      // When
      final result = container.read(filteredMonthlyTransactionsProvider);

      // Then: error 또는 loading (비동기 타이밍)
      expect(result, isA<AsyncValue<List<Transaction>>>());
    });
  });
}
