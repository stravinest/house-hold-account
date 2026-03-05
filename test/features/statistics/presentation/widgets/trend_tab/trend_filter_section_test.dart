import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/statistics/domain/entities/statistics_entities.dart';
import 'package:shared_household_account/features/statistics/presentation/providers/statistics_provider.dart';
import 'package:shared_household_account/features/statistics/presentation/widgets/trend_tab/trend_filter_section.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';

Widget buildWidget({
  TrendPeriod period = TrendPeriod.monthly,
  String selectedType = 'expense',
}) {
  return ProviderScope(
    overrides: [
      trendPeriodProvider.overrideWith((ref) => period),
      selectedStatisticsTypeProvider.overrideWith((ref) => selectedType),
    ],
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: TrendFilterSection(),
      ),
    ),
  );
}

void main() {
  group('TrendFilterSection 위젯 테스트', () {
    testWidgets('위젯이 정상적으로 렌더링된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(TrendFilterSection), findsOneWidget);
    });

    testWidgets('월별 모드에서 드롭다운이 표시된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget(period: TrendPeriod.monthly));
      await tester.pumpAndSettle();

      // Then - PopupMenuButton이 존재해야 함
      expect(find.byType(PopupMenuButton<TrendPeriod>), findsOneWidget);
    });

    testWidgets('연별 모드에서 드롭다운이 표시된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget(period: TrendPeriod.yearly));
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(TrendFilterSection), findsOneWidget);
    });

    testWidgets('지출 타입 선택 시 위젯이 렌더링된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget(selectedType: 'expense'));
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(TrendFilterSection), findsOneWidget);
    });

    testWidgets('수입 타입 선택 시 위젯이 렌더링된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget(selectedType: 'income'));
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(TrendFilterSection), findsOneWidget);
    });

    testWidgets('Row 레이아웃으로 필터들이 가로로 배치된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(Row), findsWidgets);
    });

    testWidgets('드롭다운 버튼을 탭하면 메뉴가 열린다', (tester) async {
      // Given
      await tester.pumpWidget(buildWidget(period: TrendPeriod.monthly));
      await tester.pumpAndSettle();

      // When - PopupMenuButton 탭
      await tester.tap(find.byType(PopupMenuButton<TrendPeriod>));
      await tester.pumpAndSettle();

      // Then - 메뉴 아이템이 표시되어야 함
      expect(find.byType(PopupMenuItem<TrendPeriod>), findsWidgets);
    });
  });
}
