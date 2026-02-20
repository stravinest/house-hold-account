import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_household_account/features/category/data/models/category_model.dart';
import 'package:shared_household_account/features/category/presentation/providers/category_provider.dart';
import 'package:shared_household_account/features/ledger/presentation/providers/ledger_provider.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  group('CategoryNotifier.updateCategory 반환값 테스트', () {
    late MockCategoryRepository mockRepository;
    late ProviderContainer container;

    const testLedgerId = 'test-ledger-id';

    setUp(() {
      mockRepository = MockCategoryRepository();
    });

    tearDown(() {
      container.dispose();
    });

    test('updateCategory 성공 시 서버 응답 카테고리를 반환한다', () async {
      // Given
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

      // Then - 서버 응답 값을 그대로 반환하는지 확인
      expect(result.id, equals('cat-1'));
      expect(result.name, equals('수정된 카테고리'));
      expect(result.icon, equals('shopping_cart'));
      expect(result.color, equals('#E91E63'));
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

    test('updateCategory가 서버 응답의 정확한 데이터를 반환하는지 확인한다 (copyWith가 아닌 서버 응답)', () async {
      // Given - 서버에서 name을 trim 처리하여 다른 값을 반환하는 시나리오
      final serverResponse = CategoryModel(
        id: 'cat-1',
        ledgerId: testLedgerId,
        name: '서버에서 정규화된 이름',
        icon: 'star',
        color: '#FF0000',
        type: 'expense',
        isDefault: true, // 서버에서 isDefault가 변경될 수 있음
        sortOrder: 5,    // 서버에서 sortOrder가 다를 수 있음
        createdAt: DateTime(2026, 1, 1),
      );

      when(
        () => mockRepository.updateCategory(
          id: 'cat-1',
          name: '  서버에서 정규화된 이름  ',
          icon: 'star',
          color: '#FF0000',
        ),
      ).thenAnswer((_) async => serverResponse);

      when(() => mockRepository.getCategories(testLedgerId))
          .thenAnswer((_) async => [serverResponse]);

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
        name: '  서버에서 정규화된 이름  ',
        icon: 'star',
        color: '#FF0000',
      );

      // Then - copyWith와 달리 서버 응답의 isDefault, sortOrder 등이 정확히 반영됨
      expect(result.name, equals('서버에서 정규화된 이름'));
      expect(result.isDefault, isTrue);
      expect(result.sortOrder, equals(5));
      expect(result.createdAt, equals(DateTime(2026, 1, 1)));
    });
  });
}
