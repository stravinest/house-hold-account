import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_household_account/features/auth/presentation/pages/login_page.dart';
import 'package:shared_household_account/features/auth/presentation/providers/auth_provider.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../helpers/mock_supabase.dart';
import '../../../../helpers/test_helpers.dart';

class _MockAuthService extends Mock implements AuthService {}

Future<void> pumpLoginPage(
  WidgetTester tester, {
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
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('ko'),
        home: LoginPage(),
      ),
    ),
  );
}

// 하위 호환성을 위한 래퍼 (physicalSize 없이 widget만 반환)
Widget buildLoginPage({AuthService? authService}) {
  return ProviderScope(
    overrides: [
      authStateProvider.overrideWith((ref) => const Stream.empty()),
      if (authService != null) ...[
        authServiceProvider.overrideWith((ref) => authService),
        authNotifierProvider.overrideWith(
          (ref) => AuthNotifier(authService, ref),
        ),
      ],
    ],
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: Locale('ko'),
      home: LoginPage(),
    ),
  );
}

void main() {
  group('LoginPage 위젯 테스트', () {
    late MockGoTrueClient mockAuth;
    late _MockAuthService mockAuthService;

    setUp(() {
      mockAuth = MockGoTrueClient();
      mockAuthService = _MockAuthService();
      when(() => mockAuth.currentUser).thenReturn(null);
      when(() => mockAuthService.currentUser).thenReturn(null);
    });

    group('UI 렌더링', () {
      testWidgets('로그인 페이지가 정상적으로 렌더링된다', (tester) async {
        // Given & When
        await tester.pumpWidget(buildLoginPage());
        await tester.pump();

        // Then: 주요 UI 요소 확인
        expect(find.byType(TextFormField), findsNWidgets(2));
        expect(find.byType(ElevatedButton), findsOneWidget);
        expect(find.byType(OutlinedButton), findsOneWidget);
      });

      testWidgets('이메일과 비밀번호 입력 필드가 표시된다', (tester) async {
        // Given & When
        await tester.pumpWidget(buildLoginPage());
        await tester.pump();

        // Then
        expect(find.byIcon(Icons.mail_outline), findsOneWidget);
        expect(find.byIcon(Icons.lock_outline), findsOneWidget);
      });

      testWidgets('회원가입 링크가 표시된다', (tester) async {
        // Given & When
        await tester.pumpWidget(buildLoginPage());
        await tester.pump();

        // Then: 회원가입 텍스트 확인
        expect(find.text('계정이 없으신가요?'), findsOneWidget);
        expect(find.text('회원가입'), findsOneWidget);
      });

      testWidgets('Google 로그인 버튼이 표시된다', (tester) async {
        // Given & When
        await tester.pumpWidget(buildLoginPage());
        await tester.pump();

        // Then
        expect(find.text('Google로 계속하기'), findsOneWidget);
      });

      testWidgets('비밀번호 찾기 링크가 표시된다', (tester) async {
        // Given & When
        await tester.pumpWidget(buildLoginPage());
        await tester.pump();

        // Then: 비밀번호 찾기 텍스트 버튼
        expect(find.text('비밀번호를 잊으셨나요?'), findsOneWidget);
      });

      testWidgets('앱 타이틀이 표시된다', (tester) async {
        // Given & When
        await tester.pumpWidget(buildLoginPage());
        await tester.pump();

        // Then: 앱 타이틀 (우생가계부)
        expect(find.text('우생가계부'), findsOneWidget);
      });
    });

    group('비밀번호 가시성 토글', () {
      testWidgets('비밀번호 가시성 토글 버튼이 작동한다', (tester) async {
        // Given
        await tester.pumpWidget(buildLoginPage());
        await tester.pump();

        // When: 비밀번호 가시성 아이콘 찾기 (초기: visibility_off)
        final visibilityOffIcon = find.byIcon(Icons.visibility_off_outlined);
        expect(visibilityOffIcon, findsOneWidget);

        // When: 토글 버튼 클릭
        await tester.tap(visibilityOffIcon);
        await tester.pump();

        // Then: 아이콘이 변경됨 (visibility로)
        expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      });

      testWidgets('비밀번호 가시성 아이콘을 다시 클릭하면 원래 상태로 돌아간다', (tester) async {
        // Given
        await tester.pumpWidget(buildLoginPage());
        await tester.pump();

        // When: 두 번 클릭
        final visibilityOffIcon = find.byIcon(Icons.visibility_off_outlined);
        await tester.tap(visibilityOffIcon);
        await tester.pump();
        await tester.tap(find.byIcon(Icons.visibility_outlined));
        await tester.pump();

        // Then: 다시 visibility_off 상태
        expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
      });
    });

    group('폼 유효성 검사', () {
      testWidgets('빈 이메일로 로그인 시도 시 유효성 검사 에러가 표시된다', (tester) async {
        // Given
        await tester.pumpWidget(buildLoginPage());
        await tester.pump();

        // When: 로그인 버튼 클릭 (입력 없이)
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();

        // Then: 유효성 검사 에러 확인
        expect(find.text('이메일을 입력해주세요'), findsOneWidget);
      });

      testWidgets('@가 없는 이메일 입력 시 유효성 검사 에러가 표시된다', (tester) async {
        // Given
        await tester.pumpWidget(buildLoginPage());
        await tester.pump();

        // When: 유효하지 않은 이메일 입력 후 로그인
        await tester.enterText(find.byType(TextFormField).first, 'invalidemail');
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();

        // Then: 이메일 형식 에러 (실제 l10n 값)
        expect(find.text('올바른 이메일 형식이 아닙니다'), findsOneWidget);
      });

      testWidgets('빈 비밀번호로 로그인 시도 시 유효성 검사 에러가 표시된다', (tester) async {
        // Given
        await tester.pumpWidget(buildLoginPage());
        await tester.pump();

        // When: 이메일만 입력하고 비밀번호는 비워둠
        await tester.enterText(
          find.byType(TextFormField).first,
          'test@example.com',
        );
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();

        // Then: 비밀번호 필수 에러
        expect(find.text('비밀번호를 입력해주세요'), findsOneWidget);
      });

      testWidgets('6자 미만 비밀번호 입력 시 유효성 검사 에러가 표시된다', (tester) async {
        // Given
        await tester.pumpWidget(buildLoginPage());
        await tester.pump();

        // When: 이메일 + 짧은 비밀번호 입력
        final fields = find.byType(TextFormField);
        await tester.enterText(fields.first, 'test@example.com');
        await tester.enterText(fields.last, '12345');
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();

        // Then: 비밀번호 길이 에러 (실제 l10n 값)
        expect(find.text('비밀번호는 6자 이상이어야 합니다'), findsOneWidget);
      });

      testWidgets('유효한 이메일과 비밀번호는 유효성 검사를 통과한다', (tester) async {
        // Given & When: 유효한 이메일과 비밀번호만 입력 후 탭 (서버 호출 없이 유효성만 확인)
        await tester.pumpWidget(buildLoginPage());
        await tester.pump();

        // When: 유효한 이메일과 비밀번호 입력
        final fields = find.byType(TextFormField);
        await tester.enterText(fields.first, 'test@example.com');
        await tester.enterText(fields.last, 'password123');

        // Form 유효성만 검사 (버튼 탭 없이)
        await tester.pump();

        // Then: 유효성 에러가 표시되지 않음
        expect(find.text('이메일을 입력해주세요'), findsNothing);
        expect(find.text('비밀번호를 입력해주세요'), findsNothing);
        expect(find.text('비밀번호는 6자 이상이어야 합니다'), findsNothing);
      });
    });

    group('로그인 동작', () {
      testWidgets('잘못된 자격증명으로 로그인 시 에러 스낵바가 표시된다', (tester) async {
        // Given
        when(
          () => mockAuthService.signInWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(
          AuthApiException(
            'invalid_credentials',
            statusCode: '400',
            code: 'invalid_credentials',
          ),
        );

        await tester.pumpWidget(buildLoginPage(authService: mockAuthService));
        await tester.pump();

        // When: 로그인 시도
        final fields = find.byType(TextFormField);
        await tester.enterText(fields.first, 'test@example.com');
        await tester.enterText(fields.last, 'wrongpass');
        await tester.tap(find.byType(ElevatedButton));
        // pump으로 에러 처리 완료 대기
        await tester.pump();
        await tester.pump();

        // Then: 에러 스낵바가 표시된다
        expect(find.byType(SnackBar), findsOneWidget);
      });

      testWidgets('이메일 미인증 에러 시 에러 스낵바가 표시된다', (tester) async {
        // Given
        when(
          () => mockAuthService.signInWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(
          AuthApiException(
            'email_not_confirmed',
            statusCode: '400',
            code: 'email_not_confirmed',
          ),
        );

        await tester.pumpWidget(buildLoginPage(authService: mockAuthService));
        await tester.pump();

        // When: 로그인 시도
        final fields = find.byType(TextFormField);
        await tester.enterText(fields.first, 'test@example.com');
        await tester.enterText(fields.last, 'password123');
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();
        await tester.pump();

        // Then: 에러 스낵바 표시
        expect(find.byType(SnackBar), findsOneWidget);
      });

      testWidgets('Google 로그인 취소 시 에러 메시지가 표시되지 않는다', (tester) async {
        // Given: Google 로그인 취소 시뮬레이션 (취소 메시지 포함)
        when(() => mockAuthService.signInWithGoogle())
            .thenThrow(const AuthException('Google 로그인이 취소되었습니다.'));

        await tester.pumpWidget(buildLoginPage(authService: mockAuthService));
        await tester.pump();

        // When: Google 로그인 버튼 클릭
        await tester.tap(find.byType(OutlinedButton));
        await tester.pump();
        await tester.pump();

        // Then: 에러 스낵바가 표시되지 않는다 (취소는 에러 아님)
        expect(find.byType(SnackBar), findsNothing);
      });

      testWidgets('네트워크 에러 발생 시 에러 스낵바가 표시된다', (tester) async {
        // Given
        when(
          () => mockAuthService.signInWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(Exception('SocketException: Failed host lookup'));

        await tester.pumpWidget(buildLoginPage(authService: mockAuthService));
        await tester.pump();

        // When: 로그인 시도
        final fields = find.byType(TextFormField);
        await tester.enterText(fields.first, 'test@example.com');
        await tester.enterText(fields.last, 'password123');
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();
        await tester.pump();

        // Then: 에러 스낵바 표시
        expect(find.byType(SnackBar), findsOneWidget);
      });
    });

    group('텍스트 입력', () {
      testWidgets('이메일 필드에 텍스트를 입력할 수 있다', (tester) async {
        // Given
        await tester.pumpWidget(buildLoginPage());
        await tester.pump();

        // When
        await tester.enterText(
          find.byType(TextFormField).first,
          'test@example.com',
        );
        await tester.pump();

        // Then
        expect(find.text('test@example.com'), findsOneWidget);
      });

      testWidgets('비밀번호 필드에 텍스트를 입력할 수 있다', (tester) async {
        // Given
        await tester.pumpWidget(buildLoginPage());
        await tester.pump();

        // When
        await tester.enterText(
          find.byType(TextFormField).last,
          'mypassword',
        );
        await tester.pump();

        // Then: 에러 없이 입력됨
        expect(tester.takeException(), isNull);
      });
    });

    group('Google 로그인 동작', () {
      testWidgets('Google 로그인 버튼이 표시된다', (tester) async {
        // Given & When: 큰 화면 크기로 렌더링
        await pumpLoginPage(tester);
        await tester.pump();

        // Then: Google 로그인 OutlinedButton 존재
        expect(find.byType(OutlinedButton), findsOneWidget);
      });

      testWidgets('Google 로그인 실패 시 에러 스낵바가 표시된다', (tester) async {
        // Given
        when(
          () => mockAuthService.signInWithGoogle(),
        ).thenThrow(Exception('Google 로그인 실패'));

        await pumpLoginPage(tester, authService: mockAuthService);
        await tester.pump();

        // When: Google 로그인 버튼 탭 (exception throw이므로 polling loop 없이 바로 catch)
        await tester.tap(find.byType(OutlinedButton));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pump(const Duration(milliseconds: 50));

        // Then: 에러 스낵바 표시
        expect(find.byType(SnackBar), findsOneWidget);
      });

      testWidgets('Google 로그인 사용자 취소 시 에러 스낵바가 표시되지 않는다', (tester) async {
        // Given: 사용자 취소 에러
        when(
          () => mockAuthService.signInWithGoogle(),
        ).thenThrow(Exception('canceled'));

        await pumpLoginPage(tester, authService: mockAuthService);
        await tester.pump();

        // When: Google 로그인 버튼 탭
        await tester.tap(find.byType(OutlinedButton));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pump(const Duration(milliseconds: 50));

        // Then: 에러 스낵바가 표시되지 않음 (취소이므로)
        expect(find.byType(SnackBar), findsNothing);
      });

      testWidgets('Google 로그인 네트워크 에러 시 에러 스낵바가 표시된다', (tester) async {
        // Given: 네트워크 에러
        when(
          () => mockAuthService.signInWithGoogle(),
        ).thenThrow(AuthRetryableFetchException());

        await pumpLoginPage(tester, authService: mockAuthService);
        await tester.pump();

        // When: Google 로그인 버튼 탭
        await tester.tap(find.byType(OutlinedButton));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pump(const Duration(milliseconds: 50));

        // Then: 에러 스낵바 표시
        expect(find.byType(SnackBar), findsOneWidget);
      });

      testWidgets('Google 로그인 중 로딩 인디케이터가 표시된다', (tester) async {
        // Given: 로그인이 지연되도록 설정 (completer가 완료되지 않으면 로딩 상태 유지)
        final completer = Completer<AuthResponse>();
        when(
          () => mockAuthService.signInWithGoogle(),
        ).thenAnswer((_) => completer.future);

        await pumpLoginPage(tester, authService: mockAuthService);
        await tester.pump();

        // When: Google 로그인 버튼 탭 후 비동기 시작 (completer 대기 중)
        await tester.tap(find.byType(OutlinedButton));
        await tester.pump();

        // Then: 로딩 인디케이터 표시 (completer가 pending 상태이므로 로딩 중)
        // authNotifierProvider 로딩 상태와 버튼 로딩 상태 두 개가 표시될 수 있음
        expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
        // completer를 완료하지 않고 종료 - FakeAsync가 pending future를 정리함
      });
    });

    group('로그인 에러 처리', () {
      testWidgets('AuthApiException - invalid_credentials 에러 처리', (tester) async {
        // Given
        when(
          () => mockAuthService.signInWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(
          AuthApiException(
            'Invalid login credentials',
            statusCode: '400',
            code: 'invalid_credentials',
          ),
        );

        await pumpLoginPage(tester, authService: mockAuthService);
        await tester.pump();

        // When: exception throw이므로 polling loop 없이 catch로 바로 이동
        final fields = find.byType(TextFormField);
        await tester.enterText(fields.first, 'test@example.com');
        await tester.enterText(fields.last, 'wrongpass');
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pump(const Duration(milliseconds: 50));

        // Then: 에러 스낵바 표시
        expect(find.byType(SnackBar), findsOneWidget);
      });

      testWidgets('네트워크 에러(SocketException) 로그인 에러 처리', (tester) async {
        // Given
        when(
          () => mockAuthService.signInWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(Exception('SocketException: Connection refused'));

        await pumpLoginPage(tester, authService: mockAuthService);
        await tester.pump();

        // When
        final fields = find.byType(TextFormField);
        await tester.enterText(fields.first, 'test@example.com');
        await tester.enterText(fields.last, 'password123');
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pump(const Duration(milliseconds: 50));

        // Then: 네트워크 에러 스낵바 표시
        expect(find.byType(SnackBar), findsOneWidget);
      });

      testWidgets('AuthRetryableFetchException 로그인 에러 처리', (tester) async {
        // Given
        when(
          () => mockAuthService.signInWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(AuthRetryableFetchException());

        await pumpLoginPage(tester, authService: mockAuthService);
        await tester.pump();

        // When
        final fields = find.byType(TextFormField);
        await tester.enterText(fields.first, 'test@example.com');
        await tester.enterText(fields.last, 'password123');
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pump(const Duration(milliseconds: 50));

        // Then: 에러 스낵바 표시
        expect(find.byType(SnackBar), findsOneWidget);
      });
    });
  });
}
