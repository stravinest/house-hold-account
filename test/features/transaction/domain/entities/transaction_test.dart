import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/transaction/domain/entities/transaction.dart';

void main() {
  group('Transaction Entity', () {
    final testDate = DateTime(2026, 2, 12);
    final testCreatedAt = DateTime(2026, 2, 12, 10, 0, 0);
    final testUpdatedAt = DateTime(2026, 2, 12, 11, 0, 0);

    final transaction = Transaction(
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
      fixedExpenseCategoryName: null,
      fixedExpenseCategoryColor: null,
    );

    test('생성자가 모든 필드를 올바르게 초기화한다', () {
      expect(transaction.id, 'test-id');
      expect(transaction.ledgerId, 'ledger-id');
      expect(transaction.userId, 'user-id');
      expect(transaction.categoryId, 'category-id');
      expect(transaction.paymentMethodId, 'payment-id');
      expect(transaction.amount, 10000);
      expect(transaction.type, 'expense');
      expect(transaction.date, testDate);
      expect(transaction.title, '점심 식사');
      expect(transaction.memo, '테스트 메모');
      expect(transaction.imageUrl, 'https://example.com/image.jpg');
      expect(transaction.isRecurring, false);
      expect(transaction.recurringType, null);
      expect(transaction.recurringEndDate, null);
      expect(transaction.isFixedExpense, false);
      expect(transaction.fixedExpenseCategoryId, null);
      expect(transaction.isAsset, false);
      expect(transaction.maturityDate, null);
      expect(transaction.createdAt, testCreatedAt);
      expect(transaction.updatedAt, testUpdatedAt);
      expect(transaction.categoryName, '식비');
      expect(transaction.categoryIcon, '🍔');
      expect(transaction.categoryColor, '#FF5733');
      expect(transaction.userName, '홍길동');
      expect(transaction.userColor, '#4A90E2');
      expect(transaction.paymentMethodName, '신한카드');
    });

    test('기본값이 올바르게 설정된다', () {
      final minimalTransaction = Transaction(
        id: 'test-id',
        ledgerId: 'ledger-id',
        userId: 'user-id',
        amount: 5000,
        type: 'income',
        date: testDate,
        isRecurring: false,
        createdAt: testCreatedAt,
        updatedAt: testUpdatedAt,
      );

      expect(minimalTransaction.isFixedExpense, false);
      expect(minimalTransaction.isAsset, false);
      expect(minimalTransaction.categoryId, null);
      expect(minimalTransaction.paymentMethodId, null);
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
          'date': '2026-02-12T00:00:00.000',
          'title': '월급',
          'memo': '2월 월급',
          'image_url': 'https://example.com/salary.jpg',
          'is_recurring': true,
          'recurring_type': 'monthly',
          'recurring_end_date': '2026-12-31T00:00:00.000',
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
          'payment_methods': {
            'name': '국민은행',
          },
          'fixed_expense_categories': null,
        };

        final result = Transaction.fromJson(json);

        expect(result.id, 'json-id');
        expect(result.amount, 20000);
        expect(result.type, 'income');
        expect(result.title, '월급');
        expect(result.isRecurring, true);
        expect(result.recurringType, 'monthly');
        expect(result.categoryName, '급여');
        expect(result.categoryIcon, '💰');
        expect(result.categoryColor, '#00FF00');
        expect(result.paymentMethodName, '국민은행');
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
          'date': '2026-02-12T00:00:00.000',
          'title': null,
          'memo': null,
          'image_url': null,
          'is_recurring': null,
          'recurring_type': null,
          'recurring_end_date': null,
          'is_fixed_expense': null,
          'fixed_expense_category_id': null,
          'is_asset': null,
          'maturity_date': null,
          'created_at': '2026-02-12T10:00:00.000',
          'updated_at': '2026-02-12T11:00:00.000',
        };

        final result = Transaction.fromJson(json);

        expect(result.categoryId, null);
        expect(result.paymentMethodId, null);
        expect(result.title, null);
        expect(result.memo, null);
        expect(result.imageUrl, null);
        expect(result.isRecurring, false);
        expect(result.isFixedExpense, false);
        expect(result.isAsset, false);
      });

      test('조인된 데이터가 null일 때 올바르게 처리한다', () {
        final json = {
          'id': 'json-id',
          'ledger_id': 'ledger-id',
          'user_id': 'user-id',
          'amount': 5000,
          'type': 'expense',
          'date': '2026-02-12T00:00:00.000',
          'is_recurring': false,
          'created_at': '2026-02-12T10:00:00.000',
          'updated_at': '2026-02-12T11:00:00.000',
          'categories': null,
          'payment_methods': null,
          'fixed_expense_categories': null,
        };

        final result = Transaction.fromJson(json);

        expect(result.categoryName, null);
        expect(result.categoryIcon, null);
        expect(result.categoryColor, null);
        expect(result.paymentMethodName, null);
        expect(result.fixedExpenseCategoryName, null);
        expect(result.fixedExpenseCategoryColor, null);
      });
    });

    group('getter 메서드', () {
      test('isIncome이 올바르게 동작한다', () {
        final income = transaction.copyWith(type: 'income');
        final expense = transaction.copyWith(type: 'expense');

        expect(income.isIncome, true);
        expect(expense.isIncome, false);
      });

      test('isExpense가 올바르게 동작한다', () {
        final income = transaction.copyWith(type: 'income');
        final expense = transaction.copyWith(type: 'expense');

        expect(income.isExpense, false);
        expect(expense.isExpense, true);
      });

      test('isAssetType이 올바르게 동작한다', () {
        final asset = transaction.copyWith(type: 'asset');
        final expense = transaction.copyWith(type: 'expense');

        expect(asset.isAssetType, true);
        expect(expense.isAssetType, false);
      });

      test('isAssetTransaction이 올바르게 동작한다', () {
        final assetTrue = transaction.copyWith(type: 'asset', isAsset: true);
        final assetFalse = transaction.copyWith(type: 'asset', isAsset: false);
        final expenseTrue = transaction.copyWith(type: 'expense', isAsset: true);

        expect(assetTrue.isAssetTransaction, true);
        expect(assetFalse.isAssetTransaction, false);
        expect(expenseTrue.isAssetTransaction, false);
      });
    });

    group('copyWith', () {
      test('특정 필드만 변경된다', () {
        final updated = transaction.copyWith(
          amount: 20000,
          title: '저녁 식사',
        );

        expect(updated.amount, 20000);
        expect(updated.title, '저녁 식사');
        expect(updated.id, transaction.id);
        expect(updated.type, transaction.type);
      });

      test('모든 필드를 변경할 수 있다', () {
        final newDate = DateTime(2026, 3, 1);
        final updated = transaction.copyWith(
          id: 'new-id',
          amount: 30000,
          type: 'income',
          date: newDate,
        );

        expect(updated.id, 'new-id');
        expect(updated.amount, 30000);
        expect(updated.type, 'income');
        expect(updated.date, newDate);
      });

      test('인자가 없으면 원본과 동일한 객체를 반환한다', () {
        final copied = transaction.copyWith();

        expect(copied.id, transaction.id);
        expect(copied.amount, transaction.amount);
        expect(copied.type, transaction.type);
      });
    });

    group('Equatable', () {
      test('동일한 속성을 가진 객체는 같다고 판단된다', () {
        final transaction1 = Transaction(
          id: 'test-id',
          ledgerId: 'ledger-id',
          userId: 'user-id',
          amount: 10000,
          type: 'expense',
          date: testDate,
          isRecurring: false,
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        final transaction2 = Transaction(
          id: 'test-id',
          ledgerId: 'ledger-id',
          userId: 'user-id',
          amount: 10000,
          type: 'expense',
          date: testDate,
          isRecurring: false,
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        expect(transaction1, transaction2);
      });

      test('다른 속성을 가진 객체는 다르다고 판단된다', () {
        final transaction1 = Transaction(
          id: 'test-id-1',
          ledgerId: 'ledger-id',
          userId: 'user-id',
          amount: 10000,
          type: 'expense',
          date: testDate,
          isRecurring: false,
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        final transaction2 = Transaction(
          id: 'test-id-2',
          ledgerId: 'ledger-id',
          userId: 'user-id',
          amount: 10000,
          type: 'expense',
          date: testDate,
          isRecurring: false,
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        expect(transaction1, isNot(transaction2));
      });

      test('조인된 필드는 equality 비교에 포함되지 않는다', () {
        final transaction1 = Transaction(
          id: 'test-id',
          ledgerId: 'ledger-id',
          userId: 'user-id',
          amount: 10000,
          type: 'expense',
          date: testDate,
          isRecurring: false,
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
          categoryName: '식비',
        );

        final transaction2 = Transaction(
          id: 'test-id',
          ledgerId: 'ledger-id',
          userId: 'user-id',
          amount: 10000,
          type: 'expense',
          date: testDate,
          isRecurring: false,
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
          categoryName: '교통비',
        );

        expect(transaction1, transaction2);
      });
    });

    group('엣지 케이스', () {
      test('매우 큰 금액을 처리할 수 있다', () {
        final largeAmount = Transaction(
          id: 'test-id',
          ledgerId: 'ledger-id',
          userId: 'user-id',
          amount: 999999999,
          type: 'expense',
          date: testDate,
          isRecurring: false,
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        expect(largeAmount.amount, 999999999);
      });

      test('빈 문자열을 title과 memo로 설정할 수 있다', () {
        final emptyStrings = Transaction(
          id: 'test-id',
          ledgerId: 'ledger-id',
          userId: 'user-id',
          amount: 1000,
          type: 'expense',
          date: testDate,
          title: '',
          memo: '',
          isRecurring: false,
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        expect(emptyStrings.title, '');
        expect(emptyStrings.memo, '');
      });

      test('반복 거래의 모든 타입을 지원한다', () {
        final daily = transaction.copyWith(
          isRecurring: true,
          recurringType: 'daily',
        );
        final monthly = transaction.copyWith(
          isRecurring: true,
          recurringType: 'monthly',
        );
        final yearly = transaction.copyWith(
          isRecurring: true,
          recurringType: 'yearly',
        );

        expect(daily.recurringType, 'daily');
        expect(monthly.recurringType, 'monthly');
        expect(yearly.recurringType, 'yearly');
      });
    });
  });
}
