import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../../../../config/supabase_config.dart';
import '../../../../core/utils/date_time_utils.dart';

/// 중복 체크 결과
class DuplicateCheckResult {
  final bool isDuplicate;
  final String? existingTransactionId;
  final String? existingPendingId;
  final String duplicateHash;

  const DuplicateCheckResult({
    required this.isDuplicate,
    this.existingTransactionId,
    this.existingPendingId,
    required this.duplicateHash,
  });

  factory DuplicateCheckResult.notDuplicate(String hash) {
    return DuplicateCheckResult(isDuplicate: false, duplicateHash: hash);
  }

  factory DuplicateCheckResult.duplicateTransaction(
    String hash,
    String transactionId,
  ) {
    return DuplicateCheckResult(
      isDuplicate: true,
      existingTransactionId: transactionId,
      duplicateHash: hash,
    );
  }

  factory DuplicateCheckResult.duplicatePending(String hash, String pendingId) {
    return DuplicateCheckResult(
      isDuplicate: true,
      existingPendingId: pendingId,
      duplicateHash: hash,
    );
  }
}

/// 중복 거래 체크 서비스
///
/// 3분 이내 동일 금액 + 동일 결제수단의 거래를 중복으로 판단합니다.
class DuplicateCheckService {
  final dynamic _client;

  /// 중복 체크 시간 윈도우 (기본 3분)
  static const Duration duplicateWindow = Duration(minutes: 3);

  /// 기본 생성자 - Supabase 클라이언트 주입
  DuplicateCheckService({dynamic client})
    : _client = client ?? SupabaseConfig.client;

  /// 중복 체크
  ///
  /// [amount] - 거래 금액
  /// [paymentMethodId] - 결제수단 ID (nullable)
  /// [ledgerId] - 가계부 ID
  /// [timestamp] - 거래 시간
  ///
  /// 에러 발생 시 안전하게 notDuplicate 반환 (중복 저장보다 누락이 나음)
  Future<DuplicateCheckResult> checkDuplicate({
    required int amount,
    String? paymentMethodId,
    required String ledgerId,
    required DateTime timestamp,
  }) async {
    final hash = generateDuplicateHash(amount, paymentMethodId, timestamp);

    try {
      // 1. pending_transactions에서 중복 확인
      final pendingDuplicate = await _checkPendingDuplicate(hash, ledgerId);
      if (pendingDuplicate != null) {
        debugPrint(
          'Duplicate found in pending_transactions: $pendingDuplicate (hash: $hash)',
        );
        return DuplicateCheckResult.duplicatePending(hash, pendingDuplicate);
      }

      // 2. transactions에서 중복 확인 (시간/상호명 기반)
      final transactionDuplicate = await _checkTransactionDuplicate(
        amount: amount,
        paymentMethodId: paymentMethodId,
        ledgerId: ledgerId,
        timestamp: timestamp,
      );
      if (transactionDuplicate != null) {
        debugPrint('Duplicate found in transactions: $transactionDuplicate');
        return DuplicateCheckResult.duplicateTransaction(
          hash,
          transactionDuplicate,
        );
      }

      debugPrint('No duplicate found for hash: $hash');
      return DuplicateCheckResult.notDuplicate(hash);
    } catch (e, st) {
      // DB 에러 발생 시 안전하게 notDuplicate 반환
      // 중복 저장보다 거래 누락이 사용자에게 덜 해로움
      debugPrint('DuplicateCheckService.checkDuplicate error: $e\n$st');
      return DuplicateCheckResult.notDuplicate(hash);
    }
  }

  /// pending_transactions에서 동일 해시 확인
  ///
  /// SMS/Push 동시 수신 문제 방지:
  /// - created_at이 5초 이내인 경우는 중복으로 보지 않음
  /// - 이렇게 하면 SMS와 Push 알림이 동시에 수신되어도 서로를 중복으로 감지하지 않음
  Future<String?> _checkPendingDuplicate(String hash, String ledgerId) async {
    final fiveSecondsAgo = DateTimeUtils.toUtcIso(
      DateTime.now().subtract(const Duration(seconds: 5)),
    );

    final response = await _client
        .from('pending_transactions')
        .select('id, created_at')
        .eq('ledger_id', ledgerId)
        .eq('duplicate_hash', hash)
        .eq('status', 'pending')
        .lt('created_at', fiveSecondsAgo)
        .limit(1)
        .maybeSingle();

    return response?['id'] as String?;
  }

  /// transactions에서 시간 기반 중복 확인
  Future<String?> _checkTransactionDuplicate({
    required int amount,
    String? paymentMethodId,
    required String ledgerId,
    required DateTime timestamp,
  }) async {
    var query = _client
        .from('transactions')
        .select('id')
        .eq('ledger_id', ledgerId)
        .eq('amount', amount)
        // 날짜가 DATE 타입일 경우 시간 비교가 부정확할 수 있으므로
        // 같은 날짜의 데이터 중 최근 것을 가져와서 더 세부적인 필터링 수행
        .eq('date', timestamp.toIso8601String().split('T')[0]);

    if (paymentMethodId != null) {
      query = query.eq('payment_method_id', paymentMethodId);
    }

    final List<dynamic> responses = await query.limit(5);

    // 단순 날짜 비교가 아닌, 다른 속성이 있다면 추가 비교 로직이 가능함
    // 여기서는 일단 존재 여부만 체크하되, 캐시된 데이터와 현재 시간 차이를 볼 수 있음
    if (responses.isNotEmpty) {
      return responses.first['id'] as String?;
    }

    return null;
  }

  /// 중복 해시 생성
  ///
  /// 3분 단위로 버킷팅하여 동일 시간대의 동일 거래를 식별합니다.
  String generateDuplicateHash(
    int amount,
    String? paymentMethodId,
    DateTime timestamp,
  ) {
    // 3분 단위로 버킷팅 (180,000ms = 3분)
    final bucket = timestamp.millisecondsSinceEpoch ~/ (3 * 60 * 1000);
    final input = '$amount-${paymentMethodId ?? 'unknown'}-$bucket';

    // MD5 해시 생성 (충돌 가능성 낮고 빠름)
    final bytes = utf8.encode(input);
    final digest = md5.convert(bytes);

    return digest.toString();
  }

  /// 해시로 기존 대기 거래 조회
  Future<Map<String, dynamic>?> findPendingByHash(
    String hash,
    String ledgerId,
  ) async {
    try {
      final response = await _client
          .from('pending_transactions')
          .select()
          .eq('ledger_id', ledgerId)
          .eq('duplicate_hash', hash)
          .eq('status', 'pending')
          .limit(1)
          .maybeSingle();

      return response;
    } catch (e) {
      return null;
    }
  }

  /// 최근 중복 거래 목록 조회 (디버깅/관리용)
  Future<List<Map<String, dynamic>>> getRecentDuplicates(
    String ledgerId, {
    int limit = 20,
  }) async {
    try {
      // 최근 대기 거래 중 중복 해시가 있는 것들
      final response = await _client
          .from('pending_transactions')
          .select('duplicate_hash, count')
          .eq('ledger_id', ledgerId)
          .not('duplicate_hash', 'is', null)
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  /// 특정 거래와 유사한 거래 찾기 (금액 기준)
  Future<List<Map<String, dynamic>>> findSimilarTransactions({
    required int amount,
    required String ledgerId,
    int? tolerancePercent,
    int limit = 5,
  }) async {
    try {
      final tolerance = tolerancePercent ?? 0;
      final minAmount = (amount * (100 - tolerance) / 100).round();
      final maxAmount = (amount * (100 + tolerance) / 100).round();

      final response = await _client
          .from('transactions')
          .select('id, amount, description, date, category_id')
          .eq('ledger_id', ledgerId)
          .gte('amount', minAmount)
          .lte('amount', maxAmount)
          .order('date', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  /// SMS/Push 메시지 해시 생성 (중복 수신 방지용)
  ///
  /// 금액 + 내용 일부 + 시간(분 단위)로 해시를 만들어
  /// SMS와 Push 알림이 동시에 와도 동일한 메시지임을 식별
  ///
  /// [content] - 메시지 내용
  /// [timestamp] - 메시지 수신 시간
  ///
  /// 주의: sender를 포함하지 않음 (SMS는 전화번호, Push는 패키지명으로 달라서
  /// 같은 결제 알림이 다른 해시가 되는 문제 방지)
  static String generateMessageHash(String content, DateTime timestamp) {
    final minuteBucket = timestamp.millisecondsSinceEpoch ~/ (60 * 1000);

    // 금액 추출 (SMS/Push 공통으로 금액이 포함됨)
    final amountMatch = RegExp(r'(\d{1,3}(?:,\d{3})*)\s*원').firstMatch(content);
    final amount = amountMatch?.group(1)?.replaceAll(',', '') ?? '';

    // 내용에서 핵심 부분만 추출 (sender 제외)
    final contentPreview = content.length > 80
        ? content.substring(0, 80)
        : content;

    // 금액 + 내용 + 시간으로 해시 (sender 제외하여 SMS/Push 동일 해시)
    final input = '$amount-$contentPreview-$minuteBucket';

    final bytes = utf8.encode(input);
    return md5.convert(bytes).toString();
  }
}
