import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_household_account/features/payment_method/data/models/payment_method_model.dart';
import 'package:shared_household_account/features/payment_method/domain/entities/payment_method.dart';
import 'package:shared_household_account/features/payment_method/presentation/providers/payment_method_provider.dart';
import 'package:shared_household_account/features/ledger/presentation/providers/ledger_provider.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  group('PaymentMethodNotifier.updatePaymentMethod 반환값 테스트', () {
    late MockPaymentMethodRepository mockRepository;
    late ProviderContainer container;

    const testLedgerId = 'test-ledger-id';

    setUp(() {
      mockRepository = MockPaymentMethodRepository();
    });

    tearDown(() {
      container.dispose();
    });

    test('updatePaymentMethod 성공 시 서버 응답 결제수단을 반환한다', () async {
      // Given
      final updatedMethod = PaymentMethodModel(
        id: 'pm-1',
        ledgerId: testLedgerId,
        ownerUserId: 'user-1',
        name: '수정된 카드',
        icon: 'credit_card',
        color: '#2196F3',
        isDefault: false,
        sortOrder: 0,
        autoSaveMode: AutoSaveMode.manual,
        canAutoSave: false,
        autoCollectSource: AutoCollectSource.sms,
        createdAt: DateTime.now(),
      );

      when(
        () => mockRepository.updatePaymentMethod(
          id: 'pm-1',
          name: '수정된 카드',
          icon: 'credit_card',
          color: '#2196F3',
        ),
      ).thenAnswer((_) async => updatedMethod);

      when(() => mockRepository.getPaymentMethods(testLedgerId))
          .thenAnswer((_) async => [updatedMethod]);

      container = createContainer(
        overrides: [
          selectedLedgerIdProvider.overrideWith((ref) => testLedgerId),
          paymentMethodRepositoryProvider.overrideWith(
            (ref) => mockRepository,
          ),
        ],
      );

      final notifier = container.read(paymentMethodNotifierProvider.notifier);

      // When
      final result = await notifier.updatePaymentMethod(
        id: 'pm-1',
        name: '수정된 카드',
        icon: 'credit_card',
        color: '#2196F3',
      );

      // Then - 서버 응답 값을 그대로 반환하는지 확인
      expect(result.id, equals('pm-1'));
      expect(result.name, equals('수정된 카드'));
      expect(result.icon, equals('credit_card'));
      expect(result.color, equals('#2196F3'));
      verify(
        () => mockRepository.updatePaymentMethod(
          id: 'pm-1',
          name: '수정된 카드',
          icon: 'credit_card',
          color: '#2196F3',
        ),
      ).called(1);
    });

    test('updatePaymentMethod 실패 시 예외를 전파한다', () async {
      // Given
      when(
        () => mockRepository.updatePaymentMethod(
          id: any(named: 'id'),
          name: any(named: 'name'),
          icon: any(named: 'icon'),
          color: any(named: 'color'),
        ),
      ).thenThrow(Exception('서버 에러'));

      when(() => mockRepository.getPaymentMethods(testLedgerId))
          .thenAnswer((_) async => []);

      container = createContainer(
        overrides: [
          selectedLedgerIdProvider.overrideWith((ref) => testLedgerId),
          paymentMethodRepositoryProvider.overrideWith(
            (ref) => mockRepository,
          ),
        ],
      );

      final notifier = container.read(paymentMethodNotifierProvider.notifier);

      // When & Then
      expect(
        () => notifier.updatePaymentMethod(
          id: 'pm-1',
          name: '실패 테스트',
          icon: 'error',
          color: '#000000',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('updatePaymentMethod가 서버 응답의 정확한 데이터를 반환하는지 확인한다', () async {
      // Given - 서버에서 추가 필드가 다를 수 있는 시나리오
      final serverResponse = PaymentMethodModel(
        id: 'pm-1',
        ledgerId: testLedgerId,
        ownerUserId: 'user-1',
        name: '서버 응답 카드',
        icon: 'account_balance',
        color: '#4CAF50',
        isDefault: true,   // 서버에서 default 상태가 변경될 수 있음
        sortOrder: 3,       // 서버에서 정렬 순서가 다를 수 있음
        autoSaveMode: AutoSaveMode.manual,
        canAutoSave: false,
        autoCollectSource: AutoCollectSource.sms,
        createdAt: DateTime(2026, 1, 1),
      );

      when(
        () => mockRepository.updatePaymentMethod(
          id: 'pm-1',
          name: '서버 응답 카드',
          icon: 'account_balance',
          color: '#4CAF50',
        ),
      ).thenAnswer((_) async => serverResponse);

      when(() => mockRepository.getPaymentMethods(testLedgerId))
          .thenAnswer((_) async => [serverResponse]);

      container = createContainer(
        overrides: [
          selectedLedgerIdProvider.overrideWith((ref) => testLedgerId),
          paymentMethodRepositoryProvider.overrideWith(
            (ref) => mockRepository,
          ),
        ],
      );

      final notifier = container.read(paymentMethodNotifierProvider.notifier);

      // When
      final result = await notifier.updatePaymentMethod(
        id: 'pm-1',
        name: '서버 응답 카드',
        icon: 'account_balance',
        color: '#4CAF50',
      );

      // Then - 서버 응답의 모든 필드가 정확히 반영됨
      expect(result.name, equals('서버 응답 카드'));
      expect(result.isDefault, isTrue);
      expect(result.sortOrder, equals(3));
      expect(result.createdAt, equals(DateTime(2026, 1, 1)));
    });
  });
}
