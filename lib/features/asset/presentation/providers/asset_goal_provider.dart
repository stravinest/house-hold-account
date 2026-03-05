import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/providers/safe_notifier.dart';

import '../../domain/entities/asset_goal.dart';
import '../../data/repositories/asset_repository.dart';
import '../../data/services/loan_calculator_service.dart';
import '../../../ledger/presentation/providers/ledger_provider.dart';
import '../../../transaction/presentation/providers/transaction_provider.dart';

final assetGoalRepositoryProvider = Provider<AssetRepository>((ref) {
  return AssetRepository();
});

final assetGoalsProvider = FutureProvider<List<AssetGoal>>((ref) async {
  final ledgerId = ref.watch(selectedLedgerIdProvider);
  if (ledgerId == null) return [];

  final repository = ref.watch(assetGoalRepositoryProvider);
  return repository.getGoals(ledgerId: ledgerId);
});

class AssetGoalNotifier extends SafeNotifier<List<AssetGoal>> {
  final AssetRepository _repository;
  final String _ledgerId;

  AssetGoalNotifier(this._repository, this._ledgerId, Ref ref)
    : super(ref, const AsyncValue.loading()) {
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repository.getGoals(ledgerId: _ledgerId),
    );
  }

  Future<void> createGoal({
    required String title,
    required int targetAmount,
    DateTime? targetDate,
    String? assetType,
    List<String>? categoryIds,
    String? memo,
  }) async {
    await safeGuard(() async {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('로그인이 필요합니다');
      }

      final goal = AssetGoal(
        id: '',
        ledgerId: _ledgerId,
        title: title,
        targetAmount: targetAmount,
        targetDate: targetDate,
        assetType: assetType,
        categoryIds: categoryIds,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: currentUser.id,
        memo: memo,
      );

      await _repository.createGoal(goal);
      final result = await _repository.getGoals(ledgerId: _ledgerId);
      return result;
    });
  }

  Future<void> updateGoal(AssetGoal goal) async {
    await safeGuard(() async {
      await _repository.updateGoal(goal);
      return _repository.getGoals(ledgerId: _ledgerId);
    });
  }

  Future<void> deleteGoal(String goalId) async {
    await safeGuard(() async {
      await _repository.deleteGoal(goalId);
      return _repository.getGoals(ledgerId: _ledgerId);
    });
  }

  Future<void> createLoanGoal({
    required String title,
    required int loanAmount,
    required RepaymentMethod repaymentMethod,
    double? annualInterestRate,
    DateTime? startDate,
    DateTime? targetDate,
    int? monthlyPayment,
    bool isManualPayment = false,
    String? memo,
  }) async {
    await safeGuard(() async {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('로그인이 필요합니다');
      }

      final goal = AssetGoal(
        id: '',
        ledgerId: _ledgerId,
        title: title,
        targetAmount: loanAmount,
        targetDate: targetDate,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: currentUser.id,
        goalType: GoalType.loan,
        loanAmount: loanAmount,
        repaymentMethod: repaymentMethod,
        annualInterestRate: annualInterestRate,
        startDate: startDate,
        monthlyPayment: monthlyPayment,
        isManualPayment: isManualPayment,
        memo: memo,
      );

      await _repository.createGoal(goal);
      return _repository.getGoals(ledgerId: _ledgerId);
    });
  }
}

final assetGoalNotifierProvider =
    StateNotifierProvider.family<
      AssetGoalNotifier,
      AsyncValue<List<AssetGoal>>,
      String
    >((ref, ledgerId) {
      final repository = ref.watch(assetGoalRepositoryProvider);
      return AssetGoalNotifier(repository, ledgerId, ref);
    });

final assetGoalCurrentAmountProvider = FutureProvider.family<int, AssetGoal>((
  ref,
  goal,
) async {
  // 거래 변경 시에만 재조회하도록 트리거 watch (최적화)
  ref.watch(transactionUpdateTriggerProvider);

  final repository = ref.watch(assetGoalRepositoryProvider);
  return repository.getCurrentAmount(
    ledgerId: goal.ledgerId,
    assetType: goal.assetType,
    categoryIds: goal.categoryIds,
  );
});

final assetGoalProgressProvider = Provider.family<double, AssetGoal>((
  ref,
  goal,
) {
  final currentAmount = ref.watch(assetGoalCurrentAmountProvider(goal));

  return currentAmount.when(
    data: (amount) {
      if (goal.targetAmount == 0) return 0.0;
      return (amount / goal.targetAmount).clamp(0.0, 1.0);
    },
    loading: () => 0.0,
    error: (error, stack) => 0.0,
  );
});

final assetGoalRemainingDaysProvider = Provider.family<int?, AssetGoal>((
  ref,
  goal,
) {
  if (goal.targetDate == null) return null;
  final now = DateTime.now();
  return goal.targetDate!.difference(now).inDays;
});

// goalType == loan 인 목표만 필터링
final loanGoalsProvider = FutureProvider<List<AssetGoal>>((ref) async {
  final goals = await ref.watch(assetGoalsProvider.future);
  return goals.where((g) => g.goalType == GoalType.loan).toList();
});

// goalType == asset 인 목표만 필터링
final assetOnlyGoalsProvider = FutureProvider<List<AssetGoal>>((ref) async {
  final goals = await ref.watch(assetGoalsProvider.future);
  return goals.where((g) => g.goalType == GoalType.asset).toList();
});

// 대출 목표의 현재 잔여 원금 (추가상환 반영)
final loanRemainingBalanceProvider = Provider.family<int, AssetGoal>((
  ref,
  goal,
) {
  if (goal.goalType != GoalType.loan) return 0;
  final loanAmount = goal.loanAmount ?? 0;
  final rate = goal.annualInterestRate ?? 0.0;
  final method =
      goal.repaymentMethod ?? RepaymentMethod.equalPrincipalInterest;
  final startDate = goal.startDate;
  final targetDate = goal.targetDate;
  if (startDate == null || targetDate == null || loanAmount <= 0) return 0;

  final now = DateTime.now();
  final totalMonths =
      LoanCalculatorService.calculateMonthsBetween(startDate, targetDate);
  final elapsedMonths =
      LoanCalculatorService.calculateMonthsBetween(startDate, now);
  if (totalMonths <= 0 || elapsedMonths <= 0) return loanAmount;

  final remaining = LoanCalculatorService.calculateRemainingBalance(
    loanAmount: loanAmount,
    annualInterestRate: rate,
    totalMonths: totalMonths,
    elapsedMonths: elapsedMonths,
    method: method,
  );
  return (remaining - goal.extraRepaidAmount).clamp(0, loanAmount);
});

// 추가상환 반영 예상 만기일 (추가상환 없으면 null)
final loanEstimatedMaturityProvider = Provider.family<DateTime?, AssetGoal>((
  ref,
  goal,
) {
  if (goal.goalType != GoalType.loan || goal.extraRepaidAmount <= 0) {
    return null;
  }
  final loanAmount = goal.loanAmount ?? 0;
  final rate = goal.annualInterestRate ?? 0.0;
  final method =
      goal.repaymentMethod ?? RepaymentMethod.equalPrincipalInterest;
  final startDate = goal.startDate;
  final targetDate = goal.targetDate;
  if (startDate == null || targetDate == null || loanAmount <= 0) return null;

  final now = DateTime.now();
  final totalMonths =
      LoanCalculatorService.calculateMonthsBetween(startDate, targetDate);
  final elapsedMonths =
      LoanCalculatorService.calculateMonthsBetween(startDate, now);
  if (totalMonths <= 0 || elapsedMonths <= 0) return null;

  final remainingBalance = LoanCalculatorService.calculateRemainingBalance(
    loanAmount: loanAmount,
    annualInterestRate: rate,
    totalMonths: totalMonths,
    elapsedMonths: elapsedMonths,
    method: method,
  );

  final currentMonthlyPayment = LoanCalculatorService.calculateMonthlyPayment(
    loanAmount: loanAmount,
    annualInterestRate: rate,
    totalMonths: totalMonths,
    method: method,
    currentMonth: elapsedMonths + 1,
  );

  final newMonths = LoanCalculatorService.calculateNewMaturityMonths(
    remainingBalance: remainingBalance,
    extraRepayment: goal.extraRepaidAmount,
    annualInterestRate: rate,
    currentMonthlyPayment: currentMonthlyPayment,
    method: method,
    originalLoanAmount: loanAmount,
    originalTotalMonths: totalMonths,
  );

  if (newMonths < 0) return null;
  if (newMonths == 0) return now;

  // day를 1로 고정하여 월 오버플로우 방지
  return DateTime(now.year, now.month + newMonths, 1);
});

// 대출 목표의 자동 계산된 월 상환금 (isManualPayment=true이면 monthlyPayment 직접 사용)
final loanMonthlyPaymentProvider = Provider.family<int, AssetGoal>((ref, goal) {
  if (goal.goalType != GoalType.loan) return 0;

  // 수동 입력 모드이면 저장된 값 반환
  if (goal.isManualPayment && goal.monthlyPayment != null) {
    return goal.monthlyPayment!;
  }

  final loanAmount = goal.loanAmount ?? 0;
  final annualInterestRate = goal.annualInterestRate ?? 0.0;
  final method = goal.repaymentMethod ?? RepaymentMethod.equalPrincipalInterest;

  // 개월 수: startDate ~ targetDate
  int totalMonths = 0;
  if (goal.startDate != null && goal.targetDate != null) {
    totalMonths = LoanCalculatorService.calculateMonthsBetween(
      goal.startDate!,
      goal.targetDate!,
    );
  }

  if (totalMonths <= 0 || loanAmount <= 0) return 0;

  // 현재 몇 회차인지 계산 (원금균등/체증식에서 사용)
  int currentMonth = 1;
  if (goal.startDate != null) {
    currentMonth = LoanCalculatorService.calculateMonthsBetween(
          goal.startDate!,
          DateTime.now(),
        ) +
        1;
    if (currentMonth < 1) currentMonth = 1;
    if (currentMonth > totalMonths) currentMonth = totalMonths;
  }

  return LoanCalculatorService.calculateMonthlyPayment(
    loanAmount: loanAmount,
    annualInterestRate: annualInterestRate,
    totalMonths: totalMonths,
    method: method,
    currentMonth: currentMonth,
  );
});
