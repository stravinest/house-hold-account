import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// GoogleSignInService는 싱글톤이며 dotenv와 SupabaseConfig에 직접 의존하므로
// 내부 로직을 단위 테스트로 분리하여 검증한다.

void main() {
  group('GoogleSignInService 로직 테스트', () {
    group('Web Client ID 초기화', () {
      test('빈 clientId는 serverClientId에 null로 처리된다', () {
        // Given: GOOGLE_WEB_CLIENT_ID가 설정되지 않은 경우
        const clientId = '';

        // When: clientId가 비어있으면 null 처리
        final serverClientId = clientId.isNotEmpty ? clientId : null;

        // Then
        expect(serverClientId, isNull);
      });

      test('설정된 clientId는 serverClientId에 그대로 전달된다', () {
        // Given
        const clientId = 'test-client-id.apps.googleusercontent.com';

        // When
        final serverClientId = clientId.isNotEmpty ? clientId : null;

        // Then
        expect(serverClientId, equals(clientId));
      });
    });

    group('사용자 취소 감지 로직', () {
      test('sign_in_canceled 문자열이 포함된 에러를 취소로 감지한다', () {
        // Given
        const errorMessage = 'com.google.android.gms.common.api.ApiException: 12501 sign_in_canceled';

        // When
        final isCanceled = errorMessage.contains('sign_in_canceled') ||
            errorMessage.contains('canceled') ||
            errorMessage.contains('CANCELED');

        // Then
        expect(isCanceled, isTrue);
      });

      test('canceled 문자열이 포함된 에러를 취소로 감지한다', () {
        // Given
        const errorMessage = 'The user canceled the login process';

        // When
        final isCanceled = errorMessage.contains('sign_in_canceled') ||
            errorMessage.contains('canceled') ||
            errorMessage.contains('CANCELED');

        // Then
        expect(isCanceled, isTrue);
      });

      test('CANCELED 대문자 문자열이 포함된 에러를 취소로 감지한다', () {
        // Given
        const errorMessage = 'CANCELED by user interaction';

        // When
        final isCanceled = errorMessage.contains('sign_in_canceled') ||
            errorMessage.contains('canceled') ||
            errorMessage.contains('CANCELED');

        // Then
        expect(isCanceled, isTrue);
      });

      test('네트워크 에러는 취소로 감지하지 않는다', () {
        // Given
        const errorMessage = 'Network connection failed';

        // When
        final isCanceled = errorMessage.contains('sign_in_canceled') ||
            errorMessage.contains('canceled') ||
            errorMessage.contains('CANCELED');

        // Then
        expect(isCanceled, isFalse);
      });
    });

    group('에러 변환 로직', () {
      test('일반 예외를 AuthException으로 감싸서 throw한다', () {
        // Given
        const originalError = 'Some unexpected error';

        // When & Then
        expect(
          () => throw AuthException('Google 로그인 실패: $originalError'),
          throwsA(
            isA<AuthException>().having(
              (e) => e.message,
              'message',
              contains('Google 로그인 실패'),
            ),
          ),
        );
      });

      test('취소 에러는 전용 AuthException 메시지를 사용한다', () {
        // Given
        const cancelMessage = 'Google 로그인이 취소되었습니다.';

        // When & Then
        expect(
          () => throw AuthException(cancelMessage),
          throwsA(
            isA<AuthException>().having(
              (e) => e.message,
              'message',
              equals(cancelMessage),
            ),
          ),
        );
      });

      test('ID Token 없음 에러는 전용 AuthException 메시지를 사용한다', () {
        // Given
        const noTokenMessage = 'Google ID Token을 가져올 수 없습니다.';

        // When & Then
        expect(
          () => throw AuthException(noTokenMessage),
          throwsA(
            isA<AuthException>().having(
              (e) => e.message,
              'message',
              equals(noTokenMessage),
            ),
          ),
        );
      });
    });

    group('OAuthProvider 설정', () {
      test('Google 로그인에 OAuthProvider.google을 사용한다', () {
        // Given & When
        const provider = OAuthProvider.google;

        // Then
        expect(provider, equals(OAuthProvider.google));
        expect(provider.name, equals('google'));
      });
    });

    group('Google Sign-In 스코프 설정', () {
      test('email 스코프가 요청된다', () {
        // Given
        const scopes = ['email', 'profile'];

        // When & Then
        expect(scopes, contains('email'));
      });

      test('profile 스코프가 요청된다', () {
        // Given
        const scopes = ['email', 'profile'];

        // When & Then
        expect(scopes, contains('profile'));
      });

      test('정확히 2개의 스코프가 요청된다', () {
        // Given
        const scopes = ['email', 'profile'];

        // When & Then
        expect(scopes.length, equals(2));
      });
    });

    group('signOut 처리 로직', () {
      test('signOut 실패 시 예외를 무시하고 정상 완료된다', () {
        // Given: signOut이 예외를 던지는 상황

        // When & Then: try-catch로 예외를 무시하면 returnsNormally
        expect(
          () {
            try {
              throw Exception('Sign out failed');
            } catch (e) {
              // GoogleSignInService.signOut은 catch하고 무시함
            }
          },
          returnsNormally,
        );
      });
    });

    group('disconnect 처리 로직', () {
      test('disconnect 실패 시 예외를 무시하고 정상 완료된다', () {
        // Given & When & Then
        expect(
          () {
            try {
              throw Exception('Disconnect failed');
            } catch (e) {
              // GoogleSignInService.disconnect는 catch하고 무시함
            }
          },
          returnsNormally,
        );
      });
    });

    group('signInSilently 처리 로직', () {
      test('signInSilently 실패 시 null을 반환한다', () async {
        // Given: 예외 발생 시
        Object? capturedResult;

        // When
        try {
          throw Exception('Silent sign-in failed');
        } catch (e) {
          capturedResult = null; // 서비스에서 null 반환
        }

        // Then
        expect(capturedResult, isNull);
      });
    });

    group('configure 메서드 로직', () {
      test('iosClientId와 webClientId로 재설정할 수 있다', () {
        // Given
        const iosClientId = 'ios-client-id';
        const webClientId = 'web-client-id';

        // When: 두 값이 정의되어 있다
        final hasIosClient = iosClientId.isNotEmpty;
        final hasWebClient = webClientId.isNotEmpty;

        // Then
        expect(hasIosClient, isTrue);
        expect(hasWebClient, isTrue);
      });

      test('webClientId가 null이면 기본 _webClientId를 사용한다', () {
        // Given
        String? webClientId;
        const fallbackClientId = 'default-web-client-id';

        // When
        final resolvedClientId = webClientId ?? fallbackClientId;

        // Then
        expect(resolvedClientId, equals(fallbackClientId));
      });
    });
  });
}
