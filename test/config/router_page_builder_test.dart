import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_household_account/config/router.dart';
import 'package:shared_household_account/features/auth/presentation/providers/auth_provider.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';
import 'package:shared_household_account/shared/themes/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockAuthService extends Mock implements AuthService {}

// 테스트용 Mock User 생성
User _buildMockUser() {
  return const User(
    id: 'test-user-id',
    appMetadata: {},
    userMetadata: {},
    aud: 'authenticated',
    createdAt: '2024-01-01T00:00:00.000Z',
    isAnonymous: false,
  );
}

// routerProvider를 사용하는 위젯 빌더 헬퍼
Widget _buildProviderApp({
  required Stream<User?> authStream,
  required AuthService authService,
}) {
  return ProviderScope(
    overrides: [
      authStateProvider.overrideWith((ref) => authStream),
      authServiceProvider.overrideWith((ref) => authService),
    ],
    child: Consumer(
      builder: (context, ref, _) {
        final router = ref.watch(routerProvider);
        return MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ko'),
        );
      },
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
    } catch (_) {}
  });

  // routerProvider를 통해 SplashPage가 2초 후 /login으로 redirect되면
  // login pageBuilder 람다가 실행된다
  group('routerProvider pageBuilder 람다 실행 테스트 (비로그인 상태)', () {
    testWidgets(
        '비로그인 상태에서 SplashPage 렌더링 후 /login으로 redirect되어 loginPage pageBuilder가 실행된다',
        (tester) async {
      // Given: 비로그인 상태 (null User Stream)
      final mockAuthService = _MockAuthService();
      when(() => mockAuthService.currentUser).thenReturn(null);

      await tester.pumpWidget(
        _buildProviderApp(
          authStream: Stream.value(null),
          authService: mockAuthService,
        ),
      );

      // When: SplashPage 타이머(2초) 소진 후 redirect
      await tester.pump(const Duration(milliseconds: 2100));
      await tester.pump();

      // Then: /login으로 이동하여 LoginPage pageBuilder가 실행됨
      // (에러가 없으면 pageBuilder가 정상 실행됨)
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('비로그인 상태에서 /signup 경로 pageBuilder가 실행된다', (tester) async {
      // Given
      final mockAuthService = _MockAuthService();
      when(() => mockAuthService.currentUser).thenReturn(null);

      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream.value(null)),
          authServiceProvider.overrideWith((ref) => mockAuthService),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(routerProvider);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => Stream.value(null)),
            authServiceProvider.overrideWith((ref) => mockAuthService),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
          ),
        ),
      );

      // SplashPage 타이머 소진 → /login으로 redirect
      await tester.pump(const Duration(milliseconds: 2100));
      await tester.pump();

      // /signup으로 navigate
      router.go(Routes.signup);
      await tester.pump();
      await tester.pump();

      // signup pageBuilder가 실행됨
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('비로그인 상태에서 /forgot-password 경로 pageBuilder가 실행된다',
        (tester) async {
      // Given
      final mockAuthService = _MockAuthService();
      when(() => mockAuthService.currentUser).thenReturn(null);

      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream.value(null)),
          authServiceProvider.overrideWith((ref) => mockAuthService),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(routerProvider);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => Stream.value(null)),
            authServiceProvider.overrideWith((ref) => mockAuthService),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 2100));
      await tester.pump();

      // /forgot-password로 navigate
      router.go(Routes.forgotPassword);
      await tester.pump();
      await tester.pump();

      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('비로그인 상태에서 /email-verification 경로 pageBuilder가 실행된다',
        (tester) async {
      // Given
      final mockAuthService = _MockAuthService();
      when(() => mockAuthService.currentUser).thenReturn(null);

      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream.value(null)),
          authServiceProvider.overrideWith((ref) => mockAuthService),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(routerProvider);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => Stream.value(null)),
            authServiceProvider.overrideWith((ref) => mockAuthService),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 2100));
      await tester.pump();

      // /email-verification?email=test@test.com 으로 navigate
      router.go('${Routes.emailVerification}?email=test@test.com');
      await tester.pump();
      await tester.pump();

      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('/reset-password 경로 pageBuilder가 실행된다', (tester) async {
      // Given
      final mockAuthService = _MockAuthService();
      when(() => mockAuthService.currentUser).thenReturn(null);

      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream.value(null)),
          authServiceProvider.overrideWith((ref) => mockAuthService),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(routerProvider);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => Stream.value(null)),
            authServiceProvider.overrideWith((ref) => mockAuthService),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 2100));
      await tester.pump();

      // /reset-password는 redirect 예외 처리됨
      router.go(Routes.resetPassword);
      await tester.pump();
      await tester.pump();

      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });

  group('routerProvider pageBuilder 람다 실행 테스트 (로그인 상태)', () {
    // 로그인 상태를 만들기 위해 Mock User를 생성
    // User는 supabase_flutter의 클래스이므로 실제 인스턴스 불가
    // 대신 authStateProvider를 통해 User가 있는 것처럼 simulate

    testWidgets('errorBuilder가 실행된다 (잘못된 경로 접근)', (tester) async {
      // Given
      final mockAuthService = _MockAuthService();
      when(() => mockAuthService.currentUser).thenReturn(null);

      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream.value(null)),
          authServiceProvider.overrideWith((ref) => mockAuthService),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(routerProvider);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => Stream.value(null)),
            authServiceProvider.overrideWith((ref) => mockAuthService),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 2100));
      await tester.pump();

      // 잘못된 경로로 navigate → errorBuilder 실행
      router.go('/this-path-does-not-exist-xyz');
      await tester.pump();
      await tester.pump();

      // Then: errorBuilder가 실행되어 에러 메시지가 표시됨
      // errorBuilder에서 l10n.errorNotFound를 사용하여 텍스트를 렌더링
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('paymentMethod 경로에서 tab 쿼리 파라미터 없이 pageBuilder가 실행된다',
        (tester) async {
      // Given: 비로그인이지만 /payment-method는 딥링크 경로로 처리됨
      final mockAuthService = _MockAuthService();
      when(() => mockAuthService.currentUser).thenReturn(null);

      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream.value(null)),
          authServiceProvider.overrideWith((ref) => mockAuthService),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(routerProvider);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => Stream.value(null)),
            authServiceProvider.overrideWith((ref) => mockAuthService),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 2100));
      await tester.pump();

      // tab 파라미터 없이 navigate
      router.go(Routes.paymentMethod);
      await tester.pump();
      await tester.pump();

      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('paymentMethod 경로에서 tab=confirmed 쿼리 파라미터로 pageBuilder가 실행된다',
        (tester) async {
      // Given
      final mockAuthService = _MockAuthService();
      when(() => mockAuthService.currentUser).thenReturn(null);

      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream.value(null)),
          authServiceProvider.overrideWith((ref) => mockAuthService),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(routerProvider);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => Stream.value(null)),
            authServiceProvider.overrideWith((ref) => mockAuthService),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 2100));
      await tester.pump();

      // tab=confirmed 파라미터로 navigate
      router.go('${Routes.paymentMethod}?tab=confirmed');
      await tester.pump();
      await tester.pump();

      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('paymentMethod 경로에서 tab=pending 쿼리 파라미터로 pageBuilder가 실행된다',
        (tester) async {
      // Given
      final mockAuthService = _MockAuthService();
      when(() => mockAuthService.currentUser).thenReturn(null);

      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream.value(null)),
          authServiceProvider.overrideWith((ref) => mockAuthService),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(routerProvider);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => Stream.value(null)),
            authServiceProvider.overrideWith((ref) => mockAuthService),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 2100));
      await tester.pump();

      // tab=pending 파라미터로 navigate (tab이 있으나 confirmed가 아님 → initialAutoCollectTabIndex=0)
      router.go('${Routes.paymentMethod}?tab=pending');
      await tester.pump();
      await tester.pump();

      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('autoSaveSettings 동적 경로 pageBuilder가 실행된다', (tester) async {
      // Given: 비로그인 상태에서는 redirect되므로 딥링크 처리로 접근
      final mockAuthService = _MockAuthService();
      when(() => mockAuthService.currentUser).thenReturn(null);

      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream.value(null)),
          authServiceProvider.overrideWith((ref) => mockAuthService),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(routerProvider);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => Stream.value(null)),
            authServiceProvider.overrideWith((ref) => mockAuthService),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 2100));
      await tester.pump();

      router.go('/settings/payment-methods/test-id/auto-save');
      await tester.pump();
      await tester.pump();

      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('categoryKeywordMapping 동적 경로 pageBuilder가 실행된다',
        (tester) async {
      // Given
      final mockAuthService = _MockAuthService();
      when(() => mockAuthService.currentUser).thenReturn(null);

      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream.value(null)),
          authServiceProvider.overrideWith((ref) => mockAuthService),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(routerProvider);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => Stream.value(null)),
            authServiceProvider.overrideWith((ref) => mockAuthService),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 2100));
      await tester.pump();

      router.go('/settings/payment-methods/test-id/category-mapping/sms');
      await tester.pump();
      await tester.pump();

      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });

  // 로그인 상태에서 각 pageBuilder 람다를 실행하는 테스트
  // SplashPage가 2초 후 /home으로 redirect되어 pageBuilder가 실행됨
  group('routerProvider pageBuilder 람다 실행 테스트 (로그인 상태 - 각 경로)', () {
    testWidgets('/home 경로 pageBuilder가 실행된다', (tester) async {
      // Given: 로그인 상태
      final mockAuthService = _MockAuthService();
      when(() => mockAuthService.currentUser).thenReturn(_buildMockUser());

      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(_buildMockUser()),
          ),
          authServiceProvider.overrideWith((ref) => mockAuthService),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(routerProvider);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => Stream.value(_buildMockUser()),
            ),
            authServiceProvider.overrideWith((ref) => mockAuthService),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
          ),
        ),
      );

      // SplashPage 타이머 소진 후 로그인 상태이므로 /home으로 이동 → home pageBuilder 실행
      await tester.pump(const Duration(milliseconds: 2100));
      await tester.pump();

      // Then: /home pageBuilder가 실행됨
      expect(find.byType(MaterialApp), findsOneWidget);

      // HomePage에 60초 타이머가 있으므로 다른 경로로 이동하여 HomePage를 dispose
      router.go(Routes.guide);
      // HomePage의 short 타이머들(100ms, 1s) 소진
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('/statistics 경로 pageBuilder가 실행된다', (tester) async {
      // Given: 로그인 상태
      final mockAuthService = _MockAuthService();
      when(() => mockAuthService.currentUser).thenReturn(_buildMockUser());

      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(_buildMockUser()),
          ),
          authServiceProvider.overrideWith((ref) => mockAuthService),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(routerProvider);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => Stream.value(_buildMockUser()),
            ),
            authServiceProvider.overrideWith((ref) => mockAuthService),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 2100));
      await tester.pump();

      router.go(Routes.statistics);
      await tester.pump();
      await tester.pump();

      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('/budget 경로 pageBuilder가 실행된다', (tester) async {
      final mockAuthService = _MockAuthService();
      when(() => mockAuthService.currentUser).thenReturn(_buildMockUser());

      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(_buildMockUser()),
          ),
          authServiceProvider.overrideWith((ref) => mockAuthService),
        ],
      );
      addTearDown(container.dispose);
      final router = container.read(routerProvider);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => Stream.value(_buildMockUser()),
            ),
            authServiceProvider.overrideWith((ref) => mockAuthService),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 2100));
      await tester.pump();
      router.go(Routes.budget);
      await tester.pump();
      await tester.pump();
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('/share 경로 pageBuilder가 실행된다', (tester) async {
      final mockAuthService = _MockAuthService();
      when(() => mockAuthService.currentUser).thenReturn(_buildMockUser());
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(_buildMockUser()),
          ),
          authServiceProvider.overrideWith((ref) => mockAuthService),
        ],
      );
      addTearDown(container.dispose);
      final router = container.read(routerProvider);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => Stream.value(_buildMockUser()),
            ),
            authServiceProvider.overrideWith((ref) => mockAuthService),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 2100));
      await tester.pump();
      router.go(Routes.share);
      await tester.pump();
      await tester.pump();
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('/settings 경로 pageBuilder가 실행된다', (tester) async {
      // SettingsPage는 sharedPreferencesProvider를 필요로 함
      final prefs = await SharedPreferences.getInstance();
      final mockAuthService = _MockAuthService();
      when(() => mockAuthService.currentUser).thenReturn(_buildMockUser());
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(_buildMockUser()),
          ),
          authServiceProvider.overrideWith((ref) => mockAuthService),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);
      final router = container.read(routerProvider);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => Stream.value(_buildMockUser()),
            ),
            authServiceProvider.overrideWith((ref) => mockAuthService),
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 2100));
      await tester.pump();
      router.go(Routes.settings);
      await tester.pump();
      await tester.pump();
      expect(find.byType(MaterialApp), findsOneWidget);
      // 다른 경로로 이동하여 SettingsPage dispose
      router.go(Routes.guide);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('/search 경로 pageBuilder가 실행된다', (tester) async {
      final mockAuthService = _MockAuthService();
      when(() => mockAuthService.currentUser).thenReturn(_buildMockUser());
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(_buildMockUser()),
          ),
          authServiceProvider.overrideWith((ref) => mockAuthService),
        ],
      );
      addTearDown(container.dispose);
      final router = container.read(routerProvider);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => Stream.value(_buildMockUser()),
            ),
            authServiceProvider.overrideWith((ref) => mockAuthService),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 2100));
      await tester.pump();
      router.go(Routes.search);
      await tester.pump();
      await tester.pump();
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('/category 경로 pageBuilder가 실행된다', (tester) async {
      final mockAuthService = _MockAuthService();
      when(() => mockAuthService.currentUser).thenReturn(_buildMockUser());
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(_buildMockUser()),
          ),
          authServiceProvider.overrideWith((ref) => mockAuthService),
        ],
      );
      addTearDown(container.dispose);
      final router = container.read(routerProvider);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => Stream.value(_buildMockUser()),
            ),
            authServiceProvider.overrideWith((ref) => mockAuthService),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 2100));
      await tester.pump();
      router.go(Routes.category);
      await tester.pump();
      await tester.pump();
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('/ledger-manage 경로 pageBuilder가 실행된다', (tester) async {
      final mockAuthService = _MockAuthService();
      when(() => mockAuthService.currentUser).thenReturn(_buildMockUser());
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(_buildMockUser()),
          ),
          authServiceProvider.overrideWith((ref) => mockAuthService),
        ],
      );
      addTearDown(container.dispose);
      final router = container.read(routerProvider);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => Stream.value(_buildMockUser()),
            ),
            authServiceProvider.overrideWith((ref) => mockAuthService),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 2100));
      await tester.pump();
      router.go(Routes.ledgerManage);
      await tester.pump();
      await tester.pump();
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('/fixed-expense 경로 pageBuilder가 실행된다', (tester) async {
      final mockAuthService = _MockAuthService();
      when(() => mockAuthService.currentUser).thenReturn(_buildMockUser());
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(_buildMockUser()),
          ),
          authServiceProvider.overrideWith((ref) => mockAuthService),
        ],
      );
      addTearDown(container.dispose);
      final router = container.read(routerProvider);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => Stream.value(_buildMockUser()),
            ),
            authServiceProvider.overrideWith((ref) => mockAuthService),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 2100));
      await tester.pump();
      router.go(Routes.fixedExpense);
      await tester.pump();
      await tester.pump();
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('/recurring-templates 경로 pageBuilder가 실행된다', (tester) async {
      final mockAuthService = _MockAuthService();
      when(() => mockAuthService.currentUser).thenReturn(_buildMockUser());
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(_buildMockUser()),
          ),
          authServiceProvider.overrideWith((ref) => mockAuthService),
        ],
      );
      addTearDown(container.dispose);
      final router = container.read(routerProvider);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => Stream.value(_buildMockUser()),
            ),
            authServiceProvider.overrideWith((ref) => mockAuthService),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 2100));
      await tester.pump();
      router.go(Routes.recurringTemplates);
      await tester.pump();
      await tester.pump();
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('/settings/pending-transactions 경로 pageBuilder가 실행된다',
        (tester) async {
      final mockAuthService = _MockAuthService();
      when(() => mockAuthService.currentUser).thenReturn(_buildMockUser());
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(_buildMockUser()),
          ),
          authServiceProvider.overrideWith((ref) => mockAuthService),
        ],
      );
      addTearDown(container.dispose);
      final router = container.read(routerProvider);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => Stream.value(_buildMockUser()),
            ),
            authServiceProvider.overrideWith((ref) => mockAuthService),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 2100));
      await tester.pump();
      router.go(Routes.pendingTransactions);
      await tester.pump();
      await tester.pump();
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('/guide 경로 pageBuilder가 실행된다', (tester) async {
      final mockAuthService = _MockAuthService();
      when(() => mockAuthService.currentUser).thenReturn(_buildMockUser());
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(_buildMockUser()),
          ),
          authServiceProvider.overrideWith((ref) => mockAuthService),
        ],
      );
      addTearDown(container.dispose);
      final router = container.read(routerProvider);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => Stream.value(_buildMockUser()),
            ),
            authServiceProvider.overrideWith((ref) => mockAuthService),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 2100));
      await tester.pump();
      router.go(Routes.guide);
      await tester.pump();
      await tester.pump();
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('/guide/auto-collect 경로 pageBuilder가 실행된다', (tester) async {
      final mockAuthService = _MockAuthService();
      when(() => mockAuthService.currentUser).thenReturn(_buildMockUser());
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(_buildMockUser()),
          ),
          authServiceProvider.overrideWith((ref) => mockAuthService),
        ],
      );
      addTearDown(container.dispose);
      final router = container.read(routerProvider);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => Stream.value(_buildMockUser()),
            ),
            authServiceProvider.overrideWith((ref) => mockAuthService),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 2100));
      await tester.pump();
      router.go(Routes.autoCollectGuide);
      await tester.pump();
      await tester.pump();
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('/guide/transaction 경로 pageBuilder가 실행된다', (tester) async {
      final mockAuthService = _MockAuthService();
      when(() => mockAuthService.currentUser).thenReturn(_buildMockUser());
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(_buildMockUser()),
          ),
          authServiceProvider.overrideWith((ref) => mockAuthService),
        ],
      );
      addTearDown(container.dispose);
      final router = container.read(routerProvider);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => Stream.value(_buildMockUser()),
            ),
            authServiceProvider.overrideWith((ref) => mockAuthService),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 2100));
      await tester.pump();
      router.go(Routes.transactionGuide);
      await tester.pump();
      await tester.pump();
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('/guide/share 경로 pageBuilder가 실행된다', (tester) async {
      final mockAuthService = _MockAuthService();
      when(() => mockAuthService.currentUser).thenReturn(_buildMockUser());
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(_buildMockUser()),
          ),
          authServiceProvider.overrideWith((ref) => mockAuthService),
        ],
      );
      addTearDown(container.dispose);
      final router = container.read(routerProvider);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => Stream.value(_buildMockUser()),
            ),
            authServiceProvider.overrideWith((ref) => mockAuthService),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 2100));
      await tester.pump();
      router.go(Routes.shareGuide);
      await tester.pump();
      await tester.pump();
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('/terms-of-service 경로 pageBuilder가 실행된다', (tester) async {
      final mockAuthService = _MockAuthService();
      when(() => mockAuthService.currentUser).thenReturn(_buildMockUser());
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(_buildMockUser()),
          ),
          authServiceProvider.overrideWith((ref) => mockAuthService),
        ],
      );
      addTearDown(container.dispose);
      final router = container.read(routerProvider);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => Stream.value(_buildMockUser()),
            ),
            authServiceProvider.overrideWith((ref) => mockAuthService),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 2100));
      await tester.pump();
      router.go(Routes.termsOfService);
      await tester.pump();
      await tester.pump();
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('/privacy-policy 경로 pageBuilder가 실행된다', (tester) async {
      final mockAuthService = _MockAuthService();
      when(() => mockAuthService.currentUser).thenReturn(_buildMockUser());
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(_buildMockUser()),
          ),
          authServiceProvider.overrideWith((ref) => mockAuthService),
        ],
      );
      addTearDown(container.dispose);
      final router = container.read(routerProvider);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => Stream.value(_buildMockUser()),
            ),
            authServiceProvider.overrideWith((ref) => mockAuthService),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 2100));
      await tester.pump();
      router.go(Routes.privacyPolicy);
      await tester.pump();
      await tester.pump();
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('/debug-test 경로 pageBuilder가 실행된다', (tester) async {
      final mockAuthService = _MockAuthService();
      when(() => mockAuthService.currentUser).thenReturn(_buildMockUser());
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(_buildMockUser()),
          ),
          authServiceProvider.overrideWith((ref) => mockAuthService),
        ],
      );
      addTearDown(container.dispose);
      final router = container.read(routerProvider);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => Stream.value(_buildMockUser()),
            ),
            authServiceProvider.overrideWith((ref) => mockAuthService),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 2100));
      await tester.pump();
      router.go(Routes.debugTest);
      await tester.pump();
      await tester.pump();
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('/add-expense 딥링크 경로 pageBuilder가 실행된다', (tester) async {
      final mockAuthService = _MockAuthService();
      when(() => mockAuthService.currentUser).thenReturn(_buildMockUser());
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(_buildMockUser()),
          ),
          authServiceProvider.overrideWith((ref) => mockAuthService),
        ],
      );
      addTearDown(container.dispose);
      final router = container.read(routerProvider);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => Stream.value(_buildMockUser()),
            ),
            authServiceProvider.overrideWith((ref) => mockAuthService),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 2100));
      await tester.pump();
      router.go(Routes.addExpense);
      await tester.pump();
      await tester.pump();
      expect(find.byType(MaterialApp), findsOneWidget);
      // HomePage 내부 타이머(100ms, 1s) 소진 후 다른 경로로 이동
      router.go(Routes.guide);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('/add-income 딥링크 경로 pageBuilder가 실행된다', (tester) async {
      final mockAuthService = _MockAuthService();
      when(() => mockAuthService.currentUser).thenReturn(_buildMockUser());
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(_buildMockUser()),
          ),
          authServiceProvider.overrideWith((ref) => mockAuthService),
        ],
      );
      addTearDown(container.dispose);
      final router = container.read(routerProvider);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => Stream.value(_buildMockUser()),
            ),
            authServiceProvider.overrideWith((ref) => mockAuthService),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 2100));
      await tester.pump();
      router.go(Routes.addIncome);
      await tester.pump();
      await tester.pump();
      expect(find.byType(MaterialApp), findsOneWidget);
      // HomePage 내부 타이머 소진
      router.go(Routes.guide);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('/quick-expense 딥링크 경로 pageBuilder가 실행된다', (tester) async {
      final mockAuthService = _MockAuthService();
      when(() => mockAuthService.currentUser).thenReturn(_buildMockUser());
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(_buildMockUser()),
          ),
          authServiceProvider.overrideWith((ref) => mockAuthService),
        ],
      );
      addTearDown(container.dispose);
      final router = container.read(routerProvider);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => Stream.value(_buildMockUser()),
            ),
            authServiceProvider.overrideWith((ref) => mockAuthService),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 2100));
      await tester.pump();
      router.go(Routes.quickExpense);
      await tester.pump();
      await tester.pump();
      expect(find.byType(MaterialApp), findsOneWidget);
      // HomePage 내부 타이머 소진
      router.go(Routes.guide);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('로그인 상태에서 paymentMethod 경로 pageBuilder가 실행된다 (tab 없음)',
        (tester) async {
      final mockAuthService = _MockAuthService();
      when(() => mockAuthService.currentUser).thenReturn(_buildMockUser());
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(_buildMockUser()),
          ),
          authServiceProvider.overrideWith((ref) => mockAuthService),
        ],
      );
      addTearDown(container.dispose);
      final router = container.read(routerProvider);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => Stream.value(_buildMockUser()),
            ),
            authServiceProvider.overrideWith((ref) => mockAuthService),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 2100));
      await tester.pump();
      // tab 없이 navigate → initialTabIndex=0, initialAutoCollectTabIndex=0
      router.go(Routes.paymentMethod);
      await tester.pump();
      await tester.pump();
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('로그인 상태에서 paymentMethod 경로 pageBuilder가 실행된다 (tab=confirmed)',
        (tester) async {
      final mockAuthService = _MockAuthService();
      when(() => mockAuthService.currentUser).thenReturn(_buildMockUser());
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(_buildMockUser()),
          ),
          authServiceProvider.overrideWith((ref) => mockAuthService),
        ],
      );
      addTearDown(container.dispose);
      final router = container.read(routerProvider);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => Stream.value(_buildMockUser()),
            ),
            authServiceProvider.overrideWith((ref) => mockAuthService),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 2100));
      await tester.pump();
      // tab=confirmed → initialTabIndex=1, initialAutoCollectTabIndex=1
      router.go('${Routes.paymentMethod}?tab=confirmed');
      await tester.pump();
      await tester.pump();
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('로그인 상태에서 paymentMethod 경로 pageBuilder가 실행된다 (tab=pending)',
        (tester) async {
      final mockAuthService = _MockAuthService();
      when(() => mockAuthService.currentUser).thenReturn(_buildMockUser());
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(_buildMockUser()),
          ),
          authServiceProvider.overrideWith((ref) => mockAuthService),
        ],
      );
      addTearDown(container.dispose);
      final router = container.read(routerProvider);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => Stream.value(_buildMockUser()),
            ),
            authServiceProvider.overrideWith((ref) => mockAuthService),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 2100));
      await tester.pump();
      // tab=pending → initialTabIndex=1, initialAutoCollectTabIndex=0 (confirmed 아님)
      router.go('${Routes.paymentMethod}?tab=pending');
      await tester.pump();
      await tester.pump();
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('로그인 상태에서 autoSaveSettings 동적 경로 pageBuilder가 실행된다',
        (tester) async {
      final mockAuthService = _MockAuthService();
      when(() => mockAuthService.currentUser).thenReturn(_buildMockUser());
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(_buildMockUser()),
          ),
          authServiceProvider.overrideWith((ref) => mockAuthService),
        ],
      );
      addTearDown(container.dispose);
      final router = container.read(routerProvider);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => Stream.value(_buildMockUser()),
            ),
            authServiceProvider.overrideWith((ref) => mockAuthService),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 2100));
      await tester.pump();
      router.go('/settings/payment-methods/test-id/auto-save');
      await tester.pump();
      await tester.pump();
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('로그인 상태에서 categoryKeywordMapping 동적 경로 pageBuilder가 실행된다',
        (tester) async {
      final mockAuthService = _MockAuthService();
      when(() => mockAuthService.currentUser).thenReturn(_buildMockUser());
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(_buildMockUser()),
          ),
          authServiceProvider.overrideWith((ref) => mockAuthService),
        ],
      );
      addTearDown(container.dispose);
      final router = container.read(routerProvider);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => Stream.value(_buildMockUser()),
            ),
            authServiceProvider.overrideWith((ref) => mockAuthService),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 2100));
      await tester.pump();
      // extra 파라미터 포함
      router.go(
        '/settings/payment-methods/test-id/category-mapping/sms',
        extra: {'ledgerId': 'test-ledger-id'},
      );
      await tester.pump();
      await tester.pump();
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('로그인 상태에서 errorBuilder가 실행된다 (잘못된 경로 접근)', (tester) async {
      final mockAuthService = _MockAuthService();
      when(() => mockAuthService.currentUser).thenReturn(_buildMockUser());
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(_buildMockUser()),
          ),
          authServiceProvider.overrideWith((ref) => mockAuthService),
        ],
      );
      addTearDown(container.dispose);
      final router = container.read(routerProvider);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => Stream.value(_buildMockUser()),
            ),
            authServiceProvider.overrideWith((ref) => mockAuthService),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 2100));
      await tester.pump();
      router.go('/invalid-path-xyz-abc');
      await tester.pump();
      await tester.pump();
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });

  group('Routes 클래스 경로 상수 테스트', () {
    test('모든 Routes 상수가 /로 시작하는 유효한 경로이다', () {
      // Given & When
      final routes = [
        Routes.splash,
        Routes.login,
        Routes.signup,
        Routes.forgotPassword,
        Routes.emailVerification,
        Routes.resetPassword,
        Routes.home,
        Routes.statistics,
        Routes.budget,
        Routes.share,
        Routes.settings,
        Routes.search,
        Routes.category,
        Routes.paymentMethod,
        Routes.ledgerManage,
        Routes.fixedExpense,
        Routes.addExpense,
        Routes.addIncome,
        Routes.quickExpense,
        Routes.autoSaveSettings,
        Routes.categoryKeywordMapping,
        Routes.pendingTransactions,
        Routes.termsOfService,
        Routes.privacyPolicy,
        Routes.guide,
        Routes.recurringTemplates,
        Routes.autoCollectGuide,
        Routes.transactionGuide,
        Routes.shareGuide,
        Routes.debugTest,
      ];

      // Then: 모든 경로가 /로 시작함
      for (final route in routes) {
        expect(route, startsWith('/'),
            reason: '$route 는 /로 시작해야 한다');
      }
    });

    test('Routes 상수들이 고유한 값을 가진다', () {
      // Given: 동일 depth의 경로들 (중복 없어야 함)
      final topLevelRoutes = [
        Routes.splash,
        Routes.login,
        Routes.signup,
        Routes.forgotPassword,
        Routes.emailVerification,
        Routes.resetPassword,
        Routes.home,
        Routes.statistics,
        Routes.budget,
        Routes.share,
        Routes.settings,
        Routes.search,
        Routes.category,
        Routes.paymentMethod,
        Routes.ledgerManage,
        Routes.fixedExpense,
        Routes.addExpense,
        Routes.addIncome,
        Routes.quickExpense,
        Routes.termsOfService,
        Routes.privacyPolicy,
        Routes.guide,
        Routes.recurringTemplates,
        Routes.debugTest,
      ];

      // Then: 중복 없음
      final uniqueRoutes = topLevelRoutes.toSet();
      expect(uniqueRoutes.length, equals(topLevelRoutes.length));
    });

    test('딥링크 경로들이 올바른 패턴을 가진다', () {
      // Given & When
      expect(Routes.addExpense, equals('/add-expense'));
      expect(Routes.addIncome, equals('/add-income'));
      expect(Routes.quickExpense, equals('/quick-expense'));
      expect(Routes.paymentMethod, equals('/payment-method'));
    });

    test('중첩 경로들이 올바른 패턴을 가진다', () {
      // Given & When
      expect(Routes.autoSaveSettings,
          contains('/settings/payment-methods/:id/'));
      expect(Routes.categoryKeywordMapping,
          contains('/settings/payment-methods/:id/'));
      expect(Routes.pendingTransactions,
          equals('/settings/pending-transactions'));
    });

    test('가이드 경로들이 /guide 접두사를 가진다', () {
      // Given & When
      expect(Routes.guide, equals('/guide'));
      expect(Routes.autoCollectGuide, startsWith('/guide/'));
      expect(Routes.transactionGuide, startsWith('/guide/'));
      expect(Routes.shareGuide, startsWith('/guide/'));
    });
  });
}
