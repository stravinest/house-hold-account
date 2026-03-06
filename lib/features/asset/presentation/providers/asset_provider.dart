import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../ledger/presentation/providers/ledger_provider.dart';
import '../../../statistics/domain/entities/statistics_entities.dart';
import '../../../statistics/presentation/providers/statistics_provider.dart';
import '../../data/repositories/asset_repository.dart';
import '../../data/services/loan_calculator_service.dart';
import '../../domain/entities/asset_goal.dart';
import '../../domain/entities/asset_statistics.dart';
import 'asset_goal_provider.dart';

final assetRepositoryProvider = Provider<AssetRepository>((ref) {
  return AssetRepository();
});

// 자산 차트 기간 선택 (월별/연별)
final assetChartPeriodProvider = StateProvider<TrendPeriod>(
  (ref) => TrendPeriod.monthly,
);

// 자산 유저 필터 상태 (공유 가계부용)
final assetSharedStateProvider = StateProvider<SharedStatisticsState>(
  (ref) => const SharedStatisticsState(mode: SharedStatisticsMode.combined),
);

// 유저 필터에서 userId 추출하는 헬퍼
String? _getFilterUserId(SharedStatisticsState sharedState) {
  if (sharedState.mode == SharedStatisticsMode.singleUser &&
      sharedState.selectedUserId != null) {
    return sharedState.selectedUserId;
  }
  return null;
}

final assetStatisticsProvider = FutureProvider<AssetStatistics>((ref) async {
  final ledgerId = ref.watch(selectedLedgerIdProvider);
  if (ledgerId == null) {
    return const AssetStatistics(
      totalAmount: 0,
      monthlyChange: 0,
      monthlyChangeRate: 0.0,
      annualGrowthRate: 0.0,
      monthly: [],
      byCategory: [],
    );
  }

  final repository = ref.watch(assetRepositoryProvider);

  return repository.getEnhancedStatistics(ledgerId: ledgerId);
});

// 유저 필터 반영 카테고리별 자산 데이터
final assetFilteredByCategoryProvider =
    FutureProvider<List<CategoryAsset>>((ref) async {
  final ledgerId = ref.watch(selectedLedgerIdProvider);
  if (ledgerId == null) return [];

  final repository = ref.watch(assetRepositoryProvider);
  final sharedState = ref.watch(assetSharedStateProvider);
  final userId = _getFilterUserId(sharedState);

  return repository.getAssetsByCategory(ledgerId: ledgerId, userId: userId);
});

// 월별 차트 데이터 (전체 합계 - 유저 필터 미적용)
final assetMonthlyChartProvider = FutureProvider<List<MonthlyAsset>>((ref) async {
  final ledgerId = ref.watch(selectedLedgerIdProvider);
  if (ledgerId == null) return [];

  final repository = ref.watch(assetRepositoryProvider);

  return repository.getMonthlyAssets(ledgerId: ledgerId);
});

// 연별 차트 데이터 (전체 합계 - 유저 필터 미적용)
final assetYearlyChartProvider = FutureProvider<List<YearlyAsset>>((ref) async {
  final ledgerId = ref.watch(selectedLedgerIdProvider);
  if (ledgerId == null) return [];

  final repository = ref.watch(assetRepositoryProvider);

  return repository.getYearlyAssets(ledgerId: ledgerId);
});

// 대출 상환금 포함 여부 토글 (SharedPreferences 기반)
const _includeLoanRepaymentKey = 'include_loan_repayment_in_total';

final includeLoanRepaymentProvider =
    StateNotifierProvider<IncludeLoanRepaymentNotifier, bool>((ref) {
  return IncludeLoanRepaymentNotifier();
});

class IncludeLoanRepaymentNotifier extends StateNotifier<bool> {
  IncludeLoanRepaymentNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_includeLoanRepaymentKey) ?? false;
  }

  Future<void> toggle() async {
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_includeLoanRepaymentKey, state);
  }
}

// 대출 목표 목록을 가져오는 헬퍼
List<AssetGoal> _getLoanGoalsFromRef(Ref ref) {
  final ledgerId = ref.watch(selectedLedgerIdProvider);
  if (ledgerId == null) return [];
  final goalsAsync = ref.watch(assetGoalNotifierProvider(ledgerId));
  return goalsAsync.valueOrNull
          ?.where((g) => g.goalType == GoalType.loan)
          .toList() ??
      [];
}

// 단일 대출 목표의 특정 시점까지 누적 상환금
// now: 일관된 시점 비교를 위해 외부에서 전달
int _calculateGoalRepaid(AssetGoal goal, DateTime atDate, DateTime now) {
  final startDate = goal.startDate;
  final maturityDate = goal.targetDate;
  final loanAmount = goal.loanAmount ?? 0;
  if (startDate == null || maturityDate == null || loanAmount <= 0) return 0;

  final totalMonths =
      LoanCalculatorService.calculateMonthsBetween(startDate, maturityDate);
  final elapsedMonths =
      LoanCalculatorService.calculateMonthsBetween(startDate, atDate);
  if (totalMonths <= 0 || elapsedMonths <= 0) return 0;

  final repaid = LoanCalculatorService.calculateCumulativeRepaid(
    loanAmount: loanAmount,
    annualInterestRate: goal.annualInterestRate ?? 0.0,
    totalMonths: totalMonths,
    elapsedMonths: elapsedMonths,
    method: goal.repaymentMethod ?? RepaymentMethod.equalPrincipalInterest,
  );

  // extraRepaidAmount는 현재 시점 이전 월에만 반영
  final isCurrentOrPast =
      !atDate.isAfter(DateTime(now.year, now.month + 1, 0));
  return repaid + (isCurrentOrPast ? goal.extraRepaidAmount : 0);
}

// 특정 월까지의 모든 대출 목표 누적 상환금 합계 (차트용)
int _calculateCumulativeRepaidAtMonth(
    List<AssetGoal> loanGoals, int year, int month, DateTime now) {
  final targetDate = DateTime(year, month + 1, 0); // 해당 월 마지막 날
  int total = 0;
  for (final goal in loanGoals) {
    total += _calculateGoalRepaid(goal, targetDate, now);
  }
  return total;
}

// 월별 차트 데이터 (대출 상환금 포함)
final assetMonthlyChartWithLoanProvider =
    FutureProvider<List<MonthlyAsset>>((ref) async {
  final monthly = await ref.watch(assetMonthlyChartProvider.future);
  final includeLoan = ref.watch(includeLoanRepaymentProvider);
  if (!includeLoan) return monthly;

  final loanGoals = _getLoanGoalsFromRef(ref);
  if (loanGoals.isEmpty) return monthly;

  final now = DateTime.now();
  return monthly.map((m) {
    final loanRepaid =
        _calculateCumulativeRepaidAtMonth(loanGoals, m.year, m.month, now);
    return MonthlyAsset(
        year: m.year, month: m.month, amount: m.amount + loanRepaid);
  }).toList();
});

// 연별 차트 데이터 (대출 상환금 포함)
final assetYearlyChartWithLoanProvider =
    FutureProvider<List<YearlyAsset>>((ref) async {
  final yearly = await ref.watch(assetYearlyChartProvider.future);
  final includeLoan = ref.watch(includeLoanRepaymentProvider);
  if (!includeLoan) return yearly;

  final loanGoals = _getLoanGoalsFromRef(ref);
  if (loanGoals.isEmpty) return yearly;

  final now = DateTime.now();
  return yearly.map((y) {
    final loanRepaid =
        _calculateCumulativeRepaidAtMonth(loanGoals, y.year, 12, now);
    return YearlyAsset(year: y.year, amount: y.amount + loanRepaid);
  }).toList();
});

// 카테고리별 분포 (대출 상환금 포함)
final assetFilteredByCategoryWithLoanProvider =
    FutureProvider<List<CategoryAsset>>((ref) async {
  final categories = await ref.watch(assetFilteredByCategoryProvider.future);
  final includeLoan = ref.watch(includeLoanRepaymentProvider);
  if (!includeLoan) return categories;

  final loanGoals = _getLoanGoalsFromRef(ref);
  if (loanGoals.isEmpty) return categories;

  final now = DateTime.now();
  final loanCategories = <CategoryAsset>[];
  for (final goal in loanGoals) {
    final repaid = _calculateGoalRepaid(goal, now, now);
    if (repaid <= 0) continue;
    loanCategories.add(CategoryAsset(
      categoryId: 'loan_${goal.id}',
      categoryName: goal.title,
      categoryIcon: 'account_balance',
      categoryColor: null,
      amount: repaid,
      items: const [],
    ));
  }

  return [...categories, ...loanCategories]
    ..sort((a, b) => b.amount.compareTo(a.amount));
});

// 모든 대출 목표의 누적 상환원금 합계 (추가상환 포함, 유저 필터 미적용)
final totalLoanRepaidAmountProvider = Provider<int>((ref) {
  final ledgerId = ref.watch(selectedLedgerIdProvider);
  if (ledgerId == null) return 0;

  final goalsAsync = ref.watch(assetGoalNotifierProvider(ledgerId));
  return goalsAsync.when(
    data: (goals) {
      final loanGoals = goals.where((g) => g.goalType == GoalType.loan);
      final now = DateTime.now();
      int totalRepaid = 0;
      for (final goal in loanGoals) {
        totalRepaid += _calculateGoalRepaid(goal, now, now);
      }
      return totalRepaid;
    },
    loading: () => 0,
    error: (e, st) => 0,
  );
});
