import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_household_account/features/category/data/models/category_model.dart';
import 'package:shared_household_account/features/category/data/repositories/category_repository.dart';
import 'package:shared_household_account/features/category/presentation/providers/category_provider.dart';
import 'package:shared_household_account/features/ledger/presentation/providers/ledger_provider.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  group('CategoryProvider Tests', () {
    late MockCategoryRepository mockRepository;
    late ProviderContainer container;

    setUp(() {
      mockRepository = MockCategoryRepository();
    });

    tearDown(() {
      container.dispose();
    });

    group('categoriesProvider', () {
      test('ledgerId가 null일 때 빈 리스트를 반환한다', () async {
        // Given: ledgerId가 null인 상태
        container = createContainer(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => null),
            categoryRepositoryProvider.overrideWith((ref) => mockRepository),
          ],
        );

        // When
        final categories = await container.read(categoriesProvider.future);

        // Then
        expect(categories, isEmpty);
        verifyNever(() => mockRepository.getCategories(any()));
      });

      test('ledgerId가 존재할 때 카테고리 목록을 가져온다', () async {
        // Given
        const testLedgerId = 'test-ledger-id';
        final mockCategories = [
          CategoryModel(
            id: 'cat-1',
            ledgerId: testLedgerId,
            name: '식비',
            icon: 'restaurant',
            color: '#FF5722',
            type: 'expense',
            isDefault: false,
            sortOrder: 0,
            createdAt: DateTime.now(),
          ),
          CategoryModel(
            id: 'cat-2',
            ledgerId: testLedgerId,
            name: '급여',
            icon: 'payments',
            color: '#4CAF50',
            type: 'income',
            isDefault: false,
            sortOrder: 1,
            createdAt: DateTime.now(),
          ),
        ];

        when(() => mockRepository.getCategories(testLedgerId))
            .thenAnswer((_) async => mockCategories);

        container = createContainer(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => testLedgerId),
            categoryRepositoryProvider.overrideWith((ref) => mockRepository),
          ],
        );

        // When
        final categories = await container.read(categoriesProvider.future);

        // Then
        expect(categories.length, equals(2));
        expect(categories[0].name, equals('식비'));
        expect(categories[1].name, equals('급여'));
        verify(() => mockRepository.getCategories(testLedgerId)).called(1);
      });
    });

    group('incomeCategoriesProvider', () {
      test('수입 카테고리만 필터링하여 반환한다', () async {
        // Given
        const testLedgerId = 'test-ledger-id';
        final mockCategories = [
          CategoryModel(
            id: 'cat-1',
            ledgerId: testLedgerId,
            name: '급여',
            icon: 'payments',
            color: '#4CAF50',
            type: 'income',
            isDefault: false,
            sortOrder: 0,
            createdAt: DateTime.now(),
          ),
          CategoryModel(
            id: 'cat-2',
            ledgerId: testLedgerId,
            name: '식비',
            icon: 'restaurant',
            color: '#FF5722',
            type: 'expense',
            isDefault: false,
            sortOrder: 0,
            createdAt: DateTime.now(),
          ),
        ];

        when(() => mockRepository.getCategories(testLedgerId))
            .thenAnswer((_) async => mockCategories);

        container = createContainer(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => testLedgerId),
            categoryRepositoryProvider.overrideWith((ref) => mockRepository),
          ],
        );

        // When
        final incomeCategories =
            await container.read(incomeCategoriesProvider.future);

        // Then
        expect(incomeCategories.length, equals(1));
        expect(incomeCategories[0].type, equals('income'));
        expect(incomeCategories[0].name, equals('급여'));
      });
    });

    group('expenseCategoriesProvider', () {
      test('지출 카테고리만 필터링하여 반환한다', () async {
        // Given
        const testLedgerId = 'test-ledger-id';
        final mockCategories = [
          CategoryModel(
            id: 'cat-1',
            ledgerId: testLedgerId,
            name: '급여',
            icon: 'payments',
            color: '#4CAF50',
            type: 'income',
            isDefault: false,
            sortOrder: 0,
            createdAt: DateTime.now(),
          ),
          CategoryModel(
            id: 'cat-2',
            ledgerId: testLedgerId,
            name: '식비',
            icon: 'restaurant',
            color: '#FF5722',
            type: 'expense',
            isDefault: false,
            sortOrder: 0,
            createdAt: DateTime.now(),
          ),
        ];

        when(() => mockRepository.getCategories(testLedgerId))
            .thenAnswer((_) async => mockCategories);

        container = createContainer(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => testLedgerId),
            categoryRepositoryProvider.overrideWith((ref) => mockRepository),
          ],
        );

        // When
        final expenseCategories =
            await container.read(expenseCategoriesProvider.future);

        // Then
        expect(expenseCategories.length, equals(1));
        expect(expenseCategories[0].type, equals('expense'));
        expect(expenseCategories[0].name, equals('식비'));
      });
    });

    group('savingCategoriesProvider', () {
      test('자산 카테고리만 필터링하여 반환한다', () async {
        // Given
        const testLedgerId = 'test-ledger-id';
        final mockCategories = [
          CategoryModel(
            id: 'cat-1',
            ledgerId: testLedgerId,
            name: '정기예금',
            icon: 'savings',
            color: '#2196F3',
            type: 'asset',
            isDefault: false,
            sortOrder: 0,
            createdAt: DateTime.now(),
          ),
          CategoryModel(
            id: 'cat-2',
            ledgerId: testLedgerId,
            name: '식비',
            icon: 'restaurant',
            color: '#FF5722',
            type: 'expense',
            isDefault: false,
            sortOrder: 0,
            createdAt: DateTime.now(),
          ),
        ];

        when(() => mockRepository.getCategories(testLedgerId))
            .thenAnswer((_) async => mockCategories);

        container = createContainer(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => testLedgerId),
            categoryRepositoryProvider.overrideWith((ref) => mockRepository),
          ],
        );

        // When
        final savingCategories =
            await container.read(savingCategoriesProvider.future);

        // Then
        expect(savingCategories.length, equals(1));
        expect(savingCategories[0].type, equals('asset'));
        expect(savingCategories[0].name, equals('정기예금'));
      });
    });

    group('CategoryNotifier', () {
      test('ledgerId가 null일 때 빈 데이터 상태로 초기화된다', () async {
        // Given
        container = createContainer(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => null),
            categoryRepositoryProvider.overrideWith((ref) => mockRepository),
          ],
        );

        // When
        final notifier = container.read(categoryNotifierProvider.notifier);

        // Then
        expect(notifier.state.value, isEmpty);
      });

      test('createCategory 성공 시 카테고리를 생성하고 목록을 갱신한다', () async {
        // Given
        const testLedgerId = 'test-ledger-id';
        final newCategory = CategoryModel(
          id: 'cat-new',
          ledgerId: testLedgerId,
          name: '교통비',
          icon: 'directions_car',
          color: '#FF9800',
          type: 'expense',
          isDefault: false,
          sortOrder: 0,
          createdAt: DateTime.now(),
        );

        when(
          () => mockRepository.createCategory(
            ledgerId: testLedgerId,
            name: '교통비',
            icon: 'directions_car',
            color: '#FF9800',
            type: 'expense',
          ),
        ).thenAnswer((_) async => newCategory);

        when(() => mockRepository.getCategories(testLedgerId))
            .thenAnswer((_) async => [newCategory]);

        container = createContainer(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => testLedgerId),
            categoryRepositoryProvider.overrideWith((ref) => mockRepository),
          ],
        );

        final notifier = container.read(categoryNotifierProvider.notifier);

        // When
        final created = await notifier.createCategory(
          name: '교통비',
          icon: 'directions_car',
          color: '#FF9800',
          type: 'expense',
        );

        // Then
        expect(created.name, equals('교통비'));
        verify(
          () => mockRepository.createCategory(
            ledgerId: testLedgerId,
            name: '교통비',
            icon: 'directions_car',
            color: '#FF9800',
            type: 'expense',
          ),
        ).called(1);
      });

      test('ledgerId가 null일 때 createCategory는 예외를 발생시킨다', () async {
        // Given
        container = createContainer(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => null),
            categoryRepositoryProvider.overrideWith((ref) => mockRepository),
          ],
        );

        final notifier = container.read(categoryNotifierProvider.notifier);

        // When & Then
        expect(
          () => notifier.createCategory(
            name: '교통비',
            icon: 'directions_car',
            color: '#FF9800',
            type: 'expense',
          ),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}
