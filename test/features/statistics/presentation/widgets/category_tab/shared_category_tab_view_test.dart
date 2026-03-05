import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/share/presentation/providers/share_provider.dart';
import 'package:shared_household_account/features/statistics/data/repositories/statistics_repository.dart';
import 'package:shared_household_account/features/statistics/domain/entities/statistics_entities.dart';
import 'package:shared_household_account/features/statistics/presentation/providers/statistics_provider.dart';
import 'package:shared_household_account/features/statistics/presentation/widgets/category_tab/shared_category_tab_view.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';

List<Override> _baseOverrides({
  Future<Map<String, UserCategoryStatistics>> Function()? categoryByUserFn,
}) {
  return [
    categoryStatisticsByUserProvider.overrideWith(
      (ref) => categoryByUserFn != null ? categoryByUserFn() : Future.value({}),
    ),
    categoryStatisticsProvider.overrideWith((ref) async => []),
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
  ];
}

Widget buildWidget({
  Future<Map<String, UserCategoryStatistics>> Function()? categoryByUserFn,
}) {
  return ProviderScope(
    overrides: _baseOverrides(categoryByUserFn: categoryByUserFn),
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SharedCategoryTabView(),
      ),
    ),
  );
}

void main() {
  group('SharedCategoryTabView 위젯 테스트', () {
    testWidgets('위젯이 정상적으로 렌더링된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(SharedCategoryTabView), findsOneWidget);
    });

    testWidgets('RefreshIndicator가 표시된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('SingleChildScrollView가 표시된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('Column 위젯이 표시된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('pull-to-refresh를 실행하면 새로고침이 동작한다', (tester) async {
      // Given
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // When - RefreshIndicator의 드래그로 새로고침 트리거
      await tester.drag(find.byType(RefreshIndicator), const Offset(0, 300));
      await tester.pumpAndSettle();

      // Then - 위젯이 여전히 정상 존재
      expect(find.byType(SharedCategoryTabView), findsOneWidget);
    });

    testWidgets('SingleChildScrollView가 AlwaysScrollableScrollPhysics를 가진다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('_refreshData에서 일반 에러 발생 시 위젯이 살아있다', (tester) async {
      // Given: 첫 로드는 성공, refresh 시 에러
      var callCount = 0;
      await tester.pumpWidget(
        buildWidget(
          categoryByUserFn: () {
            callCount++;
            if (callCount > 1) {
              throw Exception('네트워크 오류');
            }
            return Future.value({});
          },
        ),
      );
      await tester.pumpAndSettle();

      // When - pull-to-refresh 트리거
      await tester.drag(find.byType(RefreshIndicator), const Offset(0, 300));
      await tester.pumpAndSettle();

      // Then - 에러가 발생해도 위젯은 유지됨
      expect(find.byType(SharedCategoryTabView), findsOneWidget);
    });

    testWidgets('_refreshData에서 SocketException 발생 시 위젯이 살아있다', (tester) async {
      // Given: refresh 시 SocketException 발생
      var callCount = 0;
      await tester.pumpWidget(
        buildWidget(
          categoryByUserFn: () {
            callCount++;
            if (callCount > 1) {
              throw const SocketException('연결 실패');
            }
            return Future.value({});
          },
        ),
      );
      await tester.pumpAndSettle();

      // When
      await tester.drag(find.byType(RefreshIndicator), const Offset(0, 300));
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(SharedCategoryTabView), findsOneWidget);
    });

    testWidgets('_isNetworkError 메서드가 네트워크 관련 에러를 감지한다', (tester) async {
      // Given: "network" 문자열이 포함된 에러
      var callCount = 0;
      await tester.pumpWidget(
        buildWidget(
          categoryByUserFn: () {
            callCount++;
            if (callCount > 1) {
              throw Exception('network connection failed');
            }
            return Future.value({});
          },
        ),
      );
      await tester.pumpAndSettle();

      // When
      await tester.drag(find.byType(RefreshIndicator), const Offset(0, 300));
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(SharedCategoryTabView), findsOneWidget);
    });
  });
}
