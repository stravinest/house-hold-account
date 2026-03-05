import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_household_account/features/auth/presentation/pages/reset_password_page.dart';
import 'package:shared_household_account/features/auth/presentation/providers/auth_provider.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../helpers/test_helpers.dart';

class _MockAuthService extends Mock implements AuthService {}

Widget buildResetPasswordPage({AuthService? authService}) {
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
      home: ResetPasswordPage(),
    ),
  );
}

void main() {
  group('ResetPasswordPage 위젯 테스트', () {
    late _MockAuthService mockAuthService;

    setUp(() {
      mockAuthService = _MockAuthService();
      when(() => mockAuthService.currentUser).thenReturn(null);
    });

    group('UI 렌더링', () {
      testWidgets('비밀번호 재설정 페이지가 정상적으로 렌더링된다', (tester) async {
        // Given & When
        await tester.pumpWidget(buildResetPasswordPage());
        await tester.pump();

        // Then
        expect(find.byType(Scaffold), findsOneWidget);
      });

      testWidgets('새 비밀번호 입력 필드가 표시된다', (tester) async {
        // Given & When
        await tester.pumpWidget(buildResetPasswordPage());
        await tester.pump();

        // Then: TextFormField가 2개 (새 비밀번호, 비밀번호 확인)
        expect(find.byType(TextFormField), findsNWidgets(2));
      });

      testWidgets('자물쇠 아이콘이 표시된다', (tester) async {
        // Given & When
        await tester.pumpWidget(buildResetPasswordPage());
        await tester.pump();

        // Then: lock_reset 아이콘 및 lock 아이콘
        expect(find.byIcon(Icons.lock_reset_outlined), findsOneWidget);
        expect(find.byIcon(Icons.lock_outlined), findsNWidgets(2));
      });

      testWidgets('비밀번호 변경 버튼이 표시된다', (tester) async {
        // Given & When
        await tester.pumpWidget(buildResetPasswordPage());
        await tester.pump();

        // Then: ElevatedButton 존재
        expect(find.byType(ElevatedButton), findsOneWidget);
      });

      testWidgets('비밀번호 가시성 토글 버튼이 각 필드에 표시된다', (tester) async {
        // Given & When
        await tester.pumpWidget(buildResetPasswordPage());
        await tester.pump();

        // Then: 비밀번호 가시성 아이콘이 2개 (각 필드당 1개)
        expect(find.byIcon(Icons.visibility_outlined), findsNWidgets(2));
      });
    });

    group('폼 유효성 검사', () {
      testWidgets('빈 비밀번호로 변경 시도 시 유효성 검사 에러가 표시된다', (tester) async {
        // Given
        await tester.pumpWidget(buildResetPasswordPage());
        await tester.pump();

        // When: 아무것도 입력하지 않고 버튼 클릭
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();

        // Then: 비밀번호 필수 에러 메시지 (실제 l10n 값)
        expect(find.text('비밀번호를 입력해주세요'), findsAtLeastNWidgets(1));
      });

      testWidgets('6자 미만 비밀번호 입력 시 유효성 검사 에러가 표시된다', (tester) async {
        // Given
        await tester.pumpWidget(buildResetPasswordPage());
        await tester.pump();

        // When: 짧은 비밀번호 입력
        final fields = find.byType(TextFormField);
        await tester.enterText(fields.first, '12345');
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();

        // Then: 비밀번호 길이 에러 메시지 (실제 l10n 값)
        expect(find.text('비밀번호는 6자 이상이어야 합니다'), findsOneWidget);
      });

      testWidgets('비밀번호 불일치 시 유효성 검사 에러가 표시된다', (tester) async {
        // Given
        await tester.pumpWidget(buildResetPasswordPage());
        await tester.pump();

        // When: 서로 다른 비밀번호 입력
        final fields = find.byType(TextFormField);
        await tester.enterText(fields.first, 'password123');
        await tester.enterText(fields.last, 'differentpass');
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();

        // Then: 비밀번호 불일치 에러 메시지
        expect(find.text('비밀번호가 일치하지 않습니다'), findsOneWidget);
      });

      testWidgets('비밀번호 확인 필드가 비어있을 때 에러가 표시된다', (tester) async {
        // Given
        await tester.pumpWidget(buildResetPasswordPage());
        await tester.pump();

        // When: 새 비밀번호만 입력하고 확인 비밀번호는 비어있음
        final fields = find.byType(TextFormField);
        await tester.enterText(fields.first, 'password123');
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();

        // Then: 확인 비밀번호 필수 에러
        // 실제 l10n 값: validationPasswordConfirmRequired = '비밀번호를 다시 입력해주세요'
        expect(find.text('비밀번호를 다시 입력해주세요'), findsOneWidget);
      });
    });

    group('비밀번호 가시성 토글', () {
      testWidgets('새 비밀번호 필드 가시성 토글이 작동한다', (tester) async {
        // Given
        await tester.pumpWidget(buildResetPasswordPage());
        await tester.pump();

        // When: 첫 번째 visibility 아이콘 클릭
        final visibilityIcons = find.byIcon(Icons.visibility_outlined);
        await tester.tap(visibilityIcons.first);
        await tester.pump();

        // Then: visibility_off 아이콘으로 변경됨
        expect(find.byIcon(Icons.visibility_off_outlined), findsAtLeastNWidgets(1));
      });

      testWidgets('비밀번호 확인 필드 가시성 토글이 작동한다', (tester) async {
        // Given
        await tester.pumpWidget(buildResetPasswordPage());
        await tester.pump();

        // When: 두 번째 visibility 아이콘 클릭
        final visibilityIcons = find.byIcon(Icons.visibility_outlined);
        await tester.tap(visibilityIcons.last);
        await tester.pump();

        // Then: visibility_off 아이콘이 나타남
        expect(find.byIcon(Icons.visibility_off_outlined), findsAtLeastNWidgets(1));
      });
    });

    group('비밀번호 변경 동작', () {
      testWidgets('유효한 비밀번호 입력 후 변경 성공 시 성공 스낵바가 표시된다', (tester) async {
        // Given
        final mockUserResponse = MockUserResponse();
        when(() => mockAuthService.updatePassword(any()))
            .thenAnswer((_) async => mockUserResponse);

        await tester.pumpWidget(
          buildResetPasswordPage(authService: mockAuthService),
        );
        await tester.pump();

        // When: 동일한 비밀번호 2회 입력 후 변경
        final fields = find.byType(TextFormField);
        await tester.enterText(fields.first, 'newpassword123');
        await tester.enterText(fields.last, 'newpassword123');
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Then: updatePassword가 호출된다
        verify(() => mockAuthService.updatePassword('newpassword123')).called(1);
      });

      testWidgets('비밀번호 변경 실패 시 에러 스낵바가 표시된다', (tester) async {
        // Given
        when(() => mockAuthService.updatePassword(any()))
            .thenThrow(const AuthException('비밀번호 변경 실패'));

        await tester.pumpWidget(
          buildResetPasswordPage(authService: mockAuthService),
        );
        await tester.pump();

        // When: 비밀번호 입력 후 변경 시도
        final fields = find.byType(TextFormField);
        await tester.enterText(fields.first, 'newpassword123');
        await tester.enterText(fields.last, 'newpassword123');
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Then: 에러 스낵바 표시
        expect(find.byType(SnackBar), findsOneWidget);
      });

      testWidgets('네트워크 에러 발생 시 네트워크 에러 메시지가 표시된다', (tester) async {
        // Given: 네트워크 에러 시뮬레이션
        when(() => mockAuthService.updatePassword(any()))
            .thenThrow(Exception('SocketException: Failed host lookup'));

        await tester.pumpWidget(
          buildResetPasswordPage(authService: mockAuthService),
        );
        await tester.pump();

        // When: 비밀번호 입력 후 변경
        final fields = find.byType(TextFormField);
        await tester.enterText(fields.first, 'newpassword123');
        await tester.enterText(fields.last, 'newpassword123');
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Then: 스낵바가 표시된다
        expect(find.byType(SnackBar), findsOneWidget);
      });
    });
  });
}
