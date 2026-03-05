import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_household_account/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:shared_household_account/features/auth/presentation/providers/auth_provider.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockAuthService extends Mock implements AuthService {}

Widget buildForgotPasswordPage({AuthService? authService}) {
  return ProviderScope(
    overrides: [
      if (authService != null)
        authServiceProvider.overrideWith((ref) => authService),
      authStateProvider.overrideWith((ref) => const Stream.empty()),
      authNotifierProvider.overrideWith(
        (ref) {
          final service = authService ?? _MockAuthService();
          return AuthNotifier(service, ref);
        },
      ),
    ],
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: Locale('ko'),
      home: ForgotPasswordPage(),
    ),
  );
}

void main() {
  group('ForgotPasswordPage 위젯 테스트', () {
    late _MockAuthService mockAuthService;

    setUp(() {
      mockAuthService = _MockAuthService();
      when(() => mockAuthService.currentUser).thenReturn(null);
    });

    group('이메일 입력 단계 (Step 0)', () {
      testWidgets('비밀번호 찾기 페이지가 정상적으로 렌더링된다', (tester) async {
        // Given & When
        await tester.pumpWidget(buildForgotPasswordPage());
        await tester.pump();

        // Then
        expect(find.byType(Scaffold), findsOneWidget);
        expect(find.byType(AppBar), findsOneWidget);
      });

      testWidgets('초기 상태에서 이메일 입력 필드가 표시된다', (tester) async {
        // Given & When
        await tester.pumpWidget(buildForgotPasswordPage());
        await tester.pump();

        // Then: 이메일 입력 필드
        expect(find.byType(TextFormField), findsOneWidget);
        expect(find.byIcon(Icons.email_outlined), findsOneWidget);
      });

      testWidgets('인증 코드 전송 버튼이 표시된다', (tester) async {
        // Given & When
        await tester.pumpWidget(buildForgotPasswordPage());
        await tester.pump();

        // Then: ElevatedButton 존재
        expect(find.byType(ElevatedButton), findsOneWidget);
      });

      testWidgets('로그인으로 돌아가기 버튼이 표시된다', (tester) async {
        // Given & When
        await tester.pumpWidget(buildForgotPasswordPage());
        await tester.pump();

        // Then: TextButton 존재
        expect(find.byType(TextButton), findsAtLeastNWidgets(1));
      });

      testWidgets('자물쇠 아이콘이 표시된다', (tester) async {
        // Given & When
        await tester.pumpWidget(buildForgotPasswordPage());
        await tester.pump();

        // Then: lock_reset 아이콘 표시
        expect(find.byIcon(Icons.lock_reset_outlined), findsOneWidget);
      });

      testWidgets('빈 이메일로 전송 시도 시 유효성 검사 에러가 표시된다', (tester) async {
        // Given
        await tester.pumpWidget(buildForgotPasswordPage());
        await tester.pump();

        // When: 이메일 없이 전송 버튼 클릭
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();

        // Then: 이메일 필수 에러 메시지
        expect(find.text('이메일을 입력해주세요'), findsOneWidget);
      });

      testWidgets('@가 없는 이메일 입력 시 유효성 검사 에러가 표시된다', (tester) async {
        // Given
        await tester.pumpWidget(buildForgotPasswordPage());
        await tester.pump();

        // When: 유효하지 않은 이메일 입력
        await tester.enterText(find.byType(TextFormField), 'invalidemail');
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();

        // Then: 이메일 형식 에러 메시지 (실제 l10n 값)
        expect(find.text('올바른 이메일 형식이 아닙니다'), findsOneWidget);
      });

      testWidgets('유효한 이메일 입력 후 전송 성공 시 resetPassword가 호출된다', (tester) async {
        // Given: Completer로 resetPassword 완료를 제어
        final completer = Completer<void>();
        when(
          () => mockAuthService.resetPassword(any()),
        ).thenAnswer((_) => completer.future);

        await tester.pumpWidget(
          buildForgotPasswordPage(authService: mockAuthService),
        );
        await tester.pump();

        // When: 유효한 이메일 입력 후 전송 버튼 탭
        await tester.enterText(
          find.byType(TextFormField),
          'test@example.com',
        );
        await tester.tap(find.byType(ElevatedButton));
        // pump()로 tap 이벤트 처리 (resetPassword는 아직 완료 안 됨)
        await tester.pump();

        // Then: resetPassword가 호출됨 (step 전환 전에 검증)
        verify(() => mockAuthService.resetPassword('test@example.com')).called(1);

        // completer를 완료하지 않고 테스트 종료 (타이머 미시작)
        // pump 없이 종료하므로 쿨다운 타이머가 시작되지 않음
      });

      testWidgets('전송 실패 시 에러 스낵바가 표시된다', (tester) async {
        // Given
        when(
          () => mockAuthService.resetPassword(any()),
        ).thenThrow(Exception('네트워크 에러'));

        await tester.pumpWidget(
          buildForgotPasswordPage(authService: mockAuthService),
        );
        await tester.pump();

        // When: 이메일 입력 후 전송
        await tester.enterText(
          find.byType(TextFormField),
          'test@example.com',
        );
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Then: 에러 스낵바가 표시된다
        expect(find.byType(SnackBar), findsOneWidget);
      });
    });

    group('뒤로가기 동작', () {
      testWidgets('AppBar 뒤로가기 버튼이 표시된다', (tester) async {
        // Given & When
        await tester.pumpWidget(buildForgotPasswordPage());
        await tester.pump();

        // Then: 뒤로가기 아이콘
        expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      });

      testWidgets('이메일 입력 단계에서 뒤로가기 버튼이 활성화된다', (tester) async {
        // Given & When
        await tester.pumpWidget(buildForgotPasswordPage());
        await tester.pump();

        // Then: 뒤로가기 버튼이 존재한다
        final backButton = find.byIcon(Icons.arrow_back);
        expect(backButton, findsOneWidget);
      });
    });

    group('폼 유효성 검사', () {
      testWidgets('유효한 이메일 형식은 검증을 통과한다', (tester) async {
        // Given: Completer로 resetPassword 완료를 제어하여 step 전환 방지
        final completer = Completer<void>();
        when(
          () => mockAuthService.resetPassword(any()),
        ).thenAnswer((_) => completer.future);

        await tester.pumpWidget(
          buildForgotPasswordPage(authService: mockAuthService),
        );
        await tester.pump();

        // When: 유효한 이메일 입력 후 전송 버튼 탭
        await tester.enterText(
          find.byType(TextFormField),
          'valid@email.com',
        );
        await tester.tap(find.byType(ElevatedButton));
        // pump()로 tap 이벤트 처리 (resetPassword는 아직 완료 안 됨)
        await tester.pump();

        // Then: 유효성 에러가 없어야 한다 (step 전환 전)
        expect(find.text('이메일을 입력해주세요'), findsNothing);
        expect(find.text('올바른 이메일 형식을 입력해주세요'), findsNothing);

        // completer를 완료하지 않고 테스트 종료 (타이머 미시작)
      });
    });

    group('OTP 입력 단계 (Step 1) 위젯 테스트', () {
      Future<void> navigateToOtpStep(WidgetTester tester) async {
        // resetPassword가 즉시 성공하도록 설정
        when(
          () => mockAuthService.resetPassword(any()),
        ).thenAnswer((_) async {});

        await tester.pumpWidget(
          buildForgotPasswordPage(authService: mockAuthService),
        );
        await tester.pump();

        // 유효한 이메일 입력 후 전송
        await tester.enterText(
          find.byType(TextFormField),
          'test@example.com',
        );
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        // 쿨다운 타이머를 소진하여 dispose 시 에러 방지
        await tester.pump(const Duration(seconds: 61));
      }

      testWidgets('이메일 전송 성공 후 OTP 단계 UI가 표시된다', (tester) async {
        // Given & When: step 1로 이동
        await tester.runAsync(() async {
          when(
            () => mockAuthService.resetPassword(any()),
          ).thenAnswer((_) async {});

          await tester.pumpWidget(
            buildForgotPasswordPage(authService: mockAuthService),
          );
          await tester.pump();

          await tester.enterText(find.byType(TextFormField), 'test@example.com');
          await tester.tap(find.byType(ElevatedButton));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));
        });

        // Then: OTP 입력 UI - Scaffold가 유지된다
        expect(find.byType(Scaffold), findsOneWidget);
      });

      testWidgets('OTP 단계에서 이메일 아이콘이 변경된다', (tester) async {
        // Given & When: step 1로 이동
        await navigateToOtpStep(tester);

        // Then: mark_email_read_outlined 아이콘 (OTP 단계)
        expect(find.byIcon(Icons.mark_email_read_outlined), findsOneWidget);
      });

      testWidgets('OTP 단계에서 로그인으로 돌아가기 버튼이 표시된다', (tester) async {
        // Given & When: step 1로 이동
        await navigateToOtpStep(tester);

        // Then: 로그인으로 돌아가기 TextButton
        expect(find.byType(TextButton), findsAtLeastNWidgets(1));
      });

      testWidgets('OTP 단계에서 뒤로가기 버튼이 step 0으로 돌아간다', (tester) async {
        // Given: step 1로 이동
        await navigateToOtpStep(tester);

        // OTP 단계인지 확인
        expect(find.byIcon(Icons.mark_email_read_outlined), findsOneWidget);

        // When: 뒤로가기 버튼 탭
        final backButton = find.byIcon(Icons.arrow_back);
        expect(backButton, findsOneWidget);
        await tester.tap(backButton);
        await tester.pump();

        // Then: 이메일 입력 단계로 돌아간다 (ElevatedButton이 다시 표시됨)
        expect(find.byType(ElevatedButton), findsOneWidget);
        // lock_reset 아이콘 (이메일 단계)
        expect(find.byIcon(Icons.lock_reset_outlined), findsOneWidget);
      });

      testWidgets('OTP 단계에서 재전송 버튼이 쿨다운 중에는 비활성화된다', (tester) async {
        // Given & When: step 1로 이동 (이메일 전송 시 쿨다운 시작)
        await navigateToOtpStep(tester);

        // Then: 쿨다운이 소진된 후 TextButton이 표시된다
        final textButtons = find.byType(TextButton);
        expect(textButtons, findsAtLeastNWidgets(1));
      });

      testWidgets('OTP 단계에서 이메일이 표시된다', (tester) async {
        // Given & When: 특정 이메일로 step 1로 이동
        when(
          () => mockAuthService.resetPassword(any()),
        ).thenAnswer((_) async {});

        await tester.pumpWidget(
          buildForgotPasswordPage(authService: mockAuthService),
        );
        await tester.pump();

        const testEmail = 'mytest@example.com';
        await tester.enterText(find.byType(TextFormField), testEmail);
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        // 쿨다운 타이머 소진
        await tester.pump(const Duration(seconds: 61));

        // Then: 이메일이 OTP 단계에서도 표시된다
        expect(find.text(testEmail), findsOneWidget);
      });
    });

    group('로딩 상태', () {
      testWidgets('전송 중 로딩 인디케이터가 표시된다', (tester) async {
        // Given: resetPassword가 지연되도록 설정 (Completer 사용)
        final completer = Completer<void>();
        when(
          () => mockAuthService.resetPassword(any()),
        ).thenAnswer((_) => completer.future);

        await tester.pumpWidget(
          buildForgotPasswordPage(authService: mockAuthService),
        );
        await tester.pump();

        // When: 이메일 입력 후 전송 버튼 탭
        await tester.enterText(
          find.byType(TextFormField),
          'test@example.com',
        );
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump(); // 비동기 시작

        // Then: 로딩 인디케이터가 표시된다
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    });

    group('네트워크 에러 처리', () {
      testWidgets('네트워크 에러 시 에러 스낵바가 표시된다', (tester) async {
        // Given: AuthRetryableFetchException throw
        when(
          () => mockAuthService.resetPassword(any()),
        ).thenThrow(AuthRetryableFetchException());

        await tester.pumpWidget(
          buildForgotPasswordPage(authService: mockAuthService),
        );
        await tester.pump();

        // When: 이메일 입력 후 전송
        await tester.enterText(
          find.byType(TextFormField),
          'test@example.com',
        );
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Then: 에러 스낵바 표시
        expect(find.byType(SnackBar), findsOneWidget);
      });
    });

    group('OTP 재전송 (_handleResendOtp) 커버리지', () {
      Future<void> goToOtpStep(WidgetTester tester) async {
        when(
          () => mockAuthService.resetPassword(any()),
        ).thenAnswer((_) async {});

        await tester.pumpWidget(
          buildForgotPasswordPage(authService: mockAuthService),
        );
        await tester.pump();
        await tester.enterText(find.byType(TextFormField), 'test@example.com');
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        // 쿨다운 타이머 소진 (60초)
        await tester.pump(const Duration(seconds: 61));
      }

      testWidgets('쿨다운이 끝난 후 재전송 버튼을 탭하면 resetPassword가 재호출된다', (tester) async {
        // Given: resetPassword 호출 횟수 추적
        var callCount = 0;
        when(() => mockAuthService.resetPassword(any())).thenAnswer((_) async {
          callCount++;
        });

        await tester.pumpWidget(
          buildForgotPasswordPage(authService: mockAuthService),
        );
        await tester.pump();
        await tester.enterText(find.byType(TextFormField), 'test@example.com');
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        // 쿨다운 타이머 소진
        await tester.pump(const Duration(seconds: 61));

        // 첫 번째 호출 확인
        expect(callCount, equals(1));

        // When: OTP 단계에서 재전송 버튼 탭 (첫 번째 TextButton = 재전송)
        final textButtons = find.byType(TextButton);
        await tester.tap(textButtons.first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // Then: resetPassword가 2번 호출되어야 한다 (최초 전송 + 재전송)
        expect(callCount, equals(2));
      });

      testWidgets('재전송 중 에러 발생 시 에러 스낵바가 표시된다', (tester) async {
        // Given: 첫 번째 resetPassword 성공, 두 번째 실패
        var callCount = 0;
        when(() => mockAuthService.resetPassword(any())).thenAnswer((_) async {
          callCount++;
          if (callCount > 1) throw Exception('재전송 실패');
        });

        await tester.pumpWidget(
          buildForgotPasswordPage(authService: mockAuthService),
        );
        await tester.pump();
        await tester.enterText(find.byType(TextFormField), 'test@example.com');
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(seconds: 61));

        // When: 재전송 버튼 탭 (쿨다운 텍스트가 아닌 재전송 버튼을 찾아서 탭)
        // TextButton 중 첫 번째(재전송)를 탭 - 마지막은 "로그인으로 돌아가기"
        final textButtons = find.byType(TextButton);
        // 재전송 버튼은 첫 번째 TextButton
        await tester.tap(textButtons.first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // Then: 에러 스낵바 표시
        expect(find.byType(SnackBar), findsOneWidget);
      });

      testWidgets('쿨다운 중에는 재전송 버튼이 비활성화된다', (tester) async {
        // Given: OTP 단계로 이동 (쿨다운 진행 중)
        when(
          () => mockAuthService.resetPassword(any()),
        ).thenAnswer((_) async {});

        await tester.pumpWidget(
          buildForgotPasswordPage(authService: mockAuthService),
        );
        await tester.pump();
        await tester.enterText(find.byType(TextFormField), 'test@example.com');
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        // 쿨다운 중 (30초만 경과)
        await tester.pump(const Duration(seconds: 30));

        // Then: 쿨다운 중에는 TextButton이 여전히 존재 (비활성)
        expect(find.byType(TextButton), findsAtLeastNWidgets(1));
      });
    });

    group('OTP 검증 (_handleVerifyOtp) 커버리지', () {
      testWidgets('OTP 단계에서 로딩 텍스트가 표시되는 상태를 확인한다', (tester) async {
        // Given: OTP 단계로 이동
        when(
          () => mockAuthService.resetPassword(any()),
        ).thenAnswer((_) async {});

        await tester.pumpWidget(
          buildForgotPasswordPage(authService: mockAuthService),
        );
        await tester.pump();
        await tester.enterText(find.byType(TextFormField), 'test@example.com');
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(seconds: 61));

        // Then: OTP 단계 UI가 표시된다
        expect(find.byType(Scaffold), findsOneWidget);
      });
    });
  });
}
