import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../config/supabase_config.dart';
import '../../../payment_method/data/services/app_badge_service.dart';

class AppVersionInfo {
  final String version;
  final int buildNumber;
  final String? storeUrl;
  final String? releaseNotes;
  final bool isForceUpdate;

  const AppVersionInfo({
    required this.version,
    required this.buildNumber,
    this.storeUrl,
    this.releaseNotes,
    this.isForceUpdate = false,
  });
}

class AppUpdateService {
  static const _lastCheckKey = 'app_update_last_check';
  static const _checkIntervalHours = 24;

  /// 업데이트 확인 (1일 1회)
  /// 새 버전이 있으면 AppVersionInfo 반환, 없으면 null
  static Future<AppVersionInfo?> checkForUpdate({
    SharedPreferences? prefs,
    bool force = false,
  }) async {
    try {
      prefs ??= await SharedPreferences.getInstance();

      // 1일 1회 체크
      if (!force) {
        final lastCheck = prefs.getInt(_lastCheckKey) ?? 0;
        final now = DateTime.now().millisecondsSinceEpoch;
        final elapsed = now - lastCheck;
        if (elapsed < _checkIntervalHours * 60 * 60 * 1000) {
          if (kDebugMode) {
            debugPrint('[AppUpdate] 체크 스킵 (마지막 체크 후 ${elapsed ~/ 1000 ~/ 60}분 경과)');
          }
          return null;
        }
      }

      // 현재 플랫폼
      final platform = Platform.isAndroid ? 'android' : 'ios';

      // Supabase에서 최신 버전 조회
      final response = await SupabaseConfig.client
          .from('app_versions')
          .select()
          .eq('platform', platform)
          .order('build_number', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) {
        if (kDebugMode) {
          debugPrint('[AppUpdate] 서버에 버전 정보 없음');
        }
        return null;
      }

      // 체크 시간 저장
      await prefs.setInt(
        _lastCheckKey,
        DateTime.now().millisecondsSinceEpoch,
      );

      // 현재 앱 버전 가져오기
      final packageInfo = await PackageInfo.fromPlatform();
      final currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 0;
      final serverBuildNumber = response['build_number'] as int;

      if (kDebugMode) {
        debugPrint('[AppUpdate] 현재: $currentBuildNumber, 서버: $serverBuildNumber');
      }

      // 비교
      if (serverBuildNumber > currentBuildNumber) {
        final versionInfo = AppVersionInfo(
          version: response['version'] as String,
          buildNumber: serverBuildNumber,
          storeUrl: response['store_url'] as String?,
          releaseNotes: response['release_notes'] as String?,
          isForceUpdate: response['is_force_update'] as bool? ?? false,
        );

        // 뱃지 설정
        await AppBadgeService.instance.updateBadge(1);

        return versionInfo;
      }

      // 최신 버전이면 뱃지 제거
      await AppBadgeService.instance.removeBadge();

      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AppUpdate] 업데이트 확인 실패: $e');
      }
      return null;
    }
  }
}
