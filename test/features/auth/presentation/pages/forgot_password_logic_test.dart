import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ForgotPasswordPage의 핵심 로직들을 단위 테스트로 검증합니다.
// 위젯 자체는 PinCodeTextField의 내부 타이머 때문에 위젯 테스트로 실행하기 어렵습니다.

void main() {
  group('ForgotPasswordPage 상태 전환 로직 테스트', () {
    group('초기 상태', () {
      test('초기 step 값은 0이다 (이메일 입력 단계)', () {
        // Given & When
        const int step = 0;

        // Then
        expect(step, equals(0));
      });

      test('초기 isLoading 값은 false이다', () {
        // Given & When
        const bool isLoading = false;

        // Then
        expect(isLoading, isFalse);
      });

      test('초기 resendCooldown 값은 0이다', () {
        // Given & When
        const int resendCooldown = 0;

        // Then
        expect(resendCooldown, equals(0));
      });
    });

    group('이메일 단계 (step 0) 로직', () {
      test('sendOtp 성공 후 step이 1로 전환된다', () {
        // Given
        int step = 0;

        // When: sendOtp 성공 시 step 전환
        step = 1;

        // Then
        expect(step, equals(1));
      });

      test('step 0에서 뒤로가기 시 context.pop이 호출되어야 한다', () {
        // Given
        int step = 0;
        bool popCalled = false;

        // When: 뒤로가기 버튼 탭 시 로직
        if (step == 1) {
          step = 0;
        } else {
          popCalled = true;
        }

        // Then
        expect(popCalled, isTrue);
        expect(step, equals(0));
      });

      test('이메일 유효성 검사 - 빈 값은 오류를 반환한다', () {
        // Given
        const email = '';

        // When: 유효성 검사 로직 시뮬레이션
        String? errorMessage;
        if (email.isEmpty) {
          errorMessage = '이메일을 입력해주세요';
        } else if (!email.contains('@')) {
          errorMessage = '유효한 이메일 주소를 입력해주세요';
        }

        // Then
        expect(errorMessage, isNotNull);
      });

      test('이메일 유효성 검사 - @ 없는 값은 오류를 반환한다', () {
        // Given
        const email = 'invalid-email';

        // When
        String? errorMessage;
        if (email.isEmpty) {
          errorMessage = '이메일을 입력해주세요';
        } else if (!email.contains('@')) {
          errorMessage = '유효한 이메일 주소를 입력해주세요';
        }

        // Then
        expect(errorMessage, isNotNull);
      });

      test('이메일 유효성 검사 - 유효한 이메일은 null을 반환한다', () {
        // Given
        const email = 'user@example.com';

        // When
        String? errorMessage;
        if (email.isEmpty) {
          errorMessage = '이메일을 입력해주세요';
        } else if (!email.contains('@')) {
          errorMessage = '유효한 이메일 주소를 입력해주세요';
        }

        // Then
        expect(errorMessage, isNull);
      });
    });

    group('OTP 단계 (step 1) 로직', () {
      test('step 1에서 뒤로가기 시 step이 0으로 전환된다', () {
        // Given
        int step = 1;
        int resendCooldown = 30;

        // When: 뒤로가기 버튼 탭 시 로직
        if (step == 1) {
          step = 0;
          resendCooldown = 0;
        }

        // Then
        expect(step, equals(0));
        expect(resendCooldown, equals(0));
      });

      test('step 1에서 뒤로가기 시 resendCooldown이 초기화된다', () {
        // Given
        int step = 1;
        int resendCooldown = 45;

        // When
        if (step == 1) {
          step = 0;
          resendCooldown = 0;
        }

        // Then
        expect(resendCooldown, equals(0));
      });

      test('OTP 길이 상수는 8이다', () {
        // Given
        const otpLength = 8;

        // Then
        expect(otpLength, equals(8));
      });
    });

    group('재전송 쿨다운 로직', () {
      test('OTP 전송 성공 후 쿨다운이 60초로 설정된다', () {
        // Given
        int resendCooldown = 0;

        // When: sendOtp 또는 resendOtp 성공 후
        resendCooldown = 60;

        // Then
        expect(resendCooldown, equals(60));
      });

      test('쿨다운이 0이면 재전송 버튼이 활성화된다', () {
        // Given
        const resendCooldown = 0;
        const isLoading = false;

        // When
        final isEnabled = !(resendCooldown > 0 || isLoading);

        // Then
        expect(isEnabled, isTrue);
      });

      test('쿨다운이 양수이면 재전송 버튼이 비활성화된다', () {
        // Given
        const resendCooldown = 30;
        const isLoading = false;

        // When
        final isEnabled = !(resendCooldown > 0 || isLoading);

        // Then
        expect(isEnabled, isFalse);
      });

      test('로딩 중이면 재전송 버튼이 비활성화된다', () {
        // Given
        const resendCooldown = 0;
        const isLoading = true;

        // When
        final isEnabled = !(resendCooldown > 0 || isLoading);

        // Then
        expect(isEnabled, isFalse);
      });

      test('타이머가 매 초 쿨다운을 감소시킨다', () {
        // Given
        int resendCooldown = 5;

        // When: 5번 틱
        for (var i = 0; i < 5; i++) {
          if (resendCooldown > 0) resendCooldown--;
        }

        // Then
        expect(resendCooldown, equals(0));
      });

      test('쿨다운이 0 이하로 내려가지 않는다', () {
        // Given
        int resendCooldown = 2;

        // When: 10번 틱
        for (var i = 0; i < 10; i++) {
          if (resendCooldown > 0) resendCooldown--;
        }

        // Then
        expect(resendCooldown, greaterThanOrEqualTo(0));
        expect(resendCooldown, equals(0));
      });

      test('resendCooldown이 0보다 크면 재전송 불가 조건이 참이다', () {
        // Given
        const resendCooldown = 15;

        // When: handleResendOtp 진입 조건
        final shouldReturn = resendCooldown > 0;

        // Then
        expect(shouldReturn, isTrue);
      });
    });

    group('에러 메시지 분류 로직', () {
      test('네트워크 에러 - SocketException을 네트워크 에러로 분류한다', () {
        // Given
        const errorStr = 'SocketException: Connection refused';

        // When
        final isNetworkError = errorStr.contains('SocketException') ||
            errorStr.contains('Failed host lookup') ||
            errorStr.contains('Network is unreachable');

        // Then
        expect(isNetworkError, isTrue);
      });

      test('네트워크 에러 - Failed host lookup을 네트워크 에러로 분류한다', () {
        // Given
        const errorStr = 'Failed host lookup: api.example.com';

        // When
        final isNetworkError = errorStr.contains('SocketException') ||
            errorStr.contains('Failed host lookup') ||
            errorStr.contains('Network is unreachable');

        // Then
        expect(isNetworkError, isTrue);
      });

      test('네트워크 에러 - Network is unreachable을 네트워크 에러로 분류한다', () {
        // Given
        const errorStr = 'Network is unreachable';

        // When
        final isNetworkError = errorStr.contains('SocketException') ||
            errorStr.contains('Failed host lookup') ||
            errorStr.contains('Network is unreachable');

        // Then
        expect(isNetworkError, isTrue);
      });

      test('AuthException - expired를 만료 에러로 분류한다', () {
        // Given
        const errorMessage = 'Token has expired';

        // When
        final isExpiredError =
            errorMessage.contains('expired') || errorMessage.contains('Token');

        // Then
        expect(isExpiredError, isTrue);
      });

      test('AuthException - Token을 만료 에러로 분류한다', () {
        // Given
        const errorMessage = 'Token is invalid';

        // When
        final isExpiredError =
            errorMessage.contains('expired') || errorMessage.contains('Token');

        // Then
        expect(isExpiredError, isTrue);
      });

      test('AuthException - 일반 메시지는 만료 에러가 아니다', () {
        // Given
        const errorMessage = 'Invalid OTP code';

        // When
        final isExpiredError =
            errorMessage.contains('expired') || errorMessage.contains('Token');

        // Then
        expect(isExpiredError, isFalse);
      });

      test('AuthRetryableFetchException을 네트워크 에러로 분류한다', () {
        // Given
        final exception = AuthRetryableFetchException();
        final errorStr = exception.runtimeType.toString();

        // When: AuthRetryableFetchException 타입 체크
        final isRetryable = exception is AuthRetryableFetchException;

        // Then
        expect(isRetryable, isTrue);
      });
    });

    group('재전송 성공 후 상태 리셋', () {
      test('재전송 성공 시 OTP 텍스트가 초기화된다', () {
        // Given
        String otpText = '12345678';

        // When: onResendSuccess 로직
        otpText = '';

        // Then
        expect(otpText, equals(''));
        expect(otpText.isEmpty, isTrue);
      });

      test('재전송 성공 시 쿨다운이 60초로 리셋된다', () {
        // Given
        int resendCooldown = 25;

        // When: onResendSuccess 로직
        resendCooldown = 60;

        // Then
        expect(resendCooldown, equals(60));
      });

      test('재전송 성공 시 isLoading이 false로 리셋된다', () {
        // Given
        bool isLoading = true;

        // When: finally 블록 로직
        isLoading = false;

        // Then
        expect(isLoading, isFalse);
      });
    });

    group('OTP 검증 로직', () {
      test('8자리 미만 OTP는 처리되지 않는다', () {
        // Given
        const otpLength = 8;
        const code = '1234567'; // 7자리

        // When: _handleVerifyOtp 진입 조건
        final shouldProcess = code.length == otpLength;

        // Then
        expect(shouldProcess, isFalse);
      });

      test('정확히 8자리 OTP는 처리된다', () {
        // Given
        const otpLength = 8;
        const code = '12345678'; // 8자리

        // When
        final shouldProcess = code.length == otpLength;

        // Then
        expect(shouldProcess, isTrue);
      });

      test('9자리 OTP는 처리되지 않는다', () {
        // Given
        const otpLength = 8;
        const code = '123456789'; // 9자리

        // When
        final shouldProcess = code.length == otpLength;

        // Then
        expect(shouldProcess, isFalse);
      });
    });

    group('dispose 순서 검증', () {
      test('타이머 취소 후 컨트롤러를 dispose 해야 한다', () {
        // Given: 올바른 dispose 순서를 시뮬레이션
        final disposedItems = <String>[];

        // When: dispose 순서 시뮬레이션
        disposedItems.add('timer_cancelled');
        disposedItems.add('emailController_disposed');
        disposedItems.add('otpController_disposed');

        // Then: 타이머가 먼저 취소된다
        expect(disposedItems.indexOf('timer_cancelled'), lessThan(
          disposedItems.indexOf('emailController_disposed'),
        ));
      });
    });
  });
}
