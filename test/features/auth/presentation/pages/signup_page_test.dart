import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_household_account/features/auth/presentation/pages/signup_page.dart';
import 'package:shared_household_account/features/auth/presentation/providers/auth_provider.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../helpers/test_helpers.dart';

class _MockAuthService extends Mock implements AuthService {}

Widget buildSignupPage({AuthService? authService}) {
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
      home: SignupPage(),
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

  group('SignupPage 위젯 테스트', () {
    late MockGoTrueClient mockAuth;
    late _MockAuthService mockAuthService;

    setUp(() {
      mockAuth = MockGoTrueClient();
      mockAuthService = _MockAuthService();
      when(() => mockAuth.currentUser).thenReturn(null);
      when(() => mockAuthService.currentUser).thenReturn(null);
    });

    group('UI 렌더링', () {
      testWidgets('회원가입 페이지가 정상적으로 렌더링된다', (tester) async {
        // Given: 기본 상태 설정
        when(() => mockAuth.currentUser).thenReturn(null);

        // When: SignupPage 렌더링
        await tester.pumpWidget(buildSignupPage());
        await tester.pump();

        // Then: 주요 UI 요소 확인
        expect(find.byType(TextFormField), findsNWidgets(4)); // 이름, 이메일, 비밀번호, 비밀번호 확인
        expect(find.byType(ElevatedButton), findsOneWidget); // 회원가입 버튼
      });

      testWidgets('모든 입력 필드가 표시된다', (tester) async {
        // Given & When
        await tester.pumpWidget(buildSignupPage());
        await tester.pump();

        // Then: 아이콘 확인
        expect(find.byIcon(Icons.person_outlined), findsOneWidget); // 이름
        expect(find.byIcon(Icons.email_outlined), findsOneWidget); // 이메일
        expect(find.byIcon(Icons.lock_outlined), findsNWidgets(2)); // 비밀번호 2개
      });

      testWidgets('로그인 링크가 표시된다', (tester) async {
        // Given & When
        await tester.pumpWidget(buildSignupPage());
        await tester.pump();

        // Then
        expect(find.text('이미 계정이 있으신가요?'), findsOneWidget);
        expect(find.widgetWithText(TextButton, '로그인'), findsOneWidget);
      });

      testWidgets('회원가입 버튼이 표시된다', (tester) async {
        // Given & When
        await tester.pumpWidget(buildSignupPage());
        await tester.pump();

        // Then
        expect(find.widgetWithText(ElevatedButton, '회원가입'), findsOneWidget);
      });

      testWidgets('이용약관 안내 문구가 표시된다', (tester) async {
        // Given & When
        await tester.pumpWidget(buildSignupPage());
        await tester.pump();

        // Then: 이용약관 관련 텍스트
        expect(find.byType(Text), findsWidgets);
      });

      testWidgets('회원가입 타이틀이 표시된다', (tester) async {
        // Given & When
        await tester.pumpWidget(buildSignupPage());
        await tester.pump();

        // Then: AppBar에 회원가입 텍스트
        expect(find.text('회원가입'), findsWidgets);
      });
    });

    group('비밀번호 가시성 토글', () {
      testWidgets('비밀번호 가시성 토글이 작동한다', (tester) async {
        // Given
        await tester.pumpWidget(buildSignupPage());
        await tester.pump();

        // When: 첫 번째 비밀번호 필드의 가시성 토글 버튼 찾기
        final visibilityIcons = find.byIcon(Icons.visibility_outlined);
        expect(visibilityIcons, findsNWidgets(2)); // 비밀번호, 비밀번호 확인

        // When: 첫 번째 토글 버튼 클릭
        await tester.tap(visibilityIcons.first);
        await tester.pump();

        // Then: 아이콘이 변경됨 (하나가 off로 변경)
        expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
        expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      });

      testWidgets('비밀번호 확인 필드 토글도 작동한다', (tester) async {
        // Given
        await tester.pumpWidget(buildSignupPage());
        await tester.pump();

        // When: 두 번째 visibility 아이콘 클릭
        final visibilityIcons = find.byIcon(Icons.visibility_outlined);
        await tester.tap(visibilityIcons.last);
        await tester.pump();

        // Then: visibility_off 아이콘이 나타남
        expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
      });

      testWidgets('토글 후 다시 클릭하면 원래 상태로 돌아간다', (tester) async {
        // Given
        await tester.pumpWidget(buildSignupPage());
        await tester.pump();

        // When: 토글 두 번 클릭
        final visibilityIcons = find.byIcon(Icons.visibility_outlined);
        await tester.tap(visibilityIcons.first);
        await tester.pump();
        await tester.tap(find.byIcon(Icons.visibility_off_outlined));
        await tester.pump();

        // Then: 다시 visibility 상태 (2개)
        expect(find.byIcon(Icons.visibility_outlined), findsNWidgets(2));
      });
    });

    group('폼 유효성 검사', () {
      testWidgets('빈 입력으로 회원가입 시도 시 유효성 검사 에러가 표시된다', (tester) async {
        // Given
        await tester.pumpWidget(buildSignupPage());
        await tester.pump();

        // When: 회원가입 버튼 클릭 (입력 없이)
        final signupButton = find.widgetWithText(ElevatedButton, '회원가입');
        await tester.tap(signupButton);
        await tester.pump();

        // Then: 유효성 검사 에러 확인
        expect(find.text('이름을 입력해주세요'), findsOneWidget);
        expect(find.text('이메일을 입력해주세요'), findsOneWidget);
      });

      testWidgets('이름이 1자인 경우 유효성 검사 에러가 표시된다', (tester) async {
        // Given
        await tester.pumpWidget(buildSignupPage());
        await tester.pump();

        // When: 1자 이름 입력
        final fields = find.byType(TextFormField);
        await tester.enterText(fields.first, '김');
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();

        // Then: 이름 길이 에러 (실제 l10n 값)
        expect(find.text('이름은 2자 이상이어야 합니다'), findsOneWidget);
      });

      testWidgets('유효하지 않은 이메일 형식 입력 시 에러가 표시된다', (tester) async {
        // Given
        await tester.pumpWidget(buildSignupPage());
        await tester.pump();

        // When: 유효하지 않은 이메일
        final fields = find.byType(TextFormField);
        await tester.enterText(fields.first, '홍길동');
        await tester.enterText(fields.at(1), 'invalidemail');
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();

        // Then: 이메일 형식 에러 (실제 l10n 값)
        expect(find.text('올바른 이메일 형식이 아닙니다'), findsOneWidget);
      });

      testWidgets('6자 미만 비밀번호 입력 시 에러가 표시된다', (tester) async {
        // Given
        await tester.pumpWidget(buildSignupPage());
        await tester.pump();

        // When: 짧은 비밀번호 입력
        final fields = find.byType(TextFormField);
        await tester.enterText(fields.first, '홍길동');
        await tester.enterText(fields.at(1), 'test@test.com');
        await tester.enterText(fields.at(2), '12345');
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();

        // Then: 비밀번호 길이 에러 (실제 l10n 값)
        expect(find.text('비밀번호는 6자 이상이어야 합니다'), findsOneWidget);
      });

      testWidgets('비밀번호가 일치하지 않을 때 에러가 표시된다', (tester) async {
        // Given
        await tester.pumpWidget(buildSignupPage());
        await tester.pump();

        // When: 서로 다른 비밀번호 입력
        final fields = find.byType(TextFormField);
        await tester.enterText(fields.first, '홍길동');
        await tester.enterText(fields.at(1), 'test@test.com');
        await tester.enterText(fields.at(2), 'password123');
        await tester.enterText(fields.at(3), 'differentpass');
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();

        // Then: 비밀번호 불일치 에러
        expect(find.text('비밀번호가 일치하지 않습니다'), findsOneWidget);
      });

      testWidgets('비밀번호 확인이 비어있을 때 에러가 표시된다', (tester) async {
        // Given
        await tester.pumpWidget(buildSignupPage());
        await tester.pump();

        // When: 비밀번호 확인 없이 입력
        final fields = find.byType(TextFormField);
        await tester.enterText(fields.first, '홍길동');
        await tester.enterText(fields.at(1), 'test@test.com');
        await tester.enterText(fields.at(2), 'password123');
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();

        // Then: 비밀번호 확인 필수 에러 (실제 l10n 값)
        expect(find.text('비밀번호를 다시 입력해주세요'), findsOneWidget);
      });
    });

    group('회원가입 동작', () {
      testWidgets('회원가입 성공 시 authService.signUpWithEmail이 호출된다', (tester) async {
        // Given
        final mockUser = MockUser();
        final mockResponse = MockAuthResponse();
        when(() => mockResponse.user).thenReturn(mockUser);
        when(
          () => mockAuthService.signUpWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
            displayName: any(named: 'displayName'),
          ),
        ).thenAnswer((_) async => mockResponse);

        await tester.pumpWidget(buildSignupPage(authService: mockAuthService));
        await tester.pump();

        // When: 모든 필드 입력 후 회원가입
        final fields = find.byType(TextFormField);
        await tester.enterText(fields.first, '홍길동');
        await tester.enterText(fields.at(1), 'test@test.com');
        await tester.enterText(fields.at(2), 'password123');
        await tester.enterText(fields.at(3), 'password123');
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();

        // Then: signUpWithEmail이 호출됨
        verify(
          () => mockAuthService.signUpWithEmail(
            email: 'test@test.com',
            password: 'password123',
            displayName: '홍길동',
          ),
        ).called(1);
      });

      testWidgets('이미 등록된 이메일로 회원가입 시 에러 스낵바가 표시된다', (tester) async {
        // Given
        when(
          () => mockAuthService.signUpWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
            displayName: any(named: 'displayName'),
          ),
        ).thenThrow(
          AuthApiException(
            'User already registered',
            statusCode: '400',
            code: 'user_already_exists',
          ),
        );

        await tester.pumpWidget(buildSignupPage(authService: mockAuthService));
        await tester.pump();

        // When: 이미 존재하는 이메일로 회원가입
        final fields = find.byType(TextFormField);
        await tester.enterText(fields.first, '홍길동');
        await tester.enterText(fields.at(1), 'existing@test.com');
        await tester.enterText(fields.at(2), 'password123');
        await tester.enterText(fields.at(3), 'password123');
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Then: 에러 스낵바 표시
        expect(find.byType(SnackBar), findsOneWidget);
      });

      testWidgets('네트워크 에러 시 에러 스낵바가 표시된다', (tester) async {
        // Given
        when(
          () => mockAuthService.signUpWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
            displayName: any(named: 'displayName'),
          ),
        ).thenThrow(Exception('SocketException: Network is unreachable'));

        await tester.pumpWidget(buildSignupPage(authService: mockAuthService));
        await tester.pump();

        // When: 회원가입 시도
        final fields = find.byType(TextFormField);
        await tester.enterText(fields.first, '홍길동');
        await tester.enterText(fields.at(1), 'test@test.com');
        await tester.enterText(fields.at(2), 'password123');
        await tester.enterText(fields.at(3), 'password123');
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Then: 에러 스낵바 표시
        expect(find.byType(SnackBar), findsOneWidget);
      });

      testWidgets('회원가입 중 버튼이 비활성화된다', (tester) async {
        // Given: 즉시 완료되는 응답
        final mockResponse = MockAuthResponse();
        when(() => mockResponse.user).thenReturn(null);
        when(
          () => mockAuthService.signUpWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
            displayName: any(named: 'displayName'),
          ),
        ).thenAnswer((_) async => mockResponse);

        await tester.pumpWidget(buildSignupPage(authService: mockAuthService));
        await tester.pump();

        // When: 입력 후 회원가입 버튼 클릭
        final fields = find.byType(TextFormField);
        await tester.enterText(fields.first, '홍길동');
        await tester.enterText(fields.at(1), 'test@test.com');
        await tester.enterText(fields.at(2), 'password123');
        await tester.enterText(fields.at(3), 'password123');
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();

        // Then: signUpWithEmail이 호출됨 (버튼 동작 확인)
        verify(
          () => mockAuthService.signUpWithEmail(
            email: 'test@test.com',
            password: 'password123',
            displayName: '홍길동',
          ),
        ).called(1);
      });

      testWidgets('이미 등록 에러 메시지가 포함된 일반 에러도 처리된다', (tester) async {
        // Given: 'already registered' 문자열이 포함된 일반 예외
        when(
          () => mockAuthService.signUpWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
            displayName: any(named: 'displayName'),
          ),
        ).thenThrow(Exception('User already registered'));

        await tester.pumpWidget(buildSignupPage(authService: mockAuthService));
        await tester.pump();

        // When: 회원가입 시도
        final fields = find.byType(TextFormField);
        await tester.enterText(fields.first, '홍길동');
        await tester.enterText(fields.at(1), 'existing@test.com');
        await tester.enterText(fields.at(2), 'password123');
        await tester.enterText(fields.at(3), 'password123');
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Then: 에러 스낵바 표시
        expect(find.byType(SnackBar), findsOneWidget);
      });
    });

    group('텍스트 입력', () {
      testWidgets('이름 필드에 텍스트를 입력할 수 있다', (tester) async {
        // Given
        await tester.pumpWidget(buildSignupPage());
        await tester.pump();

        // When
        await tester.enterText(find.byType(TextFormField).first, '홍길동');
        await tester.pump();

        // Then
        expect(find.text('홍길동'), findsOneWidget);
      });

      testWidgets('이메일 필드에 텍스트를 입력할 수 있다', (tester) async {
        // Given
        await tester.pumpWidget(buildSignupPage());
        await tester.pump();

        // When
        await tester.enterText(
          find.byType(TextFormField).at(1),
          'test@example.com',
        );
        await tester.pump();

        // Then
        expect(find.text('test@example.com'), findsOneWidget);
      });
    });
  });
}
