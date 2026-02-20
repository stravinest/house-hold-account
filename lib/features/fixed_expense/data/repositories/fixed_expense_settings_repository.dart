import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../config/supabase_config.dart';
import '../models/fixed_expense_settings_model.dart';

/// 고정비 설정 Repository
class FixedExpenseSettingsRepository {
  final SupabaseClient _client;

  FixedExpenseSettingsRepository({SupabaseClient? client})
      : _client = client ?? SupabaseConfig.client;

  // 가계부의 유저별 고정비 설정 조회
  Future<FixedExpenseSettingsModel?> getSettings(
    String ledgerId,
    String userId,
  ) async {
    try {
      final response = await _client
          .from('fixed_expense_settings')
          .select()
          .eq('ledger_id', ledgerId)
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return null;
      return FixedExpenseSettingsModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<FixedExpenseSettingsModel> updateSettings({
    required String ledgerId,
    required String userId,
    required bool includeInExpense,
  }) async {
    try {
      final response = await _client
          .from('fixed_expense_settings')
          .upsert({
            'ledger_id': ledgerId,
            'user_id': userId,
            'include_in_expense': includeInExpense,
          }, onConflict: 'ledger_id,user_id')
          .select()
          .single();

      return FixedExpenseSettingsModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  // 실시간 구독
  RealtimeChannel subscribeSettings({
    required String ledgerId,
    required String userId,
    required void Function() onSettingsChanged,
  }) {
    return _client
        .channel('fixed_expense_settings_changes_${ledgerId}_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'house',
          table: 'fixed_expense_settings',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            onSettingsChanged();
          },
        )
        .subscribe();
  }
}
