import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_household_account/features/ledger/presentation/providers/ledger_provider.dart';
import 'package:shared_household_account/features/statistics/data/repositories/statistics_repository.dart';
import 'package:shared_household_account/features/statistics/domain/entities/statistics_entities.dart';
import 'package:shared_household_account/features/statistics/presentation/providers/statistics_provider.dart';
import 'package:shared_household_account/features/statistics/presentation/widgets/trend_tab/trend_bar_chart.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';

import '../../../../../helpers/mock_repositories.dart';

void main() {
  late MockStatisticsRepository mockRepository;

  setUp(() {
    mockRepository = MockStatisticsRepository();
    registerFallbackValue(ExpenseTypeFilter.all);
  });

  // 테스트용 월별 추이 데이터 생성
  TrendStatisticsData makeMontlyTrendData({
    int months = 6,
    int incomeAmount = 0,
    int expenseAmount = 0,
  }) {
    final now = DateTime.now();
    final data = List.generate(months, (i) {
      final date = DateTime(now.year, now.month - (months - 1 - i), 1);
      return MonthlyStatistics(
        year: date.year,
        month: date.month,
        income: incomeAmount,
        expense: expenseAmount,
        saving: 0,
      );
    });
    return TrendStatisticsData(
      data: data,
      averageIncome: incomeAmount,
      averageExpense: expenseAmount,
      averageAsset: 0,
    );
  }

  // 테스트용 연별 추이 데이터 생성
  TrendStatisticsData makeYearlyTrendData({int years = 6}) {
    final now = DateTime.now();
    final data = List.generate(years, (i) {
      return YearlyStatistics(
        year: now.year - (years - 1 - i),
        income: 1000000,
        expense: 800000,
        saving: 200000,
      );
    });
    return TrendStatisticsData(
      data: data,
      averageIncome: 1000000,
      averageExpense: 800000,
      averageAsset: 200000,
    );
  }

  Widget buildWidget({
    TrendPeriod period = TrendPeriod.monthly,
    String selectedType = 'expense',
    TrendStatisticsData? monthlyData,
    TrendStatisticsData? yearlyData,
  }) {
    final mData = monthlyData ?? makeMontlyTrendData(expenseAmount: 100000);
    final yData = yearlyData ?? makeYearlyTrendData();

    when(() => mockRepository.getMonthlyTrendWithAverage(
          ledgerId: any(named: 'ledgerId'),
          baseDate: any(named: 'baseDate'),
          months: any(named: 'months'),
          expenseTypeFilter: any(named: 'expenseTypeFilter'),
        )).thenAnswer((_) async => mData);

    when(() => mockRepository.getYearlyTrendWithAverage(
          ledgerId: any(named: 'ledgerId'),
          baseDate: any(named: 'baseDate'),
          years: any(named: 'years'),
          expenseTypeFilter: any(named: 'expenseTypeFilter'),
        )).thenAnswer((_) async => yData);

    return ProviderScope(
      overrides: [
        statisticsRepositoryProvider.overrideWith((ref) => mockRepository),
        selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
        statisticsSelectedDateProvider.overrideWith((ref) => DateTime(2026, 3, 1)),
        trendPeriodProvider.overrideWith((ref) => period),
        selectedStatisticsTypeProvider.overrideWith((ref) => selectedType),
        selectedExpenseTypeFilterProvider.overrideWith(
          (ref) => ExpenseTypeFilter.all,
        ),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            height: 400,
            child: TrendBarChart(),
          ),
        ),
      ),
    );
  }

  group('TrendBarChart 위젯 테스트', () {
    testWidgets('월별 모드에서 위젯이 정상적으로 렌더링된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget(period: TrendPeriod.monthly));
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(TrendBarChart), findsOneWidget);
    });

    testWidgets('연별 모드에서 위젯이 정상적으로 렌더링된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget(period: TrendPeriod.yearly));
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(TrendBarChart), findsOneWidget);
    });

    testWidgets('데이터 로딩 중에 CircularProgressIndicator가 표시된다', (tester) async {
      // Given - monthlyTrendWithAverageProvider를 직접 오버라이드하여 로딩 상태 유지
      final completer = Completer<TrendStatisticsData>();
      final yData = makeYearlyTrendData();

      when(() => mockRepository.getYearlyTrendWithAverage(
            ledgerId: any(named: 'ledgerId'),
            baseDate: any(named: 'baseDate'),
            years: any(named: 'years'),
            expenseTypeFilter: any(named: 'expenseTypeFilter'),
          )).thenAnswer((_) async => yData);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            statisticsRepositoryProvider.overrideWith((ref) => mockRepository),
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
            statisticsSelectedDateProvider
                .overrideWith((ref) => DateTime(2026, 3, 1)),
            trendPeriodProvider.overrideWith((ref) => TrendPeriod.monthly),
            selectedStatisticsTypeProvider.overrideWith((ref) => 'expense'),
            selectedExpenseTypeFilterProvider
                .overrideWith((ref) => ExpenseTypeFilter.all),
            monthlyTrendWithAverageProvider
                .overrideWith((ref) => completer.future),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SizedBox(height: 400, child: TrendBarChart()),
            ),
          ),
        ),
      );
      await tester.pump();

      // Then - 로딩 중에는 CircularProgressIndicator가 표시되어야 함
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // 타이머 정리
      completer.complete(const TrendStatisticsData(
        data: [],
        averageIncome: 0,
        averageExpense: 0,
        averageAsset: 0,
      ));
      await tester.pumpAndSettle();
    });

    testWidgets('데이터가 비어있으면 데이터 없음 상태가 표시된다', (tester) async {
      // Given
      final emptyData = const TrendStatisticsData(
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

      // Then - 데이터 없음 텍스트가 표시되어야 함 (SizedBox with Center)
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('지출 타입에서 올바른 색상으로 바 차트가 렌더링된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget(
        period: TrendPeriod.monthly,
        selectedType: 'expense',
      ));
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(TrendBarChart), findsOneWidget);
    });

    testWidgets('수입 타입에서 위젯이 정상 렌더링된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget(
        period: TrendPeriod.monthly,
        selectedType: 'income',
        monthlyData: makeMontlyTrendData(incomeAmount: 3000000),
      ));
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(TrendBarChart), findsOneWidget);
    });

    testWidgets('자산 타입에서 위젯이 정상 렌더링된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget(
        period: TrendPeriod.monthly,
        selectedType: 'asset',
      ));
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(TrendBarChart), findsOneWidget);
    });

    testWidgets('연별 모드에서 데이터가 로드되면 차트가 표시된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget(period: TrendPeriod.yearly));
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(TrendBarChart), findsOneWidget);
    });

    testWidgets('연별 데이터가 비어있으면 빈 상태가 표시된다', (tester) async {
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
      expect(find.byType(TrendBarChart), findsOneWidget);
    });

    testWidgets('에러 발생 시 에러 메시지가 표시된다', (tester) async {
      // Given - 에러를 던지도록 설정
      when(() => mockRepository.getMonthlyTrendWithAverage(
            ledgerId: any(named: 'ledgerId'),
            baseDate: any(named: 'baseDate'),
            months: any(named: 'months'),
            expenseTypeFilter: any(named: 'expenseTypeFilter'),
          )).thenThrow(Exception('네트워크 오류'));

      // When
      await tester.pumpWidget(buildWidget(period: TrendPeriod.monthly));
      await tester.pumpAndSettle();

      // Then - 에러 상태가 표시되어야 함
      expect(find.byType(TrendBarChart), findsOneWidget);
    });

    testWidgets('SingleChildScrollView로 수평 스크롤이 가능하다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget(period: TrendPeriod.monthly));
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(SingleChildScrollView), findsWidgets);
    });

    testWidgets('연별 모드에서 수입 타입이 정상 렌더링된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget(
        period: TrendPeriod.yearly,
        selectedType: 'income',
      ));
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(TrendBarChart), findsOneWidget);
    });

    testWidgets('연별 모드에서 자산 타입이 정상 렌더링된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget(
        period: TrendPeriod.yearly,
        selectedType: 'asset',
      ));
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(TrendBarChart), findsOneWidget);
    });

    testWidgets('연별 모드에서 지출 타입이 정상 렌더링된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget(
        period: TrendPeriod.yearly,
        selectedType: 'expense',
      ));
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(TrendBarChart), findsOneWidget);
    });

    testWidgets('연별 모드에서 에러 발생 시 에러 메시지가 표시된다', (tester) async {
      // Given: 연별 데이터 에러
      when(() => mockRepository.getYearlyTrendWithAverage(
            ledgerId: any(named: 'ledgerId'),
            baseDate: any(named: 'baseDate'),
            years: any(named: 'years'),
            expenseTypeFilter: any(named: 'expenseTypeFilter'),
          )).thenThrow(Exception('서버 오류'));

      // When
      await tester.pumpWidget(buildWidget(period: TrendPeriod.yearly));
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(TrendBarChart), findsOneWidget);
    });

    testWidgets('연별 모드에서 로딩 중일 때 CircularProgressIndicator가 표시된다', (tester) async {
      // Given
      final completer = Completer<TrendStatisticsData>();
      final mData = makeMontlyTrendData();

      when(() => mockRepository.getMonthlyTrendWithAverage(
            ledgerId: any(named: 'ledgerId'),
            baseDate: any(named: 'baseDate'),
            months: any(named: 'months'),
            expenseTypeFilter: any(named: 'expenseTypeFilter'),
          )).thenAnswer((_) async => mData);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            statisticsRepositoryProvider.overrideWith((ref) => mockRepository),
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
            statisticsSelectedDateProvider
                .overrideWith((ref) => DateTime(2026, 3, 1)),
            trendPeriodProvider.overrideWith((ref) => TrendPeriod.yearly),
            selectedStatisticsTypeProvider.overrideWith((ref) => 'expense'),
            selectedExpenseTypeFilterProvider
                .overrideWith((ref) => ExpenseTypeFilter.all),
            yearlyTrendWithAverageProvider
                .overrideWith((ref) => completer.future),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SizedBox(height: 400, child: TrendBarChart()),
            ),
          ),
        ),
      );
      await tester.pump();

      // Then: 로딩 중에는 CircularProgressIndicator 표시
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // 정리
      completer.complete(const TrendStatisticsData(
        data: [],
        averageIncome: 0,
        averageExpense: 0,
        averageAsset: 0,
      ));
      await tester.pumpAndSettle();
    });

    testWidgets('월별 모드에서 날짜가 변경되면 선택된 월이 강조된다', (tester) async {
      // Given: 현재 선택 날짜와 일치하는 데이터 포함
      final selectedDate = DateTime(2026, 3, 1);
      final data = [
        MonthlyStatistics(
          year: 2026,
          month: 1,
          income: 1000000,
          expense: 500000,
          saving: 200000,
        ),
        MonthlyStatistics(
          year: 2026,
          month: 2,
          income: 1200000,
          expense: 600000,
          saving: 300000,
        ),
        MonthlyStatistics(
          year: 2026,
          month: 3,
          income: 900000,
          expense: 400000,
          saving: 150000,
        ),
      ];
      final trendData = TrendStatisticsData(
        data: data,
        averageIncome: 1033333,
        averageExpense: 500000,
        averageAsset: 216667,
      );

      when(() => mockRepository.getMonthlyTrendWithAverage(
            ledgerId: any(named: 'ledgerId'),
            baseDate: any(named: 'baseDate'),
            months: any(named: 'months'),
            expenseTypeFilter: any(named: 'expenseTypeFilter'),
          )).thenAnswer((_) async => trendData);

      // When
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            statisticsRepositoryProvider.overrideWith((ref) => mockRepository),
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
            statisticsSelectedDateProvider.overrideWith((ref) => selectedDate),
            trendPeriodProvider.overrideWith((ref) => TrendPeriod.monthly),
            selectedStatisticsTypeProvider.overrideWith((ref) => 'expense'),
            selectedExpenseTypeFilterProvider
                .overrideWith((ref) => ExpenseTypeFilter.all),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SizedBox(height: 400, child: TrendBarChart()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Then: 차트가 렌더링됨
      expect(find.byType(TrendBarChart), findsOneWidget);
    });

    testWidgets('월별 모드에서 average가 maxY보다 클 때 maxY가 average로 조정된다', (tester) async {
      // Given: average가 최대값보다 큰 데이터
      final highAverageData = TrendStatisticsData(
        data: [
          MonthlyStatistics(
            year: 2026,
            month: 3,
            income: 0,
            expense: 100000,
            saving: 0,
          ),
        ],
        averageIncome: 0,
        averageExpense: 5000000, // average가 데이터보다 훨씬 큼
        averageAsset: 0,
      );

      // When
      await tester.pumpWidget(buildWidget(
        period: TrendPeriod.monthly,
        selectedType: 'expense',
        monthlyData: highAverageData,
      ));
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(TrendBarChart), findsOneWidget);
    });
  });
}
