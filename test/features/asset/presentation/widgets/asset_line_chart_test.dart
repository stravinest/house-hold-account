import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/asset/domain/entities/asset_statistics.dart';
import 'package:shared_household_account/features/asset/presentation/providers/asset_provider.dart';
import 'package:shared_household_account/features/asset/presentation/widgets/asset_line_chart.dart';
import 'package:shared_household_account/features/statistics/domain/entities/statistics_entities.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';

/// AssetLineChart 위젯 테스트 헬퍼: ProviderScope와 함께 MaterialApp을 래핑해서 위젯을 렌더링
Widget buildWidget({
  required List<Override> overrides,
  double width = 400,
  double height = 300,
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SizedBox(
          width: width,
          height: height,
          child: const AssetLineChart(),
        ),
      ),
    ),
  );
}

void main() {
  group('AssetLineChart 위젯 테스트', () {
    group('월별 차트 (TrendPeriod.monthly)', () {
      testWidgets('월별 데이터가 없을 때 빈 상태 텍스트를 표시해야 한다', (tester) async {
        // Given: 월별 데이터 없음, 연별 데이터 없음
        await tester.pumpWidget(
          buildWidget(
            overrides: [
              assetChartPeriodProvider.overrideWith((ref) => TrendPeriod.monthly),
              assetMonthlyChartProvider.overrideWith((ref) async => []),
              assetYearlyChartProvider.overrideWith((ref) async => []),
            ],
          ),
        );
        await tester.pump();

        // Then: 차트 없이 Center 위젯으로 빈 상태 표시
        expect(find.byType(AssetLineChart), findsOneWidget);
        expect(find.byType(Center), findsWidgets);
      });

      testWidgets('월별 데이터가 있을 때 LineChart를 표시해야 한다', (tester) async {
        // Given: 정상적인 월별 데이터 3개월
        const monthlyData = [
          MonthlyAsset(year: 2024, month: 1, amount: 1000000),
          MonthlyAsset(year: 2024, month: 2, amount: 1200000),
          MonthlyAsset(year: 2024, month: 3, amount: 1500000),
        ];

        await tester.pumpWidget(
          buildWidget(
            overrides: [
              assetChartPeriodProvider.overrideWith((ref) => TrendPeriod.monthly),
              assetMonthlyChartProvider.overrideWith((ref) async => monthlyData),
              assetYearlyChartProvider.overrideWith((ref) async => []),
            ],
          ),
        );
        await tester.pumpAndSettle();

        // Then: LineChart가 화면에 표시되어야 함
        expect(find.byType(LineChart), findsOneWidget);
      });

      testWidgets('음수 금액이 포함된 월별 데이터에서 차트가 렌더링되어야 한다', (tester) async {
        // Given: 음수 금액을 포함한 월별 데이터 (minAmount < 0 분기 커버)
        const monthlyData = [
          MonthlyAsset(year: 2024, month: 1, amount: -500000),
          MonthlyAsset(year: 2024, month: 2, amount: 1000000),
          MonthlyAsset(year: 2024, month: 3, amount: 1500000),
        ];

        await tester.pumpWidget(
          buildWidget(
            overrides: [
              assetChartPeriodProvider.overrideWith((ref) => TrendPeriod.monthly),
              assetMonthlyChartProvider.overrideWith((ref) async => monthlyData),
              assetYearlyChartProvider.overrideWith((ref) async => []),
            ],
          ),
        );
        await tester.pumpAndSettle();

        // Then: 음수 범위 포함해도 LineChart가 표시됨
        expect(find.byType(LineChart), findsOneWidget);
      });

      testWidgets('모든 금액이 0인 월별 데이터에서 차트가 렌더링되어야 한다', (tester) async {
        // Given: 모든 금액이 0인 월별 데이터 (maxAmount <= 0 분기 커버)
        const monthlyData = [
          MonthlyAsset(year: 2024, month: 1, amount: 0),
          MonthlyAsset(year: 2024, month: 2, amount: 0),
        ];

        await tester.pumpWidget(
          buildWidget(
            overrides: [
              assetChartPeriodProvider.overrideWith((ref) => TrendPeriod.monthly),
              assetMonthlyChartProvider.overrideWith((ref) async => monthlyData),
              assetYearlyChartProvider.overrideWith((ref) async => []),
            ],
          ),
        );
        await tester.pumpAndSettle();

        // Then: LineChart가 표시되어야 함
        expect(find.byType(LineChart), findsOneWidget);
      });

      testWidgets('단일 월별 데이터 포인트에서 차트가 렌더링되어야 한다', (tester) async {
        // Given: 1개월치 데이터만 존재하는 경우
        const monthlyData = [
          MonthlyAsset(year: 2024, month: 6, amount: 2000000),
        ];

        await tester.pumpWidget(
          buildWidget(
            overrides: [
              assetChartPeriodProvider.overrideWith((ref) => TrendPeriod.monthly),
              assetMonthlyChartProvider.overrideWith((ref) async => monthlyData),
              assetYearlyChartProvider.overrideWith((ref) async => []),
            ],
          ),
        );
        await tester.pumpAndSettle();

        // Then: LineChart가 표시되어야 함
        expect(find.byType(LineChart), findsOneWidget);
      });

      testWidgets('월별 데이터 로딩 중에 CircularProgressIndicator를 표시해야 한다', (tester) async {
        // Given: 완료되지 않는 Completer로 로딩 상태 유지
        final completer = Completer<List<MonthlyAsset>>();

        await tester.pumpWidget(
          buildWidget(
            overrides: [
              assetChartPeriodProvider.overrideWith((ref) => TrendPeriod.monthly),
              assetMonthlyChartProvider.overrideWith(
                (ref) => completer.future,
              ),
              assetYearlyChartProvider.overrideWith((ref) async => []),
            ],
          ),
        );
        await tester.pump();

        // Then: 로딩 인디케이터가 표시되어야 함
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // 정리: Completer 완료
        completer.complete([]);
      });

      testWidgets('월별 데이터 에러 발생 시 에러 메시지를 표시해야 한다', (tester) async {
        // Given: 에러를 throw하는 Future
        await tester.pumpWidget(
          buildWidget(
            overrides: [
              assetChartPeriodProvider.overrideWith((ref) => TrendPeriod.monthly),
              assetMonthlyChartProvider.overrideWith(
                (ref) => Future<List<MonthlyAsset>>.error('데이터 로드 실패'),
              ),
              assetYearlyChartProvider.overrideWith((ref) async => []),
            ],
          ),
        );
        await tester.pumpAndSettle();

        // Then: 에러 메시지가 Text 위젯으로 표시되어야 함
        expect(find.byType(AssetLineChart), findsOneWidget);
        expect(find.byType(Text), findsWidgets);
      });

      testWidgets('차트를 탭하면 차트가 여전히 렌더링되어 있어야 한다', (tester) async {
        // Given: 3개월치 데이터로 터치 인터랙션 테스트
        const monthlyData = [
          MonthlyAsset(year: 2024, month: 1, amount: 1000000),
          MonthlyAsset(year: 2024, month: 2, amount: 1500000),
          MonthlyAsset(year: 2024, month: 3, amount: 2000000),
        ];

        await tester.pumpWidget(
          buildWidget(
            overrides: [
              assetChartPeriodProvider.overrideWith((ref) => TrendPeriod.monthly),
              assetMonthlyChartProvider.overrideWith((ref) async => monthlyData),
              assetYearlyChartProvider.overrideWith((ref) async => []),
            ],
          ),
        );
        await tester.pumpAndSettle();

        // When: 차트 중앙을 탭
        final chartFinder = find.byType(LineChart);
        expect(chartFinder, findsOneWidget);
        await tester.tap(chartFinder);
        await tester.pump();

        // Then: 차트가 여전히 렌더링되어 있어야 함
        expect(find.byType(LineChart), findsOneWidget);
      });

      testWidgets('차트 가장자리를 탭해도 인덱스 범위 밖 케이스가 안전하게 처리되어야 한다', (tester) async {
        // Given: 단일 데이터 포인트 (범위 밖 인덱스 케이스 커버)
        const monthlyData = [
          MonthlyAsset(year: 2024, month: 1, amount: 500000),
        ];

        await tester.pumpWidget(
          buildWidget(
            overrides: [
              assetChartPeriodProvider.overrideWith((ref) => TrendPeriod.monthly),
              assetMonthlyChartProvider.overrideWith((ref) async => monthlyData),
              assetYearlyChartProvider.overrideWith((ref) async => []),
            ],
          ),
        );
        await tester.pumpAndSettle();

        // When: 차트 가장자리 탭 시도
        final chartRect = tester.getRect(find.byType(LineChart));
        await tester.tapAt(Offset(chartRect.right - 1, chartRect.center.dy));
        await tester.pump();

        // Then: 렌더링이 정상적으로 유지되어야 함
        expect(find.byType(LineChart), findsOneWidget);
      });
    });

    group('연별 차트 (TrendPeriod.yearly)', () {
      testWidgets('연별 데이터가 없을 때 빈 상태를 표시해야 한다', (tester) async {
        // Given: 연별 데이터가 없는 경우
        await tester.pumpWidget(
          buildWidget(
            overrides: [
              assetChartPeriodProvider.overrideWith((ref) => TrendPeriod.yearly),
              assetMonthlyChartProvider.overrideWith((ref) async => []),
              assetYearlyChartProvider.overrideWith((ref) async => []),
            ],
          ),
        );
        await tester.pump();

        // Then: 위젯이 렌더링되고 Center 위젯이 표시되어야 함
        expect(find.byType(AssetLineChart), findsOneWidget);
      });

      testWidgets('연별 데이터가 있을 때 LineChart를 표시해야 한다', (tester) async {
        // Given: 2년치 연별 자산 데이터
        const yearlyData = [
          YearlyAsset(year: 2023, amount: 5000000),
          YearlyAsset(year: 2024, amount: 8000000),
        ];

        await tester.pumpWidget(
          buildWidget(
            overrides: [
              assetChartPeriodProvider.overrideWith((ref) => TrendPeriod.yearly),
              assetMonthlyChartProvider.overrideWith((ref) async => []),
              assetYearlyChartProvider.overrideWith((ref) async => yearlyData),
            ],
          ),
        );
        await tester.pumpAndSettle();

        // Then: LineChart가 화면에 표시되어야 함
        expect(find.byType(LineChart), findsOneWidget);
      });

      testWidgets('연별 데이터 로딩 중에 CircularProgressIndicator를 표시해야 한다', (tester) async {
        // Given: 완료되지 않는 Completer로 로딩 상태 유지
        final completer = Completer<List<YearlyAsset>>();

        await tester.pumpWidget(
          buildWidget(
            overrides: [
              assetChartPeriodProvider.overrideWith((ref) => TrendPeriod.yearly),
              assetMonthlyChartProvider.overrideWith((ref) async => []),
              assetYearlyChartProvider.overrideWith(
                (ref) => completer.future,
              ),
            ],
          ),
        );
        await tester.pump();

        // Then: 로딩 인디케이터가 표시되어야 함
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // 정리: Completer 완료
        completer.complete([]);
      });

      testWidgets('연별 단일 데이터 포인트에서 차트가 올바르게 렌더링되어야 한다', (tester) async {
        // Given: 1년치 연별 데이터
        const yearlyData = [
          YearlyAsset(year: 2024, amount: 10000000),
        ];

        await tester.pumpWidget(
          buildWidget(
            overrides: [
              assetChartPeriodProvider.overrideWith((ref) => TrendPeriod.yearly),
              assetMonthlyChartProvider.overrideWith((ref) async => []),
              assetYearlyChartProvider.overrideWith((ref) async => yearlyData),
            ],
          ),
        );
        await tester.pumpAndSettle();

        // Then: LineChart가 정상적으로 표시되어야 함
        expect(find.byType(LineChart), findsOneWidget);
      });

      testWidgets('음수 금액이 포함된 연별 데이터에서 차트가 렌더링되어야 한다', (tester) async {
        // Given: 음수 금액을 포함한 연별 데이터 (부채가 자산을 초과하는 케이스)
        const yearlyData = [
          YearlyAsset(year: 2022, amount: -1000000),
          YearlyAsset(year: 2023, amount: 500000),
          YearlyAsset(year: 2024, amount: 3000000),
        ];

        await tester.pumpWidget(
          buildWidget(
            overrides: [
              assetChartPeriodProvider.overrideWith((ref) => TrendPeriod.yearly),
              assetMonthlyChartProvider.overrideWith((ref) async => []),
              assetYearlyChartProvider.overrideWith((ref) async => yearlyData),
            ],
          ),
        );
        await tester.pumpAndSettle();

        // Then: LineChart가 표시되어야 함
        expect(find.byType(LineChart), findsOneWidget);
      });

      testWidgets('연별 차트를 탭하면 차트가 여전히 렌더링되어 있어야 한다', (tester) async {
        // Given: 3년치 연별 데이터
        const yearlyData = [
          YearlyAsset(year: 2022, amount: 3000000),
          YearlyAsset(year: 2023, amount: 5000000),
          YearlyAsset(year: 2024, amount: 8000000),
        ];

        await tester.pumpWidget(
          buildWidget(
            overrides: [
              assetChartPeriodProvider.overrideWith((ref) => TrendPeriod.yearly),
              assetMonthlyChartProvider.overrideWith((ref) async => []),
              assetYearlyChartProvider.overrideWith((ref) async => yearlyData),
            ],
          ),
        );
        await tester.pumpAndSettle();

        // When: 차트 중앙을 탭
        final chartFinder = find.byType(LineChart);
        expect(chartFinder, findsOneWidget);
        await tester.tap(chartFinder);
        await tester.pump();

        // Then: 차트가 여전히 렌더링되어 있어야 함
        expect(find.byType(LineChart), findsOneWidget);
      });
    });
  });
}
