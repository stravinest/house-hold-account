import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/config/firebase_config.dart';

void main() {
  group('FirebaseConfig currentPlatformOptions 상세 테스트', () {
    setUp(() {
      dotenv.testLoad(
        fileInput: '''
FIREBASE_API_KEY=test-api-key
FIREBASE_APP_ID=test-app-id
FIREBASE_MESSAGING_SENDER_ID=test-sender-id
FIREBASE_PROJECT_ID=test-project-id
FIREBASE_STORAGE_BUCKET=test-bucket
FIREBASE_IOS_BUNDLE_ID=com.test.app
FIREBASE_AUTH_DOMAIN=test.firebaseapp.com
''',
      );
    });

    test('currentPlatformOptions는 null이거나 Map<String, String> 타입이다', () {
      // Given & When
      final result = FirebaseConfig.currentPlatformOptions;

      // Then: kIsWeb이 아니고 macOS 테스트 환경이므로 null 또는 Map
      expect(result, anyOf(isNull, isA<Map<String, String>>()));
    });

    test('currentPlatformOptions 결과와 isAvailable이 일치한다', () {
      // Given
      final platformOptions = FirebaseConfig.currentPlatformOptions;

      // When
      final isAvailable = FirebaseConfig.isAvailable;

      // Then: currentPlatformOptions가 null이면 isAvailable도 false
      if (platformOptions == null) {
        expect(isAvailable, isFalse);
      } else {
        expect(isAvailable, isTrue);
      }
    });

    test('isAvailable은 currentPlatformOptions != null과 동일하다', () {
      // Given
      final isAvailable = FirebaseConfig.isAvailable;
      final platformOptions = FirebaseConfig.currentPlatformOptions;

      // When & Then
      expect(isAvailable, equals(platformOptions != null));
    });
  });

  group('FirebaseConfig options 상세 테스트', () {
    setUp(() {
      dotenv.testLoad(
        fileInput: '''
FIREBASE_API_KEY=test-api-key
FIREBASE_APP_ID=test-app-id
FIREBASE_MESSAGING_SENDER_ID=test-sender-id
FIREBASE_PROJECT_ID=test-project-id
FIREBASE_STORAGE_BUCKET=test-bucket
FIREBASE_IOS_BUNDLE_ID=com.test.app
FIREBASE_AUTH_DOMAIN=test.firebaseapp.com
''',
      );
    });

    test('options getter는 null이거나 FirebaseOptions 타입이다', () {
      // Given & When: macOS 테스트 환경에서는 kIsWeb=false, Platform.isAndroid=false
      final result = FirebaseConfig.options;

      // Then: macOS에서는 null 반환 (Android/iOS/Web 모두 아님)
      expect(result, isNull);
    });

    test('isAvailable이 false이면 options는 null이다 (일관성 검증)', () {
      // Given
      final isAvailable = FirebaseConfig.isAvailable;

      // When
      final options = FirebaseConfig.options;

      // Then: isAvailable=false이면 options도 null
      if (!isAvailable) {
        expect(options, isNull);
      }
    });
  });

  group('FirebaseConfig androidOptions 상세 검증', () {
    test('androidOptions에서 FIREBASE_ANDROID_APP_ID 우선, 없으면 FIREBASE_APP_ID 사용', () {
      // Given: FIREBASE_ANDROID_APP_ID 없음, FIREBASE_APP_ID 있음
      dotenv.testLoad(
        fileInput: '''
FIREBASE_API_KEY=common-key
FIREBASE_APP_ID=common-app-id
FIREBASE_MESSAGING_SENDER_ID=sender-id
FIREBASE_PROJECT_ID=project-id
''',
      );

      // When
      final result = FirebaseConfig.androidOptions;

      // Then: FIREBASE_ANDROID_APP_ID가 없으므로 FIREBASE_APP_ID 사용
      expect(result, isNotNull);
      expect(result!['appId'], equals('common-app-id'));
    });

    test('androidOptions에서 storageBucket이 없으면 빈 문자열을 반환한다', () {
      // Given: storageBucket 없음
      dotenv.testLoad(
        fileInput: '''
FIREBASE_API_KEY=test-key
FIREBASE_APP_ID=test-app-id
FIREBASE_MESSAGING_SENDER_ID=sender-id
FIREBASE_PROJECT_ID=project-id
''',
      );

      // When
      final result = FirebaseConfig.androidOptions;

      // Then: storageBucket은 '' (기본값)
      expect(result, isNotNull);
      expect(result!['storageBucket'], equals(''));
    });

    test('androidOptions가 반환하는 Map에 5개 키가 있다', () {
      // Given: 모든 필수 값 설정
      dotenv.testLoad(
        fileInput: '''
FIREBASE_API_KEY=test-key
FIREBASE_APP_ID=test-app-id
FIREBASE_MESSAGING_SENDER_ID=sender-id
FIREBASE_PROJECT_ID=project-id
FIREBASE_STORAGE_BUCKET=test-bucket
''',
      );

      // When
      final result = FirebaseConfig.androidOptions;

      // Then: apiKey, appId, messagingSenderId, projectId, storageBucket = 5개
      expect(result, isNotNull);
      expect(result!.length, equals(5));
      expect(result.keys, containsAll(['apiKey', 'appId', 'messagingSenderId', 'projectId', 'storageBucket']));
    });
  });

  group('FirebaseConfig iosOptions 상세 검증', () {
    test('iosOptions에서 iosBundleId가 없으면 빈 문자열을 반환한다', () {
      // Given: iosBundleId 없음
      dotenv.testLoad(
        fileInput: '''
FIREBASE_API_KEY=test-key
FIREBASE_APP_ID=test-app-id
FIREBASE_MESSAGING_SENDER_ID=sender-id
FIREBASE_PROJECT_ID=project-id
''',
      );

      // When
      final result = FirebaseConfig.iosOptions;

      // Then: iosBundleId는 '' (기본값)
      expect(result, isNotNull);
      expect(result!['iosBundleId'], equals(''));
    });

    test('iosOptions가 반환하는 Map에 6개 키가 있다', () {
      // Given: 모든 필수 값 설정
      dotenv.testLoad(
        fileInput: '''
FIREBASE_API_KEY=test-key
FIREBASE_APP_ID=test-app-id
FIREBASE_MESSAGING_SENDER_ID=sender-id
FIREBASE_PROJECT_ID=project-id
FIREBASE_STORAGE_BUCKET=test-bucket
FIREBASE_IOS_BUNDLE_ID=com.test.app
''',
      );

      // When
      final result = FirebaseConfig.iosOptions;

      // Then: apiKey, appId, messagingSenderId, projectId, iosBundleId, storageBucket = 6개
      expect(result, isNotNull);
      expect(result!.length, equals(6));
      expect(result.keys, containsAll([
        'apiKey', 'appId', 'messagingSenderId', 'projectId', 'iosBundleId', 'storageBucket',
      ]));
    });

    test('iosOptions에서 FIREBASE_IOS_APP_ID가 없으면 FIREBASE_APP_ID를 사용한다', () {
      // Given: iOS 전용 APP_ID 없음
      dotenv.testLoad(
        fileInput: '''
FIREBASE_API_KEY=common-key
FIREBASE_APP_ID=common-app-id
FIREBASE_MESSAGING_SENDER_ID=sender-id
FIREBASE_PROJECT_ID=project-id
FIREBASE_IOS_BUNDLE_ID=com.test.app
''',
      );

      // When
      final result = FirebaseConfig.iosOptions;

      // Then: FIREBASE_IOS_APP_ID 없으므로 FIREBASE_APP_ID 사용
      expect(result, isNotNull);
      expect(result!['appId'], equals('common-app-id'));
    });
  });

  group('FirebaseConfig webOptions 상세 검증', () {
    test('webOptions에서 authDomain이 없으면 빈 문자열을 반환한다', () {
      // Given: authDomain 없음
      dotenv.testLoad(
        fileInput: '''
FIREBASE_WEB_API_KEY=web-key
FIREBASE_WEB_APP_ID=web-app-id
FIREBASE_MESSAGING_SENDER_ID=sender-id
FIREBASE_PROJECT_ID=project-id
''',
      );

      // When
      final result = FirebaseConfig.webOptions;

      // Then: authDomain은 '' (기본값)
      expect(result, isNotNull);
      expect(result!['authDomain'], equals(''));
    });

    test('webOptions가 반환하는 Map에 6개 키가 있다', () {
      // Given: 모든 필수 값 설정
      dotenv.testLoad(
        fileInput: '''
FIREBASE_WEB_API_KEY=web-key
FIREBASE_WEB_APP_ID=web-app-id
FIREBASE_MESSAGING_SENDER_ID=sender-id
FIREBASE_PROJECT_ID=project-id
FIREBASE_STORAGE_BUCKET=test-bucket
FIREBASE_AUTH_DOMAIN=test.firebaseapp.com
''',
      );

      // When
      final result = FirebaseConfig.webOptions;

      // Then: apiKey, appId, messagingSenderId, projectId, authDomain, storageBucket = 6개
      expect(result, isNotNull);
      expect(result!.length, equals(6));
      expect(result.keys, containsAll([
        'apiKey', 'appId', 'messagingSenderId', 'projectId', 'authDomain', 'storageBucket',
      ]));
    });

    test('webOptions에서 FIREBASE_WEB_APP_ID가 없으면 FIREBASE_APP_ID를 사용한다', () {
      // Given: Web 전용 APP_ID 없음
      dotenv.testLoad(
        fileInput: '''
FIREBASE_WEB_API_KEY=web-key
FIREBASE_APP_ID=common-app-id
FIREBASE_MESSAGING_SENDER_ID=sender-id
FIREBASE_PROJECT_ID=project-id
''',
      );

      // When
      final result = FirebaseConfig.webOptions;

      // Then: FIREBASE_WEB_APP_ID 없으므로 FIREBASE_APP_ID 사용
      expect(result, isNotNull);
      expect(result!['appId'], equals('common-app-id'));
    });

    test('webOptions에서 FIREBASE_WEB_API_KEY가 없으면 FIREBASE_API_KEY를 사용한다', () {
      // Given: Web 전용 API_KEY 없음
      dotenv.testLoad(
        fileInput: '''
FIREBASE_API_KEY=common-api-key
FIREBASE_WEB_APP_ID=web-app-id
FIREBASE_MESSAGING_SENDER_ID=sender-id
FIREBASE_PROJECT_ID=project-id
''',
      );

      // When
      final result = FirebaseConfig.webOptions;

      // Then: FIREBASE_WEB_API_KEY 없으므로 FIREBASE_API_KEY 사용
      expect(result, isNotNull);
      expect(result!['apiKey'], equals('common-api-key'));
    });
  });

  group('FirebaseConfig kIsWeb 분기 검증', () {
    test('kIsWeb 값이 bool 타입이다', () {
      // Given & When & Then: kIsWeb은 컴파일 타임 상수
      expect(kIsWeb, isA<bool>());
    });

    test('테스트 환경에서 kIsWeb은 false이다', () {
      // Given & When & Then: Flutter 단위 테스트는 웹이 아님
      expect(kIsWeb, isFalse);
    });

    test('options getter 는 kIsWeb=false 환경에서 null을 반환한다 (Android/iOS 아님)', () {
      // Given: macOS 테스트 환경
      dotenv.testLoad(
        fileInput: '''
FIREBASE_API_KEY=test-key
FIREBASE_APP_ID=test-app-id
FIREBASE_MESSAGING_SENDER_ID=sender-id
FIREBASE_PROJECT_ID=project-id
''',
      );

      // When: macOS는 kIsWeb=false, Platform.isAndroid=false, Platform.isIOS=false
      final options = FirebaseConfig.options;

      // Then: 어떤 분기에도 해당하지 않으므로 null 반환
      expect(options, isNull);
    });
  });

  group('FirebaseConfig 필수 키 누락 다양한 케이스 테스트', () {
    test('androidOptions에서 apiKey만 없으면 null을 반환한다', () {
      // Given: apiKey만 누락
      dotenv.testLoad(
        fileInput: '''
FIREBASE_APP_ID=test-app-id
FIREBASE_MESSAGING_SENDER_ID=sender-id
FIREBASE_PROJECT_ID=project-id
''',
      );

      // When
      final result = FirebaseConfig.androidOptions;

      // Then
      expect(result, isNull);
    });

    test('androidOptions에서 projectId만 없으면 null을 반환한다', () {
      // Given: projectId만 누락
      dotenv.testLoad(
        fileInput: '''
FIREBASE_API_KEY=test-key
FIREBASE_APP_ID=test-app-id
FIREBASE_MESSAGING_SENDER_ID=sender-id
''',
      );

      // When
      final result = FirebaseConfig.androidOptions;

      // Then
      expect(result, isNull);
    });

    test('iosOptions에서 apiKey만 없으면 null을 반환한다', () {
      // Given
      dotenv.testLoad(
        fileInput: '''
FIREBASE_APP_ID=test-app-id
FIREBASE_MESSAGING_SENDER_ID=sender-id
FIREBASE_PROJECT_ID=project-id
FIREBASE_IOS_BUNDLE_ID=com.test.app
''',
      );

      // When
      final result = FirebaseConfig.iosOptions;

      // Then
      expect(result, isNull);
    });

    test('webOptions에서 apiKey만 없으면 null을 반환한다', () {
      // Given: 모든 apiKey 키 누락
      dotenv.testLoad(
        fileInput: '''
FIREBASE_WEB_APP_ID=web-app-id
FIREBASE_MESSAGING_SENDER_ID=sender-id
FIREBASE_PROJECT_ID=project-id
''',
      );

      // When
      final result = FirebaseConfig.webOptions;

      // Then
      expect(result, isNull);
    });

    test('모든 환경변수가 비어있으면 모든 platform options가 null이다', () {
      // Given: 완전히 빈 dotenv
      dotenv.testLoad(fileInput: '');

      // When
      final android = FirebaseConfig.androidOptions;
      final ios = FirebaseConfig.iosOptions;
      final web = FirebaseConfig.webOptions;

      // Then
      expect(android, isNull);
      expect(ios, isNull);
      expect(web, isNull);
    });
  });

  group('FirebaseConfig 환경변수 폴백(fallback) 동작 테스트', () {
    test('FIREBASE_ANDROID_API_KEY 없으면 FIREBASE_API_KEY로 폴백된다', () {
      // Given: Android 전용 키 없음
      dotenv.testLoad(
        fileInput: '''
FIREBASE_API_KEY=fallback-api-key
FIREBASE_APP_ID=test-app-id
FIREBASE_MESSAGING_SENDER_ID=sender-id
FIREBASE_PROJECT_ID=project-id
''',
      );

      // When
      final result = FirebaseConfig.androidOptions;

      // Then: FIREBASE_API_KEY로 폴백
      expect(result!['apiKey'], equals('fallback-api-key'));
    });

    test('FIREBASE_IOS_API_KEY 없으면 FIREBASE_API_KEY로 폴백된다', () {
      // Given: iOS 전용 키 없음
      dotenv.testLoad(
        fileInput: '''
FIREBASE_API_KEY=fallback-ios-key
FIREBASE_APP_ID=test-app-id
FIREBASE_MESSAGING_SENDER_ID=sender-id
FIREBASE_PROJECT_ID=project-id
FIREBASE_IOS_BUNDLE_ID=com.test.app
''',
      );

      // When
      final result = FirebaseConfig.iosOptions;

      // Then: FIREBASE_API_KEY로 폴백
      expect(result!['apiKey'], equals('fallback-ios-key'));
    });
  });
}
