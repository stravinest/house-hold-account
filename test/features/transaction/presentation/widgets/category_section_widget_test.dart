import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/category/presentation/providers/category_provider.dart';
import 'package:shared_household_account/features/fixed_expense/presentation/providers/fixed_expense_category_provider.dart';
import 'package:shared_household_account/features/ledger/presentation/providers/ledger_provider.dart';
import 'package:shared_household_account/features/transaction/presentation/widgets/category_section_widget.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';

void main() {
  group('CategorySectionWidget 위젯 테스트', () {
    testWidgets('고정비가 아닐 때 위젯이 렌더링되어야 한다', (tester) async {
      // When: 위젯 렌더링
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            expenseCategoriesProvider.overrideWith((ref) async {
              return [];
            }),
            selectedLedgerIdProvider.overrideWith((ref) => 'test-ledger-id'),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: CategorySectionWidget(
                isFixedExpense: false,
                selectedCategory: null,
                selectedFixedExpenseCategory: null,
                transactionType: 'expense',
                onCategorySelected: (_) {},
                onFixedExpenseCategorySelected: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Then: 위젯이 렌더링되어야 함
      expect(find.byType(CategorySectionWidget), findsOneWidget);
      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('고정비일 때 위젯이 렌더링되어야 한다', (tester) async {
      // When: 위젯 렌더링
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            fixedExpenseCategoriesProvider.overrideWith((ref) async {
              return [];
            }),
            selectedLedgerIdProvider.overrideWith((ref) => 'test-ledger-id'),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: CategorySectionWidget(
                isFixedExpense: true,
                selectedCategory: null,
                selectedFixedExpenseCategory: null,
                transactionType: 'expense',
                onCategorySelected: (_) {},
                onFixedExpenseCategorySelected: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Then: 위젯이 렌더링되어야 함
      expect(find.byType(CategorySectionWidget), findsOneWidget);
      expect(find.byType(Column), findsWidgets);
    });
  });
}
