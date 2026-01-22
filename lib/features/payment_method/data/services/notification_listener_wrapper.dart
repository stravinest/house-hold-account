import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:notification_listener_service/notification_event.dart';
import 'package:notification_listener_service/notification_listener_service.dart';

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
  final LearnedSmsFormatRepository _learnedSmsFormatRepository =
      LearnedSmsFormatRepository();
  final CategoryMappingService _categoryMappingService =
      CategoryMappingService();
  final DuplicateCheckService _duplicateCheckService = DuplicateCheckService();

  List<PaymentMethodModel> _autoSavePaymentMethods = [];
  final Map<String, List<LearnedSmsFormatModel>> _learnedFormatsCache = {};

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
    'com.android.shell', // For ADB testing
  };

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
    if (_currentUserId == null || _currentLedgerId == null) return;
    if (event.hasRemoved == true) return;

    final packageName = event.packageName ?? '';
    final title = event.title ?? '';
    final content = event.content ?? '';
    final timestamp = DateTime.now();

    if (packageName.isEmpty || content.isEmpty) return;

    if (!_isFinancialApp(packageName)) {
      debugPrint('Skipping non-financial notification: $packageName');
      return;
    }

    debugPrint('Processing financial notification: $packageName');
    final combinedContent = '$title $content';

    final matchResult = _findMatchingPaymentMethod(
      packageName,
      combinedContent,
    );
    if (matchResult == null) {
      debugPrint(
        'No matching payment method found for package: $packageName, content: $combinedContent',
      );
      return;
    }

    debugPrint(
      'Found match for notification: ${matchResult.paymentMethod.name}',
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
    return _financialAppPackagesLower.any((pkg) => packageLower.contains(pkg));
  }

  _PaymentMethodMatchResult? _findMatchingPaymentMethod(
    String packageName,
    String content,
  ) {
    final packageLower = packageName.toLowerCase();
    final contentLower = content.toLowerCase();

    for (final pm in _autoSavePaymentMethods) {
      final formats = _learnedFormatsCache[pm.id];

      // 1. 학습된 포맷으로 먼저 매칭 시도
      if (formats != null && formats.isNotEmpty) {
        for (final format in formats) {
          final senderPattern = format.senderPattern.toLowerCase();

          if (packageLower.contains(senderPattern) ||
              contentLower.contains(senderPattern)) {
            return _PaymentMethodMatchResult(
              paymentMethod: pm,
              learnedFormat: format.toEntity(),
            );
          }

          for (final keyword in format.senderKeywords) {
            if (packageLower.contains(keyword.toLowerCase()) ||
                contentLower.contains(keyword.toLowerCase())) {
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
      if (pmName.length >= 2 && contentLower.contains(pmName)) {
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
      debugPrint(
        'Notification parsing failed for: $content. Result: $parsedResult',
      );
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

    if (duplicateResult.isDuplicate) {
      debugPrint('Duplicate notification detected');
      _onNotificationProcessedController.add(
        NotificationProcessedEvent(
          packageName: packageName,
          content: content,
          success: false,
          reason: 'duplicate',
        ),
      );
      return;
    }

    String? categoryId = paymentMethod.defaultCategoryId;
    if (categoryId == null && parsedResult.merchant != null) {
      categoryId = await _categoryMappingService.findCategoryId(
        parsedResult.merchant!,
        _currentLedgerId!,
      );
    }

    final autoSaveModeStr = paymentMethod.autoSaveMode.toJson();
    debugPrint(
      'Notification matched with mode: $autoSaveModeStr for ${paymentMethod.name}',
    );

    if (autoSaveModeStr == 'auto') {
      await _createPendingTransaction(
        packageName: packageName,
        content: content,
        timestamp: timestamp,
        paymentMethod: paymentMethod,
        parsedResult: parsedResult,
        categoryId: categoryId,
        duplicateHash: duplicateResult.duplicateHash,
        status: PendingTransactionStatus.confirmed,
        isViewed: false,
      );
    } else {
      await _createPendingTransaction(
        packageName: packageName,
        content: content,
        timestamp: timestamp,
        paymentMethod: paymentMethod,
        parsedResult: parsedResult,
        categoryId: categoryId,
        duplicateHash: duplicateResult.duplicateHash,
        status: PendingTransactionStatus.pending,
        isViewed: false,
      );
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
    required PendingTransactionStatus status,
    bool isViewed = false,
  }) async {
    try {
      await _pendingTransactionRepository.createPendingTransaction(
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
        status: status,
        isViewed: isViewed,
      );

      if (status == PendingTransactionStatus.confirmed) {
        debugPrint(
          'Auto-saved transaction from notification: ${parsedResult.amount}',
        );
      }
    } catch (e) {
      debugPrint('Failed to create pending transaction from notification: $e');
      rethrow;
    }
  }

  void dispose() {
    stopListening();
    _onNotificationProcessedController.close();
    _isInitialized = false;
    _currentUserId = null;
    _currentLedgerId = null;
    _learnedFormatsCache.clear();
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
