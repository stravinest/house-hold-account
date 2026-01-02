import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ledger/presentation/providers/ledger_provider.dart';
import '../../../transaction/presentation/providers/transaction_provider.dart';
import '../../data/repositories/budget_repository.dart';
import '../../domain/entities/budget.dart';

// Repository 프로바이더
final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return BudgetRepository();
});

// 현재 월 예산 목록
final budgetsProvider = FutureProvider<List<Budget>>((ref) async {
  final ledgerId = ref.watch(selectedLedgerIdProvider);
  if (ledgerId == null) return [];

  final date = ref.watch(selectedDateProvider);
  final repository = ref.watch(budgetRepositoryProvider);

  return repository.getBudgets(
    ledgerId: ledgerId,
    year: date.year,
    month: date.month,
  );
});

// 예산 대비 지출 현황
final budgetSpentProvider = FutureProvider<Map<String, int>>((ref) async {
  final ledgerId = ref.watch(selectedLedgerIdProvider);
  if (ledgerId == null) return {'total': 0};

  final date = ref.watch(selectedDateProvider);
  final repository = ref.watch(budgetRepositoryProvider);

  return repository.getBudgetSpent(
    ledgerId: ledgerId,
    year: date.year,
    month: date.month,
  );
});

// 총 예산
final totalBudgetProvider = FutureProvider<Budget?>((ref) async {
  final ledgerId = ref.watch(selectedLedgerIdProvider);
  if (ledgerId == null) return null;

  final date = ref.watch(selectedDateProvider);
  final repository = ref.watch(budgetRepositoryProvider);

  return repository.getTotalBudget(
    ledgerId: ledgerId,
    year: date.year,
    month: date.month,
  );
});

// 예산 요약 정보
final budgetSummaryProvider = Provider<BudgetSummary>((ref) {
  final budgetsAsync = ref.watch(budgetsProvider);
  final spentAsync = ref.watch(budgetSpentProvider);

  int totalBudget = 0;
  int totalSpent = 0;

  budgetsAsync.whenData((budgets) {
    for (final budget in budgets) {
      if (budget.isTotalBudget) {
        totalBudget = budget.amount;
      }
    }
  });

  spentAsync.whenData((spent) {
    totalSpent = spent['total'] ?? 0;
  });

  return BudgetSummary(
    totalBudget: totalBudget,
    totalSpent: totalSpent,
  );
});

// 예산 관리 노티파이어
class BudgetNotifier extends StateNotifier<AsyncValue<List<Budget>>> {
  final BudgetRepository _repository;
  final String? _ledgerId;
  final Ref _ref;

  BudgetNotifier(this._repository, this._ledgerId, this._ref)
      : super(const AsyncValue.loading()) {
    if (_ledgerId != null) {
      loadBudgets();
    } else {
      state = const AsyncValue.data([]);
    }
  }

  Future<void> loadBudgets() async {
    if (_ledgerId == null) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();
    try {
      final date = _ref.read(selectedDateProvider);
      final budgets = await _repository.getBudgets(
        ledgerId: _ledgerId,
        year: date.year,
        month: date.month,
      );
      state = AsyncValue.data(budgets);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Budget> createBudget({
    String? categoryId,
    required int amount,
  }) async {
    if (_ledgerId == null) throw Exception('가계부를 선택해주세요');

    final date = _ref.read(selectedDateProvider);
    final budget = await _repository.createBudget(
      ledgerId: _ledgerId,
      categoryId: categoryId,
      amount: amount,
      year: date.year,
      month: date.month,
    );

    _ref.invalidate(budgetsProvider);
    _ref.invalidate(totalBudgetProvider);

    return budget;
  }

  Future<void> updateBudget({
    required String id,
    int? amount,
  }) async {
    await _repository.updateBudget(id: id, amount: amount);

    _ref.invalidate(budgetsProvider);
    _ref.invalidate(totalBudgetProvider);
  }

  Future<void> deleteBudget(String id) async {
    await _repository.deleteBudget(id);

    _ref.invalidate(budgetsProvider);
    _ref.invalidate(totalBudgetProvider);
  }

  Future<void> copyFromPreviousMonth() async {
    if (_ledgerId == null) throw Exception('가계부를 선택해주세요');

    final date = _ref.read(selectedDateProvider);
    await _repository.copyBudgetFromPreviousMonth(
      ledgerId: _ledgerId,
      year: date.year,
      month: date.month,
    );

    _ref.invalidate(budgetsProvider);
    _ref.invalidate(totalBudgetProvider);
  }
}

final budgetNotifierProvider =
    StateNotifierProvider<BudgetNotifier, AsyncValue<List<Budget>>>((ref) {
  final repository = ref.watch(budgetRepositoryProvider);
  final ledgerId = ref.watch(selectedLedgerIdProvider);
  return BudgetNotifier(repository, ledgerId, ref);
});

// 예산 요약 모델
class BudgetSummary {
  final int totalBudget;
  final int totalSpent;

  const BudgetSummary({
    required this.totalBudget,
    required this.totalSpent,
  });

  int get remaining => totalBudget - totalSpent;

  double get progressRate {
    if (totalBudget == 0) return 0;
    return (totalSpent / totalBudget).clamp(0.0, 2.0);
  }

  bool get isOverBudget => totalSpent > totalBudget;
}
