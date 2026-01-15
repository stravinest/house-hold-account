// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$firebaseMessagingServiceHash() =>
    r'bbeb89798816882e110210be7bcf88c4005ed765';

/// Firebase Messaging Service Provider
///
/// Copied from [firebaseMessagingService].
@ProviderFor(firebaseMessagingService)
final firebaseMessagingServiceProvider =
    AutoDisposeProvider<FirebaseMessagingService>.internal(
      firebaseMessagingService,
      name: r'firebaseMessagingServiceProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$firebaseMessagingServiceHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FirebaseMessagingServiceRef =
    AutoDisposeProviderRef<FirebaseMessagingService>;
String _$notificationHash() => r'bc95d4a5972cdf97a08d97e9cb5a52339067decb';

/// 알림 Provider
///
/// Firebase 메시징 초기화 및 알림 수신 처리를 담당합니다.
/// 현재 로그인한 사용자에 대해 FCM 토큰을 등록하고 관리합니다.
///
/// Copied from [Notification].
@ProviderFor(Notification)
final notificationProvider =
    AutoDisposeAsyncNotifierProvider<Notification, void>.internal(
      Notification.new,
      name: r'notificationProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$notificationHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$Notification = AutoDisposeAsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
