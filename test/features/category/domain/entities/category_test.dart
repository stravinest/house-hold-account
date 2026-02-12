import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/category/domain/entities/category.dart';

void main() {
  group('Category Entity', () {
    final testCreatedAt = DateTime(2026, 2, 12, 10, 0, 0);

    final category = Category(
      id: 'test-id',
      ledgerId: 'ledger-id',
      name: '식비',
      icon: '🍔',
      color: '#FF5733',
      type: 'expense',
      isDefault: false,
      sortOrder: 0,
      createdAt: testCreatedAt,
    );

    test('생성자가 모든 필드를 올바르게 초기화한다', () {
      expect(category.id, 'test-id');
      expect(category.ledgerId, 'ledger-id');
      expect(category.name, '식비');
      expect(category.icon, '🍔');
      expect(category.color, '#FF5733');
      expect(category.type, 'expense');
      expect(category.isDefault, false);
      expect(category.sortOrder, 0);
      expect(category.createdAt, testCreatedAt);
    });

    group('getter 메서드', () {
      test('isIncome이 올바르게 동작한다', () {
        final income = category.copyWith(type: 'income');
        final expense = category.copyWith(type: 'expense');
        final asset = category.copyWith(type: 'asset');

        expect(income.isIncome, true);
        expect(expense.isIncome, false);
        expect(asset.isIncome, false);
      });

      test('isExpense가 올바르게 동작한다', () {
        final income = category.copyWith(type: 'income');
        final expense = category.copyWith(type: 'expense');
        final asset = category.copyWith(type: 'asset');

        expect(income.isExpense, false);
        expect(expense.isExpense, true);
        expect(asset.isExpense, false);
      });

      test('isAssetType이 올바르게 동작한다', () {
        final income = category.copyWith(type: 'income');
        final expense = category.copyWith(type: 'expense');
        final asset = category.copyWith(type: 'asset');

        expect(income.isAssetType, false);
        expect(expense.isAssetType, false);
        expect(asset.isAssetType, true);
      });
    });

    group('copyWith', () {
      test('특정 필드만 변경된다', () {
        final updated = category.copyWith(
          name: '교통비',
          icon: '🚗',
        );

        expect(updated.name, '교통비');
        expect(updated.icon, '🚗');
        expect(updated.id, category.id);
        expect(updated.type, category.type);
        expect(updated.color, category.color);
      });

      test('모든 필드를 변경할 수 있다', () {
        final newDate = DateTime(2026, 3, 1);
        final updated = category.copyWith(
          id: 'new-id',
          name: '주거비',
          icon: '🏠',
          color: '#00FF00',
          type: 'income',
          isDefault: true,
          sortOrder: 5,
          createdAt: newDate,
        );

        expect(updated.id, 'new-id');
        expect(updated.name, '주거비');
        expect(updated.icon, '🏠');
        expect(updated.color, '#00FF00');
        expect(updated.type, 'income');
        expect(updated.isDefault, true);
        expect(updated.sortOrder, 5);
        expect(updated.createdAt, newDate);
      });

      test('인자가 없으면 원본과 동일한 객체를 반환한다', () {
        final copied = category.copyWith();

        expect(copied.id, category.id);
        expect(copied.name, category.name);
        expect(copied.icon, category.icon);
        expect(copied.type, category.type);
      });
    });

    group('Equatable', () {
      test('동일한 속성을 가진 객체는 같다고 판단된다', () {
        final category1 = Category(
          id: 'test-id',
          ledgerId: 'ledger-id',
          name: '식비',
          icon: '🍔',
          color: '#FF5733',
          type: 'expense',
          isDefault: false,
          sortOrder: 0,
          createdAt: testCreatedAt,
        );

        final category2 = Category(
          id: 'test-id',
          ledgerId: 'ledger-id',
          name: '식비',
          icon: '🍔',
          color: '#FF5733',
          type: 'expense',
          isDefault: false,
          sortOrder: 0,
          createdAt: testCreatedAt,
        );

        expect(category1, category2);
      });

      test('다른 속성을 가진 객체는 다르다고 판단된다', () {
        final category1 = Category(
          id: 'test-id-1',
          ledgerId: 'ledger-id',
          name: '식비',
          icon: '🍔',
          color: '#FF5733',
          type: 'expense',
          isDefault: false,
          sortOrder: 0,
          createdAt: testCreatedAt,
        );

        final category2 = Category(
          id: 'test-id-2',
          ledgerId: 'ledger-id',
          name: '식비',
          icon: '🍔',
          color: '#FF5733',
          type: 'expense',
          isDefault: false,
          sortOrder: 0,
          createdAt: testCreatedAt,
        );

        expect(category1, isNot(category2));
      });
    });

    group('엣지 케이스', () {
      test('다양한 타입의 카테고리를 생성할 수 있다', () {
        final income = Category(
          id: 'income-id',
          ledgerId: 'ledger-id',
          name: '급여',
          icon: '💰',
          color: '#00FF00',
          type: 'income',
          isDefault: true,
          sortOrder: 0,
          createdAt: testCreatedAt,
        );

        final expense = Category(
          id: 'expense-id',
          ledgerId: 'ledger-id',
          name: '식비',
          icon: '🍔',
          color: '#FF5733',
          type: 'expense',
          isDefault: false,
          sortOrder: 1,
          createdAt: testCreatedAt,
        );

        final asset = Category(
          id: 'asset-id',
          ledgerId: 'ledger-id',
          name: '정기예금',
          icon: '🏦',
          color: '#0000FF',
          type: 'asset',
          isDefault: false,
          sortOrder: 2,
          createdAt: testCreatedAt,
        );

        expect(income.type, 'income');
        expect(expense.type, 'expense');
        expect(asset.type, 'asset');
      });

      test('빈 문자열을 이름으로 사용할 수 있다', () {
        final emptyName = Category(
          id: 'test-id',
          ledgerId: 'ledger-id',
          name: '',
          icon: '🍔',
          color: '#FF5733',
          type: 'expense',
          isDefault: false,
          sortOrder: 0,
          createdAt: testCreatedAt,
        );

        expect(emptyName.name, '');
      });

      test('매우 큰 sortOrder 값을 가질 수 있다', () {
        final largeSort = Category(
          id: 'test-id',
          ledgerId: 'ledger-id',
          name: '식비',
          icon: '🍔',
          color: '#FF5733',
          type: 'expense',
          isDefault: false,
          sortOrder: 999999,
          createdAt: testCreatedAt,
        );

        expect(largeSort.sortOrder, 999999);
      });

      test('음수 sortOrder 값을 가질 수 있다', () {
        final negativeSort = Category(
          id: 'test-id',
          ledgerId: 'ledger-id',
          name: '식비',
          icon: '🍔',
          color: '#FF5733',
          type: 'expense',
          isDefault: false,
          sortOrder: -1,
          createdAt: testCreatedAt,
        );

        expect(negativeSort.sortOrder, -1);
      });

      test('다양한 색상 형식을 지원한다', () {
        final hex6 = category.copyWith(color: '#FF5733');
        final hex3 = category.copyWith(color: '#F00');
        final rgb = category.copyWith(color: 'rgb(255,0,0)');

        expect(hex6.color, '#FF5733');
        expect(hex3.color, '#F00');
        expect(rgb.color, 'rgb(255,0,0)');
      });

      test('다양한 아이콘을 지원한다', () {
        final emoji = category.copyWith(icon: '🍔');
        final text = category.copyWith(icon: 'food');
        final unicode = category.copyWith(icon: '\u{1F354}');

        expect(emoji.icon, '🍔');
        expect(text.icon, 'food');
        expect(unicode.icon, '\u{1F354}');
      });
    });
  });
}
