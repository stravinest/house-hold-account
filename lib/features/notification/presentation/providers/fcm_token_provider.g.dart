// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fcm_token_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$fcmTokenRepositoryHash() =>
    r'0b3a1c28cd7adadbf050305bcc86fbedef82bc45';

/// FCM 토큰 Repository Provider
///
/// Copied from [fcmTokenRepository].
@ProviderFor(fcmTokenRepository)
final fcmTokenRepositoryProvider =
    AutoDisposeProvider<FcmTokenRepository>.internal(
      fcmTokenRepository,
      name: r'fcmTokenRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$fcmTokenRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FcmTokenRepositoryRef = AutoDisposeProviderRef<FcmTokenRepository>;
String _$fcmTokenHash() => r'a1f81be2092da35a9e91002aa11e1f9ef7e70e7a';

/// FCM 토큰 목록 Provider
///
/// 현재 로그인한 사용자의 FCM 토큰 목록을 관리합니다.
///
/// Copied from [FcmToken].
@ProviderFor(FcmToken)
final fcmTokenProvider =
    AutoDisposeAsyncNotifierProvider<FcmToken, List<FcmTokenModel>>.internal(
      FcmToken.new,
      name: r'fcmTokenProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$fcmTokenHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$FcmToken = AutoDisposeAsyncNotifier<List<FcmTokenModel>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
