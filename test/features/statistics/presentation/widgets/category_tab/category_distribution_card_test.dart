import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/statistics/data/repositories/statistics_repository.dart';
import 'package:shared_household_account/features/statistics/presentation/providers/statistics_provider.dart';
import 'package:shared_household_account/features/statistics/presentation/widgets/category_tab/category_distribution_card.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';

List<CategoryStatistics> makeCategories() {
  return [
    const CategoryStatistics(
      categoryId: 'cat-1',
      categoryName: '식비',
      categoryIcon: 'restaurant',
      categoryColor: '#FF5733',
      amount: 300000,
    ),
    const CategoryStatistics(
      categoryId: 'cat-2',
      categoryName: '교통비',
      categoryIcon: 'restaurant',
      categoryColor: '#33C1FF',
      amount: 200000,
    ),
  ];
}

Widget buildWidget({
  List<CategoryStatistics>? categories,
  bool loading = false,
}) {
  final cats = categories ?? makeCategories();

  return ProviderScope(
    overrides: [
      categoryStatisticsProvider.overrideWith(
        (ref) async {
          if (loading) await Completer<void>().future;
          return cats;
        },
      ),
      categoryDetailStateProvider.overrideWith(
        (ref) => const CategoryDetailState(),
      ),
    ],
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(child: CategoryDistributionCard()),
      ),
    ),
  );
}

void main() {
  group('CategoryDistributionCard 위젯 테스트', () {
    testWidgets('위젯이 정상적으로 렌더링된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(CategoryDistributionCard), findsOneWidget);
    });

    testWidgets('카테고리 데이터가 있으면 카드가 렌더링된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Then - 카드가 렌더링되어야 함
      expect(find.byType(CategoryDistributionCard), findsOneWidget);
      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('카테고리 데이터가 비어있으면 위젯은 정상 렌더링된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget(categories: []));
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(CategoryDistributionCard), findsOneWidget);
    });

    testWidgets('퍼센티지가 표시된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Then - 퍼센티지 텍스트가 있어야 함
      expect(find.textContaining('%'), findsWidgets);
    });

    testWidgets('카테고리 항목이 탭 가능한 GestureDetector로 감싸져 있다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(GestureDetector), findsWidgets);
    });
  });
}
