import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/auth/presentation/pages/login_page.dart';
import 'package:shared_household_account/features/auth/presentation/providers/auth_provider.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  group('LoginPage 위젯 테스트', () {
    late MockGoTrueClient mockAuth;

    setUp(() {
      mockAuth = MockGoTrueClient();
    });

    testWidgets('로그인 페이지가 정상적으로 렌더링된다', (tester) async {
      // Given: 기본 상태 설정
      when(() => mockAuth.currentUser).thenReturn(null);

      // When: LoginPage 렌더링
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => const Stream.empty()),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
            home: const LoginPage(),
          ),
        ),
      );
      await tester.pump();

      // Then: 주요 UI 요소 확인
      expect(find.byType(TextFormField), findsNWidgets(2)); // 이메일, 비밀번호
      expect(find.byType(ElevatedButton), findsOneWidget); // 로그인 버튼
      expect(find.byType(OutlinedButton), findsOneWidget); // Google 로그인 버튼
    });

    testWidgets('이메일과 비밀번호 입력 필드가 표시된다', (tester) async {
      // Given
      when(() => mockAuth.currentUser).thenReturn(null);

      // When
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => const Stream.empty()),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
            home: const LoginPage(),
          ),
        ),
      );
      await tester.pump();

      // Then
      expect(find.byIcon(Icons.mail_outline), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    });

    testWidgets('비밀번호 가시성 토글 버튼이 작동한다', (tester) async {
      // Given
      when(() => mockAuth.currentUser).thenReturn(null);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => const Stream.empty()),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
            home: const LoginPage(),
          ),
        ),
      );
      await tester.pump();

      // When: 비밀번호 가시성 아이콘 찾기
      final visibilityOffIcon = find.byIcon(Icons.visibility_off_outlined);
      expect(visibilityOffIcon, findsOneWidget);

      // When: 토글 버튼 클릭
      await tester.tap(visibilityOffIcon);
      await tester.pump();

      // Then: 아이콘이 변경됨
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    });

    testWidgets('회원가입 링크가 표시된다', (tester) async {
      // Given
      when(() => mockAuth.currentUser).thenReturn(null);

      // When
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => const Stream.empty()),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
            home: const LoginPage(),
          ),
        ),
      );
      await tester.pump();

      // Then: 회원가입 텍스트 확인
      expect(find.text('계정이 없으신가요?'), findsOneWidget);
      expect(find.text('회원가입'), findsOneWidget);
    });

    testWidgets('Google 로그인 버튼이 표시된다', (tester) async {
      // Given
      when(() => mockAuth.currentUser).thenReturn(null);

      // When
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => const Stream.empty()),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
            home: const LoginPage(),
          ),
        ),
      );
      await tester.pump();

      // Then
      expect(find.text('Google로 계속하기'), findsOneWidget);
    });

    testWidgets('빈 이메일로 로그인 시도 시 유효성 검사 에러가 표시된다', (tester) async {
      // Given
      when(() => mockAuth.currentUser).thenReturn(null);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => const Stream.empty()),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
            home: const LoginPage(),
          ),
        ),
      );
      await tester.pump();

      // When: 로그인 버튼 클릭 (입력 없이)
      final loginButton = find.byType(ElevatedButton);
      await tester.tap(loginButton);
      await tester.pump();

      // Then: 유효성 검사 에러 확인
      expect(find.text('이메일을 입력해주세요'), findsOneWidget);
    });
  });
}
