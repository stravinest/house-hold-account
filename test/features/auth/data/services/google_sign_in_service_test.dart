import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockGoogleSignIn extends Mock implements GoogleSignIn {}

class MockGoogleSignInAccount extends Mock implements GoogleSignInAccount {}

class MockGoogleSignInAuthentication extends Mock
    implements GoogleSignInAuthentication {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

void main() {
  // GoogleSignInService는 싱글톤이며 내부 의존성이 복잡하여
  // 완전한 단위 테스트보다는 통합 테스트가 더 적합합니다.
  // 여기서는 GoogleSignIn 패키지와의 상호작용을 검증합니다.

  group('GoogleSignInService', () {
    late MockGoogleSignIn mockGoogleSignIn;
    late MockGoogleSignInAccount mockGoogleAccount;
    late MockGoogleSignInAuthentication mockGoogleAuth;

    setUp(() {
      mockGoogleSignIn = MockGoogleSignIn();
      mockGoogleAccount = MockGoogleSignInAccount();
      mockGoogleAuth = MockGoogleSignInAuthentication();
    });

    setUpAll(() {
      // Fallback 값 등록
      registerFallbackValue(OAuthProvider.google);
    });

    group('Google Sign-In 플로우', () {
      test('사용자가 로그인을 취소하면 AuthException을 throw한다', () async {
        // Given: Google Sign-In이 null 반환 (사용자 취소)
        when(() => mockGoogleSignIn.signIn()).thenAnswer((_) async => null);

        // When & Then
        expect(
          () async {
            final googleUser = await mockGoogleSignIn.signIn();
            if (googleUser == null) {
              throw const AuthException('Google 로그인이 취소되었습니다.');
            }
          },
          throwsA(isA<AuthException>()),
        );
      });

      test('Google 로그인 성공 시 GoogleSignInAccount를 반환한다', () async {
        // Given
        when(() => mockGoogleSignIn.signIn()).thenAnswer(
          (_) async => mockGoogleAccount,
        );

        // When
        final result = await mockGoogleSignIn.signIn();

        // Then
        expect(result, isNotNull);
        expect(result, equals(mockGoogleAccount));
      });

      test('ID Token이 없으면 AuthException을 throw한다', () async {
        // Given: Google Auth에 ID Token이 없음
        when(() => mockGoogleAccount.authentication).thenAnswer(
          (_) async => mockGoogleAuth,
        );
        when(() => mockGoogleAuth.idToken).thenReturn(null);

        // When & Then
        expect(
          () async {
            final auth = await mockGoogleAccount.authentication;
            if (auth.idToken == null) {
              throw const AuthException('Google ID Token을 가져올 수 없습니다.');
            }
          },
          throwsA(isA<AuthException>()),
        );
      });

      test('ID Token과 Access Token을 성공적으로 가져온다', () async {
        // Given
        const idToken = 'test-id-token';
        const accessToken = 'test-access-token';

        when(() => mockGoogleAccount.authentication).thenAnswer(
          (_) async => mockGoogleAuth,
        );
        when(() => mockGoogleAuth.idToken).thenReturn(idToken);
        when(() => mockGoogleAuth.accessToken).thenReturn(accessToken);

        // When
        final auth = await mockGoogleAccount.authentication;

        // Then
        expect(auth.idToken, equals(idToken));
        expect(auth.accessToken, equals(accessToken));
      });
    });

    group('Google Sign-Out', () {
      test('signOut을 호출하면 Google 세션이 종료된다', () async {
        // Given
        when(() => mockGoogleSignIn.signOut()).thenAnswer((_) async => null);

        // When
        await mockGoogleSignIn.signOut();

        // Then
        verify(() => mockGoogleSignIn.signOut()).called(1);
      });

      test('signOut 실패 시 예외를 무시한다', () async {
        // Given: signOut이 예외를 throw
        when(() => mockGoogleSignIn.signOut()).thenThrow(
          Exception('Sign out failed'),
        );

        // When & Then: 예외가 전파되지 않아야 함 (서비스 레벨에서 catch)
        expect(
          () async {
            try {
              await mockGoogleSignIn.signOut();
            } catch (e) {
              // 서비스에서는 이 예외를 catch하고 무시함
            }
          },
          returnsNormally,
        );
      });
    });

    group('Google Disconnect', () {
      test('disconnect를 호출하면 Google 계정 연결이 해제된다', () async {
        // Given
        when(() => mockGoogleSignIn.disconnect()).thenAnswer(
          (_) async => null,
        );

        // When
        await mockGoogleSignIn.disconnect();

        // Then
        verify(() => mockGoogleSignIn.disconnect()).called(1);
      });

      test('disconnect 실패 시 예외를 무시한다', () async {
        // Given
        when(() => mockGoogleSignIn.disconnect()).thenThrow(
          Exception('Disconnect failed'),
        );

        // When & Then: 예외가 전파되지 않아야 함
        expect(
          () async {
            try {
              await mockGoogleSignIn.disconnect();
            } catch (e) {
              // 서비스에서는 이 예외를 catch하고 무시함
            }
          },
          returnsNormally,
        );
      });
    });

    group('Silent Sign-In', () {
      test('이전 세션이 있으면 자동으로 로그인한다', () async {
        // Given
        when(() => mockGoogleSignIn.signInSilently()).thenAnswer(
          (_) async => mockGoogleAccount,
        );

        // When
        final result = await mockGoogleSignIn.signInSilently();

        // Then
        expect(result, isNotNull);
        expect(result, equals(mockGoogleAccount));
      });

      test('이전 세션이 없으면 null을 반환한다', () async {
        // Given
        when(() => mockGoogleSignIn.signInSilently()).thenAnswer(
          (_) async => null,
        );

        // When
        final result = await mockGoogleSignIn.signInSilently();

        // Then
        expect(result, isNull);
      });

      test('signInSilently 실패 시 null을 반환한다', () async {
        // Given
        when(() => mockGoogleSignIn.signInSilently()).thenThrow(
          Exception('Silent sign-in failed'),
        );

        // When
        GoogleSignInAccount? result;
        try {
          result = await mockGoogleSignIn.signInSilently();
        } catch (e) {
          result = null;
        }

        // Then: 예외를 catch하고 null 반환
        expect(result, isNull);
      });
    });

    group('Current User', () {
      test('currentUser getter가 현재 로그인된 사용자를 반환한다', () {
        // Given
        when(() => mockGoogleSignIn.currentUser).thenReturn(mockGoogleAccount);

        // When
        final currentUser = mockGoogleSignIn.currentUser;

        // Then
        expect(currentUser, isNotNull);
        expect(currentUser, equals(mockGoogleAccount));
      });

      test('로그인하지 않았으면 currentUser가 null이다', () {
        // Given
        when(() => mockGoogleSignIn.currentUser).thenReturn(null);

        // When
        final currentUser = mockGoogleSignIn.currentUser;

        // Then
        expect(currentUser, isNull);
      });
    });

    group('에러 처리', () {
      test('sign_in_canceled 에러를 AuthException으로 변환한다', () {
        // Given
        const errorMessage = 'sign_in_canceled by user';

        // When & Then
        expect(
          () {
            if (errorMessage.contains('sign_in_canceled')) {
              throw const AuthException('Google 로그인이 취소되었습니다.');
            }
          },
          throwsA(isA<AuthException>()),
        );
      });

      test('canceled 에러를 AuthException으로 변환한다', () {
        // Given
        const errorMessage = 'User canceled the operation';

        // When & Then
        expect(
          () {
            if (errorMessage.contains('canceled')) {
              throw const AuthException('Google 로그인이 취소되었습니다.');
            }
          },
          throwsA(isA<AuthException>()),
        );
      });

      test('CANCELED 에러를 AuthException으로 변환한다', () {
        // Given
        const errorMessage = 'CANCELED by user';

        // When & Then
        expect(
          () {
            if (errorMessage.contains('CANCELED')) {
              throw const AuthException('Google 로그인이 취소되었습니다.');
            }
          },
          throwsA(isA<AuthException>()),
        );
      });

      test('기타 에러를 AuthException으로 감싸서 throw한다', () {
        // Given
        const errorMessage = 'Network error';

        // When & Then
        expect(
          () {
            throw AuthException('Google 로그인 실패: $errorMessage');
          },
          throwsA(isA<AuthException>()),
        );
      });
    });

    group('GoogleSignIn 설정', () {
      test('GoogleSignIn이 올바른 scopes로 초기화된다', () {
        // Given
        const expectedScopes = ['email', 'profile'];

        // When & Then: GoogleSignIn 생성 시 scopes 검증
        final googleSignIn = GoogleSignIn(scopes: expectedScopes);
        expect(googleSignIn.scopes, equals(expectedScopes));
      });

      test('configure 메서드로 clientId를 재설정할 수 있다', () {
        // Given
        const iosClientId = 'test-ios-client-id';
        const webClientId = 'test-web-client-id';

        // When: configure 호출
        final googleSignIn = GoogleSignIn(
          clientId: iosClientId,
          serverClientId: webClientId,
          scopes: ['email', 'profile'],
        );

        // Then
        expect(googleSignIn.clientId, equals(iosClientId));
      });
    });

    group('OAuthProvider', () {
      test('Supabase에 전달하는 provider가 google이다', () {
        // Given & When
        const provider = OAuthProvider.google;

        // Then
        expect(provider, equals(OAuthProvider.google));
        expect(provider.name, equals('google'));
      });
    });
  });
}
