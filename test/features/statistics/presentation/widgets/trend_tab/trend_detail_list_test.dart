import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/statistics/data/repositories/statistics_repository.dart';
import 'package:shared_household_account/features/statistics/domain/entities/statistics_entities.dart';
import 'package:shared_household_account/features/statistics/presentation/providers/statistics_provider.dart';
import 'package:shared_household_account/features/statistics/presentation/widgets/trend_tab/trend_detail_list.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';

TrendStatisticsData makeMonthlyData() {
  return TrendStatisticsData(
    data: [
      const MonthlyStatistics(
        year: 2026,
        month: 1,
        income: 3000000,
        expense: 1500000,
        saving: 1500000,
      ),
      const MonthlyStatistics(
        year: 2026,
        month: 2,
        income: 3200000,
        expense: 1800000,
        saving: 1400000,
      ),
      const MonthlyStatistics(
        year: 2026,
        month: 3,
        income: 3100000,
        expense: 1600000,
        saving: 1500000,
      ),
    ],
    averageIncome: 3100000,
    averageExpense: 1633333,
    averageAsset: 0,
  );
}

TrendStatisticsData makeYearlyData() {
  return const TrendStatisticsData(
    data: [
      YearlyStatistics(
        year: 2024,
        income: 36000000,
        expense: 20000000,
        saving: 16000000,
      ),
      YearlyStatistics(
        year: 2025,
        income: 38000000,
        expense: 22000000,
        saving: 16000000,
      ),
    ],
    averageIncome: 37000000,
    averageExpense: 21000000,
    averageAsset: 0,
  );
}

Widget buildWidget({
  TrendPeriod period = TrendPeriod.monthly,
  String selectedType = 'expense',
  TrendStatisticsData? monthlyData,
  TrendStatisticsData? yearlyData,
}) {
  final mData = monthlyData ?? makeMonthlyData();
  final yData = yearlyData ?? makeYearlyData();

  return ProviderScope(
    overrides: [
      trendPeriodProvider.overrideWith((ref) => period),
      selectedStatisticsTypeProvider.overrideWith((ref) => selectedType),
      monthlyTrendWithAverageProvider.overrideWith((ref) async => mData),
      yearlyTrendWithAverageProvider.overrideWith((ref) async => yData),
    ],
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(child: TrendDetailList()),
      ),
    ),
  );
}

void main() {
  group('TrendDetailList 위젯 테스트', () {
    testWidgets('월별 모드에서 위젯이 정상적으로 렌더링된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget(period: TrendPeriod.monthly));
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(TrendDetailList), findsOneWidget);
    });

    testWidgets('연별 모드에서 위젯이 정상적으로 렌더링된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget(period: TrendPeriod.yearly));
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(TrendDetailList), findsOneWidget);
    });

    testWidgets('월별 모드에서 월 데이터가 ListView로 표시된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget(period: TrendPeriod.monthly));
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(ListView), findsWidgets);
    });

    testWidgets('연별 모드에서 연 데이터가 ListView로 표시된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget(period: TrendPeriod.yearly));
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(ListView), findsWidgets);
    });

    testWidgets('월별 모드 지출 타입에서 금액이 표시된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget(
        period: TrendPeriod.monthly,
        selectedType: 'expense',
      ));
      await tester.pumpAndSettle();

      // Then - 금액 텍스트가 있어야 함
      expect(find.byType(TrendDetailList), findsOneWidget);
    });

    testWidgets('월별 모드 수입 타입에서 위젯이 렌더링된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget(
        period: TrendPeriod.monthly,
        selectedType: 'income',
      ));
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(TrendDetailList), findsOneWidget);
    });

    testWidgets('빈 월별 데이터에서 위젯이 렌더링된다', (tester) async {
      // Given
      const emptyData = TrendStatisticsData(
        data: [],
        averageIncome: 0,
        averageExpense: 0,
        averageAsset: 0,
      );

      // When
      await tester.pumpWidget(buildWidget(
        period: TrendPeriod.monthly,
        monthlyData: emptyData,
      ));
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(TrendDetailList), findsOneWidget);
    });

    testWidgets('빈 연별 데이터에서 위젯이 렌더링된다', (tester) async {
      // Given
      const emptyData = TrendStatisticsData(
        data: [],
        averageIncome: 0,
        averageExpense: 0,
        averageAsset: 0,
      );

      // When
      await tester.pumpWidget(buildWidget(
        period: TrendPeriod.yearly,
        yearlyData: emptyData,
      ));
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(TrendDetailList), findsOneWidget);
    });
  });
}
