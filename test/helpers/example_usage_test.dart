import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'test_helpers.dart';

/// 테스트 헬퍼 사용 예시를 보여주는 테스트
void main() {
  group('테스트 헬퍼 사용 예시', () {
    test('TestDataFactory를 사용하여 Ledger 생성할 수 있다', () {
      // Given: TestDataFactory로 테스트 데이터 생성
      final ledger = TestDataFactory.ledger(
        name: '나의 가계부',
        currency: 'KRW',
      );

      // Then: 생성된 데이터 검증
      expect(ledger.name, equals('나의 가계부'));
      expect(ledger.currency, equals('KRW'));
      expect(ledger.id, equals('test-ledger-id'));
    });

    test('TestDataFactory를 사용하여 Transaction 생성할 수 있다', () {
      // Given: TestDataFactory로 거래 데이터 생성
      final transaction = TestDataFactory.transaction(
        amount: 50000,
        type: 'expense',
        title: '점심 식사',
      );

      // Then: 생성된 데이터 검증
      expect(transaction.amount, equals(50000));
      expect(transaction.type, equals('expense'));
      expect(transaction.title, equals('점심 식사'));
      expect(transaction.isExpense, isTrue);
    });

    test('TestDataFactory를 사용하여 여러 거래 목록을 생성할 수 있다', () {
      // Given: 5개의 거래 목록 생성
      final transactions = TestDataFactory.transactions(count: 5);

      // Then: 5개가 생성되고 각각 다른 금액을 가진다
      expect(transactions.length, equals(5));
      expect(transactions[0].amount, equals(10000));
      expect(transactions[1].amount, equals(20000));
      expect(transactions[4].amount, equals(50000));
    });

    test('TestDataFactory를 사용하여 Category 생성할 수 있다', () {
      // Given: 카테고리 생성
      final category = TestDataFactory.category(
        name: '교통비',
        icon: '🚗',
        type: 'expense',
      );

      // Then: 생성된 데이터 검증
      expect(category.name, equals('교통비'));
      expect(category.icon, equals('🚗'));
      expect(category.isExpense, isTrue);
    });

    test('TestDataFactory를 사용하여 PaymentMethod 생성할 수 있다', () {
      // Given: 결제수단 생성
      final paymentMethod = TestDataFactory.paymentMethod(
        name: 'KB카드',
        canAutoSave: true,
      );

      // Then: 생성된 데이터 검증
      expect(paymentMethod.name, equals('KB카드'));
      expect(paymentMethod.canAutoSave, isTrue);
    });

    test('Mock Repository를 사용할 수 있다', () {
      // Given: Mock Repository 생성
      final mockLedgerRepo = MockLedgerRepository();

      // When: stub 설정
      when(() => mockLedgerRepo.getLedger('test-id'))
          .thenAnswer((_) async => TestDataFactory.ledgerModel());

      // Then: Mock이 정상 동작
      expect(mockLedgerRepo, isA<MockLedgerRepository>());
    });

    test('Mock Service를 사용할 수 있다', () {
      // Given: Mock Service 생성
      final mockSmsParsingService = MockSmsParsingService();

      // Then: Mock이 정상 동작
      expect(mockSmsParsingService, isA<MockSmsParsingService>());
    });

    test('createContainer로 ProviderContainer를 생성할 수 있다', () {
      // Given: ProviderContainer 생성
      final container = createContainer();

      // Then: 컨테이너가 정상 생성됨
      expect(container, isA<ProviderContainer>());

      // Cleanup
      container.dispose();
    });

    test('AsyncValueTestHelpers를 사용하여 AsyncValue 상태를 검증할 수 있다', () {
      // Given: AsyncValue 생성
      final dataValue = AsyncValueTestHelpers.data(42);
      final loadingValue = AsyncValueTestHelpers.loading<int>();
      final errorValue =
          AsyncValueTestHelpers.error<int>(Exception('테스트 에러'));

      // Then: 상태 확인
      expect(AsyncValueTestHelpers.isData(dataValue), isTrue);
      expect(AsyncValueTestHelpers.isLoading(loadingValue), isTrue);
      expect(AsyncValueTestHelpers.isError(errorValue), isTrue);
    });

    test('ProviderListener를 사용하여 Provider 값 변화를 추적할 수 있다', () {
      // Given: ProviderListener 생성
      final listener = ProviderListener<int>();

      // When: 값 변화 기록
      listener(null, 1);
      listener(1, 2);
      listener(2, 3);

      // Then: 변화 기록 확인
      expect(listener.callCount, equals(3));
      expect(listener.latest, equals(3));
      expect(listener.values, equals([1, 2, 3]));

      // When: 리셋
      listener.reset();

      // Then: 초기화됨
      expect(listener.callCount, equals(0));
      expect(listener.latest, isNull);
    });
  });
}
