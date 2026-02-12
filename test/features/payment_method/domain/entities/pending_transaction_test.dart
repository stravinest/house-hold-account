import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/payment_method/domain/entities/pending_transaction.dart';

void main() {
  group('PendingTransactionStatus', () {
    test('fromString은 올바른 상태를 반환한다', () {
      expect(
        PendingTransactionStatus.fromString('confirmed'),
        PendingTransactionStatus.confirmed,
      );
      expect(
        PendingTransactionStatus.fromString('rejected'),
        PendingTransactionStatus.rejected,
      );
      expect(
        PendingTransactionStatus.fromString('converted'),
        PendingTransactionStatus.converted,
      );
      expect(
        PendingTransactionStatus.fromString('pending'),
        PendingTransactionStatus.pending,
      );
    });

    test('fromString은 알 수 없는 값에 대해 pending을 반환한다', () {
      expect(
        PendingTransactionStatus.fromString('unknown'),
        PendingTransactionStatus.pending,
      );
      expect(
        PendingTransactionStatus.fromString(''),
        PendingTransactionStatus.pending,
      );
    });

    test('toJson은 enum name을 반환한다', () {
      expect(PendingTransactionStatus.pending.toJson(), 'pending');
      expect(PendingTransactionStatus.confirmed.toJson(), 'confirmed');
      expect(PendingTransactionStatus.rejected.toJson(), 'rejected');
      expect(PendingTransactionStatus.converted.toJson(), 'converted');
    });
  });

  group('SourceType', () {
    test('fromString은 올바른 타입을 반환한다', () {
      expect(SourceType.fromString('sms'), SourceType.sms);
      expect(SourceType.fromString('notification'), SourceType.notification);
    });

    test('fromString은 알 수 없는 값에 대해 sms를 반환한다', () {
      expect(SourceType.fromString('unknown'), SourceType.sms);
      expect(SourceType.fromString(''), SourceType.sms);
    });

    test('toJson은 enum name을 반환한다', () {
      expect(SourceType.sms.toJson(), 'sms');
      expect(SourceType.notification.toJson(), 'notification');
    });
  });

  group('PendingTransaction', () {
    final testSourceTimestamp = DateTime(2026, 2, 12, 10, 0, 0);
    final testCreatedAt = DateTime(2026, 2, 12, 10, 5, 0);
    final testUpdatedAt = DateTime(2026, 2, 12, 10, 10, 0);
    final testExpiresAt = DateTime(2026, 2, 19, 10, 0, 0);
    final testParsedDate = DateTime(2026, 2, 12);

    final pendingTransaction = PendingTransaction(
      id: 'test-id',
      ledgerId: 'ledger-id',
      paymentMethodId: 'payment-method-id',
      userId: 'user-id',
      sourceType: SourceType.sms,
      sourceSender: 'KB카드',
      sourceContent: '[Web발신]\n승인 10,000원\n신한카드\n스타벅스',
      sourceTimestamp: testSourceTimestamp,
      parsedAmount: 10000,
      parsedType: 'expense',
      parsedMerchant: '스타벅스',
      parsedCategoryId: 'category-id',
      parsedDate: testParsedDate,
      status: PendingTransactionStatus.pending,
      transactionId: null,
      duplicateHash: 'hash123',
      isDuplicate: false,
      createdAt: testCreatedAt,
      updatedAt: testUpdatedAt,
      expiresAt: testExpiresAt,
      isViewed: false,
    );

    test('기본값이 올바르게 설정된다', () {
      final transaction = PendingTransaction(
        id: 'test-id',
        ledgerId: 'ledger-id',
        userId: 'user-id',
        sourceType: SourceType.sms,
        sourceContent: 'test content',
        sourceTimestamp: testSourceTimestamp,
        createdAt: testCreatedAt,
        updatedAt: testUpdatedAt,
        expiresAt: testExpiresAt,
      );

      expect(transaction.status, PendingTransactionStatus.pending);
      expect(transaction.isDuplicate, false);
      expect(transaction.isViewed, false);
    });

    group('getter 테스트', () {
      test('isParsed는 parsedAmount가 있을 때 true를 반환한다', () {
        expect(pendingTransaction.isParsed, true);

        final unparsed = PendingTransaction(
          id: 'test-id',
          ledgerId: 'ledger-id',
          userId: 'user-id',
          sourceType: SourceType.sms,
          sourceContent: 'test content',
          sourceTimestamp: testSourceTimestamp,
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
          expiresAt: testExpiresAt,
        );

        expect(unparsed.isParsed, false);
      });

      test('isExpense는 parsedType이 expense일 때 true를 반환한다', () {
        expect(pendingTransaction.isExpense, true);

        final income = pendingTransaction.copyWith(parsedType: 'income');
        expect(income.isExpense, false);
      });

      test('isIncome은 parsedType이 income일 때 true를 반환한다', () {
        final income = pendingTransaction.copyWith(parsedType: 'income');
        expect(income.isIncome, true);
        expect(pendingTransaction.isIncome, false);
      });
    });

    group('copyWith', () {
      test('특정 필드만 변경할 수 있다', () {
        final updated = pendingTransaction.copyWith(
          status: PendingTransactionStatus.confirmed,
          transactionId: 'transaction-123',
          isViewed: true,
        );

        expect(updated.status, PendingTransactionStatus.confirmed);
        expect(updated.transactionId, 'transaction-123');
        expect(updated.isViewed, true);
        expect(updated.id, pendingTransaction.id);
        expect(updated.ledgerId, pendingTransaction.ledgerId);
      });

      test('모든 필드를 변경할 수 있다', () {
        final newTimestamp = DateTime(2026, 2, 13);
        final updated = pendingTransaction.copyWith(
          id: 'new-id',
          ledgerId: 'new-ledger-id',
          paymentMethodId: 'new-payment-id',
          userId: 'new-user-id',
          sourceType: SourceType.notification,
          sourceSender: 'new-sender',
          sourceContent: 'new-content',
          sourceTimestamp: newTimestamp,
          parsedAmount: 20000,
          parsedType: 'income',
          parsedMerchant: 'new-merchant',
          parsedCategoryId: 'new-category-id',
          parsedDate: newTimestamp,
          status: PendingTransactionStatus.rejected,
          transactionId: 'new-transaction-id',
          duplicateHash: 'new-hash',
          isDuplicate: true,
          createdAt: newTimestamp,
          updatedAt: newTimestamp,
          expiresAt: newTimestamp,
          isViewed: true,
        );

        expect(updated.id, 'new-id');
        expect(updated.sourceType, SourceType.notification);
        expect(updated.parsedAmount, 20000);
        expect(updated.status, PendingTransactionStatus.rejected);
        expect(updated.isDuplicate, true);
      });

      test('인자를 제공하지 않으면 원본과 동일한 값을 유지한다', () {
        final copied = pendingTransaction.copyWith();

        expect(copied.id, pendingTransaction.id);
        expect(copied.ledgerId, pendingTransaction.ledgerId);
        expect(copied.userId, pendingTransaction.userId);
        expect(copied.parsedAmount, pendingTransaction.parsedAmount);
        expect(copied.status, pendingTransaction.status);
      });
    });

    group('Equatable', () {
      test('동일한 값을 가진 인스턴스는 같다', () {
        final transaction1 = PendingTransaction(
          id: 'test-id',
          ledgerId: 'ledger-id',
          userId: 'user-id',
          sourceType: SourceType.sms,
          sourceContent: 'test content',
          sourceTimestamp: testSourceTimestamp,
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
          expiresAt: testExpiresAt,
        );

        final transaction2 = PendingTransaction(
          id: 'test-id',
          ledgerId: 'ledger-id',
          userId: 'user-id',
          sourceType: SourceType.sms,
          sourceContent: 'test content',
          sourceTimestamp: testSourceTimestamp,
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
          expiresAt: testExpiresAt,
        );

        expect(transaction1, transaction2);
      });

      test('다른 값을 가진 인스턴스는 다르다', () {
        final transaction1 = pendingTransaction;
        final transaction2 = pendingTransaction.copyWith(id: 'different-id');

        expect(transaction1, isNot(transaction2));
      });
    });

    group('엣지 케이스', () {
      test('모든 nullable 필드가 null일 수 있다', () {
        final transaction = PendingTransaction(
          id: 'test-id',
          ledgerId: 'ledger-id',
          userId: 'user-id',
          sourceType: SourceType.sms,
          sourceContent: 'test content',
          sourceTimestamp: testSourceTimestamp,
          paymentMethodId: null,
          sourceSender: null,
          parsedAmount: null,
          parsedType: null,
          parsedMerchant: null,
          parsedCategoryId: null,
          parsedDate: null,
          transactionId: null,
          duplicateHash: null,
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
          expiresAt: testExpiresAt,
        );

        expect(transaction.paymentMethodId, null);
        expect(transaction.sourceSender, null);
        expect(transaction.parsedAmount, null);
        expect(transaction.isParsed, false);
      });

      test('빈 문자열 sourceContent를 처리할 수 있다', () {
        final transaction = PendingTransaction(
          id: 'test-id',
          ledgerId: 'ledger-id',
          userId: 'user-id',
          sourceType: SourceType.sms,
          sourceContent: '',
          sourceTimestamp: testSourceTimestamp,
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
          expiresAt: testExpiresAt,
        );

        expect(transaction.sourceContent, '');
      });

      test('매우 큰 parsedAmount를 처리할 수 있다', () {
        final transaction = pendingTransaction.copyWith(
          parsedAmount: 999999999,
        );

        expect(transaction.parsedAmount, 999999999);
      });

      test('다양한 SourceType을 지원한다', () {
        final smsTransaction = pendingTransaction.copyWith(
          sourceType: SourceType.sms,
        );
        final notificationTransaction = pendingTransaction.copyWith(
          sourceType: SourceType.notification,
        );

        expect(smsTransaction.sourceType, SourceType.sms);
        expect(notificationTransaction.sourceType, SourceType.notification);
      });

      test('모든 PendingTransactionStatus를 지원한다', () {
        final pending = pendingTransaction.copyWith(
          status: PendingTransactionStatus.pending,
        );
        final confirmed = pendingTransaction.copyWith(
          status: PendingTransactionStatus.confirmed,
        );
        final rejected = pendingTransaction.copyWith(
          status: PendingTransactionStatus.rejected,
        );
        final converted = pendingTransaction.copyWith(
          status: PendingTransactionStatus.converted,
        );

        expect(pending.status, PendingTransactionStatus.pending);
        expect(confirmed.status, PendingTransactionStatus.confirmed);
        expect(rejected.status, PendingTransactionStatus.rejected);
        expect(converted.status, PendingTransactionStatus.converted);
      });
    });
  });
}
