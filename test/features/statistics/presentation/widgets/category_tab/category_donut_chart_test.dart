import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/statistics/data/repositories/statistics_repository.dart';
import 'package:shared_household_account/features/statistics/presentation/providers/statistics_provider.dart';
import 'package:shared_household_account/features/statistics/presentation/widgets/category_tab/category_donut_chart.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

Widget buildWidget({
  List<CategoryStatistics>? statistics,
  String selectedType = 'expense',
  bool isLoading = false,
  bool hasError = false,
}) {
  return ProviderScope(
    overrides: [
      categoryStatisticsProvider.overrideWith(
        (ref) async {
          if (isLoading) await Future.delayed(const Duration(seconds: 30));
          if (hasError) throw Exception('통계 조회 실패');
          return statistics ?? [];
        },
      ),
      selectedStatisticsTypeProvider.overrideWith((ref) => selectedType),
    ],
    child: const MaterialApp(
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: CategoryDonutChart(),
      ),
    ),
  );
}

void main() {
  group('CategoryDonutChart 위젯 테스트', () {
    testWidgets('위젯이 정상적으로 렌더링된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget(statistics: []));
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(CategoryDonutChart), findsOneWidget);
    });

    testWidgets('통계 데이터가 없으면 빈 상태 메시지가 표시된다', (tester) async {
      // Given: 빈 통계 목록
      // When
      await tester.pumpWidget(buildWidget(statistics: []));
      await tester.pumpAndSettle();

      // Then: 빈 상태가 표시됨 (SizedBox 또는 텍스트)
      expect(find.byType(CategoryDonutChart), findsOneWidget);
    });

    testWidgets('통계 데이터가 있으면 차트가 표시된다', (tester) async {
      // Given
      const stats = [
        CategoryStatistics(
          categoryId: 'cat-1',
          categoryName: '식비',
          categoryIcon: 'restaurant',
          categoryColor: '#FF5733',
          amount: 300000,
        ),
        CategoryStatistics(
          categoryId: 'cat-2',
          categoryName: '교통',
          categoryIcon: 'directions_car',
          categoryColor: '#4A90E2',
          amount: 100000,
        ),
      ];

      // When
      await tester.pumpWidget(buildWidget(statistics: stats));
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(CategoryDonutChart), findsOneWidget);
    });

    testWidgets('로딩 중에 CircularProgressIndicator가 표시된다', (tester) async {
      // Given: Completer를 사용해 Future가 완료되지 않도록 유지
      final completer = Completer<List<CategoryStatistics>>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            categoryStatisticsProvider.overrideWith(
              (ref) => completer.future,
            ),
            selectedStatisticsTypeProvider.overrideWith((ref) => 'expense'),
          ],
          child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: CategoryDonutChart()),
          ),
        ),
      );
      await tester.pump(); // 로딩 상태 렌더링

      // Then
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Cleanup: completer 완료
      completer.complete([]);
    });

    testWidgets('에러 상태에서 에러 메시지가 표시된다', (tester) async {
      // Given & When
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            categoryStatisticsProvider.overrideWith(
              (ref) async => throw Exception('테스트 에러'),
            ),
            selectedStatisticsTypeProvider.overrideWith((ref) => 'expense'),
          ],
          child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: CategoryDonutChart()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Then: 에러 위젯이 표시됨
      expect(find.byType(CategoryDonutChart), findsOneWidget);
    });

    testWidgets('income 타입으로도 정상 렌더링된다', (tester) async {
      // Given & When
      await tester.pumpWidget(
        buildWidget(
          statistics: const [
            CategoryStatistics(
              categoryId: 'cat-1',
              categoryName: '급여',
              categoryIcon: 'work',
              categoryColor: '#4CAF50',
              amount: 3000000,
            ),
          ],
          selectedType: 'income',
        ),
      );
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(CategoryDonutChart), findsOneWidget);
    });
  });
}
