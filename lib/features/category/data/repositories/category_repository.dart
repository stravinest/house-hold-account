import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../config/supabase_config.dart';
import '../models/category_model.dart';

class CategoryRepository {
  final _client = SupabaseConfig.client;

  // 가계부의 모든 카테고리 조회
  Future<List<CategoryModel>> getCategories(String ledgerId) async {
    final response = await _client
        .schema('house')
        .from('categories')
        .select()
        .eq('ledger_id', ledgerId)
        .order('sort_order');

    return (response as List)
        .map((json) => CategoryModel.fromJson(json))
        .toList();
  }

  // 타입별 카테고리 조회
  Future<List<CategoryModel>> getCategoriesByType({
    required String ledgerId,
    required String type,
  }) async {
    final response = await _client
        .schema('house')
        .from('categories')
        .select()
        .eq('ledger_id', ledgerId)
        .eq('type', type)
        .order('sort_order');

    return (response as List)
        .map((json) => CategoryModel.fromJson(json))
        .toList();
  }

  // 카테고리 생성
  Future<CategoryModel> createCategory({
    required String ledgerId,
    required String name,
    required String icon,
    required String color,
    required String type,
  }) async {
    // 현재 최대 sort_order 조회
    final maxOrderResponse = await _client
        .schema('house')
        .from('categories')
        .select('sort_order')
        .eq('ledger_id', ledgerId)
        .eq('type', type)
        .order('sort_order', ascending: false)
        .limit(1)
        .maybeSingle();

    final maxOrder = maxOrderResponse?['sort_order'] as int? ?? 0;

    final data = CategoryModel.toCreateJson(
      ledgerId: ledgerId,
      name: name,
      icon: icon,
      color: color,
      type: type,
      sortOrder: maxOrder + 1,
    );

    final response = await _client
        .schema('house')
        .from('categories')
        .insert(data)
        .select()
        .single();

    return CategoryModel.fromJson(response);
  }

  // 카테고리 수정
  Future<CategoryModel> updateCategory({
    required String id,
    String? name,
    String? icon,
    String? color,
    int? sortOrder,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (icon != null) updates['icon'] = icon;
    if (color != null) updates['color'] = color;
    if (sortOrder != null) updates['sort_order'] = sortOrder;

    final response = await _client
        .schema('house')
        .from('categories')
        .update(updates)
        .eq('id', id)
        .select()
        .single();

    return CategoryModel.fromJson(response);
  }

  // 카테고리 삭제 (기본 카테고리는 삭제 불가)
  Future<void> deleteCategory(String id) async {
    final response = await _client
        .schema('house')
        .from('categories')
        .delete()
        .eq('id', id)
        .eq('is_default', false)
        .select();

    if ((response as List).isEmpty) {
      throw Exception('카테고리 삭제에 실패했습니다. 기본 카테고리이거나 권한이 없습니다.');
    }
  }

  // 카테고리 순서 변경
  Future<void> reorderCategories(List<String> categoryIds) async {
    for (int i = 0; i < categoryIds.length; i++) {
      await _client
          .schema('house')
          .from('categories')
          .update({'sort_order': i})
          .eq('id', categoryIds[i]);
    }
  }

  // 실시간 구독 - categories 테이블
  RealtimeChannel subscribeCategories({
    required String ledgerId,
    required void Function() onCategoryChanged,
  }) {
    return _client
        .channel('categories_changes_$ledgerId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'house',
          table: 'categories',
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
