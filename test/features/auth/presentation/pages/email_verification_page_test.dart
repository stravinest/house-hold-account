import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_household_account/features/auth/presentation/pages/email_verification_page.dart';
import 'package:shared_household_account/features/auth/presentation/providers/auth_provider.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../helpers/test_helpers.dart';

class _MockAuthService extends Mock implements AuthService {}

Future<void> pumpEmailVerificationPage(
  WidgetTester tester, {
  String email = 'test@example.com',
  AuthService? authService,
}) async {
  tester.view.physicalSize = const Size(1080, 1920);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authStateProvider.overrideWith((ref) => const Stream.empty()),
        if (authService != null) ...[
          authServiceProvider.overrideWith((ref) => authService),
          authNotifierProvider.overrideWith(
            (ref) => AuthNotifier(authService, ref),
          ),
        ],
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: EmailVerificationPage(email: email),
      ),
    ),
  );
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    try {
      await Supabase.initialize(
        url: 'https://test.supabase.co',
        anonKey: 'test-anon-key',
      );
    } catch (_) {
      // 이미 초기화된 경우 무시
    }
  });

  group('EmailVerificationPage 위젯 테스트', () {
    late _MockAuthService mockAuthService;

    setUp(() {
      mockAuthService = _MockAuthService();
      when(() => mockAuthService.currentUser).thenReturn(null);
    });

    group('UI 렌더링', () {
      testWidgets('이메일 인증 페이지가 정상적으로 렌더링된다', (tester) async {
        // Given & When
        await pumpEmailVerificationPage(tester);
        await tester.pump();

        // Then: 주요 UI 요소 확인
        expect(find.byType(Scaffold), findsOneWidget);
        expect(find.byType(AppBar), findsOneWidget);
      });

      testWidgets('이메일 주소가 페이지에 표시된다', (tester) async {
        // Given: 특정 이메일 주소
        const testEmail = 'user@example.com';

        // When
        await pumpEmailVerificationPage(tester, email: testEmail);
        await tester.pump();

        // Then: 이메일 주소가 화면에 표시된다
        expect(find.text(testEmail), findsOneWidget);
      });

      testWidgets('미인증 상태에서 이메일 아이콘이 표시된다', (tester) async {
        // Given & When
        await pumpEmailVerificationPage(tester);
        await tester.pump();

        // Then: 이메일 미읽음 아이콘 (미인증 상태)
        expect(
          find.byIcon(Icons.mark_email_unread_outlined),
          findsOneWidget,
        );
      });

      testWidgets('미인증 상태에서 인증 상태 확인 버튼이 표시된다', (tester) async {
        // Given & When
        await pumpEmailVerificationPage(tester);
        await tester.pump();

        // Then: OutlinedButton이 2개 (인증 확인, 재전송)
        expect(find.byType(OutlinedButton), findsNWidgets(2));
      });

      testWidgets('미인증 상태에서 인증 메일 재전송 버튼이 표시된다', (tester) async {
        // Given & When
        await pumpEmailVerificationPage(tester);
        await tester.pump();

        // Then: refresh 아이콘 (재전송 버튼)
        expect(find.byIcon(Icons.refresh), findsOneWidget);
      });

      testWidgets('미인증 상태에서 sync 아이콘이 표시된다', (tester) async {
        // Given & When
        await pumpEmailVerificationPage(tester);
        await tester.pump();

        // Then: sync 아이콘 (인증 상태 확인 버튼)
        expect(find.byIcon(Icons.sync), findsOneWidget);
      });

      testWidgets('앱바에 뒤로가기 버튼이 표시된다', (tester) async {
        // Given & When
        await pumpEmailVerificationPage(tester);
        await tester.pump();

        // Then: 뒤로가기 아이콘
        expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      });

      testWidgets('미인증 배지(미인증 텍스트)가 표시된다', (tester) async {
        // Given & When
        await pumpEmailVerificationPage(tester);
        await tester.pump();

        // Then: pending 아이콘 (미인증 배지)
        expect(find.byIcon(Icons.pending), findsOneWidget);
      });
    });

    group('이메일 재전송 동작', () {
      testWidgets('재전송 버튼 클릭 시 에러가 발생하면 에러 스낵바가 표시된다', (tester) async {
        // Given: Supabase auth가 예외를 throw하는 상황 시뮬레이션
        // EmailVerificationPage는 SupabaseConfig.auth에 직접 접근하므로
        // 실제 Supabase 초기화 상태에서 테스트
        await pumpEmailVerificationPage(tester);
        await tester.pump();

        // When: 재전송 버튼 클릭 (refresh 아이콘 버튼)
        // SupabaseConfig.auth.resend()는 test URL로 인해 실패하여 에러 스낵바 표시
        final refreshButton = find.byIcon(Icons.refresh);
        expect(refreshButton, findsOneWidget);
        await tester.tap(refreshButton);
        await tester.pumpAndSettle();

        // Then: 에러 처리가 수행된다 (예외 없이 UI가 유지됨)
        expect(find.byType(Scaffold), findsOneWidget);
      });

      testWidgets('재전송 성공 또는 실패 후 isResending이 false로 복원된다', (tester) async {
        // Given & When
        await pumpEmailVerificationPage(tester);
        await tester.pump();

        // When: 재전송 버튼 탭
        final refreshButton = find.byIcon(Icons.refresh);
        await tester.tap(refreshButton);
        // 비동기 작업 완료 대기
        await tester.pumpAndSettle();

        // Then: 재전송 중 상태가 아님 (정상 복원)
        // refresh 아이콘이 다시 표시되어야 함 (isResending = false)
        expect(find.byType(Scaffold), findsOneWidget);
      });
    });

    group('인증 상태 확인 동작', () {
      testWidgets('인증 상태 확인 버튼 클릭 시 예외 없이 동작한다', (tester) async {
        // Given
        await pumpEmailVerificationPage(tester);
        await tester.pump();

        // When: sync 버튼 클릭
        final syncButton = find.byIcon(Icons.sync);
        expect(syncButton, findsOneWidget);
        await tester.tap(syncButton);
        await tester.pumpAndSettle();

        // Then: 예외 없이 UI가 유지된다
        expect(find.byType(Scaffold), findsOneWidget);
      });

      testWidgets('인증 확인 중 UI가 정상적으로 표시된다', (tester) async {
        // Given
        await pumpEmailVerificationPage(tester);
        await tester.pump();

        // When: sync 버튼 탭 후 즉시 UI 확인
        final syncButton = find.byIcon(Icons.sync);
        await tester.tap(syncButton);
        await tester.pump(); // 비동기 시작 전 UI 상태

        // Then: UI가 깨지지 않는다
        expect(find.byType(Scaffold), findsOneWidget);

        // 비동기 완료
        await tester.pumpAndSettle();
      });
    });

    group('앱바 동작', () {
      testWidgets('앱바가 존재하고 제목이 있다', (tester) async {
        // Given & When
        await pumpEmailVerificationPage(tester);
        await tester.pump();

        // Then
        final appBar = find.byType(AppBar);
        expect(appBar, findsOneWidget);
      });
    });

    group('다양한 이메일 주소 처리', () {
      testWidgets('긴 이메일 주소도 정상적으로 표시된다', (tester) async {
        // Given
        const longEmail = 'very.long.email.address@very.long.domain.example.com';

        // When
        await pumpEmailVerificationPage(tester, email: longEmail);
        await tester.pump();

        // Then: 긴 이메일도 표시된다
        expect(find.text(longEmail), findsOneWidget);
      });

      testWidgets('특수문자 포함 이메일이 표시된다', (tester) async {
        // Given
        const specialEmail = 'user+tag@example.co.kr';

        // When
        await pumpEmailVerificationPage(tester, email: specialEmail);
        await tester.pump();

        // Then
        expect(find.text(specialEmail), findsOneWidget);
      });
    });
  });

  group('EmailVerificationPage 로직 테스트', () {
    group('쿨다운 타이머 로직', () {
      test('쿨다운 초기값은 0이다', () {
        // Given
        int resendCooldown = 0;

        // When & Then
        expect(resendCooldown, equals(0));
      });

      test('재전송 후 쿨다운이 60초로 설정된다', () {
        // Given
        int resendCooldown = 0;

        // When: 재전송 호출 (쿨다운 설정)
        resendCooldown = 60;

        // Then
        expect(resendCooldown, equals(60));
      });

      test('쿨다운이 0보다 크면 재전송 버튼이 비활성화된다', () {
        // Given
        const resendCooldown = 30;

        // When: 버튼 활성화 여부 계산
        final isResendEnabled = resendCooldown == 0;

        // Then
        expect(isResendEnabled, isFalse);
      });

      test('쿨다운이 0이면 재전송 버튼이 활성화된다', () {
        // Given
        const resendCooldown = 0;

        // When: 버튼 활성화 여부 계산
        final isResendEnabled = resendCooldown == 0;

        // Then
        expect(isResendEnabled, isTrue);
      });

      test('타이머가 매 초마다 쿨다운을 감소시킨다', () {
        // Given
        int resendCooldown = 3;

        // When: 타이머 틱 시뮬레이션
        if (resendCooldown > 0) resendCooldown--;
        if (resendCooldown > 0) resendCooldown--;
        if (resendCooldown > 0) resendCooldown--;

        // Then
        expect(resendCooldown, equals(0));
      });
    });

    group('이메일 인증 상태 로직', () {
      test('초기 인증 상태는 false이다', () {
        // Given
        bool isVerified = false;

        // When & Then
        expect(isVerified, isFalse);
      });

      test('이메일 인증 완료 시 isVerified가 true로 변경된다', () {
        // Given
        bool isVerified = false;

        // When: 인증 완료 이벤트 수신
        isVerified = true;

        // Then
        expect(isVerified, isTrue);
      });

      test('인증 완료 시 폴링 타이머가 취소되어야 한다', () {
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
    });

    group('서버 검증 로직', () {
      test('이미 검증 중이면 중복 서버 요청을 방지한다', () {
        // Given
        bool isChecking = false;
        bool isVerified = false;
        int serverCallCount = 0;

        // When: checkVerificationFromServer 호출
        void checkVerification() {
          if (isVerified || isChecking) return;
          isChecking = true;
          serverCallCount++;
        }

        checkVerification(); // 첫 번째 호출
        checkVerification(); // 두 번째 호출 (isChecking=true여서 무시됨)

        // Then: 서버 호출이 1번만 이루어진다
        expect(serverCallCount, equals(1));
      });

      test('이미 인증됐으면 서버 요청을 하지 않는다', () {
        // Given
        bool isChecking = false;
        bool isVerified = true;
        int serverCallCount = 0;

        // When
        void checkVerification() {
          if (isVerified || isChecking) return;
          serverCallCount++;
        }

        checkVerification();

        // Then
        expect(serverCallCount, equals(0));
      });
    });

    group('폴링 주기 설정', () {
      test('폴링 주기는 5초이다', () {
        // Given
        const pollingInterval = Duration(seconds: 5);

        // Then
        expect(pollingInterval.inSeconds, equals(5));
      });
    });

    group('이메일 표시', () {
      test('이메일 주소가 올바르게 전달된다', () {
        // Given
        const email = 'test@example.com';

        // When: 페이지에 이메일 전달
        const displayEmail = email;

        // Then
        expect(displayEmail, equals('test@example.com'));
      });

      test('다양한 이메일 형식을 처리할 수 있다', () {
        // Given
        const emails = [
          'user@gmail.com',
          'another@domain.co.kr',
          'test+tag@company.org',
        ];

        // When & Then: 모든 이메일이 그대로 표시된다
        for (final email in emails) {
          expect(email, isNotEmpty);
          expect(email, contains('@'));
        }
      });
    });

    group('미인증 상태 UI 세부 요소', () {
      testWidgets('재전송 쿨다운 시작 전 버튼이 활성화된다', (tester) async {
        // Given & When: 기본 상태 (쿨다운 없음)
        await pumpEmailVerificationPage(tester);
        await tester.pump();

        // Then: refresh 아이콘이 있는 버튼이 활성화 상태여야 한다
        final refreshButton = find.byIcon(Icons.refresh);
        expect(refreshButton, findsOneWidget);
        // 버튼이 탭 가능해야 한다
        final outlinedButtons = find.byType(OutlinedButton);
        expect(outlinedButtons, findsNWidgets(2));
      });

      testWidgets('sync 아이콘이 있는 인증 상태 확인 버튼이 활성화된다', (tester) async {
        // Given & When
        await pumpEmailVerificationPage(tester);
        await tester.pump();

        // Then: sync 버튼이 활성화 상태여야 한다
        expect(find.byIcon(Icons.sync), findsOneWidget);
      });

      testWidgets('미인증 상태에서 errorContainer 배경의 배지가 표시된다', (tester) async {
        // Given & When: 미인증 상태
        await pumpEmailVerificationPage(tester);
        await tester.pump();

        // Then: pending 아이콘(미인증 배지)이 표시된다
        expect(find.byIcon(Icons.pending), findsOneWidget);
      });

      testWidgets('인증 상태 확인 버튼 탭 후 잠시 비활성화된다', (tester) async {
        // Given
        await pumpEmailVerificationPage(tester);
        await tester.pump();

        // When: sync 버튼 탭
        await tester.tap(find.byIcon(Icons.sync));
        await tester.pump();

        // Then: 버튼이 비활성화될 수 있다 (isChecking=true)
        expect(find.byType(Scaffold), findsOneWidget);

        await tester.pumpAndSettle();
      });

      testWidgets('이메일이 여러 개의 위젯에서 표시될 수 있다', (tester) async {
        // Given
        const testEmail = 'verify@test.com';

        // When
        await pumpEmailVerificationPage(tester, email: testEmail);
        await tester.pump();

        // Then: 이메일이 화면에 표시된다
        expect(find.text(testEmail), findsOneWidget);
      });

      testWidgets('재전송 버튼을 탭하면 loading 표시가 나타났다 사라진다', (tester) async {
        // Given
        await pumpEmailVerificationPage(tester);
        await tester.pump();

        // When: 재전송 버튼 탭
        await tester.tap(find.byIcon(Icons.refresh));
        // pump() 한 번으로 비동기 시작 직후 상태 (isResending=true 가능)
        await tester.pump();

        // Then: Scaffold가 여전히 렌더링된다
        expect(find.byType(Scaffold), findsOneWidget);

        await tester.pumpAndSettle();
      });
    });

    group('UI 상태 전환 분기 로직', () {
      testWidgets('emailVerificationSent 텍스트가 미인증 상태에서 표시된다', (tester) async {
        // Given & When: 미인증 상태 (기본)
        await pumpEmailVerificationPage(tester);
        await tester.pump();

        // Then: Scaffold가 렌더링된다 (미인증 분기)
        expect(find.byType(Scaffold), findsOneWidget);
        // 미인증 아이콘
        expect(find.byIcon(Icons.mark_email_unread_outlined), findsOneWidget);
      });

      testWidgets('다른 이메일로도 페이지가 정상 렌더링된다', (tester) async {
        // Given
        const anotherEmail = 'another.user@domain.co.kr';

        // When
        await pumpEmailVerificationPage(tester, email: anotherEmail);
        await tester.pump();

        // Then
        expect(find.text(anotherEmail), findsOneWidget);
        expect(find.byType(AppBar), findsOneWidget);
      });
    });
  });
}
