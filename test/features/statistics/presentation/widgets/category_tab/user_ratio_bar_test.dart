import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/statistics/data/repositories/statistics_repository.dart';
import 'package:shared_household_account/features/statistics/domain/entities/statistics_entities.dart';
import 'package:shared_household_account/features/statistics/presentation/providers/statistics_provider.dart';
import 'package:shared_household_account/features/statistics/presentation/widgets/category_tab/user_ratio_bar.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

Widget buildWidget({
  Map<String, UserCategoryStatistics>? userStats,
  String selectedType = 'expense',
}) {
  return ProviderScope(
    overrides: [
      categoryStatisticsByUserProvider.overrideWith(
        (ref) async => userStats ?? {},
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
        body: UserRatioBar(),
      ),
    ),
  );
}

void main() {
  group('UserRatioBar 위젯 테스트', () {
    testWidgets('위젯이 정상적으로 렌더링된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(UserRatioBar), findsOneWidget);
    });

    testWidgets('사용자 통계가 없으면 SizedBox.shrink()가 반환된다', (tester) async {
      // Given: 빈 사용자 통계
      // When
      await tester.pumpWidget(buildWidget(userStats: {}));
      await tester.pumpAndSettle();

      // Then: Card가 표시되지 않음
      expect(find.byType(Card), findsNothing);
    });

    testWidgets('총 금액이 0이면 아무것도 표시되지 않는다', (tester) async {
      // Given: 모든 금액이 0인 통계
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
      await tester.pumpWidget(buildWidget(userStats: userStats));
      await tester.pumpAndSettle();

      // Then: Card가 표시되지 않음
      expect(find.byType(Card), findsNothing);
    });

    testWidgets('사용자 통계가 있으면 Card가 표시된다', (tester) async {
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
      await tester.pumpWidget(buildWidget(userStats: userStats));
      await tester.pumpAndSettle();

      // Then: Card가 표시됨
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('로딩 상태에서 위젯이 정상 렌더링된다', (tester) async {
      // Given & When
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            categoryStatisticsByUserProvider.overrideWith(
              (ref) async => <String, UserCategoryStatistics>{},
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
            home: Scaffold(body: UserRatioBar()),
          ),
        ),
      );
      await tester.pump();

      // Then
      expect(find.byType(UserRatioBar), findsOneWidget);
    });
  });
}
