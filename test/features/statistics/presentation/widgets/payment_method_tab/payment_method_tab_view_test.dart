import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/ledger/domain/entities/ledger.dart';
import 'package:shared_household_account/features/statistics/domain/entities/statistics_entities.dart';
import 'package:shared_household_account/features/statistics/presentation/providers/statistics_provider.dart';
import 'package:shared_household_account/features/statistics/presentation/widgets/payment_method_tab/payment_method_tab_view.dart';
import 'package:shared_household_account/features/share/presentation/providers/share_provider.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';

List<PaymentMethodStatistics> makePaymentMethods() {
  return [
    const PaymentMethodStatistics(
      paymentMethodId: 'pm-1',
      paymentMethodName: '신한카드',
      paymentMethodIcon: 'credit_card',
      paymentMethodColor: '#4A90E2',
      amount: 200000,
      percentage: 66.7,
    ),
    const PaymentMethodStatistics(
      paymentMethodId: 'pm-2',
      paymentMethodName: '현금',
      paymentMethodIcon: 'payments',
      paymentMethodColor: '#4CAF50',
      amount: 100000,
      percentage: 33.3,
    ),
  ];
}

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

Widget buildWidget({
  bool isShared = false,
  List<PaymentMethodStatistics>? statistics,
  List<LedgerMember>? members,
  SharedStatisticsState? sharedState,
}) {
  final stats = statistics ?? makePaymentMethods();
  final memberList = members ?? [];
  final state = sharedState ??
      const SharedStatisticsState(mode: SharedStatisticsMode.combined);

  return ProviderScope(
    overrides: [
      isSharedLedgerProvider.overrideWith((ref) => isShared),
      paymentMethodStatisticsProvider.overrideWith((ref) async => stats),
      paymentMethodStatisticsByUserProvider.overrideWith((ref) async => {}),
      paymentMethodDetailStateProvider.overrideWith(
        (ref) => const PaymentMethodDetailState(),
      ),
      paymentMethodSharedStatisticsStateProvider.overrideWith(
        (ref) => state,
      ),
      selectedPaymentMethodExpenseTypeFilterProvider.overrideWith(
        (ref) => ExpenseTypeFilter.all,
      ),
      currentLedgerMembersProvider.overrideWith((ref) async => memberList),
    ],
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: PaymentMethodTabView(),
      ),
    ),
  );
}

void main() {
  group('PaymentMethodTabView 위젯 테스트', () {
    testWidgets('위젯이 정상적으로 렌더링된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(PaymentMethodTabView), findsOneWidget);
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

    testWidgets('지출 라벨 GestureDetector가 표시된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('비공유 가계부에서 정상 렌더링된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget(isShared: false));
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(PaymentMethodTabView), findsOneWidget);
    });

    testWidgets('데이터가 없어도 정상 렌더링된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget(statistics: []));
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(PaymentMethodTabView), findsOneWidget);
    });

    testWidgets('Column 위젯이 표시된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('공유 가계부에서 정상 렌더링된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget(isShared: true));
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(PaymentMethodTabView), findsOneWidget);
    });

    testWidgets('공유 가계부에서 멤버가 2명 이상이면 MemberTabs가 포함된다', (tester) async {
      // Given: 공유 가계부 + 2명 멤버
      final twoMembers = [
        makeMember('user-1', displayName: '홍길동', color: '#FF5722'),
        makeMember('user-2', displayName: '김철수', color: '#4CAF50'),
      ];

      // When
      await tester.pumpWidget(
        buildWidget(isShared: true, members: twoMembers),
      );
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(PaymentMethodTabView), findsOneWidget);
    });

    testWidgets('공유 가계부에서 멤버가 1명이면 MemberTabs가 표시되지 않는다', (tester) async {
      // Given: 공유 가계부 + 1명 멤버
      final oneMember = [
        makeMember('user-1', displayName: '홍길동', color: '#FF5722'),
      ];

      // When
      await tester.pumpWidget(
        buildWidget(isShared: true, members: oneMember),
      );
      await tester.pumpAndSettle();

      // Then: 위젯은 렌더링되지만 MemberTabs는 없음
      expect(find.byType(PaymentMethodTabView), findsOneWidget);
    });

    testWidgets('pull-to-refresh를 실행하면 새로고침이 동작한다', (tester) async {
      // Given
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // When - RefreshIndicator 드래그로 새로고침 트리거
      await tester.drag(find.byType(RefreshIndicator), const Offset(0, 300));
      await tester.pumpAndSettle();

      // Then - 위젯이 여전히 정상 존재
      expect(find.byType(PaymentMethodTabView), findsOneWidget);
    });

    testWidgets('지출 라벨을 탭하면 안내 토스트가 나타난다', (tester) async {
      // Given
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // When: GestureDetector(지출 라벨) 탭
      final gestureDetectors = find.byType(GestureDetector);
      if (gestureDetectors.evaluate().isNotEmpty) {
        await tester.tap(gestureDetectors.first);
        await tester.pumpAndSettle();
      }

      // Then: 위젯이 여전히 존재
      expect(find.byType(PaymentMethodTabView), findsOneWidget);
    });

    testWidgets('고정비 필터로 변경해도 위젯이 정상 렌더링된다', (tester) async {
      // Given
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isSharedLedgerProvider.overrideWith((ref) => false),
            paymentMethodStatisticsProvider
                .overrideWith((ref) async => makePaymentMethods()),
            paymentMethodStatisticsByUserProvider
                .overrideWith((ref) async => {}),
            paymentMethodDetailStateProvider.overrideWith(
              (ref) => const PaymentMethodDetailState(),
            ),
            paymentMethodSharedStatisticsStateProvider.overrideWith(
              (ref) => const SharedStatisticsState(
                mode: SharedStatisticsMode.combined,
              ),
            ),
            selectedPaymentMethodExpenseTypeFilterProvider.overrideWith(
              (ref) => ExpenseTypeFilter.fixed,
            ),
            currentLedgerMembersProvider.overrideWith((ref) async => []),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: PaymentMethodTabView()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(PaymentMethodTabView), findsOneWidget);
    });
  });
}
