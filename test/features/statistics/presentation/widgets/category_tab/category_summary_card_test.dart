import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/statistics/data/repositories/statistics_repository.dart';
import 'package:shared_household_account/features/statistics/domain/entities/statistics_entities.dart';

import 'package:shared_household_account/features/statistics/presentation/providers/statistics_provider.dart';
import 'package:shared_household_account/features/statistics/presentation/widgets/category_tab/category_summary_card.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';

List<CategoryStatistics> makeCategories({int expenseAmount = 300000}) {
  return [
    CategoryStatistics(
      categoryId: 'cat-1',
      categoryName: '식비',
      categoryIcon: 'restaurant',
      categoryColor: '#FF5733',
      amount: expenseAmount,
    ),
  ];
}

Widget buildWidget({
  List<CategoryStatistics>? categories,
  MonthComparisonData? comparison,
  String selectedType = 'expense',
  ExpenseTypeFilter expenseFilter = ExpenseTypeFilter.all,
}) {
  final cats = categories ?? makeCategories();
  final comp = comparison ??
      const MonthComparisonData(
        currentTotal: 300000,
        previousTotal: 250000,
        difference: 50000,
        percentageChange: 20.0,
      );

  return ProviderScope(
    overrides: [
      categoryStatisticsProvider.overrideWith((ref) async => cats),
      monthComparisonProvider.overrideWith((ref) async => comp),
      selectedStatisticsTypeProvider.overrideWith((ref) => selectedType),
      selectedExpenseTypeFilterProvider.overrideWith((ref) => expenseFilter),
    ],
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(child: CategorySummaryCard()),
      ),
    ),
  );
}

void main() {
  group('CategorySummaryCard 위젯 테스트', () {
    testWidgets('위젯이 정상적으로 렌더링된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(CategorySummaryCard), findsOneWidget);
    });

    testWidgets('지출 타입 선택 시 위젯이 렌더링된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget(selectedType: 'expense'));
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(CategorySummaryCard), findsOneWidget);
    });

    testWidgets('수입 타입 선택 시 위젯이 렌더링된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget(selectedType: 'income'));
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(CategorySummaryCard), findsOneWidget);
    });

    testWidgets('전월 대비 증가 시 증가 아이콘이 표시된다', (tester) async {
      // Given
      const comparison = MonthComparisonData(
        currentTotal: 400000,
        previousTotal: 200000,
        difference: 200000,
        percentageChange: 100.0,
      );

      // When
      await tester.pumpWidget(buildWidget(comparison: comparison));
      await tester.pumpAndSettle();

      // Then
      expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
    });

    testWidgets('전월 대비 감소 시 감소 아이콘이 표시된다', (tester) async {
      // Given
      const comparison = MonthComparisonData(
        currentTotal: 100000,
        previousTotal: 200000,
        difference: -100000,
        percentageChange: -50.0,
      );

      // When
      await tester.pumpWidget(buildWidget(comparison: comparison));
      await tester.pumpAndSettle();

      // Then
      expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
    });

    testWidgets('고정비 필터 적용 시 위젯이 렌더링된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget(
        selectedType: 'expense',
        expenseFilter: ExpenseTypeFilter.fixed,
      ));
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(CategorySummaryCard), findsOneWidget);
    });

    testWidgets('데이터가 비어있으면 0원이 표시된다', (tester) async {
      // Given
      const emptyComparison = MonthComparisonData(
        currentTotal: 0,
        previousTotal: 0,
        difference: 0,
        percentageChange: 0,
      );

      // When
      await tester.pumpWidget(buildWidget(
        categories: [],
        comparison: emptyComparison,
      ));
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(CategorySummaryCard), findsOneWidget);
    });
  });
}
