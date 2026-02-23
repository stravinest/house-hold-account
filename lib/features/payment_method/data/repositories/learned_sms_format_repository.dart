import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../config/supabase_config.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../models/learned_sms_format_model.dart';

class LearnedSmsFormatRepository {
  final SupabaseClient _client;

  LearnedSmsFormatRepository({SupabaseClient? client})
      : _client = client ?? SupabaseConfig.client;

  Future<List<LearnedSmsFormatModel>> getFormatsByPaymentMethod(
    String paymentMethodId,
  ) async {
    final response = await _client
        .from('learned_sms_formats')
        .select()
        .eq('payment_method_id', paymentMethodId)
        .order('confidence', ascending: false);

    return (response as List)
        .map((json) => LearnedSmsFormatModel.fromJson(json))
        .toList();
  }

  Future<List<LearnedSmsFormatModel>> getAllFormatsForLedger(
    String ledgerId,
  ) async {
    final response = await _client
        .from('learned_sms_formats')
        .select('*, payment_methods!inner(ledger_id)')
        .eq('payment_methods.ledger_id', ledgerId)
        .order('confidence', ascending: false);

    return (response as List)
        .map((json) => LearnedSmsFormatModel.fromJson(json))
        .toList();
  }

  Future<LearnedSmsFormatModel?> findMatchingFormat(
    String ledgerId,
    String sender,
  ) async {
    final formats = await getAllFormatsForLedger(ledgerId);

    for (final format in formats) {
      if (format.matchesSender(sender)) {
        return format;
      }
    }
    return null;
  }

  Future<LearnedSmsFormatModel> createFormat({
    required String paymentMethodId,
    required String senderPattern,
    List<String> senderKeywords = const [],
    required String amountRegex,
    Map<String, List<String>>? typeKeywords,
    String? merchantRegex,
    String? dateRegex,
    String? sampleSms,
    bool isSystem = false,
    double confidence = 0.8,
    List<String> excludedKeywords = const [],
  }) async {
    final data = LearnedSmsFormatModel.toCreateJson(
      paymentMethodId: paymentMethodId,
      senderPattern: senderPattern,
      senderKeywords: senderKeywords,
      amountRegex: amountRegex,
      typeKeywords: typeKeywords,
      merchantRegex: merchantRegex,
      dateRegex: dateRegex,
      sampleSms: sampleSms,
      isSystem: isSystem,
      confidence: confidence,
      excludedKeywords: excludedKeywords,
    );

    final response = await _client
        .from('learned_sms_formats')
        .insert(data)
        .select()
        .single();

    return LearnedSmsFormatModel.fromJson(response);
  }

  Future<LearnedSmsFormatModel> updateFormat({
    required String id,
    String? senderPattern,
    List<String>? senderKeywords,
    String? amountRegex,
    Map<String, List<String>>? typeKeywords,
    String? merchantRegex,
    String? dateRegex,
    double? confidence,
    List<String>? excludedKeywords,
  }) async {
    final updates = <String, dynamic>{'updated_at': DateTimeUtils.nowUtcIso()};
    if (senderPattern != null) updates['sender_pattern'] = senderPattern;
    if (senderKeywords != null) updates['sender_keywords'] = senderKeywords;
    if (amountRegex != null) updates['amount_regex'] = amountRegex;
    if (typeKeywords != null) updates['type_keywords'] = typeKeywords;
    if (merchantRegex != null) updates['merchant_regex'] = merchantRegex;
    if (dateRegex != null) updates['date_regex'] = dateRegex;
    if (confidence != null) updates['confidence'] = confidence;
    if (excludedKeywords != null) {
      updates['excluded_keywords'] = excludedKeywords;
    }

    final response = await _client
        .from('learned_sms_formats')
        .update(updates)
        .eq('id', id)
        .select()
        .single();

    return LearnedSmsFormatModel.fromJson(response);
  }

  /// match_count 증가
  ///
  /// RPC 함수가 없으면 직접 업데이트로 폴백
  Future<void> incrementMatchCount(String id) async {
    try {
      // RPC 함수로 원자적 증가 시도
      await _client.rpc(
        'increment_sms_format_match_count',
        params: {'format_id': id},
      );
    } catch (_) {
      // RPC 함수가 없으면 직접 업데이트 (race condition 가능성 있음)
      try {
        final current = await _client
            .from('learned_sms_formats')
            .select('match_count')
            .eq('id', id)
            .maybeSingle();

        if (current != null) {
          await _client
              .from('learned_sms_formats')
              .update({
                'match_count': (current['match_count'] as int? ?? 0) + 1,
                'updated_at': DateTimeUtils.nowUtcIso(),
              })
              .eq('id', id);
        }
      } catch (e) {
        // match_count는 핵심 기능이 아니지만 지속적 실패 시 확인 필요
        debugPrint(
          '[LearnedSmsFormat] incrementMatchCount fallback failed: $e',
        );
      }
    }
  }

  Future<void> deleteFormat(String id) async {
    await _client.from('learned_sms_formats').delete().eq('id', id);
  }

  Future<void> deleteNonSystemFormats(String paymentMethodId) async {
    await _client
        .from('learned_sms_formats')
        .delete()
        .eq('payment_method_id', paymentMethodId)
        .eq('is_system', false);
  }

  // === SmsScanner 서비스 호환 메서드 ===

  /// Model 객체로 포맷 생성
  Future<LearnedSmsFormatModel> create(LearnedSmsFormatModel model) async {
    return createFormat(
      paymentMethodId: model.paymentMethodId,
      senderPattern: model.senderPattern,
      senderKeywords: model.senderKeywords,
      amountRegex: model.amountRegex,
      typeKeywords: model.typeKeywords,
      merchantRegex: model.merchantRegex,
      dateRegex: model.dateRegex,
      sampleSms: model.sampleSms,
      isSystem: model.isSystem,
      confidence: model.confidence,
    );
  }

  /// 결제수단 ID로 포맷 목록 조회 (별칭)
  Future<List<LearnedSmsFormatModel>> getByPaymentMethodId(
    String paymentMethodId,
  ) {
    return getFormatsByPaymentMethod(paymentMethodId);
  }

  /// 포맷 삭제 (별칭)
  Future<void> delete(String id) {
    return deleteFormat(id);
  }
}
