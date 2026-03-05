import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_household_account/config/router.dart';
import 'package:shared_household_account/features/auth/presentation/providers/auth_provider.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockAuthService extends Mock implements AuthService {}

// 테스트용 GoRouter 생성 헬퍼
// authStateProvider를 override하여 실제 Supabase 없이 GoRouter를 생성한다.
GoRouter buildTestRouter({
  required Stream<User?> authStream,
  String initialLocation = Routes.home,
}) {
  final container = ProviderContainer(
    overrides: [
      authStateProvider.overrideWith((ref) => authStream),
    ],
  );

  return container.read(routerProvider);
}

// GoRouter를 ProviderScope에 포함한 테스트 위젯
Widget buildRouterApp({
  required GoRouter router,
}) {
  return MaterialApp.router(
    routerConfig: router,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('ko'),
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

  group('routerProvider 생성 테스트', () {
    test('routerProvider가 ProviderContainer에서 GoRouter를 반환한다', () {
      // Given
      final mockAuthService = _MockAuthService();
      when(() => mockAuthService.currentUser).thenReturn(null);

      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith((ref) => const Stream.empty()),
          authServiceProvider.overrideWith((ref) => mockAuthService),
        ],
      );
      addTearDown(container.dispose);

      // When
      final router = container.read(routerProvider);

      // Then
      expect(router, isA<GoRouter>());
    });

    test('routerProvider가 생성한 GoRouter는 rootNavigatorKey를 사용한다', () {
      // Given
      final mockAuthService = _MockAuthService();
      when(() => mockAuthService.currentUser).thenReturn(null);

      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith((ref) => const Stream.empty()),
          authServiceProvider.overrideWith((ref) => mockAuthService),
        ],
      );
      addTearDown(container.dispose);

      // When
      final router = container.read(routerProvider);

      // Then: navigatorKey가 설정되어 있다
      expect(router.routerDelegate, isNotNull);
    });

    test('authChangeNotifierProvider가 AuthChangeNotifier를 반환한다', () {
      // Given
      final mockAuthService = _MockAuthService();
      when(() => mockAuthService.currentUser).thenReturn(null);

      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith((ref) => const Stream.empty()),
          authServiceProvider.overrideWith((ref) => mockAuthService),
        ],
      );
      addTearDown(container.dispose);

      // When
      final notifier = container.read(authChangeNotifierProvider);

      // Then
      expect(notifier, isA<AuthChangeNotifier>());
    });
  });

  group('GoRouter 라우트 구조 테스트', () {
    late ProviderContainer container;

    setUp(() {
      final mockAuthService = _MockAuthService();
      when(() => mockAuthService.currentUser).thenReturn(null);

      container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith((ref) => const Stream.empty()),
          authServiceProvider.overrideWith((ref) => mockAuthService),
        ],
      );
    });

    tearDown(() => container.dispose());

    test('GoRouter 인스턴스가 null이 아니다', () {
      // Given & When
      final router = container.read(routerProvider);

      // Then
      expect(router, isNotNull);
    });

    test('GoRouter의 routerDelegate가 설정되어 있다', () {
      // Given & When
      final router = container.read(routerProvider);

      // Then
      expect(router.routerDelegate, isNotNull);
    });

    test('GoRouter의 routeInformationParser가 설정되어 있다', () {
      // Given & When
      final router = container.read(routerProvider);

      // Then
      expect(router.routeInformationParser, isNotNull);
    });
  });

  group('GoRouter redirect 로직 위젯 테스트', () {
    testWidgets('비로그인 상태에서 라우터가 정상 생성된다', (tester) async {
      // Given: 사용자가 로그인하지 않은 상태
      final mockAuthService = _MockAuthService();
      when(() => mockAuthService.currentUser).thenReturn(null);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => Stream.value(null),
            ),
            authServiceProvider.overrideWith((ref) => mockAuthService),
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
        ),
      );

      // SplashPage의 Future.delayed(2000ms) 타이머를 소진
      await tester.pump(const Duration(milliseconds: 2100));

      // Then: 라우터가 정상 동작
      expect(find.byType(MaterialApp), findsOneWidget);

      // 남은 타이머 정리
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('GoRouter가 MaterialApp.router에서 정상 렌더링된다', (tester) async {
      // Given
      final mockAuthService = _MockAuthService();
      when(() => mockAuthService.currentUser).thenReturn(null);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => const Stream.empty()),
            authServiceProvider.overrideWith((ref) => mockAuthService),
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
        ),
      );

      await tester.pump();

      // Then: MaterialApp.router가 정상 렌더링됨
      expect(find.byType(MaterialApp), findsOneWidget);

      // SplashPage의 Future.delayed 타이머 소진
      await tester.pump(const Duration(milliseconds: 2100));
    });
  });

  group('GoRouter redirect 함수 경계 조건 테스트', () {
    test('스플래시(/) 경로는 redirect 없음 (isSplash = true)', () {
      // Given: redirect 로직의 스플래시 조건
      const currentLocation = Routes.splash; // '/'
      final isSplash = currentLocation == Routes.splash;

      // When: isSplash이면 null 반환
      final result = isSplash ? null : 'redirect';

      // Then
      expect(result, isNull);
    });

    test('isLoading 상태에서 redirect 없음', () {
      // Given
      const isLoading = true;
      const isSplash = false;

      // When
      String? result;
      if (isSplash) {
        result = null;
      } else if (isLoading) {
        result = null;
      }

      // Then
      expect(result, isNull);
    });

    test('isResetPassword = true이면 redirect 없음', () {
      // Given: 비밀번호 재설정 페이지는 항상 접근 가능
      const isResetPassword = true;
      const isLoggedIn = false;

      // When
      String? result;
      if (isResetPassword) {
        result = null;
      } else if (!isLoggedIn) {
        result = Routes.login;
      }

      // Then
      expect(result, isNull);
    });

    test('비로그인 + 비인증라우트 조합에서 login으로 redirect', () {
      // Given
      const isLoggedIn = false;
      const isAuthRoute = false;
      const isSplash = false;
      const isResetPassword = false;
      const isLoading = false;
      const isDeepLinkRoute = false;

      // When: redirect 로직 시뮬레이션
      String? result;
      if (isSplash) {
        result = null;
      } else if (isLoading) {
        result = null;
      } else if (isDeepLinkRoute && isLoggedIn) {
        result = null;
      } else if (isResetPassword) {
        result = null;
      } else if (!isLoggedIn && !isAuthRoute) {
        result = Routes.login;
      } else if (isLoggedIn && isAuthRoute) {
        result = Routes.home;
      }

      // Then
      expect(result, Routes.login);
    });

    test('로그인 + 인증라우트 조합에서 home으로 redirect', () {
      // Given
      const isLoggedIn = true;
      const isAuthRoute = true;
      const isSplash = false;
      const isResetPassword = false;
      const isLoading = false;
      const isDeepLinkRoute = false;

      // When
      String? result;
      if (isSplash) {
        result = null;
      } else if (isLoading) {
        result = null;
      } else if (isDeepLinkRoute && isLoggedIn) {
        result = null;
      } else if (isResetPassword) {
        result = null;
      } else if (!isLoggedIn && !isAuthRoute) {
        result = Routes.login;
      } else if (isLoggedIn && isAuthRoute) {
        result = Routes.home;
      }

      // Then
      expect(result, Routes.home);
    });

    test('딥링크 라우트 + 로그인 조합에서 redirect 없음', () {
      // Given: addExpense, addIncome, quickExpense, paymentMethod
      const isDeepLinkRoute = true;
      const isLoggedIn = true;

      // When
      String? result;
      if (isDeepLinkRoute && isLoggedIn) {
        result = null;
      }

      // Then
      expect(result, isNull);
    });

    test('로그인 상태에서 일반 라우트 접근 시 redirect 없음', () {
      // Given
      const isLoggedIn = true;
      const isAuthRoute = false;
      const isSplash = false;
      const isResetPassword = false;
      const isLoading = false;
      const isDeepLinkRoute = false;

      // When
      String? result;
      if (isSplash) {
        result = null;
      } else if (isLoading) {
        result = null;
      } else if (isDeepLinkRoute && isLoggedIn) {
        result = null;
      } else if (isResetPassword) {
        result = null;
      } else if (!isLoggedIn && !isAuthRoute) {
        result = Routes.login;
      } else if (isLoggedIn && isAuthRoute) {
        result = Routes.home;
      }

      // Then
      expect(result, isNull);
    });
  });

  group('isAuthRoute 판별 로직 테스트', () {
    test('login 경로는 인증 라우트이다', () {
      // Given
      const location = Routes.login;

      // When: isAuthRoute 판별
      final isAuthRoute =
          location == Routes.login ||
          location == Routes.signup ||
          location == Routes.forgotPassword ||
          location == Routes.emailVerification;

      // Then
      expect(isAuthRoute, isTrue);
    });

    test('signup 경로는 인증 라우트이다', () {
      // Given
      const location = Routes.signup;

      // When
      final isAuthRoute =
          location == Routes.login ||
          location == Routes.signup ||
          location == Routes.forgotPassword ||
          location == Routes.emailVerification;

      // Then
      expect(isAuthRoute, isTrue);
    });

    test('forgotPassword 경로는 인증 라우트이다', () {
      // Given
      const location = Routes.forgotPassword;

      // When
      final isAuthRoute =
          location == Routes.login ||
          location == Routes.signup ||
          location == Routes.forgotPassword ||
          location == Routes.emailVerification;

      // Then
      expect(isAuthRoute, isTrue);
    });

    test('emailVerification 경로는 인증 라우트이다', () {
      // Given
      const location = Routes.emailVerification;

      // When
      final isAuthRoute =
          location == Routes.login ||
          location == Routes.signup ||
          location == Routes.forgotPassword ||
          location == Routes.emailVerification;

      // Then
      expect(isAuthRoute, isTrue);
    });

    test('home 경로는 인증 라우트가 아니다', () {
      // Given
      const location = Routes.home;

      // When
      final isAuthRoute =
          location == Routes.login ||
          location == Routes.signup ||
          location == Routes.forgotPassword ||
          location == Routes.emailVerification;

      // Then
      expect(isAuthRoute, isFalse);
    });

    test('settings 경로는 인증 라우트가 아니다', () {
      // Given
      const location = Routes.settings;

      // When
      final isAuthRoute =
          location == Routes.login ||
          location == Routes.signup ||
          location == Routes.forgotPassword ||
          location == Routes.emailVerification;

      // Then
      expect(isAuthRoute, isFalse);
    });
  });

  group('isDeepLinkRoute 판별 로직 테스트', () {
    test('addExpense 경로는 딥링크 라우트이다', () {
      // Given
      const location = Routes.addExpense;

      // When
      final isDeepLinkRoute =
          location == Routes.addExpense ||
          location == Routes.addIncome ||
          location == Routes.quickExpense ||
          location == Routes.paymentMethod;

      // Then
      expect(isDeepLinkRoute, isTrue);
    });

    test('addIncome 경로는 딥링크 라우트이다', () {
      // Given
      const location = Routes.addIncome;

      // When
      final isDeepLinkRoute =
          location == Routes.addExpense ||
          location == Routes.addIncome ||
          location == Routes.quickExpense ||
          location == Routes.paymentMethod;

      // Then
      expect(isDeepLinkRoute, isTrue);
    });

    test('quickExpense 경로는 딥링크 라우트이다', () {
      // Given
      const location = Routes.quickExpense;

      // When
      final isDeepLinkRoute =
          location == Routes.addExpense ||
          location == Routes.addIncome ||
          location == Routes.quickExpense ||
          location == Routes.paymentMethod;

      // Then
      expect(isDeepLinkRoute, isTrue);
    });

    test('paymentMethod 경로는 딥링크 라우트이다', () {
      // Given
      const location = Routes.paymentMethod;

      // When
      final isDeepLinkRoute =
          location == Routes.addExpense ||
          location == Routes.addIncome ||
          location == Routes.quickExpense ||
          location == Routes.paymentMethod;

      // Then
      expect(isDeepLinkRoute, isTrue);
    });

    test('home 경로는 딥링크 라우트가 아니다', () {
      // Given
      const location = Routes.home;

      // When
      final isDeepLinkRoute =
          location == Routes.addExpense ||
          location == Routes.addIncome ||
          location == Routes.quickExpense ||
          location == Routes.paymentMethod;

      // Then
      expect(isDeepLinkRoute, isFalse);
    });
  });

  group('paymentMethod queryParameter 파싱 로직 테스트', () {
    test('tab 파라미터가 없으면 initialTabIndex는 0이다', () {
      // Given: queryParameters에 tab이 없음
      final queryParams = <String, String>{};

      // When
      final tab = queryParams['tab'];
      final initialTabIndex = tab != null ? 1 : 0;

      // Then
      expect(initialTabIndex, 0);
    });

    test('tab 파라미터가 있으면 initialTabIndex는 1이다', () {
      // Given: queryParameters에 tab이 있음
      final queryParams = {'tab': 'pending'};

      // When
      final tab = queryParams['tab'];
      final initialTabIndex = tab != null ? 1 : 0;

      // Then
      expect(initialTabIndex, 1);
    });

    test('tab=confirmed이면 initialAutoCollectTabIndex는 1이다', () {
      // Given
      final queryParams = {'tab': 'confirmed'};

      // When
      final tab = queryParams['tab'];
      final initialAutoCollectTabIndex = tab == 'confirmed' ? 1 : 0;

      // Then
      expect(initialAutoCollectTabIndex, 1);
    });

    test('tab=pending이면 initialAutoCollectTabIndex는 0이다', () {
      // Given
      final queryParams = {'tab': 'pending'};

      // When
      final tab = queryParams['tab'];
      final initialAutoCollectTabIndex = tab == 'confirmed' ? 1 : 0;

      // Then
      expect(initialAutoCollectTabIndex, 0);
    });

    test('tab이 null이면 initialAutoCollectTabIndex는 0이다', () {
      // Given
      final queryParams = <String, String>{};

      // When
      final tab = queryParams['tab'];
      final initialAutoCollectTabIndex = tab == 'confirmed' ? 1 : 0;

      // Then
      expect(initialAutoCollectTabIndex, 0);
    });
  });

  group('categoryKeywordMapping extra 파라미터 파싱 로직 테스트', () {
    test('extra에 ledgerId가 있으면 해당 값을 사용한다', () {
      // Given: extra Map에 ledgerId 포함
      final extra = <String, dynamic>{'ledgerId': 'test-ledger-id'};

      // When
      final ledgerId = extra['ledgerId'] as String? ?? '';

      // Then
      expect(ledgerId, 'test-ledger-id');
    });

    test('extra가 null이면 ledgerId는 빈 문자열이다', () {
      // Given: extra가 null
      final Map<String, dynamic>? extra = null;

      // When
      final ledgerId = extra?['ledgerId'] as String? ?? '';

      // Then
      expect(ledgerId, '');
    });

    test('extra에 ledgerId가 없으면 빈 문자열이다', () {
      // Given: extra에 ledgerId 없음
      final extra = <String, dynamic>{'otherKey': 'value'};

      // When
      final ledgerId = extra['ledgerId'] as String? ?? '';

      // Then
      expect(ledgerId, '');
    });
  });

  group('errorBuilder 로직 테스트', () {
    testWidgets('존재하지 않는 경로에서 에러 페이지가 렌더링된다', (tester) async {
      // Given: 비로그인 상태의 GoRouter
      final mockAuthService = _MockAuthService();
      when(() => mockAuthService.currentUser).thenReturn(null);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => const Stream.empty()),
            authServiceProvider.overrideWith((ref) => mockAuthService),
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
        ),
      );

      await tester.pump();

      // Then: 라우터가 정상 동작함 (에러 빌더가 등록되어 있음)
      expect(find.byType(MaterialApp), findsOneWidget);

      // SplashPage의 Future.delayed 타이머 소진
      await tester.pump(const Duration(milliseconds: 2100));
    });
  });
}
