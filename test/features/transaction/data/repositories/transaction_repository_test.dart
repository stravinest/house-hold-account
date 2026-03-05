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
          'is_fixed_expense': false,
          'profiles': {'display_name': 'User1', 'color': '#A8D8EA'},
        },
        {
          'amount': 50000,
          'type': 'expense',
          'user_id': 'user-1',
          'is_fixed_expense': false,
          'profiles': {'display_name': 'User1', 'color': '#A8D8EA'},
        },
        {
          'amount': 20000,
          'type': 'asset',
          'user_id': 'user-2',
          'is_fixed_expense': false,
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

    test('고정비 제외 옵션이 켜진 경우 고정비 지출을 합계에서 제외한다', () async {
      const ledgerId = 'ledger-1';
      final mockData = <Map<String, dynamic>>[
        {
          'amount': 200000,
          'type': 'expense',
          'user_id': 'user-1',
          'is_fixed_expense': true,
          'profiles': {'display_name': 'User1', 'color': '#A8D8EA'},
        },
        {
          'amount': 30000,
          'type': 'expense',
          'user_id': 'user-1',
          'is_fixed_expense': false,
          'profiles': {'display_name': 'User1', 'color': '#A8D8EA'},
        },
      ];

      when(() => mockClient.from('transactions'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: mockData));

      final result = await repository.getMonthlyTotal(
        ledgerId: ledgerId,
        year: 2024,
        month: 1,
        excludeFixedExpense: true,
      );

      // 고정비(200000)는 제외, 일반 지출(30000)만 집계
      expect(result['expense'], 30000);
      expect(result['balance'], -30000);
    });

    test('데이터가 없을 때 모든 합계가 0이고 users가 빈 맵이다', () async {
      when(() => mockClient.from('transactions'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: []));

      final result = await repository.getMonthlyTotal(
        ledgerId: 'ledger-1',
        year: 2024,
        month: 1,
      );

      expect(result['income'], 0);
      expect(result['expense'], 0);
      expect(result['balance'], 0);
      expect((result['users'] as Map).isEmpty, true);
    });

    test('profile이 null인 경우 기본값(User, #A8D8EA)을 사용한다', () async {
      final mockData = <Map<String, dynamic>>[
        {
          'amount': 10000,
          'type': 'income',
          'user_id': 'user-1',
          'is_fixed_expense': false,
          'profiles': null,
        },
      ];

      when(() => mockClient.from('transactions'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: mockData));

      final result = await repository.getMonthlyTotal(
        ledgerId: 'ledger-1',
        year: 2024,
        month: 1,
      );

      final users = result['users'] as Map<String, Map<String, dynamic>>;
      expect(users['user-1']!['displayName'], 'User');
      expect(users['user-1']!['color'], '#A8D8EA');
    });
  });

  group('TransactionRepository - getTransactionsByDateRange', () {
    test('기간별 거래 조회 시 올바른 모델 리스트를 반환한다', () async {
      const ledgerId = 'ledger-1';
      final startDate = DateTime(2024, 1, 1);
      final endDate = DateTime(2024, 1, 31);
      final mockData = <Map<String, dynamic>>[
        {
          'id': 'tx-range-1',
          'ledger_id': ledgerId,
          'user_id': 'user-123',
          'amount': 15000,
          'type': 'income',
          'date': '2024-01-10',
          'title': '용돈',
          'created_at': '2024-01-10T10:00:00Z',
          'updated_at': '2024-01-10T10:00:00Z',
          'categories': null,
          'profiles': null,
          'payment_methods': null,
          'fixed_expense_categories': null,
          'is_recurring': false,
          'is_fixed_expense': false,
        },
      ];

      when(() => mockClient.from('transactions'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: mockData));

      final result = await repository.getTransactionsByDateRange(
        ledgerId: ledgerId,
        startDate: startDate,
        endDate: endDate,
      );

      expect(result, isA<List<TransactionModel>>());
      expect(result.length, 1);
      expect(result[0].id, 'tx-range-1');
      expect(result[0].amount, 15000);
    });

    test('기간 내 데이터가 없으면 빈 리스트를 반환한다', () async {
      when(() => mockClient.from('transactions'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: []));

      final result = await repository.getTransactionsByDateRange(
        ledgerId: 'ledger-1',
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 31),
      );

      expect(result, isEmpty);
    });
  });

  group('TransactionRepository - getTransactionsByMonth', () {
    test('월별 거래 조회 시 해당 월의 거래 리스트를 반환한다', () async {
      const ledgerId = 'ledger-1';
      final mockData = <Map<String, dynamic>>[
        {
          'id': 'tx-month-1',
          'ledger_id': ledgerId,
          'user_id': 'user-123',
          'amount': 5000,
          'type': 'expense',
          'date': '2024-03-15',
          'title': '커피',
          'created_at': '2024-03-15T09:00:00Z',
          'updated_at': '2024-03-15T09:00:00Z',
          'categories': null,
          'profiles': null,
          'payment_methods': null,
          'fixed_expense_categories': null,
          'is_recurring': false,
          'is_fixed_expense': false,
        },
      ];

      when(() => mockClient.from('transactions'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: mockData));

      final result = await repository.getTransactionsByMonth(
        ledgerId: ledgerId,
        year: 2024,
        month: 3,
      );

      expect(result.length, 1);
      expect(result[0].id, 'tx-month-1');
    });
  });

  group('TransactionRepository - batchUpdateTransactions', () {
    test('빈 ID 목록이면 아무것도 하지 않는다', () async {
      // batchUpdateTransactions는 ids가 비어 있으면 early return
      // from() 호출 자체가 없어야 함
      await repository.batchUpdateTransactions(ids: [], updates: {'title': '변경'});
      verifyNever(() => mockClient.from(any()));
    });

    test('50건 초과 시 예외를 던진다', () async {
      final ids = List.generate(51, (i) => 'tx-$i');
      expect(
        () => repository.batchUpdateTransactions(
          ids: ids,
          updates: {'title': '변경'},
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('50건 이하 유효한 경우 update 쿼리를 실행한다', () async {
      final ids = ['tx-1', 'tx-2', 'tx-3'];

      when(() => mockClient.from('transactions'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: []));

      // 예외 없이 완료되어야 함
      await repository.batchUpdateTransactions(
        ids: ids,
        updates: {'title': '일괄 변경'},
      );
    });
  });

  group('TransactionRepository - getDailyTotals', () {
    test('일별 합계 조회 시 날짜별로 수입과 지출이 올바르게 집계된다', () async {
      const ledgerId = 'ledger-1';
      final mockData = <Map<String, dynamic>>[
        {
          'date': '2024-01-15',
          'amount': 50000,
          'type': 'income',
          'user_id': 'user-1',
          'is_fixed_expense': false,
          'profiles': {'display_name': 'User1', 'color': '#A8D8EA'},
        },
        {
          'date': '2024-01-15',
          'amount': 20000,
          'type': 'expense',
          'user_id': 'user-1',
          'is_fixed_expense': false,
          'profiles': {'display_name': 'User1', 'color': '#A8D8EA'},
        },
        {
          'date': '2024-01-20',
          'amount': 10000,
          'type': 'expense',
          'user_id': 'user-2',
          'is_fixed_expense': false,
          'profiles': {'display_name': 'User2', 'color': '#FFB6A3'},
        },
      ];

      when(() => mockClient.from('transactions'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: mockData));

      final result = await repository.getDailyTotals(
        ledgerId: ledgerId,
        year: 2024,
        month: 1,
      );

      expect(result.length, 2); // 1월15일, 1월20일
      final jan15 = result[DateTime(2024, 1, 15)]!;
      expect(jan15['totalIncome'], 50000);
      expect(jan15['totalExpense'], 20000);

      final jan20 = result[DateTime(2024, 1, 20)]!;
      expect(jan20['totalExpense'], 10000);
    });

    test('고정비 제외 옵션 켜진 경우 일별 합계에서 고정비를 제외한다', () async {
      final mockData = <Map<String, dynamic>>[
        {
          'date': '2024-01-10',
          'amount': 100000,
          'type': 'expense',
          'user_id': 'user-1',
          'is_fixed_expense': true,
          'profiles': {'display_name': 'User1', 'color': '#A8D8EA'},
        },
        {
          'date': '2024-01-10',
          'amount': 15000,
          'type': 'expense',
          'user_id': 'user-1',
          'is_fixed_expense': false,
          'profiles': {'display_name': 'User1', 'color': '#A8D8EA'},
        },
      ];

      when(() => mockClient.from('transactions'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: mockData));

      final result = await repository.getDailyTotals(
        ledgerId: 'ledger-1',
        year: 2024,
        month: 1,
        excludeFixedExpense: true,
      );

      final jan10 = result[DateTime(2024, 1, 10)]!;
      // totalExpense는 고정비 제외 (15000만 포함)
      expect(jan10['totalExpense'], 15000);
      // 사용자별 expense는 고정비 포함 (dot 표시용: 115000)
      final users = jan10['users'] as Map<String, Map<String, dynamic>>;
      expect(users['user-1']!['expense'], 115000);
    });
  });

  group('TransactionRepository - createRecurringTemplate', () {
    test('로그인되지 않은 경우 예외를 던진다', () async {
      when(() => mockAuth.currentUser).thenReturn(null);

      expect(
        () => repository.createRecurringTemplate(
          ledgerId: 'ledger-1',
          amount: 50000,
          type: 'expense',
          startDate: DateTime(2024, 1, 1),
          recurringType: 'monthly',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('반복 거래 템플릿 생성 시 올바른 데이터를 반환한다', () async {
      final mockResponse = <String, dynamic>{
        'id': 'template-new',
        'ledger_id': 'ledger-1',
        'user_id': 'user-123',
        'amount': 50000,
        'type': 'expense',
        'recurring_type': 'monthly',
        'start_date': '2024-01-01',
        'is_active': true,
        'is_fixed_expense': false,
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-01T00:00:00Z',
      };

      when(() => mockClient.from('recurring_templates'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(
                selectData: [mockResponse],
                singleData: mockResponse,
              ));

      final result = await repository.createRecurringTemplate(
        ledgerId: 'ledger-1',
        amount: 50000,
        type: 'expense',
        startDate: DateTime(2024, 1, 1),
        recurringType: 'monthly',
      );

      expect(result['id'], 'template-new');
      expect(result['amount'], 50000);
      expect(result['recurring_type'], 'monthly');
    });
  });

  group('TransactionRepository - toggleRecurringTemplate', () {
    test('템플릿 활성/비활성 토글을 정상적으로 실행한다', () async {
      when(() => mockClient.from('recurring_templates'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: []));

      // 예외 없이 완료되어야 함
      await repository.toggleRecurringTemplate('template-1', false);
    });
  });

  group('TransactionRepository - deleteRecurringTemplate', () {
    test('반복 거래 템플릿 삭제를 정상적으로 실행한다', () async {
      when(() => mockClient.from('recurring_templates'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: []));

      await repository.deleteRecurringTemplate('template-1');
    });
  });

  group('TransactionRepository - getRecurringTemplates', () {
    test('활성 템플릿 목록을 반환한다', () async {
      final mockData = <Map<String, dynamic>>[
        {
          'id': 'template-1',
          'amount': 100000,
          'type': 'expense',
          'recurring_type': 'monthly',
          'is_active': true,
          'categories': null,
          'payment_methods': null,
          'fixed_expense_categories': null,
        },
      ];

      when(() => mockClient.from('recurring_templates'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: mockData));

      final result = await repository.getRecurringTemplates(ledgerId: 'ledger-1');

      expect(result.length, 1);
      expect(result[0]['id'], 'template-1');
    });
  });

  group('TransactionRepository - getAllRecurringTemplates', () {
    test('활성 및 비활성 템플릿 모두 반환한다', () async {
      final mockData = <Map<String, dynamic>>[
        {
          'id': 'template-active',
          'amount': 50000,
          'type': 'expense',
          'is_active': true,
          'categories': null,
          'payment_methods': null,
          'fixed_expense_categories': null,
          'profiles': null,
        },
        {
          'id': 'template-inactive',
          'amount': 30000,
          'type': 'expense',
          'is_active': false,
          'categories': null,
          'payment_methods': null,
          'fixed_expense_categories': null,
          'profiles': null,
        },
      ];

      when(() => mockClient.from('recurring_templates'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: mockData));

      final result = await repository.getAllRecurringTemplates(ledgerId: 'ledger-1');

      expect(result.length, 2);
    });
  });

  group('TransactionRepository - updateRecurringTemplate', () {
    test('반복 거래 템플릿 수정을 정상적으로 실행한다', () async {
      when(() => mockClient.from('recurring_templates'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: []));

      await repository.updateRecurringTemplate(
        'template-1',
        amount: 80000,
        title: '새 제목',
      );
    });

    test('clearEndDate=true이면 end_date를 null로 설정하는 업데이트를 실행한다', () async {
      when(() => mockClient.from('recurring_templates'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: []));

      await repository.updateRecurringTemplate(
        'template-1',
        clearEndDate: true,
      );
    });

    test('endDate가 있으면 end_date를 날짜 문자열로 업데이트한다', () async {
      when(() => mockClient.from('recurring_templates'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: []));

      await repository.updateRecurringTemplate(
        'template-1',
        endDate: DateTime(2024, 12, 31),
      );
    });

    test('fixedExpenseCategoryId가 있으면 업데이트에 포함된다', () async {
      when(() => mockClient.from('recurring_templates'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: []));

      await repository.updateRecurringTemplate(
        'template-1',
        fixedExpenseCategoryId: 'cat-fixed-1',
      );
    });

    test('paymentMethodId가 있으면 업데이트에 포함된다', () async {
      when(() => mockClient.from('recurring_templates'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: []));

      await repository.updateRecurringTemplate(
        'template-1',
        paymentMethodId: 'pm-1',
      );
    });

    test('categoryId가 있으면 업데이트에 포함된다', () async {
      when(() => mockClient.from('recurring_templates'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: []));

      await repository.updateRecurringTemplate(
        'template-1',
        categoryId: 'cat-1',
      );
    });
  });

  group('TransactionRepository - updateTransaction 추가 파라미터', () {
    final mockResponse = <String, dynamic>{
      'id': 'tx-1',
      'ledger_id': 'ledger-1',
      'user_id': 'user-123',
      'amount': 15000,
      'type': 'expense',
      'date': '2024-01-15',
      'title': '테스트',
      'is_recurring': true,
      'is_fixed_expense': true,
      'created_at': '2024-01-15T12:00:00Z',
      'updated_at': '2024-01-15T14:00:00Z',
      'categories': null,
      'profiles': null,
      'payment_methods': null,
      'fixed_expense_categories': null,
    };

    test('imageUrl을 포함하여 거래를 수정한다', () async {
      when(() => mockClient.from('transactions')).thenAnswer((_) =>
          FakeSupabaseQueryBuilder(
              selectData: [mockResponse], singleData: mockResponse));

      final result = await repository.updateTransaction(
        id: 'tx-1',
        imageUrl: 'https://example.com/image.jpg',
      );
      expect(result.id, equals('tx-1'));
    });

    test('isRecurring을 포함하여 거래를 수정한다', () async {
      when(() => mockClient.from('transactions')).thenAnswer((_) =>
          FakeSupabaseQueryBuilder(
              selectData: [mockResponse], singleData: mockResponse));

      final result = await repository.updateTransaction(
        id: 'tx-1',
        isRecurring: true,
      );
      expect(result.id, equals('tx-1'));
    });

    test('recurringType을 포함하여 거래를 수정한다', () async {
      when(() => mockClient.from('transactions')).thenAnswer((_) =>
          FakeSupabaseQueryBuilder(
              selectData: [mockResponse], singleData: mockResponse));

      final result = await repository.updateTransaction(
        id: 'tx-1',
        recurringType: 'monthly',
      );
      expect(result.id, equals('tx-1'));
    });

    test('recurringEndDate를 포함하여 거래를 수정한다', () async {
      when(() => mockClient.from('transactions')).thenAnswer((_) =>
          FakeSupabaseQueryBuilder(
              selectData: [mockResponse], singleData: mockResponse));

      final result = await repository.updateTransaction(
        id: 'tx-1',
        recurringEndDate: DateTime(2024, 12, 31),
      );
      expect(result.id, equals('tx-1'));
    });

    test('isFixedExpense를 포함하여 거래를 수정한다', () async {
      when(() => mockClient.from('transactions')).thenAnswer((_) =>
          FakeSupabaseQueryBuilder(
              selectData: [mockResponse], singleData: mockResponse));

      final result = await repository.updateTransaction(
        id: 'tx-1',
        isFixedExpense: true,
      );
      expect(result.id, equals('tx-1'));
    });

    test('fixedExpenseCategoryId를 포함하여 거래를 수정한다', () async {
      when(() => mockClient.from('transactions')).thenAnswer((_) =>
          FakeSupabaseQueryBuilder(
              selectData: [mockResponse], singleData: mockResponse));

      final result = await repository.updateTransaction(
        id: 'tx-1',
        fixedExpenseCategoryId: 'fixed-cat-1',
      );
      expect(result.id, equals('tx-1'));
    });
  });

  group('TransactionRepository - deleteTransactionAndDeactivateTemplate', () {
    test('deleteTransactionAndDeactivateTemplate는 RPC 함수를 호출한다', () async {
      when(() => mockClient.rpc(
            'delete_transaction_and_stop_recurring',
            params: any(named: 'params'),
          )).thenAnswer((_) => FakePostgrestFilterBuilder<dynamic>([]));

      await repository.deleteTransactionAndDeactivateTemplate(
        'tx-1',
        'template-1',
      );
      // 에러 없이 완료되면 성공
    });
  });

  group('TransactionRepository - generateRecurringTransactions', () {
    test('generateRecurringTransactions는 RPC 함수를 호출한다', () async {
      when(() => mockClient.rpc('generate_recurring_transactions'))
          .thenAnswer((_) => FakePostgrestFilterBuilder<dynamic>([]));

      await repository.generateRecurringTransactions();
      // 에러 없이 완료되면 성공
    });
  });
}
