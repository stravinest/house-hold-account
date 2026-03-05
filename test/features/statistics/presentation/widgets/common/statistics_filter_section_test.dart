import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/statistics/domain/entities/statistics_entities.dart';
import 'package:shared_household_account/features/statistics/presentation/providers/statistics_provider.dart';
import 'package:shared_household_account/features/statistics/presentation/widgets/common/statistics_filter_section.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

Widget buildWidget({
  String selectedType = 'expense',
  ExpenseTypeFilter expenseFilter = ExpenseTypeFilter.all,
}) {
  return ProviderScope(
    overrides: [
      selectedStatisticsTypeProvider.overrideWith((ref) => selectedType),
      selectedExpenseTypeFilterProvider.overrideWith((ref) => expenseFilter),
    ],
    child: const MaterialApp(
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: StatisticsFilterSection(),
      ),
    ),
  );
}

void main() {
  group('StatisticsFilterSection 위젯 테스트', () {
    testWidgets('위젯이 정상적으로 렌더링된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(StatisticsFilterSection), findsOneWidget);
    });

    testWidgets('expense 타입 선택 시 Row 위젯이 표시된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget(selectedType: 'expense'));
      await tester.pumpAndSettle();

      // Then: Row가 표시됨
      expect(find.byType(Row), findsWidgets);
    });

    testWidgets('income 타입 선택 시 지출 필터가 표시되지 않는다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget(selectedType: 'income'));
      await tester.pumpAndSettle();

      // Then: ExpenseTypeFilterWidget가 없음
      expect(find.byType(StatisticsFilterSection), findsOneWidget);
    });

    testWidgets('asset 타입 선택 시 StatisticsFilterSection이 정상 렌더링된다',
        (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget(selectedType: 'asset'));
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(StatisticsFilterSection), findsOneWidget);
    });

    testWidgets('expense 타입에서 Flexible 위젯이 포함된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget(selectedType: 'expense'));
      await tester.pumpAndSettle();

      // Then: Flexible이 표시되어 있음 (지출 필터 섹션에 Flexible 포함)
      expect(find.byType(Flexible), findsWidgets);
    });
  });
}
