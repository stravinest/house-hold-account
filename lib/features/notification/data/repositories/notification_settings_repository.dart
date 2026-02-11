import '../../../../config/supabase_config.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../../domain/entities/notification_type.dart';

class NotificationSettingsRepository {
  final _client = SupabaseConfig.client;

  /// NotificationType을 컬럼명으로 변환
  String _getColumnName(NotificationType type) {
    switch (type) {
      case NotificationType.sharedLedgerChange:
        return 'shared_ledger_change_enabled';
      case NotificationType.transactionAdded:
        return 'transaction_added_enabled';
      case NotificationType.transactionUpdated:
        return 'transaction_updated_enabled';
      case NotificationType.transactionDeleted:
        return 'transaction_deleted_enabled';
      case NotificationType.autoCollectSuggested:
        return 'auto_collect_suggested_enabled';
      case NotificationType.autoCollectSaved:
        return 'auto_collect_saved_enabled';
      case NotificationType.inviteReceived:
        return 'invite_received_enabled';
      case NotificationType.inviteAccepted:
        return 'invite_accepted_enabled';
    }
  }

  /// 사용자의 알림 설정 조회
  ///
  /// [userId] 사용자 ID
  /// Returns: 사용자의 알림 설정 (각 알림 타입별 활성화 여부를 Map으로 반환)
  Future<Map<NotificationType, bool>> getNotificationSettings(
    String userId,
  ) async {
    try {
      final response = await _client
          .from('notification_settings')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        // 설정이 없으면 모든 알림이 활성화된 기본값 반환
        return {for (var type in NotificationType.values) type: true};
      }

      return {
        // deprecated는 UI에 노출하지 않음
        NotificationType.sharedLedgerChange:
            response['shared_ledger_change_enabled'] as bool? ?? true,
        // 공유 가계부
        NotificationType.transactionAdded:
            response['transaction_added_enabled'] as bool? ?? true,
        NotificationType.transactionUpdated:
            response['transaction_updated_enabled'] as bool? ?? true,
        NotificationType.transactionDeleted:
            response['transaction_deleted_enabled'] as bool? ?? true,
        // 자동수집
        NotificationType.autoCollectSuggested:
            response['auto_collect_suggested_enabled'] as bool? ?? true,
        NotificationType.autoCollectSaved:
            response['auto_collect_saved_enabled'] as bool? ?? true,
        // 초대
        NotificationType.inviteReceived:
            response['invite_received_enabled'] as bool? ?? true,
        NotificationType.inviteAccepted:
            response['invite_accepted_enabled'] as bool? ?? true,
      };
    } catch (e) {
      // 에러를 호출자에게 전파
      rethrow;
    }
  }

  /// 특정 알림 설정 업데이트
  ///
  /// [userId] 사용자 ID
  /// [type] 알림 타입
  /// [enabled] 활성화 여부
  Future<void> updateNotificationSetting({
    required String userId,
    required NotificationType type,
    required bool enabled,
  }) async {
    try {
      final columnName = _getColumnName(type);

      // UPSERT: 설정이 없으면 생성, 있으면 업데이트
      await _client.from('notification_settings').upsert({
        'user_id': userId,
        columnName: enabled,
        'updated_at': DateTimeUtils.nowUtcIso(),
      }, onConflict: 'user_id');
    } catch (e) {
      // 에러를 호출자에게 전파
      rethrow;
    }
  }

  /// 모든 알림 타입에 대한 기본 설정 생성
  ///
  /// 신규 사용자 가입 시 호출됩니다. (enabled=true)
  /// DB 트리거로도 자동 생성되지만, 명시적으로 호출할 수 있습니다.
  ///
  /// [userId] 사용자 ID
  Future<void> initializeDefaultSettings(String userId) async {
    try {
      await _client.from('notification_settings').upsert({
        'user_id': userId,
        'shared_ledger_change_enabled': true,
        'transaction_added_enabled': true,
        'transaction_updated_enabled': true,
        'transaction_deleted_enabled': true,
        'auto_collect_suggested_enabled': true,
        'auto_collect_saved_enabled': true,
        'invite_received_enabled': true,
        'invite_accepted_enabled': true,
      }, onConflict: 'user_id');
    } catch (e) {
      rethrow;
    }
  }
}
