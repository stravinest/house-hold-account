import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_household_account/features/payment_method/data/models/pending_transaction_model.dart';
import 'package:shared_household_account/features/payment_method/data/repositories/pending_transaction_repository.dart';
import 'package:shared_household_account/features/payment_method/domain/entities/pending_transaction.dart';

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

  group('PendingTransactionRepository - markAllAsViewed', () {
    test('모든 미확인 거래를 확인 상태로 변경한다', () async {
      when(() => mockClient.from('pending_transactions'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: []));

      await repository.markAllAsViewed('ledger-1', 'user-123');
      // 에러 없이 완료되면 성공
    });
  });
}
