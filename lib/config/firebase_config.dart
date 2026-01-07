import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Firebase 설정 클래스
/// .env 파일에서 Firebase 관련 환경변수를 읽어 FirebaseOptions를 제공합니다.
/// Firebase 설정이 없어도 앱이 정상 동작하도록 null을 반환할 수 있습니다.
class FirebaseConfig {
  /// Android용 Firebase 옵션
  static Map<String, String>? get androidOptions {
    final apiKey = dotenv.env['FIREBASE_ANDROID_API_KEY'];
    final appId = dotenv.env['FIREBASE_ANDROID_APP_ID'];
    final messagingSenderId = dotenv.env['FIREBASE_MESSAGING_SENDER_ID'];
    final projectId = dotenv.env['FIREBASE_PROJECT_ID'];

    // 필수 값이 하나라도 없으면 null 반환
    if (apiKey == null ||
        appId == null ||
        messagingSenderId == null ||
        projectId == null) {
      return null;
    }

    return {
      'apiKey': apiKey,
      'appId': appId,
      'messagingSenderId': messagingSenderId,
      'projectId': projectId,
      'storageBucket': dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? '',
    };
  }

  /// iOS용 Firebase 옵션
  static Map<String, String>? get iosOptions {
    final apiKey = dotenv.env['FIREBASE_IOS_API_KEY'];
    final appId = dotenv.env['FIREBASE_IOS_APP_ID'];
    final messagingSenderId = dotenv.env['FIREBASE_MESSAGING_SENDER_ID'];
    final projectId = dotenv.env['FIREBASE_PROJECT_ID'];
    final iosBundleId = dotenv.env['FIREBASE_IOS_BUNDLE_ID'];

    // 필수 값이 하나라도 없으면 null 반환
    if (apiKey == null ||
        appId == null ||
        messagingSenderId == null ||
        projectId == null ||
        iosBundleId == null) {
      return null;
    }

    return {
      'apiKey': apiKey,
      'appId': appId,
      'messagingSenderId': messagingSenderId,
      'projectId': projectId,
      'iosBundleId': iosBundleId,
      'storageBucket': dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? '',
    };
  }

  /// Web용 Firebase 옵션
  static Map<String, String>? get webOptions {
    final apiKey = dotenv.env['FIREBASE_WEB_API_KEY'];
    final appId = dotenv.env['FIREBASE_WEB_APP_ID'];
    final messagingSenderId = dotenv.env['FIREBASE_MESSAGING_SENDER_ID'];
    final projectId = dotenv.env['FIREBASE_PROJECT_ID'];

    // 필수 값이 하나라도 없으면 null 반환
    if (apiKey == null ||
        appId == null ||
        messagingSenderId == null ||
        projectId == null) {
      return null;
    }

    return {
      'apiKey': apiKey,
      'appId': appId,
      'messagingSenderId': messagingSenderId,
      'projectId': projectId,
      'authDomain': dotenv.env['FIREBASE_AUTH_DOMAIN'] ?? '',
      'storageBucket': dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? '',
    };
  }

  /// 현재 플랫폼에 맞는 Firebase 옵션 반환
  /// Firebase 설정이 없으면 null을 반환하여 앱이 Firebase 없이도 실행 가능하도록 합니다.
  static Map<String, String>? get currentPlatformOptions {
    if (kIsWeb) {
      return webOptions;
    } else if (Platform.isAndroid) {
      return androidOptions;
    } else if (Platform.isIOS) {
      return iosOptions;
    }
    return null;
  }

  /// Firebase 사용 가능 여부 확인
  static bool get isAvailable => currentPlatformOptions != null;

  /// 현재 플랫폼에 맞는 FirebaseOptions 반환
  /// Firebase 설정이 없으면 null을 반환합니다.
  static FirebaseOptions? get options {
    if (kIsWeb) {
      final webOpts = webOptions;
      if (webOpts == null) return null;

      return FirebaseOptions(
        apiKey: webOpts['apiKey']!,
        appId: webOpts['appId']!,
        messagingSenderId: webOpts['messagingSenderId']!,
        projectId: webOpts['projectId']!,
        authDomain: webOpts['authDomain'],
        storageBucket: webOpts['storageBucket'],
      );
    } else if (Platform.isAndroid) {
      final androidOpts = androidOptions;
      if (androidOpts == null) return null;

      return FirebaseOptions(
        apiKey: androidOpts['apiKey']!,
        appId: androidOpts['appId']!,
        messagingSenderId: androidOpts['messagingSenderId']!,
        projectId: androidOpts['projectId']!,
        storageBucket: androidOpts['storageBucket'],
      );
    } else if (Platform.isIOS) {
      final iosOpts = iosOptions;
      if (iosOpts == null) return null;

      return FirebaseOptions(
        apiKey: iosOpts['apiKey']!,
        appId: iosOpts['appId']!,
        messagingSenderId: iosOpts['messagingSenderId']!,
        projectId: iosOpts['projectId']!,
        iosBundleId: iosOpts['iosBundleId'],
        storageBucket: iosOpts['storageBucket'],
      );
    }
    return null;
  }
}
