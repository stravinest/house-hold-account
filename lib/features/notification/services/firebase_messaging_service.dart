import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/repositories/fcm_token_repository.dart';
import '../../../config/firebase_config.dart';
import 'local_notification_service.dart';

/// 알림 탭 시 호출되는 콜백 타입
typedef FcmNotificationTapCallback =
    void Function(String? type, Map<String, dynamic>? data);

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
  FirebaseMessaging? _messaging;

  // 토큰 갱신 리스너 구독
  StreamSubscription? _tokenRefreshSubscription;

  // 메시지 리스너 구독 (메모리 누수 방지)
  StreamSubscription<RemoteMessage>? _onMessageSubscription;
  StreamSubscription<RemoteMessage>? _onMessageOpenedAppSubscription;

  /// 알림 탭 콜백 (외부에서 설정)
  FcmNotificationTapCallback? onNotificationTap;

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
  FirebaseMessaging _getMessagingInstance() {
    return FirebaseMessaging.instance;
  }

  /// 알림 권한 요청 (iOS)
  Future<void> _requestPermission() async {
    try {
      if (_messaging == null) return;

      final settings = await _messaging!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (kDebugMode) {
        if (settings.authorizationStatus == AuthorizationStatus.authorized) {
          print('알림 권한이 허용되었습니다.');
        } else {
          print('알림 권한이 거부되었습니다.');
        }
      }
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

      final token = await _messaging!.getToken();
      if (kDebugMode && token != null) {
        print('FCM token retrieved successfully');
      }
      return token;
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

      if (kDebugMode) {
        print('[FCM] Saving token, device type: $deviceType');
      }

      await _tokenRepository.saveFcmToken(
        userId: userId,
        token: token,
        deviceType: deviceType,
      );

      if (kDebugMode) {
        print('[FCM] Token saved successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[FCM] Token save FAILED: ${e.runtimeType}');
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
        await _messaging!.deleteToken();
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

    _tokenRefreshSubscription = _messaging!.onTokenRefresh.listen((
      newToken,
    ) async {
      try {
        if (kDebugMode) {
          print('FCM 토큰이 갱신되었습니다.');
        }
        await _saveToken(userId, newToken);
      } catch (e) {
        if (kDebugMode) {
          print('토큰 갱신 저장 중 에러 발생: $e');
        }
      }
    });
  }

  // 중복 수신 방지를 위한 최근 메시지 ID 저장
  final Set<String> _processedMessageIds = {};

  /// 포그라운드/백그라운드 메시지 핸들러 설정
  void _setupMessageHandlers() {
    if (_messaging == null) return;

    // 기존 구독 취소 (중복 방지)
    _onMessageSubscription?.cancel();
    _onMessageOpenedAppSubscription?.cancel();

    // 포그라운드 메시지 핸들러
    _onMessageSubscription = FirebaseMessaging.onMessage.listen((
      RemoteMessage message,
    ) {
      final messageId = message.messageId;

      if (kDebugMode) {
        print('[FCM] 포그라운드 메시지 수신: ${message.notification?.title}');
        print('[FCM] Message ID: $messageId');
      }

      // 메시지 ID가 있으면 중복 체크
      if (messageId != null) {
        if (_processedMessageIds.contains(messageId)) {
          if (kDebugMode) {
            print('[FCM] 중복 메시지 수신 무시 (ID: $messageId)');
          }
          return;
        }

        // 새로운 메시지 ID 저장 및 일정 시간 후 삭제 (메모리 관리)
        _processedMessageIds.add(messageId);
        Timer(const Duration(minutes: 5), () {
          _processedMessageIds.remove(messageId);
        });
      }

      // 본인이 생성한 거래에 대한 알림은 무시
      final creatorUserId = message.data['creator_user_id'];
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;

      if (kDebugMode) {
        print(
          '[FCM] creatorUserId: $creatorUserId, currentUserId: $currentUserId',
        );
      }

      if (creatorUserId != null &&
          currentUserId != null &&
          creatorUserId == currentUserId) {
        if (kDebugMode) {
          print('[FCM] Ignoring self-created transaction notification');
        }
        return;
      }

      // 로컬 알림으로 표시 (LocalNotificationService 사용)
      if (message.notification != null) {
        if (kDebugMode) {
          print('[FCM] Showing local notification for foreground message');
        }
        LocalNotificationService().showNotification(
          title: message.notification!.title ?? '',
          body: message.notification!.body ?? '',
          data: message.data,
        );
      } else {
        if (kDebugMode) {
          print('[FCM] Message received but no notification object found');
        }
      }
    });

    // 백그라운드에서 알림 탭하여 앱 열린 경우
    _onMessageOpenedAppSubscription = FirebaseMessaging.onMessageOpenedApp
        .listen(_handleNotificationTap);

    // 백그라운드 메시지 핸들러
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  /// 알림 탭 처리
  void _handleNotificationTap(RemoteMessage message) {
    if (kDebugMode) {
      print('FCM notification tapped');
    }

    if (onNotificationTap != null) {
      final type = message.data['type'] as String?;
      onNotificationTap!(type, message.data.cast<String, dynamic>());
    }
  }

  /// 앱이 종료된 상태에서 알림 탭으로 실행된 경우 확인
  ///
  /// 앱 시작 시 한 번 호출해야 합니다.
  Future<void> checkInitialMessage() async {
    if (_messaging == null) return;

    try {
      final message = await _messaging!.getInitialMessage();
      if (message != null) {
        if (kDebugMode) {
          print('Initial FCM message found on app start');
        }
        _handleNotificationTap(message);
      }
    } catch (e) {
      if (kDebugMode) {
        print('초기 FCM 메시지 확인 중 에러 발생: $e');
      }
    }
  }

  /// 서비스 정리 (앱 종료 시 호출)
  Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
    await _onMessageSubscription?.cancel();
    await _onMessageOpenedAppSubscription?.cancel();
    _tokenRefreshSubscription = null;
    _onMessageSubscription = null;
    _onMessageOpenedAppSubscription = null;
  }
}

/// 백그라운드 메시지 핸들러
///
/// 최상위 함수로 정의되어야 합니다 (Firebase 요구사항)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase 초기화가 필요한 경우 (이미 main.dart에서 초기화됨)
  // await Firebase.initializeApp();

  if (kDebugMode) {
    print('백그라운드 메시지 수신: ${message.notification?.title}');
  }
}
