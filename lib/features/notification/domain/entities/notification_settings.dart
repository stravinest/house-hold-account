import 'package:equatable/equatable.dart';
import 'notification_type.dart';

/// 알림 설정 엔티티
class NotificationSettings extends Equatable {
  final String id;
  final String userId;
  final NotificationType notificationType;
  final bool enabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  const NotificationSettings({
    required this.id,
    required this.userId,
    required this.notificationType,
    required this.enabled,
    required this.createdAt,
    required this.updatedAt,
  });

  NotificationSettings copyWith({
    String? id,
    String? userId,
    NotificationType? notificationType,
    bool? enabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NotificationSettings(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      notificationType: notificationType ?? this.notificationType,
      enabled: enabled ?? this.enabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    notificationType,
    enabled,
    createdAt,
    updatedAt,
  ];
}
