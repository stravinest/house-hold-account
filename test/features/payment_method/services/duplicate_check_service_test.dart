import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_household_account/features/payment_method/data/services/duplicate_check_service.dart';

import '../../../helpers/mock_supabase.dart';

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

      test('3분 정확히 경계값에서 버킷팅이 올바르게 동작해야 한다', () {
        // 14:00 ~ 14:02:59 는 같은 버킷 (0 ~ 179초)
        final timestamp1 = DateTime(2024, 1, 15, 14, 0, 0); // 14:00:00
        final timestamp2 = DateTime(2024, 1, 15, 14, 2, 59); // 14:02:59

        final hash1 = service.generateDuplicateHash(10000, 'pm-1', timestamp1);
        final hash2 = service.generateDuplicateHash(10000, 'pm-1', timestamp2);

        // 같은 3분 버킷 내 -> 동일 해시
        expect(hash1, equals(hash2));
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

      test('기본 생성자로 모든 필드를 설정할 수 있다', () {
        const result = DuplicateCheckResult(
          isDuplicate: true,
          existingTransactionId: 'tx-1',
          existingPendingId: 'pending-1',
          duplicateHash: 'hash-abc',
        );

        expect(result.isDuplicate, isTrue);
        expect(result.existingTransactionId, 'tx-1');
        expect(result.existingPendingId, 'pending-1');
        expect(result.duplicateHash, 'hash-abc');
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

    group('generateMessageHash (static)', () {
      test('동일한 메시지와 시간에 동일한 해시를 반환한다', () {
        final timestamp = DateTime(2024, 1, 15, 14, 30);
        const content = 'KB국민카드 10,000원 결제 스타벅스';

        final hash1 = DuplicateCheckService.generateMessageHash(content, timestamp);
        final hash2 = DuplicateCheckService.generateMessageHash(content, timestamp);

        expect(hash1, equals(hash2));
      });

      test('1분 이내의 동일 내용은 동일한 해시를 가진다', () {
        const content = 'KB국민카드 10,000원 결제 스타벅스';
        final timestamp1 = DateTime(2024, 1, 15, 14, 30, 0);
        final timestamp2 = DateTime(2024, 1, 15, 14, 30, 59);

        final hash1 = DuplicateCheckService.generateMessageHash(content, timestamp1);
        final hash2 = DuplicateCheckService.generateMessageHash(content, timestamp2);

        expect(hash1, equals(hash2));
      });

      test('1분 이상 차이나는 메시지는 다른 해시를 가진다', () {
        const content = 'KB국민카드 10,000원 결제 스타벅스';
        final timestamp1 = DateTime(2024, 1, 15, 14, 30, 0);
        final timestamp2 = DateTime(2024, 1, 15, 14, 31, 0);

        final hash1 = DuplicateCheckService.generateMessageHash(content, timestamp1);
        final hash2 = DuplicateCheckService.generateMessageHash(content, timestamp2);

        expect(hash1, isNot(equals(hash2)));
      });

      test('80자 초과 내용은 첫 80자만 해시에 포함된다', () {
        final longContent = 'A' * 90; // 90자
        final shortContent = 'A' * 80; // 첫 80자
        final timestamp = DateTime(2024, 1, 15, 14, 30);

        final hash1 = DuplicateCheckService.generateMessageHash(longContent, timestamp);
        final hash2 = DuplicateCheckService.generateMessageHash(shortContent, timestamp);

        // 앞 80자가 같으므로 동일한 해시
        expect(hash1, equals(hash2));
      });

      test('해시는 32자 hex 형식이어야 한다', () {
        final timestamp = DateTime(2024, 1, 15, 14, 30);
        const content = 'KB국민카드 10,000원 결제';

        final hash = DuplicateCheckService.generateMessageHash(content, timestamp);

        expect(hash.length, equals(32));
        expect(RegExp(r'^[a-f0-9]+$').hasMatch(hash), isTrue);
      });
    });

    group('checkDuplicate (DB 연동)', () {
      late DuplicateCheckService service;
      late MockSupabaseClient mockClient;

      setUp(() {
        mockClient = MockSupabaseClient();
        service = DuplicateCheckService(client: mockClient);
      });

      test('pending_transactions에서 중복 발견 시 duplicatePending 결과를 반환한다', () async {
        // Given: pending_transactions에 동일 해시 존재
        when(() => mockClient.from('pending_transactions')).thenAnswer((_) =>
            FakeSupabaseQueryBuilder(
              selectData: [{'id': 'pending-existing', 'created_at': '2024-01-01T00:00:00Z'}],
              maybeSingleData: {'id': 'pending-existing', 'created_at': '2024-01-01T00:00:00Z'},
              hasMaybeSingleData: true,
            ));

        // When
        final result = await service.checkDuplicate(
          amount: 10000,
          paymentMethodId: 'pm-1',
          ledgerId: 'ledger-1',
          timestamp: DateTime(2024, 1, 15, 14, 30),
        );

        // Then
        expect(result.isDuplicate, isTrue);
        expect(result.existingPendingId, 'pending-existing');
      });

      test('DB 에러 발생 시 안전하게 notDuplicate를 반환한다', () async {
        // Given: DB 에러
        when(() => mockClient.from('pending_transactions'))
            .thenThrow(Exception('DB connection failed'));

        // When
        final result = await service.checkDuplicate(
          amount: 10000,
          paymentMethodId: 'pm-1',
          ledgerId: 'ledger-1',
          timestamp: DateTime(2024, 1, 15, 14, 30),
        );

        // Then: 에러 시 notDuplicate (거래 누락이 중복보다 나음)
        expect(result.isDuplicate, isFalse);
        expect(result.duplicateHash, isNotEmpty);
      });

      test('중복이 없는 경우 notDuplicate 결과를 반환한다', () async {
        // Given: 중복 없음
        when(() => mockClient.from('pending_transactions')).thenAnswer((_) =>
            FakeSupabaseQueryBuilder(
              selectData: [],
              hasMaybeSingleData: true,
              maybeSingleData: null,
            ));

        when(() => mockClient.from('transactions')).thenAnswer((_) =>
            FakeSupabaseQueryBuilder(selectData: []));

        // When
        final result = await service.checkDuplicate(
          amount: 10000,
          paymentMethodId: 'pm-1',
          ledgerId: 'ledger-1',
          timestamp: DateTime(2024, 1, 15, 14, 30),
        );

        // Then
        expect(result.isDuplicate, isFalse);
      });
    });

    group('findPendingByHash', () {
      late DuplicateCheckService service;
      late MockSupabaseClient mockClient;

      setUp(() {
        mockClient = MockSupabaseClient();
        service = DuplicateCheckService(client: mockClient);
      });

      test('해시로 기존 대기 거래를 찾아 반환한다', () async {
        final pendingData = {'id': 'pending-1', 'duplicate_hash': 'hash-abc'};

        when(() => mockClient.from('pending_transactions')).thenAnswer((_) =>
            FakeSupabaseQueryBuilder(
              selectData: [pendingData],
              maybeSingleData: pendingData,
              hasMaybeSingleData: true,
            ));

        final result = await service.findPendingByHash('hash-abc', 'ledger-1');
        expect(result, isNotNull);
        expect(result!['id'], 'pending-1');
      });

      test('매칭되는 거래가 없으면 null을 반환한다', () async {
        when(() => mockClient.from('pending_transactions')).thenAnswer((_) =>
            FakeSupabaseQueryBuilder(
              selectData: [],
              hasMaybeSingleData: true,
              maybeSingleData: null,
            ));

        final result = await service.findPendingByHash('hash-xyz', 'ledger-1');
        expect(result, isNull);
      });

      test('DB 에러 발생 시 null을 반환한다', () async {
        when(() => mockClient.from('pending_transactions'))
            .thenThrow(Exception('DB error'));

        final result = await service.findPendingByHash('hash-abc', 'ledger-1');
        expect(result, isNull);
      });
    });

    group('findSimilarTransactions', () {
      late DuplicateCheckService service;
      late MockSupabaseClient mockClient;

      setUp(() {
        mockClient = MockSupabaseClient();
        service = DuplicateCheckService(client: mockClient);
      });

      test('유사 금액 거래를 조회한다', () async {
        final transactions = [
          {'id': 'tx-1', 'amount': 10000, 'description': '스타벅스', 'date': '2024-01-15', 'category_id': 'cat-1'},
        ];

        when(() => mockClient.from('transactions')).thenAnswer((_) =>
            FakeSupabaseQueryBuilder(selectData: transactions));

        final result = await service.findSimilarTransactions(
          amount: 10000,
          ledgerId: 'ledger-1',
        );
        expect(result, isA<List<Map<String, dynamic>>>());
        expect(result.length, 1);
      });

      test('허용 오차를 포함한 금액 범위로 조회한다', () async {
        final transactions = [
          {'id': 'tx-1', 'amount': 9500, 'description': '스타벅스', 'date': '2024-01-15', 'category_id': 'cat-1'},
        ];

        when(() => mockClient.from('transactions')).thenAnswer((_) =>
            FakeSupabaseQueryBuilder(selectData: transactions));

        final result = await service.findSimilarTransactions(
          amount: 10000,
          ledgerId: 'ledger-1',
          tolerancePercent: 10,
        );
        expect(result.length, 1);
      });

      test('DB 에러 발생 시 빈 리스트를 반환한다', () async {
        when(() => mockClient.from('transactions'))
            .thenThrow(Exception('DB error'));

        final result = await service.findSimilarTransactions(
          amount: 10000,
          ledgerId: 'ledger-1',
        );
        expect(result, isEmpty);
      });
    });

    group('getRecentDuplicates', () {
      late DuplicateCheckService service;
      late MockSupabaseClient mockClient;

      setUp(() {
        mockClient = MockSupabaseClient();
        service = DuplicateCheckService(client: mockClient);
      });

      test('최근 중복 거래 목록을 조회한다', () async {
        final mockData = [
          {'duplicate_hash': 'hash-1', 'count': 2},
        ];

        when(() => mockClient.from('pending_transactions')).thenAnswer((_) =>
            FakeSupabaseQueryBuilder(selectData: mockData));

        final result = await service.getRecentDuplicates('ledger-1');
        expect(result, isA<List<Map<String, dynamic>>>());
        expect(result.length, 1);
      });

      test('DB 에러 발생 시 빈 리스트를 반환한다', () async {
        when(() => mockClient.from('pending_transactions'))
            .thenThrow(Exception('DB error'));

        final result = await service.getRecentDuplicates('ledger-1');
        expect(result, isEmpty);
      });
    });
  });
}
