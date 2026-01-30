import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';

class AppBadgeService {
  AppBadgeService._();

  static AppBadgeService? _instance;
  static AppBadgeService get instance {
    _instance ??= AppBadgeService._();
    return _instance!;
  }

  bool _isSupported = false;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Android와 iOS에서만 지원
      if (!Platform.isAndroid && !Platform.isIOS) {
        _isSupported = false;
        _initialized = true;
        return;
      }

      _isSupported = await FlutterAppBadger.isAppBadgeSupported();
      _initialized = true;

      if (kDebugMode) {
        debugPrint('[AppBadge] Initialized, supported: $_isSupported');
      }
    } catch (e) {
      _isSupported = false;
      _initialized = true;
      if (kDebugMode) {
        debugPrint('[AppBadge] Initialization error: $e');
      }
    }
  }

  Future<void> updateBadge(int count) async {
    if (!_initialized) {
      await initialize();
    }

    if (!_isSupported) return;

    try {
      if (count > 0) {
        await FlutterAppBadger.updateBadgeCount(count);
        if (kDebugMode) {
          debugPrint('[AppBadge] Badge updated to $count');
        }
      } else {
        await FlutterAppBadger.removeBadge();
        if (kDebugMode) {
          debugPrint('[AppBadge] Badge removed');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AppBadge] Error updating badge: $e');
      }
    }
  }

  Future<void> removeBadge() async {
    await updateBadge(0);
  }

  bool get isSupported => _isSupported;
}
