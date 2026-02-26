import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:notification_listener_service/notification_event.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../notification/data/services/notification_service.dart';
import '../../../notification/domain/entities/notification_type.dart';
import '../../../notification/services/local_notification_service.dart';
import '../../../transaction/data/repositories/transaction_repository.dart';
import '../../domain/entities/learned_push_format.dart';
import '../../domain/entities/payment_method.dart';
import '../../domain/entities/pending_transaction.dart';
import '../models/learned_push_format_model.dart';
import '../models/payment_method_model.dart';
import '../models/pending_transaction_model.dart';
import '../repositories/learned_push_format_repository.dart';
import '../repositories/payment_method_repository.dart';
import '../repositories/pending_transaction_repository.dart';
import 'category_mapping_service.dart';
import 'duplicate_check_service.dart';
import 'native_notification_sync_service.dart';
import 'sms_parsing_service.dart';

class NotificationListenerWrapper {
  NotificationListenerWrapper._()
    : _paymentMethodRepository = PaymentMethodRepository(),
      _pendingTransactionRepository = PendingTransactionRepository(),
      _transactionRepository = TransactionRepository(),
      _learnedPushFormatRepository = LearnedPushFormatRepository(),
      _categoryMappingService = CategoryMappingService(),
      _duplicateCheckService = DuplicateCheckService(),
      _notificationService = NotificationService();

  /// 테스트용 팩토리 생성자
  /// 의존성 주입을 통해 mock 객체를 사용할 수 있도록 지원
  @visibleForTesting
  NotificationListenerWrapper.forTesting({
    required PaymentMethodRepository paymentMethodRepository,
    required PendingTransactionRepository pendingTransactionRepository,
    required TransactionRepository transactionRepository,
    required LearnedPushFormatRepository learnedPushFormatRepository,
    required CategoryMappingService categoryMappingService,
    required DuplicateCheckService duplicateCheckService,
    required NotificationService notificationService,
  }) : _paymentMethodRepository = paymentMethodRepository,
       _pendingTransactionRepository = pendingTransactionRepository,
       _transactionRepository = transactionRepository,
       _learnedPushFormatRepository = learnedPushFormatRepository,
       _categoryMappingService = categoryMappingService,
       _duplicateCheckService = duplicateCheckService,
       _notificationService = notificationService;

  static NotificationListenerWrapper? _instance;
  static NotificationListenerWrapper get instance {
    _instance ??= NotificationListenerWrapper._();
    return _instance!;
  }

  // Kotlin MethodChannel for cache invalidation
  static const _notificationSyncChannel = MethodChannel(
    'com.household.shared/notification_sync',
  );

  /// Kotlin 서비스의 캐시를 무효화
  /// 결제수단 설정 변경 후 호출해야 함
  static Future<void> invalidateNativeCache() async {
    if (!Platform.isAndroid) return;

    try {
      await _notificationSyncChannel.invokeMethod(
        'invalidateNotificationCache',
      );
      if (kDebugMode) {
        debugPrint('[NotificationWrapper] Native cache invalidated');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[NotificationWrapper] Failed to invalidate native cache: $e',
        );
      }
    }
  }

  bool _isInitialized = false;
  bool _isListening = false;
  String? _currentUserId;
  String? _currentLedgerId;
  StreamSubscription<ServiceNotificationEvent>? _subscription;
  RealtimeChannel? _paymentMethodsSubscription;

  late final PaymentMethodRepository _paymentMethodRepository;
  late final PendingTransactionRepository _pendingTransactionRepository;
  late final TransactionRepository _transactionRepository;
  late final LearnedPushFormatRepository _learnedPushFormatRepository;
  late final CategoryMappingService _categoryMappingService;
  late final DuplicateCheckService _duplicateCheckService;
  late final NotificationService _notificationService;

  List<PaymentMethodModel> _autoSavePaymentMethods = [];
  final Map<String, List<LearnedPushFormatModel>> _learnedFormatsCache = {};

  // SMS/Push 중복 수신 방지 캐시 (메시지 해시 → 타임스탬프)
  final Map<String, DateTime> _recentlyProcessedMessages = {};
  static const Duration _messageCacheDuration = Duration(seconds: 10);

  // 소문자로 사전 변환하여 비교 최적화 (2026-01-25 웹 서치로 검증됨)
  static final Set<String> _financialAppPackagesLower = {
    // KB 카드/은행
    'com.kbcard.cxh.appcard', // KB Pay (KB국민카드 앱)
    'com.kbstar.kbbank', // KB국민은행
    // 신한 카드/은행
    'com.shinhan.sbanking', // 신한은행
    'com.shcard.smartpay', // 신한 SOL페이 (메인 카드 앱)
    'com.shinhancard.wallet', // 신한카드 올댓
    'com.shinhancard.smartshinhan', // 구 신한카드 앱
    // 삼성 카드/페이
    'com.samsung.android.spay', // 삼성페이
    'kr.co.samsungcard.mpocket', // 삼성카드 메인 앱
    'net.ib.android.smcard', // monimo (삼성금융네트웍스)
    'com.samsungcard.shopping', // 삼성카드 쇼핑
    // 현대카드
    'com.hyundaicard.appcard', // 현대카드 메인 앱
    'com.hyundaicard.weather', // 현대카드 웨더
    'com.hyundaicard.cultureapp', // 현대카드 DIVE
    'com.hyundaicard.hyundaicardmpoint', // 현대카드 M몰
    // 롯데카드
    'com.lcacapp', // 디지로카 (롯데카드 메인 앱)
    'com.lottecard.lcap', // 롯데카드 인슈플러스
    // 우리/하나 카드
    'com.wooricard.smartapp', // 우리카드
    'com.hanacard.app', // 하나카드
    // NH농협
    'nh.smart.nhallone', // NH스마트올원
    'nh.smart.banking', // NH스마트뱅킹
    // 기타 은행
    'com.ibk.neobanking', // IBK기업은행
    // 인터넷 전문 은행
    'com.kakaobank.channel', // 카카오뱅크
    'viva.republica.toss', // 토스뱅크
    'com.kbank.kbankapp', // 케이뱅크
    // 간편결제
    'com.naver.pay.app', // 네이버페이
    'com.naverfin.payapp', // 네이버페이 (대체)
    'com.kakaopay.app', // 카카오페이
    'com.komsco.kpay', // K-Pay
    // 카카오톡 (알림톡 금융 알림 수집)
    'com.kakao.talk', // 카카오톡 알림톡
    // 경기지역화폐 (실제 확인된 패키지명)
    'gov.gyeonggi.ggcard', // 경기지역화폐 공식 앱 (확인됨!)
    'kr.or.ggc', // 경기지역화폐 공통
    'com.ggc', // 경기지역화폐 앱
    'kr.suwon.pay', // 수원페이
    'com.gyeonggi.currency', // 경기화폐
    // 서울/인천 지역화폐 (2026-01-25 웹 서치로 검증됨)
    'com.bizplay.seoul.pay', // 서울사랑상품권 (서울페이+)
    'gov.incheon.incheonercard', // 인천이음페이
  };

  // 테스트용 패키지 (디버그 모드에서만 사용)
  static const String _testPackage = 'com.android.shell';

  // 메시지 앱 패키지 - Flutter 실시간 알림에서 제외
  // Kotlin FinancialNotificationListener가 MMS/SMS 알림을 직접 처리하여 SQLite에 저장
  // Flutter는 SQLite 동기화 시 이 알림들을 처리함 (syncCachedNotifications)
  static final Set<String> _smsAppPackages = {
    'com.google.android.apps.messaging', // Google Messages
    'com.samsung.android.messaging', // Samsung Messages
    'com.android.mms', // Stock Android SMS
    'com.sonyericsson.conversations', // Sony Messages
    'com.lge.message', // LG Messages
  };

  // 자기 앱 패키지 - 순환 푸시 알림 방지를 위해 제외
  // 공유 가계부에서 A가 거래 등록 시 B에게 푸시 알림이 가는데,
  // 이 알림이 B의 자동수집에서 감지되어 중복 거래가 생성되는 것을 방지
  static const String _ownAppPackage =
      'com.household.shared.shared_household_account';

  final _onNotificationProcessedController =
      StreamController<NotificationProcessedEvent>.broadcast();
  Stream<NotificationProcessedEvent> get onNotificationProcessed =>
      _onNotificationProcessedController.stream;

  bool get isAndroid => Platform.isAndroid;
  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;

  Future<bool> isPermissionGranted() async {
    if (!isAndroid) return false;

    try {
      return await NotificationListenerService.isPermissionGranted();
    } catch (e) {
      debugPrint('Notification permission check failed: $e');
      return false;
    }
  }

  Future<bool> requestPermission() async {
    if (!isAndroid) return false;

    try {
      // dynamic으로 받아서 타입 에러 방지
      final dynamic result =
          await NotificationListenerService.requestPermission();
      // bool로 안전하게 변환
      if (result is bool) {
        return result;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Notification permission request failed: $e');
      }
      // Reply already submitted 에러는 무시 (플러그인 버그)
      // 설정 화면은 정상적으로 열렸으므로 false 반환
      return false;
    }
  }

  Future<void> openSettings() async {
    if (!isAndroid) return;

    try {
      // dynamic으로 받아서 타입 에러 방지
      final dynamic result =
          await NotificationListenerService.requestPermission();
      // 반환값을 명시적으로 처리하여 타입 에러 방지
      if (kDebugMode) {
        debugPrint('Notification settings opened, result: $result');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to open notification settings: $e');
      }
      // Reply already submitted 에러는 무시 (플러그인 버그)
      // 설정 화면은 정상적으로 열렸으므로 에러를 무시
    }
  }

  Future<void> initialize({
    required String userId,
    required String ledgerId,
  }) async {
    if (!isAndroid) {
      debugPrint('Notification listener is only available on Android');
      return;
    }

    _currentUserId = userId;
    _currentLedgerId = ledgerId;

    await _loadAutoSavePaymentMethods();
    await _loadLearnedFormats();

    // Realtime 구독 시작: payment_methods 테이블 변경 시 캐시 갱신
    _paymentMethodsSubscription?.unsubscribe();
    _paymentMethodsSubscription = _paymentMethodRepository
        .subscribePaymentMethods(
          ledgerId: ledgerId,
          onPaymentMethodChanged: () {
            if (kDebugMode) {
              debugPrint(
                '[Realtime] payment_methods changed - refreshing cache',
              );
            }
            refreshPaymentMethods();
          },
        );

    _isInitialized = true;

    // 앱 시작 시 네이티브에 캐싱된 알림 동기화 (실패해도 초기화는 성공)
    try {
      await syncCachedNotifications();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[NativeSync] Initial sync failed, will retry later: $e');
      }
      // 동기화 실패는 초기화 실패로 간주하지 않음
      // 다음 앱 실행 시 재시도됨
    }
  }

  /// 앱 종료 중 네이티브 서비스가 수집한 알림을 동기화
  /// 앱 시작 시 자동 호출됨
  Future<int> syncCachedNotifications() async {
    if (!isAndroid || !_isInitialized) return 0;

    final syncService = NativeNotificationSyncService.instance;
    final cachedNotifications = await syncService.getPendingNotifications();

    if (cachedNotifications.isEmpty) {
      if (kDebugMode) {
        debugPrint('[NativeSync] No cached notifications to sync');
      }
      return 0;
    }

    if (kDebugMode) {
      debugPrint(
        '[NativeSync] Found ${cachedNotifications.length} cached notifications',
      );
    }

    final processedIds = <int>[];
    var successCount = 0;

    for (final notification in cachedNotifications) {
      try {
        if (kDebugMode) {
          debugPrint('[NativeSync] Processing: ${notification.packageName}');
        }

        // 기존 processManualNotification 로직 재사용
        await _processCachedNotification(notification);
        processedIds.add(notification.id);
        successCount++;
      } catch (e) {
        if (kDebugMode) {
          debugPrint(
            '[NativeSync] Failed to process notification ${notification.id}: $e',
          );
        }
        // 실패한 알림의 재시도 횟수 증가 (3회 초과 시 더 이상 재시도하지 않음)
        final newRetryCount = await syncService.incrementRetryCount(
          notification.id,
        );
        if (kDebugMode) {
          if (newRetryCount >= 3) {
            debugPrint(
              '[NativeSync] Notification ${notification.id} exceeded max retries, will not retry',
            );
          } else {
            debugPrint(
              '[NativeSync] Notification ${notification.id} retry count: $newRetryCount/3',
            );
          }
        }
        // 실패해도 다음 알림 처리 계속
      }
    }

    // 처리된 알림 동기화됨으로 표시
    if (processedIds.isNotEmpty) {
      await syncService.markAsSynced(processedIds);
    }

    // 오래된 알림 정리 (7일 이상)
    await syncService.clearOldNotifications(olderThanDays: 7);

    if (kDebugMode) {
      debugPrint(
        '[NativeSync] Synced $successCount/${cachedNotifications.length} notifications',
      );
    }

    return successCount;
  }

  /// 네이티브에서 캐싱된 알림 처리
  Future<void> _processCachedNotification(
    CachedNotification notification,
  ) async {
    if (_currentUserId == null || _currentLedgerId == null) return;

    final packageName = notification.packageName;
    final title = notification.title ?? '';
    final content = notification.text;
    final timestamp = notification.receivedAt;

    final combinedContent = '$title $content';

    // 결제수단 매칭
    final matchResult = _findMatchingPaymentMethod(
      packageName,
      combinedContent,
    );

    if (matchResult == null) {
      if (kDebugMode) {
        debugPrint('[NativeSync] No matching payment method for: $packageName');
      }
      return;
    }

    // 기존 처리 로직 재사용
    await _processNotification(
      packageName: packageName,
      content: combinedContent,
      timestamp: timestamp,
      paymentMethod: matchResult.paymentMethod,
      learnedFormat: matchResult.learnedFormat,
      sourceType: notification.sourceType ?? 'notification',
    );
  }

  Future<void> _loadAutoSavePaymentMethods() async {
    if (_currentLedgerId == null || _currentUserId == null) return;

    try {
      _autoSavePaymentMethods = await _paymentMethodRepository
          .getAutoSaveEnabledPaymentMethods(_currentLedgerId!, _currentUserId!);
    } catch (e) {
      debugPrint('Failed to load auto-save payment methods: $e');
      _autoSavePaymentMethods = [];
    }
  }

  Future<void> _loadLearnedFormats() async {
    _learnedFormatsCache.clear();

    for (final pm in _autoSavePaymentMethods) {
      try {
        final formats = await _learnedPushFormatRepository.getByPaymentMethodId(
          pm.id,
        );
        if (formats.isNotEmpty) {
          _learnedFormatsCache[pm.id] = formats;
        }
      } catch (e) {
        debugPrint('Failed to load learned formats for ${pm.id}: $e');
      }
    }
  }

  Future<void> refreshPaymentMethods() async {
    await _loadAutoSavePaymentMethods();
    await _loadLearnedFormats();
  }

  void startListening() {
    if (!isAndroid || !_isInitialized || _isListening) return;

    _subscription = NotificationListenerService.notificationsStream.listen(
      onNotificationReceived,
      onError: (error) {
        debugPrint('Notification stream error: $error');
      },
    );

    _isListening = true;
    debugPrint('Notification listener started');
  }

  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _isListening = false;
    debugPrint('Notification listener stopped');
  }

  @visibleForTesting
  Future<void> onNotificationReceived(ServiceNotificationEvent event) async {
    // 디버그 모드에서 모든 알림의 패키지명을 출력 (금융 앱 패키지명 확인용)
    if (kDebugMode) {
      debugPrint('========================================');
      debugPrint('[NotificationListener] 알림 수신:');
      debugPrint('  - 패키지명: ${event.packageName}');
      debugPrint('  - 제목: ${event.title}');
      // content는 금액/가맹점 정보 포함 - 일부만 출력
      final contentPreview = (event.content ?? '').length > 30
          ? '${event.content!.substring(0, 30)}...'
          : event.content;
      debugPrint('  - 내용 미리보기: $contentPreview');
      debugPrint('  - 삭제됨: ${event.hasRemoved}');
      debugPrint('========================================');
    }

    if (_currentUserId == null || _currentLedgerId == null) {
      if (kDebugMode) {
        debugPrint(
          '[NotificationListener] Skipping: userId or ledgerId is null',
        );
      }
      return;
    }
    // hasRemoved 체크 - 디버그 모드의 테스트 알림은 예외 처리
    final packageName = event.packageName ?? '';
    final isTestNotification =
        kDebugMode && packageName.toLowerCase().contains(_testPackage);
    if (event.hasRemoved == true && !isTestNotification) {
      if (kDebugMode) {
        debugPrint('[NotificationListener] Skipping: notification removed');
      }
      return;
    }
    if (isTestNotification && kDebugMode) {
      debugPrint(
        '[NotificationListener] Processing test notification (ignoring hasRemoved)',
      );
    }

    final title = event.title ?? '';
    final content = event.content ?? '';
    final timestamp = DateTime.now();

    if (packageName.isEmpty || content.isEmpty) {
      if (kDebugMode) {
        debugPrint(
          '[NotificationListener] Skipping: packageName or content is empty',
        );
      }
      return;
    }

    // 메시지 앱 알림 제외 - Kotlin FinancialNotificationListener가 처리하므로 중복 방지
    final packageLower = packageName.toLowerCase();
    if (_smsAppPackages.any((pkg) => packageLower.contains(pkg))) {
      if (kDebugMode) {
        debugPrint(
          '[NotificationListener] Skipping message app: $packageName (handled by Kotlin)',
        );
      }
      return;
    }

    // 자기 앱 푸시 알림 제외 - 공유 가계부의 FCM 알림 중복 방지
    if (packageLower.contains(_ownAppPackage)) {
      if (kDebugMode) {
        debugPrint('[NotificationListener] Skipping own app: $packageName');
      }
      return;
    }

    final combinedContent = '$title $content';

    // 카카오톡 알림톡: 금융 채널 title + 거래 키워드 + 금액 패턴 3중 검증
    // 개인 채팅/일반 채널 알림을 확실히 차단
    final isKakaoPackage = packageLower.contains('com.kakao.talk');
    if (isKakaoPackage) {
      if (!_isFinancialAlimtalk(title, content)) {
        if (kDebugMode) {
          debugPrint(
            '[NotificationListener] Skipping non-financial kakao notification (title: $title)',
          );
        }
        return;
      }
      if (kDebugMode) {
        debugPrint(
          '[NotificationListener] Kakao alimtalk financial notification: $title',
        );
      }
    }

    // 패키지명 또는 내용에서 금융 관련 여부 확인
    final isFinancial = _isFinancialApp(packageName);
    final isFinancialSender = FinancialSmsSenders.isFinancialSender(
      title,
      content,
    );
    if (kDebugMode) {
      debugPrint(
        '[NotificationListener] isFinancialApp: $isFinancial, isFinancialSender: $isFinancialSender',
      );
    }

    if (!isFinancial && !isFinancialSender) {
      if (kDebugMode) {
        debugPrint(
          '[NotificationListener] Skipping non-financial: $packageName',
        );
      }
      return;
    }

    if (kDebugMode) {
      debugPrint('[NotificationListener] Processing: $packageName');
      debugPrint(
        '[NotificationListener] Auto-save PM count: ${_autoSavePaymentMethods.length}',
      );
      for (final pm in _autoSavePaymentMethods) {
        debugPrint(
          '  - ${pm.name} (mode: ${pm.autoSaveMode.toJson()}, source: ${pm.autoCollectSource.toJson()})',
        );
      }
    }

    final matchResult = _findMatchingPaymentMethod(
      packageName,
      combinedContent,
    );
    if (matchResult == null) {
      debugPrint(
        '[NotificationListener] No matching payment method found for package: $packageName',
      );
      debugPrint('[NotificationListener] combinedContent: $combinedContent');
      return;
    }

    debugPrint(
      '[NotificationListener] Found match: ${matchResult.paymentMethod.name}',
    );

    // 카카오톡 알림톡도 Push 알림이므로 sourceType은 'notification'
    const sourceType = 'notification';

    await _processNotification(
      packageName: packageName,
      content: combinedContent,
      timestamp: timestamp,
      paymentMethod: matchResult.paymentMethod,
      learnedFormat: matchResult.learnedFormat,
      sourceType: sourceType,
    );
  }

  @visibleForTesting
  Future<void> processManualNotification({
    required String packageName,
    required String title,
    required String content,
  }) async {
    if (_currentUserId == null || _currentLedgerId == null) return;

    final combinedContent = '$title $content';
    final matchResult = _findMatchingPaymentMethod(
      packageName,
      combinedContent,
    );

    if (matchResult == null) {
      debugPrint(
        'Manual Notification: No matching payment method found for package: $packageName',
      );
      return;
    }

    await _processNotification(
      packageName: packageName,
      content: combinedContent,
      timestamp: DateTime.now(),
      paymentMethod: matchResult.paymentMethod,
      learnedFormat: matchResult.learnedFormat,
    );
  }

  @visibleForTesting
  static bool isFinancialAppForTesting(String packageName) {
    return _isFinancialAppStatic(packageName);
  }

  static bool _isFinancialAppStatic(String packageName) {
    final packageLower = packageName.toLowerCase();

    // 디버그 모드에서만 테스트 패키지(com.android.shell) 허용
    if (kDebugMode && packageLower.contains(_testPackage)) {
      return true;
    }

    return _financialAppPackagesLower.any((pkg) => packageLower.contains(pkg));
  }

  bool _isFinancialApp(String packageName) {
    return _isFinancialAppStatic(packageName);
  }

  /// 테스트에서 키워드 동기화 검증을 위한 접근자
  @visibleForTesting
  static List<String> get financialChannelKeywordsForTesting =>
      _financialChannelKeywords;

  @visibleForTesting
  static List<String> get alimtalkTransactionKeywordsForTesting =>
      _alimtalkTransactionKeywords;

  @visibleForTesting
  static RegExp get amountPatternForTesting => _amountPattern;

  // 카카오톡 알림톡 금융 채널 키워드 (title에서 확인)
  // FinancialNotificationListener.kt의 FINANCIAL_CHANNEL_KEYWORDS와 동기화 필요
  static const _financialChannelKeywords = [
    // 카드사
    'KB국민카드', '국민카드', '신한카드', '삼성카드', '현대카드',
    '롯데카드', '우리카드', '하나카드', 'BC카드', 'NH카드',
    '비씨카드',
    // 은행
    'KB국민은행', '국민은행', '신한은행', '우리은행', '하나은행',
    'NH농협', '농협은행', 'IBK기업은행', '기업은행',
    '카카오뱅크', '토스뱅크', '케이뱅크',
    // 간편결제
    '카카오페이', '네이버페이',
    // 카카오톡 알림톡 채널명 (실제 알림에서 title로 사용됨)
    '카드영수증',
  ];

  // 카카오톡 알림톡 본문 거래 키워드
  // FinancialNotificationListener.kt의 ALIMTALK_TRANSACTION_KEYWORDS와 동기화 필요
  static const _alimtalkTransactionKeywords = [
    '승인',
    '결제',
    '출금',
    '입금',
    '이체',
    '충전',
    '취소',
    '환불',
    '일시불',
    '할부',
    '사용금액',
    '잔액',
    '체크카드',
    '신용카드',
    '사용',
  ];

  // 금액 패턴 정규식
  static final _amountPattern = RegExp(r'[0-9,]+원|\d{1,3}(,\d{3})+');

  /// 카카오톡 알림톡 금융 알림 3중 검증 (테스트용 public static 메서드)
  /// 1) title이 금융 채널 키워드 포함
  /// 2) content에 거래 키워드 포함
  /// 3) content에 금액 패턴 포함
  @visibleForTesting
  static bool isFinancialAlimtalkForTesting(String title, String content) {
    return _isFinancialAlimtalkStatic(title, content);
  }

  static bool _isFinancialAlimtalkStatic(String title, String content) {
    if (title.isEmpty || content.isEmpty) return false;

    // 1) 금융 채널 title 확인
    final titleLower = title.toLowerCase();
    final isFinancialChannel = _financialChannelKeywords.any(
      (keyword) => titleLower.contains(keyword.toLowerCase()),
    );
    if (!isFinancialChannel) return false;

    // 2) 거래 키워드 확인
    final hasTransactionKeyword = _alimtalkTransactionKeywords.any(
      (keyword) => content.contains(keyword),
    );
    if (!hasTransactionKeyword) return false;

    // 3) 금액 패턴 확인
    final hasAmountPattern = _amountPattern.hasMatch(content);
    if (!hasAmountPattern) return false;

    return true;
  }

  bool _isFinancialAlimtalk(String title, String content) {
    return _isFinancialAlimtalkStatic(title, content);
  }

  _PaymentMethodMatchResult? _findMatchingPaymentMethod(
    String packageName,
    String content,
  ) {
    final packageLower = packageName.toLowerCase();
    final contentLower = content.toLowerCase();

    if (kDebugMode) {
      debugPrint('[Matching] Searching for payment method match...');
      // content는 민감 정보 포함 가능 - 길이만 출력
      debugPrint('[Matching] content length: ${contentLower.length}');
    }

    for (final pm in _autoSavePaymentMethods) {
      // Push 소스로 설정된 결제수단만 매칭 (SMS로 설정된 결제수단은 무시)
      // 카카오톡 알림톡도 Push 알림이므로 push 소스 결제수단과 매칭됨
      if (pm.autoCollectSource != AutoCollectSource.push) continue;

      final formats = _learnedFormatsCache[pm.id];
      if (kDebugMode) {
        debugPrint(
          '[Matching] Checking PM: ${pm.name}, formats: ${formats?.length ?? 0}',
        );
      }

      // 1. 학습된 포맷으로 먼저 매칭 시도
      if (formats != null && formats.isNotEmpty) {
        for (final format in formats) {
          if (kDebugMode) {
            debugPrint('[Matching] Checking format: ${format.packageName}');
          }

          // payment_method_id 일치 여부 검증
          if (format.paymentMethodId != pm.id) {
            if (kDebugMode) {
              debugPrint(
                '[Matching] WARNING: Format payment_method_id mismatch!',
              );
              debugPrint('  Format ID: ${format.id}');
              debugPrint('  Format PM ID: ${format.paymentMethodId}');
              debugPrint('  Current PM ID: ${pm.id}');
            }
            continue; // 불일치하면 스킵
          }

          if (format.matchesNotification(packageLower, contentLower)) {
            if (kDebugMode) {
              debugPrint('[Matching] Matched by format!');
            }
            return _PaymentMethodMatchResult(
              paymentMethod: pm,
              learnedFormat: format.toEntity(),
            );
          }
        }
      }

      // 2. Fallback: 결제수단 이름이 내용에 포함되어 있는지 확인 (이름이 2자 이상인 경우만)
      final pmName = pm.name.toLowerCase();
      final nameMatches = pmName.length >= 2 && contentLower.contains(pmName);
      final isOwner = pm.ownerUserId == _currentUserId;

      if (kDebugMode) {
        debugPrint(
          '[Matching] Fallback: pmName="$pmName", matches=$nameMatches, isOwner=$isOwner',
        );
      }

      // 이름 매칭 + owner 일치 모두 확인
      if (nameMatches && isOwner) {
        if (kDebugMode) {
          debugPrint('[Matching] Matched by payment method name!');
        }
        return _PaymentMethodMatchResult(paymentMethod: pm);
      } else if (nameMatches && !isOwner) {
        // 이름은 일치하지만 owner가 다른 경우 경고 로그
        if (kDebugMode) {
          debugPrint('[Matching] WARNING: Name matched but owner mismatch!');
          debugPrint('  PM ID: ${pm.id}');
          debugPrint('  PM Owner: ${pm.ownerUserId}');
          debugPrint('  Current User: $_currentUserId');
        }
      }
    }
    return null;
  }

  Future<void> _processNotification({
    required String packageName,
    required String content,
    required DateTime timestamp,
    required PaymentMethodModel paymentMethod,
    LearnedPushFormat? learnedFormat,
    String sourceType = 'notification',
  }) async {
    // 메시지 내용으로 해시 생성 (중복 수신 방지)
    final messageHash = DuplicateCheckService.generateMessageHash(
      content,
      timestamp,
    );

    // 최근 10초 이내에 동일한 메시지를 처리했는지 확인
    final cachedTime = _recentlyProcessedMessages[messageHash];
    if (cachedTime != null) {
      final timeDiff = DateTime.now().difference(cachedTime);
      if (timeDiff < _messageCacheDuration) {
        debugPrint(
          'Duplicate notification detected (cached ${timeDiff.inSeconds}s ago) - ignoring',
        );
        return;
      }
    }

    // 메시지 처리 시작 - 캐시에 기록
    _recentlyProcessedMessages[messageHash] = DateTime.now();
    _cleanupMessageCache();

    ParsedSmsResult parsedResult;

    if (learnedFormat != null) {
      parsedResult = SmsParsingService.parseSmsWithFormat(
        content,
        learnedFormat,
      );

      await _learnedPushFormatRepository.incrementMatchCount(learnedFormat.id);
    } else {
      parsedResult = SmsParsingService.parseSms(packageName, content);
    }

    if (!parsedResult.isParsed) {
      if (kDebugMode) {
        debugPrint('Notification parsing failed. Result: $parsedResult');
      }
      _onNotificationProcessedController.add(
        NotificationProcessedEvent(
          packageName: packageName,
          content: content,
          success: false,
          reason: 'parsing_failed',
        ),
      );
      return;
    }

    final duplicateResult = await _duplicateCheckService.checkDuplicate(
      amount: parsedResult.amount!,
      paymentMethodId: paymentMethod.id,
      ledgerId: _currentLedgerId!,
      timestamp: timestamp,
    );

    String? categoryId = paymentMethod.defaultCategoryId;
    if (categoryId == null) {
      // 1순위: 사용자 키워드 매핑 (원본 알림 내용 기반)
      categoryId = await _categoryMappingService.findCategoryByKeywordMapping(
        content,
        paymentMethod.id,
        'push',
        _currentLedgerId!,
      );
    }
    if (categoryId == null && parsedResult.merchant != null) {
      // 2순위: 기존 상호명 기반 매핑
      categoryId = await _categoryMappingService.findCategoryId(
        parsedResult.merchant!,
        _currentLedgerId!,
      );
    }

    // 캐시에서 최신 autoSaveMode 확인 (refreshPaymentMethods()로 동기화됨)
    final cachedPaymentMethod = _autoSavePaymentMethods
        .where((pm) => pm.id == paymentMethod.id)
        .firstOrNull;
    final autoSaveModeStr =
        cachedPaymentMethod?.autoSaveMode.toJson() ??
        paymentMethod.autoSaveMode.toJson();
    if (kDebugMode) {
      debugPrint('=== AutoSaveMode Decision ===');
      debugPrint('  PM ID: ${paymentMethod.id}');
      debugPrint('  PM Name: ${paymentMethod.name}');
      debugPrint('  PM Owner: ${paymentMethod.ownerUserId}');
      debugPrint('  Current User: $_currentUserId');
      debugPrint('  Original mode: ${paymentMethod.autoSaveMode.toJson()}');
      debugPrint(
        '  Cached mode: ${cachedPaymentMethod?.autoSaveMode.toJson() ?? "not found"}',
      );
      debugPrint('  Final mode: $autoSaveModeStr');
      debugPrint('  isDuplicate: ${duplicateResult.isDuplicate}');
      debugPrint('=============================');
    }

    // 자동 저장 여부 결정: 중복이 아니고 auto 모드일 때만 자동 저장
    final shouldAutoSave =
        !duplicateResult.isDuplicate && autoSaveModeStr == 'auto';

    if (duplicateResult.isDuplicate && kDebugMode) {
      debugPrint(
        'Duplicate notification detected - saving as pending for user review',
      );
    }

    PendingTransactionModel pendingTx;
    try {
      // 항상 pending 상태로 먼저 생성 (원자성 보장)
      // 거래 생성 성공 시에만 confirmed로 업데이트
      pendingTx = await _createPendingTransaction(
        packageName: packageName,
        content: content,
        timestamp: timestamp,
        paymentMethod: paymentMethod,
        parsedResult: parsedResult,
        categoryId: categoryId,
        duplicateHash: duplicateResult.duplicateHash,
        isDuplicate: duplicateResult.isDuplicate,
        shouldAutoSave: shouldAutoSave,
        isViewed: false,
        sourceType: sourceType,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[ProcessNotification] Failed to create pending transaction: $e',
        );
      }
      _onNotificationProcessedController.add(
        NotificationProcessedEvent(
          packageName: packageName,
          content: content,
          success: false,
          reason: 'db_error: $e',
        ),
      );
      return;
    }

    // 자동수집 알림 전송
    await _sendAutoCollectNotification(
      paymentMethod: paymentMethod,
      pendingTx: pendingTx,
      autoSaveMode: autoSaveModeStr,
    );

    _onNotificationProcessedController.add(
      NotificationProcessedEvent(
        packageName: packageName,
        content: content,
        success: true,
        autoSaveMode: autoSaveModeStr,
        parsedAmount: parsedResult.amount,
        parsedMerchant: parsedResult.merchant,
      ),
    );
  }

  Future<PendingTransactionModel> _createPendingTransaction({
    required String packageName,
    required String content,
    required DateTime timestamp,
    required PaymentMethodModel paymentMethod,
    required ParsedSmsResult parsedResult,
    required String? categoryId,
    required String duplicateHash,
    required bool isDuplicate,
    required bool shouldAutoSave,
    bool isViewed = false,
    String sourceType = 'notification',
  }) async {
    if (kDebugMode) {
      debugPrint('[CreatePending] Creating pending transaction:');
      debugPrint('  - ledgerId: $_currentLedgerId');
      debugPrint('  - paymentMethodId: ${paymentMethod.id}');
      debugPrint('  - shouldAutoSave: $shouldAutoSave');
      debugPrint('  - isDuplicate: $isDuplicate');
    }

    try {
      // 1. 항상 pending 상태로 먼저 생성 (원자성 보장)
      final sourceTypeEnum = sourceType == 'sms'
          ? SourceType.sms
          : SourceType.notification;
      final pendingTx = await _pendingTransactionRepository
          .createPendingTransaction(
            ledgerId: _currentLedgerId!,
            paymentMethodId: paymentMethod.id,
            userId: _currentUserId!,
            sourceType: sourceTypeEnum,
            sourceSender: packageName,
            sourceContent: content,
            sourceTimestamp: timestamp,
            parsedAmount: parsedResult.amount,
            parsedType: parsedResult.transactionType,
            parsedMerchant: parsedResult.merchant,
            parsedCategoryId: categoryId,
            parsedDate: parsedResult.date ?? timestamp,
            duplicateHash: duplicateHash,
            isDuplicate: isDuplicate,
            status: PendingTransactionStatus.pending,
            isViewed: isViewed,
          );

      if (kDebugMode) {
        debugPrint('[CreatePending] Success! ID: ${pendingTx.id}');
      }

      // 2. 자동 저장 모드일 때만 거래 생성 시도
      if (shouldAutoSave) {
        final amount = parsedResult.amount;
        final type = parsedResult.transactionType;

        // 금액과 타입이 있어야만 거래 생성 가능
        if (amount != null && type != null) {
          if (kDebugMode) {
            debugPrint('[AutoSave] Creating actual transaction...');
          }
          try {
            await _transactionRepository.createTransaction(
              ledgerId: _currentLedgerId!,
              categoryId: categoryId,
              paymentMethodId: paymentMethod.id,
              amount: amount,
              type: type,
              title: parsedResult.merchant ?? '',
              date: parsedResult.date ?? timestamp,
              sourceType: sourceTypeEnum.toJson(),
            );

            // 3. 거래 생성 성공 시에만 confirmed로 업데이트
            await _pendingTransactionRepository.updateStatus(
              id: pendingTx.id,
              status: PendingTransactionStatus.confirmed,
            );

            if (kDebugMode) {
              debugPrint(
                '[AutoSave] Transaction created and status updated to confirmed!',
              );
            }
          } catch (e) {
            // 거래 생성 실패 시 pending 상태 유지 (이미 pending이므로 추가 작업 불필요)
            if (kDebugMode) {
              debugPrint('[AutoSave] Failed to create transaction: $e');
              debugPrint(
                '[AutoSave] Keeping status as pending for manual review',
              );
            }
          }
        } else if (kDebugMode) {
          debugPrint('[AutoSave] Skipped auto-save - missing amount or type');
        }
      }

      return pendingTx;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[CreatePending] ERROR: $e');
        debugPrint('[CreatePending] StackTrace: $st');
      }
      // 토큰 만료 등으로 저장 실패 시 로컬 알림으로 사용자에게 알림
      if (e is AuthException) {
        try {
          await LocalNotificationService().showNotification(
            title: '자동수집 저장 실패',
            body: '인증이 만료되었습니다. 앱을 열어 다시 로그인해주세요.',
          );
        } catch (_) {
          // 알림 전송 실패는 무시
        }
      }
      rethrow;
    }
  }

  /// 오래된 메시지 캐시 정리
  void _cleanupMessageCache() {
    final now = DateTime.now();
    _recentlyProcessedMessages.removeWhere((key, timestamp) {
      return now.difference(timestamp) > _messageCacheDuration;
    });
  }

  /// 자동수집 알림 전송
  ///
  /// suggest 모드: '자동수집 거래 확인' 알림 (대기중 탭으로 딥링크)
  /// auto 모드: '자동수집 거래 저장' 알림 (확인됨 탭으로 딥링크)
  Future<void> _sendAutoCollectNotification({
    required PaymentMethodModel paymentMethod,
    required PendingTransactionModel pendingTx,
    required String autoSaveMode,
  }) async {
    if (_currentUserId == null) {
      if (kDebugMode) {
        debugPrint(
          '[Notification] currentUserId is null - skipping notification',
        );
      }
      return;
    }

    // manual 모드는 알림 전송하지 않음
    if (autoSaveMode == 'manual') {
      return;
    }

    try {
      final NotificationType notificationType;
      final String title;
      final String body;
      final String targetTab;

      if (autoSaveMode == 'suggest') {
        notificationType = NotificationType.autoCollectSuggested;
        title = '자동수집 거래 확인';
        body = '새로운 거래가 수집되었습니다. 확인해주세요.';
        targetTab = 'pending'; // 대기중 탭
      } else {
        // auto
        notificationType = NotificationType.autoCollectSaved;
        title = '자동수집 거래 저장';
        body = '새로운 거래가 자동으로 저장되었습니다.';
        targetTab = 'confirmed'; // 확인됨 탭
      }

      await _notificationService.sendAutoCollectNotification(
        userId: _currentUserId!,
        type: notificationType,
        title: title,
        body: body,
        data: {
          'type': notificationType.value,
          'pendingId': pendingTx.id,
          'targetTab': targetTab,
          'paymentMethodName': paymentMethod.name,
          'amount': pendingTx.parsedAmount?.toString() ?? '',
          'merchant': pendingTx.parsedMerchant ?? '',
        },
      );

      if (kDebugMode) {
        debugPrint('[Notification] Auto-collect notification sent:');
        debugPrint('  - type: $notificationType');
        debugPrint('  - pendingId: ${pendingTx.id}');
        debugPrint('  - targetTab: $targetTab');
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint(
          '[Notification] Failed to send auto-collect notification: $e',
        );
        debugPrint('[Notification] StackTrace: $st');
      }
      // 알림 전송 실패는 치명적 에러가 아니므로 rethrow 하지 않음
    }
  }

  void dispose() {
    stopListening();
    _paymentMethodsSubscription?.unsubscribe();
    _paymentMethodsSubscription = null;
    _onNotificationProcessedController.close();
    _isInitialized = false;
    _currentUserId = null;
    _currentLedgerId = null;
    _learnedFormatsCache.clear();
    _recentlyProcessedMessages.clear();
    _instance = null;
  }
}

class _PaymentMethodMatchResult {
  final PaymentMethodModel paymentMethod;
  final LearnedPushFormat? learnedFormat;

  const _PaymentMethodMatchResult({
    required this.paymentMethod,
    this.learnedFormat,
  });
}

class NotificationProcessedEvent {
  final String packageName;
  final String content;
  final bool success;
  final String? reason;
  final String? autoSaveMode;
  final int? parsedAmount;
  final String? parsedMerchant;

  const NotificationProcessedEvent({
    required this.packageName,
    required this.content,
    required this.success,
    this.reason,
    this.autoSaveMode,
    this.parsedAmount,
    this.parsedMerchant,
  });
}
