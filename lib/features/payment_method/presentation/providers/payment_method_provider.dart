import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ledger/presentation/providers/ledger_provider.dart';
import '../../data/repositories/payment_method_repository.dart';
import '../../domain/entities/payment_method.dart';

// Repository 프로바이더
final paymentMethodRepositoryProvider = Provider<PaymentMethodRepository>((ref) {
  return PaymentMethodRepository();
});

// 현재 가계부의 결제수단 목록
final paymentMethodsProvider = FutureProvider<List<PaymentMethod>>((ref) async {
  final ledgerId = ref.watch(selectedLedgerIdProvider);
  if (ledgerId == null) return [];

  final repository = ref.watch(paymentMethodRepositoryProvider);
  return repository.getPaymentMethods(ledgerId);
});

// 결제수단 관리 노티파이어
class PaymentMethodNotifier extends StateNotifier<AsyncValue<List<PaymentMethod>>> {
  final PaymentMethodRepository _repository;
  final String? _ledgerId;
  final Ref _ref;

  PaymentMethodNotifier(this._repository, this._ledgerId, this._ref)
      : super(const AsyncValue.loading()) {
    if (_ledgerId != null) {
      loadPaymentMethods();
    } else {
      state = const AsyncValue.data([]);
    }
  }

  Future<void> loadPaymentMethods() async {
    if (_ledgerId == null) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();
    try {
      final paymentMethods = await _repository.getPaymentMethods(_ledgerId);
      state = AsyncValue.data(paymentMethods);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<PaymentMethod> createPaymentMethod({
    required String name,
    String icon = '',
    String color = '#6750A4',
  }) async {
    if (_ledgerId == null) throw Exception('가계부를 선택해주세요');

    try {
      final paymentMethod = await _repository.createPaymentMethod(
        ledgerId: _ledgerId,
        name: name,
        icon: icon,
        color: color,
      );

      _ref.invalidate(paymentMethodsProvider);
      await loadPaymentMethods();
      return paymentMethod;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updatePaymentMethod({
    required String id,
    String? name,
    String? icon,
    String? color,
  }) async {
    try {
      await _repository.updatePaymentMethod(
        id: id,
        name: name,
        icon: icon,
        color: color,
      );

      _ref.invalidate(paymentMethodsProvider);
      await loadPaymentMethods();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deletePaymentMethod(String id) async {
    try {
      await _repository.deletePaymentMethod(id);
      _ref.invalidate(paymentMethodsProvider);
      await loadPaymentMethods();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final paymentMethodNotifierProvider =
    StateNotifierProvider<PaymentMethodNotifier, AsyncValue<List<PaymentMethod>>>((ref) {
  final repository = ref.watch(paymentMethodRepositoryProvider);
  final ledgerId = ref.watch(selectedLedgerIdProvider);
  return PaymentMethodNotifier(repository, ledgerId, ref);
});
