import '../../../../config/supabase_config.dart';
import '../../domain/entities/notification_type.dart';

/// 알림 설정 Repository
/// Supabase notification_settings 테이블과 상호작용하여 사용자의 알림 설정을 관리합니다.
///
/// 주의: notification_settings 테이블은 각 알림 타입별로 별도의 boolean 컬럼을 가지고 있습니다.
/// (budget_warning_enabled, budget_exceeded_enabled 등)
class NotificationSettingsRepository {
  final _client = SupabaseConfig.client;

  /// NotificationType을 컬럼명으로 변환
  String _getColumnName(NotificationType type) {
    switch (type) {
      case NotificationType.budgetWarning:
        return 'budget_warning_enabled';
      case NotificationType.budgetExceeded:
        return 'budget_exceeded_enabled';
      case NotificationType.sharedLedgerChange:
        return 'shared_ledger_change_enabled';
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
        return {
          for (var type in NotificationType.values) type: true,
        };
      }

      // DB 응답을 Map으로 변환
      return {
        NotificationType.budgetWarning:
            response['budget_warning_enabled'] as bool? ?? true,
        NotificationType.budgetExceeded:
            response['budget_exceeded_enabled'] as bool? ?? true,
        NotificationType.sharedLedgerChange:
            response['shared_ledger_change_enabled'] as bool? ?? true,
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
      await _client.from('notification_settings').upsert(
        {
          'user_id': userId,
          columnName: enabled,
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'user_id',
      );
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
      await _client.from('notification_settings').upsert(
        {
          'user_id': userId,
          'budget_warning_enabled': true,
          'budget_exceeded_enabled': true,
          'shared_ledger_change_enabled': true,
          'invite_received_enabled': true,
          'invite_accepted_enabled': true,
        },
        onConflict: 'user_id',
      );
    } catch (e) {
      // 에러를 호출자에게 전파
      rethrow;
    }
  }
}
