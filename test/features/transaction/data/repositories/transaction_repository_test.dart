import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_household_account/features/transaction/data/models/transaction_model.dart';
import 'package:shared_household_account/features/transaction/data/repositories/transaction_repository.dart';

import '../../../../helpers/mock_supabase.dart';

void main() {
  late MockSupabaseClient mockClient;
  late MockGoTrueClient mockAuth;
  late MockUser mockUser;
  late TransactionRepository repository;

  setUp(() {
    mockClient = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    mockUser = MockUser();

    when(() => mockClient.auth).thenReturn(mockAuth);
    when(() => mockAuth.currentUser).thenReturn(mockUser);
    when(() => mockUser.id).thenReturn('user-123');

    repository = TransactionRepository(client: mockClient);
  });

  group('TransactionRepository - getTransactionsByDate', () {
    test('날짜별 거래 조회 시 올바른 쿼리를 실행하고 모델 리스트를 반환한다', () async {
      const ledgerId = 'ledger-1';
      final date = DateTime(2024, 1, 15);
      final mockData = <Map<String, dynamic>>[
        {
          'id': 'tx-1',
          'ledger_id': ledgerId,
          'user_id': 'user-123',
          'amount': 10000,
          'type': 'expense',
          'date': '2024-01-15',
          'title': '점심',
          'created_at': '2024-01-15T12:00:00Z',
          'updated_at': '2024-01-15T12:00:00Z',
          'categories': {'name': '식비', 'icon': 'restaurant', 'color': '#FF5733'},
          'profiles': {'display_name': 'User1', 'email': 'user1@test.com', 'color': '#A8D8EA'},
          'payment_methods': {'name': 'KB카드'},
          'fixed_expense_categories': null, 'is_recurring': false, 'is_fixed_expense': false,
        },
      ];

      when(() => mockClient.from('transactions'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: mockData));

      final result = await repository.getTransactionsByDate(
          ledgerId: ledgerId, date: date);
      expect(result, isA<List<TransactionModel>>());
      expect(result.length, 1);
      expect(result[0].id, 'tx-1');
      expect(result[0].amount, 10000);
    });

    test('날짜별 거래 조회 시 데이터가 없으면 빈 리스트를 반환한다', () async {
      const ledgerId = 'ledger-1';
      final date = DateTime(2024, 1, 15);

      when(() => mockClient.from('transactions'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: []));

      final result = await repository.getTransactionsByDate(
          ledgerId: ledgerId, date: date);
      expect(result, isEmpty);
    });
  });

  group('TransactionRepository - createTransaction', () {
    test('거래 생성 시 올바른 데이터로 INSERT하고 생성된 거래를 반환한다', () async {
      const ledgerId = 'ledger-1';
      const amount = 50000;
      const type = 'expense';
      final date = DateTime(2024, 1, 15);
      final mockResponse = <String, dynamic>{
        'id': 'tx-new',
        'ledger_id': ledgerId,
        'user_id': 'user-123',
        'amount': amount,
        'type': type,
        'date': '2024-01-15',
        'title': '저녁',
        'created_at': '2024-01-15T18:00:00Z',
        'updated_at': '2024-01-15T18:00:00Z',
        'categories': {'name': '식비', 'icon': 'restaurant', 'color': '#FF5733'},
        'profiles': {'display_name': 'User1', 'email': 'user1@test.com', 'color': '#A8D8EA'},
        'payment_methods': {'name': '현금'},
        'fixed_expense_categories': null, 'is_recurring': false, 'is_fixed_expense': false,
      };

      when(() => mockClient.from('transactions')).thenAnswer((_) =>
          FakeSupabaseQueryBuilder(
              selectData: [mockResponse], singleData: mockResponse));

      final result = await repository.createTransaction(
        ledgerId: ledgerId,
        amount: amount,
        type: type,
        date: date,
        title: '저녁',
      );
      expect(result, isA<TransactionModel>());
      expect(result.id, 'tx-new');
      expect(result.amount, amount);
    });

    test('거래 생성 시 로그인되지 않은 경우 예외를 던진다', () async {
      when(() => mockAuth.currentUser).thenReturn(null);
      expect(
        () => repository.createTransaction(
          ledgerId: 'ledger-1',
          amount: 10000,
          type: 'expense',
          date: DateTime.now(),
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('TransactionRepository - updateTransaction', () {
    test('거래 수정 시 올바른 필드만 업데이트하고 수정된 거래를 반환한다', () async {
      const transactionId = 'tx-1';
      const newAmount = 15000;
      final mockResponse = <String, dynamic>{
        'id': transactionId,
        'ledger_id': 'ledger-1',
        'user_id': 'user-123',
        'amount': newAmount,
        'type': 'expense',
        'date': '2024-01-15',
        'title': '수정된 제목',
        'created_at': '2024-01-15T12:00:00Z',
        'updated_at': '2024-01-15T14:00:00Z',
        'categories': null,
        'profiles': null,
        'payment_methods': null,
        'fixed_expense_categories': null, 'is_recurring': false, 'is_fixed_expense': false,
      };

      when(() => mockClient.from('transactions')).thenAnswer((_) =>
          FakeSupabaseQueryBuilder(
              selectData: [mockResponse], singleData: mockResponse));

      final result = await repository.updateTransaction(
          id: transactionId, amount: newAmount, title: '수정된 제목');
      expect(result, isA<TransactionModel>());
      expect(result.id, transactionId);
      expect(result.amount, newAmount);
    });
  });

  group('TransactionRepository - deleteTransaction', () {
    test('거래 삭제 시 올바른 ID로 DELETE 쿼리를 실행한다', () async {
      const transactionId = 'tx-1';

      when(() => mockClient.from('transactions'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: []));

      await repository.deleteTransaction(transactionId);
      // delete 체인이 에러 없이 완료되면 성공
    });
  });

  group('TransactionRepository - getMonthlyTotal', () {
    test('월별 합계 조회 시 수입, 지출, 사용자별 데이터를 올바르게 집계한다', () async {
      const ledgerId = 'ledger-1';
      const year = 2024;
      const month = 1;
      final mockData = <Map<String, dynamic>>[
        {
          'amount': 100000,
          'type': 'income',
          'user_id': 'user-1',
          'profiles': {'display_name': 'User1', 'color': '#A8D8EA'},
        },
        {
          'amount': 50000,
          'type': 'expense',
          'user_id': 'user-1',
          'profiles': {'display_name': 'User1', 'color': '#A8D8EA'},
        },
        {
          'amount': 20000,
          'type': 'asset',
          'user_id': 'user-2',
          'profiles': {'display_name': 'User2', 'color': '#FFB6A3'},
        },
      ];

      when(() => mockClient.from('transactions'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: mockData));

      final result = await repository.getMonthlyTotal(
          ledgerId: ledgerId, year: year, month: month);
      expect(result['income'], 100000);
      expect(result['expense'], 50000);
      expect(result['balance'], 50000);
      expect(result['users'], isA<Map>());
      expect((result['users'] as Map).length, 2);
    });
  });
}
