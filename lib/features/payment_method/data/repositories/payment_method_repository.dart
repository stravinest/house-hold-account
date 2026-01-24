import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../config/supabase_config.dart';
import '../../../../core/utils/supabase_error_handler.dart';
import '../models/payment_method_model.dart';

class PaymentMethodRepository {
  final _client = SupabaseConfig.client;

  /// 결제수단 쿼리를 위한 공통 헬퍼 메서드
  Future<List<PaymentMethodModel>> _queryPaymentMethods({
    required String ledgerId,
    String? ownerUserId,
    bool? canAutoSave,
  }) async {
    var query = _client.from('payment_methods').select().eq('ledger_id', ledgerId);

    if (ownerUserId != null) {
      query = query.eq('owner_user_id', ownerUserId);
    }
    if (canAutoSave != null) {
      query = query.eq('can_auto_save', canAutoSave);
    }

    final response = await query.order('sort_order');
    return (response as List)
        .map((json) => PaymentMethodModel.fromJson(json))
        .toList();
  }

  // 가계부의 모든 결제수단 조회
  Future<List<PaymentMethodModel>> getPaymentMethods(String ledgerId) async {
    return _queryPaymentMethods(ledgerId: ledgerId);
  }

  // 특정 멤버의 결제수단만 조회 (멤버별 탭용)
  Future<List<PaymentMethodModel>> getPaymentMethodsByOwner({
    required String ledgerId,
    required String ownerUserId,
  }) async {
    return _queryPaymentMethods(
      ledgerId: ledgerId,
      ownerUserId: ownerUserId,
    );
  }

  // 공유 결제수단 조회 (직접입력, can_auto_save = false)
  Future<List<PaymentMethodModel>> getSharedPaymentMethods(
    String ledgerId,
  ) async {
    return _queryPaymentMethods(
      ledgerId: ledgerId,
      canAutoSave: false,
    );
  }

  // 특정 멤버의 자동수집 결제수단만 조회 (can_auto_save = true)
  Future<List<PaymentMethodModel>> getAutoCollectPaymentMethodsByOwner({
    required String ledgerId,
    required String ownerUserId,
  }) async {
    return _queryPaymentMethods(
      ledgerId: ledgerId,
      ownerUserId: ownerUserId,
      canAutoSave: true,
    );
  }

  // ID로 단일 결제수단 조회 (백그라운드 알림 처리용 - 타임아웃 포함)
  Future<PaymentMethodModel?> getPaymentMethodById(String id) async {
    try {
      final response = await _client
          .from('payment_methods')
          .select()
          .eq('id', id)
          .maybeSingle()
          .timeout(const Duration(seconds: 5));

      if (response == null) return null;
      return PaymentMethodModel.fromJson(response);
    } on TimeoutException {
      debugPrint('getPaymentMethodById timeout - will use cached value');
      return null;
    } catch (e) {
      debugPrint('Failed to get payment method by id: $e');
      return null;
    }
  }

  // 결제수단 생성
  Future<PaymentMethodModel> createPaymentMethod({
    required String ledgerId,
    required String name,
    String icon = '',
    String color = '#6750A4',
    bool canAutoSave = true,
  }) async {
    try {
      // 현재 로그인한 사용자 ID 가져오기
      final currentUserId = _client.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('로그인이 필요합니다');
      }

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
        ownerUserId: currentUserId,
        name: name,
        icon: icon,
        color: color,
        sortOrder: maxOrder + 1,
        canAutoSave: canAutoSave,
      );

      final response = await _client
          .from('payment_methods')
          .insert(data)
          .select()
          .single();

      return PaymentMethodModel.fromJson(response);
    } catch (e) {
      if (SupabaseErrorHandler.isDuplicateError(e)) {
        throw DuplicateItemException(itemType: '결제수단', itemName: name);
      }
      rethrow;
    }
  }

  // 결제수단 수정
  Future<PaymentMethodModel> updatePaymentMethod({
    required String id,
    String? name,
    String? icon,
    String? color,
    int? sortOrder,
    bool? canAutoSave,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (icon != null) updates['icon'] = icon;
      if (color != null) updates['color'] = color;
      if (sortOrder != null) updates['sort_order'] = sortOrder;
      if (canAutoSave != null) updates['can_auto_save'] = canAutoSave;

      final response = await _client
          .from('payment_methods')
          .update(updates)
          .eq('id', id)
          .select()
          .single();

      return PaymentMethodModel.fromJson(response);
    } catch (e) {
      if (SupabaseErrorHandler.isDuplicateError(e)) {
        throw DuplicateItemException(itemType: '결제수단', itemName: name);
      }
      rethrow;
    }
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
    try {
      final response = await _client.rpc(
        'batch_reorder_payment_methods',
        params: {'p_payment_method_ids': paymentMethodIds},
      );

      // RPC가 false를 반환하면 실패로 간주
      if (response == false) {
        throw Exception('결제수단 순서 변경에 실패했습니다.');
      }
    } catch (e) {
      debugPrint('결제수단 순서 변경 실패: $e');
      rethrow;
    }
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

  Future<PaymentMethodModel> updateAutoSaveSettings({
    required String id,
    required String autoSaveMode,
    String? defaultCategoryId,
    String? autoCollectSource,
  }) async {
    final updates = <String, dynamic>{'auto_save_mode': autoSaveMode};
    if (defaultCategoryId != null) {
      updates['default_category_id'] = defaultCategoryId;
    }
    if (autoCollectSource != null) {
      updates['auto_collect_source'] = autoCollectSource;
    }

    final response = await _client
        .from('payment_methods')
        .update(updates)
        .eq('id', id)
        .select()
        .single();

    return PaymentMethodModel.fromJson(response);
  }

  Future<List<PaymentMethodModel>> getAutoSaveEnabledPaymentMethods(
    String ledgerId,
  ) async {
    final response = await _client
        .from('payment_methods')
        .select()
        .eq('ledger_id', ledgerId)
        .neq('auto_save_mode', 'manual')
        .order('sort_order');

    return (response as List)
        .map((json) => PaymentMethodModel.fromJson(json))
        .toList();
  }
}
