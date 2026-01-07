// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_settings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$notificationSettingsRepositoryHash() =>
    r'cd5607a6205a8320e12298eaaafffbd9dd03d7e7';

/// 알림 설정 Repository Provider
///
/// Copied from [notificationSettingsRepository].
@ProviderFor(notificationSettingsRepository)
final notificationSettingsRepositoryProvider =
    AutoDisposeProvider<NotificationSettingsRepository>.internal(
      notificationSettingsRepository,
      name: r'notificationSettingsRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$notificationSettingsRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef NotificationSettingsRepositoryRef =
    AutoDisposeProviderRef<NotificationSettingsRepository>;
String _$notificationSettingsHash() =>
    r'1e5c1bb5d44f667bb0a1f2322d0f8ad86c5ad0a0';

/// 알림 설정 Provider
///
/// 현재 로그인한 사용자의 알림 설정을 관리합니다.
/// 각 알림 타입별 활성화 여부를 Map으로 제공합니다.
///
/// Copied from [NotificationSettings].
@ProviderFor(NotificationSettings)
final notificationSettingsProvider =
    AutoDisposeAsyncNotifierProvider<
      NotificationSettings,
      Map<NotificationType, bool>
    >.internal(
      NotificationSettings.new,
      name: r'notificationSettingsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$notificationSettingsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$NotificationSettings =
    AutoDisposeAsyncNotifier<Map<NotificationType, bool>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
