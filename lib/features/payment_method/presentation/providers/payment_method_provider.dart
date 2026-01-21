import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../ledger/presentation/providers/ledger_provider.dart';
import '../../data/repositories/payment_method_repository.dart';
import '../../data/repositories/learned_sms_format_repository.dart';
import '../../data/services/sms_scanner_service.dart';
import '../../domain/entities/payment_method.dart';

final paymentMethodRepositoryProvider = Provider<PaymentMethodRepository>((
  ref,
) {
  return PaymentMethodRepository();
});

final learnedSmsFormatRepositoryProvider = Provider<LearnedSmsFormatRepository>(
  (ref) {
    return LearnedSmsFormatRepository();
  },
);

final smsScannerServiceProvider = Provider<SmsScannerService>((ref) {
  final repository = ref.watch(learnedSmsFormatRepositoryProvider);
  return SmsScannerService(repository);
});

// 현재 가계부의 결제수단 목록
final paymentMethodsProvider = FutureProvider<List<PaymentMethod>>((ref) async {
  final ledgerId = ref.watch(selectedLedgerIdProvider);
  if (ledgerId == null) return [];

  final repository = ref.watch(paymentMethodRepositoryProvider);
  return repository.getPaymentMethods(ledgerId);
});

// 결제수단 관리 노티파이어
class PaymentMethodNotifier
    extends StateNotifier<AsyncValue<List<PaymentMethod>>> {
  final PaymentMethodRepository _repository;
  final String? _ledgerId;
  final Ref _ref;
  RealtimeChannel? _paymentMethodsChannel;

  PaymentMethodNotifier(this._repository, this._ledgerId, this._ref)
    : super(const AsyncValue.loading()) {
    if (_ledgerId != null) {
      loadPaymentMethods();
      _subscribeToChanges();
    } else {
      state = const AsyncValue.data([]);
    }
  }

  void _subscribeToChanges() {
    if (_ledgerId == null) return;

    try {
      _paymentMethodsChannel = _repository.subscribePaymentMethods(
        ledgerId: _ledgerId!,
        onPaymentMethodChanged: () {
          _refreshPaymentMethodsQuietly();
        },
      );
    } catch (e) {
      debugPrint('PaymentMethod Realtime subscribe fail: $e');
    }
  }

  Future<void> _refreshPaymentMethodsQuietly() async {
    if (_ledgerId == null) return;

    try {
      final paymentMethods = await _repository.getPaymentMethods(_ledgerId!);
      if (mounted) {
        state = AsyncValue.data(paymentMethods);
        _ref.invalidate(paymentMethodsProvider);
      }
    } catch (e) {
      debugPrint('PaymentMethod refresh fail: $e');
    }
  }

  @override
  void dispose() {
    _paymentMethodsChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> loadPaymentMethods() async {
    if (_ledgerId == null) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();
    try {
      final paymentMethods = await _repository.getPaymentMethods(_ledgerId);
      if (mounted) {
        state = AsyncValue.data(paymentMethods);
      }
    } catch (e, st) {
      if (mounted) {
        state = AsyncValue.error(e, st);
      }
      rethrow;
    }
  }

  Future<PaymentMethod> createPaymentMethod({
    required String name,
    String icon = '',
    String color = '#6750A4',
    bool canAutoSave = true,
  }) async {
    if (_ledgerId == null) throw Exception('가계부를 선택해주세요');

    try {
      final paymentMethod = await _repository.createPaymentMethod(
        ledgerId: _ledgerId,
        name: name,
        icon: icon,
        color: color,
        canAutoSave: canAutoSave,
      );

      if (mounted) {
        _ref.invalidate(paymentMethodsProvider);
        await loadPaymentMethods();
      }
      return paymentMethod;
    } catch (e, st) {
      debugPrint('PaymentMethod create fail: $e');
      if (mounted) {
        state = AsyncValue.error(e, st);
      }
      rethrow;
    }
  }

  Future<void> updatePaymentMethod({
    required String id,
    String? name,
    String? icon,
    String? color,
    bool? canAutoSave,
  }) async {
    try {
      await _repository.updatePaymentMethod(
        id: id,
        name: name,
        icon: icon,
        color: color,
        canAutoSave: canAutoSave,
      );

      // Realtime subscription이 변경을 감지하므로 수동 로드가 불필요합니다.
      // loadPaymentMethods()는 비동기이므로, 호출 전 mounted 체크를 하더라도
      // 완료 전에 dispose될 수 있어 크래시가 발생할 수 있습니다.
      // invalidate만 수행하고, Realtime subscription이 UI를 업데이트합니다.
      if (mounted) {
        _ref.invalidate(paymentMethodsProvider);
      }
    } catch (e, st) {
      debugPrint('PaymentMethod update fail: $e');
      if (mounted) {
        state = AsyncValue.error(e, st);
      }
      // rethrow를 제거하여 호출자에서 추가 에러 핸들링 필요 없이 안전하게 종료
    }
  }

  Future<void> deletePaymentMethod(String id) async {
    try {
      await _repository.deletePaymentMethod(id);
      _ref.invalidate(paymentMethodsProvider);
      await loadPaymentMethods();
    } catch (e) {
      // 에러 발생 시에도 데이터를 다시 로드하여 상태 복구
      await loadPaymentMethods();
      rethrow;
    }
  }

  Future<void> updateAutoSaveSettings({
    required String id,
    required AutoSaveMode autoSaveMode,
    String? defaultCategoryId,
  }) async {
    try {
      await _repository.updateAutoSaveSettings(
        id: id,
        autoSaveMode: autoSaveMode.toJson(),
        defaultCategoryId: defaultCategoryId,
      );

      _ref.invalidate(paymentMethodsProvider);
      await loadPaymentMethods();
    } catch (e, st) {
      if (mounted) {
        state = AsyncValue.error(e, st);
      }
      rethrow;
    }
  }
}

final paymentMethodNotifierProvider =
    StateNotifierProvider.autoDispose<
      PaymentMethodNotifier,
      AsyncValue<List<PaymentMethod>>
    >((ref) {
      final repository = ref.watch(paymentMethodRepositoryProvider);
      final ledgerId = ref.watch(selectedLedgerIdProvider);
      return PaymentMethodNotifier(repository, ledgerId, ref);
    });
