import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/providers/safe_notifier.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../ledger/presentation/providers/ledger_provider.dart';
import '../../data/repositories/fixed_expense_settings_repository.dart';
import '../../domain/entities/fixed_expense_settings.dart';

// Repository 프로바이더
final fixedExpenseSettingsRepositoryProvider =
    Provider<FixedExpenseSettingsRepository>((ref) {
      return FixedExpenseSettingsRepository();
    });

// 현재 가계부의 현재 유저 고정비 설정
final fixedExpenseSettingsProvider = FutureProvider<FixedExpenseSettings?>((
  ref,
) async {
  final ledgerId = ref.watch(selectedLedgerIdProvider);
  if (ledgerId == null) return null;

  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final repository = ref.watch(fixedExpenseSettingsRepositoryProvider);
  return repository.getSettings(ledgerId, user.id);
});

// 고정비를 지출에 편입하는지 여부 (간편 접근용)
final includeFixedExpenseInExpenseProvider = FutureProvider<bool>((ref) async {
  final settings = await ref.watch(fixedExpenseSettingsProvider.future);
  return settings?.includeInExpense ?? false;
});

// 고정비 설정 관리 노티파이어
class FixedExpenseSettingsNotifier
    extends SafeNotifier<FixedExpenseSettings?> {
  final FixedExpenseSettingsRepository _repository;
  final String? _ledgerId;
  final String? _userId;
  RealtimeChannel? _settingsChannel;

  FixedExpenseSettingsNotifier(
    this._repository,
    this._ledgerId,
    this._userId,
    Ref ref,
  ) : super(ref, const AsyncValue.loading()) {
    if (_ledgerId != null && _userId != null) {
      loadSettings();
      _subscribeToChanges();
    } else {
      safeUpdateState(const AsyncValue.data(null));
    }
  }

  void _subscribeToChanges() {
    if (_ledgerId == null || _userId == null) return;

    try {
      _settingsChannel = _repository.subscribeSettings(
        ledgerId: _ledgerId,
        userId: _userId,
        onSettingsChanged: () {
          _refreshSettingsQuietly();
        },
      );
    } catch (e) {
      debugPrint('FixedExpenseSettings Realtime subscribe fail: $e');
    }
  }

  Future<void> _refreshSettingsQuietly() async {
    if (_ledgerId == null || _userId == null) return;

    try {
      final settings = await safeAsync(
        () => _repository.getSettings(_ledgerId, _userId),
      );
      if (settings == null && !mounted) return;
      safeUpdateState(AsyncValue.data(settings));
      safeInvalidate(fixedExpenseSettingsProvider);
    } catch (e) {
      debugPrint('FixedExpenseSettings refresh fail: $e');
    }
  }

  @override
  void dispose() {
    _settingsChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> loadSettings() async {
    if (_ledgerId == null || _userId == null) {
      safeUpdateState(const AsyncValue.data(null));
      return;
    }

    safeUpdateState(const AsyncValue.loading());
    try {
      final settings = await safeAsync(
        () => _repository.getSettings(_ledgerId, _userId),
      );
      if (!mounted) return;
      safeUpdateState(AsyncValue.data(settings));
    } catch (e, st) {
      safeUpdateState(AsyncValue.error(e, st));
      rethrow;
    }
  }

  Future<void> updateIncludeInExpense(bool includeInExpense) async {
    if (_ledgerId == null) throw Exception('가계부를 선택해주세요');
    if (_userId == null) throw Exception('로그인이 필요합니다');

    try {
      final settings = await safeAsync(
        () => _repository.updateSettings(
          ledgerId: _ledgerId,
          userId: _userId,
          includeInExpense: includeInExpense,
        ),
      );
      if (!mounted) return;
      safeUpdateState(AsyncValue.data(settings));
      safeInvalidate(fixedExpenseSettingsProvider);
    } catch (e, st) {
      safeUpdateState(AsyncValue.error(e, st));
      rethrow;
    }
  }
}

final fixedExpenseSettingsNotifierProvider =
    StateNotifierProvider.autoDispose<
      FixedExpenseSettingsNotifier,
      AsyncValue<FixedExpenseSettings?>
    >((ref) {
      final repository = ref.watch(fixedExpenseSettingsRepositoryProvider);
      final ledgerId = ref.watch(selectedLedgerIdProvider);
      final user = ref.watch(currentUserProvider);
      return FixedExpenseSettingsNotifier(
        repository,
        ledgerId,
        user?.id,
        ref,
      );
    });
