import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_household_account/features/ledger/presentation/providers/ledger_provider.dart';
import 'package:shared_household_account/features/payment_method/data/repositories/payment_method_repository.dart';
import 'package:shared_household_account/features/payment_method/presentation/providers/payment_method_provider.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  group('PaymentMethodProvider Tests', () {
    late MockPaymentMethodRepository mockRepository;
    late ProviderContainer container;

    setUp(() {
      mockRepository = MockPaymentMethodRepository();
    });

    tearDown(() {
      container.dispose();
    });

    test('paymentMethodRepositoryProvider는 PaymentMethodRepository 인스턴스를 제공한다', () {
      // Given
      container = createContainer(
        overrides: [
          paymentMethodRepositoryProvider.overrideWith((ref) => mockRepository),
        ],
      );

      // When
      final repository = container.read(paymentMethodRepositoryProvider);

      // Then
      expect(repository, isA<PaymentMethodRepository>());
    });

    // 복잡한 테스트는 통합 테스트에서 검증
  });
}
