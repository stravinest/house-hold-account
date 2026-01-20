import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../l10n/generated/app_localizations.dart';
import '../features/auth/presentation/pages/email_verification_page.dart';
import '../features/auth/presentation/pages/forgot_password_page.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/signup_page.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/category/presentation/pages/category_management_page.dart';
import '../features/fixed_expense/presentation/pages/fixed_expense_management_page.dart';
import '../features/ledger/presentation/pages/home_page.dart';
import '../features/ledger/presentation/pages/ledger_management_page.dart';
import '../features/payment_method/presentation/pages/auto_save_settings_page.dart';
import '../features/payment_method/presentation/pages/payment_method_management_page.dart';
import '../features/payment_method/presentation/pages/pending_transactions_page.dart';
import '../features/search/presentation/pages/search_page.dart';
import '../features/settings/presentation/pages/settings_page.dart';
import '../features/share/presentation/pages/share_management_page.dart';
import 'page_transitions.dart';

// 라우트 이름 상수
class Routes {
  Routes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String emailVerification = '/email-verification';
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
  static const String fixedExpense = '/fixed-expense';
  static const String addExpense = '/add-expense';
  static const String addIncome = '/add-income';
  static const String quickExpense = '/quick-expense';
  static const String autoSaveSettings =
      '/settings/payment-methods/:id/auto-save';
  static const String pendingTransactions = '/settings/pending-transactions';
}

// 인증 상태 변경을 감지하는 Notifier
class AuthChangeNotifier extends ChangeNotifier {
  AuthChangeNotifier(this._ref) {
    _ref.listen(authStateProvider, (previous, next) {
      notifyListeners();
    });
  }

  final Ref _ref;
}

final authChangeNotifierProvider = Provider<AuthChangeNotifier>(
  (ref) => AuthChangeNotifier(ref),
);

// 라우터 프로바이더
final routerProvider = Provider<GoRouter>((ref) {
  final authChangeNotifier = ref.watch(authChangeNotifierProvider);

  return GoRouter(
    initialLocation: Routes.splash,
    debugLogDiagnostics: true,
    refreshListenable: authChangeNotifier,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final isLoggedIn = authState.valueOrNull != null;
      final isAuthRoute =
          state.matchedLocation == Routes.login ||
          state.matchedLocation == Routes.signup ||
          state.matchedLocation == Routes.forgotPassword ||
          state.matchedLocation == Routes.emailVerification;
      final isSplash = state.matchedLocation == Routes.splash;
      final isDeepLinkRoute =
          state.matchedLocation == Routes.addExpense ||
          state.matchedLocation == Routes.addIncome ||
          state.matchedLocation == Routes.quickExpense;

      // 스플래시 화면에서는 리다이렉트하지 않음
      if (isSplash) return null;

      // 딥링크 라우트는 리다이렉트하지 않음 (이미 로그인된 상태에서만 접근 가능)
      if (isDeepLinkRoute && isLoggedIn) {
        return null;
      }

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
      // 스플래시 - 페이드 전환
      GoRoute(
        path: Routes.splash,
        pageBuilder: (context, state) =>
            fadeTransition(key: state.pageKey, child: const SplashPage()),
      ),

      // 인증 - 페이드 전환
      GoRoute(
        path: Routes.login,
        pageBuilder: (context, state) =>
            fadeTransition(key: state.pageKey, child: const LoginPage()),
      ),
      GoRoute(
        path: Routes.signup,
        pageBuilder: (context, state) =>
            fadeTransition(key: state.pageKey, child: const SignupPage()),
      ),
      GoRoute(
        path: Routes.forgotPassword,
        pageBuilder: (context, state) => fadeTransition(
          key: state.pageKey,
          child: const ForgotPasswordPage(),
        ),
      ),
      GoRoute(
        path: Routes.emailVerification,
        pageBuilder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return fadeTransition(
            key: state.pageKey,
            child: EmailVerificationPage(email: email),
          );
        },
      ),

      // 메인 - 페이드 전환
      GoRoute(
        path: Routes.home,
        pageBuilder: (context, state) => fadeTransition(
          key: state.pageKey,
          child: HomePage(key: ValueKey(state.matchedLocation)),
        ),
      ),

      // 통계 - 슬라이드 전환
      GoRoute(
        path: Routes.statistics,
        pageBuilder: (context, state) => slideTransition(
          key: state.pageKey,
          child: const Placeholder(), // TODO: 구현 예정
        ),
      ),

      // 예산 - 슬라이드 전환
      GoRoute(
        path: Routes.budget,
        pageBuilder: (context, state) => slideTransition(
          key: state.pageKey,
          child: const Placeholder(), // TODO: 구현 예정
        ),
      ),

      // 공유 관리 - 슬라이드 전환
      GoRoute(
        path: Routes.share,
        pageBuilder: (context, state) => slideTransition(
          key: state.pageKey,
          child: const ShareManagementPage(),
        ),
      ),

      // 설정 - 슬라이드 전환
      GoRoute(
        path: Routes.settings,
        pageBuilder: (context, state) =>
            slideTransition(key: state.pageKey, child: const SettingsPage()),
      ),

      // 검색 - 페이드 스케일 전환 (강조)
      GoRoute(
        path: Routes.search,
        pageBuilder: (context, state) =>
            fadeScaleTransition(key: state.pageKey, child: const SearchPage()),
      ),

      // 카테고리 관리 - 슬라이드 전환
      GoRoute(
        path: Routes.category,
        pageBuilder: (context, state) => slideTransition(
          key: state.pageKey,
          child: const CategoryManagementPage(),
        ),
      ),

      // 결제수단 관리 - 슬라이드 전환
      GoRoute(
        path: Routes.paymentMethod,
        pageBuilder: (context, state) => slideTransition(
          key: state.pageKey,
          child: const PaymentMethodManagementPage(),
        ),
      ),

      // 가계부 관리 - 슬라이드 전환
      GoRoute(
        path: Routes.ledgerManage,
        pageBuilder: (context, state) => slideTransition(
          key: state.pageKey,
          child: const LedgerManagementPage(),
        ),
      ),

      // 고정비 관리 - 슬라이드 전환
      GoRoute(
        path: Routes.fixedExpense,
        pageBuilder: (context, state) => slideTransition(
          key: state.pageKey,
          child: const FixedExpenseManagementPage(),
        ),
      ),

      // 자동 저장 설정 - 슬라이드 전환
      GoRoute(
        path: Routes.autoSaveSettings,
        pageBuilder: (context, state) {
          final paymentMethodId = state.pathParameters['id']!;
          return slideTransition(
            key: state.pageKey,
            child: AutoSaveSettingsPage(paymentMethodId: paymentMethodId),
          );
        },
      ),

      // 대기 중인 거래 - 슬라이드 전환
      GoRoute(
        path: Routes.pendingTransactions,
        pageBuilder: (context, state) => slideTransition(
          key: state.pageKey,
          child: const PendingTransactionsPage(),
        ),
      ),

      // 위젯 딥링크 - 지출 추가 (페이드 전환)
      GoRoute(
        path: Routes.addExpense,
        pageBuilder: (context, state) => fadeTransition(
          key: state.pageKey,
          child: HomePage(
            key: ValueKey(state.matchedLocation),
            initialTransactionType: 'expense',
          ),
        ),
      ),

      // 위젯 딥링크 - 수입 추가 (페이드 전환)
      GoRoute(
        path: Routes.addIncome,
        pageBuilder: (context, state) => fadeTransition(
          key: state.pageKey,
          child: HomePage(
            key: ValueKey(state.matchedLocation),
            initialTransactionType: 'income',
          ),
        ),
      ),

      // 위젯 딥링크 - 빠른 지출 (페이드 전환)
      GoRoute(
        path: Routes.quickExpense,
        pageBuilder: (context, state) => fadeTransition(
          key: state.pageKey,
          child: HomePage(
            key: ValueKey(state.matchedLocation),
            showQuickExpense: true,
          ),
        ),
      ),
    ],
    errorBuilder: (context, state) {
      final l10n = AppLocalizations.of(context)!;
      final message = l10n.errorNotFound ?? 'Page not found';
      return Scaffold(
        body: Center(child: Text('$message: ${state.matchedLocation}')),
      );
    },
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
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    // 인증 상태 로딩이 완료되면 즉시 리다이렉트
    authState.when(
      data: (user) {
        // build 중에 navigation을 직접 호출하면 안되므로 다음 프레임에 실행
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (user != null) {
            context.go(Routes.home);
          } else {
            context.go(Routes.login);
          }
        });
      },
      loading: () {
        // 로딩 중 - 아무것도 안함 (UI만 표시)
      },
      error: (_, __) {
        // 에러 시 로그인 페이지로
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          context.go(Routes.login);
        });
      },
    );

    // 네이티브 스플래시가 이미 표시되므로 최소한의 UI만 표시
    // (빈 화면 방지용 - 실제로는 거의 보이지 않음)
    return const Scaffold(body: SizedBox.shrink());
  }
}
