import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/statistics/domain/entities/statistics_entities.dart';
import 'package:shared_household_account/features/statistics/presentation/widgets/common/expense_type_filter.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';

void main() {
  group('ExpenseTypeFilterWidget 위젯 테스트', () {
    testWidgets('필수 프로퍼티가 올바르게 렌더링된다', (tester) async {
      // Given
      ExpenseTypeFilter? changedFilter;

      // When
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ExpenseTypeFilterWidget(
              selectedFilter: ExpenseTypeFilter.all,
              onChanged: (filter) {
                changedFilter = filter;
              },
            ),
          ),
        ),
      );

      // Then - 위젯이 렌더링되는지만 확인
      expect(find.byType(ExpenseTypeFilterWidget), findsOneWidget);
      expect(changedFilter, isNull);
    });

    testWidgets('선택된 필터에 따라 위젯이 렌더링된다', (tester) async {
      // Given - all 선택
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ExpenseTypeFilterWidget(
              selectedFilter: ExpenseTypeFilter.all,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      // Then
      expect(find.byType(ExpenseTypeFilterWidget), findsOneWidget);
      expect(find.byType(InkWell), findsNWidgets(3)); // 3개의 필터 버튼
    });

    testWidgets('enabled가 false일 때도 렌더링된다', (tester) async {
      // Given
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ExpenseTypeFilterWidget(
              selectedFilter: ExpenseTypeFilter.all,
              onChanged: (_) {},
              enabled: false,
            ),
          ),
        ),
      );

      // Then
      expect(find.byType(ExpenseTypeFilterWidget), findsOneWidget);
    });

    testWidgets('각 ExpenseTypeFilter 값으로 위젯이 생성된다', (tester) async {
      // Given & When - 각 필터 값으로 위젯 생성
      for (final filter in ExpenseTypeFilter.values) {
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: ExpenseTypeFilterWidget(
                selectedFilter: filter,
                onChanged: (_) {},
              ),
            ),
          ),
        );

        // Then - 렌더링 확인
        expect(find.byType(ExpenseTypeFilterWidget), findsOneWidget);

        await tester.pumpWidget(Container());
      }
    });
  });
}
