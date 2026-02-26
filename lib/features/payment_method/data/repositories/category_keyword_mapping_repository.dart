import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../config/supabase_config.dart';
import '../models/category_keyword_mapping_model.dart';

class CategoryKeywordMappingRepository {
  final SupabaseClient _client;

  CategoryKeywordMappingRepository({SupabaseClient? client})
      : _client = client ?? SupabaseConfig.client;

  Future<List<CategoryKeywordMappingModel>> getByPaymentMethod(
    String paymentMethodId, {
    String? sourceType,
  }) async {
    var query = _client
        .from('category_keyword_mappings')
        .select()
        .eq('payment_method_id', paymentMethodId);

    if (sourceType != null) {
      query = query.eq('source_type', sourceType);
    }

    final response = await query.order('created_at', ascending: false);

    return (response as List)
        .map((json) => CategoryKeywordMappingModel.fromJson(json))
        .toList();
  }

  Future<List<CategoryKeywordMappingModel>> getByLedger(
    String ledgerId, {
    String? sourceType,
  }) async {
    var query = _client
        .from('category_keyword_mappings')
        .select()
        .eq('ledger_id', ledgerId);

    if (sourceType != null) {
      query = query.eq('source_type', sourceType);
    }

    final response = await query.order('created_at', ascending: false);

    return (response as List)
        .map((json) => CategoryKeywordMappingModel.fromJson(json))
        .toList();
  }

  Future<CategoryKeywordMappingModel> create({
    required String paymentMethodId,
    required String ledgerId,
    required String keyword,
    required String categoryId,
    required String sourceType,
    required String createdBy,
  }) async {
    final data = CategoryKeywordMappingModel.toCreateJson(
      paymentMethodId: paymentMethodId,
      ledgerId: ledgerId,
      keyword: keyword,
      categoryId: categoryId,
      sourceType: sourceType,
      createdBy: createdBy,
    );

    final response = await _client
        .from('category_keyword_mappings')
        .insert(data)
        .select()
        .single();

    return CategoryKeywordMappingModel.fromJson(response);
  }

  Future<void> delete(String id) async {
    await _client.from('category_keyword_mappings').delete().eq('id', id);
  }

  Future<CategoryKeywordMappingModel?> findByKeyword(
    String paymentMethodId,
    String keyword,
    String sourceType,
  ) async {
    final response = await _client
        .from('category_keyword_mappings')
        .select()
        .eq('payment_method_id', paymentMethodId)
        .eq('keyword', keyword)
        .eq('source_type', sourceType)
        .maybeSingle();

    if (response == null) return null;
    return CategoryKeywordMappingModel.fromJson(response);
  }
}
