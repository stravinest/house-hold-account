import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../fixed_expense/presentation/providers/fixed_expense_settings_provider.dart';
import '../../../ledger/presentation/providers/ledger_provider.dart';
import '../../../share/presentation/providers/share_provider.dart';
import '../../data/repositories/statistics_repository.dart';
import '../../domain/entities/statistics_entities.dart';
import '../widgets/common/expense_type_filter.dart';

// 공유 통계 필터 모드
enum SharedStatisticsMode {
  combined, // 합쳐서 (모든 사용자 합계)
  overlay, // 겹쳐서 (사용자별 비교)
  singleUser, // 특정 사용자만
}

// 공유 통계 상태 클래스
class SharedStatisticsState {
  final SharedStatisticsMode mode;
  final String? selectedUserId; // singleUser 모드일 때 선택된 사용자 ID

  const SharedStatisticsState({
    this.mode = SharedStatisticsMode.overlay,
    this.selectedUserId,
  });

  SharedStatisticsState copyWith({
    SharedStatisticsMode? mode,
    String? selectedUserId,
  }) {
    return SharedStatisticsState(
      mode: mode ?? this.mode,
      selectedUserId: selectedUserId,
    );
  }
}

// 공유 통계 필터 상태 Provider
final sharedStatisticsStateProvider = StateProvider<SharedStatisticsState>((
  ref,
) {
  return const SharedStatisticsState();
});

// Repository Provider
final statisticsRepositoryProvider = Provider<StatisticsRepository>((ref) {
  return StatisticsRepository();
});

// 탭 인덱스 관리
final statisticsTabIndexProvider = StateProvider<int>((ref) => 0);

// 통계 페이지 전용 선택 날짜 Provider (캘린더와 분리하여 독립적인 상태 관리)
final statisticsSelectedDateProvider = StateProvider<DateTime>(
  (ref) => DateTime.now(),
);

// 선택된 통계 타입 (지출/수입/자산)
final selectedStatisticsTypeProvider = StateProvider<String>(
  (ref) => 'expense',
);

// 지출 타입 필터 (전체/고정비/변동비) - 지출 선택 시에만 활성화
final selectedExpenseTypeFilterProvider = StateProvider<ExpenseTypeFilter>(
  (ref) => ExpenseTypeFilter.all,
);

// 추이 탭 기간 필터 (월별/연별)
final trendPeriodProvider = StateProvider<TrendPeriod>(
  (ref) => TrendPeriod.monthly,
);

// 카테고리별 지출 통계
final categoryExpenseStatisticsProvider =
    FutureProvider<List<CategoryStatistics>>((ref) async {
      final ledgerId = ref.watch(selectedLedgerIdProvider);
      if (ledgerId == null) return [];

      final date = ref.watch(statisticsSelectedDateProvider);
      final repository = ref.watch(statisticsRepositoryProvider);
      final expenseTypeFilter = ref.watch(selectedExpenseTypeFilterProvider);

      // 고정비 설정 가져오기
      final includeFixedExpenseInExpense = await ref.watch(
        includeFixedExpenseInExpenseProvider.future,
      );

      return repository.getCategoryStatistics(
        ledgerId: ledgerId,
        year: date.year,
        month: date.month,
        type: 'expense',
        expenseTypeFilter: expenseTypeFilter,
        includeFixedExpenseInExpense: includeFixedExpenseInExpense,
      );
    });

// 카테고리별 수입 통계
final categoryIncomeStatisticsProvider =
    FutureProvider<List<CategoryStatistics>>((ref) async {
      final ledgerId = ref.watch(selectedLedgerIdProvider);
      if (ledgerId == null) return [];

      final date = ref.watch(statisticsSelectedDateProvider);
      final repository = ref.watch(statisticsRepositoryProvider);

      return repository.getCategoryStatistics(
        ledgerId: ledgerId,
        year: date.year,
        month: date.month,
        type: 'income',
      );
    });

// 카테고리별 자산 통계
final categoryAssetStatisticsProvider =
    FutureProvider<List<CategoryStatistics>>((ref) async {
      final ledgerId = ref.watch(selectedLedgerIdProvider);
      if (ledgerId == null) return [];

      final date = ref.watch(statisticsSelectedDateProvider);
      final repository = ref.watch(statisticsRepositoryProvider);

      return repository.getCategoryStatistics(
        ledgerId: ledgerId,
        year: date.year,
        month: date.month,
        type: 'asset',
      );
    });

// 현재 선택된 타입의 카테고리 통계
final categoryStatisticsProvider = FutureProvider<List<CategoryStatistics>>((
  ref,
) async {
  final type = ref.watch(selectedStatisticsTypeProvider);

  if (type == 'income') {
    return ref.watch(categoryIncomeStatisticsProvider.future);
  } else if (type == 'asset') {
    return ref.watch(categoryAssetStatisticsProvider.future);
  } else {
    return ref.watch(categoryExpenseStatisticsProvider.future);
  }
});

// 총 지출/수입 계산
final totalStatisticsProvider = Provider<Map<String, int>>((ref) {
  final expenseData = ref.watch(categoryExpenseStatisticsProvider).valueOrNull;
  final incomeData = ref.watch(categoryIncomeStatisticsProvider).valueOrNull;

  final totalExpense =
      expenseData?.fold(0, (sum, item) => sum + item.amount) ?? 0;
  final totalIncome =
      incomeData?.fold(0, (sum, item) => sum + item.amount) ?? 0;

  return {
    'expense': totalExpense,
    'income': totalIncome,
    'balance': totalIncome - totalExpense,
  };
});

// 월 비교 데이터 (전월 대비)
final monthComparisonProvider = FutureProvider<MonthComparisonData>((
  ref,
) async {
  final ledgerId = ref.watch(selectedLedgerIdProvider);
  if (ledgerId == null) return MonthComparisonData.empty();

  final date = ref.watch(statisticsSelectedDateProvider);
  final type = ref.watch(selectedStatisticsTypeProvider);
  final repository = ref.watch(statisticsRepositoryProvider);

  // 지출일 경우에만 고정비/변동비 필터 적용
  ExpenseTypeFilter? expenseTypeFilter;
  if (type == 'expense') {
    expenseTypeFilter = ref.watch(selectedExpenseTypeFilterProvider);
  }

  return repository.getMonthComparison(
    ledgerId: ledgerId,
    year: date.year,
    month: date.month,
    type: type,
    expenseTypeFilter: expenseTypeFilter,
  );
});

// 결제수단별 통계
final paymentMethodStatisticsProvider =
    FutureProvider<List<PaymentMethodStatistics>>((ref) async {
      final ledgerId = ref.watch(selectedLedgerIdProvider);
      if (ledgerId == null) return [];

      final date = ref.watch(statisticsSelectedDateProvider);
      final repository = ref.watch(statisticsRepositoryProvider);

      // 결제수단 탭에서는 항상 지출만 표시
      return repository.getPaymentMethodStatistics(
        ledgerId: ledgerId,
        year: date.year,
        month: date.month,
        type: 'expense',
      );
    });

// 월별 추이 (평균값 포함)
final monthlyTrendWithAverageProvider = FutureProvider<TrendStatisticsData>((
  ref,
) async {
  final ledgerId = ref.watch(selectedLedgerIdProvider);
  if (ledgerId == null) {
    return const TrendStatisticsData(
      data: [],
      averageIncome: 0,
      averageExpense: 0,
      averageAsset: 0,
    );
  }

  final date = ref.watch(statisticsSelectedDateProvider);
  final repository = ref.watch(statisticsRepositoryProvider);

  return repository.getMonthlyTrendWithAverage(
    ledgerId: ledgerId,
    baseDate: date,
    months: 6,
  );
});

// 연별 추이 (평균값 포함, 선택된 날짜 기준)
final yearlyTrendWithAverageProvider = FutureProvider<TrendStatisticsData>((
  ref,
) async {
  final ledgerId = ref.watch(selectedLedgerIdProvider);
  if (ledgerId == null) {
    return const TrendStatisticsData(
      data: [],
      averageIncome: 0,
      averageExpense: 0,
      averageAsset: 0,
    );
  }

  final date = ref.watch(statisticsSelectedDateProvider);
  final repository = ref.watch(statisticsRepositoryProvider);

  return repository.getYearlyTrendWithAverage(
    ledgerId: ledgerId,
    baseDate: date,
    years: 6,
  );
});

// 연별 추이 (하위 호환성 유지)
final yearlyTrendProvider = FutureProvider<List<YearlyStatistics>>((ref) async {
  final ledgerId = ref.watch(selectedLedgerIdProvider);
  if (ledgerId == null) return [];

  final repository = ref.watch(statisticsRepositoryProvider);

  return repository.getYearlyTrend(ledgerId: ledgerId, years: 3);
});

// 기존 월별 추이 (하위 호환성 유지)
final monthlyTrendProvider = FutureProvider<List<MonthlyStatistics>>((
  ref,
) async {
  final ledgerId = ref.watch(selectedLedgerIdProvider);
  if (ledgerId == null) return [];

  final repository = ref.watch(statisticsRepositoryProvider);

  return repository.getMonthlyTrend(ledgerId: ledgerId, months: 6);
});

// ========== 공유 가계부용 Provider ==========

// 사용자별 카테고리 통계 (공유 가계부용)
final categoryStatisticsByUserProvider =
    FutureProvider<Map<String, UserCategoryStatistics>>((ref) async {
      final ledgerId = ref.watch(selectedLedgerIdProvider);
      if (ledgerId == null) return {};

      final date = ref.watch(statisticsSelectedDateProvider);
      final type = ref.watch(selectedStatisticsTypeProvider);
      final repository = ref.watch(statisticsRepositoryProvider);

      // 지출일 경우에만 고정비/변동비 필터 적용
      ExpenseTypeFilter? expenseTypeFilter;
      if (type == 'expense') {
        expenseTypeFilter = ref.watch(selectedExpenseTypeFilterProvider);
      }

      return repository.getCategoryStatisticsByUser(
        ledgerId: ledgerId,
        year: date.year,
        month: date.month,
        type: type,
        expenseTypeFilter: expenseTypeFilter,
      );
    });

// 공유 가계부 여부 확인
final isSharedLedgerProvider = Provider<bool>((ref) {
  final ledgerAsync = ref.watch(currentLedgerProvider);
  final ledger = ledgerAsync.valueOrNull;
  final memberCount = ref.watch(currentLedgerMemberCountProvider);
  return ledger?.isShared == true && memberCount >= 2;
});

// 총액 (모든 사용자 합계)
final sharedTotalAmountProvider = Provider<int>((ref) {
  final userStats = ref.watch(categoryStatisticsByUserProvider).valueOrNull;
  if (userStats == null || userStats.isEmpty) return 0;

  return userStats.values.fold(0, (sum, user) => sum + user.totalAmount);
});
