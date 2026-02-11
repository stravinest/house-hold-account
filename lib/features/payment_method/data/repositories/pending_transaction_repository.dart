import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../config/supabase_config.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../../domain/entities/pending_transaction.dart';
import '../models/pending_transaction_model.dart';

class PendingTransactionRepository {
  final _client = SupabaseConfig.client;

  Future<List<PendingTransactionModel>> getPendingTransactions(
    String ledgerId, {
    PendingTransactionStatus? status,
    String? userId,
  }) async {
    return _retry(() async {
      var query = _client
          .from('pending_transactions')
          .select()
          .eq('ledger_id', ledgerId);

      if (userId != null) {
        query = query.eq('user_id', userId);
      }

      if (status != null) {
        query = query.eq('status', status.toJson());
      }

      final response = await query.order('source_timestamp', ascending: false);

      return (response as List)
          .map((json) => PendingTransactionModel.fromJson(json))
          .toList();
    });
  }

  Future<int> getPendingCount(String ledgerId, String userId) async {
    final response = await _client
        .from('pending_transactions')
        .select('id')
        .eq('ledger_id', ledgerId)
        .eq('user_id', userId)
        .eq('is_viewed', false);

    return (response as List).length;
  }

  Future<PendingTransactionModel> createPendingTransaction({
    required String ledgerId,
    String? paymentMethodId,
    required String userId,
    required SourceType sourceType,
    String? sourceSender,
    required String sourceContent,
    required DateTime sourceTimestamp,
    int? parsedAmount,
    String? parsedType,
    String? parsedMerchant,
    String? parsedCategoryId,
    DateTime? parsedDate,
    String? duplicateHash,
    bool isDuplicate = false,
    PendingTransactionStatus? status,
    bool isViewed = false,
  }) async {
    final data = PendingTransactionModel.toCreateJson(
      ledgerId: ledgerId,
      paymentMethodId: paymentMethodId,
      userId: userId,
      sourceType: sourceType,
      sourceSender: sourceSender,
      sourceContent: sourceContent,
      sourceTimestamp: sourceTimestamp,
      parsedAmount: parsedAmount,
      parsedType: parsedType,
      parsedMerchant: parsedMerchant,
      parsedCategoryId: parsedCategoryId,
      parsedDate: parsedDate,
      duplicateHash: duplicateHash,
      isDuplicate: isDuplicate,
      status: status,
      isViewed: isViewed,
    );

    return _retry(() async {
      // 현재 인증 사용자 확인
      final currentAuthUser = _client.auth.currentUser;
      if (currentAuthUser == null) {
        throw Exception('Not authenticated - auth.currentUser is null');
      }
      if (currentAuthUser.id != userId) {
        throw Exception(
          'User ID mismatch - auth.uid: ${currentAuthUser.id}, provided userId: $userId',
        );
      }

      final response = await _client
          .from('pending_transactions')
          .insert(data)
          .select();

      if ((response as List).isEmpty) {
        // 추가 진단: 해당 사용자가 ledger의 멤버인지 확인
        final memberCheck = await _client
            .from('ledger_members')
            .select('role')
            .eq('ledger_id', ledgerId)
            .eq('user_id', userId)
            .maybeSingle();

        throw Exception(
          'INSERT returned 0 rows - RLS policy may have blocked the insert. '
          'ledgerId: $ledgerId, userId: $userId, authUid: ${currentAuthUser.id}, '
          'isMember: ${memberCheck != null}, role: ${memberCheck?['role']}',
        );
      }

      return PendingTransactionModel.fromJson(response.first);
    });
  }

  Future<PendingTransactionModel> updateStatus({
    required String id,
    required PendingTransactionStatus status,
    String? transactionId,
  }) async {
    final updates = PendingTransactionModel.toUpdateStatusJson(
      status: status,
      transactionId: transactionId,
    );

    final response = await _client
        .from('pending_transactions')
        .update(updates)
        .eq('id', id)
        .select()
        .single();

    return PendingTransactionModel.fromJson(response);
  }

  Future<PendingTransactionModel> updateParsedData({
    required String id,
    int? parsedAmount,
    String? parsedType,
    String? parsedMerchant,
    String? parsedCategoryId,
    DateTime? parsedDate,
    String? paymentMethodId,
  }) async {
    final updates = <String, dynamic>{'updated_at': DateTimeUtils.nowUtcIso()};
    if (parsedAmount != null) updates['parsed_amount'] = parsedAmount;
    if (parsedType != null) updates['parsed_type'] = parsedType;
    if (parsedMerchant != null) updates['parsed_merchant'] = parsedMerchant;
    if (parsedCategoryId != null) {
      updates['parsed_category_id'] = parsedCategoryId;
    }
    if (parsedDate != null) {
      updates['parsed_date'] = parsedDate.toIso8601String().split('T').first;
    }
    if (paymentMethodId != null) {
      updates['payment_method_id'] = paymentMethodId;
    }

    final response = await _client
        .from('pending_transactions')
        .update(updates)
        .eq('id', id)
        .select()
        .single();

    return PendingTransactionModel.fromJson(response);
  }

  Future<void> deletePendingTransaction(String id) async {
    await _client.from('pending_transactions').delete().eq('id', id);
  }

  Future<void> deleteAllByStatus(
    String ledgerId,
    String userId,
    PendingTransactionStatus status,
  ) async {
    await _client
        .from('pending_transactions')
        .delete()
        .eq('ledger_id', ledgerId)
        .eq('user_id', userId)
        .eq('status', status.toJson());
  }

  Future<void> deleteAllRejected(String ledgerId, String userId) async {
    await deleteAllByStatus(
      ledgerId,
      userId,
      PendingTransactionStatus.rejected,
    );
  }

  /// 확인됨 탭의 모든 항목 삭제 (confirmed + converted 상태)
  Future<void> deleteAllConfirmed(String ledgerId, String userId) async {
    await _client
        .from('pending_transactions')
        .delete()
        .eq('ledger_id', ledgerId)
        .eq('user_id', userId)
        .inFilter('status', ['confirmed', 'converted']);
  }

  Future<bool> checkDuplicate({
    required int amount,
    required String? paymentMethodId,
    required DateTime timestamp,
    int minutesWindow = 3,
  }) async {
    if (paymentMethodId == null) return false;

    try {
      final response = await _client.rpc(
        'check_duplicate_transaction',
        params: {
          'p_amount': amount,
          'p_payment_method_id': paymentMethodId,
          'p_timestamp': timestamp.toIso8601String(),
          'p_minutes': minutesWindow,
        },
      );
      return response as bool? ?? false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[PendingTransaction] checkDuplicate RPC failed: $e');
      }
      return false;
    }
  }

  Future<int> cleanupExpired() async {
    try {
      final response = await _client.rpc(
        'cleanup_expired_pending_transactions',
      );
      return response as int? ?? 0;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[PendingTransaction] cleanupExpired RPC failed: $e');
      }
      return 0;
    }
  }

  Future<List<PendingTransactionModel>> confirmAll(
    String ledgerId,
    String userId,
  ) async {
    final response = await _client
        .from('pending_transactions')
        .update({
          'status': 'confirmed',
          'updated_at': DateTimeUtils.nowUtcIso(),
        })
        .eq('ledger_id', ledgerId)
        .eq('user_id', userId)
        .eq('status', 'pending')
        .select();

    return (response as List)
        .map((json) => PendingTransactionModel.fromJson(json))
        .toList();
  }

  Future<void> rejectAll(String ledgerId, String userId) async {
    await _client
        .from('pending_transactions')
        .update({'status': 'rejected', 'updated_at': DateTimeUtils.nowUtcIso()})
        .eq('ledger_id', ledgerId)
        .eq('user_id', userId)
        .eq('status', 'pending');
  }

  RealtimeChannel subscribePendingTransactions({
    required String ledgerId,
    required String userId,
    required void Function() onTableChanged,
  }) {
    return _client
        .channel('pending_transactions_changes_${ledgerId}_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'house',
          table: 'pending_transactions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'ledger_id',
            value: ledgerId,
          ),
          callback: (payload) {
            final recordData = payload.newRecord;
            if (recordData['user_id'] != userId) {
              return;
            }
            onTableChanged();
          },
        )
        .subscribe();
  }

  Future<T> _retry<T>(Future<T> Function() block, {int maxAttempts = 3}) async {
    for (var i = 0; i < maxAttempts; i++) {
      try {
        return await block();
      } catch (e) {
        if (i == maxAttempts - 1) rethrow;
        await Future.delayed(
          Duration(milliseconds: 1000 * (i + 1)),
        ); // 1s, 2s, 3s...
      }
    }
    throw Exception('Unreachable');
  }

  Future<void> markAllAsViewed(String ledgerId, String userId) async {
    await _client
        .from('pending_transactions')
        .update({'is_viewed': true, 'updated_at': DateTimeUtils.nowUtcIso()})
        .eq('ledger_id', ledgerId)
        .eq('user_id', userId)
        .eq('is_viewed', false);
  }

  /// duplicateHash로 원본 중복 거래 찾기
  Future<PendingTransactionModel?> findOriginalDuplicate({
    required String ledgerId,
    required String userId,
    required String duplicateHash,
    required String currentTransactionId,
  }) async {
    try {
      final response = await _client
          .from('pending_transactions')
          .select()
          .eq('ledger_id', ledgerId)
          .eq('user_id', userId)
          .eq('duplicate_hash', duplicateHash)
          .neq('id', currentTransactionId)
          .order('created_at', ascending: true)
          .limit(1);

      if ((response as List).isEmpty) return null;
      return PendingTransactionModel.fromJson(response.first);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[PendingTransaction] findOriginalDuplicate failed: $e');
      }
      return null;
    }
  }
}
