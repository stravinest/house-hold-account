import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../data/repositories/fcm_token_repository.dart';
import '../../../config/firebase_config.dart';

/// FCM 토큰 관리 서비스
/// Firebase Cloud Messaging을 통해 푸시 알림 토큰을 관리합니다.
/// 싱글톤 패턴으로 구현되어 앱 전체에서 하나의 인스턴스만 사용합니다.
class FirebaseMessagingService {
  static final FirebaseMessagingService _instance =
      FirebaseMessagingService._internal();

  factory FirebaseMessagingService() => _instance;

  FirebaseMessagingService._internal();

  final FcmTokenRepository _tokenRepository = FcmTokenRepository();

  // Firebase Messaging 인스턴스 (Firebase가 설정되지 않으면 null)
  dynamic _messaging;

  // 토큰 갱신 리스너 구독
  StreamSubscription? _tokenRefreshSubscription;

  /// FCM 초기화
  ///
  /// Firebase가 설정되지 않은 경우 초기화를 건너뛰고 정상 종료합니다.
  ///
  /// [userId] 현재 로그인한 사용자 ID
  ///
  /// Throws: Firebase 또는 토큰 저장 중 발생한 에러
  Future<void> initialize(String userId) async {
    try {
      // Firebase 설정 확인
      if (!FirebaseConfig.isAvailable) {
        if (kDebugMode) {
          print('Firebase 설정이 없습니다. FCM 기능을 사용할 수 없습니다.');
        }
        return;
      }

      // Firebase Messaging 인스턴스를 동적으로 가져옴
      // firebase_messaging 패키지가 없어도 컴파일 가능하도록 dynamic 사용
      try {
        // 런타임에 FirebaseMessaging.instance 접근 시도
        _messaging = _getMessagingInstance();
      } catch (e) {
        if (kDebugMode) {
          print('FirebaseMessaging을 불러올 수 없습니다: $e');
        }
        return;
      }

      // 알림 권한 요청 (iOS)
      if (Platform.isIOS) {
        await _requestPermission();
      }

      // FCM 토큰 획득 및 저장
      final token = await getToken();
      if (token != null) {
        await _saveToken(userId, token);
      }

      // 토큰 갱신 리스너 설정
      _setupTokenRefreshListener(userId);

      // 메시지 핸들러 설정
      _setupMessageHandlers();
    } catch (e) {
      if (kDebugMode) {
        print('FCM 초기화 중 에러 발생: $e');
      }
      rethrow;
    }
  }

  /// Firebase Messaging 인스턴스 가져오기
  ///
  /// firebase_messaging 패키지가 설치되지 않은 경우 에러 발생
  dynamic _getMessagingInstance() {
    // 실제 구현 시 firebase_messaging 패키지를 import하고
    // return FirebaseMessaging.instance;
    // 현재는 패키지가 없으므로 null 반환
    throw UnsupportedError('firebase_messaging 패키지가 설치되지 않았습니다.');
  }

  /// 알림 권한 요청 (iOS)
  Future<void> _requestPermission() async {
    try {
      if (_messaging == null) return;

      // 실제 구현:
      // final settings = await _messaging.requestPermission(
      //   alert: true,
      //   badge: true,
      //   sound: true,
      // );
      //
      // if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      //   print('알림 권한이 허용되었습니다.');
      // } else {
      //   print('알림 권한이 거부되었습니다.');
      // }
    } catch (e) {
      if (kDebugMode) {
        print('알림 권한 요청 중 에러 발생: $e');
      }
      rethrow;
    }
  }

  /// FCM 토큰 획득
  ///
  /// Returns: FCM 토큰 문자열 또는 null (Firebase가 설정되지 않은 경우)
  Future<String?> getToken() async {
    try {
      if (_messaging == null) return null;

      // 실제 구현:
      // final token = await _messaging.getToken();
      // return token;

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('FCM 토큰 획득 중 에러 발생: $e');
      }
      rethrow;
    }
  }

  /// FCM 토큰 Supabase에 저장
  ///
  /// [userId] 사용자 ID
  /// [token] FCM 토큰
  Future<void> _saveToken(String userId, String token) async {
    try {
      // 디바이스 타입 판단
      String deviceType = 'unknown';
      if (kIsWeb) {
        deviceType = 'web';
      } else if (Platform.isAndroid) {
        deviceType = 'android';
      } else if (Platform.isIOS) {
        deviceType = 'ios';
      }

      await _tokenRepository.saveFcmToken(
        userId: userId,
        token: token,
        deviceType: deviceType,
      );
    } catch (e) {
      if (kDebugMode) {
        print('FCM 토큰 저장 중 에러 발생: $e');
      }
      rethrow;
    }
  }

  /// FCM 토큰 삭제 (로그아웃 시 호출)
  ///
  /// [userId] 사용자 ID
  Future<void> deleteToken(String userId) async {
    try {
      // 현재 디바이스의 토큰 삭제
      final token = await getToken();
      if (token != null) {
        await _tokenRepository.deleteFcmToken(token);
      }

      // FCM 토큰 삭제 (Firebase에서)
      if (_messaging != null) {
        // 실제 구현:
        // await _messaging.deleteToken();
      }

      // 구독 취소
      await _tokenRefreshSubscription?.cancel();
    } catch (e) {
      if (kDebugMode) {
        print('FCM 토큰 삭제 중 에러 발생: $e');
      }
      rethrow;
    }
  }

  /// 토큰 갱신 리스너 설정
  ///
  /// FCM 토큰이 갱신되면 자동으로 Supabase에 저장합니다.
  ///
  /// [userId] 사용자 ID
  void _setupTokenRefreshListener(String userId) {
    if (_messaging == null) return;

    // 실제 구현:
    // _tokenRefreshSubscription = _messaging.onTokenRefresh.listen((newToken) async {
    //   try {
    //     await _saveToken(userId, newToken);
    //   } catch (e) {
    //     if (kDebugMode) {
    //       print('토큰 갱신 저장 중 에러 발생: $e');
    //     }
    //   }
    // });
  }

  /// 포그라운드/백그라운드 메시지 핸들러 설정
  void _setupMessageHandlers() {
    if (_messaging == null) return;

    // 포그라운드 메시지 핸들러
    // 실제 구현:
    // FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    //   if (kDebugMode) {
    //     print('포그라운드 메시지 수신: ${message.notification?.title}');
    //   }
    //
    //   // 로컬 알림으로 표시 (LocalNotificationService 사용)
    //   if (message.notification != null) {
    //     LocalNotificationService().showNotification(
    //       title: message.notification!.title ?? '',
    //       body: message.notification!.body ?? '',
    //       data: message.data,
    //     );
    //   }
    // });

    // 백그라운드 메시지 핸들러
    // 실제 구현:
    // FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  /// 서비스 정리 (앱 종료 시 호출)
  Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
  }
}

/// 백그라운드 메시지 핸들러
///
/// 최상위 함수로 정의되어야 합니다 (Firebase 요구사항)
// @pragma('vm:entry-point')
// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   // Firebase 초기화가 필요한 경우
//   // await Firebase.initializeApp();
//
//   if (kDebugMode) {
//     print('백그라운드 메시지 수신: ${message.notification?.title}');
//   }
// }
