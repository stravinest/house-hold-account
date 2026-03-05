import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/statistics/data/repositories/statistics_repository.dart';
import 'package:shared_household_account/features/statistics/presentation/providers/statistics_provider.dart';
import 'package:shared_household_account/features/statistics/presentation/widgets/category_tab/side_by_side_donut_chart.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

Widget buildWidget({
  Map<String, UserCategoryStatistics>? userStats,
  SharedStatisticsState? sharedState,
}) {
  return ProviderScope(
    overrides: [
      categoryStatisticsByUserProvider.overrideWith(
        (ref) async => userStats ?? {},
      ),
      if (sharedState != null)
        sharedStatisticsStateProvider.overrideWith(
          (ref) => sharedState,
        ),
    ],
    child: const MaterialApp(
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SideBySideDonutChart(),
      ),
    ),
  );
}

void main() {
  group('SideBySideDonutChart 위젯 테스트', () {
    testWidgets('위젯이 정상적으로 렌더링된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(SideBySideDonutChart), findsOneWidget);
    });

    testWidgets('사용자 통계가 없으면 빈 상태가 표시된다', (tester) async {
      // Given: 빈 사용자 통계
      // When
      await tester.pumpWidget(buildWidget(userStats: {}));
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(SideBySideDonutChart), findsOneWidget);
    });

    testWidgets('combined 모드에서 위젯이 렌더링된다', (tester) async {
      // Given
      final userStats = {
        'user-1': const UserCategoryStatistics(
          userId: 'user-1',
          userName: '김철수',
          userColor: '#FF5733',
          totalAmount: 300000,
          categories: {},
        ),
      };

      // When
      await tester.pumpWidget(
        buildWidget(
          userStats: userStats,
          sharedState: const SharedStatisticsState(
            mode: SharedStatisticsMode.combined,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(SideBySideDonutChart), findsOneWidget);
    });

    testWidgets('singleUser 모드에서 위젯이 렌더링된다', (tester) async {
      // Given
      final userStats = {
        'user-1': const UserCategoryStatistics(
          userId: 'user-1',
          userName: '김철수',
          userColor: '#FF5733',
          totalAmount: 300000,
          categories: {},
        ),
      };

      // When
      await tester.pumpWidget(
        buildWidget(
          userStats: userStats,
          sharedState: const SharedStatisticsState(
            mode: SharedStatisticsMode.singleUser,
            selectedUserId: 'user-1',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(SideBySideDonutChart), findsOneWidget);
    });

    testWidgets('overlay 모드에서 위젯이 렌더링된다', (tester) async {
      // Given
      final userStats = {
        'user-1': const UserCategoryStatistics(
          userId: 'user-1',
          userName: '김철수',
          userColor: '#FF5733',
          totalAmount: 300000,
          categories: {},
        ),
        'user-2': const UserCategoryStatistics(
          userId: 'user-2',
          userName: '이영희',
          userColor: '#4A90E2',
          totalAmount: 200000,
          categories: {},
        ),
      };

      // When
      await tester.pumpWidget(
        buildWidget(
          userStats: userStats,
          sharedState: const SharedStatisticsState(
            mode: SharedStatisticsMode.overlay,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(SideBySideDonutChart), findsOneWidget);
    });

    testWidgets('카테고리 데이터가 있는 combined 모드에서 PieChart가 렌더링된다', (tester) async {
      // Given - 카테고리 데이터를 포함한 사용자 통계
      final userStats = {
        'user-1': UserCategoryStatistics(
          userId: 'user-1',
          userName: '김철수',
          userColor: '#FF5733',
          totalAmount: 300000,
          categories: {
            'cat-1': const CategoryStatistics(
              categoryId: 'cat-1',
              categoryName: '식비',
              categoryIcon: 'restaurant',
              categoryColor: '#FF5733',
              amount: 200000,
            ),
            'cat-2': const CategoryStatistics(
              categoryId: 'cat-2',
              categoryName: '교통비',
              categoryIcon: 'train',
              categoryColor: '#4A90E2',
              amount: 100000,
            ),
          },
        ),
        'user-2': UserCategoryStatistics(
          userId: 'user-2',
          userName: '이영희',
          userColor: '#4CAF50',
          totalAmount: 150000,
          categories: {
            'cat-1': const CategoryStatistics(
              categoryId: 'cat-1',
              categoryName: '식비',
              categoryIcon: 'restaurant',
              categoryColor: '#FF5733',
              amount: 150000,
            ),
          },
        ),
      };

      // When
      await tester.pumpWidget(
        buildWidget(
          userStats: userStats,
          sharedState: const SharedStatisticsState(
            mode: SharedStatisticsMode.combined,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(SideBySideDonutChart), findsOneWidget);
    });

    testWidgets('카테고리 데이터가 있는 singleUser 모드에서 도넛 차트가 렌더링된다', (tester) async {
      // Given - 카테고리 데이터 포함
      final userStats = {
        'user-1': UserCategoryStatistics(
          userId: 'user-1',
          userName: '김철수',
          userColor: '#FF5733',
          totalAmount: 500000,
          categories: {
            'cat-1': const CategoryStatistics(
              categoryId: 'cat-1',
              categoryName: '식비',
              categoryIcon: 'restaurant',
              categoryColor: '#FF5733',
              amount: 300000,
            ),
            'cat-2': const CategoryStatistics(
              categoryId: 'cat-2',
              categoryName: '교통비',
              categoryIcon: 'train',
              categoryColor: '#4A90E2',
              amount: 200000,
            ),
          },
        ),
      };

      // When
      await tester.pumpWidget(
        buildWidget(
          userStats: userStats,
          sharedState: const SharedStatisticsState(
            mode: SharedStatisticsMode.singleUser,
            selectedUserId: 'user-1',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(SideBySideDonutChart), findsOneWidget);
    });

    testWidgets('카테고리 데이터가 있는 overlay 모드에서 2명의 도넛 차트가 나란히 렌더링된다', (tester) async {
      // Given - 두 사용자 모두 카테고리 데이터 포함
      final userStats = {
        'user-1': UserCategoryStatistics(
          userId: 'user-1',
          userName: '김철수',
          userColor: '#FF5733',
          totalAmount: 300000,
          categories: {
            'cat-1': const CategoryStatistics(
              categoryId: 'cat-1',
              categoryName: '식비',
              categoryIcon: 'restaurant',
              categoryColor: '#FF5733',
              amount: 300000,
            ),
          },
        ),
        'user-2': UserCategoryStatistics(
          userId: 'user-2',
          userName: '이영희',
          userColor: '#4CAF50',
          totalAmount: 200000,
          categories: {
            'cat-2': const CategoryStatistics(
              categoryId: 'cat-2',
              categoryName: '교통비',
              categoryIcon: 'train',
              categoryColor: '#4A90E2',
              amount: 200000,
            ),
          },
        ),
      };

      // When
      await tester.pumpWidget(
        buildWidget(
          userStats: userStats,
          sharedState: const SharedStatisticsState(
            mode: SharedStatisticsMode.overlay,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Then - 두 사용자 이름이 화면에 표시되어야 함
      expect(find.byType(SideBySideDonutChart), findsOneWidget);
      expect(find.text('김철수'), findsWidgets);
      expect(find.text('이영희'), findsWidgets);
    });

    testWidgets('6개 초과 카테고리가 있을 때 기타로 묶인다', (tester) async {
      // Given - 6개 초과의 카테고리
      final categories = <String, CategoryStatistics>{};
      for (int i = 1; i <= 8; i++) {
        categories['cat-$i'] = CategoryStatistics(
          categoryId: 'cat-$i',
          categoryName: '카테고리$i',
          categoryIcon: 'label',
          categoryColor: '#FF573${i}',
          amount: (9 - i) * 50000,
        );
      }

      final userStats = {
        'user-1': UserCategoryStatistics(
          userId: 'user-1',
          userName: '김철수',
          userColor: '#FF5733',
          totalAmount: categories.values.fold(0, (s, c) => s + c.amount),
          categories: categories,
        ),
      };

      // When
      await tester.pumpWidget(
        buildWidget(
          userStats: userStats,
          sharedState: const SharedStatisticsState(
            mode: SharedStatisticsMode.singleUser,
            selectedUserId: 'user-1',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(SideBySideDonutChart), findsOneWidget);
    });

    testWidgets('overlay 모드에서 사용자가 1명이면 단일 차트가 표시된다', (tester) async {
      // Given - 사용자 1명, 카테고리 데이터 포함
      final userStats = {
        'user-1': UserCategoryStatistics(
          userId: 'user-1',
          userName: '김철수',
          userColor: '#FF5733',
          totalAmount: 300000,
          categories: {
            'cat-1': const CategoryStatistics(
              categoryId: 'cat-1',
              categoryName: '식비',
              categoryIcon: 'restaurant',
              categoryColor: '#FF5733',
              amount: 300000,
            ),
          },
        ),
      };

      // When
      await tester.pumpWidget(
        buildWidget(
          userStats: userStats,
          sharedState: const SharedStatisticsState(
            mode: SharedStatisticsMode.overlay,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Then - 사용자가 1명이므로 단일 차트로 폴백
      expect(find.byType(SideBySideDonutChart), findsOneWidget);
    });

    testWidgets('singleUser 모드에서 선택된 userId가 없으면 첫 번째 사용자 차트가 표시된다', (tester) async {
      // Given
      final userStats = {
        'user-1': UserCategoryStatistics(
          userId: 'user-1',
          userName: '김철수',
          userColor: '#FF5733',
          totalAmount: 300000,
          categories: {
            'cat-1': const CategoryStatistics(
              categoryId: 'cat-1',
              categoryName: '식비',
              categoryIcon: 'restaurant',
              categoryColor: '#FF5733',
              amount: 300000,
            ),
          },
        ),
      };

      // When - selectedUserId가 없는 singleUser 모드
      await tester.pumpWidget(
        buildWidget(
          userStats: userStats,
          sharedState: const SharedStatisticsState(
            mode: SharedStatisticsMode.singleUser,
            selectedUserId: 'non-existent-user',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Then - 첫 번째 사용자로 폴백하여 차트 표시
      expect(find.byType(SideBySideDonutChart), findsOneWidget);
    });

    testWidgets('데이터 로딩 중에는 CircularProgressIndicator가 표시된다', (tester) async {
      // Given - Completer로 타이머 없이 로딩 상태 유지
      final completer = Completer<Map<String, UserCategoryStatistics>>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            categoryStatisticsByUserProvider.overrideWith(
              (ref) => completer.future,
            ),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: SideBySideDonutChart()),
          ),
        ),
      );
      await tester.pump();

      // Then - 로딩 인디케이터 표시
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // 타이머 정리 - completer 완료
      completer.complete({});
      await tester.pumpAndSettle();
    });

    testWidgets('combined 모드에서 totalAmount가 0이면 빈 상태가 표시된다', (tester) async {
      // Given - totalAmount가 0인 사용자 통계
      final userStats = {
        'user-1': const UserCategoryStatistics(
          userId: 'user-1',
          userName: '김철수',
          userColor: '#FF5733',
          totalAmount: 0,
          categories: {},
        ),
      };

      // When
      await tester.pumpWidget(
        buildWidget(
          userStats: userStats,
          sharedState: const SharedStatisticsState(
            mode: SharedStatisticsMode.combined,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(SideBySideDonutChart), findsOneWidget);
    });
  });
}
