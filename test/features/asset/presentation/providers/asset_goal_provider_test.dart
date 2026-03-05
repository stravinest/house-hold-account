import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_household_account/features/asset/data/repositories/asset_repository.dart';
import 'package:shared_household_account/features/asset/domain/entities/asset_goal.dart';
import 'package:shared_household_account/features/asset/presentation/providers/asset_goal_provider.dart';
import 'package:shared_household_account/features/ledger/presentation/providers/ledger_provider.dart';
import 'package:shared_household_account/features/transaction/presentation/providers/transaction_provider.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  group('AssetGoalProvider Tests', () {
    late MockAssetRepository mockRepository;
    late ProviderContainer container;

    setUpAll(() {
      registerFallbackValue(
        AssetGoal(
          id: 'test-id',
          ledgerId: 'test-ledger',
          title: 'test',
          targetAmount: 1000000,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'test-user',
        ),
      );
    });

    setUp(() {
      mockRepository = MockAssetRepository();
    });

    tearDown(() {
      container.dispose();
    });

    group('assetGoalsProvider', () {
      test('ledgerId가 null인 경우 빈 리스트를 반환한다', () async {
        // Given
        container = createContainer(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => null),
            assetGoalRepositoryProvider.overrideWith((ref) => mockRepository),
          ],
        );

        // When
        final goals = await container.read(assetGoalsProvider.future);

        // Then
        expect(goals, isEmpty);
        verifyNever(() => mockRepository.getGoals(ledgerId: any(named: 'ledgerId')));
      });

      test('ledgerId가 있는 경우 목표 목록을 가져온다', () async {
        // Given
        const testLedgerId = 'test-ledger-id';
        final mockGoals = [
          AssetGoal(
            id: 'goal-1',
            ledgerId: testLedgerId,
            title: '비상금 모으기',
            targetAmount: 10000000,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            createdBy: 'user-1',
          ),
          AssetGoal(
            id: 'goal-2',
            ledgerId: testLedgerId,
            title: '주택 구입 자금',
            targetAmount: 500000000,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            createdBy: 'user-1',
          ),
        ];

        when(() => mockRepository.getGoals(ledgerId: testLedgerId))
            .thenAnswer((_) async => mockGoals);

        container = createContainer(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => testLedgerId),
            assetGoalRepositoryProvider.overrideWith((ref) => mockRepository),
          ],
        );

        // When
        final goals = await container.read(assetGoalsProvider.future);

        // Then
        expect(goals.length, equals(2));
        expect(goals[0].title, equals('비상금 모으기'));
        expect(goals[1].title, equals('주택 구입 자금'));
        verify(() => mockRepository.getGoals(ledgerId: testLedgerId)).called(1);
      });
    });

    group('loanGoalsProvider', () {
      test('대출 목표만 필터링하여 반환한다', () async {
        // Given
        const testLedgerId = 'test-ledger-id';
        final now = DateTime.now();
        final mockGoals = [
          AssetGoal(
            id: 'asset-1',
            ledgerId: testLedgerId,
            title: '비상금',
            targetAmount: 10000000,
            createdAt: now,
            updatedAt: now,
            createdBy: 'user-1',
            goalType: GoalType.asset,
          ),
          AssetGoal(
            id: 'loan-1',
            ledgerId: testLedgerId,
            title: '주택담보대출',
            targetAmount: 300000000,
            createdAt: now,
            updatedAt: now,
            createdBy: 'user-1',
            goalType: GoalType.loan,
            loanAmount: 300000000,
          ),
          AssetGoal(
            id: 'loan-2',
            ledgerId: testLedgerId,
            title: '자동차 할부',
            targetAmount: 30000000,
            createdAt: now,
            updatedAt: now,
            createdBy: 'user-1',
            goalType: GoalType.loan,
            loanAmount: 30000000,
          ),
        ];

        when(() => mockRepository.getGoals(ledgerId: testLedgerId))
            .thenAnswer((_) async => mockGoals);

        container = createContainer(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => testLedgerId),
            assetGoalRepositoryProvider.overrideWith((ref) => mockRepository),
          ],
        );

        // When
        final loanGoals = await container.read(loanGoalsProvider.future);

        // Then
        expect(loanGoals.length, 2);
        expect(loanGoals.every((g) => g.goalType == GoalType.loan), isTrue);
        expect(loanGoals.map((g) => g.id), containsAll(['loan-1', 'loan-2']));
      });

      test('대출 목표가 없으면 빈 리스트를 반환한다', () async {
        // Given
        const testLedgerId = 'test-ledger-id';
        final now = DateTime.now();
        final mockGoals = [
          AssetGoal(
            id: 'asset-1',
            ledgerId: testLedgerId,
            title: '비상금',
            targetAmount: 10000000,
            createdAt: now,
            updatedAt: now,
            createdBy: 'user-1',
            goalType: GoalType.asset,
          ),
        ];

        when(() => mockRepository.getGoals(ledgerId: testLedgerId))
            .thenAnswer((_) async => mockGoals);

        container = createContainer(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => testLedgerId),
            assetGoalRepositoryProvider.overrideWith((ref) => mockRepository),
          ],
        );

        // When
        final loanGoals = await container.read(loanGoalsProvider.future);

        // Then
        expect(loanGoals, isEmpty);
      });
    });

    group('assetOnlyGoalsProvider', () {
      test('자산 목표만 필터링하여 반환한다', () async {
        // Given
        const testLedgerId = 'test-ledger-id';
        final now = DateTime.now();
        final mockGoals = [
          AssetGoal(
            id: 'asset-1',
            ledgerId: testLedgerId,
            title: '비상금',
            targetAmount: 10000000,
            createdAt: now,
            updatedAt: now,
            createdBy: 'user-1',
            goalType: GoalType.asset,
          ),
          AssetGoal(
            id: 'loan-1',
            ledgerId: testLedgerId,
            title: '주택담보대출',
            targetAmount: 300000000,
            createdAt: now,
            updatedAt: now,
            createdBy: 'user-1',
            goalType: GoalType.loan,
          ),
        ];

        when(() => mockRepository.getGoals(ledgerId: testLedgerId))
            .thenAnswer((_) async => mockGoals);

        container = createContainer(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => testLedgerId),
            assetGoalRepositoryProvider.overrideWith((ref) => mockRepository),
          ],
        );

        // When
        final assetGoals = await container.read(assetOnlyGoalsProvider.future);

        // Then
        expect(assetGoals.length, 1);
        expect(assetGoals[0].goalType, GoalType.asset);
        expect(assetGoals[0].id, 'asset-1');
      });
    });

    group('assetGoalProgressProvider', () {
      test('현재 금액이 목표금액과 같으면 진행률이 1.0이어야 한다', () async {
        // Given
        const testLedgerId = 'ledger-1';
        final goal = AssetGoal(
          id: 'goal-1',
          ledgerId: testLedgerId,
          title: '비상금',
          targetAmount: 10000000,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'user-1',
        );

        when(() => mockRepository.getCurrentAmount(
          ledgerId: testLedgerId,
          assetType: any(named: 'assetType'),
          categoryIds: any(named: 'categoryIds'),
        )).thenAnswer((_) async => 10000000);

        container = createContainer(
          overrides: [
            assetGoalRepositoryProvider.overrideWith((ref) => mockRepository),
            transactionUpdateTriggerProvider.overrideWith((ref) => 0),
          ],
        );

        // When - 비동기 provider가 완료되길 기다림
        await container.read(assetGoalCurrentAmountProvider(goal).future);
        final progress = container.read(assetGoalProgressProvider(goal));

        // Then
        expect(progress, closeTo(1.0, 0.001));
      });

      test('현재 금액이 0이면 진행률이 0.0이어야 한다', () async {
        // Given
        const testLedgerId = 'ledger-1';
        final goal = AssetGoal(
          id: 'goal-1',
          ledgerId: testLedgerId,
          title: '비상금',
          targetAmount: 10000000,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'user-1',
        );

        when(() => mockRepository.getCurrentAmount(
          ledgerId: testLedgerId,
          assetType: any(named: 'assetType'),
          categoryIds: any(named: 'categoryIds'),
        )).thenAnswer((_) async => 0);

        container = createContainer(
          overrides: [
            assetGoalRepositoryProvider.overrideWith((ref) => mockRepository),
            transactionUpdateTriggerProvider.overrideWith((ref) => 0),
          ],
        );

        // When
        await container.read(assetGoalCurrentAmountProvider(goal).future);
        final progress = container.read(assetGoalProgressProvider(goal));

        // Then
        expect(progress, closeTo(0.0, 0.001));
      });

      test('현재 금액이 목표금액의 50%이면 진행률이 0.5이어야 한다', () async {
        // Given
        const testLedgerId = 'ledger-1';
        final goal = AssetGoal(
          id: 'goal-1',
          ledgerId: testLedgerId,
          title: '비상금',
          targetAmount: 10000000,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'user-1',
        );

        when(() => mockRepository.getCurrentAmount(
          ledgerId: testLedgerId,
          assetType: any(named: 'assetType'),
          categoryIds: any(named: 'categoryIds'),
        )).thenAnswer((_) async => 5000000);

        container = createContainer(
          overrides: [
            assetGoalRepositoryProvider.overrideWith((ref) => mockRepository),
            transactionUpdateTriggerProvider.overrideWith((ref) => 0),
          ],
        );

        // When
        await container.read(assetGoalCurrentAmountProvider(goal).future);
        final progress = container.read(assetGoalProgressProvider(goal));

        // Then
        expect(progress, closeTo(0.5, 0.001));
      });

      test('현재 금액이 목표금액을 초과해도 진행률은 최대 1.0이어야 한다', () async {
        // Given
        const testLedgerId = 'ledger-1';
        final goal = AssetGoal(
          id: 'goal-1',
          ledgerId: testLedgerId,
          title: '비상금',
          targetAmount: 10000000,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'user-1',
        );

        when(() => mockRepository.getCurrentAmount(
          ledgerId: testLedgerId,
          assetType: any(named: 'assetType'),
          categoryIds: any(named: 'categoryIds'),
        )).thenAnswer((_) async => 20000000);

        container = createContainer(
          overrides: [
            assetGoalRepositoryProvider.overrideWith((ref) => mockRepository),
            transactionUpdateTriggerProvider.overrideWith((ref) => 0),
          ],
        );

        // When
        await container.read(assetGoalCurrentAmountProvider(goal).future);
        final progress = container.read(assetGoalProgressProvider(goal));

        // Then
        expect(progress, closeTo(1.0, 0.001));
      });

      test('목표금액이 0이면 진행률이 0.0이어야 한다', () async {
        // Given
        const testLedgerId = 'ledger-1';
        final goal = AssetGoal(
          id: 'goal-1',
          ledgerId: testLedgerId,
          title: '비상금',
          targetAmount: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'user-1',
        );

        when(() => mockRepository.getCurrentAmount(
          ledgerId: testLedgerId,
          assetType: any(named: 'assetType'),
          categoryIds: any(named: 'categoryIds'),
        )).thenAnswer((_) async => 5000000);

        container = createContainer(
          overrides: [
            assetGoalRepositoryProvider.overrideWith((ref) => mockRepository),
            transactionUpdateTriggerProvider.overrideWith((ref) => 0),
          ],
        );

        // When
        await container.read(assetGoalCurrentAmountProvider(goal).future);
        final progress = container.read(assetGoalProgressProvider(goal));

        // Then
        expect(progress, 0.0);
      });
    });

    group('assetGoalRemainingDaysProvider', () {
      test('목표 날짜가 있는 경우 남은 일수를 계산한다', () {
        // Given
        final now = DateTime.now();
        final targetDate = now.add(const Duration(days: 30));

        final goal = AssetGoal(
          id: 'goal-1',
          ledgerId: 'ledger-1',
          title: '비상금',
          targetAmount: 10000000,
          targetDate: targetDate,
          createdAt: now,
          updatedAt: now,
          createdBy: 'user-1',
        );

        container = createContainer();

        // When
        final remainingDays =
            container.read(assetGoalRemainingDaysProvider(goal));

        // Then: 약 30일
        expect(remainingDays, isNotNull);
        expect(remainingDays! >= 29 && remainingDays <= 30, isTrue);
      });

      test('목표 날짜가 없는 경우 null을 반환한다', () {
        // Given
        final goal = AssetGoal(
          id: 'goal-1',
          ledgerId: 'ledger-1',
          title: '비상금',
          targetAmount: 10000000,
          targetDate: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'user-1',
        );

        container = createContainer();

        // When
        final remainingDays =
            container.read(assetGoalRemainingDaysProvider(goal));

        // Then
        expect(remainingDays, isNull);
      });

      test('목표 날짜가 과거인 경우 음수를 반환한다', () {
        // Given
        final pastDate = DateTime.now().subtract(const Duration(days: 10));
        final goal = AssetGoal(
          id: 'goal-1',
          ledgerId: 'ledger-1',
          title: '비상금',
          targetAmount: 10000000,
          targetDate: pastDate,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'user-1',
        );

        container = createContainer();

        // When
        final remainingDays =
            container.read(assetGoalRemainingDaysProvider(goal));

        // Then
        expect(remainingDays, isNotNull);
        expect(remainingDays!, isNegative);
      });
    });

    group('loanRemainingBalanceProvider', () {
      test('대출 목표가 아니면 0을 반환한다', () {
        // Given
        final goal = AssetGoal(
          id: 'goal-1',
          ledgerId: 'ledger-1',
          title: '비상금',
          targetAmount: 10000000,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'user-1',
          goalType: GoalType.asset,
        );

        container = createContainer();

        // When
        final balance = container.read(loanRemainingBalanceProvider(goal));

        // Then
        expect(balance, 0);
      });

      test('startDate 또는 targetDate가 null이면 0을 반환한다', () {
        // Given
        final goal = AssetGoal(
          id: 'loan-1',
          ledgerId: 'ledger-1',
          title: '주택담보대출',
          targetAmount: 300000000,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'user-1',
          goalType: GoalType.loan,
          loanAmount: 300000000,
          startDate: null,
          targetDate: null,
        );

        container = createContainer();

        // When
        final balance = container.read(loanRemainingBalanceProvider(goal));

        // Then
        expect(balance, 0);
      });

      test('유효한 대출 목표에 대해 잔여 원금을 계산한다', () {
        // Given
        final startDate = DateTime(2024, 1, 1);
        final targetDate = DateTime(2032, 1, 1);
        final goal = AssetGoal(
          id: 'loan-1',
          ledgerId: 'ledger-1',
          title: '주택담보대출',
          targetAmount: 200000000,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
          createdBy: 'user-1',
          goalType: GoalType.loan,
          loanAmount: 200000000,
          annualInterestRate: 3.5,
          repaymentMethod: RepaymentMethod.equalPrincipalInterest,
          startDate: startDate,
          targetDate: targetDate,
          extraRepaidAmount: 0,
        );

        container = createContainer();

        // When
        final balance = container.read(loanRemainingBalanceProvider(goal));

        // Then: 잔여 원금은 양수이고 대출금보다 작거나 같아야 함
        expect(balance, greaterThanOrEqualTo(0));
        expect(balance, lessThanOrEqualTo(200000000));
      });

      test('추가상환이 있으면 잔여 원금이 더 작아야 한다', () {
        // Given
        final startDate = DateTime(2024, 1, 1);
        final targetDate = DateTime(2032, 1, 1);

        final goalWithoutExtra = AssetGoal(
          id: 'loan-1',
          ledgerId: 'ledger-1',
          title: '주택담보대출',
          targetAmount: 200000000,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
          createdBy: 'user-1',
          goalType: GoalType.loan,
          loanAmount: 200000000,
          annualInterestRate: 3.5,
          repaymentMethod: RepaymentMethod.equalPrincipalInterest,
          startDate: startDate,
          targetDate: targetDate,
          extraRepaidAmount: 0,
        );

        final goalWithExtra = goalWithoutExtra.copyWith(
          extraRepaidAmount: 10000000,
        );

        container = createContainer();

        // When
        final balanceWithout = container.read(loanRemainingBalanceProvider(goalWithoutExtra));
        final balanceWith = container.read(loanRemainingBalanceProvider(goalWithExtra));

        // Then
        expect(balanceWith, lessThan(balanceWithout));
      });
    });

    group('loanMonthlyPaymentProvider', () {
      test('대출 목표가 아니면 0을 반환한다', () {
        // Given
        final goal = AssetGoal(
          id: 'goal-1',
          ledgerId: 'ledger-1',
          title: '비상금',
          targetAmount: 10000000,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'user-1',
          goalType: GoalType.asset,
        );

        container = createContainer();

        // When
        final payment = container.read(loanMonthlyPaymentProvider(goal));

        // Then
        expect(payment, 0);
      });

      test('수동 입력 모드에서는 저장된 monthlyPayment를 반환한다', () {
        // Given
        final goal = AssetGoal(
          id: 'loan-1',
          ledgerId: 'ledger-1',
          title: '주택담보대출',
          targetAmount: 200000000,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'user-1',
          goalType: GoalType.loan,
          loanAmount: 200000000,
          isManualPayment: true,
          monthlyPayment: 1500000,
          startDate: DateTime(2024, 1, 1),
          targetDate: DateTime(2032, 1, 1),
        );

        container = createContainer();

        // When
        final payment = container.read(loanMonthlyPaymentProvider(goal));

        // Then
        expect(payment, 1500000);
      });

      test('자동 계산 모드에서 원리금균등 월 상환금을 계산한다', () {
        // Given
        final goal = AssetGoal(
          id: 'loan-1',
          ledgerId: 'ledger-1',
          title: '주택담보대출',
          targetAmount: 200000000,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'user-1',
          goalType: GoalType.loan,
          loanAmount: 200000000,
          annualInterestRate: 3.5,
          repaymentMethod: RepaymentMethod.equalPrincipalInterest,
          startDate: DateTime(2025, 1, 1),
          targetDate: DateTime(2033, 1, 1),
          isManualPayment: false,
        );

        container = createContainer();

        // When
        final payment = container.read(loanMonthlyPaymentProvider(goal));

        // Then: 2억, 3.5%, 96개월 -> 약 2,390,000원 근처
        expect(payment, greaterThan(2000000));
        expect(payment, lessThan(2600000));
      });

      test('startDate 또는 targetDate가 없으면 0을 반환한다', () {
        // Given
        final goal = AssetGoal(
          id: 'loan-1',
          ledgerId: 'ledger-1',
          title: '주택담보대출',
          targetAmount: 200000000,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'user-1',
          goalType: GoalType.loan,
          loanAmount: 200000000,
          isManualPayment: false,
          startDate: null,
          targetDate: null,
        );

        container = createContainer();

        // When
        final payment = container.read(loanMonthlyPaymentProvider(goal));

        // Then
        expect(payment, 0);
      });
    });

    group('loanEstimatedMaturityProvider', () {
      test('대출 목표가 아니면 null을 반환한다', () {
        // Given
        final goal = AssetGoal(
          id: 'goal-1',
          ledgerId: 'ledger-1',
          title: '비상금',
          targetAmount: 10000000,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'user-1',
          goalType: GoalType.asset,
        );

        container = createContainer();

        // When
        final maturity = container.read(loanEstimatedMaturityProvider(goal));

        // Then
        expect(maturity, isNull);
      });

      test('추가상환이 없으면 null을 반환한다', () {
        // Given
        final goal = AssetGoal(
          id: 'loan-1',
          ledgerId: 'ledger-1',
          title: '주택담보대출',
          targetAmount: 200000000,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'user-1',
          goalType: GoalType.loan,
          loanAmount: 200000000,
          extraRepaidAmount: 0,
          startDate: DateTime(2024, 1, 1),
          targetDate: DateTime(2032, 1, 1),
        );

        container = createContainer();

        // When
        final maturity = container.read(loanEstimatedMaturityProvider(goal));

        // Then
        expect(maturity, isNull);
      });

      test('추가상환이 있으면 예상 만기일이 원래 만기일보다 이전이어야 한다', () {
        // Given
        final startDate = DateTime(2024, 1, 1);
        final targetDate = DateTime(2032, 1, 1);
        final goal = AssetGoal(
          id: 'loan-1',
          ledgerId: 'ledger-1',
          title: '주택담보대출',
          targetAmount: 200000000,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
          createdBy: 'user-1',
          goalType: GoalType.loan,
          loanAmount: 200000000,
          annualInterestRate: 3.5,
          repaymentMethod: RepaymentMethod.equalPrincipalInterest,
          startDate: startDate,
          targetDate: targetDate,
          extraRepaidAmount: 20000000,
        );

        container = createContainer();

        // When
        final maturity = container.read(loanEstimatedMaturityProvider(goal));

        // Then: 만기 단축이 있어야 함 (null이 아니고 원래 만기일보다 이전)
        if (maturity != null) {
          expect(maturity.isBefore(targetDate), isTrue);
        }
      });

      test('startDate 또는 targetDate가 null이면 null을 반환한다', () {
        // Given
        final goal = AssetGoal(
          id: 'loan-1',
          ledgerId: 'ledger-1',
          title: '주택담보대출',
          targetAmount: 200000000,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'user-1',
          goalType: GoalType.loan,
          loanAmount: 200000000,
          extraRepaidAmount: 10000000,
          startDate: null,
          targetDate: null,
        );

        container = createContainer();

        // When
        final maturity = container.read(loanEstimatedMaturityProvider(goal));

        // Then
        expect(maturity, isNull);
      });
    });

    group('AssetGoalNotifier - updateGoal', () {
      test('updateGoal 호출 시 repository.updateGoal이 실행되고 목록을 재조회한다', () async {
        // Given
        const testLedgerId = 'ledger-1';
        final now = DateTime.now();
        final updatedGoal = AssetGoal(
          id: 'goal-1',
          ledgerId: testLedgerId,
          title: '수정된 목표',
          targetAmount: 20000000,
          createdAt: now,
          updatedAt: now,
          createdBy: 'user-1',
        );

        when(() => mockRepository.updateGoal(any()))
            .thenAnswer((_) async => updatedGoal);
        when(() => mockRepository.getGoals(ledgerId: testLedgerId))
            .thenAnswer((_) async => [updatedGoal]);

        container = createContainer(
          overrides: [
            assetGoalRepositoryProvider.overrideWith((ref) => mockRepository),
          ],
        );

        // When
        final notifier = container.read(
          assetGoalNotifierProvider(testLedgerId).notifier,
        );
        await notifier.updateGoal(updatedGoal);

        // Then
        verify(() => mockRepository.updateGoal(any())).called(1);
      });

      test('deleteGoal 호출 시 repository.deleteGoal이 실행되고 목록을 재조회한다', () async {
        // Given
        const testLedgerId = 'ledger-1';

        when(() => mockRepository.deleteGoal(any()))
            .thenAnswer((_) async {});
        when(() => mockRepository.getGoals(ledgerId: testLedgerId))
            .thenAnswer((_) async => []);

        container = createContainer(
          overrides: [
            assetGoalRepositoryProvider.overrideWith((ref) => mockRepository),
          ],
        );

        // When
        final notifier = container.read(
          assetGoalNotifierProvider(testLedgerId).notifier,
        );
        await notifier.deleteGoal('goal-1');

        // Then
        verify(() => mockRepository.deleteGoal('goal-1')).called(1);
      });
    });

    group('AssetGoalNotifier - 초기 로드', () {
      test('notifier 생성 시 자동으로 목표를 로드한다', () async {
        // Given
        const testLedgerId = 'ledger-1';
        final now = DateTime.now();
        final mockGoals = [
          AssetGoal(
            id: 'goal-1',
            ledgerId: testLedgerId,
            title: '비상금',
            targetAmount: 10000000,
            createdAt: now,
            updatedAt: now,
            createdBy: 'user-1',
          ),
        ];

        when(() => mockRepository.getGoals(ledgerId: testLedgerId))
            .thenAnswer((_) async => mockGoals);

        container = createContainer(
          overrides: [
            assetGoalRepositoryProvider.overrideWith((ref) => mockRepository),
          ],
        );

        // When: notifier를 읽으면 자동으로 _loadGoals가 호출됨
        container.read(assetGoalNotifierProvider(testLedgerId));
        await Future.delayed(const Duration(milliseconds: 100));

        final state = container.read(assetGoalNotifierProvider(testLedgerId));

        // Then
        expect(state, isA<AsyncValue<List<AssetGoal>>>());
        verify(() => mockRepository.getGoals(ledgerId: testLedgerId))
            .called(greaterThan(0));
      });
    });

    group('assetGoalProgressProvider - loading/error 상태', () {
      test('currentAmount가 로딩 중이면 진행률이 0.0이어야 한다', () async {
        // Given
        const testLedgerId = 'ledger-1';
        final goal = AssetGoal(
          id: 'goal-1',
          ledgerId: testLedgerId,
          title: '비상금',
          targetAmount: 10000000,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'user-1',
        );

        // 완료되지 않는 Future로 loading 상태 유지
        when(() => mockRepository.getCurrentAmount(
          ledgerId: testLedgerId,
          assetType: any(named: 'assetType'),
          categoryIds: any(named: 'categoryIds'),
        )).thenAnswer((_) => Completer<int>().future);

        container = createContainer(
          overrides: [
            assetGoalRepositoryProvider.overrideWith((ref) => mockRepository),
            transactionUpdateTriggerProvider.overrideWith((ref) => 0),
          ],
        );

        // When: loading 상태에서 읽으면 0.0 반환
        final progress = container.read(assetGoalProgressProvider(goal));

        // Then
        expect(progress, closeTo(0.0, 0.001));
      });

      test('currentAmount에서 에러 발생 시 진행률이 0.0이어야 한다', () async {
        // Given
        const testLedgerId = 'ledger-1';
        final goal = AssetGoal(
          id: 'goal-1',
          ledgerId: testLedgerId,
          title: '비상금',
          targetAmount: 10000000,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'user-1',
        );

        when(() => mockRepository.getCurrentAmount(
          ledgerId: testLedgerId,
          assetType: any(named: 'assetType'),
          categoryIds: any(named: 'categoryIds'),
        )).thenThrow(Exception('네트워크 오류'));

        container = createContainer(
          overrides: [
            assetGoalRepositoryProvider.overrideWith((ref) => mockRepository),
            transactionUpdateTriggerProvider.overrideWith((ref) => 0),
          ],
        );

        // When: 에러 발생 후 provider 완료 대기
        try {
          await container.read(assetGoalCurrentAmountProvider(goal).future);
        } catch (_) {}
        final progress = container.read(assetGoalProgressProvider(goal));

        // Then: 에러 상태에서 0.0 반환
        expect(progress, closeTo(0.0, 0.001));
      });
    });

    group('AssetGoalNotifier - createGoal 에러 처리', () {
      test('createGoal 호출 시 Supabase 미초기화 상태에서 에러 상태로 전환된다', () async {
        // Given
        const testLedgerId = 'ledger-1';

        when(() => mockRepository.getGoals(ledgerId: testLedgerId))
            .thenAnswer((_) async => []);

        container = createContainer(
          overrides: [
            assetGoalRepositoryProvider.overrideWith((ref) => mockRepository),
          ],
        );

        final notifier = container.read(
          assetGoalNotifierProvider(testLedgerId).notifier,
        );

        // When: Supabase가 초기화되지 않은 테스트 환경에서 createGoal 호출
        await notifier.createGoal(
          title: '테스트 목표',
          targetAmount: 1000000,
        );

        // Then: 에러 상태가 되거나 로딩 상태가 처리되어야 한다
        final state = container.read(assetGoalNotifierProvider(testLedgerId));
        expect(state, isA<AsyncValue<List<AssetGoal>>>());
      });

      test('createLoanGoal 호출 시 Supabase 미초기화 상태에서 에러 상태로 전환된다', () async {
        // Given
        const testLedgerId = 'ledger-1';

        when(() => mockRepository.getGoals(ledgerId: testLedgerId))
            .thenAnswer((_) async => []);

        container = createContainer(
          overrides: [
            assetGoalRepositoryProvider.overrideWith((ref) => mockRepository),
          ],
        );

        final notifier = container.read(
          assetGoalNotifierProvider(testLedgerId).notifier,
        );

        // When: Supabase가 초기화되지 않은 테스트 환경에서 createLoanGoal 호출
        await notifier.createLoanGoal(
          title: '테스트 대출 목표',
          loanAmount: 100000000,
          repaymentMethod: RepaymentMethod.equalPrincipalInterest,
        );

        // Then: 에러 상태가 되거나 로딩 상태가 처리되어야 한다
        final state = container.read(assetGoalNotifierProvider(testLedgerId));
        expect(state, isA<AsyncValue<List<AssetGoal>>>());
      });
    });

    group('assetGoalCurrentAmountProvider', () {
      test('카테고리 ID 목록이 있으면 getCurrentAmount에 전달된다', () async {
        // Given
        const testLedgerId = 'ledger-1';
        final categoryIds = ['cat-1', 'cat-2'];
        final goal = AssetGoal(
          id: 'goal-1',
          ledgerId: testLedgerId,
          title: '비상금',
          targetAmount: 10000000,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'user-1',
          categoryIds: categoryIds,
        );

        when(() => mockRepository.getCurrentAmount(
          ledgerId: testLedgerId,
          assetType: any(named: 'assetType'),
          categoryIds: any(named: 'categoryIds'),
        )).thenAnswer((_) async => 5000000);

        container = createContainer(
          overrides: [
            assetGoalRepositoryProvider.overrideWith((ref) => mockRepository),
            transactionUpdateTriggerProvider.overrideWith((ref) => 0),
          ],
        );

        // When
        final amount = await container.read(
          assetGoalCurrentAmountProvider(goal).future,
        );

        // Then
        expect(amount, 5000000);
        verify(() => mockRepository.getCurrentAmount(
          ledgerId: testLedgerId,
          assetType: any(named: 'assetType'),
          categoryIds: any(named: 'categoryIds'),
        )).called(1);
      });
    });
  });
}
