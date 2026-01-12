import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../ledger/presentation/providers/ledger_provider.dart';
import '../../data/repositories/fixed_expense_settings_repository.dart';
import '../../domain/entities/fixed_expense_settings.dart';

// Repository 프로바이더
final fixedExpenseSettingsRepositoryProvider =
    Provider<FixedExpenseSettingsRepository>((ref) {
  return FixedExpenseSettingsRepository();
});

// 현재 가계부의 고정비 설정
final fixedExpenseSettingsProvider =
    FutureProvider<FixedExpenseSettings?>((ref) async {
  final ledgerId = ref.watch(selectedLedgerIdProvider);
  if (ledgerId == null) return null;

  final repository = ref.watch(fixedExpenseSettingsRepositoryProvider);
  return repository.getSettings(ledgerId);
});

// 고정비를 지출에 편입하는지 여부 (간편 접근용)
final includeFixedExpenseInExpenseProvider = FutureProvider<bool>((ref) async {
  final settings = await ref.watch(fixedExpenseSettingsProvider.future);
  return settings?.includeInExpense ?? false;
});

// 고정비 설정 관리 노티파이어
class FixedExpenseSettingsNotifier
    extends StateNotifier<AsyncValue<FixedExpenseSettings?>> {
  final FixedExpenseSettingsRepository _repository;
  final String? _ledgerId;
  final Ref _ref;
  RealtimeChannel? _settingsChannel;

  FixedExpenseSettingsNotifier(this._repository, this._ledgerId, this._ref)
      : super(const AsyncValue.loading()) {
    if (_ledgerId != null) {
      loadSettings();
      _subscribeToChanges();
    } else {
      state = const AsyncValue.data(null);
    }
  }

  void _subscribeToChanges() {
    if (_ledgerId == null) return;

    try {
      _settingsChannel = _repository.subscribeSettings(
        ledgerId: _ledgerId,
        onSettingsChanged: () {
          _refreshSettingsQuietly();
        },
      );
    } catch (e) {
      debugPrint('FixedExpenseSettings Realtime subscribe fail: $e');
    }
  }

  Future<void> _refreshSettingsQuietly() async {
    if (_ledgerId == null) return;

    try {
      final settings = await _repository.getSettings(_ledgerId);
      if (mounted) {
        state = AsyncValue.data(settings);
        _ref.invalidate(fixedExpenseSettingsProvider);
      }
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
    if (_ledgerId == null) {
      state = const AsyncValue.data(null);
      return;
    }

    state = const AsyncValue.loading();
    try {
      final settings = await _repository.getSettings(_ledgerId);
      state = AsyncValue.data(settings);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateIncludeInExpense(bool includeInExpense) async {
    if (_ledgerId == null) throw Exception('가계부를 선택해주세요');

    try {
      final settings = await _repository.updateSettings(
        ledgerId: _ledgerId,
        includeInExpense: includeInExpense,
      );

      state = AsyncValue.data(settings);
      _ref.invalidate(fixedExpenseSettingsProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final fixedExpenseSettingsNotifierProvider = StateNotifierProvider<
    FixedExpenseSettingsNotifier, AsyncValue<FixedExpenseSettings?>>((ref) {
  final repository = ref.watch(fixedExpenseSettingsRepositoryProvider);
  final ledgerId = ref.watch(selectedLedgerIdProvider);
  return FixedExpenseSettingsNotifier(repository, ledgerId, ref);
});
