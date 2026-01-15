import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config/firebase_config.dart';
import 'config/router.dart';
import 'config/supabase_config.dart';
import 'features/ledger/presentation/providers/ledger_provider.dart';
import 'features/notification/presentation/providers/notification_provider.dart';
import 'features/notification/services/local_notification_service.dart';
import 'features/widget/data/services/widget_data_service.dart';
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
    extends ConsumerState<SharedHouseholdAccountApp> {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();

    Future.microtask(() {
      ref.read(ledgerIdPersistenceProvider);
    });
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
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

  void _handleDeepLink(Uri uri) {
    debugPrint('딥링크 수신: $uri');

    // scheme이 sharedhousehold인 경우에만 처리
    if (uri.scheme != 'sharedhousehold') {
      debugPrint('지원하지 않는 스킴: ${uri.scheme}');
      return;
    }

    // URI의 host가 라우트 경로가 됨
    // 예: sharedhousehold://add-expense -> /add-expense
    final path = uri.host.isEmpty ? '/' : '/${uri.host}';

    // 라우터로 이동
    final router = ref.read(routerProvider);

    // 딥링크 처리를 약간 지연시켜 앱이 완전히 초기화되도록 함
    Future.delayed(const Duration(milliseconds: 500), () {
      router.go(path);
      debugPrint('딥링크 라우팅: $path');
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    // FCM 토큰 관리: 사용자 인증 상태 변경 시 자동으로 토큰 저장/삭제
    // notificationProvider가 authStateChangesProvider를 watch하므로
    // 로그인/로그아웃 시 FCM 토큰이 자동으로 관리됨
    ref.watch(notificationProvider);

    return MaterialApp.router(
      title: '공유 가계부',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ko', 'KR'), Locale('en', 'US')],
      locale: const Locale('ko', 'KR'),
    );
  }
}
