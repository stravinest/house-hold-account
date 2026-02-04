import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// 알림 탭 시 호출되는 콜백 타입
typedef NotificationTapCallback =
    void Function(String? type, Map<String, dynamic>? data);

class LocalNotificationService {
  static final LocalNotificationService _instance =
      LocalNotificationService._internal();

  factory LocalNotificationService() => _instance;

  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// 알림 탭 콜백 (외부에서 설정)
  NotificationTapCallback? onNotificationTap;

  /// 로컬 알림 초기화
  ///
  /// flutter_local_notifications 패키지가 설치되지 않은 경우 초기화를 건너뜁니다.
  ///
  /// Throws: 초기화 중 발생한 에러
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      const initializationSettingsAndroid = AndroidInitializationSettings(
        '@drawable/ic_notification',
      );
      const initializationSettingsIOS = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      if (Platform.isAndroid) {
        await _createAndroidChannel();
        // 권한 요청은 PermissionRequestDialog에서 통합 처리
      }

      _isInitialized = true;

      if (kDebugMode) {
        print('로컬 알림 초기화 완료');
      }
    } catch (e) {
      if (kDebugMode) {
        print('로컬 알림 초기화 중 에러 발생: $e');
      }
      rethrow;
    }
  }

  Future<void> _createAndroidChannel() async {
    try {
      const androidChannel = AndroidNotificationChannel(
        'household_account_channel',
        '공유 가계부 알림',
        description: '공유 가계부 관련 알림 채널',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );

      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(androidChannel);
    } catch (e) {
      if (kDebugMode) {
        print('Android 알림 채널 생성 중 에러 발생: $e');
      }
      rethrow;
    }
  }

  /// Android 13+ (API 33+)에서 푸시 알림 권한 확인
  ///
  /// Returns: 권한이 허용되었으면 true, 아니면 false
  Future<bool> checkPushNotificationPermission() async {
    if (!Platform.isAndroid) return true;

    try {
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidImplementation != null) {
        final granted = await androidImplementation.areNotificationsEnabled();
        return granted ?? false;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Android 알림 권한 확인 중 에러 발생: $e');
      }
      return false;
    }
  }

  /// Android 13+ (API 33+)에서 푸시 알림 권한 요청
  ///
  /// Returns: 권한이 허용되었으면 true, 아니면 false
  Future<bool> requestPushNotificationPermission() async {
    if (!Platform.isAndroid) return true;

    try {
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidImplementation != null) {
        final granted = await androidImplementation
            .requestNotificationsPermission();

        if (kDebugMode) {
          if (granted == true) {
            print('Android 알림 권한 허용됨');
          } else {
            print('Android 알림 권한 거부됨');
          }
        }
        return granted ?? false;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Android 알림 권한 요청 중 에러 발생: $e');
      }
      return false;
    }
  }

  /// 알림 표시
  ///
  /// [title] 알림 제목
  /// [body] 알림 내용
  /// [data] 추가 데이터 (알림 탭 시 사용)
  ///
  /// Throws: 알림 표시 중 발생한 에러
  Future<void> showNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    if (!_isInitialized) {
      if (kDebugMode) {
        print('로컬 알림이 초기화되지 않았습니다.');
      }
      return;
    }

    try {
      final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      const androidDetails = AndroidNotificationDetails(
        'household_account_channel',
        '공유 가계부 알림',
        channelDescription: '공유 가계부 관련 알림 채널',
        importance: Importance.max,
        priority: Priority.max,
        icon: '@drawable/ic_notification',
        playSound: true,
        enableVibration: true,
        showWhen: true,
        channelShowBadge: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // payload에 전체 data를 JSON으로 저장
      String? payload;
      if (data != null) {
        payload = jsonEncode(data);
      }

      await _notificationsPlugin.show(
        notificationId,
        title,
        body,
        notificationDetails,
        payload: payload,
      );

      if (kDebugMode) {
        print('알림 표시: $title - $body');
      }
    } catch (e) {
      if (kDebugMode) {
        print('알림 표시 중 에러 발생: $e');
      }
      rethrow;
    }
  }

  Future<void> cancelNotification(int id) async {
    if (!_isInitialized) return;

    try {
      await _notificationsPlugin.cancel(id);

      if (kDebugMode) {
        print('알림 취소: $id');
      }
    } catch (e) {
      if (kDebugMode) {
        print('알림 취소 중 에러 발생: $e');
      }
      rethrow;
    }
  }

  Future<void> cancelAllNotifications() async {
    if (!_isInitialized) return;

    try {
      await _notificationsPlugin.cancelAll();

      if (kDebugMode) {
        print('모든 알림 취소');
      }
    } catch (e) {
      if (kDebugMode) {
        print('모든 알림 취소 중 에러 발생: $e');
      }
      rethrow;
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (kDebugMode) {
      print('Notification tapped');
    }

    if (payload != null && onNotificationTap != null) {
      try {
        final data = jsonDecode(payload) as Map<String, dynamic>;
        final type = data['type'] as String?;
        onNotificationTap!(type, data);
      } catch (e) {
        // payload가 JSON이 아닌 경우 (이전 버전 호환)
        onNotificationTap!(payload, null);
      }
    }
  }

  /// 앱이 종료된 상태에서 알림 탭으로 실행된 경우 처리
  ///
  /// 앱 시작 시 한 번 호출해야 합니다.
  Future<void> checkInitialNotification() async {
    if (!_isInitialized) return;

    try {
      final details = await _notificationsPlugin
          .getNotificationAppLaunchDetails();
      if (details != null &&
          details.didNotificationLaunchApp &&
          details.notificationResponse != null) {
        _onNotificationTapped(details.notificationResponse!);
      }
    } catch (e) {
      if (kDebugMode) {
        print('초기 알림 확인 중 에러 발생: $e');
      }
    }
  }
}
