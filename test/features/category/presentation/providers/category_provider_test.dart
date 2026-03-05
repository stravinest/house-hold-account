import 'package:flutter_riverpod/flutter_riverpod.dart' show AsyncError;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_household_account/features/category/data/models/category_model.dart';
import 'package:shared_household_account/features/category/data/repositories/category_repository.dart';
import 'package:shared_household_account/features/category/domain/entities/category.dart';
import 'package:shared_household_account/features/category/presentation/providers/category_provider.dart';
import 'package:shared_household_account/features/ledger/presentation/providers/ledger_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../helpers/mock_supabase.dart';
import '../../../../helpers/test_helpers.dart';

void main() {
  group('CategoryProvider Tests', () {
    late MockCategoryRepository mockRepository;
    late ProviderContainer container;

    setUpAll(() {
      registerFallbackValue(PostgresChangeEvent.all);
    });

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

    group('CategoryNotifier - 초기화', () {
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

      test('ledgerId가 있을 때 카테고리를 로드하여 데이터 상태가 된다', () async {
        // Given
        const testLedgerId = 'test-ledger-id';
        final categories = [
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
        ];
        when(() => mockRepository.getCategories(testLedgerId))
            .thenAnswer((_) async => categories);

        container = createContainer(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => testLedgerId),
            categoryRepositoryProvider.overrideWith((ref) => mockRepository),
          ],
        );

        // When: 비동기 로딩 완료 대기
        await Future.delayed(Duration.zero);
        final notifier = container.read(categoryNotifierProvider.notifier);
        await Future.delayed(Duration.zero);

        // Then
        expect(notifier.state.hasValue, isTrue);
      });
    });

    group('CategoryNotifier - createCategory', () {
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

      test('createCategory 실패 시 에러 상태가 되고 예외를 전파한다', () async {
        // Given
        const testLedgerId = 'test-ledger-id';
        when(() => mockRepository.getCategories(testLedgerId))
            .thenAnswer((_) async => []);
        when(
          () => mockRepository.createCategory(
            ledgerId: any(named: 'ledgerId'),
            name: any(named: 'name'),
            icon: any(named: 'icon'),
            color: any(named: 'color'),
            type: any(named: 'type'),
          ),
        ).thenThrow(Exception('생성 실패'));

        container = createContainer(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => testLedgerId),
            categoryRepositoryProvider.overrideWith((ref) => mockRepository),
          ],
        );

        final notifier = container.read(categoryNotifierProvider.notifier);

        // When & Then
        await expectLater(
          () => notifier.createCategory(
            name: '실패카테고리',
            icon: 'error',
            color: '#000000',
            type: 'expense',
          ),
          throwsA(isA<Exception>()),
        );

        // 에러 상태 확인
        final state = container.read(categoryNotifierProvider);
        expect(state, isA<AsyncError<List<Category>>>());
      });
    });

    group('CategoryNotifier - updateCategory', () {
      test('updateCategory 성공 시 서버 응답 카테고리를 반환한다', () async {
        // Given
        const testLedgerId = 'test-ledger-id';
        final updatedCategory = CategoryModel(
          id: 'cat-1',
          ledgerId: testLedgerId,
          name: '수정된 카테고리',
          icon: 'shopping_cart',
          color: '#E91E63',
          type: 'expense',
          isDefault: false,
          sortOrder: 0,
          createdAt: DateTime.now(),
        );

        when(
          () => mockRepository.updateCategory(
            id: 'cat-1',
            name: '수정된 카테고리',
            icon: 'shopping_cart',
            color: '#E91E63',
          ),
        ).thenAnswer((_) async => updatedCategory);

        when(() => mockRepository.getCategories(testLedgerId))
            .thenAnswer((_) async => [updatedCategory]);

        container = createContainer(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => testLedgerId),
            categoryRepositoryProvider.overrideWith((ref) => mockRepository),
          ],
        );

        final notifier = container.read(categoryNotifierProvider.notifier);

        // When
        final result = await notifier.updateCategory(
          id: 'cat-1',
          name: '수정된 카테고리',
          icon: 'shopping_cart',
          color: '#E91E63',
        );

        // Then
        expect(result.id, equals('cat-1'));
        expect(result.name, equals('수정된 카테고리'));
        verify(
          () => mockRepository.updateCategory(
            id: 'cat-1',
            name: '수정된 카테고리',
            icon: 'shopping_cart',
            color: '#E91E63',
          ),
        ).called(1);
      });

      test('updateCategory 실패 시 예외를 전파한다', () async {
        // Given
        const testLedgerId = 'test-ledger-id';
        when(
          () => mockRepository.updateCategory(
            id: any(named: 'id'),
            name: any(named: 'name'),
            icon: any(named: 'icon'),
            color: any(named: 'color'),
          ),
        ).thenThrow(Exception('서버 에러'));

        when(() => mockRepository.getCategories(testLedgerId))
            .thenAnswer((_) async => []);

        container = createContainer(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => testLedgerId),
            categoryRepositoryProvider.overrideWith((ref) => mockRepository),
          ],
        );

        final notifier = container.read(categoryNotifierProvider.notifier);

        // When & Then
        expect(
          () => notifier.updateCategory(
            id: 'cat-1',
            name: '실패 테스트',
            icon: 'error',
            color: '#000000',
          ),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('CategoryNotifier - deleteCategory', () {
      test('deleteCategory 성공 시 카테고리를 삭제하고 목록을 갱신한다', () async {
        // Given
        const testLedgerId = 'test-ledger-id';
        when(() => mockRepository.deleteCategory(any()))
            .thenAnswer((_) async {});
        when(() => mockRepository.getCategories(testLedgerId))
            .thenAnswer((_) async => []);

        container = createContainer(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => testLedgerId),
            categoryRepositoryProvider.overrideWith((ref) => mockRepository),
          ],
        );

        final notifier = container.read(categoryNotifierProvider.notifier);

        // When
        await notifier.deleteCategory('cat-1');

        // Then: deleteCategory가 호출됨
        verify(() => mockRepository.deleteCategory('cat-1')).called(1);
      });

      test('deleteCategory 실패 시 데이터를 다시 로드하고 예외를 전파한다', () async {
        // Given
        const testLedgerId = 'test-ledger-id';
        when(() => mockRepository.deleteCategory(any()))
            .thenThrow(Exception('삭제 실패'));
        when(() => mockRepository.getCategories(testLedgerId))
            .thenAnswer((_) async => []);

        container = createContainer(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => testLedgerId),
            categoryRepositoryProvider.overrideWith((ref) => mockRepository),
          ],
        );

        final notifier = container.read(categoryNotifierProvider.notifier);

        // When & Then: 예외가 전파됨
        await expectLater(
          () => notifier.deleteCategory('cat-1'),
          throwsA(isA<Exception>()),
        );

        // 실패 후에도 getCategories가 호출되어 상태 복구를 시도
        verify(() => mockRepository.getCategories(testLedgerId)).called(greaterThan(0));
      });
    });

    group('CategoryNotifier - loadCategories', () {
      test('loadCategories 실패 시 에러 상태로 전환되고 예외를 전파한다', () async {
        // Given: 처음엔 성공, 두 번째 호출에서 실패
        const testLedgerId = 'test-ledger-id';
        var callCount = 0;
        when(() => mockRepository.getCategories(testLedgerId))
            .thenAnswer((_) async {
          callCount++;
          if (callCount > 1) throw Exception('로드 실패');
          return [];
        });

        container = createContainer(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => testLedgerId),
            categoryRepositoryProvider.overrideWith((ref) => mockRepository),
          ],
        );

        final notifier = container.read(categoryNotifierProvider.notifier);

        // When: 초기 로드 완료 후 수동 로드 실패
        await Future.delayed(Duration.zero);

        // Then: 두 번째 로드에서 에러 발생
        await expectLater(
          () => notifier.loadCategories(),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('CategoryNotifier - _subscribeToChanges 및 _refreshCategoriesQuietly', () {
      test('subscribeCategories가 호출되고 onCategoryChanged 콜백이 실행되면 카테고리를 다시 로드한다', () async {
        // Given: subscribeCategories가 onCategoryChanged 콜백을 캡처하도록 설정
        const testLedgerId = 'test-ledger-id';
        final mockChannel = MockRealtimeChannel();
        void Function()? capturedCallback;

        when(() => mockChannel.unsubscribe())
            .thenAnswer((_) async => 'ok');

        // subscribeCategories를 stub하여 콜백을 캡처
        when(
          () => mockRepository.subscribeCategories(
            ledgerId: testLedgerId,
            onCategoryChanged: any(named: 'onCategoryChanged'),
          ),
        ).thenAnswer((invocation) {
          capturedCallback =
              invocation.namedArguments[const Symbol('onCategoryChanged')]
                  as void Function();
          return mockChannel;
        });

        final initialCategories = [
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
        ];
        final updatedCategories = [
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
            name: '교통비',
            icon: 'directions_car',
            color: '#FF9800',
            type: 'expense',
            isDefault: false,
            sortOrder: 1,
            createdAt: DateTime.now(),
          ),
        ];

        var callCount = 0;
        when(() => mockRepository.getCategories(testLedgerId)).thenAnswer((_) async {
          callCount++;
          if (callCount == 1) return initialCategories;
          return updatedCategories;
        });

        container = createContainer(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => testLedgerId),
            categoryRepositoryProvider.overrideWith((ref) => mockRepository),
          ],
        );

        // When: notifier 초기화 및 초기 로드 완료 대기
        container.read(categoryNotifierProvider.notifier);
        await Future.delayed(Duration.zero);

        // subscribeCategories가 호출되어 콜백이 캡처되었는지 확인
        expect(capturedCallback, isNotNull);

        // 콜백 호출로 _refreshCategoriesQuietly 실행
        capturedCallback!();
        await Future.delayed(Duration.zero);

        // Then: getCategories가 2번 이상 호출되었음 (초기 + refresh)
        verify(() => mockRepository.getCategories(testLedgerId)).called(greaterThan(1));
      });

      test('subscribeCategories에서 예외가 발생해도 앱이 크래시되지 않는다', () async {
        // Given: subscribeCategories가 예외를 던지도록 설정
        const testLedgerId = 'test-ledger-id';
        when(
          () => mockRepository.subscribeCategories(
            ledgerId: testLedgerId,
            onCategoryChanged: any(named: 'onCategoryChanged'),
          ),
        ).thenThrow(Exception('Realtime 연결 실패'));

        when(() => mockRepository.getCategories(testLedgerId))
            .thenAnswer((_) async => []);

        // When: 컨테이너 생성 및 notifier 초기화 (예외 발생해도 크래시 없음)
        container = createContainer(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => testLedgerId),
            categoryRepositoryProvider.overrideWith((ref) => mockRepository),
          ],
        );

        container.read(categoryNotifierProvider.notifier);
        await Future.delayed(Duration.zero);

        // Then: 크래시 없이 실행 완료
        expect(true, isTrue);
      });

      test('_refreshCategoriesQuietly에서 getCategories가 실패해도 에러가 무시된다', () async {
        // Given
        const testLedgerId = 'test-ledger-id';
        final mockChannel = MockRealtimeChannel();
        void Function()? capturedCallback;

        when(() => mockChannel.unsubscribe())
            .thenAnswer((_) async => 'ok');

        when(
          () => mockRepository.subscribeCategories(
            ledgerId: testLedgerId,
            onCategoryChanged: any(named: 'onCategoryChanged'),
          ),
        ).thenAnswer((invocation) {
          capturedCallback =
              invocation.namedArguments[const Symbol('onCategoryChanged')]
                  as void Function();
          return mockChannel;
        });

        var callCount = 0;
        when(() => mockRepository.getCategories(testLedgerId)).thenAnswer((_) async {
          callCount++;
          if (callCount > 1) throw Exception('네트워크 오류');
          return [];
        });

        container = createContainer(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => testLedgerId),
            categoryRepositoryProvider.overrideWith((ref) => mockRepository),
          ],
        );

        container.read(categoryNotifierProvider.notifier);
        await Future.delayed(Duration.zero);

        expect(capturedCallback, isNotNull);

        // When: 콜백 호출로 _refreshCategoriesQuietly 실행 (내부에서 에러 발생)
        capturedCallback!();
        await Future.delayed(Duration.zero);

        // Then: 예외 없이 완료 (_refreshCategoriesQuietly에서 에러 무시됨)
        expect(true, isTrue);
      });
    });

    group('CategoryNotifier - loadCategories null ledgerId 분기', () {
      test('ledgerId가 null인 상태에서 loadCategories 호출 시 빈 리스트 상태가 된다', () async {
        // Given: ledgerId null로 초기화
        container = createContainer(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => null),
            categoryRepositoryProvider.overrideWith((ref) => mockRepository),
          ],
        );

        final notifier = container.read(categoryNotifierProvider.notifier);

        // When: ledgerId가 null인 상태에서 직접 loadCategories 호출
        await notifier.loadCategories();

        // Then: 빈 데이터 상태 반환 (getCategories 호출 없음)
        final state = container.read(categoryNotifierProvider);
        expect(state.hasValue, isTrue);
        expect(state.value, isEmpty);
        verifyNever(() => mockRepository.getCategories(any()));
      });
    });

    group('categoryRepositoryProvider', () {
      test('categoryRepositoryProvider를 override하면 mock을 반환한다', () {
        // Given: Supabase 초기화 없이 mock으로 override
        container = createContainer(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => null),
            categoryRepositoryProvider.overrideWith((ref) => mockRepository),
          ],
        );

        // When
        final repository = container.read(categoryRepositoryProvider);

        // Then
        expect(repository, isA<CategoryRepository>());
        expect(repository, same(mockRepository));
      });
    });
  });
}
