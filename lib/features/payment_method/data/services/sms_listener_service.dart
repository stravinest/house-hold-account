import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:another_telephony/telephony.dart';
import 'package:crypto/crypto.dart';
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

    // 발신자 또는 본문에서 금융사 패턴 확인
    if (!FinancialSmsSenders.isFinancialSender(sender, content)) {
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
    final messageHash = _generateMessageHash(sender, content, timestamp);

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

    // 캐시된 값 대신 DB에서 최신 autoSaveMode 조회 (설정 변경 후 캐시 동기화 문제 방지)
    final freshPaymentMethod = await _paymentMethodRepository.getPaymentMethodById(paymentMethod.id);
    final autoSaveModeStr = freshPaymentMethod?.autoSaveMode.toJson() ?? paymentMethod.autoSaveMode.toJson();
    debugPrint(
      'SMS matched with mode: $autoSaveModeStr (fresh from DB) for ${paymentMethod.name}',
    );

    // 중복 감지 처리: 중복이더라도 pending으로 저장하여 사용자가 확인할 수 있게 함
    PendingTransactionStatus initialStatus;
    if (duplicateResult.isDuplicate) {
      debugPrint('Duplicate SMS detected - saving as pending for user review');
      initialStatus = PendingTransactionStatus.pending;
    } else if (autoSaveModeStr == 'auto') {
      initialStatus = PendingTransactionStatus.confirmed;
    } else {
      initialStatus = PendingTransactionStatus.pending;
    }

    await _createPendingTransaction(
      sender: sender,
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
    required PendingTransactionStatus status,
    bool isViewed = false,
  }) async {
    try {
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
        status: status,
        isViewed: isViewed,
      );

      // 자동 저장 모드일 때 실제 거래도 생성
      if (status == PendingTransactionStatus.confirmed) {
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

            debugPrint('[AutoSave-SMS] Transaction created successfully!');
          } catch (e) {
            debugPrint('[AutoSave-SMS] Failed to create transaction: $e');
            debugPrint('[AutoSave-SMS] Rolling back status to pending...');
            // 거래 생성 실패 시 status를 pending으로 롤백 (수동 확인 필요)
            try {
              await _pendingTransactionRepository.updateStatus(
                id: pendingTx.id,
                status: PendingTransactionStatus.pending,
              );
              debugPrint('[AutoSave-SMS] Status rolled back to pending');
            } catch (rollbackError) {
              debugPrint('[AutoSave-SMS] Failed to rollback status: $rollbackError');
            }
          }
        } else {
          debugPrint('[AutoSave-SMS] Skipped - missing amount or type');
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

  /// 메시지 내용으로 고유 해시 생성 (중복 수신 방지용)
  ///
  /// 금액 + 내용 일부 + 시간(분 단위)로 해시를 만들어
  /// SMS와 Push 알림이 동시에 와도 동일한 메시지임을 식별
  ///
  /// 주의: sender를 포함하지 않음 (SMS는 전화번호, Push는 패키지명으로 달라서
  /// 같은 결제 알림이 다른 해시가 되는 문제 방지)
  String _generateMessageHash(String sender, String content, DateTime timestamp) {
    final minuteBucket = timestamp.millisecondsSinceEpoch ~/ (60 * 1000);

    // 금액 추출 (SMS/Push 공통으로 금액이 포함됨)
    final amountMatch = RegExp(r'(\d{1,3}(?:,\d{3})*)\s*원').firstMatch(content);
    final amount = amountMatch?.group(1)?.replaceAll(',', '') ?? '';

    // 내용에서 핵심 부분만 추출 (sender 제외)
    final contentPreview = content.length > 80 ? content.substring(0, 80) : content;

    // 금액 + 내용 + 시간으로 해시 (sender 제외하여 SMS/Push 동일 해시)
    final input = '$amount-$contentPreview-$minuteBucket';

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
    _onSmsProcessedController.close();
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
