import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../config/supabase_config.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../models/learned_push_format_model.dart';

class LearnedPushFormatRepository {
  final SupabaseClient _client;

  LearnedPushFormatRepository({SupabaseClient? client})
      : _client = client ?? SupabaseConfig.client;

  Future<List<LearnedPushFormatModel>> getFormatsByPaymentMethod(
    String paymentMethodId,
  ) async {
    final response = await _client
        .from('learned_push_formats')
        .select()
        .eq('payment_method_id', paymentMethodId)
        .order('confidence', ascending: false);

    return (response as List)
        .map((json) => LearnedPushFormatModel.fromJson(json))
        .toList();
  }

  Future<List<LearnedPushFormatModel>> getAllFormatsForLedger(
    String ledgerId,
  ) async {
    final response = await _client
        .from('learned_push_formats')
        .select('*, payment_methods!inner(ledger_id)')
        .eq('payment_methods.ledger_id', ledgerId)
        .order('confidence', ascending: false);

    return (response as List)
        .map((json) => LearnedPushFormatModel.fromJson(json))
        .toList();
  }

  Future<LearnedPushFormatModel?> findMatchingFormat(
    String ledgerId,
    String packageName,
    String content,
  ) async {
    final formats = await getAllFormatsForLedger(ledgerId);

    for (final format in formats) {
      if (format.matchesNotification(packageName, content)) {
        return format;
      }
    }
    return null;
  }

  Future<LearnedPushFormatModel> createFormat({
    required String paymentMethodId,
    required String packageName,
    List<String> appKeywords = const [],
    required String amountRegex,
    Map<String, List<String>>? typeKeywords,
    String? merchantRegex,
    String? dateRegex,
    String? sampleNotification,
    double confidence = 0.8,
  }) async {
    final data = LearnedPushFormatModel.toCreateJson(
      paymentMethodId: paymentMethodId,
      packageName: packageName,
      appKeywords: appKeywords,
      amountRegex: amountRegex,
      typeKeywords: typeKeywords,
      merchantRegex: merchantRegex,
      dateRegex: dateRegex,
      sampleNotification: sampleNotification,
      confidence: confidence,
    );

    final response = await _client
        .from('learned_push_formats')
        .insert(data)
        .select()
        .single();

    return LearnedPushFormatModel.fromJson(response);
  }

  Future<LearnedPushFormatModel> updateFormat({
    required String id,
    String? packageName,
    List<String>? appKeywords,
    String? amountRegex,
    Map<String, List<String>>? typeKeywords,
    String? merchantRegex,
    String? dateRegex,
    double? confidence,
  }) async {
    final updates = <String, dynamic>{'updated_at': DateTimeUtils.nowUtcIso()};
    if (packageName != null) updates['package_name'] = packageName;
    if (appKeywords != null) updates['app_keywords'] = appKeywords;
    if (amountRegex != null) updates['amount_regex'] = amountRegex;
    if (typeKeywords != null) updates['type_keywords'] = typeKeywords;
    if (merchantRegex != null) updates['merchant_regex'] = merchantRegex;
    if (dateRegex != null) updates['date_regex'] = dateRegex;
    if (confidence != null) updates['confidence'] = confidence;

    final response = await _client
        .from('learned_push_formats')
        .update(updates)
        .eq('id', id)
        .select()
        .single();

    return LearnedPushFormatModel.fromJson(response);
  }

  /// match_count 증가
  ///
  /// RPC 함수가 없으면 직접 업데이트로 폴백
  Future<void> incrementMatchCount(String id) async {
    try {
      // RPC 함수로 원자적 증가 시도
      await _client.rpc(
        'increment_push_format_match_count',
        params: {'format_id': id},
      );
    } catch (_) {
      // RPC 함수가 없으면 직접 업데이트 (race condition 가능성 있음)
      try {
        final current = await _client
            .from('learned_push_formats')
            .select('match_count')
            .eq('id', id)
            .maybeSingle();

        if (current != null) {
          await _client
              .from('learned_push_formats')
              .update({
                'match_count': (current['match_count'] as int? ?? 0) + 1,
                'updated_at': DateTimeUtils.nowUtcIso(),
              })
              .eq('id', id);
        }
      } catch (e) {
        // match_count는 핵심 기능이 아니지만 지속적 실패 시 확인 필요
        debugPrint(
          '[LearnedPushFormat] incrementMatchCount fallback failed: $e',
        );
      }
    }
  }

  Future<void> deleteFormat(String id) async {
    await _client.from('learned_push_formats').delete().eq('id', id);
  }

  Future<void> deleteNonSystemFormats(String paymentMethodId) async {
    await _client
        .from('learned_push_formats')
        .delete()
        .eq('payment_method_id', paymentMethodId);
  }

  // === PushScanner 서비스 호환 메서드 ===

  /// Model 객체로 포맷 생성
  Future<LearnedPushFormatModel> create(LearnedPushFormatModel model) async {
    return createFormat(
      paymentMethodId: model.paymentMethodId,
      packageName: model.packageName,
      appKeywords: model.appKeywords,
      amountRegex: model.amountRegex,
      typeKeywords: model.typeKeywords,
      merchantRegex: model.merchantRegex,
      dateRegex: model.dateRegex,
      sampleNotification: model.sampleNotification,
      confidence: model.confidence,
    );
  }

  /// 결제수단 ID로 포맷 목록 조회 (별칭)
  Future<List<LearnedPushFormatModel>> getByPaymentMethodId(
    String paymentMethodId,
  ) {
    return getFormatsByPaymentMethod(paymentMethodId);
  }

  /// 포맷 삭제 (별칭)
  Future<void> delete(String id) {
    return deleteFormat(id);
  }
}
