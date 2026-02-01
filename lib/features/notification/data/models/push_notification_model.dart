import 'dart:convert';
import '../../domain/entities/push_notification.dart';
import '../../domain/entities/notification_type.dart';

/// 푸시 알림 모델 클래스
/// Supabase push_notifications 테이블과 매핑
class PushNotificationModel extends PushNotification {
  const PushNotificationModel({
    required super.id,
    required super.userId,
    required super.type,
    required super.title,
    required super.message,
    super.data,
    required super.isRead,
    required super.createdAt,
  });

  /// JSON에서 PushNotificationModel 생성
  factory PushNotificationModel.fromJson(Map<String, dynamic> json) {
    // data 필드 처리 (JSON 문자열 또는 Map)
    Map<String, dynamic>? dataMap;
    final dataField = json['data'];
    if (dataField != null) {
      if (dataField is String) {
        // JSON 문자열인 경우 파싱
        dataMap = jsonDecode(dataField) as Map<String, dynamic>;
      } else if (dataField is Map<String, dynamic>) {
        // 이미 Map인 경우 그대로 사용
        dataMap = dataField;
      }
    }

    return PushNotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: NotificationType.fromString(json['type'] as String),
      title: json['title'] as String,
      message: json['body'] as String,
      data: dataMap,
      isRead: json['is_read'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// PushNotificationModel을 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type.value,
      'title': title,
      'body': message,
      'data': data != null ? jsonEncode(data) : null,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// 푸시 알림 생성을 위한 JSON 변환 (id, createdAt 제외)
  static Map<String, dynamic> toCreateJson({
    required String userId,
    required NotificationType type,
    required String title,
    required String message,
    Map<String, dynamic>? data,
    bool isRead = false,
  }) {
    return {
      'user_id': userId,
      'type': type.value,
      'title': title,
      'body': message,
      'data': data != null ? jsonEncode(data) : null,
      'is_read': isRead,
    };
  }

  /// 읽음 상태 업데이트를 위한 JSON 변환
  static Map<String, dynamic> toReadJson() {
    return {'is_read': true};
  }

  @override
  PushNotificationModel copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? message,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return PushNotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
