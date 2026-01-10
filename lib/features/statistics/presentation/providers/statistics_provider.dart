import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ledger/presentation/providers/ledger_provider.dart';
import '../../../transaction/presentation/providers/transaction_provider.dart';
import '../../data/repositories/statistics_repository.dart';

// Repository 프로바이더
final statisticsRepositoryProvider = Provider<StatisticsRepository>((ref) {
  return StatisticsRepository();
});

// 통계 기간 타입
enum StatisticsPeriod { weekly, monthly, yearly }

// 선택된 통계 타입 (지출/수입)
final selectedStatisticsTypeProvider = StateProvider<String>((ref) => 'expense');

// 카테고리별 지출 통계
final categoryExpenseStatisticsProvider =
    FutureProvider<List<CategoryStatistics>>((ref) async {
  final ledgerId = ref.watch(selectedLedgerIdProvider);
  if (ledgerId == null) return [];

  final date = ref.watch(selectedDateProvider);
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

  final date = ref.watch(selectedDateProvider);
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

  final date = ref.watch(selectedDateProvider);
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

// 월별 추세 (최근 6개월)
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

// 일별 추세 (현재 월)
final dailyTrendProvider = FutureProvider<List<DailyStatistics>>((ref) async {
  final ledgerId = ref.watch(selectedLedgerIdProvider);
  if (ledgerId == null) return [];

  final date = ref.watch(selectedDateProvider);
  final repository = ref.watch(statisticsRepositoryProvider);

  return repository.getDailyTrend(
    ledgerId: ledgerId,
    year: date.year,
    month: date.month,
  );
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
