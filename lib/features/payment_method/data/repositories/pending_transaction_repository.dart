import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../config/supabase_config.dart';
import '../../domain/entities/pending_transaction.dart';
import '../models/pending_transaction_model.dart';

class PendingTransactionRepository {
  final _client = SupabaseConfig.client;

  Future<List<PendingTransactionModel>> getPendingTransactions(
    String ledgerId, {
    PendingTransactionStatus? status,
  }) async {
    return _retry(() async {
      var query = _client
          .from('pending_transactions')
          .select()
          .eq('ledger_id', ledgerId);

      if (status != null) {
        query = query.eq('status', status.toJson());
      }

      final response = await query.order('source_timestamp', ascending: false);

      return (response as List)
          .map((json) => PendingTransactionModel.fromJson(json))
          .toList();
    });
  }

  Future<int> getPendingCount(String ledgerId) async {
    final response = await _client
        .from('pending_transactions')
        .select()
        .eq('ledger_id', ledgerId)
        .eq('status', 'pending');

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
    PendingTransactionStatus? status,
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
      status: status,
    );

    return _retry(() async {
      final response = await _client
          .from('pending_transactions')
          .insert(data)
          .select()
          .single();

      return PendingTransactionModel.fromJson(response);
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
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
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
    PendingTransactionStatus status,
  ) async {
    await _client
        .from('pending_transactions')
        .delete()
        .eq('ledger_id', ledgerId)
        .eq('status', status.toJson());
  }

  Future<void> deleteAllRejected(String ledgerId) async {
    await deleteAllByStatus(ledgerId, PendingTransactionStatus.rejected);
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
    } catch (_) {
      return false;
    }
  }

  Future<int> cleanupExpired() async {
    try {
      final response = await _client.rpc(
        'cleanup_expired_pending_transactions',
      );
      return response as int? ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<List<PendingTransactionModel>> confirmAll(String ledgerId) async {
    final response = await _client
        .from('pending_transactions')
        .update({
          'status': 'confirmed',
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('ledger_id', ledgerId)
        .eq('status', 'pending')
        .select();

    return (response as List)
        .map((json) => PendingTransactionModel.fromJson(json))
        .toList();
  }

  Future<void> rejectAll(String ledgerId) async {
    await _client
        .from('pending_transactions')
        .update({
          'status': 'rejected',
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('ledger_id', ledgerId)
        .eq('status', 'pending');
  }

  RealtimeChannel subscribePendingTransactions({
    required String ledgerId,
    required void Function() onTableChanged,
  }) {
    return _client
        .channel('pending_transactions_changes_$ledgerId')
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
}
