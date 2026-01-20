import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/payment_method/data/services/duplicate_check_service.dart';

/// Mock Supabase Client (테스트용)
class MockSupabaseClient {}

void main() {
  group('DuplicateCheckService', () {
    group('generateDuplicateHash', () {
      late DuplicateCheckService service;

      setUp(() {
        // Mock client 주입으로 Supabase 초기화 우회
        service = DuplicateCheckService(client: MockSupabaseClient());
      });

      test('동일한 입력에 대해 동일한 해시를 생성해야 한다', () {
        final timestamp = DateTime(2024, 1, 15, 14, 30);

        final hash1 = service.generateDuplicateHash(
          50000,
          'payment-id-1',
          timestamp,
        );
        final hash2 = service.generateDuplicateHash(
          50000,
          'payment-id-1',
          timestamp,
        );

        expect(hash1, equals(hash2));
      });

      test('3분 이내의 동일 거래는 동일한 해시를 가져야 한다', () {
        final timestamp1 = DateTime(2024, 1, 15, 14, 30);
        final timestamp2 = DateTime(2024, 1, 15, 14, 31); // 1분 후

        final hash1 = service.generateDuplicateHash(
          50000,
          'payment-id-1',
          timestamp1,
        );
        final hash2 = service.generateDuplicateHash(
          50000,
          'payment-id-1',
          timestamp2,
        );

        expect(hash1, equals(hash2));
      });

      test('3분 이상 차이나는 거래는 다른 해시를 가져야 한다', () {
        final timestamp1 = DateTime(2024, 1, 15, 14, 30);
        final timestamp2 = DateTime(2024, 1, 15, 14, 35); // 5분 후

        final hash1 = service.generateDuplicateHash(
          50000,
          'payment-id-1',
          timestamp1,
        );
        final hash2 = service.generateDuplicateHash(
          50000,
          'payment-id-1',
          timestamp2,
        );

        expect(hash1, isNot(equals(hash2)));
      });

      test('다른 금액은 다른 해시를 가져야 한다', () {
        final timestamp = DateTime(2024, 1, 15, 14, 30);

        final hash1 = service.generateDuplicateHash(
          50000,
          'payment-id-1',
          timestamp,
        );
        final hash2 = service.generateDuplicateHash(
          60000,
          'payment-id-1',
          timestamp,
        );

        expect(hash1, isNot(equals(hash2)));
      });

      test('다른 결제수단은 다른 해시를 가져야 한다', () {
        final timestamp = DateTime(2024, 1, 15, 14, 30);

        final hash1 = service.generateDuplicateHash(
          50000,
          'payment-id-1',
          timestamp,
        );
        final hash2 = service.generateDuplicateHash(
          50000,
          'payment-id-2',
          timestamp,
        );

        expect(hash1, isNot(equals(hash2)));
      });

      test('결제수단이 null인 경우에도 해시 생성이 가능해야 한다', () {
        final timestamp = DateTime(2024, 1, 15, 14, 30);

        final hash = service.generateDuplicateHash(50000, null, timestamp);

        expect(hash, isNotEmpty);
        expect(hash.contains('unknown'), isFalse); // 해시된 결과
      });

      test('해시는 MD5 형식(32자 hex)이어야 한다', () {
        final timestamp = DateTime(2024, 1, 15, 14, 30);

        final hash = service.generateDuplicateHash(
          50000,
          'payment-id-1',
          timestamp,
        );

        expect(hash.length, equals(32));
        expect(RegExp(r'^[a-f0-9]+$').hasMatch(hash), isTrue);
      });
    });

    group('DuplicateCheckResult', () {
      test('notDuplicate 팩토리가 올바른 결과를 반환해야 한다', () {
        final result = DuplicateCheckResult.notDuplicate('test-hash');

        expect(result.isDuplicate, isFalse);
        expect(result.duplicateHash, equals('test-hash'));
        expect(result.existingTransactionId, isNull);
        expect(result.existingPendingId, isNull);
      });

      test('duplicateTransaction 팩토리가 올바른 결과를 반환해야 한다', () {
        final result = DuplicateCheckResult.duplicateTransaction(
          'test-hash',
          'txn-123',
        );

        expect(result.isDuplicate, isTrue);
        expect(result.duplicateHash, equals('test-hash'));
        expect(result.existingTransactionId, equals('txn-123'));
        expect(result.existingPendingId, isNull);
      });

      test('duplicatePending 팩토리가 올바른 결과를 반환해야 한다', () {
        final result = DuplicateCheckResult.duplicatePending(
          'test-hash',
          'pending-456',
        );

        expect(result.isDuplicate, isTrue);
        expect(result.duplicateHash, equals('test-hash'));
        expect(result.existingTransactionId, isNull);
        expect(result.existingPendingId, equals('pending-456'));
      });
    });

    group('duplicateWindow', () {
      test('중복 체크 윈도우는 3분이어야 한다', () {
        expect(
          DuplicateCheckService.duplicateWindow,
          equals(const Duration(minutes: 3)),
        );
      });
    });
  });
}
