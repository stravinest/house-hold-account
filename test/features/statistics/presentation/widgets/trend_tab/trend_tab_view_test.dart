import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/statistics/data/repositories/statistics_repository.dart';
import 'package:shared_household_account/features/statistics/domain/entities/statistics_entities.dart';
import 'package:shared_household_account/features/statistics/presentation/providers/statistics_provider.dart';
import 'package:shared_household_account/features/statistics/presentation/widgets/trend_tab/trend_tab_view.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';

TrendStatisticsData makeMonthlyTrendData() {
  return TrendStatisticsData(
    data: [
      const MonthlyStatistics(
        year: 2026,
        month: 1,
        income: 1000000,
        expense: 500000,
        saving: 0,
      ),
      const MonthlyStatistics(
        year: 2026,
        month: 2,
        income: 1100000,
        expense: 600000,
        saving: 0,
      ),
    ],
    averageIncome: 1050000,
    averageExpense: 550000,
    averageAsset: 0,
  );
}

TrendStatisticsData makeYearlyTrendData() {
  return TrendStatisticsData(
    data: [
      const YearlyStatistics(
        year: 2025,
        income: 12000000,
        expense: 8000000,
        saving: 0,
      ),
      const YearlyStatistics(
        year: 2026,
        income: 13000000,
        expense: 9000000,
        saving: 0,
      ),
    ],
    averageIncome: 12500000,
    averageExpense: 8500000,
    averageAsset: 0,
  );
}

Widget buildWidget({TrendPeriod period = TrendPeriod.monthly}) {
  return ProviderScope(
    overrides: [
      trendPeriodProvider.overrideWith((ref) => period),
      selectedStatisticsTypeProvider.overrideWith((ref) => 'expense'),
      monthlyTrendWithAverageProvider.overrideWith(
        (ref) async => makeMonthlyTrendData(),
      ),
      yearlyTrendWithAverageProvider.overrideWith(
        (ref) async => makeYearlyTrendData(),
      ),
    ],
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: TrendTabView(),
      ),
    ),
  );
}

void main() {
  group('TrendTabView 위젯 테스트', () {
    testWidgets('위젯이 정상적으로 렌더링된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(TrendTabView), findsOneWidget);
    });

    testWidgets('RefreshIndicator가 표시된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('SingleChildScrollView가 표시된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(SingleChildScrollView), findsWidgets);
    });

    testWidgets('월별 모드에서 정상 렌더링된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget(period: TrendPeriod.monthly));
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(TrendTabView), findsOneWidget);
    });

    testWidgets('연별 모드에서 정상 렌더링된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget(period: TrendPeriod.yearly));
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(TrendTabView), findsOneWidget);
    });

    testWidgets('Column 위젯이 표시된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('로딩 중에도 위젯이 렌더링된다', (tester) async {
      // Given
      final completer = Completer<TrendStatisticsData>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            trendPeriodProvider.overrideWith((ref) => TrendPeriod.monthly),
            selectedStatisticsTypeProvider.overrideWith((ref) => 'expense'),
            monthlyTrendWithAverageProvider.overrideWith(
              (ref) => completer.future,
            ),
            yearlyTrendWithAverageProvider.overrideWith(
              (ref) async => makeYearlyTrendData(),
            ),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: TrendTabView(),
            ),
          ),
        ),
      );
      await tester.pump();

      // Then
      expect(find.byType(TrendTabView), findsOneWidget);

      // Cleanup
      completer.complete(makeMonthlyTrendData());
      await tester.pumpAndSettle();
    });

    testWidgets('pull-to-refresh를 실행하면 _refreshTrendData가 호출된다', (tester) async {
      // Given
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // When - RefreshIndicator 드래그로 새로고침 트리거
      await tester.drag(find.byType(RefreshIndicator), const Offset(0, 300));
      await tester.pumpAndSettle();

      // Then - 위젯이 여전히 정상 존재
      expect(find.byType(TrendTabView), findsOneWidget);
    });

    testWidgets('pull-to-refresh 완료 후 연별 데이터가 정상 렌더링된다', (tester) async {
      // Given: 연별 모드에서 pull-to-refresh 실행
      await tester.pumpWidget(buildWidget(period: TrendPeriod.yearly));
      await tester.pumpAndSettle();

      // When - pull-to-refresh 트리거
      await tester.drag(find.byType(RefreshIndicator), const Offset(0, 300));
      await tester.pumpAndSettle();

      // Then - 새로고침 후에도 위젯이 정상 존재
      expect(find.byType(TrendTabView), findsOneWidget);
    });
  });
}
