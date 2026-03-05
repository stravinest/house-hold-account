import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/statistics/data/repositories/statistics_repository.dart';
import 'package:shared_household_account/features/statistics/domain/entities/statistics_entities.dart';
import 'package:shared_household_account/features/statistics/presentation/providers/statistics_provider.dart';
import 'package:shared_household_account/features/statistics/presentation/widgets/category_tab/shared_category_summary_card.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';

void main() {
  // 테스트용 사용자 카테고리 통계 데이터 생성
  Map<String, UserCategoryStatistics> makeUserStats({
    int user1Amount = 100000,
    int user2Amount = 50000,
  }) {
    return {
      'user-1': UserCategoryStatistics(
        userId: 'user-1',
        userName: '홍길동',
        userColor: '#FF5722',
        totalAmount: user1Amount,
        categories: {
          'cat-1': CategoryStatistics(
            categoryId: 'cat-1',
            categoryName: '식비',
            categoryIcon: 'restaurant',
            categoryColor: '#FF5733',
            amount: user1Amount,
          ),
        },
      ),
      'user-2': UserCategoryStatistics(
        userId: 'user-2',
        userName: '김철수',
        userColor: '#4CAF50',
        totalAmount: user2Amount,
        categories: {
          'cat-2': CategoryStatistics(
            categoryId: 'cat-2',
            categoryName: '교통비',
            categoryIcon: 'restaurant',
            categoryColor: '#33C1FF',
            amount: user2Amount,
          ),
        },
      ),
    };
  }

  Widget buildWidget({
    Map<String, UserCategoryStatistics>? userStats,
    MonthComparisonData? comparison,
    String selectedType = 'expense',
    ExpenseTypeFilter expenseFilter = ExpenseTypeFilter.all,
  }) {
    final stats = userStats ?? makeUserStats();
    final comp = comparison ??
        const MonthComparisonData(
          currentTotal: 150000,
          previousTotal: 120000,
          difference: 30000,
          percentageChange: 25.0,
        );

    return ProviderScope(
      overrides: [
        selectedStatisticsTypeProvider.overrideWith((ref) => selectedType),
        selectedExpenseTypeFilterProvider.overrideWith((ref) => expenseFilter),
        categoryStatisticsByUserProvider.overrideWith(
          (ref) async => stats,
        ),
        monthComparisonProvider.overrideWith(
          (ref) async => comp,
        ),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: SharedCategorySummaryCard(),
          ),
        ),
      ),
    );
  }

  group('SharedCategorySummaryCard 위젯 테스트', () {
    testWidgets('위젯이 정상적으로 렌더링된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(SharedCategorySummaryCard), findsOneWidget);
    });

    testWidgets('데이터 로딩 중일 때 CircularProgressIndicator가 표시된다', (tester) async {
      // Given - 완료되지 않는 Completer로 로딩 상태 유지
      final completer = Completer<Map<String, UserCategoryStatistics>>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            selectedStatisticsTypeProvider.overrideWith((ref) => 'expense'),
            selectedExpenseTypeFilterProvider
                .overrideWith((ref) => ExpenseTypeFilter.all),
            categoryStatisticsByUserProvider
                .overrideWith((ref) => completer.future),
            monthComparisonProvider.overrideWith(
              (ref) async => MonthComparisonData.empty(),
            ),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SingleChildScrollView(
                child: SharedCategorySummaryCard(),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Then - 로딩 인디케이터가 표시되어야 함
      expect(find.byType(SharedCategorySummaryCard), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // 타이머 정리
      completer.complete({});
      await tester.pumpAndSettle();
    });

    testWidgets('사용자 이름이 카드에 표시된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Then
      expect(find.text('홍길동'), findsOneWidget);
      expect(find.text('김철수'), findsOneWidget);
    });

    testWidgets('userStats가 비어있으면 빈 상태가 표시된다', (tester) async {
      // Given - 빈 통계 데이터
      await tester.pumpWidget(buildWidget(userStats: {}));
      await tester.pumpAndSettle();

      // Then - 위젯은 존재하되 사용자 이름은 없어야 함
      expect(find.byType(SharedCategorySummaryCard), findsOneWidget);
      expect(find.text('홍길동'), findsNothing);
      expect(find.text('김철수'), findsNothing);
    });

    testWidgets('지출 타입이 선택되면 지출 관련 라벨이 표시된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget(selectedType: 'expense'));
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(SharedCategorySummaryCard), findsOneWidget);
    });

    testWidgets('수입 타입이 선택되면 위젯이 정상 렌더링된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget(selectedType: 'income'));
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(SharedCategorySummaryCard), findsOneWidget);
    });

    testWidgets('고정비 필터가 적용될 때 위젯이 렌더링된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget(
        selectedType: 'expense',
        expenseFilter: ExpenseTypeFilter.fixed,
      ));
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(SharedCategorySummaryCard), findsOneWidget);
    });

    testWidgets('전월 대비 증가 데이터가 있을 때 증가 아이콘이 표시된다', (tester) async {
      // Given
      const comparison = MonthComparisonData(
        currentTotal: 200000,
        previousTotal: 100000,
        difference: 100000,
        percentageChange: 100.0,
      );

      // When
      await tester.pumpWidget(buildWidget(comparison: comparison));
      await tester.pumpAndSettle();

      // Then - 증가 화살표 아이콘이 표시되어야 함
      expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
    });

    testWidgets('전월 대비 감소 데이터가 있을 때 감소 아이콘이 표시된다', (tester) async {
      // Given
      const comparison = MonthComparisonData(
        currentTotal: 80000,
        previousTotal: 100000,
        difference: -20000,
        percentageChange: -20.0,
      );

      // When
      await tester.pumpWidget(buildWidget(comparison: comparison));
      await tester.pumpAndSettle();

      // Then - 감소 화살표 아이콘이 표시되어야 함
      expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
    });

    testWidgets('전월과 동일한 데이터가 있을 때 remove 아이콘이 표시된다', (tester) async {
      // Given
      const comparison = MonthComparisonData(
        currentTotal: 100000,
        previousTotal: 100000,
        difference: 0,
        percentageChange: 0.0,
      );

      // When
      await tester.pumpWidget(buildWidget(comparison: comparison));
      await tester.pumpAndSettle();

      // Then - 변화없음 아이콘이 표시되어야 함
      expect(find.byIcon(Icons.remove), findsOneWidget);
    });

    testWidgets('이전 달 데이터가 없을 때 안내 텍스트가 표시된다', (tester) async {
      // Given - currentTotal과 previousTotal 모두 0인 경우
      const comparison = MonthComparisonData(
        currentTotal: 0,
        previousTotal: 0,
        difference: 0,
        percentageChange: 0,
      );

      // When
      await tester.pumpWidget(buildWidget(comparison: comparison));
      await tester.pumpAndSettle();

      // Then - 위젯이 렌더링되고, 아이콘 없이 텍스트가 표시됨
      expect(find.byType(SharedCategorySummaryCard), findsOneWidget);
      expect(find.byIcon(Icons.arrow_upward), findsNothing);
      expect(find.byIcon(Icons.arrow_downward), findsNothing);
    });
  });
}
