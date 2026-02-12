import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/asset/domain/entities/asset_statistics.dart';
import 'package:shared_household_account/features/asset/presentation/widgets/asset_line_chart.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';

void main() {
  group('AssetLineChart 위젯 테스트', () {
    testWidgets('데이터가 없을 때 위젯이 렌더링되어야 한다', (tester) async {
      // Given: 빈 월별 데이터
      const monthly = <MonthlyAsset>[];

      // When: 위젯 렌더링
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: AssetLineChart(monthly: monthly),
          ),
        ),
      );

      // Then: 위젯이 렌더링되어야 함
      expect(find.byType(AssetLineChart), findsOneWidget);
      expect(find.byType(Center), findsOneWidget);
    });

    testWidgets('데이터가 있을 때 차트를 표시해야 한다', (tester) async {
      // Given: 월별 데이터
      const monthly = [
        MonthlyAsset(year: 2024, month: 1, amount: 1000000),
        MonthlyAsset(year: 2024, month: 2, amount: 1200000),
        MonthlyAsset(year: 2024, month: 3, amount: 1500000),
      ];

      // When: 위젯 렌더링
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: AssetLineChart(monthly: monthly),
          ),
        ),
      );

      // Then: LineChart가 표시되어야 함
      expect(find.byType(LineChart), findsOneWidget);
    });
  });
}
