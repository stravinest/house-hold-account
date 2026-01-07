import 'package:equatable/equatable.dart';

/// FCM 토큰 엔티티
class FcmToken extends Equatable {
  final String id;
  final String userId;
  final String token;
  final String deviceType; // android, ios, web
  final DateTime createdAt;
  final DateTime updatedAt;

  const FcmToken({
    required this.id,
    required this.userId,
    required this.token,
    required this.deviceType,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isAndroid => deviceType == 'android';
  bool get isIos => deviceType == 'ios';
  bool get isWeb => deviceType == 'web';

  FcmToken copyWith({
    String? id,
    String? userId,
    String? token,
    String? deviceType,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FcmToken(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      token: token ?? this.token,
      deviceType: deviceType ?? this.deviceType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        token,
        deviceType,
        createdAt,
        updatedAt,
      ];
}
