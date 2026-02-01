import 'package:flutter/foundation.dart';

import '../../../../config/supabase_config.dart';
import '../../domain/entities/notification_type.dart';
import '../repositories/notification_settings_repository.dart';
import '../../services/local_notification_service.dart';

/// 알림 전송 서비스
///
/// 알림 설정 확인 후 로컬 알림 표시 및 히스토리 저장
/// 자동수집 알림 전용 (공유 가계부 알림은 Edge Function에서 처리)
class NotificationService {
  final _client = SupabaseConfig.client;
  final _settingsRepository = NotificationSettingsRepository();
  final _localNotificationService = LocalNotificationService();

  /// 알림 전송 (자동수집 전용)
  ///
  /// [userId] 알림 받을 사용자 ID
  /// [type] 알림 타입 (autoCollectSuggested 또는 autoCollectSaved)
  /// [title] 알림 제목
  /// [body] 알림 내용
  /// [data] 추가 데이터 (pendingId, transactionId 등)
  Future<void> sendAutoCollectNotification({
    required String userId,
    required NotificationType type,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    try {
      // 1. 사용자 알림 설정 조회
      final settings = await _settingsRepository.getNotificationSettings(
        userId,
      );

      // 2. 해당 알림 타입이 활성화되어 있는지 확인
      final isEnabled = settings[type] ?? false;
      if (!isEnabled) {
        if (kDebugMode) {
          debugPrint('[NotificationService] $type 알림이 비활성화되어 있습니다.');
        }
        return;
      }

      // 3. 로컬 알림 표시 (포그라운드인 경우)
      // FCM은 백그라운드에서만 자동 표시되므로 로컬 알림 사용
      await _localNotificationService.showNotification(
        title: title,
        body: body,
        data: data,
      );

      // 4. 알림 히스토리 저장
      await _savePushNotification(
        userId: userId,
        type: type,
        title: title,
        body: body,
        data: data,
      );

      if (kDebugMode) {
        debugPrint('[NotificationService] $type 알림 전송 완료 (userId: $userId)');
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[NotificationService] 알림 전송 실패: $e');
        debugPrint(st.toString());
      }
      // 알림 전송 실패는 치명적 에러가 아니므로 rethrow 하지 않음
    }
  }

  /// 알림 히스토리 저장
  Future<void> _savePushNotification({
    required String userId,
    required NotificationType type,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _client.from('push_notifications').insert({
        'user_id': userId,
        'type': type.value,
        'title': title,
        'body': body,
        'data': data,
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[NotificationService] 알림 히스토리 저장 실패: $e');
      }
      // 히스토리 저장 실패는 무시 (선택 사항)
    }
  }
}
