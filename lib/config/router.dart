import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/signup_page.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/category/presentation/pages/category_management_page.dart';
import '../features/ledger/presentation/pages/home_page.dart';
import '../features/ledger/presentation/pages/ledger_management_page.dart';
import '../features/payment_method/presentation/pages/payment_method_management_page.dart';
import '../features/search/presentation/pages/search_page.dart';
import '../features/settings/presentation/pages/settings_page.dart';
import '../features/share/presentation/pages/share_management_page.dart';

// 라우트 이름 상수
class Routes {
  Routes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String home = '/home';
  static const String ledgerDetail = '/ledger/:id';
  static const String transaction = '/transaction';
  static const String transactionAdd = '/transaction/add';
  static const String transactionEdit = '/transaction/:id/edit';
  static const String statistics = '/statistics';
  static const String budget = '/budget';
  static const String share = '/share';
  static const String settings = '/settings';
  static const String profile = '/profile';
  static const String search = '/search';
  static const String category = '/category';
  static const String paymentMethod = '/payment-method';
  static const String ledgerManage = '/ledger-manage';
}

// 라우터 프로바이더
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: Routes.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final isAuthRoute = state.matchedLocation == Routes.login ||
          state.matchedLocation == Routes.signup;
      final isSplash = state.matchedLocation == Routes.splash;

      // 스플래시 화면에서는 리다이렉트하지 않음
      if (isSplash) return null;

      // 로그인하지 않은 상태에서 인증 페이지가 아닌 곳으로 가려고 하면 로그인으로
      if (!isLoggedIn && !isAuthRoute) {
        return Routes.login;
      }

      // 로그인한 상태에서 인증 페이지로 가려고 하면 홈으로
      if (isLoggedIn && isAuthRoute) {
        return Routes.home;
      }

      return null;
    },
    routes: [
      // 스플래시
      GoRoute(
        path: Routes.splash,
        builder: (context, state) => const SplashPage(),
      ),

      // 인증
      GoRoute(
        path: Routes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: Routes.signup,
        builder: (context, state) => const SignupPage(),
      ),

      // 메인
      GoRoute(
        path: Routes.home,
        builder: (context, state) => const HomePage(),
      ),

      // 통계
      GoRoute(
        path: Routes.statistics,
        builder: (context, state) => const Placeholder(), // TODO: 구현 예정
      ),

      // 예산
      GoRoute(
        path: Routes.budget,
        builder: (context, state) => const Placeholder(), // TODO: 구현 예정
      ),

      // 공유 관리
      GoRoute(
        path: Routes.share,
        builder: (context, state) => const ShareManagementPage(),
      ),

      // 설정
      GoRoute(
        path: Routes.settings,
        builder: (context, state) => const SettingsPage(),
      ),

      // 검색
      GoRoute(
        path: Routes.search,
        builder: (context, state) => const SearchPage(),
      ),

      // 카테고리 관리
      GoRoute(
        path: Routes.category,
        builder: (context, state) => const CategoryManagementPage(),
      ),

      // 결제수단 관리
      GoRoute(
        path: Routes.paymentMethod,
        builder: (context, state) => const PaymentMethodManagementPage(),
      ),

      // 가계부 관리
      GoRoute(
        path: Routes.ledgerManage,
        builder: (context, state) => const LedgerManagementPage(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('페이지를 찾을 수 없습니다: ${state.matchedLocation}'),
      ),
    ),
  );
});

// 스플래시 페이지 (임시)
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    final authState = ref.read(authStateProvider);
    if (authState.valueOrNull != null) {
      context.go(Routes.home);
    } else {
      context.go(Routes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              '공유 가계부',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
