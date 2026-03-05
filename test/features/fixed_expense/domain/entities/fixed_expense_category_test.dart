import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/fixed_expense/domain/entities/fixed_expense_category.dart';

void main() {
  group('FixedExpenseCategory 엔티티 테스트', () {
    final testDate = DateTime(2026, 2, 20, 10, 0, 0);

    final category = FixedExpenseCategory(
      id: 'cat-1',
      ledgerId: 'ledger-1',
      name: '월세',
      icon: 'home',
      color: '#FF9800',
      sortOrder: 0,
      createdAt: testDate,
    );

    group('생성자 테스트', () {
      test('모든 필드가 올바르게 설정된다', () {
        // Given / When
        // category 위에서 생성됨

        // Then
        expect(category.id, 'cat-1');
        expect(category.ledgerId, 'ledger-1');
        expect(category.name, '월세');
        expect(category.icon, 'home');
        expect(category.color, '#FF9800');
        expect(category.sortOrder, 0);
        expect(category.createdAt, testDate);
      });

      test('다양한 sortOrder 값으로 생성할 수 있다', () {
        // Given / When
        final category0 = FixedExpenseCategory(
          id: 'cat-0',
          ledgerId: 'ledger-1',
          name: '카테고리0',
          icon: '',
          color: '#FFFFFF',
          sortOrder: 0,
          createdAt: testDate,
        );

        final category5 = FixedExpenseCategory(
          id: 'cat-5',
          ledgerId: 'ledger-1',
          name: '카테고리5',
          icon: '',
          color: '#000000',
          sortOrder: 5,
          createdAt: testDate,
        );

        // Then
        expect(category0.sortOrder, 0);
        expect(category5.sortOrder, 5);
      });

      test('아이콘이 빈 문자열일 수 있다', () {
        // Given / When
        final categoryNoIcon = FixedExpenseCategory(
          id: 'cat-no-icon',
          ledgerId: 'ledger-1',
          name: '아이콘없음',
          icon: '',
          color: '#FF0000',
          sortOrder: 1,
          createdAt: testDate,
        );

        // Then
        expect(categoryNoIcon.icon, '');
      });
    });

    group('Equatable 동등성 테스트', () {
      test('동일한 필드를 가진 두 인스턴스는 동일하다', () {
        // Given
        final category1 = FixedExpenseCategory(
          id: 'cat-1',
          ledgerId: 'ledger-1',
          name: '월세',
          icon: 'home',
          color: '#FF9800',
          sortOrder: 0,
          createdAt: testDate,
        );

        final category2 = FixedExpenseCategory(
          id: 'cat-1',
          ledgerId: 'ledger-1',
          name: '월세',
          icon: 'home',
          color: '#FF9800',
          sortOrder: 0,
          createdAt: testDate,
        );

        // Then
        expect(category1, equals(category2));
        expect(category1 == category2, true);
      });

      test('id가 다르면 동일하지 않다', () {
        // Given
        final category1 = FixedExpenseCategory(
          id: 'cat-1',
          ledgerId: 'ledger-1',
          name: '월세',
          icon: 'home',
          color: '#FF9800',
          sortOrder: 0,
          createdAt: testDate,
        );

        final category2 = FixedExpenseCategory(
          id: 'cat-2',
          ledgerId: 'ledger-1',
          name: '월세',
          icon: 'home',
          color: '#FF9800',
          sortOrder: 0,
          createdAt: testDate,
        );

        // Then
        expect(category1, isNot(equals(category2)));
      });

      test('name이 다르면 동일하지 않다', () {
        // Given
        final category1 = FixedExpenseCategory(
          id: 'cat-1',
          ledgerId: 'ledger-1',
          name: '월세',
          icon: 'home',
          color: '#FF9800',
          sortOrder: 0,
          createdAt: testDate,
        );

        final category2 = FixedExpenseCategory(
          id: 'cat-1',
          ledgerId: 'ledger-1',
          name: '통신비',
          icon: 'home',
          color: '#FF9800',
          sortOrder: 0,
          createdAt: testDate,
        );

        // Then
        expect(category1, isNot(equals(category2)));
      });

      test('color가 다르면 동일하지 않다', () {
        // Given
        final category1 = FixedExpenseCategory(
          id: 'cat-1',
          ledgerId: 'ledger-1',
          name: '월세',
          icon: 'home',
          color: '#FF9800',
          sortOrder: 0,
          createdAt: testDate,
        );

        final category2 = FixedExpenseCategory(
          id: 'cat-1',
          ledgerId: 'ledger-1',
          name: '월세',
          icon: 'home',
          color: '#000000',
          sortOrder: 0,
          createdAt: testDate,
        );

        // Then
        expect(category1, isNot(equals(category2)));
      });

      test('sortOrder가 다르면 동일하지 않다', () {
        // Given
        final category1 = FixedExpenseCategory(
          id: 'cat-1',
          ledgerId: 'ledger-1',
          name: '월세',
          icon: 'home',
          color: '#FF9800',
          sortOrder: 0,
          createdAt: testDate,
        );

        final category2 = FixedExpenseCategory(
          id: 'cat-1',
          ledgerId: 'ledger-1',
          name: '월세',
          icon: 'home',
          color: '#FF9800',
          sortOrder: 1,
          createdAt: testDate,
        );

        // Then
        expect(category1, isNot(equals(category2)));
      });

      test('ledgerId가 다르면 동일하지 않다', () {
        // Given
        final category1 = FixedExpenseCategory(
          id: 'cat-1',
          ledgerId: 'ledger-1',
          name: '월세',
          icon: 'home',
          color: '#FF9800',
          sortOrder: 0,
          createdAt: testDate,
        );

        final category2 = FixedExpenseCategory(
          id: 'cat-1',
          ledgerId: 'ledger-2',
          name: '월세',
          icon: 'home',
          color: '#FF9800',
          sortOrder: 0,
          createdAt: testDate,
        );

        // Then
        expect(category1, isNot(equals(category2)));
      });

      test('createdAt이 다르면 동일하지 않다', () {
        // Given
        final category1 = FixedExpenseCategory(
          id: 'cat-1',
          ledgerId: 'ledger-1',
          name: '월세',
          icon: 'home',
          color: '#FF9800',
          sortOrder: 0,
          createdAt: DateTime(2026, 2, 20),
        );

        final category2 = FixedExpenseCategory(
          id: 'cat-1',
          ledgerId: 'ledger-1',
          name: '월세',
          icon: 'home',
          color: '#FF9800',
          sortOrder: 0,
          createdAt: DateTime(2026, 2, 21),
        );

        // Then
        expect(category1, isNot(equals(category2)));
      });
    });

    group('props 테스트', () {
      test('props에 모든 필드가 포함된다', () {
        // When
        final props = category.props;

        // Then
        expect(props, contains('cat-1'));
        expect(props, contains('ledger-1'));
        expect(props, contains('월세'));
        expect(props, contains('home'));
        expect(props, contains('#FF9800'));
        expect(props, contains(0));
        expect(props, contains(testDate));
      });

      test('props의 길이가 7이다 (id, ledgerId, name, icon, color, sortOrder, createdAt)', () {
        // When
        final props = category.props;

        // Then
        expect(props.length, 7);
      });
    });

    group('hashCode 테스트', () {
      test('동일한 객체는 같은 hashCode를 가진다', () {
        // Given
        final category1 = FixedExpenseCategory(
          id: 'cat-1',
          ledgerId: 'ledger-1',
          name: '월세',
          icon: 'home',
          color: '#FF9800',
          sortOrder: 0,
          createdAt: testDate,
        );

        final category2 = FixedExpenseCategory(
          id: 'cat-1',
          ledgerId: 'ledger-1',
          name: '월세',
          icon: 'home',
          color: '#FF9800',
          sortOrder: 0,
          createdAt: testDate,
        );

        // Then
        expect(category1.hashCode, equals(category2.hashCode));
      });
    });
  });
}
