import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../services/firebase_messaging_service.dart';

part 'notification_provider.g.dart';

/// Firebase Messaging Service Provider
@riverpod
FirebaseMessagingService firebaseMessagingService(Ref ref) {
  return FirebaseMessagingService();
}

/// 알림 Provider
///
/// Firebase 메시징 초기화 및 알림 수신 처리를 담당합니다.
/// 현재 로그인한 사용자에 대해 FCM 토큰을 등록하고 관리합니다.
@riverpod
class Notification extends _$Notification {
  @override
  Future<void> build() async {
    // 현재 로그인한 사용자 정보 가져오기
    final user = ref.watch(currentUserProvider);

    if (kDebugMode) {
      debugPrint('[NotificationProvider] build() called');
      debugPrint('[NotificationProvider] user: ${user?.id ?? "null"}');
    }

    if (user == null) {
      // 로그인하지 않은 경우 초기화하지 않음
      if (kDebugMode) {
        debugPrint('[NotificationProvider] user is null, skipping FCM init');
      }
      return;
    }

    // Firebase 메시징 초기화 (재시도 로직 포함)
    final service = ref.watch(firebaseMessagingServiceProvider);
    await _initializeWithRetry(service, user.id);
  }

  /// FCM 초기화 (재시도 로직 포함)
  ///
  /// 최대 3회 재시도, 각 시도 사이 1초 대기
  Future<void> _initializeWithRetry(
    FirebaseMessagingService service,
    String userId,
  ) async {
    const maxRetries = 3;

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        if (kDebugMode) {
          debugPrint(
            '[NotificationProvider] FCM init attempt $attempt/$maxRetries for user: $userId',
          );
        }

        await service.initialize(userId);

        if (kDebugMode) {
          debugPrint(
            '[NotificationProvider] FCM init SUCCESS for user: $userId',
          );
        }
        return; // 성공하면 종료
      } catch (e, st) {
        if (kDebugMode) {
          debugPrint(
            '[NotificationProvider] FCM init FAILED (attempt $attempt): $e',
          );
        }

        if (attempt == maxRetries) {
          // 마지막 시도도 실패하면 에러 상태로 설정하고 rethrow
          state = AsyncValue.error(e, st);
          rethrow;
        }

        // 재시도 전 대기
        await Future.delayed(const Duration(seconds: 1));
      }
    }
  }

  /// FCM 토큰 삭제
  ///
  /// 로그아웃 시 호출하여 현재 디바이스의 FCM 토큰을 삭제합니다.
  Future<void> deleteToken() async {
    // 현재 로그인한 사용자 정보 가져오기
    final user = ref.read(currentUserProvider);
    if (user == null) {
      throw Exception('로그인이 필요합니다');
    }

    final service = ref.read(firebaseMessagingServiceProvider);
    try {
      await service.deleteToken(user.id);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}
