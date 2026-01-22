import 'dart:async';
import 'dart:io';

import 'package:another_telephony/telephony.dart';
import 'package:flutter/foundation.dart';

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

@pragma('vm:entry-point')
void backgroundSmsHandler(SmsMessage message) async {
  debugPrint('Background SMS received: ${message.address}');
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
  final LearnedSmsFormatRepository _learnedSmsFormatRepository =
      LearnedSmsFormatRepository();
  final CategoryMappingService _categoryMappingService =
      CategoryMappingService();
  final DuplicateCheckService _duplicateCheckService = DuplicateCheckService();

  List<PaymentMethodModel> _autoSavePaymentMethods = [];
  final Map<String, List<LearnedSmsFormatModel>> _learnedFormatsCache = {};

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
    if (!isAndroid || !_isInitialized || _isListening) return;

    _telephony.listenIncomingSms(
      onNewMessage: onSmsReceived,
      onBackgroundMessage: backgroundSmsHandler,
      listenInBackground: true,
    );

    _isListening = true;
    debugPrint('SMS listener started');
  }

  void stopListening() {
    _isListening = false;
    debugPrint('SMS listener stopped');
  }

  @visibleForTesting
  Future<void> onSmsReceived(SmsMessage message) async {
    if (_currentUserId == null || _currentLedgerId == null) return;

    final sender = message.address ?? '';
    final content = message.body ?? '';
    final timestamp = message.date != null
        ? DateTime.fromMillisecondsSinceEpoch(message.date!)
        : DateTime.now();

    if (sender.isEmpty || content.isEmpty) return;

    if (!FinancialSmsSenders.isFinancialSender(sender)) {
      return;
    }

    final matchResult = _findMatchingPaymentMethod(sender, content);
    if (matchResult == null) {
      debugPrint('No matching payment method found for sender: $sender');
      return;
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

    if (duplicateResult.isDuplicate) {
      debugPrint('Duplicate SMS detected');
      _onSmsProcessedController.add(
        SmsProcessedEvent(
          sender: sender,
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
      'SMS matched with mode: $autoSaveModeStr for ${paymentMethod.name}',
    );

    if (autoSaveModeStr == 'auto') {
      await _createPendingTransaction(
        sender: sender,
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
        sender: sender,
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
    required PendingTransactionStatus status,
    bool isViewed = false,
  }) async {
    try {
      await _pendingTransactionRepository.createPendingTransaction(
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
        status: status,
        isViewed: isViewed,
      );

      if (status == PendingTransactionStatus.confirmed) {
        debugPrint('Auto-saved transaction: ${parsedResult.amount}');
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
          .where((m) => FinancialSmsSenders.isFinancialSender(m.address ?? ''))
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

  void dispose() {
    stopListening();
    _onSmsProcessedController.close();
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
