import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/auth/presentation/pages/signup_page.dart';
import 'package:shared_household_account/features/auth/presentation/providers/auth_provider.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  group('SignupPage 위젯 테스트', () {
    late MockGoTrueClient mockAuth;

    setUp(() {
      mockAuth = MockGoTrueClient();
    });

    testWidgets('회원가입 페이지가 정상적으로 렌더링된다', (tester) async {
      // Given: 기본 상태 설정
      when(() => mockAuth.currentUser).thenReturn(null);

      // When: SignupPage 렌더링
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => const Stream.empty()),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
            home: const SignupPage(),
          ),
        ),
      );
      await tester.pump();

      // Then: 주요 UI 요소 확인
      expect(find.byType(TextFormField), findsNWidgets(4)); // 이름, 이메일, 비밀번호, 비밀번호 확인
      expect(find.byType(ElevatedButton), findsOneWidget); // 회원가입 버튼
    });

    testWidgets('모든 입력 필드가 표시된다', (tester) async {
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
            home: const SignupPage(),
          ),
        ),
      );
      await tester.pump();

      // Then: 아이콘 확인
      expect(find.byIcon(Icons.person_outlined), findsOneWidget); // 이름
      expect(find.byIcon(Icons.email_outlined), findsOneWidget); // 이메일
      expect(find.byIcon(Icons.lock_outlined), findsNWidgets(2)); // 비밀번호 2개
    });

    testWidgets('비밀번호 가시성 토글이 작동한다', (tester) async {
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
            home: const SignupPage(),
          ),
        ),
      );
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

    testWidgets('로그인 링크가 표시된다', (tester) async {
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
            home: const SignupPage(),
          ),
        ),
      );
      await tester.pump();

      // Then
      expect(find.text('이미 계정이 있으신가요?'), findsOneWidget);
      expect(find.widgetWithText(TextButton, '로그인'), findsOneWidget);
    });

    testWidgets('회원가입 버튼이 표시된다', (tester) async {
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
            home: const SignupPage(),
          ),
        ),
      );
      await tester.pump();

      // Then: 회원가입 버튼 존재 확인
      expect(
        find.widgetWithText(ElevatedButton, '회원가입'),
        findsOneWidget,
      );
    });

    testWidgets('빈 입력으로 회원가입 시도 시 유효성 검사 에러가 표시된다', (tester) async {
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
            home: const SignupPage(),
          ),
        ),
      );
      await tester.pump();

      // When: 회원가입 버튼 클릭 (입력 없이)
      final signupButton = find.widgetWithText(ElevatedButton, '회원가입');
      await tester.tap(signupButton);
      await tester.pump();

      // Then: 유효성 검사 에러 확인
      expect(find.text('이름을 입력해주세요'), findsOneWidget);
      expect(find.text('이메일을 입력해주세요'), findsOneWidget);
    });

  });
}
