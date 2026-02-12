import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_household_account/features/ledger/presentation/providers/ledger_provider.dart';
import 'package:shared_household_account/features/payment_method/data/repositories/pending_transaction_repository.dart';
import 'package:shared_household_account/features/payment_method/presentation/providers/pending_transaction_provider.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  group('PendingTransactionProvider Tests', () {
    late MockPendingTransactionRepository mockRepository;
    late ProviderContainer container;

    setUp(() {
      mockRepository = MockPendingTransactionRepository();
    });

    tearDown(() {
      container.dispose();
    });

    test('pendingTransactionRepositoryProvider는 PendingTransactionRepository 인스턴스를 제공한다', () {
      // Given
      container = createContainer(
        overrides: [
          pendingTransactionRepositoryProvider.overrideWith((ref) => mockRepository),
        ],
      );

      // When
      final repository = container.read(pendingTransactionRepositoryProvider);

      // Then
      expect(repository, isA<PendingTransactionRepository>());
    });

    // 복잡한 테스트는 통합 테스트에서 검증
  });
}
