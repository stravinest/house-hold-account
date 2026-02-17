import 'dart:async';
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/generated/app_localizations.dart';
import 'shared/themes/locale_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:supabase_flutter/supabase_flutter.dart' show AuthChangeEvent;

import 'config/firebase_config.dart';
import 'config/router.dart';
import 'config/supabase_config.dart';
import 'features/ledger/presentation/providers/ledger_provider.dart';
import 'features/notification/presentation/providers/notification_provider.dart';
import 'features/notification/services/firebase_messaging_service.dart';
import 'features/notification/services/local_notification_service.dart';
import 'features/payment_method/presentation/widgets/permission_request_dialog.dart';
import 'features/settings/data/services/app_update_service.dart';
import 'features/settings/presentation/widgets/app_update_dialog.dart';
import 'features/settings/presentation/widgets/guide_dialog.dart';
import 'features/widget/data/services/widget_data_service.dart';
import 'features/payment_method/presentation/providers/auto_save_manager.dart';
import 'features/payment_method/data/services/app_badge_service.dart';
import 'shared/themes/app_theme.dart';
import 'shared/themes/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 한국어 로케일 데이터 초기화 (DateFormat, NumberFormat 사용 전에 호출 필요)
  await initializeDateFormatting('ko_KR', null);

  // Supabase 초기화
  try {
    await SupabaseConfig.initialize();
  } catch (e) {
    debugPrint('Supabase 초기화 실패: $e');
  }

  try {
    final firebaseOptions = FirebaseConfig.options;
    if (firebaseOptions != null) {
      await Firebase.initializeApp(options: firebaseOptions);
      debugPrint('Firebase 초기화 완료');

      // Firebase Analytics 초기화 (FCM이 Analytics에 의존함)
      FirebaseAnalytics.instance;
      debugPrint('Firebase Analytics 초기화 완료');
    } else {
      debugPrint('Firebase 설정이 없습니다. 푸시 알림 기능은 비활성화됩니다.');
    }
  } catch (e) {
    debugPrint('Firebase 초기화 실패: $e');
    debugPrint('푸시 알림 기능은 비활성화됩니다. Firebase 설정을 확인하세요.');
  }

  try {
    await WidgetDataService.initialize();
    debugPrint('홈 위젯 서비스 초기화 완료');
  } catch (e) {
    debugPrint('홈 위젯 서비스 초기화 실패: $e');
  }

  try {
    await LocalNotificationService().initialize();
    debugPrint('로컬 알림 서비스 초기화 완료');
  } catch (e) {
    debugPrint('로컬 알림 서비스 초기화 실패: $e');
  }

  try {
    await AppBadgeService.instance.initialize();
    debugPrint('앱 뱃지 서비스 초기화 완료');
  } catch (e) {
    debugPrint('앱 뱃지 서비스 초기화 실패: $e');
  }

  final sharedPreferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const SharedHouseholdAccountApp(),
    ),
  );
}

class SharedHouseholdAccountApp extends ConsumerStatefulWidget {
  const SharedHouseholdAccountApp({super.key});

  @override
  ConsumerState<SharedHouseholdAccountApp> createState() =>
      _SharedHouseholdAccountAppState();
}

class _SharedHouseholdAccountAppState
    extends ConsumerState<SharedHouseholdAccountApp>
    with WidgetsBindingObserver {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  StreamSubscription<dynamic>? _authSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initDeepLinks();
    _setupNotificationTapHandlers();

    // 로그인 시 가이드 + 권한 확인 + 업데이트 체크 설정
    _setupLoginPermissionCheck();
  }

  /// 로그인 시 가이드 + 권한 확인 + 업데이트 체크 설정
  void _setupLoginPermissionCheck() {
    // 인증 상태 변경 감지
    _authSubscription = SupabaseConfig.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;

      // 로그인 이벤트 (signedIn) 및 세션이 있을 때만 처리
      if (event == AuthChangeEvent.signedIn && session != null) {
        // 권한 확인 후 비허용된 권한이 있으면 다이얼로그 표시 (Android 전용)
        if (Platform.isAndroid) {
          _checkPermissionsOnLogin();
        }
        // 앱 업데이트 확인 (모든 플랫폼)
        _checkForAppUpdate();
      }
    });
  }

  /// 로그인 시 가이드 및 권한 다이얼로그 표시
  Future<void> _checkPermissionsOnLogin() async {
    // 약간의 딜레이 후 확인 (홈 화면 로딩 완료 후)
    await Future.delayed(const Duration(milliseconds: 2000));

    final navigatorContext = rootNavigatorKey.currentContext;
    if (navigatorContext == null || !navigatorContext.mounted) return;

    final prefs = ref.read(sharedPreferencesProvider);
    const guideFlag = 'guide_dialog_shown';

    if (prefs.getBool(guideFlag) != true) {
      // 가이드 다이얼로그 표시 (첫 로그인)
      await GuideDialog.show(navigatorContext);

      // 플래그 설정
      await prefs.setBool(guideFlag, true);

      // 가이드 닫힌 후 권한 다이얼로그 표시 (Android 전용)
      if (!navigatorContext.mounted) return;
      if (Platform.isAndroid) {
        await PermissionRequestDialog.showInitialPermissions(navigatorContext);
      }
    } else {
      // 이미 가이드를 본 경우, 비허용 권한 있으면 권한 다이얼로그만 표시
      await PermissionRequestDialog.showIfAnyDenied(navigatorContext);
    }
  }

  /// 앱 업데이트 확인
  Future<void> _checkForAppUpdate() async {
    // 가이드/권한 다이얼로그 이후 체크하도록 딜레이
    await Future.delayed(const Duration(milliseconds: 3000));

    final navigatorContext = rootNavigatorKey.currentContext;
    if (navigatorContext == null || !navigatorContext.mounted) return;

    final prefs = ref.read(sharedPreferencesProvider);
    final versionInfo = await AppUpdateService.checkForUpdate(prefs: prefs);

    if (versionInfo != null) {
      final ctx = rootNavigatorKey.currentContext;
      if (ctx != null && ctx.mounted) {
        await AppUpdateDialog.show(ctx, versionInfo);
      }
    }
  }

  /// 알림 탭 핸들러 설정
  void _setupNotificationTapHandlers() {
    // 로컬 알림 탭 핸들러
    LocalNotificationService().onNotificationTap = _handleNotificationTap;

    // FCM 알림 탭 핸들러
    FirebaseMessagingService().onNotificationTap = _handleNotificationTap;

    // 앱 시작 시 초기 알림 확인 (지연 실행)
    Future.delayed(const Duration(milliseconds: 1000), () {
      LocalNotificationService().checkInitialNotification();
      FirebaseMessagingService().checkInitialMessage();
    });
  }

  /// 알림 탭 시 라우팅 처리
  void _handleNotificationTap(String? type, Map<String, dynamic>? data) {
    debugPrint('알림 탭 처리: type=$type, data=$data');

    final router = ref.read(routerProvider);

    switch (type) {
      case 'invite_received':
      case 'invite_accepted':
        // 초대 관련 알림 -> 홈 화면으로 이동 후 공유 관리 화면으로 push
        // go() 대신 push()를 사용하여 뒤로가기 버튼이 표시되도록 함
        router.go(Routes.home);
        Future.microtask(() => router.push(Routes.share));
        break;
      case 'shared_ledger_change':
        // 공유 가계부 변경 알림 -> 홈 화면으로 이동
        router.go(Routes.home);
        break;
      case 'auto_collect_suggested':
        // 자동수집 제안 알림 -> 결제수단 관리 > 수집내역 > 대기중 탭
        router.go(Routes.home);
        Future.microtask(
          () => router.push('${Routes.paymentMethod}?tab=pending'),
        );
        break;
      case 'auto_collect_saved':
        // 자동수집 저장 알림 -> 결제수단 관리 > 수집내역 > 확인됨 탭
        router.go(Routes.home);
        Future.microtask(
          () => router.push('${Routes.paymentMethod}?tab=confirmed'),
        );
        break;
      default:
        // 기타 알림 -> 홈 화면으로 이동
        router.go(Routes.home);
        break;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // 로그인 상태일 때만 업데이트 체크 (24시간 제한으로 중복 방지)
      final session = SupabaseConfig.auth.currentSession;
      if (session != null) {
        _checkForAppUpdate();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _linkSubscription?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    // 앱이 종료된 상태에서 딥링크로 실행된 경우 처리
    try {
      final uri = await _appLinks.getInitialLink();
      if (uri != null) {
        _handleDeepLink(uri);
      }
    } catch (e) {
      debugPrint('초기 딥링크 처리 실패: $e');
    }

    // 앱이 실행 중일 때 딥링크 처리
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        _handleDeepLink(uri);
      },
      onError: (err) {
        debugPrint('딥링크 스트림 에러: $err');
      },
    );
  }

  // 허용된 딥링크 호스트 목록 (보안: 화이트리스트 방식)
  static const _allowedHosts = {
    'auth-callback', // Supabase 인증 콜백
    'add-expense', // 지출 추가
    'add-income', // 수입 추가
    'quick-expense', // 빠른 지출 추가
    'payment-method', // 자동수집 알림 딥링크
  };

  void _handleDeepLink(Uri uri) {
    debugPrint('딥링크 수신: $uri');

    // scheme이 sharedhousehold인 경우에만 처리
    if (uri.scheme != 'sharedhousehold') {
      debugPrint('지원하지 않는 스킴: ${uri.scheme}');
      return;
    }

    // 보안: 허용된 호스트만 처리 (화이트리스트 방식)
    if (uri.host.isNotEmpty && !_allowedHosts.contains(uri.host)) {
      debugPrint('허용되지 않은 호스트: ${uri.host}');
      return;
    }

    // Supabase 인증 콜백 처리 (이메일 인증, 비밀번호 재설정 등)
    // sharedhousehold://auth-callback?... 형태로 들어옴
    // 보안: uri.hasFragment 조건 제거 (너무 광범위하여 악의적 URI 허용 가능)
    if (uri.host == 'auth-callback') {
      debugPrint('Supabase 인증 콜백 감지');
      // Supabase SDK가 자동으로 세션을 처리함
      // 세션 복구 후 홈으로 이동
      _handleAuthCallback(uri);
      return;
    }

    // URI의 host가 라우트 경로가 됨
    // 예: sharedhousehold://add-expense -> /add-expense
    // 예: sharedhousehold://payment-method?tab=pending -> /payment-method?tab=pending
    final path = uri.host.isEmpty ? '/' : '/${uri.host}';
    final queryString = uri.query.isNotEmpty ? '?${uri.query}' : '';
    final fullPath = '$path$queryString';

    // 라우터로 이동
    final router = ref.read(routerProvider);

    // 딥링크 처리를 약간 지연시켜 앱이 완전히 초기화되도록 함
    Future.delayed(const Duration(milliseconds: 500), () {
      // payment-method는 별도 페이지이므로 홈 위에 스택으로 추가
      // 알림 탭(_handleNotificationTap)과 동일한 패턴 사용
      if (uri.host == 'payment-method') {
        router.go(Routes.home);
        Future.microtask(() {
          router.push(fullPath);
          debugPrint('딥링크 라우팅 (push): $fullPath');
        });
      } else {
        // add-expense, add-income, quick-expense는 HomePage 자체를 렌더링하므로 go() 유지
        router.go(fullPath);
        debugPrint('딥링크 라우팅 (go): $fullPath');
      }
    });
  }

  Future<void> _handleAuthCallback(Uri uri) async {
    debugPrint('인증 콜백 처리 시작: $uri');

    try {
      // Supabase SDK가 URI에서 토큰을 추출하여 세션 복구
      final response = await SupabaseConfig.client.auth.getSessionFromUrl(uri);
      debugPrint('세션 복구 성공');

      final user = response.session.user;
      final router = ref.read(routerProvider);

      // 비밀번호 재설정 감지 (URL fragment에 type=recovery 포함)
      final isPasswordRecovery =
          uri.fragment.contains('type=recovery') ||
          uri.queryParameters['type'] == 'recovery';

      if (isPasswordRecovery) {
        debugPrint('비밀번호 재설정 - 새 비밀번호 입력 페이지로 이동');
        Future.delayed(const Duration(milliseconds: 500), () {
          router.go(Routes.resetPassword);
        });
      } else if (user.emailConfirmedAt != null) {
        // 이메일 인증 완료 - 홈으로 이동
        Future.delayed(const Duration(milliseconds: 500), () {
          router.go(Routes.home);
          debugPrint('이메일 인증 완료 - 홈으로 이동');
        });
      } else {
        // 이메일 미인증 - 인증 대기 페이지로 이동
        final email = user.email ?? '';
        Future.delayed(const Duration(milliseconds: 500), () {
          router.go(
            '${Routes.emailVerification}?email=${Uri.encodeComponent(email)}',
          );
          debugPrint('이메일 미인증 - 인증 페이지로 이동');
        });
      }
    } catch (e) {
      debugPrint('세션 복구 실패: $e');
      // 실패해도 로그인 페이지로 이동
      final router = ref.read(routerProvider);
      router.go(Routes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    // FCM 토큰 관리 및 자동 저장 서비스 관리
    // build에서의 watch는 에러 발생 시 앱 전체를 크래시(회색 화면) 시킬 수 있으나,
    // notificationProvider는 내부적으로 AsyncValue를 사용하므로 안전하게 감시합니다.
    ref.watch(notificationProvider);

    // autoSaveManagerProvider는 Provider<void>이므로 listen 대신 watch를 사용합니다.
    ref.watch(autoSaveManagerProvider);

    // ledgerIdPersistenceProvider를 watch하여 가계부 ID 저장 리스너 활성화
    // Provider<void>는 반드시 watch로 호출해야 내부 ref.listen()이 작동함
    ref.watch(ledgerIdPersistenceProvider);

    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: SupportedLocales.all,
      locale: locale,
      builder: (context, child) {
        return child ?? const SizedBox.shrink();
      },
    );
  }
}
