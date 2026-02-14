import 'dart:async';
import 'dart:io';

import 'package:another_telephony/telephony.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../notification/data/services/notification_service.dart';
import '../../../notification/domain/entities/notification_type.dart';
import '../../../notification/services/local_notification_service.dart';
import '../../../transaction/data/repositories/transaction_repository.dart';
import '../../domain/entities/learned_sms_format.dart';
import '../../domain/entities/payment_method.dart';
import '../../domain/entities/pending_transaction.dart';
import '../models/learned_sms_format_model.dart';
import '../models/payment_method_model.dart';
import '../models/pending_transaction_model.dart';
import '../repositories/learned_sms_format_repository.dart';
import '../repositories/payment_method_repository.dart';
import '../repositories/pending_transaction_repository.dart';
import 'category_mapping_service.dart';
import 'duplicate_check_service.dart';
import 'sms_parsing_service.dart';

@pragma('vm:entry-point')
Future<void> backgroundSmsHandler(SmsMessage message) async {
  // 이 함수는 더 이상 호출되지 않습니다.
  // 백그라운드 SMS 수신은 Kotlin SmsBroadcastReceiver에서 처리합니다.
  debugPrint(
    '[BackgroundSMS] This handler is deprecated. Kotlin handles SMS now.',
  );
}

/// SMS 리스너 서비스
///
/// 실시간 SMS 수신은 Kotlin SmsBroadcastReceiver에서 처리합니다.
/// 이 서비스는 권한 관리와 과거 SMS 스캔 기능만 제공합니다.
///
/// - 권한 체크/요청: [checkPermissions], [requestPermissions]
/// - 과거 SMS 스캔: [getRecentSms], [processPastSms]
class SmsListenerService {
  SmsListenerService._();

  static SmsListenerService? _instance;
  static SmsListenerService get instance {
    _instance ??= SmsListenerService._();
    return _instance!;
  }

  final Telephony _telephony = Telephony.instance;

  bool _isInitialized = false;
  final bool _isListening = false;
  String? _currentUserId;
  String? _currentLedgerId;
  RealtimeChannel? _paymentMethodsSubscription;

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
  final NotificationService _notificationService = NotificationService();

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

  /// SMS 권한 상태 확인 (요청하지 않고 확인만)
  Future<bool> checkPermissions() async {
    if (!isAndroid) return false;

    try {
      final status = await Permission.sms.status;
      return status.isGranted;
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
    // 실시간 SMS 수신은 Kotlin SmsBroadcastReceiver에서 처리
    // Flutter에서는 더 이상 리스닝하지 않음
    if (kDebugMode) {
      debugPrint(
        '[SmsListener] SMS listening is now handled by Kotlin SmsBroadcastReceiver',
      );
    }
    // Note: _isListening을 true로 설정하지 않음 (실제로 리스닝하지 않으므로)
  }

  void stopListening() {
    // Kotlin SmsBroadcastReceiver가 처리하므로 no-op
    if (kDebugMode) {
      debugPrint(
        '[SmsListener] stopListening called (no-op, Kotlin handles SMS)',
      );
    }
  }

  @visibleForTesting
  Future<void> onSmsReceived(SmsMessage message) async {
    // 동시성 제어: 메시지 고유 ID 생성
    final messageId =
        '${message.address}_${message.date ?? DateTime.now().millisecondsSinceEpoch}';

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
    // [AutoCollect-SMS] STEP 1: SMS 수신
    if (kDebugMode) {
      debugPrint('========================================');
      debugPrint('[AutoCollect-SMS] STEP 1: SMS 수신');
      debugPrint('  - Sender: ${message.address}');
      debugPrint('  - Content length: ${message.body?.length ?? 0}');
      debugPrint('========================================');
    }

    // [AutoCollect-SMS] STEP 2: 초기화 상태 확인
    if (_currentUserId == null || _currentLedgerId == null) {
      if (kDebugMode) {
        debugPrint(
          '[AutoCollect-SMS] STEP 2: SKIP - userId or ledgerId is null',
        );
      }
      return;
    }
    if (kDebugMode) {
      debugPrint(
        '[AutoCollect-SMS] STEP 2: OK - userId=$_currentUserId, ledgerId=$_currentLedgerId',
      );
    }

    final sender = message.address ?? '';
    final content = message.body ?? '';
    final timestamp = message.date != null
        ? DateTime.fromMillisecondsSinceEpoch(message.date!)
        : DateTime.now();

    if (sender.isEmpty || content.isEmpty) {
      if (kDebugMode) {
        debugPrint(
          '[AutoCollect-SMS] STEP 2: SKIP - sender or content is empty',
        );
      }
      return;
    }

    // [AutoCollect-SMS] STEP 3: 금융 SMS 필터링
    if (!FinancialSmsSenders.isFinancialSender(sender, content)) {
      if (kDebugMode) {
        debugPrint('[AutoCollect-SMS] STEP 3: SKIP - not a financial SMS');
      }
      return;
    }
    if (kDebugMode) {
      debugPrint('[AutoCollect-SMS] STEP 3: OK - financial SMS detected');
    }

    // [AutoCollect-SMS] STEP 4: 결제수단 매칭
    final matchResult = _findMatchingPaymentMethod(sender, content);
    if (matchResult == null) {
      if (kDebugMode) {
        debugPrint(
          '[AutoCollect-SMS] STEP 4: FAIL - No matching payment method',
        );
        debugPrint('  - Sender: $sender');
        debugPrint(
          '  - SMS-source payment methods: ${_autoSavePaymentMethods.where((pm) => pm.autoCollectSource == AutoCollectSource.sms).length}',
        );
      }
      return;
    }
    if (kDebugMode) {
      debugPrint(
        '[AutoCollect-SMS] STEP 4: OK - matched ${matchResult.paymentMethod.name}',
      );
    }

    // STEP 5~8은 _processSms에서 처리
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
    // [AutoCollect-SMS] STEP 5: 중복 메시지 확인 (캐시)
    final messageHash = DuplicateCheckService.generateMessageHash(
      content,
      timestamp,
    );
    final cachedTime = _recentlyProcessedMessages[messageHash];
    if (cachedTime != null) {
      final timeDiff = DateTime.now().difference(cachedTime);
      if (timeDiff < _messageCacheDuration) {
        if (kDebugMode) {
          debugPrint(
            '[AutoCollect-SMS] STEP 5: SKIP - duplicate (cached ${timeDiff.inSeconds}s ago)',
          );
        }
        return;
      }
    }
    _recentlyProcessedMessages[messageHash] = DateTime.now();
    _cleanupMessageCache();
    if (kDebugMode) {
      debugPrint('[AutoCollect-SMS] STEP 5: OK - not a cached duplicate');
    }

    // [AutoCollect-SMS] STEP 6: SMS 파싱
    ParsedSmsResult parsedResult;
    if (learnedFormat != null) {
      parsedResult = SmsParsingService.parseSmsWithFormat(
        content,
        learnedFormat,
      );
      await _learnedSmsFormatRepository.incrementMatchCount(learnedFormat.id);
      if (kDebugMode) {
        debugPrint('[AutoCollect-SMS] STEP 6: Parsed with learned format');
      }
    } else {
      parsedResult = SmsParsingService.parseSms(sender, content);
      if (kDebugMode) {
        debugPrint('[AutoCollect-SMS] STEP 6: Parsed with default parser');
      }
    }

    if (!parsedResult.isParsed) {
      if (kDebugMode) {
        debugPrint('[AutoCollect-SMS] STEP 6: FAIL - parsing failed');
        debugPrint('  - Result: $parsedResult');
      }
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
    if (kDebugMode) {
      debugPrint('[AutoCollect-SMS] STEP 6: OK - parsed successfully');
      debugPrint(
        '  - Type: ${parsedResult.transactionType}, Merchant: ${parsedResult.merchant}',
      );
    }

    // [AutoCollect-SMS] STEP 7: 중복 거래 확인 (DB)
    final duplicateResult = await _duplicateCheckService.checkDuplicate(
      amount: parsedResult.amount!,
      paymentMethodId: paymentMethod.id,
      ledgerId: _currentLedgerId!,
      timestamp: timestamp,
    );
    if (kDebugMode) {
      debugPrint(
        '[AutoCollect-SMS] STEP 7: Duplicate check - isDuplicate=${duplicateResult.isDuplicate}',
      );
    }

    String? categoryId = paymentMethod.defaultCategoryId;
    if (categoryId == null && parsedResult.merchant != null) {
      categoryId = await _categoryMappingService.findCategoryId(
        parsedResult.merchant!,
        _currentLedgerId!,
      );
    }

    final cachedPaymentMethod = _autoSavePaymentMethods
        .where((pm) => pm.id == paymentMethod.id)
        .firstOrNull;
    final autoSaveModeStr =
        cachedPaymentMethod?.autoSaveMode.toJson() ??
        paymentMethod.autoSaveMode.toJson();
    final shouldAutoSave =
        !duplicateResult.isDuplicate && autoSaveModeStr == 'auto';
    if (kDebugMode) {
      debugPrint(
        '[AutoCollect-SMS] STEP 7: mode=$autoSaveModeStr, shouldAutoSave=$shouldAutoSave',
      );
    }

    // [AutoCollect-SMS] STEP 8: pending_transactions 저장
    if (kDebugMode) {
      debugPrint('[AutoCollect-SMS] STEP 8: Creating pending transaction...');
    }
    final pendingTx = await _createPendingTransaction(
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
    if (kDebugMode) {
      debugPrint('[AutoCollect-SMS] STEP 8: OK - pending transaction created');
    }

    // 자동수집 알림 전송
    await _sendAutoCollectNotification(
      paymentMethod: paymentMethod,
      pendingTx: pendingTx,
      autoSaveMode: autoSaveModeStr,
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

  Future<PendingTransactionModel> _createPendingTransaction({
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
      final pendingTx = await _pendingTransactionRepository
          .createPendingTransaction(
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
            debugPrint(
              '[AutoSave-SMS] Transaction created and status updated to confirmed!',
            );
          } catch (e) {
            // 거래 생성 실패 시 pending 상태 유지 (이미 pending이므로 추가 작업 불필요)
            debugPrint('[AutoSave-SMS] Failed to create transaction: $e');
            debugPrint(
              '[AutoSave-SMS] Keeping status as pending for manual review',
            );
          }
        } else {
          debugPrint(
            '[AutoSave-SMS] Skipped auto-save - missing amount or type',
          );
        }
      }

      return pendingTx;
    } catch (e) {
      debugPrint('Failed to create pending transaction: $e');
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
          .where(
            (m) =>
                FinancialSmsSenders.isFinancialSender(m.address ?? '', m.body),
          )
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
