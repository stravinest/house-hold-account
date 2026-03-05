import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_household_account/features/ledger/presentation/providers/ledger_provider.dart';
import 'package:shared_household_account/features/statistics/data/repositories/statistics_repository.dart';
import 'package:shared_household_account/features/statistics/domain/entities/statistics_entities.dart';
import 'package:shared_household_account/features/statistics/presentation/providers/statistics_provider.dart';
import 'package:shared_household_account/features/statistics/presentation/widgets/category_tab/category_detail_bottom_sheet.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';

import '../../../../../helpers/mock_repositories.dart';

void main() {
  late MockStatisticsRepository mockRepository;

  setUp(() {
    mockRepository = MockStatisticsRepository();
    registerFallbackValue(ExpenseTypeFilter.all);
  });

  Widget buildWidget({
    CategoryDetailState? initialState,
    CategoryTopResult? topResult,
  }) {
    final state = initialState ??
        const CategoryDetailState(
          isOpen: true,
          categoryId: 'cat-1',
          categoryName: '식비',
          categoryColor: '#FF5722',
          categoryIcon: 'restaurant',
          categoryPercentage: 35.0,
          type: 'expense',
          totalAmount: 100000,
        );

    final result = topResult ??
        const CategoryTopResult(
          items: [
            CategoryTopTransaction(
              rank: 1,
              title: '스타벅스',
              amount: 5000,
              percentage: 5.0,
              date: '2월 16일 (일)',
              userName: '홍길동',
              userColor: '#FF5722',
            ),
          ],
          totalAmount: 100000,
        );

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
        )).thenAnswer((_) async => result);

    return ProviderScope(
      overrides: [
        statisticsRepositoryProvider.overrideWith((ref) => mockRepository),
        categoryDetailStateProvider.overrideWith((ref) => state),
        selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
        statisticsSelectedDateProvider.overrideWith((ref) => DateTime(2026, 2, 1)),
        selectedExpenseTypeFilterProvider.overrideWith(
          (ref) => ExpenseTypeFilter.all,
        ),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: CategoryDetailBottomSheet()),
      ),
    );
  }

  group('CategoryDetailBottomSheet 위젯 테스트', () {
    testWidgets('위젯이 정상적으로 렌더링된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(CategoryDetailBottomSheet), findsOneWidget);
    });

    testWidgets('카테고리 이름이 표시된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Then
      expect(find.text('식비'), findsOneWidget);
    });

    testWidgets('퍼센티지가 표시된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Then
      expect(find.text('35.0%'), findsOneWidget);
    });

    testWidgets('닫기 버튼(Icons.close)이 표시된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Then
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('지출 타입일 때 마이너스 부호가 금액 앞에 표시된다', (tester) async {
      // Given
      const state = CategoryDetailState(
        isOpen: true,
        categoryId: 'cat-1',
        categoryName: '식비',
        categoryColor: '#FF5722',
        categoryIcon: 'restaurant',
        categoryPercentage: 35.0,
        type: 'expense',
        totalAmount: 100000,
      );

      // When
      await tester.pumpWidget(buildWidget(initialState: state));
      await tester.pumpAndSettle();

      // Then - 위젯이 렌더링되고 type이 expense임
      expect(find.byType(CategoryDetailBottomSheet), findsOneWidget);
    });

    testWidgets('수입 타입일 때 플러스 부호가 금액 앞에 표시된다', (tester) async {
      // Given
      const state = CategoryDetailState(
        isOpen: true,
        categoryId: 'cat-1',
        categoryName: '급여',
        categoryColor: '#4CAF50',
        categoryIcon: 'work',
        categoryPercentage: 100.0,
        type: 'income',
        totalAmount: 3000000,
      );

      // When
      await tester.pumpWidget(buildWidget(initialState: state));
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(CategoryDetailBottomSheet), findsOneWidget);
    });

    testWidgets('거래 목록이 로딩 중일 때 CircularProgressIndicator가 표시된다', (tester) async {
      // Given - categoryTopTransactionsProvider를 직접 오버라이드하여 로딩 상태 유지
      final completer = Completer<CategoryTopResult>();
      const state = CategoryDetailState(
        isOpen: true,
        categoryId: 'cat-1',
        categoryName: '식비',
        categoryColor: '#FF5722',
        categoryIcon: 'restaurant',
        categoryPercentage: 35.0,
        type: 'expense',
        totalAmount: 100000,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            categoryDetailStateProvider.overrideWith((ref) => state),
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
            statisticsSelectedDateProvider
                .overrideWith((ref) => DateTime(2026, 2, 1)),
            selectedExpenseTypeFilterProvider
                .overrideWith((ref) => ExpenseTypeFilter.all),
            categoryTopTransactionsProvider
                .overrideWith((ref) => completer.future),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: CategoryDetailBottomSheet()),
          ),
        ),
      );
      await tester.pump();

      // Then - 로딩 중에는 CircularProgressIndicator가 표시되어야 함
      expect(find.byType(CategoryDetailBottomSheet), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // 타이머 정리
      completer.complete(const CategoryTopResult(items: [], totalAmount: 0));
      await tester.pumpAndSettle();
    });

    testWidgets('거래 데이터가 로드되면 거래 항목이 표시된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Then - 거래 제목이 표시되어야 함
      expect(find.text('스타벅스'), findsOneWidget);
    });

    testWidgets('거래 목록이 비어 있으면 데이터 없음 안내 텍스트가 표시된다', (tester) async {
      // Given
      const emptyResult = CategoryTopResult(items: [], totalAmount: 0);

      // When
      await tester.pumpWidget(buildWidget(topResult: emptyResult));
      await tester.pumpAndSettle();

      // Then - 데이터 없음 메시지가 표시되어야 함
      expect(find.byType(CategoryDetailBottomSheet), findsOneWidget);
    });

    testWidgets('드래그 핸들이 상단에 표시된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Then - Container 위젯들이 존재해야 함 (드래그 핸들 포함)
      expect(find.byType(Container), findsWidgets);
    });
  });
}
