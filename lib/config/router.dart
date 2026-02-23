import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../l10n/generated/app_localizations.dart';
import '../features/auth/presentation/pages/email_verification_page.dart';
import '../features/auth/presentation/pages/forgot_password_page.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/reset_password_page.dart';
import '../features/auth/presentation/pages/signup_page.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/category/presentation/pages/category_management_page.dart';
import '../features/fixed_expense/presentation/pages/fixed_expense_management_page.dart';
import '../features/ledger/presentation/pages/home_page.dart';
import '../features/ledger/presentation/pages/ledger_management_page.dart';
import '../features/payment_method/presentation/pages/auto_save_settings_page.dart';
import '../features/payment_method/presentation/pages/debug_test_page.dart';
import '../features/payment_method/presentation/pages/payment_method_management_page.dart';
import '../features/payment_method/presentation/pages/pending_transactions_page.dart';
import '../features/search/presentation/pages/search_page.dart';
import '../features/transaction/presentation/pages/recurring_template_management_page.dart';
import '../features/settings/presentation/pages/auto_collect_guide_page.dart';
import '../features/settings/presentation/pages/guide_page.dart';
import '../features/settings/presentation/pages/share_guide_page.dart';
import '../features/settings/presentation/pages/transaction_guide_page.dart';
import '../features/settings/presentation/pages/privacy_policy_page.dart';
import '../features/settings/presentation/pages/settings_page.dart';
import '../features/settings/presentation/pages/terms_of_service_page.dart';
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
  static const String termsOfService = '/terms-of-service';
  static const String privacyPolicy = '/privacy-policy';
  static const String resetPassword = '/reset-password';
  static const String guide = '/guide';
  static const String recurringTemplates = '/recurring-templates';
  static const String autoCollectGuide = '/guide/auto-collect';
  static const String transactionGuide = '/guide/transaction';
  static const String shareGuide = '/guide/share';
  static const String debugTest = '/debug-test';
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

/// 전역 Navigator 키 - 다이얼로그 표시 등에 사용
final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

// 라우터 프로바이더
final routerProvider = Provider<GoRouter>((ref) {
  final authChangeNotifier = ref.watch(authChangeNotifierProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
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
      final isResetPassword = state.matchedLocation == Routes.resetPassword;
      final isSplash = state.matchedLocation == Routes.splash;
      final isDeepLinkRoute =
          state.matchedLocation == Routes.addExpense ||
          state.matchedLocation == Routes.addIncome ||
          state.matchedLocation == Routes.quickExpense ||
          state.matchedLocation == Routes.paymentMethod;

      // 스플래시 화면에서는 리다이렉트하지 않음
      if (isSplash) return null;

      // 딥링크 라우트는 리다이렉트하지 않음 (이미 로그인된 상태에서만 접근 가능)
      if (isDeepLinkRoute && isLoggedIn) {
        return null;
      }

      // 비밀번호 재설정 페이지는 항상 접근 가능
      // (recovery 콜백에서 세션 복구 타이밍에 따라 isLoggedIn이 false일 수 있음)
      if (isResetPassword) {
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

      // 비밀번호 재설정 - 페이드 전환
      GoRoute(
        path: Routes.resetPassword,
        pageBuilder: (context, state) => fadeTransition(
          key: state.pageKey,
          child: const ResetPasswordPage(),
        ),
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

      // 결제수단 관리 - 슬라이드 전환 (딥링크 쿼리 파라미터 지원)
      GoRoute(
        path: Routes.paymentMethod,
        pageBuilder: (context, state) {
          final tab = state.uri.queryParameters['tab'];
          // tab 파라미터가 있으면 수집내역 탭(index 1)으로 이동
          final initialTabIndex = tab != null ? 1 : 0;
          // 수집내역 내부 탭: pending=0, confirmed=1
          final initialAutoCollectTabIndex = tab == 'confirmed' ? 1 : 0;
          return slideTransition(
            key: state.pageKey,
            child: PaymentMethodManagementPage(
              initialTabIndex: initialTabIndex,
              initialAutoCollectTabIndex: initialAutoCollectTabIndex,
            ),
          );
        },
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

      // 반복 거래 관리 - 슬라이드 전환
      GoRoute(
        path: Routes.recurringTemplates,
        pageBuilder: (context, state) => slideTransition(
          key: state.pageKey,
          child: const RecurringTemplateManagementPage(),
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

      // 사용 가이드 - 슬라이드 전환
      GoRoute(
        path: Routes.guide,
        pageBuilder: (context, state) =>
            slideTransition(key: state.pageKey, child: const GuidePage()),
      ),

      // 자동수집 가이드 - 슬라이드 전환
      GoRoute(
        path: Routes.autoCollectGuide,
        pageBuilder: (context, state) => slideTransition(
          key: state.pageKey,
          child: const AutoCollectGuidePage(),
        ),
      ),

      // 거래 기록 가이드 - 슬라이드 전환
      GoRoute(
        path: Routes.transactionGuide,
        pageBuilder: (context, state) => slideTransition(
          key: state.pageKey,
          child: const TransactionGuidePage(),
        ),
      ),

      // 가계부 공유 가이드 - 슬라이드 전환
      GoRoute(
        path: Routes.shareGuide,
        pageBuilder: (context, state) => slideTransition(
          key: state.pageKey,
          child: const ShareGuidePage(),
        ),
      ),

      // 이용약관 - 슬라이드 전환
      GoRoute(
        path: Routes.termsOfService,
        pageBuilder: (context, state) => slideTransition(
          key: state.pageKey,
          child: const TermsOfServicePage(),
        ),
      ),

      // 개인정보처리방침 - 슬라이드 전환
      GoRoute(
        path: Routes.privacyPolicy,
        pageBuilder: (context, state) => slideTransition(
          key: state.pageKey,
          child: const PrivacyPolicyPage(),
        ),
      ),

      // 디버그 테스트 - 슬라이드 전환 (디버그 모드 전용)
      GoRoute(
        path: Routes.debugTest,
        pageBuilder: (context, state) =>
            slideTransition(key: state.pageKey, child: const DebugTestPage()),
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
      final l10n = AppLocalizations.of(context);
      final message = l10n.errorNotFound;
      return Scaffold(
        body: Center(child: Text('$message: ${state.matchedLocation}')),
      );
    },
  );
});

// 스플래시 페이지 (1v48l 디자인)
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with TickerProviderStateMixin {
  late final AnimationController _dotController;
  bool _minTimeElapsed = false;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    // 최소 2초 동안 스플래시 디자인 표시
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (!mounted) return;
      _minTimeElapsed = true;
      _tryNavigate(ref.read(authStateProvider));
    });
  }

  void _tryNavigate(AsyncValue<dynamic> authState) {
    if (!_minTimeElapsed || _hasNavigated || !mounted) return;

    authState.when(
      data: (user) {
        _hasNavigated = true;
        if (user != null) {
          context.go(Routes.home);
        } else {
          context.go(Routes.login);
        }
      },
      loading: () {},
      error: (e, stack) {
        _hasNavigated = true;
        context.go(Routes.login);
      },
    );
  }

  @override
  void dispose() {
    _dotController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final l10n = AppLocalizations.of(context);

    // 인증 상태 변경 시 최소 시간 경과 후 리다이렉트
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryNavigate(authState);
    });

    return Scaffold(
      backgroundColor: const Color(0xFFFDFDF5),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 앱 아이콘
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x15000000),
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Image.asset(
                  'assets/images/app_icon.png',
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // 타이틀
            Text(
              l10n.appTitle,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1C19),
              ),
            ),
            const SizedBox(height: 8),
            // 서브타이틀
            Text(
              l10n.appSubtitle,
              style: const TextStyle(fontSize: 14, color: Color(0xFF44483E)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // 로딩 인디케이터 (3개 점)
            AnimatedBuilder(
              animation: _dotController,
              builder: (context, child) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (index) {
                    const colors = [
                      Color(0xFF2E7D32),
                      Color(0xFFA8DAB5),
                      Color(0xFFC4C8BB),
                    ];
                    final delay = index * 0.3;
                    final value = _dotController.value;
                    final opacity = ((value - delay) % 1.0 < 0.5) ? 1.0 : 0.4;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Opacity(
                        opacity: opacity,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: colors[index],
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
