import 'dart:io';
import 'package:flutter/foundation.dart';

/// 로컬 알림 표시 서비스
/// flutter_local_notifications 패키지를 사용하여 로컬 알림을 표시합니다.
/// 싱글톤 패턴으로 구현되어 앱 전체에서 하나의 인스턴스만 사용합니다.
class LocalNotificationService {
  static final LocalNotificationService _instance =
      LocalNotificationService._internal();

  factory LocalNotificationService() => _instance;

  LocalNotificationService._internal();

  // FlutterLocalNotificationsPlugin 인스턴스 (패키지가 없으면 null)
  dynamic _notificationsPlugin;

  // 초기화 여부
  bool _isInitialized = false;

  /// 로컬 알림 초기화
  ///
  /// flutter_local_notifications 패키지가 설치되지 않은 경우 초기화를 건너뜁니다.
  ///
  /// Throws: 초기화 중 발생한 에러
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // FlutterLocalNotificationsPlugin 인스턴스 생성 시도
      _notificationsPlugin = _createPluginInstance();

      if (_notificationsPlugin == null) {
        if (kDebugMode) {
          print('flutter_local_notifications 패키지가 설치되지 않았습니다.');
        }
        return;
      }

      // 실제 구현 (flutter_local_notifications 패키지 설치 후):
      // const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
      // const initializationSettingsIOS = DarwinInitializationSettings(
      //   requestAlertPermission: true,
      //   requestBadgePermission: true,
      //   requestSoundPermission: true,
      // );
      //
      // const initializationSettings = InitializationSettings(
      //   android: initializationSettingsAndroid,
      //   iOS: initializationSettingsIOS,
      // );
      //
      // await _notificationsPlugin.initialize(
      //   initializationSettings,
      //   onDidReceiveNotificationResponse: _onNotificationTapped,
      // );

      // Android 알림 채널 생성
      if (Platform.isAndroid) {
        await _createAndroidChannel();
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

  /// FlutterLocalNotificationsPlugin 인스턴스 생성
  ///
  /// flutter_local_notifications 패키지가 설치되지 않은 경우 null 반환
  dynamic _createPluginInstance() {
    try {
      // 실제 구현:
      // return FlutterLocalNotificationsPlugin();
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('FlutterLocalNotificationsPlugin을 생성할 수 없습니다: $e');
      }
      return null;
    }
  }

  /// Android 알림 채널 생성
  Future<void> _createAndroidChannel() async {
    if (_notificationsPlugin == null) return;

    try {
      // 실제 구현:
      // const androidChannel = AndroidNotificationChannel(
      //   'default_channel',
      //   'Default Notifications',
      //   description: 'Default notification channel',
      //   importance: Importance.high,
      // );
      //
      // await _notificationsPlugin
      //     .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      //     ?.createNotificationChannel(androidChannel);
    } catch (e) {
      if (kDebugMode) {
        print('Android 알림 채널 생성 중 에러 발생: $e');
      }
      rethrow;
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
    if (!_isInitialized || _notificationsPlugin == null) {
      if (kDebugMode) {
        print('로컬 알림이 초기화되지 않았습니다.');
      }
      return;
    }

    try {
      // 실제 구현 (flutter_local_notifications 패키지 설치 후):
      // final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      //
      // const androidDetails = AndroidNotificationDetails(
      //   'default_channel',
      //   'Default Notifications',
      //   channelDescription: 'Default notification channel',
      //   importance: Importance.high,
      //   priority: Priority.high,
      // );
      //
      // const iosDetails = DarwinNotificationDetails(
      //   presentAlert: true,
      //   presentBadge: true,
      //   presentSound: true,
      // );
      //
      // const notificationDetails = NotificationDetails(
      //   android: androidDetails,
      //   iOS: iosDetails,
      // );
      //
      // await _notificationsPlugin.show(
      //   notificationId,
      //   title,
      //   body,
      //   notificationDetails,
      //   payload: data != null ? jsonEncode(data) : null,
      // );

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

  /// 특정 알림 취소
  ///
  /// [id] 취소할 알림 ID
  Future<void> cancelNotification(int id) async {
    if (!_isInitialized || _notificationsPlugin == null) return;

    try {
      // 실제 구현:
      // await _notificationsPlugin.cancel(id);

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

  /// 모든 알림 취소
  Future<void> cancelAllNotifications() async {
    if (!_isInitialized || _notificationsPlugin == null) return;

    try {
      // 실제 구현:
      // await _notificationsPlugin.cancelAll();

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

  /// 알림 탭 시 호출되는 콜백
  ///
  /// [response] 알림 응답 객체 (payload 포함)
  ///
  /// 주의: 이 메서드는 flutter_local_notifications 패키지 설치 후
  /// initialize 메서드에서 onDidReceiveNotificationResponse 콜백으로 사용됩니다.
  // ignore: unused_element
  void _onNotificationTapped(dynamic response) {
    // 실제 구현:
    // final payload = response.payload;
    // if (payload != null) {
    //   try {
    //     final data = jsonDecode(payload) as Map<String, dynamic>;
    //
    //     // 알림 데이터에 따라 적절한 화면으로 이동
    //     // 예: 거래 알림이면 거래 상세 화면으로 이동
    //     if (data.containsKey('transaction_id')) {
    //       // 거래 상세 화면으로 이동
    //     } else if (data.containsKey('ledger_id')) {
    //       // 가계부 화면으로 이동
    //     }
    //   } catch (e) {
    //     if (kDebugMode) {
    //       print('알림 데이터 파싱 중 에러 발생: $e');
    //     }
    //   }
    // }

    if (kDebugMode) {
      print('알림 탭됨');
    }
  }
}
