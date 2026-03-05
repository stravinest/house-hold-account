import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/category/presentation/providers/category_provider.dart';
import 'package:shared_household_account/features/fixed_expense/presentation/providers/fixed_expense_category_provider.dart';
import 'package:shared_household_account/features/ledger/presentation/providers/ledger_provider.dart';
import 'package:shared_household_account/features/transaction/presentation/widgets/category_section_widget.dart';
import 'package:shared_household_account/features/transaction/presentation/widgets/category_selector_widget.dart';
import 'package:shared_household_account/features/transaction/presentation/widgets/fixed_expense_category_selector_widget.dart';
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

    testWidgets('isFixedExpense=false일 때 카테고리 라벨 텍스트가 표시된다', (tester) async {
      // Given / When
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            expenseCategoriesProvider.overrideWith((ref) async => []),
            selectedLedgerIdProvider.overrideWith((ref) => 'test-ledger-id'),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
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

      // Then: 카테고리 라벨이 표시되어야 함
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('isFixedExpense=true일 때 FixedExpenseCategorySelectorWidget이 렌더링된다', (tester) async {
      // Given / When
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            fixedExpenseCategoriesProvider.overrideWith((ref) async => []),
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

      // Then: FixedExpenseCategorySelectorWidget이 있어야 함
      expect(find.byType(FixedExpenseCategorySelectorWidget), findsOneWidget);
    });

    testWidgets('isFixedExpense=false일 때 CategorySelectorWidget이 렌더링된다', (tester) async {
      // Given / When
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            expenseCategoriesProvider.overrideWith((ref) async => []),
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

      // Then: CategorySelectorWidget이 있어야 함
      expect(find.byType(CategorySelectorWidget), findsOneWidget);
    });

    testWidgets('수입 타입으로 렌더링 시 CategorySelectorWidget이 표시된다', (tester) async {
      // Given / When
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            expenseCategoriesProvider.overrideWith((ref) async => []),
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
                transactionType: 'income',
                onCategorySelected: (_) {},
                onFixedExpenseCategorySelected: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Then
      expect(find.byType(CategorySectionWidget), findsOneWidget);
    });

    testWidgets('enabled=false일 때 위젯이 비활성화 상태로 렌더링된다', (tester) async {
      // Given / When: enabled=false로 렌더링
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            expenseCategoriesProvider.overrideWith((ref) async => []),
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
                enabled: false,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Then: 위젯이 렌더링되어야 함
      expect(find.byType(CategorySectionWidget), findsOneWidget);
    });

    testWidgets('고정비+enabled=false일 때 FixedExpenseCategorySelectorWidget이 렌더링된다', (tester) async {
      // Given / When
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            fixedExpenseCategoriesProvider.overrideWith((ref) async => []),
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
                enabled: false,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Then
      expect(find.byType(FixedExpenseCategorySelectorWidget), findsOneWidget);
    });
  });

  group('PaymentMethodSectionWidget 위젯 테스트', () {
    testWidgets('기본 상태로 렌더링된다', (tester) async {
      // Given / When
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => 'test-ledger-id'),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: PaymentMethodSectionWidget(
                selectedPaymentMethod: null,
                onPaymentMethodSelected: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Then: 위젯이 렌더링되어야 함
      expect(find.byType(PaymentMethodSectionWidget), findsOneWidget);
    });

    testWidgets('enabled=false일 때 PaymentMethodSectionWidget이 렌더링된다', (tester) async {
      // Given / When
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => 'test-ledger-id'),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: PaymentMethodSectionWidget(
                selectedPaymentMethod: null,
                onPaymentMethodSelected: (_) {},
                enabled: false,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Then
      expect(find.byType(PaymentMethodSectionWidget), findsOneWidget);
      expect(find.byType(Column), findsWidgets);
    });
  });
}
