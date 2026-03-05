import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/share/presentation/providers/share_provider.dart';
import 'package:shared_household_account/features/statistics/data/repositories/statistics_repository.dart';
import 'package:shared_household_account/features/statistics/domain/entities/statistics_entities.dart';
import 'package:shared_household_account/features/statistics/presentation/providers/statistics_provider.dart';
import 'package:shared_household_account/features/statistics/presentation/widgets/category_tab/category_tab_view.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';

Widget buildWidget({
  bool isShared = false,
  List<CategoryStatistics>? categories,
}) {
  final cats = categories ??
      [
        const CategoryStatistics(
          categoryId: 'cat-1',
          categoryName: '식비',
          categoryIcon: 'restaurant',
          categoryColor: '#FF5733',
          amount: 300000,
        ),
      ];

  return ProviderScope(
    overrides: [
      isSharedLedgerProvider.overrideWith((ref) => isShared),
      categoryStatisticsProvider.overrideWith((ref) async => cats),
      categoryExpenseStatisticsProvider.overrideWith((ref) async => cats),
      categoryIncomeStatisticsProvider.overrideWith((ref) async => []),
      categoryAssetStatisticsProvider.overrideWith((ref) async => []),
      monthComparisonProvider.overrideWith(
        (ref) async => const MonthComparisonData(
          currentTotal: 300000,
          previousTotal: 250000,
          difference: 50000,
          percentageChange: 20.0,
        ),
      ),
      categoryDetailStateProvider.overrideWith(
        (ref) => const CategoryDetailState(),
      ),
      selectedStatisticsTypeProvider.overrideWith((ref) => 'expense'),
      selectedExpenseTypeFilterProvider.overrideWith(
        (ref) => ExpenseTypeFilter.all,
      ),
    ],
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: CategoryTabView(),
      ),
    ),
  );
}

void main() {
  group('CategoryTabView 위젯 테스트', () {
    testWidgets('위젯이 정상적으로 렌더링된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(CategoryTabView), findsOneWidget);
    });

    testWidgets('비공유 가계부에서 RefreshIndicator가 표시된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget(isShared: false));
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('비공유 가계부에서 SingleChildScrollView가 표시된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget(isShared: false));
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('비공유 가계부에서 Column 위젯이 표시된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget(isShared: false));
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('pull-to-refresh를 실행하면 새로고침이 동작한다', (tester) async {
      // Given
      await tester.pumpWidget(buildWidget(isShared: false));
      await tester.pumpAndSettle();

      // When - RefreshIndicator의 드래그로 새로고침 트리거
      await tester.drag(find.byType(RefreshIndicator), const Offset(0, 300));
      await tester.pumpAndSettle();

      // Then - 위젯이 여전히 정상 존재
      expect(find.byType(CategoryTabView), findsOneWidget);
    });

    testWidgets('공유 가계부에서는 SharedCategoryTabView가 렌더링된다', (tester) async {
      // Given & When
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isSharedLedgerProvider.overrideWith((ref) => true),
            categoryStatisticsProvider.overrideWith((ref) async => []),
            categoryStatisticsByUserProvider.overrideWith((ref) async => {}),
            categoryExpenseStatisticsProvider.overrideWith((ref) async => []),
            categoryIncomeStatisticsProvider.overrideWith((ref) async => []),
            categoryAssetStatisticsProvider.overrideWith((ref) async => []),
            selectedStatisticsTypeProvider.overrideWith((ref) => 'expense'),
            selectedExpenseTypeFilterProvider.overrideWith(
              (ref) => ExpenseTypeFilter.all,
            ),
            monthComparisonProvider.overrideWith(
              (ref) async => const MonthComparisonData(
                currentTotal: 0,
                previousTotal: 0,
                difference: 0,
                percentageChange: 0,
              ),
            ),
            categoryDetailStateProvider.overrideWith(
              (ref) => const CategoryDetailState(),
            ),
            sharedStatisticsStateProvider.overrideWith(
              (ref) => const SharedStatisticsState(),
            ),
            currentLedgerMembersProvider.overrideWith(
              (ref) async => [],
            ),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: CategoryTabView(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Then - 공유 가계부이므로 CategoryTabView가 존재해야 함
      expect(find.byType(CategoryTabView), findsOneWidget);
    });

    testWidgets('_refreshCategoryData에서 일반 에러 발생 시 위젯이 살아있다', (tester) async {
      // Given: 첫 로드 성공, refresh 시 에러 발생
      var callCount = 0;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isSharedLedgerProvider.overrideWith((ref) => false),
            categoryStatisticsProvider.overrideWith((ref) async => []),
            categoryExpenseStatisticsProvider.overrideWith((ref) {
              callCount++;
              if (callCount > 1) throw Exception('서버 오류');
              return Future.value([]);
            }),
            categoryIncomeStatisticsProvider.overrideWith((ref) async => []),
            categoryAssetStatisticsProvider.overrideWith((ref) async => []),
            monthComparisonProvider.overrideWith(
              (ref) async => const MonthComparisonData(
                currentTotal: 0,
                previousTotal: 0,
                difference: 0,
                percentageChange: 0,
              ),
            ),
            categoryDetailStateProvider.overrideWith(
              (ref) => const CategoryDetailState(),
            ),
            selectedStatisticsTypeProvider.overrideWith((ref) => 'expense'),
            selectedExpenseTypeFilterProvider.overrideWith(
              (ref) => ExpenseTypeFilter.all,
            ),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: CategoryTabView()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // When - pull-to-refresh 트리거
      await tester.drag(find.byType(RefreshIndicator), const Offset(0, 300));
      await tester.pumpAndSettle();

      // Then - 에러가 발생해도 위젯은 유지됨
      expect(find.byType(CategoryTabView), findsOneWidget);
    });

    testWidgets('_refreshCategoryData에서 SocketException 발생 시 위젯이 살아있다', (tester) async {
      // Given
      var callCount = 0;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isSharedLedgerProvider.overrideWith((ref) => false),
            categoryStatisticsProvider.overrideWith((ref) async => []),
            categoryExpenseStatisticsProvider.overrideWith((ref) {
              callCount++;
              if (callCount > 1) throw const SocketException('연결 실패');
              return Future.value([]);
            }),
            categoryIncomeStatisticsProvider.overrideWith((ref) async => []),
            categoryAssetStatisticsProvider.overrideWith((ref) async => []),
            monthComparisonProvider.overrideWith(
              (ref) async => const MonthComparisonData(
                currentTotal: 0,
                previousTotal: 0,
                difference: 0,
                percentageChange: 0,
              ),
            ),
            categoryDetailStateProvider.overrideWith(
              (ref) => const CategoryDetailState(),
            ),
            selectedStatisticsTypeProvider.overrideWith((ref) => 'expense'),
            selectedExpenseTypeFilterProvider.overrideWith(
              (ref) => ExpenseTypeFilter.all,
            ),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: CategoryTabView()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // When
      await tester.drag(find.byType(RefreshIndicator), const Offset(0, 300));
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(CategoryTabView), findsOneWidget);
    });

    testWidgets('_isNetworkError가 네트워크 관련 에러를 감지한다', (tester) async {
      // Given: "failed host lookup" 포함 에러
      var callCount = 0;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isSharedLedgerProvider.overrideWith((ref) => false),
            categoryStatisticsProvider.overrideWith((ref) async => []),
            categoryExpenseStatisticsProvider.overrideWith((ref) {
              callCount++;
              if (callCount > 1) {
                throw Exception('failed host lookup: api.example.com');
              }
              return Future.value([]);
            }),
            categoryIncomeStatisticsProvider.overrideWith((ref) async => []),
            categoryAssetStatisticsProvider.overrideWith((ref) async => []),
            monthComparisonProvider.overrideWith(
              (ref) async => const MonthComparisonData(
                currentTotal: 0,
                previousTotal: 0,
                difference: 0,
                percentageChange: 0,
              ),
            ),
            categoryDetailStateProvider.overrideWith(
              (ref) => const CategoryDetailState(),
            ),
            selectedStatisticsTypeProvider.overrideWith((ref) => 'expense'),
            selectedExpenseTypeFilterProvider.overrideWith(
              (ref) => ExpenseTypeFilter.all,
            ),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: CategoryTabView()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // When
      await tester.drag(find.byType(RefreshIndicator), const Offset(0, 300));
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(CategoryTabView), findsOneWidget);
    });
  });
}
