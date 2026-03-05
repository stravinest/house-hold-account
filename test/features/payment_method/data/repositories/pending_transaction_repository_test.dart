import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_household_account/features/payment_method/data/models/pending_transaction_model.dart';
import 'package:shared_household_account/features/payment_method/data/repositories/pending_transaction_repository.dart';
import 'package:shared_household_account/features/payment_method/domain/entities/pending_transaction.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../helpers/mock_supabase.dart';

void main() {
  late MockSupabaseClient mockClient;
  late MockGoTrueClient mockAuth;
  late MockUser mockUser;
  late PendingTransactionRepository repository;

  setUp(() {
    mockClient = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    mockUser = MockUser();

    when(() => mockClient.auth).thenReturn(mockAuth);
    when(() => mockAuth.currentUser).thenReturn(mockUser);
    when(() => mockUser.id).thenReturn('user-123');

    repository = PendingTransactionRepository(client: mockClient);
  });

  Map<String, dynamic> _makePendingData({
    String id = 'pending-1',
    String status = 'pending',
    String? transactionId,
    bool isViewed = false,
    int parsedAmount = 10000,
  }) {
    return {
      'id': id,
      'ledger_id': 'ledger-1',
      'payment_method_id': 'pm-1',
      'user_id': 'user-123',
      'source_type': 'sms',
      'source_sender': 'KB카드',
      'source_content': '사용 ${parsedAmount}원',
      'source_timestamp': '2024-01-15T12:00:00Z',
      'parsed_amount': parsedAmount,
      'parsed_type': 'expense',
      'parsed_merchant': '편의점',
      'parsed_category_id': null,
      'parsed_date': '2024-01-15',
      'duplicate_hash': null,
      'is_duplicate': false,
      'status': status,
      'transaction_id': transactionId,
      'is_viewed': isViewed,
      'created_at': '2024-01-15T12:00:00Z',
      'updated_at': '2024-01-15T12:00:00Z',
      'expires_at': '2024-01-22T12:00:00Z',
    };
  }

  group('PendingTransactionRepository - getPendingTransactions', () {
    test('임시 거래 조회 시 상태 및 사용자로 필터링된 리스트를 반환한다', () async {
      final mockData = [_makePendingData()];

      when(() => mockClient.from('pending_transactions'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: mockData));

      final result = await repository.getPendingTransactions(
        'ledger-1',
        status: PendingTransactionStatus.pending,
        userId: 'user-123',
      );
      expect(result, isA<List<PendingTransactionModel>>());
      expect(result.length, 1);
      expect(result[0].parsedAmount, 10000);
    });

    test('상태 필터 없이 전체 거래를 조회한다', () async {
      final mockData = [
        _makePendingData(status: 'pending'),
        _makePendingData(id: 'pending-2', status: 'confirmed'),
      ];

      when(() => mockClient.from('pending_transactions'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: mockData));

      final result = await repository.getPendingTransactions('ledger-1');
      expect(result.length, 2);
    });

    test('결과가 없을 경우 빈 리스트를 반환한다', () async {
      when(() => mockClient.from('pending_transactions'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: []));

      final result = await repository.getPendingTransactions('ledger-1');
      expect(result, isEmpty);
    });
  });

  group('PendingTransactionRepository - getPendingCount', () {
    test('미확인 임시 거래 수를 반환한다', () async {
      final mockData = [
        {'id': 'pending-1'},
        {'id': 'pending-2'},
      ];

      when(() => mockClient.from('pending_transactions'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: mockData));

      final result = await repository.getPendingCount('ledger-1', 'user-123');
      expect(result, 2);
    });

    test('미확인 거래가 없는 경우 0을 반환한다', () async {
      when(() => mockClient.from('pending_transactions'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: []));

      final result = await repository.getPendingCount('ledger-1', 'user-123');
      expect(result, 0);
    });
  });

  group('PendingTransactionRepository - createPendingTransaction', () {
    test('임시 거래 생성 시 올바른 데이터로 INSERT하고 생성된 거래를 반환한다', () async {
      final mockData = [_makePendingData(id: 'pending-new', parsedAmount: 20000)];

      when(() => mockClient.from('pending_transactions'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: mockData));

      final result = await repository.createPendingTransaction(
        ledgerId: 'ledger-1',
        userId: 'user-123',
        sourceType: SourceType.sms,
        sourceSender: 'KB카드',
        sourceContent: '사용 20,000원',
        sourceTimestamp: DateTime(2024, 1, 15, 14, 0),
        parsedAmount: 20000,
        parsedType: 'expense',
        parsedMerchant: '식당',
      );
      expect(result, isA<PendingTransactionModel>());
      expect(result.id, 'pending-new');
      expect(result.parsedAmount, 20000);
    });

    test('사용자 인증이 없는 경우 예외를 던진다', () async {
      when(() => mockAuth.currentUser).thenReturn(null);

      when(() => mockClient.from('pending_transactions'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: []));

      expect(
        () => repository.createPendingTransaction(
          ledgerId: 'ledger-1',
          userId: 'user-123',
          sourceType: SourceType.sms,
          sourceSender: 'KB카드',
          sourceContent: '사용 10,000원',
          sourceTimestamp: DateTime.now(),
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('인증된 사용자 ID와 제공된 userId가 다른 경우 예외를 던진다', () async {
      expect(
        () => repository.createPendingTransaction(
          ledgerId: 'ledger-1',
          userId: 'different-user',
          sourceType: SourceType.sms,
          sourceSender: 'KB카드',
          sourceContent: '사용 10,000원',
          sourceTimestamp: DateTime.now(),
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('PendingTransactionRepository - updateStatus', () {
    test('상태 업데이트 시 올바른 데이터로 UPDATE하고 수정된 거래를 반환한다', () async {
      final mockData = _makePendingData(
        status: 'confirmed',
        transactionId: 'tx-123',
        isViewed: true,
      );

      when(() => mockClient.from('pending_transactions')).thenAnswer((_) =>
          FakeSupabaseQueryBuilder(
              selectData: [mockData], singleData: mockData));

      final result = await repository.updateStatus(
        id: 'pending-1',
        status: PendingTransactionStatus.confirmed,
        transactionId: 'tx-123',
      );
      expect(result.status, PendingTransactionStatus.confirmed);
      expect(result.transactionId, 'tx-123');
    });

    test('거부(rejected) 상태로 업데이트한다', () async {
      final mockData = _makePendingData(status: 'rejected');

      when(() => mockClient.from('pending_transactions')).thenAnswer((_) =>
          FakeSupabaseQueryBuilder(
              selectData: [mockData], singleData: mockData));

      final result = await repository.updateStatus(
        id: 'pending-1',
        status: PendingTransactionStatus.rejected,
      );
      expect(result.status, PendingTransactionStatus.rejected);
    });
  });

  group('PendingTransactionRepository - updateParsedData', () {
    test('파싱 데이터 업데이트 시 제공된 필드만 업데이트하고 결과를 반환한다', () async {
      final mockData = _makePendingData(parsedAmount: 25000);
      mockData['parsed_merchant'] = '스타벅스';

      when(() => mockClient.from('pending_transactions')).thenAnswer((_) =>
          FakeSupabaseQueryBuilder(
              selectData: [mockData], singleData: mockData));

      final result = await repository.updateParsedData(
        id: 'pending-1',
        parsedAmount: 25000,
        parsedMerchant: '스타벅스',
      );
      expect(result, isA<PendingTransactionModel>());
      expect(result.parsedAmount, 25000);
      expect(result.parsedMerchant, '스타벅스');
    });

    test('날짜와 카테고리 ID도 함께 업데이트한다', () async {
      final mockData = _makePendingData();
      mockData['parsed_category_id'] = 'cat-123';

      when(() => mockClient.from('pending_transactions')).thenAnswer((_) =>
          FakeSupabaseQueryBuilder(
              selectData: [mockData], singleData: mockData));

      final result = await repository.updateParsedData(
        id: 'pending-1',
        parsedCategoryId: 'cat-123',
        parsedDate: DateTime(2024, 1, 15),
      );
      expect(result, isA<PendingTransactionModel>());
    });
  });

  group('PendingTransactionRepository - deletePendingTransaction', () {
    test('단일 임시 거래 삭제가 정상적으로 완료된다', () async {
      when(() => mockClient.from('pending_transactions'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: []));

      await repository.deletePendingTransaction('pending-1');
      // 에러 없이 완료되면 성공
    });
  });

  group('PendingTransactionRepository - deleteAllByStatus', () {
    test('특정 상태의 모든 거래 삭제 시 조건에 맞는 거래를 삭제한다', () async {
      when(() => mockClient.from('pending_transactions'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: []));

      await repository.deleteAllByStatus(
        'ledger-1',
        'user-123',
        PendingTransactionStatus.rejected,
      );
      // 에러 없이 완료되면 성공
    });
  });

  group('PendingTransactionRepository - deleteAllRejected', () {
    test('거부된 모든 거래를 삭제한다', () async {
      when(() => mockClient.from('pending_transactions'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: []));

      await repository.deleteAllRejected('ledger-1', 'user-123');
      // 에러 없이 완료되면 성공
    });
  });

  group('PendingTransactionRepository - deleteAllConfirmed', () {
    test('확인됨 탭의 모든 항목(confirmed + converted)을 삭제한다', () async {
      when(() => mockClient.from('pending_transactions'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: []));

      await repository.deleteAllConfirmed('ledger-1', 'user-123');
      // 에러 없이 완료되면 성공
    });
  });

  group('PendingTransactionRepository - checkDuplicate', () {
    test('중복 체크 RPC 함수 호출 시 중복 여부를 반환한다', () async {
      when(() => mockClient.rpc('check_duplicate_transaction',
              params: any(named: 'params')))
          .thenAnswer(
              (_) => FakePostgrestFilterBuilder<dynamic>(true));

      final result = await repository.checkDuplicate(
        amount: 10000,
        paymentMethodId: 'pm-1',
        timestamp: DateTime(2024, 1, 15, 12, 0),
      );
      expect(result, isTrue);
    });

    test('결제수단이 null인 경우 중복 체크를 건너뛰고 false를 반환한다', () async {
      final result = await repository.checkDuplicate(
        amount: 10000,
        paymentMethodId: null,
        timestamp: DateTime(2024, 1, 15, 12, 0),
      );
      expect(result, isFalse);
    });

    test('RPC 함수 실패 시 false를 반환하여 안전하게 처리한다', () async {
      when(() => mockClient.rpc('check_duplicate_transaction',
              params: any(named: 'params')))
          .thenThrow(Exception('RPC failed'));

      final result = await repository.checkDuplicate(
        amount: 10000,
        paymentMethodId: 'pm-1',
        timestamp: DateTime(2024, 1, 15, 12, 0),
      );
      expect(result, isFalse);
    });

    test('중복이 아닌 경우 false를 반환한다', () async {
      when(() => mockClient.rpc('check_duplicate_transaction',
              params: any(named: 'params')))
          .thenAnswer(
              (_) => FakePostgrestFilterBuilder<dynamic>(false));

      final result = await repository.checkDuplicate(
        amount: 10000,
        paymentMethodId: 'pm-1',
        timestamp: DateTime(2024, 1, 15, 12, 0),
      );
      expect(result, isFalse);
    });
  });

  group('PendingTransactionRepository - cleanupExpired', () {
    test('만료된 거래 정리 RPC 호출 시 정리된 건수를 반환한다', () async {
      when(() => mockClient.rpc('cleanup_expired_pending_transactions'))
          .thenAnswer((_) => FakePostgrestFilterBuilder<dynamic>(5));

      final result = await repository.cleanupExpired();
      expect(result, 5);
    });

    test('RPC 실패 시 0을 반환한다', () async {
      when(() => mockClient.rpc('cleanup_expired_pending_transactions'))
          .thenThrow(Exception('RPC failed'));

      final result = await repository.cleanupExpired();
      expect(result, 0);
    });
  });

  group('PendingTransactionRepository - confirmAll', () {
    test('모든 대기 중인 거래를 확인 상태로 변경하고 변경된 거래 목록을 반환한다', () async {
      final mockData = [
        _makePendingData(status: 'confirmed'),
        _makePendingData(id: 'pending-2', status: 'confirmed'),
      ];

      when(() => mockClient.from('pending_transactions'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: mockData));

      final result = await repository.confirmAll('ledger-1', 'user-123');
      expect(result, isA<List<PendingTransactionModel>>());
      expect(result.length, 2);
      expect(result.every((tx) => tx.status == PendingTransactionStatus.confirmed), isTrue);
    });
  });

  group('PendingTransactionRepository - rejectAll', () {
    test('모든 대기 중인 거래를 거부 상태로 변경한다', () async {
      when(() => mockClient.from('pending_transactions'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: []));

      await repository.rejectAll('ledger-1', 'user-123');
      // 에러 없이 완료되면 성공
    });
  });

  group('PendingTransactionRepository - markAllAsViewed', () {
    test('모든 미확인 거래를 확인 상태로 변경한다', () async {
      when(() => mockClient.from('pending_transactions'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: []));

      await repository.markAllAsViewed('ledger-1', 'user-123');
      // 에러 없이 완료되면 성공
    });
  });

  group('PendingTransactionRepository - createPendingTransaction INSERT 0행 반환', () {
    test('INSERT가 0행을 반환하면 멤버 체크 후 예외를 던진다', () async {
      // INSERT는 빈 리스트를 반환하고, 멤버 체크에서도 null 반환
      when(() => mockClient.from('pending_transactions'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: []));
      when(() => mockClient.from('ledger_members')).thenAnswer((_) =>
          FakeSupabaseQueryBuilder(
              selectData: [],
              maybeSingleData: null,
              hasMaybeSingleData: true));

      await expectLater(
        () => repository.createPendingTransaction(
          ledgerId: 'ledger-1',
          userId: 'user-123',
          sourceType: SourceType.sms,
          sourceSender: 'KB카드',
          sourceContent: '사용 10,000원',
          sourceTimestamp: DateTime.now(),
          parsedAmount: 10000,
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('PendingTransactionRepository - updateParsedData 추가 파라미터', () {
    test('parsedType 파라미터를 포함하여 파싱 데이터를 업데이트한다', () async {
      final mockData = _makePendingData();
      mockData['parsed_type'] = 'income';

      when(() => mockClient.from('pending_transactions')).thenAnswer((_) =>
          FakeSupabaseQueryBuilder(
              selectData: [mockData], singleData: mockData));

      final result = await repository.updateParsedData(
        id: 'pending-1',
        parsedType: 'income',
      );
      expect(result, isA<PendingTransactionModel>());
    });

    test('paymentMethodId 파라미터를 포함하여 파싱 데이터를 업데이트한다', () async {
      final mockData = _makePendingData();
      mockData['payment_method_id'] = 'pm-new';

      when(() => mockClient.from('pending_transactions')).thenAnswer((_) =>
          FakeSupabaseQueryBuilder(
              selectData: [mockData], singleData: mockData));

      final result = await repository.updateParsedData(
        id: 'pending-1',
        paymentMethodId: 'pm-new',
      );
      expect(result, isA<PendingTransactionModel>());
    });
  });

  group('PendingTransactionRepository - subscribePendingTransactions', () {
    test('subscribePendingTransactions는 RealtimeChannel을 반환한다', () {
      final mockChannel = MockRealtimeChannel();
      when(() => mockClient.channel(any())).thenReturn(mockChannel);
      when(() => mockChannel.onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: any(named: 'schema'),
            table: any(named: 'table'),
            filter: any(named: 'filter'),
            callback: any(named: 'callback'),
          )).thenReturn(mockChannel);
      when(() => mockChannel.subscribe()).thenReturn(mockChannel);

      final channel = repository.subscribePendingTransactions(
        ledgerId: 'ledger-1',
        userId: 'user-123',
        onTableChanged: () {},
      );
      expect(channel, isNotNull);
    });
  });

  group('PendingTransactionRepository - findOriginalDuplicate', () {
    test('duplicateHash로 원본 중복 거래를 찾아 반환한다', () async {
      final originalPending = _makePendingData(id: 'original-1');

      when(() => mockClient.from('pending_transactions')).thenAnswer((_) =>
          FakeSupabaseQueryBuilder(selectData: [originalPending]));

      final result = await repository.findOriginalDuplicate(
        ledgerId: 'ledger-1',
        userId: 'user-123',
        duplicateHash: 'hash-abc',
        currentTransactionId: 'pending-current',
      );
      expect(result, isA<PendingTransactionModel>());
      expect(result!.id, 'original-1');
    });

    test('원본 중복 거래가 없는 경우 null을 반환한다', () async {
      when(() => mockClient.from('pending_transactions'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: []));

      final result = await repository.findOriginalDuplicate(
        ledgerId: 'ledger-1',
        userId: 'user-123',
        duplicateHash: 'hash-xyz',
        currentTransactionId: 'pending-current',
      );
      expect(result, isNull);
    });

    test('DB 에러 발생 시 null을 반환한다', () async {
      when(() => mockClient.from('pending_transactions'))
          .thenThrow(Exception('DB error'));

      final result = await repository.findOriginalDuplicate(
        ledgerId: 'ledger-1',
        userId: 'user-123',
        duplicateHash: 'hash-abc',
        currentTransactionId: 'pending-current',
      );
      expect(result, isNull);
    });
  });
}
