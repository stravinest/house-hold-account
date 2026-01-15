import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../config/supabase_config.dart';
import '../models/fixed_expense_settings_model.dart';

/// 고정비 설정 Repository
class FixedExpenseSettingsRepository {
  final _client = SupabaseConfig.client;

  // 가계부의 고정비 설정 조회
  Future<FixedExpenseSettingsModel?> getSettings(String ledgerId) async {
    try {
      final response = await _client
          .from('fixed_expense_settings')
          .select()
          .eq('ledger_id', ledgerId)
          .maybeSingle();

      if (response == null) return null;
      return FixedExpenseSettingsModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<FixedExpenseSettingsModel> updateSettings({
    required String ledgerId,
    required bool includeInExpense,
  }) async {
    try {
      final response = await _client
          .from('fixed_expense_settings')
          .upsert({
            'ledger_id': ledgerId,
            'include_in_expense': includeInExpense,
          }, onConflict: 'ledger_id')
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
    required void Function() onSettingsChanged,
  }) {
    return _client
        .channel('fixed_expense_settings_changes_$ledgerId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'house',
          table: 'fixed_expense_settings',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'ledger_id',
            value: ledgerId,
          ),
          callback: (payload) {
            onSettingsChanged();
          },
        )
        .subscribe();
  }
}
