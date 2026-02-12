import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/ledger/presentation/providers/monthly_list_view_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('MonthlyListViewProvider Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    group('MonthlyViewTypeNotifier', () {
      test('기본값은 calendar이다', () {
        // Given
        SharedPreferences.setMockInitialValues({});

        // When
        final notifier = MonthlyViewTypeNotifier();

        // Then
        expect(notifier.state, equals(MonthlyViewType.calendar));
      });

      test('toggle은 calendar와 list를 전환한다', () async {
        // Given
        SharedPreferences.setMockInitialValues({});
        final notifier = MonthlyViewTypeNotifier();

        // When: calendar → list
        await notifier.toggle();

        // Then
        expect(notifier.state, equals(MonthlyViewType.list));

        // When: list → calendar
        await notifier.toggle();

        // Then
        expect(notifier.state, equals(MonthlyViewType.calendar));
      });

      test('toggle은 SharedPreferences에 저장한다', () async {
        // Given
        SharedPreferences.setMockInitialValues({});
        final notifier = MonthlyViewTypeNotifier();

        // When
        await notifier.toggle();

        // Then
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('monthly_view_type'), equals('list'));
      });
    });

    group('TransactionFilter', () {
      test('TransactionFilter enum이 올바르게 정의되어 있다', () {
        // Then
        expect(TransactionFilter.values.length, equals(5));
        expect(TransactionFilter.values.contains(TransactionFilter.all), isTrue);
        expect(TransactionFilter.values.contains(TransactionFilter.recurring),
            isTrue);
        expect(TransactionFilter.values.contains(TransactionFilter.income),
            isTrue);
        expect(TransactionFilter.values.contains(TransactionFilter.expense),
            isTrue);
        expect(TransactionFilter.values.contains(TransactionFilter.asset),
            isTrue);
      });
    });
  });
}
