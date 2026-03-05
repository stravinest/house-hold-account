import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/asset/domain/entities/asset_statistics.dart';

void main() {
  group('AssetStatistics 엔티티', () {
    test('동일한 값으로 생성된 두 객체는 같아야 한다', () {
      // Given
      final monthly = [
        const MonthlyAsset(year: 2026, month: 1, amount: 1000000),
      ];
      final byCategory = [
        CategoryAsset(
          categoryId: 'cat-1',
          categoryName: '예금',
          amount: 1000000,
          items: [],
        ),
      ];

      final stats1 = AssetStatistics(
        totalAmount: 5000000,
        monthlyChange: 200000,
        monthlyChangeRate: 4.0,
        annualGrowthRate: 10.0,
        monthly: monthly,
        byCategory: byCategory,
      );

      final stats2 = AssetStatistics(
        totalAmount: 5000000,
        monthlyChange: 200000,
        monthlyChangeRate: 4.0,
        annualGrowthRate: 10.0,
        monthly: monthly,
        byCategory: byCategory,
      );

      // Then
      expect(stats1, equals(stats2));
    });

    test('값이 다른 두 객체는 같지 않아야 한다', () {
      // Given
      final stats1 = AssetStatistics(
        totalAmount: 5000000,
        monthlyChange: 200000,
        monthlyChangeRate: 4.0,
        annualGrowthRate: 10.0,
        monthly: [],
        byCategory: [],
      );

      final stats2 = AssetStatistics(
        totalAmount: 9000000,
        monthlyChange: 100000,
        monthlyChangeRate: 2.0,
        annualGrowthRate: 5.0,
        monthly: [],
        byCategory: [],
      );

      // Then
      expect(stats1, isNot(equals(stats2)));
    });

    test('props가 올바른 필드들을 포함해야 한다', () {
      // Given
      final stats = AssetStatistics(
        totalAmount: 3000000,
        monthlyChange: 100000,
        monthlyChangeRate: 3.33,
        annualGrowthRate: 8.0,
        monthly: [],
        byCategory: [],
      );

      // Then
      expect(stats.props, contains(3000000));
      expect(stats.props, contains(100000));
      expect(stats.props, contains(3.33));
      expect(stats.props, contains(8.0));
    });
  });

  group('MonthlyAsset 엔티티', () {
    test('동일한 값으로 생성된 두 객체는 같아야 한다', () {
      // Given
      const monthly1 = MonthlyAsset(year: 2026, month: 3, amount: 5000000);
      const monthly2 = MonthlyAsset(year: 2026, month: 3, amount: 5000000);

      // Then
      expect(monthly1, equals(monthly2));
    });

    test('값이 다른 두 객체는 같지 않아야 한다', () {
      // Given
      const monthly1 = MonthlyAsset(year: 2026, month: 3, amount: 5000000);
      const monthly2 = MonthlyAsset(year: 2026, month: 4, amount: 5000000);

      // Then
      expect(monthly1, isNot(equals(monthly2)));
    });

    test('props가 year, month, amount를 포함해야 한다', () {
      // Given
      const monthly = MonthlyAsset(year: 2026, month: 3, amount: 5000000);

      // Then
      expect(monthly.props, containsAll([2026, 3, 5000000]));
    });

    test('음수 금액도 저장할 수 있어야 한다', () {
      // Given
      const monthly = MonthlyAsset(year: 2026, month: 1, amount: -100000);

      // Then
      expect(monthly.amount, -100000);
    });
  });

  group('CategoryAsset 엔티티', () {
    test('동일한 값으로 생성된 두 객체는 같아야 한다', () {
      // Given
      final cat1 = CategoryAsset(
        categoryId: 'cat-1',
        categoryName: '예금',
        categoryIcon: 'savings',
        categoryColor: '#4CAF50',
        amount: 1000000,
        items: [],
      );

      final cat2 = CategoryAsset(
        categoryId: 'cat-1',
        categoryName: '예금',
        categoryIcon: 'savings',
        categoryColor: '#4CAF50',
        amount: 1000000,
        items: [],
      );

      // Then
      expect(cat1, equals(cat2));
    });

    test('categoryIcon과 categoryColor가 null인 경우에도 생성되어야 한다', () {
      // Given
      final cat = CategoryAsset(
        categoryId: 'cat-1',
        categoryName: '기타',
        amount: 500000,
        items: [],
      );

      // Then
      expect(cat.categoryIcon, isNull);
      expect(cat.categoryColor, isNull);
      expect(cat.categoryName, '기타');
    });

    test('props가 올바른 필드들을 포함해야 한다', () {
      // Given
      final cat = CategoryAsset(
        categoryId: 'cat-1',
        categoryName: '예금',
        amount: 1000000,
        items: [],
      );

      // Then
      expect(cat.props, contains('cat-1'));
      expect(cat.props, contains('예금'));
      expect(cat.props, contains(1000000));
    });

    test('items 리스트가 포함되어야 한다', () {
      // Given
      final items = [
        const AssetItem(id: 'item-1', title: '정기예금', amount: 500000),
        const AssetItem(id: 'item-2', title: '적금', amount: 300000),
      ];

      final cat = CategoryAsset(
        categoryId: 'cat-1',
        categoryName: '예금',
        amount: 800000,
        items: items,
      );

      // Then
      expect(cat.items.length, 2);
      expect(cat.items[0].title, '정기예금');
    });
  });

  group('AssetItem 엔티티', () {
    test('동일한 값으로 생성된 두 객체는 같아야 한다', () {
      // Given
      const item1 = AssetItem(id: 'item-1', title: '정기예금', amount: 1000000);
      const item2 = AssetItem(id: 'item-1', title: '정기예금', amount: 1000000);

      // Then
      expect(item1, equals(item2));
    });

    test('maturityDate가 null인 경우에도 생성되어야 한다', () {
      // Given
      const item = AssetItem(id: 'item-1', title: '주식', amount: 200000);

      // Then
      expect(item.maturityDate, isNull);
    });

    test('maturityDate가 있는 경우 올바르게 저장되어야 한다', () {
      // Given
      final maturity = DateTime(2027, 12, 31);
      final item = AssetItem(
        id: 'item-1',
        title: '정기예금',
        amount: 5000000,
        maturityDate: maturity,
      );

      // Then
      expect(item.maturityDate, equals(maturity));
    });

    test('props가 id, title, amount, maturityDate를 포함해야 한다', () {
      // Given
      const item = AssetItem(id: 'item-1', title: '정기예금', amount: 1000000);

      // Then
      expect(item.props, containsAll(['item-1', '정기예금', 1000000]));
    });
  });
}
