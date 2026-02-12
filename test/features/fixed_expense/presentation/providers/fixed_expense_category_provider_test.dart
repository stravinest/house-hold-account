import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_household_account/features/fixed_expense/data/repositories/fixed_expense_category_repository.dart';
import 'package:shared_household_account/features/fixed_expense/presentation/providers/fixed_expense_category_provider.dart';
import 'package:shared_household_account/features/ledger/presentation/providers/ledger_provider.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  group('FixedExpenseCategoryProvider Tests', () {
    late MockFixedExpenseCategoryRepository mockRepository;
    late ProviderContainer container;

    setUp(() {
      mockRepository = MockFixedExpenseCategoryRepository();
    });

    tearDown(() {
      container.dispose();
    });

    test('fixedExpenseCategoryRepositoryProvider는 FixedExpenseCategoryRepository 인스턴스를 제공한다', () {
      // Given
      container = createContainer(
        overrides: [
          fixedExpenseCategoryRepositoryProvider.overrideWith((ref) => mockRepository),
        ],
      );

      // When
      final repository = container.read(fixedExpenseCategoryRepositoryProvider);

      // Then
      expect(repository, isA<FixedExpenseCategoryRepository>());
    });

    // 복잡한 테스트는 통합 테스트에서 검증
  });
}
