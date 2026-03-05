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

// 모든 대출 목표의 누적 상환원금 합계 (추가상환 포함, 유저 필터 미적용)
final totalLoanRepaidAmountProvider = Provider<int>((ref) {
  final ledgerId = ref.watch(selectedLedgerIdProvider);
  if (ledgerId == null) return 0;

  final goalsAsync = ref.watch(assetGoalNotifierProvider(ledgerId));
  return goalsAsync.when(
    data: (goals) {
      final loanGoals = goals.where((g) => g.goalType == GoalType.loan);
      int totalRepaid = 0;

      for (final goal in loanGoals) {
        final loanAmount = goal.loanAmount ?? 0;
        final rate = goal.annualInterestRate ?? 0.0;
        final method =
            goal.repaymentMethod ?? RepaymentMethod.equalPrincipalInterest;
        final startDate = goal.startDate;
        final targetDate = goal.targetDate;

        if (startDate == null || targetDate == null || loanAmount <= 0) continue;

        final now = DateTime.now();
        final totalMonths =
            LoanCalculatorService.calculateMonthsBetween(startDate, targetDate);
        final elapsedMonths =
            LoanCalculatorService.calculateMonthsBetween(startDate, now);

        if (totalMonths <= 0 || elapsedMonths <= 0) continue;

        final cumulativeRepaid = LoanCalculatorService.calculateCumulativeRepaid(
          loanAmount: loanAmount,
          annualInterestRate: rate,
          totalMonths: totalMonths,
          elapsedMonths: elapsedMonths,
          method: method,
        );

        totalRepaid += cumulativeRepaid + goal.extraRepaidAmount;
      }

      return totalRepaid;
    },
    loading: () => 0,
    error: (e, st) => 0,
  );
});
