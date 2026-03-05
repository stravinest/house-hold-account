import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/statistics/data/repositories/statistics_repository.dart';
import 'package:shared_household_account/features/statistics/domain/entities/statistics_entities.dart';
import 'package:shared_household_account/features/statistics/presentation/pages/statistics_page.dart';
import 'package:shared_household_account/features/statistics/presentation/providers/statistics_provider.dart';
import 'package:shared_household_account/features/share/presentation/providers/share_provider.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';

Widget buildWidget({int tabIndex = 0}) {
  return ProviderScope(
    overrides: [
      statisticsTabIndexProvider.overrideWith((ref) => tabIndex),
      isSharedLedgerProvider.overrideWith((ref) => false),
      categoryStatisticsProvider.overrideWith((ref) async => []),
      categoryExpenseStatisticsProvider.overrideWith((ref) async => []),
      categoryIncomeStatisticsProvider.overrideWith((ref) async => []),
      categoryAssetStatisticsProvider.overrideWith((ref) async => []),
      monthComparisonProvider.overrideWith(
        (ref) async => const MonthComparisonData(
          currentTotal: 0,
          previousTotal: 0,
          difference: 0,
          percentageChange: 0,
        ),
      ),
      categoryDetailStateProvider.overrideWith(
        (ref) => const CategoryDetailState(),
      ),
      selectedStatisticsTypeProvider.overrideWith((ref) => 'expense'),
      selectedExpenseTypeFilterProvider.overrideWith(
        (ref) => ExpenseTypeFilter.all,
      ),
      paymentMethodStatisticsProvider.overrideWith((ref) async => []),
      paymentMethodStatisticsByUserProvider.overrideWith((ref) async => {}),
      paymentMethodDetailStateProvider.overrideWith(
        (ref) => const PaymentMethodDetailState(),
      ),
      paymentMethodSharedStatisticsStateProvider.overrideWith(
        (ref) => const SharedStatisticsState(
            mode: SharedStatisticsMode.combined),
      ),
      selectedPaymentMethodExpenseTypeFilterProvider.overrideWith(
        (ref) => ExpenseTypeFilter.all,
      ),
      trendPeriodProvider.overrideWith((ref) => TrendPeriod.monthly),
      monthlyTrendWithAverageProvider.overrideWith(
        (ref) async => TrendStatisticsData(
          data: [],
          averageIncome: 0,
          averageExpense: 0,
          averageAsset: 0,
        ),
      ),
      yearlyTrendWithAverageProvider.overrideWith(
        (ref) async => TrendStatisticsData(
          data: [],
          averageIncome: 0,
          averageExpense: 0,
          averageAsset: 0,
        ),
      ),
      currentLedgerMembersProvider.overrideWith((ref) async => []),
    ],
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: StatisticsPage(),
      ),
    ),
  );
}

void main() {
  group('StatisticsPage 위젯 테스트', () {
    testWidgets('위젯이 정상적으로 렌더링된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(StatisticsPage), findsOneWidget);
    });

    testWidgets('TabBar가 표시된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(TabBar), findsOneWidget);
    });

    testWidgets('TabBarView가 표시된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(TabBarView), findsOneWidget);
    });

    testWidgets('Tab이 3개 표시된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(Tab), findsNWidgets(3));
    });

    testWidgets('Column 레이아웃으로 구성된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(Column), findsWidgets);
    });
  });
}
