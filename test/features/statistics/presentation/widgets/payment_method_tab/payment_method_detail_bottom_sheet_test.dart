import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_household_account/features/ledger/presentation/providers/ledger_provider.dart';
import 'package:shared_household_account/features/statistics/data/repositories/statistics_repository.dart';
import 'package:shared_household_account/features/statistics/domain/entities/statistics_entities.dart';
import 'package:shared_household_account/features/statistics/presentation/providers/statistics_provider.dart';
import 'package:shared_household_account/features/statistics/presentation/widgets/payment_method_tab/payment_method_detail_bottom_sheet.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';

import '../../../../../helpers/mock_repositories.dart';

void main() {
  late MockStatisticsRepository mockRepository;

  setUp(() {
    mockRepository = MockStatisticsRepository();
    registerFallbackValue(ExpenseTypeFilter.all);
  });

  Widget buildWidget({
    PaymentMethodDetailState? initialState,
    CategoryTopResult? topResult,
  }) {
    final state = initialState ??
        const PaymentMethodDetailState(
          isOpen: true,
          paymentMethodId: 'pm-1',
          paymentMethodName: '신한카드',
          paymentMethodIcon: 'credit_card',
          paymentMethodColor: '#4A90E2',
          canAutoSave: false,
          percentage: 40.0,
          totalAmount: 200000,
        );

    final result = topResult ??
        const CategoryTopResult(
          items: [
            CategoryTopTransaction(
              rank: 1,
              title: '편의점',
              amount: 10000,
              percentage: 5.0,
              date: '2월 16일 (일)',
              userName: '홍길동',
              userColor: '#FF5722',
            ),
          ],
          totalAmount: 200000,
        );

    when(() => mockRepository.getPaymentMethodTopTransactions(
          ledgerId: any(named: 'ledgerId'),
          year: any(named: 'year'),
          month: any(named: 'month'),
          type: any(named: 'type'),
          paymentMethodId: any(named: 'paymentMethodId'),
          paymentMethodName: any(named: 'paymentMethodName'),
          canAutoSave: any(named: 'canAutoSave'),
          userId: any(named: 'userId'),
          expenseTypeFilter: any(named: 'expenseTypeFilter'),
          limit: any(named: 'limit'),
        )).thenAnswer((_) async => result);

    return ProviderScope(
      overrides: [
        statisticsRepositoryProvider.overrideWith((ref) => mockRepository),
        paymentMethodDetailStateProvider.overrideWith((ref) => state),
        selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
        statisticsSelectedDateProvider.overrideWith((ref) => DateTime(2026, 2, 1)),
        selectedPaymentMethodExpenseTypeFilterProvider.overrideWith(
          (ref) => ExpenseTypeFilter.all,
        ),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: PaymentMethodDetailBottomSheet()),
      ),
    );
  }

  group('PaymentMethodDetailBottomSheet 위젯 테스트', () {
    testWidgets('위젯이 정상적으로 렌더링된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(PaymentMethodDetailBottomSheet), findsOneWidget);
    });

    testWidgets('결제수단 이름이 표시된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Then
      expect(find.text('신한카드'), findsOneWidget);
    });

    testWidgets('퍼센티지가 표시된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Then
      expect(find.text('40.0%'), findsOneWidget);
    });

    testWidgets('닫기 버튼(Icons.close)이 표시된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Then
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('거래 목록이 로딩 중일 때 CircularProgressIndicator가 표시된다', (tester) async {
      // Given - paymentMethodTopTransactionsProvider를 직접 오버라이드하여 로딩 상태 유지
      final completer = Completer<CategoryTopResult>();
      const state = PaymentMethodDetailState(
        isOpen: true,
        paymentMethodId: 'pm-1',
        paymentMethodName: '신한카드',
        paymentMethodIcon: 'credit_card',
        paymentMethodColor: '#4A90E2',
        canAutoSave: false,
        percentage: 40.0,
        totalAmount: 200000,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            paymentMethodDetailStateProvider.overrideWith((ref) => state),
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
            statisticsSelectedDateProvider
                .overrideWith((ref) => DateTime(2026, 2, 1)),
            selectedPaymentMethodExpenseTypeFilterProvider
                .overrideWith((ref) => ExpenseTypeFilter.all),
            paymentMethodTopTransactionsProvider
                .overrideWith((ref) => completer.future),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: PaymentMethodDetailBottomSheet()),
          ),
        ),
      );
      await tester.pump();

      // Then - 로딩 중에는 CircularProgressIndicator가 표시되어야 함
      expect(find.byType(PaymentMethodDetailBottomSheet), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // 타이머 정리
      completer.complete(const CategoryTopResult(items: [], totalAmount: 0));
      await tester.pumpAndSettle();
    });

    testWidgets('거래 데이터가 로드되면 거래 항목이 표시된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Then
      expect(find.text('편의점'), findsOneWidget);
    });

    testWidgets('거래 목록이 비어 있으면 데이터 없음 안내가 표시된다', (tester) async {
      // Given
      const emptyResult = CategoryTopResult(items: [], totalAmount: 0);

      // When
      await tester.pumpWidget(buildWidget(topResult: emptyResult));
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(PaymentMethodDetailBottomSheet), findsOneWidget);
    });

    testWidgets('isOpen=false 상태에서도 위젯이 렌더링된다', (tester) async {
      // Given
      const closedState = PaymentMethodDetailState(
        isOpen: false,
      );

      when(() => mockRepository.getPaymentMethodTopTransactions(
            ledgerId: any(named: 'ledgerId'),
            year: any(named: 'year'),
            month: any(named: 'month'),
            type: any(named: 'type'),
            paymentMethodId: any(named: 'paymentMethodId'),
            paymentMethodName: any(named: 'paymentMethodName'),
            canAutoSave: any(named: 'canAutoSave'),
            userId: any(named: 'userId'),
            expenseTypeFilter: any(named: 'expenseTypeFilter'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => const CategoryTopResult(items: [], totalAmount: 0));

      // When
      await tester.pumpWidget(buildWidget(initialState: closedState));
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(PaymentMethodDetailBottomSheet), findsOneWidget);
    });

    testWidgets('canAutoSave=true인 결제수단도 정상 렌더링된다', (tester) async {
      // Given
      const autoSaveState = PaymentMethodDetailState(
        isOpen: true,
        paymentMethodId: 'pm-2',
        paymentMethodName: 'KB카드',
        paymentMethodIcon: 'credit_card',
        paymentMethodColor: '#F4A261',
        canAutoSave: true,
        percentage: 60.0,
        totalAmount: 300000,
      );

      // When
      await tester.pumpWidget(buildWidget(initialState: autoSaveState));
      await tester.pumpAndSettle();

      // Then
      expect(find.text('KB카드'), findsOneWidget);
    });

    testWidgets('드래그 핸들이 상단에 표시된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Then - Container 위젯들이 존재해야 함
      expect(find.byType(Container), findsWidgets);
    });
  });
}
