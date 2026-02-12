import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/asset/domain/entities/asset_statistics.dart';
import 'package:shared_household_account/features/asset/presentation/widgets/asset_category_list.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';

void main() {
  group('AssetCategoryList 위젯 테스트', () {
    testWidgets('카테고리 데이터가 없을 때 위젯이 렌더링되어야 한다', (tester) async {
      // Given: 빈 카테고리 리스트
      const assetStatistics = AssetStatistics(
        totalAmount: 0,
        monthlyChange: 0,
        monthlyChangeRate: 0,
        annualGrowthRate: 0,
        byCategory: [],
        monthly: [],
      );

      // When: 위젯 렌더링
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: AssetCategoryList(assetStatistics: assetStatistics),
          ),
        ),
      );

      // Then: 위젯이 렌더링되어야 함
      expect(find.byType(AssetCategoryList), findsOneWidget);
    });

    testWidgets('카테고리 데이터가 있을 때 Column을 표시해야 한다', (tester) async {
      // Given: 카테고리 데이터가 있는 통계
      const assetStatistics = AssetStatistics(
        totalAmount: 1000000,
        monthlyChange: 0,
        monthlyChangeRate: 0,
        annualGrowthRate: 0,
        byCategory: [
          CategoryAsset(
            categoryId: 'cat1',
            categoryName: '정기예금',
            categoryIcon: null,
            categoryColor: '#4CAF50',
            amount: 600000,
            items: [],
          ),
          CategoryAsset(
            categoryId: 'cat2',
            categoryName: '주식',
            categoryIcon: null,
            categoryColor: '#2196F3',
            amount: 400000,
            items: [],
          ),
        ],
        monthly: [],
      );

      // When: 위젯 렌더링
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: AssetCategoryList(assetStatistics: assetStatistics),
          ),
        ),
      );

      // Then: Column이 표시되어야 함
      expect(find.byType(Column), findsWidgets);
      expect(find.byType(ExpansionTile), findsNWidgets(2));
    });

    testWidgets('ExpansionTile을 정상적으로 렌더링해야 한다', (tester) async {
      // Given: 하위 아이템이 있는 카테고리
      const assetStatistics = AssetStatistics(
        totalAmount: 1000000,
        monthlyChange: 0,
        monthlyChangeRate: 0,
        annualGrowthRate: 0,
        byCategory: [
          CategoryAsset(
            categoryId: 'cat1',
            categoryName: '정기예금',
            categoryIcon: null,
            categoryColor: '#4CAF50',
            amount: 1000000,
            items: [
              AssetItem(
                id: 'tx1',
                title: '우리은행 예금',
                amount: 500000,
              ),
              AssetItem(
                id: 'tx2',
                title: '신한은행 예금',
                amount: 500000,
              ),
            ],
          ),
        ],
        monthly: [],
      );

      // When: 위젯 렌더링
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: AssetCategoryList(assetStatistics: assetStatistics),
          ),
        ),
      );

      // Then: ExpansionTile이 존재해야 함
      expect(find.byType(ExpansionTile), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });
  });
}
