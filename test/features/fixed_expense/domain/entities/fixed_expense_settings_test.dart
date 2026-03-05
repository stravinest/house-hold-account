import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/fixed_expense/domain/entities/fixed_expense_settings.dart';

void main() {
  group('FixedExpenseSettings 엔티티 테스트', () {
    final baseSettings = FixedExpenseSettings(
      id: 'settings-1',
      ledgerId: 'ledger-1',
      userId: 'user-1',
      includeInExpense: true,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 2),
    );

    test('모든 필드가 올바르게 초기화된다', () {
      expect(baseSettings.id, 'settings-1');
      expect(baseSettings.ledgerId, 'ledger-1');
      expect(baseSettings.userId, 'user-1');
      expect(baseSettings.includeInExpense, isTrue);
      expect(baseSettings.createdAt, DateTime(2024, 1, 1));
      expect(baseSettings.updatedAt, DateTime(2024, 1, 2));
    });

    test('includeInExpense가 false인 경우 올바르게 초기화된다', () {
      final settings = FixedExpenseSettings(
        id: 'settings-2',
        ledgerId: 'ledger-1',
        userId: 'user-1',
        includeInExpense: false,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 2),
      );

      expect(settings.includeInExpense, isFalse);
    });

    test('동일한 필드를 가진 두 인스턴스는 동등하다 (Equatable)', () {
      final settings1 = FixedExpenseSettings(
        id: 'settings-1',
        ledgerId: 'ledger-1',
        userId: 'user-1',
        includeInExpense: true,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 2),
      );

      final settings2 = FixedExpenseSettings(
        id: 'settings-1',
        ledgerId: 'ledger-1',
        userId: 'user-1',
        includeInExpense: true,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 2),
      );

      expect(settings1, equals(settings2));
    });

    test('다른 id를 가진 두 인스턴스는 동등하지 않다', () {
      final settings1 = FixedExpenseSettings(
        id: 'settings-1',
        ledgerId: 'ledger-1',
        userId: 'user-1',
        includeInExpense: true,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 2),
      );

      final settings2 = FixedExpenseSettings(
        id: 'settings-2',
        ledgerId: 'ledger-1',
        userId: 'user-1',
        includeInExpense: true,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 2),
      );

      expect(settings1, isNot(equals(settings2)));
    });

    test('includeInExpense가 다르면 동등하지 않다', () {
      final settings1 = FixedExpenseSettings(
        id: 'settings-1',
        ledgerId: 'ledger-1',
        userId: 'user-1',
        includeInExpense: true,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 2),
      );

      final settings2 = FixedExpenseSettings(
        id: 'settings-1',
        ledgerId: 'ledger-1',
        userId: 'user-1',
        includeInExpense: false,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 2),
      );

      expect(settings1, isNot(equals(settings2)));
    });

    test('props 리스트가 모든 필드를 포함한다', () {
      expect(baseSettings.props, [
        'settings-1',
        'ledger-1',
        'user-1',
        true,
        DateTime(2024, 1, 1),
        DateTime(2024, 1, 2),
      ]);
    });
  });
}
