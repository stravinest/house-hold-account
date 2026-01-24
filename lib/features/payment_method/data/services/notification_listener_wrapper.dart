import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:notification_listener_service/notification_event.dart';
import 'package:notification_listener_service/notification_listener_service.dart';

import '../../../transaction/data/repositories/transaction_repository.dart';
import '../../domain/entities/learned_sms_format.dart';
import '../../domain/entities/pending_transaction.dart';
import '../models/learned_sms_format_model.dart';
import '../models/payment_method_model.dart';
import '../repositories/learned_sms_format_repository.dart';
import '../repositories/payment_method_repository.dart';
import '../repositories/pending_transaction_repository.dart';
import 'category_mapping_service.dart';
import 'duplicate_check_service.dart';
import 'sms_parsing_service.dart';

class NotificationListenerWrapper {
  NotificationListenerWrapper._();

  static NotificationListenerWrapper? _instance;
  static NotificationListenerWrapper get instance {
    _instance ??= NotificationListenerWrapper._();
    return _instance!;
  }

  bool _isInitialized = false;
  bool _isListening = false;
  String? _currentUserId;
  String? _currentLedgerId;
  StreamSubscription<ServiceNotificationEvent>? _subscription;

  final PaymentMethodRepository _paymentMethodRepository =
      PaymentMethodRepository();
  final PendingTransactionRepository _pendingTransactionRepository =
      PendingTransactionRepository();
  final TransactionRepository _transactionRepository =
      TransactionRepository();
  final LearnedSmsFormatRepository _learnedSmsFormatRepository =
      LearnedSmsFormatRepository();
  final CategoryMappingService _categoryMappingService =
      CategoryMappingService();
  final DuplicateCheckService _duplicateCheckService = DuplicateCheckService();

  List<PaymentMethodModel> _autoSavePaymentMethods = [];
  final Map<String, List<LearnedSmsFormatModel>> _learnedFormatsCache = {};

  // SMS/Push 중복 수신 방지 캐시 (메시지 해시 → 타임스탬프)
  final Map<String, DateTime> _recentlyProcessedMessages = {};
  static const Duration _messageCacheDuration = Duration(seconds: 10);

  // 소문자로 사전 변환하여 비교 최적화
  static final Set<String> _financialAppPackagesLower = {
    'com.kbcard.cxh.appcard',
    'com.kbstar.kbbank',
    'com.shinhan.sbanking',
    'com.shinhancard.smartshinhan',
    'com.samsung.android.spay',
    'com.samsungcard.app',
    'com.hyundaicard.appcard',
    'com.lottecard.app',
    'com.wooricard.smartapp',
    'com.hanacard.app',
    'nh.smart.nhallone',
    'nh.smart.banking',
    'com.ibk.neobanking',
    'com.kakaobank.channel',
    'viva.republica.toss',
    'com.kbank.kbankapp',
    'com.nhn.android.search',
    'com.naver.pay.app',
    'com.kakaopay.app',
  };

  // 테스트용 패키지 (디버그 모드에서만 사용)
  static const String _testPackage = 'com.android.shell';

  // SMS 앱 패키지 - NotificationListener에서 제외 (SmsListenerService가 처리)
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
  static const String _ownAppPackage = 'com.household.shared.shared_household_account';

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
      return await NotificationListenerService.requestPermission();
    } catch (e) {
      debugPrint('Notification permission request failed: $e');
      return false;
    }
  }

  Future<void> openSettings() async {
    if (!isAndroid) return;

    try {
      await NotificationListenerService.requestPermission();
    } catch (e) {
      debugPrint('Failed to open notification settings: $e');
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
    _isInitialized = true;
  }

  Future<void> _loadAutoSavePaymentMethods() async {
    if (_currentLedgerId == null) return;

    try {
      _autoSavePaymentMethods = await _paymentMethodRepository
          .getAutoSaveEnabledPaymentMethods(_currentLedgerId!);
    } catch (e) {
      debugPrint('Failed to load auto-save payment methods: $e');
      _autoSavePaymentMethods = [];
    }
  }

  Future<void> _loadLearnedFormats() async {
    _learnedFormatsCache.clear();

    for (final pm in _autoSavePaymentMethods) {
      try {
        final formats = await _learnedSmsFormatRepository.getByPaymentMethodId(
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
    if (kDebugMode) {
      debugPrint('[NotificationListener] Received notification:');
      debugPrint('  - packageName: ${event.packageName}');
      debugPrint('  - title: ${event.title}');
      // content는 금액/가맹점 정보 포함 - 일부만 출력
      final contentPreview = (event.content ?? '').length > 30
          ? '${event.content!.substring(0, 30)}...'
          : event.content;
      debugPrint('  - content preview: $contentPreview');
      debugPrint('  - hasRemoved: ${event.hasRemoved}');
    }

    if (_currentUserId == null || _currentLedgerId == null) {
      if (kDebugMode) {
        debugPrint('[NotificationListener] Skipping: userId or ledgerId is null');
      }
      return;
    }
    // hasRemoved 체크 - 디버그 모드의 테스트 알림은 예외 처리
    final packageName = event.packageName ?? '';
    final isTestNotification = kDebugMode && packageName.toLowerCase().contains(_testPackage);
    if (event.hasRemoved == true && !isTestNotification) {
      if (kDebugMode) {
        debugPrint('[NotificationListener] Skipping: notification removed');
      }
      return;
    }
    if (isTestNotification && kDebugMode) {
      debugPrint('[NotificationListener] Processing test notification (ignoring hasRemoved)');
    }

    final title = event.title ?? '';
    final content = event.content ?? '';
    final timestamp = DateTime.now();

    if (packageName.isEmpty || content.isEmpty) {
      if (kDebugMode) {
        debugPrint('[NotificationListener] Skipping: packageName or content is empty');
      }
      return;
    }

    // SMS 앱 알림 제외 - SmsListenerService가 SMS를 직접 처리함 (중복 방지)
    final packageLower = packageName.toLowerCase();
    if (_smsAppPackages.any((pkg) => packageLower.contains(pkg))) {
      if (kDebugMode) {
        debugPrint('[NotificationListener] Skipping SMS app notification: $packageName');
      }
      return;
    }

    // 자기 앱 알림 제외 - 순환 푸시 알림 방지
    // 공유 가계부에서 다른 사용자가 거래 등록 시 받는 FCM 푸시가
    // 자동수집에서 감지되어 중복 거래가 생성되는 것을 방지
    if (packageLower.contains(_ownAppPackage)) {
      if (kDebugMode) {
        debugPrint('[NotificationListener] Skipping own app notification: $packageName');
      }
      return;
    }

    final combinedContent = '$title $content';

    // 패키지명 또는 내용에서 금융 관련 여부 확인
    final isFinancial = _isFinancialApp(packageName);
    final isFinancialSender = FinancialSmsSenders.isFinancialSender(title, content);
    if (kDebugMode) {
      debugPrint('[NotificationListener] isFinancialApp: $isFinancial, isFinancialSender: $isFinancialSender');
    }

    if (!isFinancial && !isFinancialSender) {
      if (kDebugMode) {
        debugPrint('[NotificationListener] Skipping non-financial: $packageName');
      }
      return;
    }

    if (kDebugMode) {
      debugPrint('[NotificationListener] Processing: $packageName');
      debugPrint('[NotificationListener] Auto-save PM count: ${_autoSavePaymentMethods.length}');
      for (final pm in _autoSavePaymentMethods) {
        debugPrint('  - ${pm.name} (mode: ${pm.autoSaveMode.toJson()})');
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

    await _processNotification(
      packageName: packageName,
      content: combinedContent,
      timestamp: timestamp,
      paymentMethod: matchResult.paymentMethod,
      learnedFormat: matchResult.learnedFormat,
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

  bool _isFinancialApp(String packageName) {
    final packageLower = packageName.toLowerCase();

    // 디버그 모드에서만 테스트 패키지(com.android.shell) 허용
    if (kDebugMode && packageLower.contains(_testPackage)) {
      return true;
    }

    return _financialAppPackagesLower.any((pkg) => packageLower.contains(pkg));
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
      final formats = _learnedFormatsCache[pm.id];
      if (kDebugMode) {
        debugPrint('[Matching] Checking PM: ${pm.name}, formats: ${formats?.length ?? 0}');
      }

      // 1. 학습된 포맷으로 먼저 매칭 시도
      if (formats != null && formats.isNotEmpty) {
        for (final format in formats) {
          final senderPattern = format.senderPattern.toLowerCase();
          if (kDebugMode) {
            debugPrint('[Matching] Checking format pattern: $senderPattern');
          }

          if (packageLower.contains(senderPattern) ||
              contentLower.contains(senderPattern)) {
            if (kDebugMode) {
              debugPrint('[Matching] Matched by senderPattern!');
            }
            return _PaymentMethodMatchResult(
              paymentMethod: pm,
              learnedFormat: format.toEntity(),
            );
          }

          for (final keyword in format.senderKeywords) {
            if (packageLower.contains(keyword.toLowerCase()) ||
                contentLower.contains(keyword.toLowerCase())) {
              if (kDebugMode) {
                debugPrint('[Matching] Matched by keyword: $keyword');
              }
              return _PaymentMethodMatchResult(
                paymentMethod: pm,
                learnedFormat: format.toEntity(),
              );
            }
          }
        }
      }

      // 2. Fallback: 결제수단 이름이 내용에 포함되어 있는지 확인 (이름이 2자 이상인 경우만)
      final pmName = pm.name.toLowerCase();
      final nameMatches = pmName.length >= 2 && contentLower.contains(pmName);
      if (kDebugMode) {
        debugPrint('[Matching] Fallback: pmName="$pmName", matches=$nameMatches');
      }
      if (nameMatches) {
        if (kDebugMode) {
          debugPrint('[Matching] Matched by payment method name!');
        }
        return _PaymentMethodMatchResult(paymentMethod: pm);
      }
    }
    return null;
  }

  Future<void> _processNotification({
    required String packageName,
    required String content,
    required DateTime timestamp,
    required PaymentMethodModel paymentMethod,
    LearnedSmsFormat? learnedFormat,
  }) async {
    // 메시지 내용으로 해시 생성 (중복 수신 방지)
    final messageHash = _generateMessageHash(packageName, content, timestamp);

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

      await _learnedSmsFormatRepository.incrementMatchCount(learnedFormat.id);
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
    if (categoryId == null && parsedResult.merchant != null) {
      categoryId = await _categoryMappingService.findCategoryId(
        parsedResult.merchant!,
        _currentLedgerId!,
      );
    }

    final autoSaveModeStr = paymentMethod.autoSaveMode.toJson();
    if (kDebugMode) {
      debugPrint('Notification matched: mode=$autoSaveModeStr, pm=${paymentMethod.name}');
    }

    // 중복 감지 처리: 중복이더라도 pending으로 저장하여 사용자가 확인할 수 있게 함
    PendingTransactionStatus initialStatus;
    if (duplicateResult.isDuplicate) {
      if (kDebugMode) {
        debugPrint('Duplicate notification detected - saving as pending for user review');
      }
      initialStatus = PendingTransactionStatus.pending;
    } else if (autoSaveModeStr == 'auto') {
      initialStatus = PendingTransactionStatus.confirmed;
    } else {
      initialStatus = PendingTransactionStatus.pending;
    }

    try {
      await _createPendingTransaction(
        packageName: packageName,
        content: content,
        timestamp: timestamp,
        paymentMethod: paymentMethod,
        parsedResult: parsedResult,
        categoryId: categoryId,
        duplicateHash: duplicateResult.duplicateHash,
        isDuplicate: duplicateResult.isDuplicate,
        status: initialStatus,
        isViewed: false,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ProcessNotification] Failed to create pending transaction: $e');
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

  Future<void> _createPendingTransaction({
    required String packageName,
    required String content,
    required DateTime timestamp,
    required PaymentMethodModel paymentMethod,
    required ParsedSmsResult parsedResult,
    required String? categoryId,
    required String duplicateHash,
    required bool isDuplicate,
    required PendingTransactionStatus status,
    bool isViewed = false,
  }) async {
    if (kDebugMode) {
      debugPrint('[CreatePending] Creating pending transaction:');
      debugPrint('  - ledgerId: $_currentLedgerId');
      debugPrint('  - paymentMethodId: ${paymentMethod.id}');
      debugPrint('  - status: ${status.toJson()}');
      debugPrint('  - isDuplicate: $isDuplicate');
    }

    try {
      final pendingTx = await _pendingTransactionRepository.createPendingTransaction(
        ledgerId: _currentLedgerId!,
        paymentMethodId: paymentMethod.id,
        userId: _currentUserId!,
        sourceType: SourceType.notification,
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
        status: status,
        isViewed: isViewed,
      );

      if (kDebugMode) {
        debugPrint('[CreatePending] Success! ID: ${pendingTx.id}');
      }

      // 자동 저장 모드일 때 실제 거래도 생성
      if (status == PendingTransactionStatus.confirmed) {
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
              sourceType: SourceType.notification.toJson(),
            );

            if (kDebugMode) {
              debugPrint('[AutoSave] Transaction created successfully!');
            }
          } catch (e) {
            if (kDebugMode) {
              debugPrint('[AutoSave] Failed to create transaction: $e');
              debugPrint('[AutoSave] Rolling back status to pending...');
            }
            // 거래 생성 실패 시 status를 pending으로 롤백 (수동 확인 필요)
            try {
              await _pendingTransactionRepository.updateStatus(
                id: pendingTx.id,
                status: PendingTransactionStatus.pending,
              );
              if (kDebugMode) {
                debugPrint('[AutoSave] Status rolled back to pending');
              }
            } catch (rollbackError) {
              if (kDebugMode) {
                debugPrint('[AutoSave] Failed to rollback status: $rollbackError');
              }
            }
          }
        } else if (kDebugMode) {
          debugPrint('[AutoSave] Skipped - missing amount or type');
        }
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[CreatePending] ERROR: $e');
        debugPrint('[CreatePending] StackTrace: $st');
      }
      rethrow;
    }
  }

  /// 메시지 내용으로 고유 해시 생성 (중복 수신 방지용)
  ///
  /// 발신자 + 내용 일부 + 시간(분 단위)로 해시를 만들어
  /// SMS와 Push 알림이 동시에 와도 동일한 메시지임을 식별
  String _generateMessageHash(String sender, String content, DateTime timestamp) {
    final minuteBucket = timestamp.millisecondsSinceEpoch ~/ (60 * 1000);
    final contentPreview = content.length > 100 ? content.substring(0, 100) : content;
    final input = '$sender-$contentPreview-$minuteBucket';

    // md5 해시 (결정적 해시, duplicate_check_service와 동일한 방식)
    final bytes = utf8.encode(input);
    return md5.convert(bytes).toString();
  }

  /// 오래된 메시지 캐시 정리
  void _cleanupMessageCache() {
    final now = DateTime.now();
    _recentlyProcessedMessages.removeWhere((key, timestamp) {
      return now.difference(timestamp) > _messageCacheDuration;
    });
  }

  void dispose() {
    stopListening();
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
  final LearnedSmsFormat? learnedFormat;

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
