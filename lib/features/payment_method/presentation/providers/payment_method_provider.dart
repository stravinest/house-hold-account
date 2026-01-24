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

// 특정 멤버의 결제수단 목록 (멤버별 탭용)
final paymentMethodsByOwnerProvider =
    FutureProvider.family<List<PaymentMethod>, String>((
      ref,
      ownerUserId,
    ) async {
      final ledgerId = ref.watch(selectedLedgerIdProvider);
      if (ledgerId == null) return [];

      final repository = ref.watch(paymentMethodRepositoryProvider);
      return repository.getPaymentMethodsByOwner(
        ledgerId: ledgerId,
        ownerUserId: ownerUserId,
      );
    });

// 공유 결제수단 목록 (직접입력, can_auto_save = false)
final sharedPaymentMethodsProvider =
    FutureProvider<List<PaymentMethod>>((ref) async {
      final ledgerId = ref.watch(selectedLedgerIdProvider);
      if (ledgerId == null) return [];

      final repository = ref.watch(paymentMethodRepositoryProvider);
      return repository.getSharedPaymentMethods(ledgerId);
    });

// 특정 멤버의 자동수집 결제수단 목록 (can_auto_save = true)
final autoCollectPaymentMethodsByOwnerProvider =
    FutureProvider.family<List<PaymentMethod>, String>((
      ref,
      ownerUserId,
    ) async {
      final ledgerId = ref.watch(selectedLedgerIdProvider);
      if (ledgerId == null) return [];

      final repository = ref.watch(paymentMethodRepositoryProvider);
      return repository.getAutoCollectPaymentMethodsByOwner(
        ledgerId: ledgerId,
        ownerUserId: ownerUserId,
      );
    });

// 결제수단 관리 노티파이어
class PaymentMethodNotifier extends SafeNotifier<List<PaymentMethod>> {
  final PaymentMethodRepository _repository;
  final String? _ledgerId;
  RealtimeChannel? _paymentMethodsChannel;

  PaymentMethodNotifier(this._repository, this._ledgerId, Ref ref)
    : super(ref, const AsyncValue.loading()) {
    // 생성자 완료 후 다음 이벤트 루프에서 초기화 실행
    if (_ledgerId != null) {
      Future.microtask(() {
        _subscribeToChanges();
        loadPaymentMethods();
      });
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
      // 공유/자동수집 provider도 함께 갱신
      safeInvalidate(sharedPaymentMethodsProvider);
      // 자동수집 결제수단 provider는 family이므로 전체 목록 재갱신을 위해
      // UI에서 현재 userId로 다시 watch하도록 함
      // (family provider는 특정 args로만 invalidate 가능하므로 UI에서 처리)
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
      rethrow; // UI에서 에러 처리할 수 있도록 전파
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
    AutoCollectSource? autoCollectSource,
  }) async {
    try {
      await safeAsync(
        () => _repository.updateAutoSaveSettings(
          id: id,
          autoSaveMode: autoSaveMode.toJson(),
          defaultCategoryId: defaultCategoryId,
          autoCollectSource: autoCollectSource?.toJson(),
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
    StateNotifierProvider<
      PaymentMethodNotifier,
      AsyncValue<List<PaymentMethod>>
    >((ref) {
      final repository = ref.watch(paymentMethodRepositoryProvider);
      final ledgerId = ref.watch(selectedLedgerIdProvider);
      return PaymentMethodNotifier(repository, ledgerId, ref);
    });
