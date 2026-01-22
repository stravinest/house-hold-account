import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/providers/safe_notifier.dart';

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
class PaymentMethodNotifier extends SafeNotifier<List<PaymentMethod>> {
  final PaymentMethodRepository _repository;
  final String? _ledgerId;
  RealtimeChannel? _paymentMethodsChannel;

  PaymentMethodNotifier(this._repository, this._ledgerId, Ref ref)
    : super(ref, const AsyncValue.loading()) {
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
        ledgerId: _ledgerId,
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
      final paymentMethods = await safeAsync(
        () => _repository.getPaymentMethods(_ledgerId),
      );
      if (paymentMethods == null) return; // disposed

      safeUpdateState(AsyncValue.data(paymentMethods));
      safeInvalidate(paymentMethodsProvider);
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
      final paymentMethod = await safeAsync(
        () => _repository.createPaymentMethod(
          ledgerId: _ledgerId,
          name: name,
          icon: icon,
          color: color,
          canAutoSave: canAutoSave,
        ),
      );

      if (paymentMethod == null) throw Exception('위젯이 dispose되었습니다');

      safeInvalidate(paymentMethodsProvider);
      await loadPaymentMethods();
      return paymentMethod;
    } catch (e, st) {
      debugPrint('PaymentMethod create fail: $e');
      safeUpdateState(AsyncValue.error(e, st));
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
      await safeAsync(
        () => _repository.updatePaymentMethod(
          id: id,
          name: name,
          icon: icon,
          color: color,
          canAutoSave: canAutoSave,
        ),
      );

      // Realtime subscription이 변경을 감지하므로 수동 로드가 불필요합니다.
      safeInvalidate(paymentMethodsProvider);
    } catch (e, st) {
      debugPrint('PaymentMethod update fail: $e');
      safeUpdateState(AsyncValue.error(e, st));
      // rethrow를 제거하여 호출자에서 추가 에러 핸들링 필요 없이 안전하게 종료
    }
  }

  Future<void> deletePaymentMethod(String id) async {
    try {
      await safeAsync(() => _repository.deletePaymentMethod(id));

      safeInvalidate(paymentMethodsProvider);
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
      await safeAsync(
        () => _repository.updateAutoSaveSettings(
          id: id,
          autoSaveMode: autoSaveMode.toJson(),
          defaultCategoryId: defaultCategoryId,
        ),
      );

      safeInvalidate(paymentMethodsProvider);
      await loadPaymentMethods();
    } catch (e, st) {
      safeUpdateState(AsyncValue.error(e, st));
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
