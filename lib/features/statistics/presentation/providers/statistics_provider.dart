import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ledger/presentation/providers/ledger_provider.dart';
import '../../data/repositories/statistics_repository.dart';
import '../../domain/entities/statistics_entities.dart';

// Repository Provider
final statisticsRepositoryProvider = Provider<StatisticsRepository>((ref) {
  return StatisticsRepository();
});

// 탭 인덱스 관리
final statisticsTabIndexProvider = StateProvider<int>((ref) => 0);

// 통계 페이지 전용 선택 날짜 Provider (캘린더와 분리하여 독립적인 상태 관리)
final statisticsSelectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

// 선택된 통계 타입 (지출/수입/저축)
final selectedStatisticsTypeProvider = StateProvider<String>((ref) => 'expense');

// 추이 탭 기간 필터 (월별/연별)
final trendPeriodProvider = StateProvider<TrendPeriod>((ref) => TrendPeriod.monthly);

// 카테고리별 지출 통계
final categoryExpenseStatisticsProvider =
    FutureProvider<List<CategoryStatistics>>((ref) async {
  final ledgerId = ref.watch(selectedLedgerIdProvider);
  if (ledgerId == null) return [];

  final date = ref.watch(statisticsSelectedDateProvider);
  final repository = ref.watch(statisticsRepositoryProvider);

  return repository.getCategoryStatistics(
    ledgerId: ledgerId,
    year: date.year,
    month: date.month,
    type: 'expense',
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

// 카테고리별 저축 통계
final categorySavingStatisticsProvider =
    FutureProvider<List<CategoryStatistics>>((ref) async {
  final ledgerId = ref.watch(selectedLedgerIdProvider);
  if (ledgerId == null) return [];

  final date = ref.watch(statisticsSelectedDateProvider);
  final repository = ref.watch(statisticsRepositoryProvider);

  return repository.getCategoryStatistics(
    ledgerId: ledgerId,
    year: date.year,
    month: date.month,
    type: 'saving',
  );
});

// 현재 선택된 타입의 카테고리 통계
final categoryStatisticsProvider =
    FutureProvider<List<CategoryStatistics>>((ref) async {
  final type = ref.watch(selectedStatisticsTypeProvider);

  if (type == 'income') {
    return ref.watch(categoryIncomeStatisticsProvider.future);
  } else if (type == 'saving') {
    return ref.watch(categorySavingStatisticsProvider.future);
  } else {
    return ref.watch(categoryExpenseStatisticsProvider.future);
  }
});

// 총 지출/수입 계산
final totalStatisticsProvider = Provider<Map<String, int>>((ref) {
  final expenseAsync = ref.watch(categoryExpenseStatisticsProvider);
  final incomeAsync = ref.watch(categoryIncomeStatisticsProvider);

  int totalExpense = 0;
  int totalIncome = 0;

  expenseAsync.whenData((data) {
    totalExpense = data.fold(0, (sum, item) => sum + item.amount);
  });

  incomeAsync.whenData((data) {
    totalIncome = data.fold(0, (sum, item) => sum + item.amount);
  });

  return {
    'expense': totalExpense,
    'income': totalIncome,
    'balance': totalIncome - totalExpense,
  };
});

// 월 비교 데이터 (전월 대비)
final monthComparisonProvider =
    FutureProvider<MonthComparisonData>((ref) async {
  final ledgerId = ref.watch(selectedLedgerIdProvider);
  if (ledgerId == null) return MonthComparisonData.empty();

  final date = ref.watch(statisticsSelectedDateProvider);
  final type = ref.watch(selectedStatisticsTypeProvider);
  final repository = ref.watch(statisticsRepositoryProvider);

  return repository.getMonthComparison(
    ledgerId: ledgerId,
    year: date.year,
    month: date.month,
    type: type,
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
final monthlyTrendWithAverageProvider =
    FutureProvider<TrendStatisticsData>((ref) async {
  final ledgerId = ref.watch(selectedLedgerIdProvider);
  if (ledgerId == null) {
    return const TrendStatisticsData(
      data: [],
      averageIncome: 0,
      averageExpense: 0,
      averageSaving: 0,
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
final yearlyTrendWithAverageProvider =
    FutureProvider<TrendStatisticsData>((ref) async {
  final ledgerId = ref.watch(selectedLedgerIdProvider);
  if (ledgerId == null) {
    return const TrendStatisticsData(
      data: [],
      averageIncome: 0,
      averageExpense: 0,
      averageSaving: 0,
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
final yearlyTrendProvider =
    FutureProvider<List<YearlyStatistics>>((ref) async {
  final ledgerId = ref.watch(selectedLedgerIdProvider);
  if (ledgerId == null) return [];

  final repository = ref.watch(statisticsRepositoryProvider);

  return repository.getYearlyTrend(
    ledgerId: ledgerId,
    years: 3,
  );
});

// 기존 월별 추이 (하위 호환성 유지)
final monthlyTrendProvider =
    FutureProvider<List<MonthlyStatistics>>((ref) async {
  final ledgerId = ref.watch(selectedLedgerIdProvider);
  if (ledgerId == null) return [];

  final repository = ref.watch(statisticsRepositoryProvider);

  return repository.getMonthlyTrend(
    ledgerId: ledgerId,
    months: 6,
  );
});
