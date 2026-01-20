import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../../../../config/supabase_config.dart';

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
        return DuplicateCheckResult.duplicatePending(hash, pendingDuplicate);
      }

      // 2. transactions에서 중복 확인 (시간 기반)
      final transactionDuplicate = await _checkTransactionDuplicate(
        amount: amount,
        paymentMethodId: paymentMethodId,
        ledgerId: ledgerId,
        timestamp: timestamp,
      );
      if (transactionDuplicate != null) {
        return DuplicateCheckResult.duplicateTransaction(
          hash,
          transactionDuplicate,
        );
      }

      return DuplicateCheckResult.notDuplicate(hash);
    } catch (e, st) {
      // DB 에러 발생 시 안전하게 notDuplicate 반환
      // 중복 저장보다 거래 누락이 사용자에게 덜 해로움
      debugPrint('DuplicateCheckService.checkDuplicate error: $e\n$st');
      return DuplicateCheckResult.notDuplicate(hash);
    }
  }

  /// pending_transactions에서 동일 해시 확인
  Future<String?> _checkPendingDuplicate(String hash, String ledgerId) async {
    final response = await _client
        .from('pending_transactions')
        .select('id')
        .eq('ledger_id', ledgerId)
        .eq('duplicate_hash', hash)
        .eq('status', 'pending')
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
    final windowStart = timestamp.subtract(duplicateWindow);
    final windowEnd = timestamp.add(duplicateWindow);

    var query = _client
        .from('transactions')
        .select('id')
        .eq('ledger_id', ledgerId)
        .eq('amount', amount)
        .gte('date', windowStart.toIso8601String())
        .lte('date', windowEnd.toIso8601String());

    if (paymentMethodId != null) {
      query = query.eq('payment_method_id', paymentMethodId);
    }

    final response = await query.limit(1).maybeSingle();
    return response?['id'] as String?;
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
}
