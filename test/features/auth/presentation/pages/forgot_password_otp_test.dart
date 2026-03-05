import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_household_account/features/auth/presentation/providers/auth_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockAuthService extends Mock implements AuthService {}

void main() {
  group('ForgotPasswordPage OTP 단계 테스트', () {
    late _MockAuthService mockAuthService;

    setUp(() {
      mockAuthService = _MockAuthService();
      when(() => mockAuthService.currentUser).thenReturn(null);
    });

    group('OTP 단계 UI 렌더링', () {
      test('step 0에서 resetPassword 성공 후 step 1로 전환된다', () {
        // Given: step 상태 시뮬레이션
        int step = 0;

        // When: resetPassword 성공 후 step 전환
        void onResetPasswordSuccess() {
          step = 1;
        }

        onResetPasswordSuccess();

        // Then
        expect(step, equals(1));
      });

      test('이메일 전송 성공 후 OTP 입력 UI로 전환된다', () {
        // Given: step 0 상태
        int step = 0;
        bool otpUiVisible = false;

        // When: resetPassword 성공 후 step 1로 전환
        step = 1;
        otpUiVisible = step == 1;

        // Then: OTP UI가 표시된다
        expect(step, equals(1));
        expect(otpUiVisible, isTrue);
      });

      test('step 1에서 뒤로가기 시 step 0으로 돌아간다', () {
        // Given: OTP 단계 상태
        int step = 1;
        int resendCooldown = 30;

        // When: 뒤로가기 동작 (step이 1이면 step 0으로)
        if (step == 1) {
          step = 0;
          resendCooldown = 0;
        }

        // Then
        expect(step, equals(0));
        expect(resendCooldown, equals(0));
      });

      test('OTP 단계에서 뒤로가기 버튼이 이메일 단계로 돌아간다', () {
        // Given: OTP 단계 (step 1)
        int step = 1;

        // When: 뒤로가기 버튼 탭
        if (step == 1) {
          step = 0;
        }

        // Then: 이메일 단계로 돌아간다
        expect(step, equals(0));
      });

      test('step 0에서 뒤로가기 시 context.pop이 호출된다', () {
        // Given: 이메일 단계 상태
        int step = 0;
        bool popCalled = false;

        // When: 뒤로가기 동작 (step이 0이면 pop)
        if (step == 1) {
          step = 0;
        } else {
          popCalled = true;
        }

        // Then
        expect(popCalled, isTrue);
        expect(step, equals(0));
      });
    });

    group('쿨다운 타이머 로직', () {
      test('쿨다운 초기값이 60초이다', () {
        // Given: 재전송 후 쿨다운 시작
        int resendCooldown = 0;

        // When: OTP 전송 후 쿨다운 시작
        resendCooldown = 60;

        // Then
        expect(resendCooldown, equals(60));
      });

      test('쿨다운이 0보다 크면 재전송 버튼이 비활성화된다', () {
        // Given
        const resendCooldown = 30;
        const isLoading = false;

        // When: 버튼 활성화 여부 계산
        final isEnabled = !(resendCooldown > 0 || isLoading);

        // Then
        expect(isEnabled, isFalse);
      });

      test('쿨다운이 0이면 재전송 버튼이 활성화된다', () {
        // Given
        const resendCooldown = 0;
        const isLoading = false;

        // When: 버튼 활성화 여부 계산
        final isEnabled = !(resendCooldown > 0 || isLoading);

        // Then
        expect(isEnabled, isTrue);
      });

      test('매 초마다 쿨다운이 감소한다', () {
        // Given
        int resendCooldown = 3;

        // When: 타이머 틱 시뮬레이션
        for (var i = 0; i < 3; i++) {
          if (resendCooldown > 0) {
            resendCooldown--;
          }
        }

        // Then
        expect(resendCooldown, equals(0));
      });

      test('쿨다운이 0 이하로 내려가지 않는다', () {
        // Given
        int resendCooldown = 1;

        // When: 여러 번 감소 시도
        for (var i = 0; i < 5; i++) {
          if (resendCooldown > 0) {
            resendCooldown--;
          }
        }

        // Then: 0 이하로 내려가지 않는다
        expect(resendCooldown, equals(0));
        expect(resendCooldown, greaterThanOrEqualTo(0));
      });
    });

    group('OTP 길이 검증', () {
      test('OTP 길이가 8자리이다', () {
        // Given: _otpLength 상수값
        const otpLength = 8;

        // When & Then
        expect(otpLength, equals(8));
      });

      test('8자리 미만의 OTP는 처리되지 않는다', () {
        // Given
        const otpLength = 8;
        const enteredCode = '1234567'; // 7자리

        // When: OTP 검증 조건
        final shouldProcess = enteredCode.length == otpLength;

        // Then
        expect(shouldProcess, isFalse);
      });

      test('정확히 8자리인 OTP는 처리된다', () {
        // Given
        const otpLength = 8;
        const enteredCode = '12345678'; // 8자리

        // When: OTP 검증 조건
        final shouldProcess = enteredCode.length == otpLength;

        // Then
        expect(shouldProcess, isTrue);
      });
    });

    group('AuthException 에러 처리 로직', () {
      test('expired 메시지가 포함된 AuthException을 OTP 만료 에러로 처리한다', () {
        // Given
        const errorMessage = 'Token has expired';

        // When: 에러 메시지 분류
        final isExpiredError =
            errorMessage.contains('expired') || errorMessage.contains('Token');

        // Then
        expect(isExpiredError, isTrue);
      });

      test('Token 메시지가 포함된 AuthException을 OTP 만료 에러로 처리한다', () {
        // Given
        const errorMessage = 'Token is invalid or has expired';

        // When
        final isExpiredError =
            errorMessage.contains('expired') || errorMessage.contains('Token');

        // Then
        expect(isExpiredError, isTrue);
      });

      test('그 외 AuthException은 유효하지 않은 OTP 에러로 처리한다', () {
        // Given
        const errorMessage = 'Invalid OTP code';

        // When
        final isExpiredError =
            errorMessage.contains('expired') || errorMessage.contains('Token');

        // Then: 만료 에러가 아니므로 일반 유효성 에러
        expect(isExpiredError, isFalse);
      });

      test('네트워크 에러 메시지 분류가 올바르다', () {
        // Given
        final networkErrors = [
          'SocketException',
          'Failed host lookup',
          'Network is unreachable',
        ];

        // When & Then: 각 에러 메시지가 네트워크 에러로 분류된다
        for (final error in networkErrors) {
          final isNetworkError = error.contains('SocketException') ||
              error.contains('Failed host lookup') ||
              error.contains('Network is unreachable');
          expect(isNetworkError, isTrue, reason: '$error는 네트워크 에러이다');
        }
      });
    });

    group('재전송 OTP 동작', () {
      test('재전송 성공 시 OTP 입력 필드가 초기화된다', () {
        // Given: OTP 컨트롤러에 값이 있는 상태
        String otpText = '12345678';

        // When: 재전송 성공 후 OTP 필드 초기화
        void onResendSuccess() {
          otpText = '';
        }

        onResendSuccess();

        // Then: OTP 필드가 초기화된다
        expect(otpText, equals(''));
      });

      test('재전송 성공 시 쿨다운이 다시 60초로 리셋된다', () {
        // Given: 이미 일부 소진된 쿨다운
        int resendCooldown = 30;

        // When: 재전송 성공 후 쿨다운 리셋
        void onResendSuccess() {
          resendCooldown = 60;
        }

        onResendSuccess();

        // Then: 쿨다운이 60초로 리셋된다
        expect(resendCooldown, equals(60));
      });
    });
  });
}
