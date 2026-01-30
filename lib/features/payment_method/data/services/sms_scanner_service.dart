import 'package:another_telephony/telephony.dart' as telephony;
import 'package:flutter/foundation.dart';

import '../../domain/entities/learned_sms_format.dart';
import '../models/learned_sms_format_model.dart';
import '../repositories/learned_sms_format_repository.dart';
import 'financial_constants.dart';
import 'korean_financial_patterns.dart';
import 'sms_parsing_service.dart';
import 'sms_listener_service.dart';

/// 플랫폼 체크 추상화 (테스트 가능성)
abstract class PlatformChecker {
  bool get isAndroid;
  bool get isIOS;
}

/// 실제 플랫폼 체크 구현
class DefaultPlatformChecker implements PlatformChecker {
  const DefaultPlatformChecker();

  @override
  bool get isAndroid =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.android);

  @override
  bool get isIOS => !kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS);
}

/// SMS 메시지 데이터
class SmsMessageData {
  final String id;
  final String sender;
  final String body;
  final DateTime date;
  final bool isRead;

  const SmsMessageData({
    required this.id,
    required this.sender,
    required this.body,
    required this.date,
    this.isRead = false,
  });

  factory SmsMessageData.fromTelephony(telephony.SmsMessage msg) {
    return SmsMessageData(
      id: msg.id?.toString() ?? '',
      sender: msg.address ?? '',
      body: msg.body ?? '',
      date: msg.date != null
          ? DateTime.fromMillisecondsSinceEpoch(msg.date!)
          : DateTime.now(),
      isRead: msg.read ?? false,
    );
  }

  @override
  String toString() =>
      'SmsMessageData(sender: $sender, body: $body, date: $date)';
}

/// SMS 스캔 결과
class SmsFormatScanResult {
  final List<SmsMessageData> financialMessages;
  final Map<String, List<SmsMessageData>> groupedBySender;
  final List<FinancialSmsFormat> detectedFormats;

  const SmsFormatScanResult({
    required this.financialMessages,
    required this.groupedBySender,
    required this.detectedFormats,
  });

  bool get hasFinancialMessages => financialMessages.isNotEmpty;
  int get totalCount => financialMessages.length;
}

/// 포맷 학습 결과
class FormatLearningResult {
  final bool success;
  final LearnedSmsFormat? learnedFormat;
  final String? error;
  final double confidence;

  const FormatLearningResult({
    required this.success,
    this.learnedFormat,
    this.error,
    this.confidence = 0.0,
  });

  factory FormatLearningResult.success(
    LearnedSmsFormat format, {
    double confidence = 0.8,
  }) {
    return FormatLearningResult(
      success: true,
      learnedFormat: format,
      confidence: confidence,
    );
  }

  factory FormatLearningResult.failure(String error) {
    return FormatLearningResult(success: false, error: error);
  }
}

/// SMS 스캐너 서비스
///
/// 기기의 SMS를 스캔하여 금융 관련 메시지를 감지하고,
/// 사용자 선택에 따라 포맷을 학습합니다.
class SmsScannerService {
  final LearnedSmsFormatRepository _formatRepository;
  final PlatformChecker _platformChecker;

  SmsScannerService(this._formatRepository, {PlatformChecker? platformChecker})
    : _platformChecker = platformChecker ?? const DefaultPlatformChecker();

  /// 플랫폼 지원 여부 확인
  bool get isSupported => _platformChecker.isAndroid;

  /// SMS 접근 권한 확인 (Android)
  /// 실제 구현은 Phase 3에서 another_telephony 패키지 연동 시 구현
  Future<bool> checkSmsPermission() async {
    if (!isSupported) return false;
    // TODO: Phase 3에서 permission_handler로 구현
    return false;
  }

  /// SMS 접근 권한 요청 (Android)
  Future<bool> requestSmsPermission() async {
    if (!isSupported) return false;
    // TODO: Phase 3에서 permission_handler로 구현
    return false;
  }

  /// 기기 SMS 스캔 (금융 관련 메시지만 필터링)
  ///
  /// [days] - 최근 몇 일간의 SMS를 스캔할지 (기본 30일)
  /// [maxCount] - 최대 스캔 메시지 수 (기본 500개)
  Future<SmsFormatScanResult> scanFinancialSms({
    int days = 30,
    int maxCount = 500,
  }) async {
    if (!isSupported) {
      return const SmsFormatScanResult(
        financialMessages: [],
        groupedBySender: {},
        detectedFormats: [],
      );
    }

    // SmsListenerService를 통해 실제 SMS 읽기
    final messages = await SmsListenerService.instance.getRecentSms(
      count: maxCount,
    );
    final allMessages = messages
        .map((m) => SmsMessageData.fromTelephony(m))
        .toList();

    // 금융 관련 메시지 필터링
    final financialMessages = allMessages
        .where((msg) => _isFinancialSms(msg))
        .toList();

    // 발신자별 그룹화
    final groupedBySender = <String, List<SmsMessageData>>{};
    for (final msg in financialMessages) {
      final key = _normalizeSmsSender(msg.sender);
      groupedBySender.putIfAbsent(key, () => []).add(msg);
    }

    // 감지된 금융사 포맷
    final detectedFormats = <FinancialSmsFormat>[];
    for (final sender in groupedBySender.keys) {
      final format = KoreanFinancialPatterns.findBySender(sender);
      if (format != null && !detectedFormats.contains(format)) {
        detectedFormats.add(format);
      }
    }

    return SmsFormatScanResult(
      financialMessages: financialMessages,
      groupedBySender: groupedBySender,
      detectedFormats: detectedFormats,
    );
  }

  /// SMS가 금융 관련인지 확인
  bool _isFinancialSms(SmsMessageData msg) {
    // 발신자로 금융사 확인
    if (FinancialSmsSenders.isFinancialSender(msg.sender)) {
      return true;
    }

    // 내용에 금액 패턴이 있는지 확인
    if (KoreanFinancialSmsPatterns.amountPattern.hasMatch(msg.body)) {
      // 금융 키워드 포함 여부
      final hasExpenseKeyword = KoreanFinancialSmsPatterns.expenseKeywords.any(
        (k) => msg.body.contains(k),
      );
      final hasIncomeKeyword = KoreanFinancialSmsPatterns.incomeKeywords.any(
        (k) => msg.body.contains(k),
      );
      return hasExpenseKeyword || hasIncomeKeyword;
    }

    return false;
  }

  /// SMS 발신자 정규화 (번호/이름 통일)
  String _normalizeSmsSender(String sender) {
    // 전화번호 형식이면 그대로 반환
    if (RegExp(r'^[\d\-+]+$').hasMatch(sender)) {
      return sender.replaceAll(RegExp(r'[\-+]'), '');
    }
    return sender.toLowerCase().trim();
  }

  /// 샘플 SMS로 포맷 학습
  ///
  /// 사용자가 선택한 SMS를 분석하여 해당 금융사의 포맷을 학습합니다.
  Future<FormatLearningResult> learnFormatFromSms({
    required SmsMessageData sampleSms,
    required String paymentMethodId,
    String? selectedInstitution,
  }) async {
    // 1. 금융사 식별
    FinancialSmsFormat? baseFormat;
    if (selectedInstitution != null) {
      baseFormat = KoreanFinancialPatterns.findByName(selectedInstitution);
    }
    baseFormat ??= KoreanFinancialPatterns.findBySender(sampleSms.sender);

    if (baseFormat == null) {
      // 알 수 없는 금융사 - 범용 패턴 사용
      return _learnGenericFormat(sampleSms, paymentMethodId);
    }

    // 2. 기존 포맷으로 파싱 시도
    final parseResult = SmsParsingService.parseSms(
      sampleSms.sender,
      sampleSms.body,
    );

    if (!parseResult.isParsed) {
      return FormatLearningResult.failure('금액 또는 거래 유형을 파싱할 수 없습니다.');
    }

    // 3. 학습된 포맷 생성
    final now = DateTime.now();
    final learnedFormat = LearnedSmsFormat(
      id: '', // Repository에서 생성
      paymentMethodId: paymentMethodId,
      senderPattern: _normalizeSmsSender(sampleSms.sender),
      senderKeywords: baseFormat.senderPatterns,
      amountRegex: baseFormat.amountRegex,
      typeKeywords: baseFormat.typeKeywords,
      merchantRegex: baseFormat.merchantRegex,
      dateRegex: baseFormat.dateRegex,
      sampleSms: sampleSms.body,
      isSystem: false,
      confidence: parseResult.confidence,
      matchCount: 1,
      createdAt: now,
      updatedAt: now,
    );

    // 4. DB에 저장
    try {
      final savedFormat = await _formatRepository.create(
        LearnedSmsFormatModel.fromEntity(learnedFormat),
      );
      return FormatLearningResult.success(
        savedFormat.toEntity(),
        confidence: parseResult.confidence,
      );
    } catch (e, st) {
      debugPrint('SmsScannerService.learnFormatFromSms error: $e\n$st');
      return FormatLearningResult.failure('포맷 저장 실패: $e');
    }
  }

  /// 범용 포맷 학습 (알 수 없는 금융사)
  Future<FormatLearningResult> _learnGenericFormat(
    SmsMessageData sampleSms,
    String paymentMethodId,
  ) async {
    // 기본 파싱 시도
    final parseResult = SmsParsingService.parseSms(
      sampleSms.sender,
      sampleSms.body,
    );

    if (!parseResult.isParsed) {
      return FormatLearningResult.failure(
        '금액 또는 거래 유형을 파싱할 수 없습니다. '
        '지원하지 않는 SMS 형식일 수 있습니다.',
      );
    }

    final now = DateTime.now();
    final learnedFormat = LearnedSmsFormat(
      id: '',
      paymentMethodId: paymentMethodId,
      senderPattern: _normalizeSmsSender(sampleSms.sender),
      senderKeywords: [sampleSms.sender],
      amountRegex: r'([0-9,]+)\s*원',
      typeKeywords: FinancialConstants.defaultTypeKeywords,
      sampleSms: sampleSms.body,
      isSystem: false,
      confidence: parseResult.confidence * 0.8, // 범용 패턴은 신뢰도 낮춤
      matchCount: 1,
      createdAt: now,
      updatedAt: now,
    );

    try {
      final savedFormat = await _formatRepository.create(
        LearnedSmsFormatModel.fromEntity(learnedFormat),
      );
      return FormatLearningResult.success(
        savedFormat.toEntity(),
        confidence: parseResult.confidence * 0.8,
      );
    } catch (e, st) {
      debugPrint('SmsScannerService._learnGenericFormat error: $e\n$st');
      return FormatLearningResult.failure('포맷 저장 실패: $e');
    }
  }

  /// 결제수단에 연결된 학습 포맷 목록 조회
  Future<List<LearnedSmsFormat>> getLearnedFormats(
    String paymentMethodId,
  ) async {
    final models = await _formatRepository.getByPaymentMethodId(
      paymentMethodId,
    );
    return models.map((m) => m.toEntity()).toList();
  }

  /// 학습된 포맷 삭제
  Future<void> deleteLearnedFormat(String formatId) async {
    await _formatRepository.delete(formatId);
  }

  /// SMS 내용이 학습된 포맷과 매칭되는지 확인
  Future<LearnedSmsFormat?> findMatchingFormat(
    String sender,
    List<String> paymentMethodIds,
  ) async {
    for (final pmId in paymentMethodIds) {
      final formats = await getLearnedFormats(pmId);
      for (final format in formats) {
        if (format.matchesSender(sender)) {
          return format;
        }
      }
    }
    return null;
  }

  /// 시스템 기본 포맷을 학습 포맷으로 등록
  Future<FormatLearningResult> registerSystemFormat({
    required String paymentMethodId,
    required String institutionName,
  }) async {
    final systemFormat = KoreanFinancialPatterns.findByName(institutionName);
    if (systemFormat == null) {
      return FormatLearningResult.failure('지원하지 않는 금융사입니다: $institutionName');
    }

    final now = DateTime.now();
    final learnedFormat = LearnedSmsFormat(
      id: '',
      paymentMethodId: paymentMethodId,
      senderPattern: systemFormat.senderPatterns.first,
      senderKeywords: systemFormat.senderPatterns,
      amountRegex: systemFormat.amountRegex,
      typeKeywords: systemFormat.typeKeywords,
      merchantRegex: systemFormat.merchantRegex,
      dateRegex: systemFormat.dateRegex,
      sampleSms: systemFormat.sampleSms,
      isSystem: true,
      confidence: 0.95, // 시스템 포맷은 높은 신뢰도
      matchCount: 0,
      createdAt: now,
      updatedAt: now,
    );

    try {
      final savedFormat = await _formatRepository.create(
        LearnedSmsFormatModel.fromEntity(learnedFormat),
      );
      return FormatLearningResult.success(
        savedFormat.toEntity(),
        confidence: 0.95,
      );
    } catch (e, st) {
      debugPrint('SmsScannerService.registerSystemFormat error: $e\n$st');
      return FormatLearningResult.failure('포맷 저장 실패: $e');
    }
  }
}
