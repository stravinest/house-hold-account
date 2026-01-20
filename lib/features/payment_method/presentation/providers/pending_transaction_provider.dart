import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ledger/presentation/providers/ledger_provider.dart';
import '../../../transaction/data/repositories/transaction_repository.dart';
import '../../data/models/pending_transaction_model.dart';
import '../../data/repositories/pending_transaction_repository.dart';
import '../../domain/entities/pending_transaction.dart';

final pendingTransactionRepositoryProvider =
    Provider<PendingTransactionRepository>((ref) {
      return PendingTransactionRepository();
    });

final pendingTransactionsProvider =
    FutureProvider<List<PendingTransactionModel>>((ref) async {
      final ledgerId = ref.watch(selectedLedgerIdProvider);
      if (ledgerId == null) return [];

      final repository = ref.watch(pendingTransactionRepositoryProvider);
      return repository.getPendingTransactions(
        ledgerId,
        status: PendingTransactionStatus.pending,
      );
    });

final pendingTransactionCountProvider = FutureProvider<int>((ref) async {
  final ledgerId = ref.watch(selectedLedgerIdProvider);
  if (ledgerId == null) return 0;

  final repository = ref.watch(pendingTransactionRepositoryProvider);
  return repository.getPendingCount(ledgerId);
});

class PendingTransactionNotifier
    extends StateNotifier<AsyncValue<List<PendingTransactionModel>>> {
  final PendingTransactionRepository _repository;
  final TransactionRepository _transactionRepository;
  final String? _ledgerId;
  final Ref _ref;

  PendingTransactionNotifier(
    this._repository,
    this._transactionRepository,
    this._ledgerId,
    this._ref,
  ) : super(const AsyncValue.loading()) {
    if (_ledgerId != null) {
      loadPendingTransactions();
    } else {
      state = const AsyncValue.data([]);
    }
  }

  Future<void> loadPendingTransactions({
    PendingTransactionStatus? status,
  }) async {
    if (_ledgerId == null) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();
    try {
      final transactions = await _repository.getPendingTransactions(
        _ledgerId,
        status: status,
      );
      state = AsyncValue.data(transactions);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> confirmTransaction(String id) async {
    try {
      final currentList = state.valueOrNull ?? [];
      final pendingTx = currentList.firstWhere((tx) => tx.id == id);

      if (pendingTx.parsedAmount == null || pendingTx.parsedType == null) {
        throw Exception('파싱된 금액 또는 타입이 없습니다');
      }

      await _transactionRepository.createTransaction(
        ledgerId: _ledgerId!,
        categoryId: pendingTx.parsedCategoryId,
        paymentMethodId: pendingTx.paymentMethodId,
        amount: pendingTx.parsedAmount!,
        type: pendingTx.parsedType!,
        title: pendingTx.parsedMerchant ?? '',
        date: pendingTx.parsedDate ?? DateTime.now(),
        sourceType: pendingTx.sourceType.toJson(),
      );

      await _repository.updateStatus(
        id: id,
        status: PendingTransactionStatus.converted,
      );

      _ref.invalidate(pendingTransactionsProvider);
      _ref.invalidate(pendingTransactionCountProvider);
      await loadPendingTransactions();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> rejectTransaction(String id) async {
    try {
      await _repository.updateStatus(
        id: id,
        status: PendingTransactionStatus.rejected,
      );

      _ref.invalidate(pendingTransactionsProvider);
      _ref.invalidate(pendingTransactionCountProvider);
      await loadPendingTransactions();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateParsedData({
    required String id,
    int? parsedAmount,
    String? parsedType,
    String? parsedMerchant,
    String? parsedCategoryId,
    DateTime? parsedDate,
    String? paymentMethodId,
  }) async {
    try {
      await _repository.updateParsedData(
        id: id,
        parsedAmount: parsedAmount,
        parsedType: parsedType,
        parsedMerchant: parsedMerchant,
        parsedCategoryId: parsedCategoryId,
        parsedDate: parsedDate,
        paymentMethodId: paymentMethodId,
      );

      await loadPendingTransactions();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> confirmAll() async {
    if (_ledgerId == null) return;

    try {
      final confirmed = await _repository.confirmAll(_ledgerId);

      for (final tx in confirmed) {
        if (tx.parsedAmount != null && tx.parsedType != null) {
          try {
            await _transactionRepository.createTransaction(
              ledgerId: _ledgerId,
              categoryId: tx.parsedCategoryId,
              paymentMethodId: tx.paymentMethodId,
              amount: tx.parsedAmount!,
              type: tx.parsedType!,
              title: tx.parsedMerchant ?? '',
              date: tx.parsedDate ?? DateTime.now(),
              sourceType: tx.sourceType.toJson(),
            );

            await _repository.updateStatus(
              id: tx.id,
              status: PendingTransactionStatus.converted,
            );
          } catch (e) {
            debugPrint('Failed to convert transaction ${tx.id}: $e');
          }
        }
      }

      _ref.invalidate(pendingTransactionsProvider);
      _ref.invalidate(pendingTransactionCountProvider);
      await loadPendingTransactions();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> rejectAll() async {
    if (_ledgerId == null) return;

    try {
      await _repository.rejectAll(_ledgerId);

      _ref.invalidate(pendingTransactionsProvider);
      _ref.invalidate(pendingTransactionCountProvider);
      await loadPendingTransactions();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deleteRejected() async {
    if (_ledgerId == null) return;

    try {
      await _repository.deleteAllRejected(_ledgerId);
      await loadPendingTransactions();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final pendingTransactionNotifierProvider =
    StateNotifierProvider<
      PendingTransactionNotifier,
      AsyncValue<List<PendingTransactionModel>>
    >((ref) {
      final repository = ref.watch(pendingTransactionRepositoryProvider);
      final transactionRepository = TransactionRepository();
      final ledgerId = ref.watch(selectedLedgerIdProvider);
      return PendingTransactionNotifier(
        repository,
        transactionRepository,
        ledgerId,
        ref,
      );
    });

// 탭별 필터링된 Provider (성능 최적화)
final pendingTabTransactionsProvider = Provider<List<PendingTransactionModel>>((
  ref,
) {
  final asyncValue = ref.watch(pendingTransactionNotifierProvider);
  return asyncValue.valueOrNull
          ?.where((t) => t.status == PendingTransactionStatus.pending)
          .toList() ??
      [];
});

final confirmedTabTransactionsProvider =
    Provider<List<PendingTransactionModel>>((ref) {
      final asyncValue = ref.watch(pendingTransactionNotifierProvider);
      return asyncValue.valueOrNull
              ?.where(
                (t) =>
                    t.status == PendingTransactionStatus.confirmed ||
                    t.status == PendingTransactionStatus.converted,
              )
              .toList() ??
          [];
    });

final rejectedTabTransactionsProvider = Provider<List<PendingTransactionModel>>(
  (ref) {
    final asyncValue = ref.watch(pendingTransactionNotifierProvider);
    return asyncValue.valueOrNull
            ?.where((t) => t.status == PendingTransactionStatus.rejected)
            .toList() ??
        [];
  },
);
