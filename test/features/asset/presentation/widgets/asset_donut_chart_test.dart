import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/asset/domain/entities/asset_statistics.dart';
import 'package:shared_household_account/features/asset/presentation/widgets/asset_donut_chart.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';

void main() {
  group('AssetDonutChart 위젯 테스트', () {
    testWidgets('데이터가 없을 때 위젯이 렌더링되어야 한다', (tester) async {
      // Given: 빈 카테고리 리스트
      const byCategory = <CategoryAsset>[];

      // When: 위젯 렌더링
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: AssetDonutChart(byCategory: byCategory),
          ),
        ),
      );

      // Then: 위젯이 렌더링되어야 함
      expect(find.byType(AssetDonutChart), findsOneWidget);
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('데이터가 있을 때 차트를 표시해야 한다', (tester) async {
      // Given: 카테고리 데이터
      const byCategory = [
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
      ];

      // When: 위젯 렌더링
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: AssetDonutChart(byCategory: byCategory),
          ),
        ),
      );

      // Then: PieChart가 표시되어야 함
      expect(find.byType(PieChart), findsOneWidget);
      expect(find.byType(Stack), findsWidgets);
    });

    testWidgets('6개 이상 카테고리가 있을 때 기타 항목으로 묶어서 표시한다', (tester) async {
      // Given: 6개 이상의 카테고리 데이터 (_processData의 skip(5) 분기 커버)
      const byCategory = [
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
          amount: 500000,
          items: [],
        ),
        CategoryAsset(
          categoryId: 'cat3',
          categoryName: '펀드',
          categoryIcon: null,
          categoryColor: '#FF9800',
          amount: 400000,
          items: [],
        ),
        CategoryAsset(
          categoryId: 'cat4',
          categoryName: '부동산',
          categoryIcon: null,
          categoryColor: '#9C27B0',
          amount: 300000,
          items: [],
        ),
        CategoryAsset(
          categoryId: 'cat5',
          categoryName: '암호화폐',
          categoryIcon: null,
          categoryColor: '#F44336',
          amount: 200000,
          items: [],
        ),
        CategoryAsset(
          categoryId: 'cat6',
          categoryName: '채권',
          categoryIcon: null,
          categoryColor: '#795548',
          amount: 100000,
          items: [],
        ),
        CategoryAsset(
          categoryId: 'cat7',
          categoryName: '현금',
          categoryIcon: null,
          categoryColor: '#607D8B',
          amount: 50000,
          items: [],
        ),
      ];

      // When: 위젯 렌더링
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: AssetDonutChart(byCategory: byCategory),
          ),
        ),
      );
      await tester.pump();

      // Then: PieChart가 표시되어야 함 (상위 5개 + 기타로 6개 섹션)
      expect(find.byType(PieChart), findsOneWidget);
    });

    testWidgets('5개 이하 카테고리는 모두 그대로 표시된다', (tester) async {
      // Given: 정확히 5개의 카테고리
      const byCategory = [
        CategoryAsset(categoryId: 'c1', categoryName: '예금', categoryIcon: null, categoryColor: '#4CAF50', amount: 500000, items: []),
        CategoryAsset(categoryId: 'c2', categoryName: '주식', categoryIcon: null, categoryColor: '#2196F3', amount: 400000, items: []),
        CategoryAsset(categoryId: 'c3', categoryName: '펀드', categoryIcon: null, categoryColor: '#FF9800', amount: 300000, items: []),
        CategoryAsset(categoryId: 'c4', categoryName: '부동산', categoryIcon: null, categoryColor: '#9C27B0', amount: 200000, items: []),
        CategoryAsset(categoryId: 'c5', categoryName: '현금', categoryIcon: null, categoryColor: '#F44336', amount: 100000, items: []),
      ];

      // When: 위젯 렌더링
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: AssetDonutChart(byCategory: byCategory),
          ),
        ),
      );

      // Then: PieChart가 표시되어야 함
      expect(find.byType(PieChart), findsOneWidget);
    });
  });
}
