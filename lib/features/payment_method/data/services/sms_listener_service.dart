import 'dart:async';
import 'dart:io';

import 'package:another_telephony/telephony.dart';
import 'package:flutter/foundation.dart';

import '../../../transaction/data/repositories/transaction_repository.dart';
import '../../domain/entities/learned_sms_format.dart';
import '../../domain/entities/payment_method.dart';
import '../../domain/entities/pending_transaction.dart';
import '../models/learned_sms_format_model.dart';
import '../models/payment_method_model.dart';
import '../repositories/learned_sms_format_repository.dart';
import '../repositories/payment_method_repository.dart';
import '../repositories/pending_transaction_repository.dart';
import 'category_mapping_service.dart';
import 'duplicate_check_service.dart';
import 'sms_parsing_service.dart';

@pragma('vm:entry-point')
Future<void> backgroundSmsHandler(SmsMessage message) async {
  debugPrint('[BackgroundSMS] SMS received from: ${message.address}');

  // Singleton instance를 통해 처리 시도
  try {
    if (SmsListenerService._instance != null &&
        SmsListenerService.instance.isInitialized) {
      await SmsListenerService.instance.onSmsReceived(message);
      debugPrint('[BackgroundSMS] Processed via instance');
    } else {
      debugPrint('[BackgroundSMS] Instance not initialized, SMS will be processed when app reopens');
    }
  } catch (e) {
    debugPrint('[BackgroundSMS] Error processing SMS: $e');
  }
}

class SmsListenerService {
  SmsListenerService._();

  static SmsListenerService? _instance;
  static SmsListenerService get instance {
    _instance ??= SmsListenerService._();
    return _instance!;
  }

  final Telephony _telephony = Telephony.instance;

  bool _isInitialized = false;
  bool _isListening = false;
  String? _currentUserId;
  String? _currentLedgerId;

  final PaymentMethodRepository _paymentMethodRepository =
      PaymentMethodRepository();
  final PendingTransactionRepository _pendingTransactionRepository =
      PendingTransactionRepository();
  final TransactionRepository _transactionRepository = TransactionRepository();
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

  // 동시성 제어: 현재 처리 중인 SMS 추적
  final Set<String> _processingMessages = {};

  final _onSmsProcessedController =
      StreamController<SmsProcessedEvent>.broadcast();
  Stream<SmsProcessedEvent> get onSmsProcessed =>
      _onSmsProcessedController.stream;

  bool get isAndroid => Platform.isAndroid;
  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;

  Future<bool> requestPermissions() async {
    if (!isAndroid) return false;

    try {
      final granted = await _telephony.requestPhoneAndSmsPermissions;
      return granted ?? false;
    } catch (e) {
      debugPrint('SMS permission request failed: $e');
      return false;
    }
  }

  Future<bool> checkPermissions() async {
    if (!isAndroid) return false;

    try {
      final smsPermission = await _telephony.requestSmsPermissions;
      return smsPermission ?? false;
    } catch (e) {
      debugPrint('SMS permission check failed: $e');
      return false;
    }
  }

  Future<void> initialize({
    required String userId,
    required String ledgerId,
  }) async {
    if (!isAndroid) {
      debugPrint('SMS listener is only available on Android');
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
    if (kDebugMode) {
      debugPrint('[SmsListener] startListening called: isAndroid=$isAndroid, isInitialized=$_isInitialized, isListening=$_isListening');
    }

    if (!isAndroid || !_isInitialized || _isListening) {
      if (kDebugMode) {
        debugPrint('[SmsListener] Cannot start listening: isAndroid=$isAndroid, isInitialized=$_isInitialized, isListening=$_isListening');
      }
      return;
    }

    _telephony.listenIncomingSms(
      onNewMessage: onSmsReceived,
      onBackgroundMessage: backgroundSmsHandler,
      listenInBackground: true,
    );

    _isListening = true;
    if (kDebugMode) {
      debugPrint('[SmsListener] SMS listener started successfully');
      debugPrint('[SmsListener] Listening for SMS with ${_autoSavePaymentMethods.length} payment methods');
      for (final pm in _autoSavePaymentMethods) {
        if (pm.autoCollectSource == AutoCollectSource.sms) {
          debugPrint('  - ${pm.name} (mode: ${pm.autoSaveMode.toJson()})');
        }
      }
    }
  }

  void stopListening() {
    _isListening = false;
    debugPrint('SMS listener stopped');
  }

  @visibleForTesting
  Future<void> onSmsReceived(SmsMessage message) async {
    // 동시성 제어: 메시지 고유 ID 생성
    final messageId = '${message.address}_${message.date ?? DateTime.now().millisecondsSinceEpoch}';

    // 이미 처리 중인 SMS면 스킵
    if (_processingMessages.contains(messageId)) {
      if (kDebugMode) {
        debugPrint('[SmsListener] Already processing: $messageId');
      }
      return;
    }

    _processingMessages.add(messageId);
    try {
      await _processSmsMessage(message);
    } finally {
      _processingMessages.remove(messageId);
    }
  }

  Future<void> _processSmsMessage(SmsMessage message) async {
    if (kDebugMode) {
      debugPrint('========================================');
      debugPrint('[SmsListener] SMS received');
      debugPrint('  - Sender: ${message.address}');
      debugPrint('  - Content length: ${message.body?.length ?? 0}');
      debugPrint('========================================');
    }

    if (_currentUserId == null || _currentLedgerId == null) {
      if (kDebugMode) {
        debugPrint('[SmsListener] Skipping: userId or ledgerId is null');
      }
      return;
    }

    final sender = message.address ?? '';
    final content = message.body ?? '';
    final timestamp = message.date != null
        ? DateTime.fromMillisecondsSinceEpoch(message.date!)
        : DateTime.now();

    if (sender.isEmpty || content.isEmpty) {
      if (kDebugMode) {
        debugPrint('[SmsListener] Skipping: sender or content is empty');
      }
      return;
    }

    // 발신자 또는 본문에서 금융사 패턴 확인
    if (!FinancialSmsSenders.isFinancialSender(sender, content)) {
      if (kDebugMode) {
        debugPrint('[SmsListener] Skipping: not a financial SMS');
      }
      return;
    }

    final matchResult = _findMatchingPaymentMethod(sender, content);
    if (matchResult == null) {
      if (kDebugMode) {
        debugPrint('[SmsListener] ❌ No matching payment method found');
        debugPrint('[SmsListener] Sender: $sender');
        debugPrint('[SmsListener] Available SMS-source payment methods: ${_autoSavePaymentMethods.where((pm) => pm.autoCollectSource == AutoCollectSource.sms).length}');
      }
      return;
    }

    if (kDebugMode) {
      debugPrint('[SmsListener] ✅ Found match: ${matchResult.paymentMethod.name}');
    }

    await _processSms(
      sender: sender,
      content: content,
      timestamp: timestamp,
      paymentMethod: matchResult.paymentMethod,
      learnedFormat: matchResult.learnedFormat,
    );
  }

  @visibleForTesting
  Future<void> processManualSms({
    required String sender,
    required String content,
  }) async {
    if (_currentUserId == null || _currentLedgerId == null) return;

    final matchResult = _findMatchingPaymentMethod(sender, content);
    if (matchResult == null) {
      debugPrint(
        'Manual SMS: No matching payment method found for sender: $sender',
      );
      return;
    }

    await _processSms(
      sender: sender,
      content: content,
      timestamp: DateTime.now(),
      paymentMethod: matchResult.paymentMethod,
      learnedFormat: matchResult.learnedFormat,
    );
  }

  _PaymentMethodMatchResult? _findMatchingPaymentMethod(
    String sender,
    String content,
  ) {
    final senderLower = sender.toLowerCase();
    final contentLower = content.toLowerCase();

    for (final pm in _autoSavePaymentMethods) {
      // SMS 소스로 설정된 결제수단만 매칭 (Push로 설정된 결제수단은 무시)
      if (pm.autoCollectSource != AutoCollectSource.sms) {
        continue;
      }

      final formats = _learnedFormatsCache[pm.id];

      // 1. 학습된 포맷으로 먼저 매칭 시도
      if (formats != null && formats.isNotEmpty) {
        for (final format in formats) {
          final senderPattern = format.senderPattern.toLowerCase();

          if (senderLower.contains(senderPattern) ||
              contentLower.contains(senderPattern)) {
            return _PaymentMethodMatchResult(
              paymentMethod: pm,
              learnedFormat: format.toEntity(),
            );
          }

          for (final keyword in format.senderKeywords) {
            if (senderLower.contains(keyword.toLowerCase()) ||
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

  Future<void> _processSms({
    required String sender,
    required String content,
    required DateTime timestamp,
    required PaymentMethodModel paymentMethod,
    LearnedSmsFormat? learnedFormat,
  }) async {
    // 메시지 내용으로 해시 생성 (중복 수신 방지)
    final messageHash = DuplicateCheckService.generateMessageHash(content, timestamp);

    // 최근 10초 이내에 동일한 메시지를 처리했는지 확인
    final cachedTime = _recentlyProcessedMessages[messageHash];
    if (cachedTime != null) {
      final timeDiff = DateTime.now().difference(cachedTime);
      if (timeDiff < _messageCacheDuration) {
        debugPrint(
          'Duplicate message detected (cached ${timeDiff.inSeconds}s ago) - ignoring',
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
      parsedResult = SmsParsingService.parseSms(sender, content);
    }

    if (!parsedResult.isParsed) {
      debugPrint('SMS parsing failed for: $content');
      _onSmsProcessedController.add(
        SmsProcessedEvent(
          sender: sender,
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

    // 캐시에서 최신 autoSaveMode 확인 (refreshPaymentMethods 호출 시 캐시가 갱신됨)
    // 설정 페이지에서 저장 시 AutoSaveService.refreshPaymentMethods()가 호출되어 캐시 동기화됨
    final cachedPaymentMethod = _autoSavePaymentMethods
        .where((pm) => pm.id == paymentMethod.id)
        .firstOrNull;
    final autoSaveModeStr = cachedPaymentMethod?.autoSaveMode.toJson() ?? paymentMethod.autoSaveMode.toJson();
    debugPrint(
      'SMS matched with mode: $autoSaveModeStr (from cache) for ${paymentMethod.name}',
    );

    // 자동 저장 여부 결정: 중복이 아니고 auto 모드일 때만 자동 저장
    final shouldAutoSave = !duplicateResult.isDuplicate && autoSaveModeStr == 'auto';

    if (duplicateResult.isDuplicate) {
      debugPrint('Duplicate SMS detected - saving as pending for user review');
    }

    // 항상 pending 상태로 먼저 생성 (원자성 보장)
    // 거래 생성 성공 시에만 confirmed로 업데이트
    await _createPendingTransaction(
      sender: sender,
      content: content,
      timestamp: timestamp,
      paymentMethod: paymentMethod,
      parsedResult: parsedResult,
      categoryId: categoryId,
      duplicateHash: duplicateResult.duplicateHash,
      isDuplicate: duplicateResult.isDuplicate,
      shouldAutoSave: shouldAutoSave,
      isViewed: false,
    );

    _onSmsProcessedController.add(
      SmsProcessedEvent(
        sender: sender,
        content: content,
        success: true,
        autoSaveMode: autoSaveModeStr,
        parsedAmount: parsedResult.amount,
        parsedMerchant: parsedResult.merchant,
      ),
    );
  }

  Future<void> _createPendingTransaction({
    required String sender,
    required String content,
    required DateTime timestamp,
    required PaymentMethodModel paymentMethod,
    required ParsedSmsResult parsedResult,
    required String? categoryId,
    required String duplicateHash,
    required bool isDuplicate,
    required bool shouldAutoSave,
    bool isViewed = false,
  }) async {
    try {
      // 1. 항상 pending 상태로 먼저 생성 (원자성 보장)
      final pendingTx = await _pendingTransactionRepository.createPendingTransaction(
        ledgerId: _currentLedgerId!,
        paymentMethodId: paymentMethod.id,
        userId: _currentUserId!,
        sourceType: SourceType.sms,
        sourceSender: sender,
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

      // 2. 자동 저장 모드일 때만 거래 생성 시도
      if (shouldAutoSave) {
        final amount = parsedResult.amount;
        final type = parsedResult.transactionType;

        // 금액과 타입이 있어야만 거래 생성 가능
        if (amount != null && type != null) {
          debugPrint('[AutoSave-SMS] Creating actual transaction...');
          try {
            await _transactionRepository.createTransaction(
              ledgerId: _currentLedgerId!,
              categoryId: categoryId,
              paymentMethodId: paymentMethod.id,
              amount: amount,
              type: type,
              title: parsedResult.merchant ?? '',
              date: parsedResult.date ?? timestamp,
              sourceType: SourceType.sms.toJson(),
            );

            // 3. 거래 생성 성공 시에만 confirmed로 업데이트
            await _pendingTransactionRepository.updateStatus(
              id: pendingTx.id,
              status: PendingTransactionStatus.confirmed,
            );
            debugPrint('[AutoSave-SMS] Transaction created and status updated to confirmed!');
          } catch (e) {
            // 거래 생성 실패 시 pending 상태 유지 (이미 pending이므로 추가 작업 불필요)
            debugPrint('[AutoSave-SMS] Failed to create transaction: $e');
            debugPrint('[AutoSave-SMS] Keeping status as pending for manual review');
          }
        } else {
          debugPrint('[AutoSave-SMS] Skipped auto-save - missing amount or type');
        }
      }
    } catch (e) {
      debugPrint('Failed to create pending transaction: $e');
      rethrow;
    }
  }

  Future<List<SmsMessage>> getRecentSms({int count = 50}) async {
    if (!isAndroid) return [];

    try {
      final messages = await _telephony.getInboxSms(
        columns: [
          SmsColumn.ID,
          SmsColumn.ADDRESS,
          SmsColumn.BODY,
          SmsColumn.DATE,
          SmsColumn.READ,
        ],
        sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
      );

      return messages
          .where((m) => FinancialSmsSenders.isFinancialSender(
                m.address ?? '',
                m.body,
              ))
          .take(count)
          .toList();
    } catch (e) {
      debugPrint('Failed to get recent SMS: $e');
      return [];
    }
  }

  Future<void> processPastSms({int days = 7, int maxCount = 100}) async {
    if (!isAndroid || _currentUserId == null || _currentLedgerId == null) {
      return;
    }

    final messages = await getRecentSms(count: maxCount);
    final cutoffDate = DateTime.now().subtract(Duration(days: days));

    for (final message in messages) {
      if (message.date == null) continue;

      final messageDate = DateTime.fromMillisecondsSinceEpoch(message.date!);
      if (messageDate.isBefore(cutoffDate)) continue;

      final matchResult = _findMatchingPaymentMethod(
        message.address ?? '',
        message.body ?? '',
      );

      if (matchResult != null) {
        await _processSms(
          sender: message.address ?? '',
          content: message.body ?? '',
          timestamp: messageDate,
          paymentMethod: matchResult.paymentMethod,
          learnedFormat: matchResult.learnedFormat,
        );
      }
    }
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
    _onSmsProcessedController.close();
    _isInitialized = false;
    _currentUserId = null;
    _currentLedgerId = null;
    _learnedFormatsCache.clear();
    _recentlyProcessedMessages.clear();
    _processingMessages.clear();
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

class SmsProcessedEvent {
  final String sender;
  final String content;
  final bool success;
  final String? reason;
  final String? autoSaveMode;
  final int? parsedAmount;
  final String? parsedMerchant;

  const SmsProcessedEvent({
    required this.sender,
    required this.content,
    required this.success,
    this.reason,
    this.autoSaveMode,
    this.parsedAmount,
    this.parsedMerchant,
  });
}
