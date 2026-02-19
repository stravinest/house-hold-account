import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/services/app_update_service.dart';

part 'app_update_provider.g.dart';

/// 현재 앱 버전 정보 (캐싱)
@riverpod
Future<PackageInfo> packageInfo(Ref ref) async {
  ref.keepAlive();
  return await PackageInfo.fromPlatform();
}

@riverpod
class AppUpdate extends _$AppUpdate {
  @override
  FutureOr<AppVersionInfo?> build() async {
    ref.keepAlive();
    return await AppUpdateService.checkForUpdate();
  }

  /// 강제 새로고침 (설정 화면 수동 체크용)
  Future<AppVersionInfo?> forceCheck() async {
    state = const AsyncLoading();
    try {
      final result = await AppUpdateService.checkForUpdate(force: true);
      state = AsyncData(result);
      return result;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[AppUpdate] forceCheck 실패: $e');
      }
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}
