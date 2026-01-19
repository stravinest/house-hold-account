import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../config/supabase_config.dart';
import '../models/payment_method_model.dart';

class PaymentMethodRepository {
  final _client = SupabaseConfig.client;

  // 가계부의 모든 결제수단 조회
  Future<List<PaymentMethodModel>> getPaymentMethods(String ledgerId) async {
    final response = await _client
        .from('payment_methods')
        .select()
        .eq('ledger_id', ledgerId)
        .order('sort_order');

    return (response as List)
        .map((json) => PaymentMethodModel.fromJson(json))
        .toList();
  }

  // 결제수단 생성
  Future<PaymentMethodModel> createPaymentMethod({
    required String ledgerId,
    required String name,
    String icon = '',
    String color = '#6750A4',
  }) async {
    // 현재 최대 sort_order 조회
    final maxOrderResponse = await _client
        .from('payment_methods')
        .select('sort_order')
        .eq('ledger_id', ledgerId)
        .order('sort_order', ascending: false)
        .limit(1)
        .maybeSingle();

    final maxOrder = maxOrderResponse?['sort_order'] as int? ?? 0;

    final data = PaymentMethodModel.toCreateJson(
      ledgerId: ledgerId,
      name: name,
      icon: icon,
      color: color,
      sortOrder: maxOrder + 1,
    );

    final response = await _client
        .from('payment_methods')
        .insert(data)
        .select()
        .single();

    return PaymentMethodModel.fromJson(response);
  }

  // 결제수단 수정
  Future<PaymentMethodModel> updatePaymentMethod({
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
        .from('payment_methods')
        .update(updates)
        .eq('id', id)
        .select()
        .single();

    return PaymentMethodModel.fromJson(response);
  }

  // 결제수단 삭제
  Future<void> deletePaymentMethod(String id) async {
    final response = await _client
        .from('payment_methods')
        .delete()
        .eq('id', id)
        .select();

    if ((response as List).isEmpty) {
      throw Exception('결제수단 삭제에 실패했습니다. 권한이 없거나 존재하지 않는 결제수단입니다.');
    }
  }

  // 결제수단 순서 변경 (배치 RPC 사용)
  Future<void> reorderPaymentMethods(List<String> paymentMethodIds) async {
    await _client.rpc(
      'batch_reorder_payment_methods',
      params: {'p_payment_method_ids': paymentMethodIds},
    );
  }

  // 실시간 구독 - payment_methods 테이블
  RealtimeChannel subscribePaymentMethods({
    required String ledgerId,
    required void Function() onPaymentMethodChanged,
  }) {
    return _client
        .channel('payment_methods_changes_$ledgerId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'house',
          table: 'payment_methods',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'ledger_id',
            value: ledgerId,
          ),
          callback: (payload) {
            onPaymentMethodChanged();
          },
        )
        .subscribe();
  }
}
