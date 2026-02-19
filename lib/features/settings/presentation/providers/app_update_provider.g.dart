// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_update_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$packageInfoHash() => r'a26b3b850684b629341d415a0ef1de2e4e922957';

/// 현재 앱 버전 정보 (캐싱)
///
/// Copied from [packageInfo].
@ProviderFor(packageInfo)
final packageInfoProvider = AutoDisposeFutureProvider<PackageInfo>.internal(
  packageInfo,
  name: r'packageInfoProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$packageInfoHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PackageInfoRef = AutoDisposeFutureProviderRef<PackageInfo>;
String _$appUpdateHash() => r'0eeb4901404342cc563194a5293f15cb924075cc';

/// See also [AppUpdate].
@ProviderFor(AppUpdate)
final appUpdateProvider =
    AutoDisposeAsyncNotifierProvider<AppUpdate, AppVersionInfo?>.internal(
      AppUpdate.new,
      name: r'appUpdateProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$appUpdateHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$AppUpdate = AutoDisposeAsyncNotifier<AppVersionInfo?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
