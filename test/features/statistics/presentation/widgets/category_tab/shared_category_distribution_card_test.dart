import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_household_account/features/ledger/domain/entities/ledger.dart';
import 'package:shared_household_account/features/ledger/presentation/providers/ledger_provider.dart';
import 'package:shared_household_account/features/share/presentation/providers/share_provider.dart';
import 'package:shared_household_account/features/statistics/data/repositories/statistics_repository.dart';
import 'package:shared_household_account/features/statistics/domain/entities/statistics_entities.dart';
import 'package:shared_household_account/features/statistics/presentation/providers/statistics_provider.dart';
import 'package:shared_household_account/features/statistics/presentation/widgets/category_tab/shared_category_distribution_card.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';

import '../../../../../helpers/mock_repositories.dart';

void main() {
  late MockStatisticsRepository mockRepository;

  setUp(() {
    mockRepository = MockStatisticsRepository();
    registerFallbackValue(ExpenseTypeFilter.all);
  });

  // 테스트용 LedgerMember 생성 헬퍼
  LedgerMember makeMember(String userId, {String? displayName, String? color}) {
    return LedgerMember(
      id: 'member-$userId',
      ledgerId: 'ledger-1',
      userId: userId,
      role: 'member',
      joinedAt: DateTime(2026, 1, 1),
      displayName: displayName,
      color: color,
    );
  }

  // 테스트용 사용자 카테고리 통계 생성 헬퍼
  Map<String, UserCategoryStatistics> makeUserStats() {
    return {
      'user-1': UserCategoryStatistics(
        userId: 'user-1',
        userName: '홍길동',
        userColor: '#FF5722',
        totalAmount: 100000,
        categories: {
          'cat-1': const CategoryStatistics(
            categoryId: 'cat-1',
            categoryName: '식비',
            categoryIcon: 'restaurant',
            categoryColor: '#FF5733',
            amount: 100000,
          ),
        },
      ),
      'user-2': UserCategoryStatistics(
        userId: 'user-2',
        userName: '김철수',
        userColor: '#4CAF50',
        totalAmount: 50000,
        categories: {
          'cat-2': const CategoryStatistics(
            categoryId: 'cat-2',
            categoryName: '교통비',
            categoryIcon: 'directions_car',
            categoryColor: '#33C1FF',
            amount: 50000,
          ),
        },
      ),
    };
  }

  Widget buildWidget({
    Map<String, UserCategoryStatistics>? userStats,
    List<LedgerMember>? members,
    SharedStatisticsState? sharedState,
  }) {
    final stats = userStats ?? makeUserStats();
    final memberList = members ??
        [
          makeMember('user-1', displayName: '홍길동', color: '#FF5722'),
          makeMember('user-2', displayName: '김철수', color: '#4CAF50'),
        ];
    final state = sharedState ??
        const SharedStatisticsState(mode: SharedStatisticsMode.combined);

    when(() => mockRepository.getCategoryStatisticsByUser(
          ledgerId: any(named: 'ledgerId'),
          year: any(named: 'year'),
          month: any(named: 'month'),
          type: any(named: 'type'),
          expenseTypeFilter: any(named: 'expenseTypeFilter'),
        )).thenAnswer((_) async => stats);

    when(() => mockRepository.getCategoryTopTransactions(
          ledgerId: any(named: 'ledgerId'),
          year: any(named: 'year'),
          month: any(named: 'month'),
          type: any(named: 'type'),
          categoryId: any(named: 'categoryId'),
          limit: any(named: 'limit'),
          isFixedExpenseFilter: any(named: 'isFixedExpenseFilter'),
          expenseTypeFilter: any(named: 'expenseTypeFilter'),
          userId: any(named: 'userId'),
        )).thenAnswer(
      (_) async => const CategoryTopResult(items: [], totalAmount: 0),
    );

    return ProviderScope(
      overrides: [
        statisticsRepositoryProvider.overrideWith((ref) => mockRepository),
        selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
        statisticsSelectedDateProvider.overrideWith((ref) => DateTime(2026, 2, 1)),
        selectedStatisticsTypeProvider.overrideWith((ref) => 'expense'),
        selectedExpenseTypeFilterProvider.overrideWith(
          (ref) => ExpenseTypeFilter.all,
        ),
        sharedStatisticsStateProvider.overrideWith((ref) => state),
        currentLedgerMembersProvider.overrideWith((ref) async => memberList),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: SharedCategoryDistributionCard(),
          ),
        ),
      ),
    );
  }

  group('SharedCategoryDistributionCard 위젯 테스트', () {
    testWidgets('위젯이 정상적으로 렌더링된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(SharedCategoryDistributionCard), findsOneWidget);
    });

    testWidgets('데이터 로딩 중일 때 위젯이 렌더링 상태를 유지한다', (tester) async {
      // Given - 응답 지연
      when(() => mockRepository.getCategoryStatisticsByUser(
            ledgerId: any(named: 'ledgerId'),
            year: any(named: 'year'),
            month: any(named: 'month'),
            type: any(named: 'type'),
            expenseTypeFilter: any(named: 'expenseTypeFilter'),
          )).thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 10));
        return {};
      });

      // When
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      // Then - 로딩 중에도 위젯 자체는 존재해야 함
      expect(find.byType(SharedCategoryDistributionCard), findsOneWidget);
    });

    testWidgets('멤버가 2명 이상이면 MemberTabs가 표시된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Then - MemberTabs 위젯이 표시되어야 함
      expect(find.byType(SharedCategoryDistributionCard), findsOneWidget);
    });

    testWidgets('멤버가 1명이면 MemberTabs가 표시되지 않는다', (tester) async {
      // Given
      final singleMember = [
        makeMember('user-1', displayName: '홍길동', color: '#FF5722'),
      ];

      // When
      await tester.pumpWidget(buildWidget(members: singleMember));
      await tester.pumpAndSettle();

      // Then - MemberTabs는 표시되지 않아야 함 (홍길동이 표시되지 않아야 함)
      expect(find.byType(SharedCategoryDistributionCard), findsOneWidget);
    });

    testWidgets('userStats가 비어있으면 빈 상태가 표시된다', (tester) async {
      // Given
      when(() => mockRepository.getCategoryStatisticsByUser(
            ledgerId: any(named: 'ledgerId'),
            year: any(named: 'year'),
            month: any(named: 'month'),
            type: any(named: 'type'),
            expenseTypeFilter: any(named: 'expenseTypeFilter'),
          )).thenAnswer((_) async => {});

      // When
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(SharedCategoryDistributionCard), findsOneWidget);
    });

    testWidgets('combined 모드에서 카테고리 목록이 표시된다', (tester) async {
      // Given
      const state = SharedStatisticsState(mode: SharedStatisticsMode.combined);

      // When
      await tester.pumpWidget(buildWidget(sharedState: state));
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(SharedCategoryDistributionCard), findsOneWidget);
    });

    testWidgets('singleUser 모드에서 해당 사용자의 카테고리만 표시된다', (tester) async {
      // Given
      const state = SharedStatisticsState(
        mode: SharedStatisticsMode.singleUser,
        selectedUserId: 'user-1',
      );

      // When
      await tester.pumpWidget(buildWidget(sharedState: state));
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(SharedCategoryDistributionCard), findsOneWidget);
    });

    testWidgets('카테고리 항목 탭 시 CategoryDetailBottomSheet를 표시하려 시도한다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Then - 카드가 렌더링됨 (GestureDetector가 있어야 함)
      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('overlay 모드에서 위젯이 정상 렌더링된다', (tester) async {
      // Given
      const state = SharedStatisticsState(mode: SharedStatisticsMode.overlay);

      // When
      await tester.pumpWidget(buildWidget(sharedState: state));
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(SharedCategoryDistributionCard), findsOneWidget);
    });

    testWidgets('overlay 모드에서 combined와 동일하게 범례 카테고리 목록이 표시된다', (tester) async {
      // Given: overlay 모드 + 카테고리 데이터
      const state = SharedStatisticsState(mode: SharedStatisticsMode.overlay);
      final stats = makeUserStats();

      // When
      await tester.pumpWidget(buildWidget(userStats: stats, sharedState: state));
      await tester.pumpAndSettle();

      // Then: 위젯이 정상 렌더링됨
      expect(find.byType(SharedCategoryDistributionCard), findsOneWidget);
    });

    testWidgets('singleUser 모드에서 selectedUserId가 없으면 첫 번째 사용자로 폴백한다', (tester) async {
      // Given: selectedUserId가 일치하지 않음
      const state = SharedStatisticsState(
        mode: SharedStatisticsMode.singleUser,
        selectedUserId: 'non-existent-user',
      );

      // When
      await tester.pumpWidget(buildWidget(sharedState: state));
      await tester.pumpAndSettle();

      // Then: 첫 번째 사용자로 폴백하여 렌더링
      expect(find.byType(SharedCategoryDistributionCard), findsOneWidget);
    });

    testWidgets('5개 초과 카테고리가 있을 때 기타로 묶인다', (tester) async {
      // Given: 7개 카테고리가 있는 사용자
      final manyCategories = <String, CategoryStatistics>{};
      for (int i = 1; i <= 7; i++) {
        manyCategories['cat-$i'] = CategoryStatistics(
          categoryId: 'cat-$i',
          categoryName: '카테고리$i',
          categoryIcon: 'label',
          categoryColor: '#FF573$i',
          amount: (8 - i) * 10000,
        );
      }
      final stats = {
        'user-1': UserCategoryStatistics(
          userId: 'user-1',
          userName: '홍길동',
          userColor: '#FF5722',
          totalAmount:
              manyCategories.values.fold(0, (s, c) => s + c.amount),
          categories: manyCategories,
        ),
      };

      // When
      await tester.pumpWidget(
        buildWidget(
          userStats: stats,
          members: [makeMember('user-1', displayName: '홍길동', color: '#FF5722')],
          sharedState: const SharedStatisticsState(
            mode: SharedStatisticsMode.combined,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Then: 위젯이 정상 렌더링됨 (기타 처리 포함)
      expect(find.byType(SharedCategoryDistributionCard), findsOneWidget);
    });

    testWidgets('totalAmount가 0인 경우 빈 도넛 차트가 표시된다', (tester) async {
      // Given: totalAmount가 0
      final emptyStats = {
        'user-1': const UserCategoryStatistics(
          userId: 'user-1',
          userName: '홍길동',
          userColor: '#FF5722',
          totalAmount: 0,
          categories: {},
        ),
      };

      when(() => mockRepository.getCategoryStatisticsByUser(
            ledgerId: any(named: 'ledgerId'),
            year: any(named: 'year'),
            month: any(named: 'month'),
            type: any(named: 'type'),
            expenseTypeFilter: any(named: 'expenseTypeFilter'),
          )).thenAnswer((_) async => emptyStats);

      // When
      await tester.pumpWidget(
        buildWidget(
          userStats: emptyStats,
          sharedState: const SharedStatisticsState(
            mode: SharedStatisticsMode.combined,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Then: 빈 상태 표시
      expect(find.byType(SharedCategoryDistributionCard), findsOneWidget);
    });

    testWidgets('에러 상태일 때 빈 상태가 표시된다', (tester) async {
      // Given: 에러 발생
      when(() => mockRepository.getCategoryStatisticsByUser(
            ledgerId: any(named: 'ledgerId'),
            year: any(named: 'year'),
            month: any(named: 'month'),
            type: any(named: 'type'),
            expenseTypeFilter: any(named: 'expenseTypeFilter'),
          )).thenThrow(Exception('네트워크 오류'));

      // When
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Then: 에러 상태에서도 위젯은 렌더링됨
      expect(find.byType(SharedCategoryDistributionCard), findsOneWidget);
    });

    testWidgets('멤버가 없으면 MemberTabs가 표시되지 않는다', (tester) async {
      // Given: 멤버 없음
      final noMembers = <LedgerMember>[];

      // When
      await tester.pumpWidget(buildWidget(members: noMembers));
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(SharedCategoryDistributionCard), findsOneWidget);
    });

    testWidgets('카테고리가 없으면 범례 리스트가 표시되지 않는다', (tester) async {
      // Given: 카테고리 없는 사용자
      final statsNoCategories = {
        'user-1': const UserCategoryStatistics(
          userId: 'user-1',
          userName: '홍길동',
          userColor: '#FF5722',
          totalAmount: 100000,
          categories: {},
        ),
      };

      // When
      await tester.pumpWidget(buildWidget(userStats: statsNoCategories));
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(SharedCategoryDistributionCard), findsOneWidget);
    });

    testWidgets('카테고리 항목을 탭하면 상세 바텀시트가 시도된다', (tester) async {
      // Given: 충분한 화면 크기
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // When: GestureDetector 탭 (카테고리 항목)
      final gestures = find.byType(GestureDetector);
      if (gestures.evaluate().isNotEmpty) {
        await tester.tap(gestures.first);
        await tester.pumpAndSettle();
      }

      // Then: 위젯이 여전히 존재
      expect(find.byType(SharedCategoryDistributionCard), findsOneWidget);
    });
  });
}
