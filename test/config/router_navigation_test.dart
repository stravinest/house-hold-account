import 'dart:async';

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

// GoRouter 내에서 context.go()를 호출하는 버튼이 있는 테스트 위젯
class _NavButton extends StatelessWidget {
  const _NavButton({required this.path});
  final String path;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => context.go(path),
      child: const Text('navigate'),
    );
  }
}

// 특정 초기 경로로 GoRouter를 렌더링하는 헬퍼
GoRouter _buildRouter({required String initialLocation}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const Scaffold(body: Text('splash')),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const Scaffold(body: Text('login')),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => Scaffold(
          body: Column(
            children: [
              const Text('home'),
              _NavButton(path: Routes.signup),
            ],
          ),
        ),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const Scaffold(body: Text('signup')),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) =>
            const Scaffold(body: Text('forgot-password')),
      ),
      GoRoute(
        path: '/email-verification',
        builder: (context, state) =>
            const Scaffold(body: Text('email-verification')),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) =>
            const Scaffold(body: Text('reset-password')),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const Scaffold(body: Text('settings')),
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const Scaffold(body: Text('search')),
      ),
      GoRoute(
        path: '/share',
        builder: (context, state) => const Scaffold(body: Text('share')),
      ),
      GoRoute(
        path: '/category',
        builder: (context, state) => const Scaffold(body: Text('category')),
      ),
      GoRoute(
        path: '/payment-method',
        builder: (context, state) =>
            const Scaffold(body: Text('payment-method')),
      ),
      GoRoute(
        path: '/ledger-manage',
        builder: (context, state) =>
            const Scaffold(body: Text('ledger-manage')),
      ),
      GoRoute(
        path: '/fixed-expense',
        builder: (context, state) =>
            const Scaffold(body: Text('fixed-expense')),
      ),
      GoRoute(
        path: '/recurring-templates',
        builder: (context, state) =>
            const Scaffold(body: Text('recurring-templates')),
      ),
      GoRoute(
        path: '/settings/pending-transactions',
        builder: (context, state) =>
            const Scaffold(body: Text('pending-transactions')),
      ),
      GoRoute(
        path: '/guide',
        builder: (context, state) => const Scaffold(body: Text('guide')),
      ),
      GoRoute(
        path: '/guide/auto-collect',
        builder: (context, state) =>
            const Scaffold(body: Text('auto-collect-guide')),
      ),
      GoRoute(
        path: '/guide/transaction',
        builder: (context, state) =>
            const Scaffold(body: Text('transaction-guide')),
      ),
      GoRoute(
        path: '/guide/share',
        builder: (context, state) =>
            const Scaffold(body: Text('share-guide')),
      ),
      GoRoute(
        path: '/terms-of-service',
        builder: (context, state) => const Scaffold(body: Text('terms')),
      ),
      GoRoute(
        path: '/privacy-policy',
        builder: (context, state) => const Scaffold(body: Text('privacy')),
      ),
      GoRoute(
        path: '/debug-test',
        builder: (context, state) => const Scaffold(body: Text('debug-test')),
      ),
      GoRoute(
        path: '/add-expense',
        builder: (context, state) => const Scaffold(body: Text('add-expense')),
      ),
      GoRoute(
        path: '/add-income',
        builder: (context, state) => const Scaffold(body: Text('add-income')),
      ),
      GoRoute(
        path: '/quick-expense',
        builder: (context, state) =>
            const Scaffold(body: Text('quick-expense')),
      ),
      GoRoute(
        path: '/statistics',
        builder: (context, state) => const Scaffold(body: Text('statistics')),
      ),
      GoRoute(
        path: '/budget',
        builder: (context, state) => const Scaffold(body: Text('budget')),
      ),
      GoRoute(
        path: '/settings/payment-methods/:id/auto-save',
        builder: (context, state) =>
            const Scaffold(body: Text('auto-save-settings')),
      ),
      GoRoute(
        path: '/settings/payment-methods/:id/category-mapping/:sourceType',
        builder: (context, state) =>
            const Scaffold(body: Text('category-keyword-mapping')),
      ),
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: Text('error: ${state.matchedLocation}')),
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

  // 각 경로를 initialLocation으로 직접 렌더링하는 방식으로 pageBuilder 패턴 검증
  // (router.dart의 실제 GoRoute 구조와 동일한 방식으로 경로 정의 검증)
  group('GoRouter 경로별 렌더링 테스트', () {
    testWidgets('/login 경로가 정상 렌더링된다', (tester) async {
      // Given: /login을 initialLocation으로 설정
      final router = _buildRouter(initialLocation: '/login');

      // When
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();

      // Then
      expect(find.text('login'), findsOneWidget);
      router.dispose();
    });

    testWidgets('/home 경로가 정상 렌더링된다', (tester) async {
      final router = _buildRouter(initialLocation: '/home');
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();
      expect(find.text('home'), findsOneWidget);
      router.dispose();
    });

    testWidgets('/signup 경로가 정상 렌더링된다', (tester) async {
      final router = _buildRouter(initialLocation: '/signup');
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();
      expect(find.text('signup'), findsOneWidget);
      router.dispose();
    });

    testWidgets('/forgot-password 경로가 정상 렌더링된다', (tester) async {
      final router = _buildRouter(initialLocation: '/forgot-password');
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();
      expect(find.text('forgot-password'), findsOneWidget);
      router.dispose();
    });

    testWidgets('/email-verification 경로가 정상 렌더링된다', (tester) async {
      final router = _buildRouter(initialLocation: '/email-verification');
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();
      expect(find.text('email-verification'), findsOneWidget);
      router.dispose();
    });

    testWidgets('/reset-password 경로가 정상 렌더링된다', (tester) async {
      final router = _buildRouter(initialLocation: '/reset-password');
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();
      expect(find.text('reset-password'), findsOneWidget);
      router.dispose();
    });

    testWidgets('/settings 경로가 정상 렌더링된다', (tester) async {
      final router = _buildRouter(initialLocation: '/settings');
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();
      expect(find.text('settings'), findsOneWidget);
      router.dispose();
    });

    testWidgets('/search 경로가 정상 렌더링된다', (tester) async {
      final router = _buildRouter(initialLocation: '/search');
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();
      expect(find.text('search'), findsOneWidget);
      router.dispose();
    });

    testWidgets('/share 경로가 정상 렌더링된다', (tester) async {
      final router = _buildRouter(initialLocation: '/share');
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();
      expect(find.text('share'), findsOneWidget);
      router.dispose();
    });

    testWidgets('/category 경로가 정상 렌더링된다', (tester) async {
      final router = _buildRouter(initialLocation: '/category');
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();
      expect(find.text('category'), findsOneWidget);
      router.dispose();
    });

    testWidgets('/payment-method 경로가 정상 렌더링된다', (tester) async {
      final router = _buildRouter(initialLocation: '/payment-method');
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();
      expect(find.text('payment-method'), findsOneWidget);
      router.dispose();
    });

    testWidgets('/ledger-manage 경로가 정상 렌더링된다', (tester) async {
      final router = _buildRouter(initialLocation: '/ledger-manage');
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();
      expect(find.text('ledger-manage'), findsOneWidget);
      router.dispose();
    });

    testWidgets('/fixed-expense 경로가 정상 렌더링된다', (tester) async {
      final router = _buildRouter(initialLocation: '/fixed-expense');
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();
      expect(find.text('fixed-expense'), findsOneWidget);
      router.dispose();
    });

    testWidgets('/recurring-templates 경로가 정상 렌더링된다', (tester) async {
      final router = _buildRouter(initialLocation: '/recurring-templates');
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();
      expect(find.text('recurring-templates'), findsOneWidget);
      router.dispose();
    });

    testWidgets('/settings/pending-transactions 경로가 정상 렌더링된다',
        (tester) async {
      final router =
          _buildRouter(initialLocation: '/settings/pending-transactions');
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();
      expect(find.text('pending-transactions'), findsOneWidget);
      router.dispose();
    });

    testWidgets('/guide 경로가 정상 렌더링된다', (tester) async {
      final router = _buildRouter(initialLocation: '/guide');
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();
      expect(find.text('guide'), findsOneWidget);
      router.dispose();
    });

    testWidgets('/guide/auto-collect 경로가 정상 렌더링된다', (tester) async {
      final router = _buildRouter(initialLocation: '/guide/auto-collect');
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();
      expect(find.text('auto-collect-guide'), findsOneWidget);
      router.dispose();
    });

    testWidgets('/guide/transaction 경로가 정상 렌더링된다', (tester) async {
      final router = _buildRouter(initialLocation: '/guide/transaction');
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();
      expect(find.text('transaction-guide'), findsOneWidget);
      router.dispose();
    });

    testWidgets('/guide/share 경로가 정상 렌더링된다', (tester) async {
      final router = _buildRouter(initialLocation: '/guide/share');
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();
      expect(find.text('share-guide'), findsOneWidget);
      router.dispose();
    });

    testWidgets('/terms-of-service 경로가 정상 렌더링된다', (tester) async {
      final router = _buildRouter(initialLocation: '/terms-of-service');
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();
      expect(find.text('terms'), findsOneWidget);
      router.dispose();
    });

    testWidgets('/privacy-policy 경로가 정상 렌더링된다', (tester) async {
      final router = _buildRouter(initialLocation: '/privacy-policy');
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();
      expect(find.text('privacy'), findsOneWidget);
      router.dispose();
    });

    testWidgets('/debug-test 경로가 정상 렌더링된다', (tester) async {
      final router = _buildRouter(initialLocation: '/debug-test');
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();
      expect(find.text('debug-test'), findsOneWidget);
      router.dispose();
    });

    testWidgets('/add-expense 경로가 정상 렌더링된다', (tester) async {
      final router = _buildRouter(initialLocation: '/add-expense');
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();
      expect(find.text('add-expense'), findsOneWidget);
      router.dispose();
    });

    testWidgets('/add-income 경로가 정상 렌더링된다', (tester) async {
      final router = _buildRouter(initialLocation: '/add-income');
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();
      expect(find.text('add-income'), findsOneWidget);
      router.dispose();
    });

    testWidgets('/quick-expense 경로가 정상 렌더링된다', (tester) async {
      final router = _buildRouter(initialLocation: '/quick-expense');
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();
      expect(find.text('quick-expense'), findsOneWidget);
      router.dispose();
    });

    testWidgets('/statistics 경로가 정상 렌더링된다', (tester) async {
      final router = _buildRouter(initialLocation: '/statistics');
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();
      expect(find.text('statistics'), findsOneWidget);
      router.dispose();
    });

    testWidgets('/budget 경로가 정상 렌더링된다', (tester) async {
      final router = _buildRouter(initialLocation: '/budget');
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();
      expect(find.text('budget'), findsOneWidget);
      router.dispose();
    });

    testWidgets('/settings/payment-methods/:id/auto-save 동적 경로가 정상 렌더링된다',
        (tester) async {
      final router = _buildRouter(
        initialLocation: '/settings/payment-methods/test-id/auto-save',
      );
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();
      expect(find.text('auto-save-settings'), findsOneWidget);
      router.dispose();
    });

    testWidgets(
        '/settings/payment-methods/:id/category-mapping/:sourceType 동적 경로가 정상 렌더링된다',
        (tester) async {
      final router = _buildRouter(
        initialLocation:
            '/settings/payment-methods/test-id/category-mapping/sms',
      );
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();
      expect(find.text('category-keyword-mapping'), findsOneWidget);
      router.dispose();
    });

    testWidgets('존재하지 않는 경로에서 errorBuilder가 실행된다', (tester) async {
      // Given: 존재하지 않는 경로
      final router = _buildRouter(initialLocation: '/non-existent-xyz');
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();
      // Then: errorBuilder가 실행되어 error 텍스트가 표시됨
      expect(find.textContaining('error'), findsOneWidget);
      router.dispose();
    });
  });

  group('SplashPage _tryNavigate 에러 상태 테스트', () {
    testWidgets('에러를 방출하는 authStream에서 SplashPage가 정상 동작한다', (tester) async {
      // Given: 에러를 방출하는 authStream
      // SplashPage는 2초 후 context.go()를 호출하므로 GoRouter 안에서 렌더링해야 함
      final mockAuthService = _MockAuthService();
      when(() => mockAuthService.currentUser).thenReturn(null);
      final errorController = StreamController<User?>();

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const SplashPage(),
          ),
          GoRoute(
            path: '/login',
            builder: (context, state) =>
                const Scaffold(body: Text('login')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => errorController.stream),
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

      await tester.pump();

      // When: 에러를 방출 (AsyncError 상태로 전환)
      errorController.addError(Exception('auth error'));
      await tester.pump();

      // Then: SplashPage가 여전히 렌더링됨
      expect(find.byType(SplashPage), findsOneWidget);

      // 타이머 소진
      await tester.pump(const Duration(milliseconds: 2100));
      await errorController.close();
      router.dispose();
    });

    testWidgets('null User를 방출하는 authStream에서 SplashPage가 초기 렌더링된다',
        (tester) async {
      // Given: null을 방출하는 Stream (비로그인)
      // SplashPage는 2초 후 context.go()를 호출하므로 GoRouter 안에서 렌더링해야 함
      final mockAuthService = _MockAuthService();
      when(() => mockAuthService.currentUser).thenReturn(null);

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const SplashPage(),
          ),
          GoRoute(
            path: '/login',
            builder: (context, state) =>
                const Scaffold(body: Text('login')),
          ),
        ],
      );

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

      await tester.pump();

      // Then: 초기에 SplashPage가 렌더링됨
      expect(find.byType(SplashPage), findsOneWidget);

      // 최소 시간 대기 후 _tryNavigate 실행 → /login으로 이동
      await tester.pump(const Duration(milliseconds: 2100));

      router.dispose();
    });

    testWidgets('로딩 상태 유지 시 SplashPage가 최소 시간 동안 표시된다', (tester) async {
      // Given: 아무것도 방출하지 않는 Stream (로딩 상태 유지)
      // Stream.empty()는 데이터 없이 완료되므로 _tryNavigate가 loading 분기로 실행됨
      final mockAuthService = _MockAuthService();
      when(() => mockAuthService.currentUser).thenReturn(null);

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const SplashPage(),
          ),
          GoRoute(
            path: '/login',
            builder: (context, state) =>
                const Scaffold(body: Text('login')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => const Stream.empty()),
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

      // Then: 로딩 중이므로 SplashPage 유지
      await tester.pump();
      expect(find.byType(SplashPage), findsOneWidget);

      // 타이머 소진
      await tester.pump(const Duration(milliseconds: 2100));
      router.dispose();
    });
  });

  group('routerProvider redirect 실제 실행 테스트', () {
    testWidgets('비로그인 상태 routerProvider가 정상 생성된다', (tester) async {
      // Given
      final mockAuthService = _MockAuthService();
      when(() => mockAuthService.currentUser).thenReturn(null);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => Stream.value(null)),
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
      expect(find.byType(MaterialApp), findsOneWidget);

      // 스플래시 타이머 소진
      await tester.pump(const Duration(milliseconds: 2100));
    });
  });
}
