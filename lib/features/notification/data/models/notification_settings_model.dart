import '../../domain/entities/notification_settings.dart';
import '../../domain/entities/notification_type.dart';

/// 알림 설정 모델 클래스
/// Supabase notification_settings 테이블과 매핑
class NotificationSettingsModel extends NotificationSettings {
  const NotificationSettingsModel({
    required super.id,
    required super.userId,
    required super.notificationType,
    required super.enabled,
    required super.createdAt,
    required super.updatedAt,
  });

  /// JSON에서 NotificationSettingsModel 생성
  factory NotificationSettingsModel.fromJson(Map<String, dynamic> json) {
    return NotificationSettingsModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      notificationType: NotificationType.fromString(
        json['notification_type'] as String,
      ),
      enabled: json['enabled'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// NotificationSettingsModel을 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'notification_type': notificationType.value,
      'enabled': enabled,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// 알림 설정 생성을 위한 JSON 변환 (id, createdAt, updatedAt 제외)
  static Map<String, dynamic> toCreateJson({
    required String userId,
    required NotificationType notificationType,
    required bool enabled,
  }) {
    return {
      'user_id': userId,
      'notification_type': notificationType.value,
      'enabled': enabled,
    };
  }

  /// 알림 설정 업데이트를 위한 JSON 변환 (enabled만 수정 가능)
  static Map<String, dynamic> toUpdateJson({
    required bool enabled,
  }) {
    return {
      'enabled': enabled,
    };
  }

  @override
  NotificationSettingsModel copyWith({
    String? id,
    String? userId,
    NotificationType? notificationType,
    bool? enabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NotificationSettingsModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      notificationType: notificationType ?? this.notificationType,
      enabled: enabled ?? this.enabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
