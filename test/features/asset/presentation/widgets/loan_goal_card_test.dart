import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/asset/domain/entities/asset_goal.dart';
import 'package:shared_household_account/features/asset/presentation/providers/asset_goal_provider.dart';
import 'package:shared_household_account/features/asset/presentation/widgets/loan_goal_card.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';

void main() {
  group('LoanGoalCard 위젯 테스트', () {
    late AssetGoal testLoanGoal;

    setUp(() {
      testLoanGoal = AssetGoal(
        id: 'loan-1',
        ledgerId: 'ledger-1',
        title: '주택담보대출',
        targetAmount: 300000000,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        createdBy: 'user-1',
        goalType: GoalType.loan,
        loanAmount: 300000000,
        repaymentMethod: RepaymentMethod.equalPrincipalInterest,
        annualInterestRate: 3.5,
        startDate: DateTime(2024, 1, 1),
        targetDate: DateTime(2034, 1, 1),
        monthlyPayment: 2961900,
        isManualPayment: false,
        extraRepaidAmount: 0,
      );
    });

    Widget buildApp({
      AssetGoal? goal,
      VoidCallback? onTap,
      VoidCallback? onEdit,
      VoidCallback? onDelete,
    }) {
      final g = goal ?? testLoanGoal;
      return ProviderScope(
        overrides: [
          loanRemainingBalanceProvider(g).overrideWith((_) => 250000000),
          loanEstimatedMaturityProvider(g).overrideWith((_) => null),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: LoanGoalCard(
              goal: g,
              onTap: onTap,
              onEdit: onEdit,
              onDelete: onDelete,
            ),
          ),
        ),
      );
    }

    testWidgets('기본 대출 카드가 렌더링된다', (tester) async {
      // When
      await tester.pumpWidget(buildApp());
      await tester.pump();

      // Then: 카드가 렌더링되어야 함
      expect(find.byType(LoanGoalCard), findsOneWidget);
      expect(find.byIcon(Icons.account_balance), findsWidgets);
    });

    testWidgets('대출 목표 제목이 표시된다', (tester) async {
      // When
      await tester.pumpWidget(buildApp());
      await tester.pump();

      // Then
      expect(find.text('주택담보대출'), findsOneWidget);
    });

    testWidgets('onEdit 콜백이 있으면 수정 버튼이 표시된다', (tester) async {
      // Given
      bool editCalled = false;

      // When
      await tester.pumpWidget(buildApp(
        onEdit: () => editCalled = true,
      ));
      await tester.pump();

      // Then: 수정 아이콘 버튼이 표시되어야 함
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);

      // When: 수정 버튼 탭
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pump();

      // Then: 콜백이 호출되어야 함
      expect(editCalled, isTrue);
    });

    testWidgets('onDelete 콜백이 있으면 삭제 버튼이 표시된다', (tester) async {
      // Given
      bool deleteCalled = false;

      // When
      await tester.pumpWidget(buildApp(
        onDelete: () => deleteCalled = true,
      ));
      await tester.pump();

      // Then: 삭제 아이콘 버튼이 표시되어야 함
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);

      // When: 삭제 버튼 탭
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pump();

      // Then: 콜백이 호출되어야 함
      expect(deleteCalled, isTrue);
    });

    testWidgets('onTap 콜백이 있으면 카드 탭 시 호출된다', (tester) async {
      // Given
      bool tapCalled = false;

      // When
      await tester.pumpWidget(buildApp(
        onTap: () => tapCalled = true,
      ));
      await tester.pump();

      // When: 카드 탭
      await tester.tap(find.byType(InkWell).first);
      await tester.pump();

      // Then
      expect(tapCalled, isTrue);
    });

    testWidgets('onEdit, onDelete가 null이면 해당 버튼이 표시되지 않는다', (tester) async {
      // When
      await tester.pumpWidget(buildApp());
      await tester.pump();

      // Then: 버튼이 없어야 함
      expect(find.byIcon(Icons.edit_outlined), findsNothing);
      expect(find.byIcon(Icons.delete_outline), findsNothing);
    });

    testWidgets('추가상환이 있는 대출 카드가 렌더링된다', (tester) async {
      // Given: 추가상환 있는 목표
      final goalWithExtra = testLoanGoal.copyWith(extraRepaidAmount: 5000000);

      // When
      await tester.pumpWidget(ProviderScope(
        overrides: [
          loanRemainingBalanceProvider(goalWithExtra).overrideWith((_) => 245000000),
          loanEstimatedMaturityProvider(goalWithExtra).overrideWith((_) => DateTime(2033, 6, 1)),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: LoanGoalCard(goal: goalWithExtra),
          ),
        ),
      ));
      await tester.pump();

      // Then: 카드가 렌더링되어야 함
      expect(find.byType(LoanGoalCard), findsOneWidget);
    });

    testWidgets('startDate와 targetDate가 없는 대출 카드도 렌더링된다', (tester) async {
      // Given: 날짜 없는 목표
      final goalNoDate = AssetGoal(
        id: 'loan-2',
        ledgerId: 'ledger-1',
        title: '날짜없는대출',
        targetAmount: 100000000,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        createdBy: 'user-1',
        goalType: GoalType.loan,
        loanAmount: 100000000,
        repaymentMethod: RepaymentMethod.bullet,
        annualInterestRate: 5.0,
      );

      // When
      await tester.pumpWidget(ProviderScope(
        overrides: [
          loanRemainingBalanceProvider(goalNoDate).overrideWith((_) => 0),
          loanEstimatedMaturityProvider(goalNoDate).overrideWith((_) => null),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: LoanGoalCard(goal: goalNoDate),
          ),
        ),
      ));
      await tester.pump();

      // Then
      expect(find.byType(LoanGoalCard), findsOneWidget);
      expect(find.text('날짜없는대출'), findsOneWidget);
    });
  });
}
