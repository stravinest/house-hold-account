import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/notification_type.dart';
import '../../data/repositories/notification_settings_repository.dart';

part 'notification_settings_provider.g.dart';

/// 알림 설정 Repository Provider
@riverpod
NotificationSettingsRepository notificationSettingsRepository(
  Ref ref,
) {
  return NotificationSettingsRepository();
}

/// 알림 설정 Provider
///
/// 현재 로그인한 사용자의 알림 설정을 관리합니다.
/// 각 알림 타입별 활성화 여부를 Map으로 제공합니다.
@riverpod
class NotificationSettings extends _$NotificationSettings {
  @override
  Future<Map<NotificationType, bool>> build() async {
    // 현재 로그인한 사용자 정보 가져오기
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      // 로그인하지 않은 경우 기본값 반환
      return {
        for (var type in NotificationType.values) type: true,
      };
    }

    final repository = ref.watch(notificationSettingsRepositoryProvider);
    try {
      return await repository.getNotificationSettings(user.id);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// 특정 알림 설정 업데이트
  ///
  /// [type] 알림 타입
  /// [enabled] 활성화 여부
  Future<void> updateNotificationSetting(
    NotificationType type,
    bool enabled,
  ) async {
    // 현재 로그인한 사용자 정보 가져오기
    final user = ref.read(currentUserProvider);
    if (user == null) {
      throw Exception('로그인이 필요합니다');
    }

    final repository = ref.read(notificationSettingsRepositoryProvider);
    try {
      await repository.updateNotificationSetting(
        userId: user.id,
        type: type,
        enabled: enabled,
      );

      // 상태 갱신
      state = const AsyncValue.loading();
      state = await AsyncValue.guard(
        () => repository.getNotificationSettings(user.id),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// 기본 알림 설정 초기화
  ///
  /// 신규 사용자 가입 시 호출합니다.
  /// 모든 알림 타입을 활성화 상태로 설정합니다.
  Future<void> initializeDefaultSettings() async {
    // 현재 로그인한 사용자 정보 가져오기
    final user = ref.read(currentUserProvider);
    if (user == null) {
      throw Exception('로그인이 필요합니다');
    }

    final repository = ref.read(notificationSettingsRepositoryProvider);
    try {
      await repository.initializeDefaultSettings(user.id);

      // 상태 갱신
      state = const AsyncValue.loading();
      state = await AsyncValue.guard(
        () => repository.getNotificationSettings(user.id),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}
