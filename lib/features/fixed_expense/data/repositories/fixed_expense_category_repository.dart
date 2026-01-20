import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../config/supabase_config.dart';
import '../../../../core/utils/supabase_error_handler.dart';
import '../models/fixed_expense_category_model.dart';

/// 고정비 카테고리 Repository
class FixedExpenseCategoryRepository {
  final _client = SupabaseConfig.client;

  // 가계부의 모든 고정비 카테고리 조회
  Future<List<FixedExpenseCategoryModel>> getCategories(String ledgerId) async {
    try {
      final response = await _client
          .from('fixed_expense_categories')
          .select()
          .eq('ledger_id', ledgerId)
          .order('sort_order');

      return (response as List)
          .map((json) => FixedExpenseCategoryModel.fromJson(json))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // 고정비 카테고리 생성
  Future<FixedExpenseCategoryModel> createCategory({
    required String ledgerId,
    required String name,
    String icon = '',
    required String color,
  }) async {
    try {
      // 현재 최대 sort_order 조회
      final maxOrderResponse = await _client
          .from('fixed_expense_categories')
          .select('sort_order')
          .eq('ledger_id', ledgerId)
          .order('sort_order', ascending: false)
          .limit(1)
          .maybeSingle();

      final maxOrder = maxOrderResponse?['sort_order'] as int? ?? 0;

      final data = FixedExpenseCategoryModel.toCreateJson(
        ledgerId: ledgerId,
        name: name,
        icon: icon,
        color: color,
        sortOrder: maxOrder + 1,
      );

      final response = await _client
          .from('fixed_expense_categories')
          .insert(data)
          .select()
          .single();

      return FixedExpenseCategoryModel.fromJson(response);
    } catch (e) {
      if (SupabaseErrorHandler.isDuplicateError(e)) {
        throw DuplicateItemException(itemType: '고정비 카테고리', itemName: name);
      }
      rethrow;
    }
  }

  // 고정비 카테고리 수정
  Future<FixedExpenseCategoryModel> updateCategory({
    required String id,
    required String name,
    String? icon,
    String? color,
    int? sortOrder,
  }) async {
    try {
      final updates = FixedExpenseCategoryModel.toUpdateJson(
        name: name,
        icon: icon,
        color: color,
        sortOrder: sortOrder,
      );

      final response = await _client
          .from('fixed_expense_categories')
          .update(updates)
          .eq('id', id)
          .select()
          .single();

      return FixedExpenseCategoryModel.fromJson(response);
    } catch (e) {
      if (SupabaseErrorHandler.isDuplicateError(e)) {
        throw DuplicateItemException(itemType: '고정비 카테고리', itemName: name);
      }
      rethrow;
    }
  }

  // 고정비 카테고리 삭제
  Future<void> deleteCategory(String id) async {
    try {
      await _client.from('fixed_expense_categories').delete().eq('id', id);
    } catch (e) {
      rethrow;
    }
  }

  // 고정비 카테고리 순서 변경 (배치 RPC 사용)
  Future<void> reorderCategories(List<String> categoryIds) async {
    try {
      await _client.rpc(
        'batch_reorder_fixed_expense_categories',
        params: {'p_category_ids': categoryIds},
      );
    } catch (e) {
      rethrow;
    }
  }

  // 실시간 구독
  RealtimeChannel subscribeCategories({
    required String ledgerId,
    required void Function() onCategoryChanged,
  }) {
    return _client
        .channel('fixed_expense_categories_changes_$ledgerId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'house',
          table: 'fixed_expense_categories',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'ledger_id',
            value: ledgerId,
          ),
          callback: (payload) {
            onCategoryChanged();
          },
        )
        .subscribe();
  }
}
