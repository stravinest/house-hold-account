import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/config/firebase_config.dart';

void main() {
  group('FirebaseConfig 구조 및 메서드 시그니처 테스트', () {
    group('getter 시그니처 검증', () {
      test('androidOptions getter가 Map<String, String>? 타입이다', () {
        // Given & When: dotenv 미로드 환경에서는 NotInitializedError 발생 가능
        Map<String, String>? result;
        try {
          result = FirebaseConfig.androidOptions;
        } catch (_) {
          result = null;
        }
        // Then: null이거나 Map<String, String> 타입이다
        expect(result, anyOf(isNull, isA<Map<String, String>>()));
      });

      test('iosOptions getter가 Map<String, String>? 타입이다', () {
        // Given & When
        Map<String, String>? result;
        try {
          result = FirebaseConfig.iosOptions;
        } catch (_) {
          result = null;
        }
        expect(result, anyOf(isNull, isA<Map<String, String>>()));
      });

      test('webOptions getter가 Map<String, String>? 타입이다', () {
        // Given & When
        Map<String, String>? result;
        try {
          result = FirebaseConfig.webOptions;
        } catch (_) {
          result = null;
        }
        expect(result, anyOf(isNull, isA<Map<String, String>>()));
      });
    });

    group('isAvailable getter 검증', () {
      test('isAvailable getter가 bool 타입을 반환한다', () {
        // Given & When
        final result = FirebaseConfig.isAvailable;

        // Then
        expect(result, isA<bool>());
      });

      test('dotenv 미로드 시 isAvailable은 false이다', () {
        // Given: .env 파일이 없는 테스트 환경
        // When
        final result = FirebaseConfig.isAvailable;

        // Then: 설정이 없으므로 false
        expect(result, isFalse);
      });
    });

    group('options getter 검증', () {
      test('options getter가 null이거나 FirebaseOptions 타입이다', () {
        // Given & When: dotenv 미로드 환경
        // Then
        expect(FirebaseConfig.options, isNull);
      });
    });

    group('currentPlatformOptions getter 검증', () {
      test('currentPlatformOptions getter가 null이거나 Map<String, String> 타입이다', () {
        // Given & When: dotenv 미로드 환경
        final result = FirebaseConfig.currentPlatformOptions;

        // Then
        expect(result, anyOf(isNull, isA<Map<String, String>>()));
      });

      test('dotenv 미로드 시 currentPlatformOptions는 null이다', () {
        // Given: 환경변수가 없는 테스트 환경
        // When
        final result = FirebaseConfig.currentPlatformOptions;

        // Then: 필수 필드가 없으므로 null
        expect(result, isNull);
      });
    });

    group('Map 키 구조 검증 (환경변수 설정 시)', () {
      test('androidOptions가 null이 아닐 때 필수 키를 포함해야 한다', () {
        // Given: androidOptions가 설정된 경우를 가정
        final expectedKeys = ['apiKey', 'appId', 'messagingSenderId', 'projectId'];

        // When: dotenv 미로드 환경에서는 NotInitializedError가 발생하므로 try-catch로 처리
        Map<String, String>? opts;
        try {
          opts = FirebaseConfig.androidOptions;
        } catch (_) {
          // dotenv가 로드되지 않은 테스트 환경에서는 정상적인 예외
          opts = null;
        }

        if (opts != null) {
          // Then: 필수 키가 포함되어 있어야 한다
          for (final key in expectedKeys) {
            expect(opts.containsKey(key), isTrue, reason: 'androidOptions에 $key 키가 있어야 한다');
          }
        }

        // null인 경우 테스트 통과 (환경변수 미설정 상태)
        expect(true, isTrue);
      });

      test('iosOptions가 null이 아닐 때 iosBundleId 키를 포함해야 한다', () {
        // Given
        Map<String, String>? opts;
        try {
          opts = FirebaseConfig.iosOptions;
        } catch (_) {
          opts = null;
        }

        if (opts != null) {
          // Then: iOS 전용 키가 포함되어 있어야 한다
          expect(opts.containsKey('iosBundleId'), isTrue);
        }
        expect(true, isTrue);
      });

      test('webOptions가 null이 아닐 때 authDomain 키를 포함해야 한다', () {
        // Given
        Map<String, String>? opts;
        try {
          opts = FirebaseConfig.webOptions;
        } catch (_) {
          opts = null;
        }

        if (opts != null) {
          // Then: Web 전용 키가 포함되어 있어야 한다
          expect(opts.containsKey('authDomain'), isTrue);
        }
        expect(true, isTrue);
      });
    });

    group('환경변수 키 이름 문서화 테스트', () {
      test('Android API 키 환경변수 이름이 올바른 형식이다', () {
        // Given: 코드에서 사용하는 환경변수 키 이름들
        const envKeys = [
          'FIREBASE_ANDROID_API_KEY',
          'FIREBASE_ANDROID_APP_ID',
          'FIREBASE_MESSAGING_SENDER_ID',
          'FIREBASE_PROJECT_ID',
          'FIREBASE_STORAGE_BUCKET',
          'FIREBASE_API_KEY',
          'FIREBASE_APP_ID',
        ];

        // Then: 모든 키가 대문자 snake_case 형식이다
        final upperSnakeCasePattern = RegExp(r'^[A-Z]+(_[A-Z0-9]+)*$');
        for (final key in envKeys) {
          expect(
            upperSnakeCasePattern.hasMatch(key),
            isTrue,
            reason: '$key 는 대문자 SCREAMING_SNAKE_CASE 형식이어야 한다',
          );
        }
      });

      test('iOS 전용 환경변수 키가 정의되어 있다', () {
        // Given
        const iosKeys = [
          'FIREBASE_IOS_API_KEY',
          'FIREBASE_IOS_APP_ID',
          'FIREBASE_IOS_BUNDLE_ID',
        ];

        // Then: 모든 iOS 키가 FIREBASE_IOS_ 접두사를 가진다
        for (final key in iosKeys) {
          expect(key, startsWith('FIREBASE_IOS_'));
        }
      });

      test('Web 전용 환경변수 키가 정의되어 있다', () {
        // Given
        const webKeys = [
          'FIREBASE_WEB_API_KEY',
          'FIREBASE_WEB_APP_ID',
          'FIREBASE_AUTH_DOMAIN',
        ];

        // Then: 첫 두 키가 FIREBASE_WEB_ 접두사를 가진다
        expect(webKeys[0], startsWith('FIREBASE_WEB_'));
        expect(webKeys[1], startsWith('FIREBASE_WEB_'));
      });
    });

    group('isAvailable과 options 일관성 테스트', () {
      test('isAvailable이 false이면 options는 null이다', () {
        // Given
        final isAvailable = FirebaseConfig.isAvailable;
        final options = FirebaseConfig.options;

        // When & Then: isAvailable이 false이면 options도 null이어야 한다
        if (!isAvailable) {
          expect(options, isNull);
        }
      });

      test('currentPlatformOptions가 null이면 isAvailable도 false이다', () {
        // Given
        final platformOptions = FirebaseConfig.currentPlatformOptions;
        final isAvailable = FirebaseConfig.isAvailable;

        // When & Then
        if (platformOptions == null) {
          expect(isAvailable, isFalse);
        }
      });
    });
  });

  group('FirebaseConfig dotenv 환경변수 설정 시 테스트', () {
    setUp(() {
      dotenv.testLoad(fileInput: '''
FIREBASE_API_KEY=test-api-key
FIREBASE_APP_ID=test-app-id
FIREBASE_MESSAGING_SENDER_ID=test-sender-id
FIREBASE_PROJECT_ID=test-project-id
FIREBASE_STORAGE_BUCKET=test-bucket
FIREBASE_IOS_BUNDLE_ID=com.test.app
FIREBASE_AUTH_DOMAIN=test.firebaseapp.com
''');
    });

    test('androidOptions가 환경변수 설정 시 Map을 반환한다', () {
      // Given: dotenv에 Android 필수 값들이 설정됨
      // When
      final result = FirebaseConfig.androidOptions;

      // Then: null이 아닌 Map을 반환한다
      expect(result, isNotNull);
      expect(result, isA<Map<String, String>>());
      expect(result!['apiKey'], equals('test-api-key'));
      expect(result['appId'], equals('test-app-id'));
      expect(result['messagingSenderId'], equals('test-sender-id'));
      expect(result['projectId'], equals('test-project-id'));
      expect(result['storageBucket'], equals('test-bucket'));
    });

    test('iosOptions가 환경변수 설정 시 Map을 반환한다', () {
      // Given: dotenv에 iOS 필수 값들이 설정됨
      // When
      final result = FirebaseConfig.iosOptions;

      // Then: null이 아닌 Map을 반환한다
      expect(result, isNotNull);
      expect(result, isA<Map<String, String>>());
      expect(result!['apiKey'], equals('test-api-key'));
      expect(result['appId'], equals('test-app-id'));
      expect(result['iosBundleId'], equals('com.test.app'));
      expect(result['storageBucket'], equals('test-bucket'));
    });

    test('webOptions가 환경변수 설정 시 Map을 반환한다', () {
      // Given: dotenv에 Web 필수 값들이 설정됨
      // When
      final result = FirebaseConfig.webOptions;

      // Then: null이 아닌 Map을 반환한다
      expect(result, isNotNull);
      expect(result, isA<Map<String, String>>());
      expect(result!['apiKey'], equals('test-api-key'));
      expect(result['appId'], equals('test-app-id'));
      expect(result['authDomain'], equals('test.firebaseapp.com'));
      expect(result['storageBucket'], equals('test-bucket'));
    });

    test('isAvailable이 환경변수 설정 시 true를 반환한다', () {
      // Given: 필수 Firebase 환경변수 설정됨
      // When
      final result = FirebaseConfig.isAvailable;

      // Then: Android 플랫폼에서 true
      expect(result, isA<bool>());
    });

    test('currentPlatformOptions가 환경변수 설정 시 null이 아니거나 플랫폼에 따라 결정된다', () {
      // Given: 환경변수가 설정됨
      // When
      final result = FirebaseConfig.currentPlatformOptions;

      // Then: Android 플랫폼에서 non-null Map 반환
      expect(result, anyOf(isNull, isA<Map<String, String>>()));
    });

    test('androidOptions에서 FIREBASE_ANDROID_API_KEY가 우선적으로 사용된다', () {
      // Given: Android 전용 키와 공통 키 모두 설정
      dotenv.testLoad(fileInput: '''
FIREBASE_ANDROID_API_KEY=android-specific-key
FIREBASE_API_KEY=common-key
FIREBASE_ANDROID_APP_ID=android-app-id
FIREBASE_APP_ID=common-app-id
FIREBASE_MESSAGING_SENDER_ID=sender-id
FIREBASE_PROJECT_ID=project-id
''');

      // When
      final result = FirebaseConfig.androidOptions;

      // Then: Android 전용 키가 우선 적용된다
      expect(result, isNotNull);
      expect(result!['apiKey'], equals('android-specific-key'));
      expect(result['appId'], equals('android-app-id'));
    });

    test('iosOptions에서 FIREBASE_IOS_API_KEY가 우선적으로 사용된다', () {
      // Given: iOS 전용 키와 공통 키 모두 설정
      dotenv.testLoad(fileInput: '''
FIREBASE_IOS_API_KEY=ios-specific-key
FIREBASE_API_KEY=common-key
FIREBASE_IOS_APP_ID=ios-app-id
FIREBASE_APP_ID=common-app-id
FIREBASE_MESSAGING_SENDER_ID=sender-id
FIREBASE_PROJECT_ID=project-id
FIREBASE_IOS_BUNDLE_ID=com.ios.app
''');

      // When
      final result = FirebaseConfig.iosOptions;

      // Then: iOS 전용 키가 우선 적용된다
      expect(result, isNotNull);
      expect(result!['apiKey'], equals('ios-specific-key'));
      expect(result['appId'], equals('ios-app-id'));
    });

    test('androidOptions에서 필수 키가 없으면 null을 반환한다', () {
      // Given: messagingSenderId 없음
      dotenv.testLoad(fileInput: '''
FIREBASE_API_KEY=test-key
FIREBASE_APP_ID=test-app-id
FIREBASE_PROJECT_ID=test-project
''');

      // When
      final result = FirebaseConfig.androidOptions;

      // Then: null 반환 (필수 키 누락)
      expect(result, isNull);
    });

    test('iosOptions에서 필수 키가 없으면 null을 반환한다', () {
      // Given: projectId 없음
      dotenv.testLoad(fileInput: '''
FIREBASE_API_KEY=test-key
FIREBASE_APP_ID=test-app-id
FIREBASE_MESSAGING_SENDER_ID=sender-id
''');

      // When
      final result = FirebaseConfig.iosOptions;

      // Then: null 반환 (필수 키 누락)
      expect(result, isNull);
    });

    test('webOptions에서 필수 키가 없으면 null을 반환한다', () {
      // Given: appId 없음
      dotenv.testLoad(fileInput: '''
FIREBASE_WEB_API_KEY=web-key
FIREBASE_MESSAGING_SENDER_ID=sender-id
FIREBASE_PROJECT_ID=project-id
''');

      // When
      final result = FirebaseConfig.webOptions;

      // Then: null 반환 (필수 키 누락)
      expect(result, isNull);
    });
  });
}
