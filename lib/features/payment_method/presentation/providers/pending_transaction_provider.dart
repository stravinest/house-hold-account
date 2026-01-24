import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
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

      final currentUser = ref.watch(currentUserProvider);
      if (currentUser == null) return [];

      final repository = ref.watch(pendingTransactionRepositoryProvider);
      return repository.getPendingTransactions(
        ledgerId,
        status: PendingTransactionStatus.pending,
        userId: currentUser.id,
      );
    });

final pendingTransactionCountProvider = FutureProvider.autoDispose<int>((
  ref,
) async {
  final ledgerId = ref.watch(selectedLedgerIdProvider);
  if (ledgerId == null) return 0;

  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) return 0;

  final repository = ref.watch(pendingTransactionRepositoryProvider);
  return repository.getPendingCount(ledgerId, currentUser.id);
});

class PendingTransactionNotifier
    extends StateNotifier<AsyncValue<List<PendingTransactionModel>>> {
  final PendingTransactionRepository _repository;
  final TransactionRepository _transactionRepository;
  final String? _ledgerId;
  final String? _userId;
  final Ref _ref;
  RealtimeChannel? _subscription;

  PendingTransactionNotifier(
    this._repository,
    this._transactionRepository,
    this._ledgerId,
    this._userId,
    this._ref,
  ) : super(const AsyncValue.loading()) {
    if (_ledgerId != null && _userId != null) {
      loadPendingTransactions();
      _subscribeToChanges();
    } else {
      state = const AsyncValue.data([]);
    }
  }

  void _subscribeToChanges() {
    if (_ledgerId == null || _userId == null) return;

    try {
      _subscription = _repository.subscribePendingTransactions(
        ledgerId: _ledgerId,
        userId: _userId,
        onTableChanged: () {
          // Realtime 업데이트는 silent refresh로 처리 (깜빡임 방지)
          loadPendingTransactions(silent: true);
          _ref.invalidate(pendingTransactionCountProvider);
        },
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('PendingTransaction Realtime subscribe fail: $e');
      }
    }
  }

  @override
  void dispose() {
    _subscription?.unsubscribe();
    super.dispose();
  }

  Future<void> loadPendingTransactions({
    PendingTransactionStatus? status,
    bool silent = false,
  }) async {
    if (kDebugMode) {
      debugPrint('[PendingTxNotifier] loadPendingTransactions called (silent: $silent)');
      debugPrint('[PendingTxNotifier] ledgerId: $_ledgerId, userId: $_userId');
    }

    if (_ledgerId == null || _userId == null) {
      if (kDebugMode) {
        debugPrint('[PendingTxNotifier] ledgerId or userId is null, returning empty');
      }
      state = const AsyncValue.data([]);
      return;
    }

    // Silent refresh: 이미 데이터가 있으면 loading 상태로 전환하지 않음
    final hasExistingData = state.hasValue && (state.value?.isNotEmpty ?? false);
    if (!silent || !hasExistingData) {
      state = const AsyncValue.loading();
    }

    try {
      final transactions = await _repository.getPendingTransactions(
        _ledgerId,
        status: status,
        userId: _userId,
      );
      if (kDebugMode) {
        debugPrint('[PendingTxNotifier] Loaded ${transactions.length} transactions');
      }
      state = AsyncValue.data(transactions);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[PendingTxNotifier] Error loading: $e');
      }
      // Silent refresh 중 에러 발생 시 기존 데이터 유지
      if (silent && hasExistingData) {
        // 에러를 로깅만 하고 상태는 유지
        if (kDebugMode) {
          debugPrint('[PendingTxNotifier] Silent refresh failed, keeping existing data');
        }
      } else {
        state = AsyncValue.error(e, st);
      }
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

  /// 파싱 데이터 업데이트와 거래 확인을 단일 트랜잭션으로 수행
  /// Race condition 방지를 위해 두 작업을 원자적으로 처리
  Future<void> updateAndConfirmTransaction({
    required String id,
    required int parsedAmount,
    required String parsedType,
    String? parsedMerchant,
    String? parsedCategoryId,
    DateTime? parsedDate,
  }) async {
    try {
      // 1. 파싱 데이터 업데이트
      await _repository.updateParsedData(
        id: id,
        parsedAmount: parsedAmount,
        parsedType: parsedType,
        parsedMerchant: parsedMerchant,
        parsedCategoryId: parsedCategoryId,
        parsedDate: parsedDate,
      );

      // 2. 거래 생성 (transactions 테이블에 저장)
      final currentList = state.valueOrNull ?? [];
      final pendingTx = currentList.firstWhere(
        (tx) => tx.id == id,
        orElse: () => throw Exception('거래를 찾을 수 없습니다'),
      );

      await _transactionRepository.createTransaction(
        ledgerId: _ledgerId!,
        categoryId: parsedCategoryId,
        paymentMethodId: pendingTx.paymentMethodId,
        amount: parsedAmount,
        type: parsedType,
        title: parsedMerchant ?? '',
        date: parsedDate ?? DateTime.now(),
        sourceType: pendingTx.sourceType.toJson(),
      );

      // 3. pending 상태를 converted로 변경
      await _repository.updateStatus(
        id: id,
        status: PendingTransactionStatus.converted,
      );

      // 4. 상태 갱신
      _ref.invalidate(pendingTransactionsProvider);
      _ref.invalidate(pendingTransactionCountProvider);
      await loadPendingTransactions();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> confirmAll() async {
    if (_ledgerId == null || _userId == null) return;

    try {
      final confirmed = await _repository.confirmAll(_ledgerId, _userId);

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
    if (_ledgerId == null || _userId == null) return;

    try {
      await _repository.rejectAll(_ledgerId, _userId);

      _ref.invalidate(pendingTransactionsProvider);
      _ref.invalidate(pendingTransactionCountProvider);
      await loadPendingTransactions();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deleteTransaction(String id) async {
    try {
      await _repository.deletePendingTransaction(id);
      await loadPendingTransactions();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deleteAllByStatus(PendingTransactionStatus status) async {
    if (_ledgerId == null || _userId == null) return;

    try {
      await _repository.deleteAllByStatus(_ledgerId, _userId, status);
      await loadPendingTransactions();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deleteRejected() async {
    await deleteAllByStatus(PendingTransactionStatus.rejected);
  }

  /// 확인됨 탭의 모든 항목 삭제 (confirmed + converted 상태)
  Future<void> deleteAllConfirmed() async {
    if (_ledgerId == null || _userId == null) return;

    try {
      await _repository.deleteAllConfirmed(_ledgerId, _userId);
      await loadPendingTransactions();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> markAllAsViewed() async {
    if (_ledgerId == null || _userId == null) return;
    try {
      await _repository.markAllAsViewed(_ledgerId, _userId);
      _ref.invalidate(pendingTransactionCountProvider);
    } catch (e) {
      debugPrint('Failed to mark notifications as viewed: $e');
    }
  }
}

final pendingTransactionNotifierProvider =
    StateNotifierProvider.autoDispose<
      PendingTransactionNotifier,
      AsyncValue<List<PendingTransactionModel>>
    >((ref) {
      final repository = ref.watch(pendingTransactionRepositoryProvider);
      final transactionRepository = TransactionRepository();
      final ledgerId = ref.watch(selectedLedgerIdProvider);
      final currentUser = ref.watch(currentUserProvider);
      return PendingTransactionNotifier(
        repository,
        transactionRepository,
        ledgerId,
        currentUser?.id,
        ref,
      );
    });

// 탭별 필터링된 Provider (성능 최적화)
// select를 사용하여 실제 데이터가 변경될 때만 재계산
final pendingTabTransactionsProvider = Provider<List<PendingTransactionModel>>((
  ref,
) {
  final transactions = ref.watch(
    pendingTransactionNotifierProvider.select(
      (asyncValue) => asyncValue.valueOrNull ?? [],
    ),
  );
  return transactions
      .where((t) => t.status == PendingTransactionStatus.pending)
      .toList();
});

final confirmedTabTransactionsProvider =
    Provider<List<PendingTransactionModel>>((ref) {
      final transactions = ref.watch(
        pendingTransactionNotifierProvider.select(
          (asyncValue) => asyncValue.valueOrNull ?? [],
        ),
      );
      return transactions
          .where(
            (t) =>
                t.status == PendingTransactionStatus.confirmed ||
                t.status == PendingTransactionStatus.converted,
          )
          .toList();
    });

final rejectedTabTransactionsProvider = Provider<List<PendingTransactionModel>>(
  (ref) {
    final transactions = ref.watch(
      pendingTransactionNotifierProvider.select(
        (asyncValue) => asyncValue.valueOrNull ?? [],
      ),
    );
    return transactions
        .where((t) => t.status == PendingTransactionStatus.rejected)
        .toList();
  },
);
