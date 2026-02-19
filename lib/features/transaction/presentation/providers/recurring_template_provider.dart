import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ledger/presentation/providers/ledger_provider.dart';
import '../../data/repositories/transaction_repository.dart';
import 'transaction_provider.dart';

// 반복 거래 템플릿 목록 (활성 + 비활성 모두)
final recurringTemplatesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final ledgerId = ref.watch(selectedLedgerIdProvider);
  if (ledgerId == null) return [];

  final repository = ref.watch(transactionRepositoryProvider);
  return repository.getAllRecurringTemplates(ledgerId: ledgerId);
});

// 반복 거래 템플릿 CRUD Notifier
class RecurringTemplateNotifier extends StateNotifier<AsyncValue<void>> {
  final TransactionRepository _repository;
  final Ref _ref;

  RecurringTemplateNotifier(this._repository, this._ref)
      : super(const AsyncValue.data(null));

  Future<void> toggle(String templateId, bool isActive) async {
    state = const AsyncValue.loading();
    try {
      await _repository.toggleRecurringTemplate(templateId, isActive);
      if (!mounted) return;
      _ref.invalidate(recurringTemplatesProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> update(
    String templateId, {
    int? amount,
    String? title,
    String? memo,
    String? recurringType,
    DateTime? endDate,
    bool clearEndDate = false,
    String? categoryId,
    String? paymentMethodId,
    String? fixedExpenseCategoryId,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateRecurringTemplate(
        templateId,
        amount: amount,
        title: title,
        memo: memo,
        recurringType: recurringType,
        endDate: endDate,
        clearEndDate: clearEndDate,
        categoryId: categoryId,
        paymentMethodId: paymentMethodId,
        fixedExpenseCategoryId: fixedExpenseCategoryId,
      );
      if (!mounted) return;
      _ref.invalidate(recurringTemplatesProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> delete(String templateId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteRecurringTemplate(templateId);
      if (!mounted) return;
      _ref.invalidate(recurringTemplatesProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final recurringTemplateNotifierProvider =
    StateNotifierProvider<RecurringTemplateNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(transactionRepositoryProvider);
  return RecurringTemplateNotifier(repository, ref);
});
