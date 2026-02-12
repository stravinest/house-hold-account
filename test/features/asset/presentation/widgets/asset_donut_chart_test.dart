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
  });
}
