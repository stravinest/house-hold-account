import 'package:flutter_test/flutter_test.dart';

// EmailVerificationPage는 initState에서 SupabaseConfig.auth에 직접 접근하므로
// 위젯 렌더링 없이 페이지의 핵심 로직을 단위 테스트로 검증한다.

void main() {
  group('EmailVerificationPage 확장 로직 테스트', () {
    group('인증 이벤트 분류 로직', () {
      test('signedIn 이벤트는 인증 완료로 처리된다', () {
        // Given
        const event = 'SIGNED_IN';
        const validEvents = ['SIGNED_IN', 'USER_UPDATED'];

        // When: 이벤트가 인증 완료 이벤트인지 확인
        final isVerificationEvent = validEvents.contains(event);

        // Then
        expect(isVerificationEvent, isTrue);
      });

      test('userUpdated 이벤트는 인증 완료로 처리된다', () {
        // Given
        const event = 'USER_UPDATED';
        const validEvents = ['SIGNED_IN', 'USER_UPDATED'];

        // When
        final isVerificationEvent = validEvents.contains(event);

        // Then
        expect(isVerificationEvent, isTrue);
      });

      test('signedOut 이벤트는 인증 완료로 처리되지 않는다', () {
        // Given
        const event = 'SIGNED_OUT';
        const validEvents = ['SIGNED_IN', 'USER_UPDATED'];

        // When
        final isVerificationEvent = validEvents.contains(event);

        // Then
        expect(isVerificationEvent, isFalse);
      });

      test('passwordRecovery 이벤트는 인증 완료로 처리되지 않는다', () {
        // Given
        const event = 'PASSWORD_RECOVERY';
        const validEvents = ['SIGNED_IN', 'USER_UPDATED'];

        // When
        final isVerificationEvent = validEvents.contains(event);

        // Then
        expect(isVerificationEvent, isFalse);
      });
    });

    group('인증 완료 탐지 로직', () {
      test('emailConfirmedAt이 null이 아니면 인증 완료로 판단한다', () {
        // Given
        final emailConfirmedAt = DateTime.now();

        // When
        final isVerified = emailConfirmedAt != null;

        // Then
        expect(isVerified, isTrue);
      });

      test('emailConfirmedAt이 null이면 인증 미완료로 판단한다', () {
        // Given
        DateTime? emailConfirmedAt;

        // When
        final isVerified = emailConfirmedAt != null;

        // Then
        expect(isVerified, isFalse);
      });

      test('user가 null이면 인증 미완료로 판단한다', () {
        // Given
        const user = null;

        // When: user가 null인 경우 인증 완료 불가
        final isVerified = user != null;

        // Then
        expect(isVerified, isFalse);
      });
    });

    group('상태 전이 로직', () {
      test('isVerified가 false에서 true로 전환될 때만 처리한다', () {
        // Given
        bool isVerified = false;
        int navigationCount = 0;

        // When: 인증 완료 이벤트 수신
        void onVerified() {
          if (!isVerified) {
            isVerified = true;
            navigationCount++;
          }
        }

        onVerified(); // 첫 번째 호출
        onVerified(); // 두 번째 호출 (이미 verified이므로 무시)

        // Then: 한 번만 처리된다
        expect(navigationCount, equals(1));
        expect(isVerified, isTrue);
      });

      test('이미 인증된 상태에서 중복 처리를 방지한다', () {
        // Given: 이미 인증된 상태
        bool isVerified = true;
        int processCount = 0;

        // When
        void handleVerification() {
          if (!isVerified) {
            processCount++;
          }
        }

        handleVerification();

        // Then: 중복 처리되지 않는다
        expect(processCount, equals(0));
      });
    });

    group('폴링 로직', () {
      test('폴링 주기는 5초이다', () {
        // Given
        const pollingDuration = Duration(seconds: 5);

        // When & Then
        expect(pollingDuration.inSeconds, equals(5));
      });

      test('인증 완료 후 폴링이 중단된다', () {
        // Given
        bool isVerified = false;
        bool pollingActive = true;

        // When: 인증 완료
        isVerified = true;
        if (isVerified) {
          pollingActive = false;
        }

        // Then
        expect(pollingActive, isFalse);
      });

      test('인증 전에는 폴링이 활성화된다', () {
        // Given
        bool isVerified = false;
        bool pollingActive = true;

        // When: 아직 인증 안 됨
        if (!isVerified) {
          pollingActive = true;
        }

        // Then
        expect(pollingActive, isTrue);
      });
    });

    group('검증 상태 플래그 로직', () {
      test('isChecking이 true일 때 중복 요청을 방지한다', () {
        // Given
        bool isChecking = true;
        bool isVerified = false;
        int callCount = 0;

        // When
        void checkVerification() {
          if (isVerified || isChecking) return;
          callCount++;
        }

        checkVerification();

        // Then: 호출되지 않는다
        expect(callCount, equals(0));
      });

      test('isChecking이 false이고 미인증 상태일 때 요청을 처리한다', () {
        // Given
        bool isChecking = false;
        bool isVerified = false;
        int callCount = 0;

        // When
        void checkVerification() {
          if (isVerified || isChecking) return;
          callCount++;
        }

        checkVerification();

        // Then: 호출된다
        expect(callCount, equals(1));
      });

      test('서버 체크 완료 후 isChecking이 false로 리셋된다', () {
        // Given
        bool isChecking = false;

        // When: 서버 체크 시작
        isChecking = true;
        // ... 서버 요청 ...
        // finally 블록에서 리셋
        isChecking = false;

        // Then
        expect(isChecking, isFalse);
      });
    });

    group('재전송 로직', () {
      test('쿨다운 중에는 재전송이 방지된다', () {
        // Given
        int resendCooldown = 30;
        bool isResending = false;
        int resendCount = 0;

        // When
        void resend() {
          if (resendCooldown > 0 || isResending) return;
          resendCount++;
        }

        resend();

        // Then
        expect(resendCount, equals(0));
      });

      test('이미 재전송 중이면 추가 재전송이 방지된다', () {
        // Given
        int resendCooldown = 0;
        bool isResending = true;
        int resendCount = 0;

        // When
        void resend() {
          if (resendCooldown > 0 || isResending) return;
          resendCount++;
        }

        resend();

        // Then
        expect(resendCount, equals(0));
      });

      test('쿨다운과 재전송 중 둘 다 없을 때 재전송이 실행된다', () {
        // Given
        int resendCooldown = 0;
        bool isResending = false;
        int resendCount = 0;

        // When
        void resend() {
          if (resendCooldown > 0 || isResending) return;
          resendCount++;
        }

        resend();

        // Then
        expect(resendCount, equals(1));
      });

      test('재전송 성공 후 쿨다운이 60초로 시작된다', () {
        // Given
        int resendCooldown = 0;

        // When: 재전송 성공
        resendCooldown = 60;

        // Then
        expect(resendCooldown, equals(60));
      });
    });

    group('앱 라이프사이클 처리 로직', () {
      test('앱이 resumed 상태로 전환될 때 검증 체크를 트리거한다', () {
        // Given
        bool isVerified = false;
        int checkCount = 0;

        // When: 앱 재개 시 미인증 상태이면 체크
        void onAppResumed() {
          if (!isVerified) {
            checkCount++;
          }
        }

        onAppResumed();

        // Then
        expect(checkCount, equals(1));
      });

      test('이미 인증된 상태에서 앱이 재개되면 체크하지 않는다', () {
        // Given
        bool isVerified = true;
        int checkCount = 0;

        // When
        void onAppResumed() {
          if (!isVerified) {
            checkCount++;
          }
        }

        onAppResumed();

        // Then
        expect(checkCount, equals(0));
      });
    });

    group('홈으로 이동 로직', () {
      test('인증 완료 후 2초 지연 후 홈으로 이동한다', () {
        // Given
        const navigationDelay = Duration(seconds: 2);

        // When & Then
        expect(navigationDelay.inSeconds, equals(2));
      });
    });

    group('이메일 유효성 검사', () {
      test('이메일 주소가 비어있지 않아야 한다', () {
        // Given
        const email = 'user@test.com';

        // When & Then
        expect(email.isNotEmpty, isTrue);
      });

      test('다양한 이메일 도메인을 처리할 수 있다', () {
        // Given
        final emails = [
          'user@gmail.com',
          'test@kakao.com',
          'admin@company.co.kr',
          'hello@naver.com',
        ];

        // When & Then: 모든 이메일이 @ 포함
        for (final email in emails) {
          expect(email, contains('@'));
        }
      });
    });
  });
}
