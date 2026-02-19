import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/core/utils/date_time_utils.dart';
import 'package:shared_household_account/features/transaction/data/models/transaction_model.dart';
import 'package:shared_household_account/features/transaction/domain/entities/transaction.dart';

void main() {
  group('TransactionModel', () {
    final testDate = DateTime(2026, 2, 12);
    final testCreatedAt = DateTime(2026, 2, 12, 10, 0, 0);
    final testUpdatedAt = DateTime(2026, 2, 12, 11, 0, 0);

    final transactionModel = TransactionModel(
      id: 'test-id',
      ledgerId: 'ledger-id',
      userId: 'user-id',
      categoryId: 'category-id',
      paymentMethodId: 'payment-id',
      amount: 10000,
      type: 'expense',
      date: testDate,
      title: '점심 식사',
      memo: '테스트 메모',
      imageUrl: 'https://example.com/image.jpg',
      isRecurring: false,
      recurringType: null,
      recurringEndDate: null,
      isFixedExpense: false,
      fixedExpenseCategoryId: null,
      isAsset: false,
      maturityDate: null,
      createdAt: testCreatedAt,
      updatedAt: testUpdatedAt,
      categoryName: '식비',
      categoryIcon: '🍔',
      categoryColor: '#FF5733',
      userName: '홍길동',
      userColor: '#4A90E2',
      paymentMethodName: '신한카드',
    );

    test('Transaction 엔티티를 확장한다', () {
      expect(transactionModel, isA<Transaction>());
    });

    group('fromJson', () {
      test('JSON에서 올바르게 역직렬화된다', () {
        final json = {
          'id': 'json-id',
          'ledger_id': 'ledger-id',
          'user_id': 'user-id',
          'category_id': 'category-id',
          'payment_method_id': 'payment-id',
          'amount': 20000,
          'type': 'income',
          'date': '2026-02-12',
          'title': '월급',
          'memo': '2월 월급',
          'image_url': 'https://example.com/salary.jpg',
          'is_recurring': true,
          'recurring_type': 'monthly',
          'recurring_end_date': '2026-12-31',
          'is_fixed_expense': false,
          'fixed_expense_category_id': null,
          'is_asset': false,
          'maturity_date': null,
          'created_at': '2026-02-12T10:00:00.000',
          'updated_at': '2026-02-12T11:00:00.000',
          'categories': {
            'name': '급여',
            'icon': '💰',
            'color': '#00FF00',
          },
          'profiles': {
            'display_name': '김철수',
            'email': 'kim@example.com',
            'color': '#FF0000',
          },
          'payment_methods': {
            'name': '국민은행',
          },
          'fixed_expense_categories': null,
        };

        final result = TransactionModel.fromJson(json);

        expect(result.id, 'json-id');
        expect(result.amount, 20000);
        expect(result.type, 'income');
        expect(result.title, '월급');
        expect(result.isRecurring, true);
        expect(result.recurringType, 'monthly');
        expect(result.categoryName, '급여');
        expect(result.categoryIcon, '💰');
        expect(result.categoryColor, '#00FF00');
        expect(result.userName, '김철수');
        expect(result.userColor, '#FF0000');
        expect(result.paymentMethodName, '국민은행');
      });

      test('프로필의 display_name이 없으면 email을 사용한다', () {
        final json = {
          'id': 'json-id',
          'ledger_id': 'ledger-id',
          'user_id': 'user-id',
          'amount': 5000,
          'type': 'expense',
          'date': '2026-02-12',
          'is_recurring': false,
          'created_at': '2026-02-12T10:00:00.000',
          'updated_at': '2026-02-12T11:00:00.000',
          'profiles': {
            'email': 'test@example.com',
            'color': '#FF0000',
          },
        };

        final result = TransactionModel.fromJson(json);

        expect(result.userName, 'test@example.com');
      });

      test('null 값들을 올바르게 처리한다', () {
        final json = {
          'id': 'json-id',
          'ledger_id': 'ledger-id',
          'user_id': 'user-id',
          'category_id': null,
          'payment_method_id': null,
          'amount': 5000,
          'type': 'expense',
          'date': '2026-02-12',
          'title': null,
          'memo': null,
          'image_url': null,
          'is_recurring': false,
          'recurring_type': null,
          'recurring_end_date': null,
          'is_fixed_expense': null,
          'fixed_expense_category_id': null,
          'is_asset': null,
          'maturity_date': null,
          'created_at': '2026-02-12T10:00:00.000',
          'updated_at': '2026-02-12T11:00:00.000',
        };

        final result = TransactionModel.fromJson(json);

        expect(result.categoryId, null);
        expect(result.paymentMethodId, null);
        expect(result.title, null);
        expect(result.memo, null);
        expect(result.imageUrl, null);
        expect(result.isFixedExpense, false);
        expect(result.isAsset, false);
      });

      test('날짜를 로컬 날짜로 파싱한다', () {
        final json = {
          'id': 'json-id',
          'ledger_id': 'ledger-id',
          'user_id': 'user-id',
          'amount': 5000,
          'type': 'expense',
          'date': '2026-03-15',
          'is_recurring': false,
          'created_at': '2026-02-12T10:00:00.000',
          'updated_at': '2026-02-12T11:00:00.000',
        };

        final result = TransactionModel.fromJson(json);

        expect(result.date.year, 2026);
        expect(result.date.month, 3);
        expect(result.date.day, 15);
      });

      test('만기일을 로컬 날짜로 파싱한다', () {
        final json = {
          'id': 'json-id',
          'ledger_id': 'ledger-id',
          'user_id': 'user-id',
          'amount': 5000,
          'type': 'asset',
          'date': '2026-02-12',
          'is_recurring': false,
          'is_asset': true,
          'maturity_date': '2027-02-12',
          'created_at': '2026-02-12T10:00:00.000',
          'updated_at': '2026-02-12T11:00:00.000',
        };

        final result = TransactionModel.fromJson(json);

        expect(result.maturityDate, isNotNull);
        expect(result.maturityDate!.year, 2027);
        expect(result.maturityDate!.month, 2);
        expect(result.maturityDate!.day, 12);
      });
    });

    group('toJson', () {
      test('JSON으로 올바르게 직렬화된다', () {
        final json = transactionModel.toJson();

        expect(json['id'], 'test-id');
        expect(json['ledger_id'], 'ledger-id');
        expect(json['user_id'], 'user-id');
        expect(json['category_id'], 'category-id');
        expect(json['payment_method_id'], 'payment-id');
        expect(json['amount'], 10000);
        expect(json['type'], 'expense');
        expect(json['date'], '2026-02-12');
        expect(json['title'], '점심 식사');
        expect(json['memo'], '테스트 메모');
        expect(json['image_url'], 'https://example.com/image.jpg');
        expect(json['is_recurring'], false);
        expect(json['recurring_type'], null);
        expect(json['recurring_end_date'], null);
        expect(json['is_fixed_expense'], false);
        expect(json['fixed_expense_category_id'], null);
        expect(json['is_asset'], false);
        expect(json['maturity_date'], null);
        expect(json['created_at'], isA<String>());
        expect(json['updated_at'], isA<String>());
      });

      test('조인된 필드는 JSON에 포함되지 않는다', () {
        final json = transactionModel.toJson();

        expect(json.containsKey('category_name'), false);
        expect(json.containsKey('category_icon'), false);
        expect(json.containsKey('category_color'), false);
        expect(json.containsKey('user_name'), false);
        expect(json.containsKey('user_color'), false);
        expect(json.containsKey('payment_method_name'), false);
      });

      test('날짜를 로컬 날짜 형식으로 직렬화한다', () {
        final model = TransactionModel(
          id: 'test-id',
          ledgerId: 'ledger-id',
          userId: 'user-id',
          amount: 5000,
          type: 'expense',
          date: DateTime(2026, 3, 15, 14, 30, 0),
          isRecurring: false,
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        final json = model.toJson();

        expect(json['date'], '2026-03-15');
      });

      test('null 값들을 올바르게 직렬화한다', () {
        final model = TransactionModel(
          id: 'test-id',
          ledgerId: 'ledger-id',
          userId: 'user-id',
          amount: 5000,
          type: 'expense',
          date: testDate,
          isRecurring: false,
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        final json = model.toJson();

        expect(json['category_id'], null);
        expect(json['payment_method_id'], null);
        expect(json['title'], null);
        expect(json['memo'], null);
        expect(json['image_url'], null);
      });

      test('반복 종료일을 로컬 날짜 형식으로 직렬화한다', () {
        final model = TransactionModel(
          id: 'test-id',
          ledgerId: 'ledger-id',
          userId: 'user-id',
          amount: 5000,
          type: 'expense',
          date: testDate,
          isRecurring: true,
          recurringType: 'monthly',
          recurringEndDate: DateTime(2026, 12, 31, 23, 59, 59),
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        final json = model.toJson();

        expect(json['recurring_end_date'], '2026-12-31');
      });

      test('만기일을 로컬 날짜 형식으로 직렬화한다', () {
        final model = TransactionModel(
          id: 'test-id',
          ledgerId: 'ledger-id',
          userId: 'user-id',
          amount: 5000,
          type: 'asset',
          date: testDate,
          isRecurring: false,
          isAsset: true,
          maturityDate: DateTime(2027, 2, 12, 23, 59, 59),
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        final json = model.toJson();

        expect(json['maturity_date'], '2027-02-12');
      });
    });

    group('toCreateJson', () {
      test('생성용 JSON을 올바르게 만든다', () {
        final json = TransactionModel.toCreateJson(
          ledgerId: 'ledger-id',
          userId: 'user-id',
          categoryId: 'category-id',
          paymentMethodId: 'payment-id',
          amount: 15000,
          type: 'expense',
          date: testDate,
          title: '저녁 식사',
          memo: '회식',
        );

        expect(json['ledger_id'], 'ledger-id');
        expect(json['user_id'], 'user-id');
        expect(json['category_id'], 'category-id');
        expect(json['payment_method_id'], 'payment-id');
        expect(json['amount'], 15000);
        expect(json['type'], 'expense');
        expect(json['date'], '2026-02-12');
        expect(json['title'], '저녁 식사');
        expect(json['memo'], '회식');
      });

      test('기본값이 올바르게 설정된다', () {
        final json = TransactionModel.toCreateJson(
          ledgerId: 'ledger-id',
          userId: 'user-id',
          amount: 5000,
          type: 'income',
          date: testDate,
        );

        expect(json['is_recurring'], false);
        expect(json['is_fixed_expense'], false);
        expect(json['is_asset'], false);
      });

      test('선택적 필드들을 포함할 수 있다', () {
        final json = TransactionModel.toCreateJson(
          ledgerId: 'ledger-id',
          userId: 'user-id',
          amount: 5000,
          type: 'expense',
          date: testDate,
          isRecurring: true,
          recurringType: 'monthly',
          recurringEndDate: DateTime(2026, 12, 31),
          isFixedExpense: true,
          fixedExpenseCategoryId: 'fixed-expense-id',
          isAsset: true,
          maturityDate: DateTime(2027, 2, 12),
          sourceType: 'auto',
        );

        expect(json['is_recurring'], true);
        expect(json['recurring_type'], 'monthly');
        expect(json['recurring_end_date'], '2026-12-31');
        expect(json['is_fixed_expense'], true);
        expect(json['fixed_expense_category_id'], 'fixed-expense-id');
        expect(json['is_asset'], true);
        expect(json['maturity_date'], '2027-02-12');
        expect(json['source_type'], 'auto');
      });

      test('null 값들을 올바르게 처리한다', () {
        final json = TransactionModel.toCreateJson(
          ledgerId: 'ledger-id',
          userId: 'user-id',
          amount: 5000,
          type: 'expense',
          date: testDate,
          categoryId: null,
          paymentMethodId: null,
          title: null,
          memo: null,
          imageUrl: null,
        );

        expect(json['category_id'], null);
        expect(json['payment_method_id'], null);
        expect(json['title'], null);
        expect(json['memo'], null);
        expect(json['image_url'], null);
      });
    });

    group('fromJson -> toJson 왕복 변환', () {
      test('데이터가 손실 없이 변환된다', () {
        final originalJson = {
          'id': 'test-id',
          'ledger_id': 'ledger-id',
          'user_id': 'user-id',
          'category_id': 'category-id',
          'payment_method_id': 'payment-id',
          'amount': 10000,
          'type': 'expense',
          'date': '2026-02-12',
          'title': '테스트',
          'memo': '메모',
          'image_url': 'https://example.com/img.jpg',
          'is_recurring': true,
          'recurring_type': 'monthly',
          'recurring_end_date': '2026-12-31',
          'is_fixed_expense': false,
          'fixed_expense_category_id': null,
          'is_asset': false,
          'maturity_date': null,
          'created_at': '2026-02-12T10:00:00.000Z',
          'updated_at': '2026-02-12T11:00:00.000Z',
        };

        final model = TransactionModel.fromJson(originalJson);
        final convertedJson = model.toJson();

        expect(convertedJson['id'], originalJson['id']);
        expect(convertedJson['amount'], originalJson['amount']);
        expect(convertedJson['type'], originalJson['type']);
        expect(convertedJson['date'], originalJson['date']);
        expect(convertedJson['is_recurring'], originalJson['is_recurring']);
        expect(convertedJson['recurring_type'], originalJson['recurring_type']);
      });
    });

    group('엣지 케이스', () {
      test('빈 문자열을 올바르게 처리한다', () {
        final json = {
          'id': 'test-id',
          'ledger_id': 'ledger-id',
          'user_id': 'user-id',
          'amount': 5000,
          'type': 'expense',
          'date': '2026-02-12',
          'title': '',
          'memo': '',
          'is_recurring': false,
          'created_at': '2026-02-12T10:00:00.000',
          'updated_at': '2026-02-12T11:00:00.000',
        };

        final result = TransactionModel.fromJson(json);

        expect(result.title, '');
        expect(result.memo, '');
      });

      test('매우 큰 금액을 처리할 수 있다', () {
        final json = TransactionModel.toCreateJson(
          ledgerId: 'ledger-id',
          userId: 'user-id',
          amount: 999999999,
          type: 'expense',
          date: testDate,
        );

        expect(json['amount'], 999999999);
      });

      test('다양한 타입의 거래를 지원한다', () {
        final income = TransactionModel.toCreateJson(
          ledgerId: 'ledger-id',
          userId: 'user-id',
          amount: 1000,
          type: 'income',
          date: testDate,
        );

        final expense = TransactionModel.toCreateJson(
          ledgerId: 'ledger-id',
          userId: 'user-id',
          amount: 1000,
          type: 'expense',
          date: testDate,
        );

        final asset = TransactionModel.toCreateJson(
          ledgerId: 'ledger-id',
          userId: 'user-id',
          amount: 1000,
          type: 'asset',
          date: testDate,
        );

        expect(income['type'], 'income');
        expect(expense['type'], 'expense');
        expect(asset['type'], 'asset');
      });
    });

    group('recurringTemplateId 필드', () {
      test('fromJson에서 recurring_template_id를 역직렬화한다', () {
        final json = {
          'id': 'test-id',
          'ledger_id': 'ledger-id',
          'user_id': 'user-id',
          'amount': 30000,
          'type': 'expense',
          'date': '2026-02-12',
          'is_recurring': true,
          'recurring_type': 'monthly',
          'recurring_template_id': 'tmpl-uuid-123',
          'created_at': '2026-02-12T10:00:00.000',
          'updated_at': '2026-02-12T11:00:00.000',
        };

        final result = TransactionModel.fromJson(json);
        expect(result.recurringTemplateId, 'tmpl-uuid-123');
      });

      test('toJson에서 recurring_template_id를 직렬화한다', () {
        final model = TransactionModel(
          id: 'test-id',
          ledgerId: 'ledger-id',
          userId: 'user-id',
          amount: 30000,
          type: 'expense',
          date: DateTime(2026, 2, 12),
          isRecurring: true,
          recurringType: 'monthly',
          recurringTemplateId: 'tmpl-uuid-456',
          createdAt: DateTime(2026, 2, 12, 10, 0),
          updatedAt: DateTime(2026, 2, 12, 11, 0),
        );

        final json = model.toJson();
        expect(json['recurring_template_id'], 'tmpl-uuid-456');
      });

      test('recurringTemplateId가 null일 때 toJson에서 null을 출력한다', () {
        final model = TransactionModel(
          id: 'test-id',
          ledgerId: 'ledger-id',
          userId: 'user-id',
          amount: 5000,
          type: 'expense',
          date: DateTime(2026, 2, 12),
          isRecurring: false,
          createdAt: DateTime(2026, 2, 12, 10, 0),
          updatedAt: DateTime(2026, 2, 12, 11, 0),
        );

        final json = model.toJson();
        expect(json['recurring_template_id'], isNull);
      });

      test('fromJson -> toJson 왕복 변환 시 recurring_template_id가 보존된다', () {
        final originalJson = {
          'id': 'test-id',
          'ledger_id': 'ledger-id',
          'user_id': 'user-id',
          'amount': 10000,
          'type': 'expense',
          'date': '2026-02-12',
          'is_recurring': true,
          'recurring_type': 'monthly',
          'recurring_template_id': 'tmpl-roundtrip',
          'is_fixed_expense': false,
          'is_asset': false,
          'created_at': '2026-02-12T10:00:00.000Z',
          'updated_at': '2026-02-12T11:00:00.000Z',
        };

        final model = TransactionModel.fromJson(originalJson);
        final convertedJson = model.toJson();

        expect(convertedJson['recurring_template_id'], 'tmpl-roundtrip');
      });
    });
  });
}
