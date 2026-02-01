import '../../domain/entities/fcm_token.dart';

/// FCM 토큰 모델 클래스
/// Supabase fcm_tokens 테이블과 매핑
class FcmTokenModel extends FcmToken {
  const FcmTokenModel({
    required super.id,
    required super.userId,
    required super.token,
    required super.deviceType,
    required super.createdAt,
    required super.updatedAt,
  });

  /// JSON에서 FcmTokenModel 생성
  factory FcmTokenModel.fromJson(Map<String, dynamic> json) {
    return FcmTokenModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      token: json['token'] as String,
      deviceType: json['device_type'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// FcmTokenModel을 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'token': token,
      'device_type': deviceType,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// FCM 토큰 생성을 위한 JSON 변환 (id, createdAt, updatedAt 제외)
  static Map<String, dynamic> toCreateJson({
    required String userId,
    required String token,
    required String deviceType,
  }) {
    return {'user_id': userId, 'token': token, 'device_type': deviceType};
  }

  @override
  FcmTokenModel copyWith({
    String? id,
    String? userId,
    String? token,
    String? deviceType,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FcmTokenModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      token: token ?? this.token,
      deviceType: deviceType ?? this.deviceType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
