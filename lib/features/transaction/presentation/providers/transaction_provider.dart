import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ledger/presentation/providers/ledger_provider.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../domain/entities/transaction.dart';

// Repository 프로바이더
final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository();
});

// 선택된 날짜
final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

// 선택된 날짜의 거래 목록
final dailyTransactionsProvider =
    FutureProvider<List<Transaction>>((ref) async {
  final ledgerId = ref.watch(selectedLedgerIdProvider);
  if (ledgerId == null) return [];

  final date = ref.watch(selectedDateProvider);
  final repository = ref.watch(transactionRepositoryProvider);

  return repository.getTransactionsByDate(ledgerId: ledgerId, date: date);
});

// 현재 월의 거래 목록
final monthlyTransactionsProvider =
    FutureProvider<List<Transaction>>((ref) async {
  final ledgerId = ref.watch(selectedLedgerIdProvider);
  if (ledgerId == null) return [];

  final date = ref.watch(selectedDateProvider);
  final repository = ref.watch(transactionRepositoryProvider);

  return repository.getTransactionsByMonth(
    ledgerId: ledgerId,
    year: date.year,
    month: date.month,
  );
});

// 현재 월 합계 (사용자별 데이터 포함)
final monthlyTotalProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final ledgerId = ref.watch(selectedLedgerIdProvider);
  if (ledgerId == null) return {'income': 0, 'expense': 0, 'balance': 0, 'users': {}};

  final date = ref.watch(selectedDateProvider);
  final repository = ref.watch(transactionRepositoryProvider);

  return repository.getMonthlyTotal(
    ledgerId: ledgerId,
    year: date.year,
    month: date.month,
  );
});

// 일별 합계 (캘린더용, 사용자별 데이터 포함)
final dailyTotalsProvider =
    FutureProvider<Map<DateTime, Map<String, dynamic>>>((ref) async {
  final ledgerId = ref.watch(selectedLedgerIdProvider);
  if (ledgerId == null) return {};

  final date = ref.watch(selectedDateProvider);
  final repository = ref.watch(transactionRepositoryProvider);

  return repository.getDailyTotals(
    ledgerId: ledgerId,
    year: date.year,
    month: date.month,
  );
});

// 거래 관리 노티파이어
class TransactionNotifier extends StateNotifier<AsyncValue<List<Transaction>>> {
  final TransactionRepository _repository;
  final String? _ledgerId;
  final Ref _ref;

  TransactionNotifier(this._repository, this._ledgerId, this._ref)
      : super(const AsyncValue.loading()) {
    if (_ledgerId != null) {
      loadTransactions();
    } else {
      state = const AsyncValue.data([]);
    }
  }

  Future<void> loadTransactions() async {
    if (_ledgerId == null) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();
    try {
      final date = _ref.read(selectedDateProvider);
      final transactions = await _repository.getTransactionsByDate(
        ledgerId: _ledgerId,
        date: date,
      );
      state = AsyncValue.data(transactions);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Transaction> createTransaction({
    String? categoryId,
    String? paymentMethodId,
    required int amount,
    required String type,
    required DateTime date,
    String? memo,
    String? imageUrl,
    bool isRecurring = false,
    String? recurringType,
    DateTime? recurringEndDate,
  }) async {
    if (_ledgerId == null) throw Exception('가계부를 선택해주세요');

    final transaction = await _repository.createTransaction(
      ledgerId: _ledgerId,
      categoryId: categoryId,
      paymentMethodId: paymentMethodId,
      amount: amount,
      type: type,
      date: date,
      memo: memo,
      imageUrl: imageUrl,
      isRecurring: isRecurring,
      recurringType: recurringType,
      recurringEndDate: recurringEndDate,
    );

    // 데이터 갱신
    _ref.invalidate(dailyTransactionsProvider);
    _ref.invalidate(monthlyTransactionsProvider);
    _ref.invalidate(monthlyTotalProvider);
    _ref.invalidate(dailyTotalsProvider);

    return transaction;
  }

  Future<void> updateTransaction({
    required String id,
    String? categoryId,
    String? paymentMethodId,
    int? amount,
    String? type,
    DateTime? date,
    String? memo,
    String? imageUrl,
    bool? isRecurring,
    String? recurringType,
    DateTime? recurringEndDate,
  }) async {
    await _repository.updateTransaction(
      id: id,
      categoryId: categoryId,
      paymentMethodId: paymentMethodId,
      amount: amount,
      type: type,
      date: date,
      memo: memo,
      imageUrl: imageUrl,
      isRecurring: isRecurring,
      recurringType: recurringType,
      recurringEndDate: recurringEndDate,
    );

    // 데이터 갱신
    _ref.invalidate(dailyTransactionsProvider);
    _ref.invalidate(monthlyTransactionsProvider);
    _ref.invalidate(monthlyTotalProvider);
    _ref.invalidate(dailyTotalsProvider);
  }

  Future<void> deleteTransaction(String id) async {
    await _repository.deleteTransaction(id);

    // 데이터 갱신
    _ref.invalidate(dailyTransactionsProvider);
    _ref.invalidate(monthlyTransactionsProvider);
    _ref.invalidate(monthlyTotalProvider);
    _ref.invalidate(dailyTotalsProvider);
  }
}

final transactionNotifierProvider =
    StateNotifierProvider<TransactionNotifier, AsyncValue<List<Transaction>>>(
        (ref) {
  final repository = ref.watch(transactionRepositoryProvider);
  final ledgerId = ref.watch(selectedLedgerIdProvider);
  return TransactionNotifier(repository, ledgerId, ref);
});
