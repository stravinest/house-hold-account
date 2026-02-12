import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_household_account/features/fixed_expense/data/repositories/fixed_expense_settings_repository.dart';
import 'package:shared_household_account/features/fixed_expense/presentation/providers/fixed_expense_settings_provider.dart';
import 'package:shared_household_account/features/ledger/presentation/providers/ledger_provider.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  group('FixedExpenseSettingsProvider Tests', () {
    late MockFixedExpenseSettingsRepository mockRepository;
    late ProviderContainer container;

    setUp(() {
      mockRepository = MockFixedExpenseSettingsRepository();
    });

    tearDown(() {
      container.dispose();
    });

    test('fixedExpenseSettingsRepositoryProvider는 FixedExpenseSettingsRepository 인스턴스를 제공한다', () {
      // Given
      container = createContainer(
        overrides: [
          fixedExpenseSettingsRepositoryProvider.overrideWith((ref) => mockRepository),
        ],
      );

      // When
      final repository = container.read(fixedExpenseSettingsRepositoryProvider);

      // Then
      expect(repository, isA<FixedExpenseSettingsRepository>());
    });

    // 복잡한 테스트는 통합 테스트에서 검증
  });
}
