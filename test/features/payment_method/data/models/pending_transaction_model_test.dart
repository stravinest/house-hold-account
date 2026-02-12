import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/payment_method/data/models/pending_transaction_model.dart';
import 'package:shared_household_account/features/payment_method/domain/entities/pending_transaction.dart';

void main() {
  group('PendingTransactionModel', () {
    final testSourceTimestamp = DateTime(2026, 2, 12, 10, 0, 0);
    final testCreatedAt = DateTime(2026, 2, 12, 10, 5, 0);
    final testUpdatedAt = DateTime(2026, 2, 12, 10, 10, 0);
    final testExpiresAt = DateTime(2026, 2, 19, 10, 0, 0);
    final testParsedDate = DateTime(2026, 2, 12);

    final pendingTransactionModel = PendingTransactionModel(
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
      isViewed: false,
      createdAt: testCreatedAt,
      updatedAt: testUpdatedAt,
      expiresAt: testExpiresAt,
    );

    test('PendingTransaction 엔티티를 확장한다', () {
      expect(pendingTransactionModel, isA<PendingTransaction>());
    });

    group('fromJson', () {
      test('JSON에서 올바르게 역직렬화된다', () {
        final json = {
          'id': 'json-id',
          'ledger_id': 'ledger-id',
          'payment_method_id': 'payment-method-id',
          'user_id': 'user-id',
          'source_type': 'sms',
          'source_sender': 'KB카드',
          'source_content': '[Web발신]\n승인 10,000원',
          'source_timestamp': '2026-02-12T10:00:00.000',
          'parsed_amount': 10000,
          'parsed_type': 'expense',
          'parsed_merchant': '스타벅스',
          'parsed_category_id': 'category-id',
          'parsed_date': '2026-02-12',
          'status': 'pending',
          'transaction_id': null,
          'duplicate_hash': 'hash123',
          'is_duplicate': false,
          'is_viewed': false,
          'created_at': '2026-02-12T10:05:00.000',
          'updated_at': '2026-02-12T10:10:00.000',
          'expires_at': '2026-02-19T10:00:00.000',
        };

        final result = PendingTransactionModel.fromJson(json);

        expect(result.id, 'json-id');
        expect(result.ledgerId, 'ledger-id');
        expect(result.paymentMethodId, 'payment-method-id');
        expect(result.userId, 'user-id');
        expect(result.sourceType, SourceType.sms);
        expect(result.sourceSender, 'KB카드');
        expect(result.sourceContent, '[Web발신]\n승인 10,000원');
        expect(result.parsedAmount, 10000);
        expect(result.parsedType, 'expense');
        expect(result.parsedMerchant, '스타벅스');
        expect(result.parsedCategoryId, 'category-id');
        expect(result.parsedDate, isNotNull);
        expect(result.status, PendingTransactionStatus.pending);
        expect(result.isDuplicate, false);
        expect(result.isViewed, false);
      });

      test('notification 타입을 역직렬화한다', () {
        final json = {
          'id': 'json-id',
          'ledger_id': 'ledger-id',
          'user_id': 'user-id',
          'source_type': 'notification',
          'source_content': 'push content',
          'source_timestamp': '2026-02-12T10:00:00.000',
          'status': 'pending',
          'created_at': '2026-02-12T10:05:00.000',
          'updated_at': '2026-02-12T10:10:00.000',
          'expires_at': '2026-02-19T10:00:00.000',
        };

        final result = PendingTransactionModel.fromJson(json);

        expect(result.sourceType, SourceType.notification);
      });

      test('다양한 상태를 역직렬화한다', () {
        final statuses = ['pending', 'confirmed', 'rejected', 'converted'];
        final expected = [
          PendingTransactionStatus.pending,
          PendingTransactionStatus.confirmed,
          PendingTransactionStatus.rejected,
          PendingTransactionStatus.converted,
        ];

        for (var i = 0; i < statuses.length; i++) {
          final json = {
            'id': 'json-id',
            'ledger_id': 'ledger-id',
            'user_id': 'user-id',
            'source_type': 'sms',
            'source_content': 'content',
            'source_timestamp': '2026-02-12T10:00:00.000',
            'status': statuses[i],
            'created_at': '2026-02-12T10:05:00.000',
            'updated_at': '2026-02-12T10:10:00.000',
            'expires_at': '2026-02-19T10:00:00.000',
          };

          final result = PendingTransactionModel.fromJson(json);
          expect(result.status, expected[i]);
        }
      });

      test('null 값들을 올바르게 처리한다', () {
        final json = {
          'id': 'json-id',
          'ledger_id': 'ledger-id',
          'payment_method_id': null,
          'user_id': 'user-id',
          'source_type': 'sms',
          'source_sender': null,
          'source_content': 'content',
          'source_timestamp': '2026-02-12T10:00:00.000',
          'parsed_amount': null,
          'parsed_type': null,
          'parsed_merchant': null,
          'parsed_category_id': null,
          'parsed_date': null,
          'status': 'pending',
          'transaction_id': null,
          'duplicate_hash': null,
          'is_duplicate': null,
          'is_viewed': null,
          'created_at': '2026-02-12T10:05:00.000',
          'updated_at': '2026-02-12T10:10:00.000',
          'expires_at': '2026-02-19T10:00:00.000',
        };

        final result = PendingTransactionModel.fromJson(json);

        expect(result.paymentMethodId, null);
        expect(result.sourceSender, null);
        expect(result.parsedAmount, null);
        expect(result.parsedType, null);
        expect(result.parsedMerchant, null);
        expect(result.parsedCategoryId, null);
        expect(result.parsedDate, null);
        expect(result.transactionId, null);
        expect(result.duplicateHash, null);
        expect(result.isDuplicate, false);
        expect(result.isViewed, false);
      });

      test('parsedDate를 로컬 날짜로 파싱한다', () {
        final json = {
          'id': 'json-id',
          'ledger_id': 'ledger-id',
          'user_id': 'user-id',
          'source_type': 'sms',
          'source_content': 'content',
          'source_timestamp': '2026-02-12T10:00:00.000',
          'parsed_date': '2026-03-15',
          'status': 'pending',
          'created_at': '2026-02-12T10:05:00.000',
          'updated_at': '2026-02-12T10:10:00.000',
          'expires_at': '2026-02-19T10:00:00.000',
        };

        final result = PendingTransactionModel.fromJson(json);

        expect(result.parsedDate, isNotNull);
        expect(result.parsedDate!.year, 2026);
        expect(result.parsedDate!.month, 3);
        expect(result.parsedDate!.day, 15);
      });
    });

    group('toJson', () {
      test('JSON으로 올바르게 직렬화된다', () {
        final json = pendingTransactionModel.toJson();

        expect(json['id'], 'test-id');
        expect(json['ledger_id'], 'ledger-id');
        expect(json['payment_method_id'], 'payment-method-id');
        expect(json['user_id'], 'user-id');
        expect(json['source_type'], 'sms');
        expect(json['source_sender'], 'KB카드');
        expect(json['source_content'], '[Web발신]\n승인 10,000원\n신한카드\n스타벅스');
        expect(json['source_timestamp'], isA<String>());
        expect(json['parsed_amount'], 10000);
        expect(json['parsed_type'], 'expense');
        expect(json['parsed_merchant'], '스타벅스');
        expect(json['parsed_category_id'], 'category-id');
        expect(json['parsed_date'], '2026-02-12');
        expect(json['status'], 'pending');
        expect(json['transaction_id'], null);
        expect(json['duplicate_hash'], 'hash123');
        expect(json['is_duplicate'], false);
        expect(json['is_viewed'], false);
        expect(json['created_at'], isA<String>());
        expect(json['updated_at'], isA<String>());
        expect(json['expires_at'], isA<String>());
      });

      test('null 값들을 올바르게 직렬화한다', () {
        final model = PendingTransactionModel(
          id: 'test-id',
          ledgerId: 'ledger-id',
          userId: 'user-id',
          sourceType: SourceType.sms,
          sourceContent: 'content',
          sourceTimestamp: testSourceTimestamp,
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
          expiresAt: testExpiresAt,
        );

        final json = model.toJson();

        expect(json['payment_method_id'], null);
        expect(json['source_sender'], null);
        expect(json['parsed_amount'], null);
        expect(json['parsed_type'], null);
        expect(json['parsed_merchant'], null);
        expect(json['parsed_category_id'], null);
        expect(json['parsed_date'], null);
        expect(json['transaction_id'], null);
        expect(json['duplicate_hash'], null);
      });

      test('parsedDate를 로컬 날짜 형식으로 직렬화한다', () {
        final model = PendingTransactionModel(
          id: 'test-id',
          ledgerId: 'ledger-id',
          userId: 'user-id',
          sourceType: SourceType.sms,
          sourceContent: 'content',
          sourceTimestamp: testSourceTimestamp,
          parsedDate: DateTime(2026, 3, 15, 14, 30, 0),
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
          expiresAt: testExpiresAt,
        );

        final json = model.toJson();

        expect(json['parsed_date'], '2026-03-15');
      });
    });

    group('toCreateJson', () {
      test('생성용 JSON을 올바르게 만든다', () {
        final json = PendingTransactionModel.toCreateJson(
          ledgerId: 'ledger-id',
          paymentMethodId: 'payment-method-id',
          userId: 'user-id',
          sourceType: SourceType.sms,
          sourceSender: 'KB카드',
          sourceContent: '[Web발신]\n승인 10,000원',
          sourceTimestamp: testSourceTimestamp,
          parsedAmount: 10000,
          parsedType: 'expense',
          parsedMerchant: '스타벅스',
          parsedCategoryId: 'category-id',
          parsedDate: testParsedDate,
          duplicateHash: 'hash123',
        );

        expect(json['ledger_id'], 'ledger-id');
        expect(json['payment_method_id'], 'payment-method-id');
        expect(json['user_id'], 'user-id');
        expect(json['source_type'], 'sms');
        expect(json['source_sender'], 'KB카드');
        expect(json['source_content'], '[Web발신]\n승인 10,000원');
        expect(json['source_timestamp'], isA<String>());
        expect(json['parsed_amount'], 10000);
        expect(json['parsed_type'], 'expense');
        expect(json['parsed_merchant'], '스타벅스');
        expect(json['parsed_category_id'], 'category-id');
        expect(json['parsed_date'], '2026-02-12');
        expect(json['duplicate_hash'], 'hash123');
        expect(json['is_duplicate'], false);
        expect(json['is_viewed'], false);
      });

      test('기본값이 올바르게 설정된다', () {
        final json = PendingTransactionModel.toCreateJson(
          ledgerId: 'ledger-id',
          userId: 'user-id',
          sourceType: SourceType.sms,
          sourceContent: 'content',
          sourceTimestamp: testSourceTimestamp,
        );

        expect(json['is_duplicate'], false);
        expect(json['is_viewed'], false);
      });

      test('선택적 필드들을 포함할 수 있다', () {
        final json = PendingTransactionModel.toCreateJson(
          ledgerId: 'ledger-id',
          userId: 'user-id',
          sourceType: SourceType.notification,
          sourceContent: 'content',
          sourceTimestamp: testSourceTimestamp,
          status: PendingTransactionStatus.confirmed,
          isDuplicate: true,
          isViewed: true,
        );

        expect(json['source_type'], 'notification');
        expect(json['status'], 'confirmed');
        expect(json['is_duplicate'], true);
        expect(json['is_viewed'], true);
      });

      test('null 필드들은 JSON에 포함되지 않는다', () {
        final json = PendingTransactionModel.toCreateJson(
          ledgerId: 'ledger-id',
          userId: 'user-id',
          sourceType: SourceType.sms,
          sourceContent: 'content',
          sourceTimestamp: testSourceTimestamp,
        );

        expect(json.containsKey('payment_method_id'), false);
        expect(json.containsKey('source_sender'), false);
        expect(json.containsKey('parsed_amount'), false);
        expect(json.containsKey('parsed_type'), false);
        expect(json.containsKey('parsed_merchant'), false);
        expect(json.containsKey('parsed_category_id'), false);
        expect(json.containsKey('parsed_date'), false);
        expect(json.containsKey('duplicate_hash'), false);
      });
    });

    group('toUpdateStatusJson', () {
      test('상태 업데이트 JSON을 올바르게 만든다', () {
        final json = PendingTransactionModel.toUpdateStatusJson(
          status: PendingTransactionStatus.confirmed,
          transactionId: 'transaction-123',
        );

        expect(json['status'], 'confirmed');
        expect(json['transaction_id'], 'transaction-123');
        expect(json['updated_at'], isA<String>());
      });

      test('transactionId 없이 상태만 업데이트할 수 있다', () {
        final json = PendingTransactionModel.toUpdateStatusJson(
          status: PendingTransactionStatus.rejected,
        );

        expect(json['status'], 'rejected');
        expect(json['updated_at'], isA<String>());
        expect(json.containsKey('transaction_id'), false);
      });

      test('다양한 상태를 업데이트할 수 있다', () {
        final statuses = [
          PendingTransactionStatus.pending,
          PendingTransactionStatus.confirmed,
          PendingTransactionStatus.rejected,
          PendingTransactionStatus.converted,
        ];

        for (var status in statuses) {
          final json = PendingTransactionModel.toUpdateStatusJson(
            status: status,
          );

          expect(json['status'], status.toJson());
        }
      });
    });

    group('fromJson -> toJson 왕복 변환', () {
      test('데이터가 손실 없이 변환된다', () {
        final originalJson = {
          'id': 'test-id',
          'ledger_id': 'ledger-id',
          'payment_method_id': 'payment-method-id',
          'user_id': 'user-id',
          'source_type': 'sms',
          'source_sender': 'KB카드',
          'source_content': '[Web발신]',
          'source_timestamp': '2026-02-12T10:00:00.000Z',
          'parsed_amount': 10000,
          'parsed_type': 'expense',
          'parsed_merchant': '스타벅스',
          'parsed_category_id': 'category-id',
          'parsed_date': '2026-02-12',
          'status': 'pending',
          'transaction_id': null,
          'duplicate_hash': 'hash123',
          'is_duplicate': false,
          'is_viewed': false,
          'created_at': '2026-02-12T10:05:00.000Z',
          'updated_at': '2026-02-12T10:10:00.000Z',
          'expires_at': '2026-02-19T10:00:00.000Z',
        };

        final model = PendingTransactionModel.fromJson(originalJson);
        final convertedJson = model.toJson();

        expect(convertedJson['id'], originalJson['id']);
        expect(convertedJson['ledger_id'], originalJson['ledger_id']);
        expect(convertedJson['user_id'], originalJson['user_id']);
        expect(convertedJson['source_type'], originalJson['source_type']);
        expect(convertedJson['parsed_amount'], originalJson['parsed_amount']);
        expect(convertedJson['status'], originalJson['status']);
      });
    });

    group('엣지 케이스', () {
      test('빈 문자열을 올바르게 처리한다', () {
        final json = {
          'id': 'test-id',
          'ledger_id': 'ledger-id',
          'user_id': 'user-id',
          'source_type': 'sms',
          'source_sender': '',
          'source_content': '',
          'source_timestamp': '2026-02-12T10:00:00.000',
          'parsed_merchant': '',
          'status': 'pending',
          'created_at': '2026-02-12T10:05:00.000',
          'updated_at': '2026-02-12T10:10:00.000',
          'expires_at': '2026-02-19T10:00:00.000',
        };

        final result = PendingTransactionModel.fromJson(json);

        expect(result.sourceSender, '');
        expect(result.sourceContent, '');
        expect(result.parsedMerchant, '');
      });

      test('매우 큰 금액을 처리할 수 있다', () {
        final json = PendingTransactionModel.toCreateJson(
          ledgerId: 'ledger-id',
          userId: 'user-id',
          sourceType: SourceType.sms,
          sourceContent: 'content',
          sourceTimestamp: testSourceTimestamp,
          parsedAmount: 999999999,
        );

        expect(json['parsed_amount'], 999999999);
      });

      test('매우 긴 sourceContent를 처리할 수 있다', () {
        final longContent = '[Web발신]\n' * 100;
        final json = PendingTransactionModel.toCreateJson(
          ledgerId: 'ledger-id',
          userId: 'user-id',
          sourceType: SourceType.sms,
          sourceContent: longContent,
          sourceTimestamp: testSourceTimestamp,
        );

        expect(json['source_content'], longContent);
      });
    });
  });
}
