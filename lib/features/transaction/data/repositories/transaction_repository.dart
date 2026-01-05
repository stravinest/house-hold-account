import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../config/supabase_config.dart';
import '../models/transaction_model.dart';

class TransactionRepository {
  final _client = SupabaseConfig.client;

  // 날짜별 거래 조회
  Future<List<TransactionModel>> getTransactionsByDate({
    required String ledgerId,
    required DateTime date,
  }) async {
    final dateStr = date.toIso8601String().split('T').first;

    final response = await _client
        .from('transactions')
        .select('*, categories(name, icon, color), profiles(display_name), payment_methods(name)')
        .eq('ledger_id', ledgerId)
        .eq('date', dateStr)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => TransactionModel.fromJson(json))
        .toList();
  }

  // 기간별 거래 조회
  Future<List<TransactionModel>> getTransactionsByDateRange({
    required String ledgerId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final startStr = startDate.toIso8601String().split('T').first;
    final endStr = endDate.toIso8601String().split('T').first;

    final response = await _client
        .from('transactions')
        .select('*, categories(name, icon, color), profiles(display_name), payment_methods(name)')
        .eq('ledger_id', ledgerId)
        .gte('date', startStr)
        .lte('date', endStr)
        .order('date', ascending: false)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => TransactionModel.fromJson(json))
        .toList();
  }

  // 월별 거래 조회
  Future<List<TransactionModel>> getTransactionsByMonth({
    required String ledgerId,
    required int year,
    required int month,
  }) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0);

    return getTransactionsByDateRange(
      ledgerId: ledgerId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  // 거래 생성
  Future<TransactionModel> createTransaction({
    required String ledgerId,
    required String categoryId,
    String? paymentMethodId,
    required int amount,
    required String type,
    required DateTime date,
    String? memo,
    String? imageUrl,
    bool isRecurring = false,
    String? recurringType,
    DateTime? recurringEndDate,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('로그인이 필요합니다');

    final data = TransactionModel.toCreateJson(
      ledgerId: ledgerId,
      categoryId: categoryId,
      userId: userId,
      paymentMethodId: paymentMethodId,
      amount: amount,
      type: type,
      date: date,
      memo: memo,
      imageUrl: imageUrl,
      isRecurring: isRecurring,
      recurringType: recurringType,
      recurringEndDate: recurringEndDate,
    );

    final response = await _client
        .from('transactions')
        .insert(data)
        .select('*, categories(name, icon, color), profiles(display_name), payment_methods(name)')
        .single();

    return TransactionModel.fromJson(response);
  }

  // 거래 수정
  Future<TransactionModel> updateTransaction({
    required String id,
    String? categoryId,
    String? paymentMethodId,
    int? amount,
    String? type,
    DateTime? date,
    String? memo,
    String? imageUrl,
    bool? isRecurring,
    String? recurringType,
    DateTime? recurringEndDate,
  }) async {
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (categoryId != null) updates['category_id'] = categoryId;
    if (paymentMethodId != null) updates['payment_method_id'] = paymentMethodId;
    if (amount != null) updates['amount'] = amount;
    if (type != null) updates['type'] = type;
    if (date != null) updates['date'] = date.toIso8601String().split('T').first;
    if (memo != null) updates['memo'] = memo;
    if (imageUrl != null) updates['image_url'] = imageUrl;
    if (isRecurring != null) updates['is_recurring'] = isRecurring;
    if (recurringType != null) updates['recurring_type'] = recurringType;
    if (recurringEndDate != null) {
      updates['recurring_end_date'] =
          recurringEndDate.toIso8601String().split('T').first;
    }

    final response = await _client
        .from('transactions')
        .update(updates)
        .eq('id', id)
        .select('*, categories(name, icon, color), profiles(display_name), payment_methods(name)')
        .single();

    return TransactionModel.fromJson(response);
  }

  // 거래 삭제
  Future<void> deleteTransaction(String id) async {
    await _client.from('transactions').delete().eq('id', id);
  }

  // 월별 합계 조회
  Future<Map<String, int>> getMonthlyTotal({
    required String ledgerId,
    required int year,
    required int month,
  }) async {
    final transactions = await getTransactionsByMonth(
      ledgerId: ledgerId,
      year: year,
      month: month,
    );

    int income = 0;
    int expense = 0;

    for (final t in transactions) {
      if (t.isIncome) {
        income += t.amount;
      } else {
        expense += t.amount;
      }
    }

    return {
      'income': income,
      'expense': expense,
      'balance': income - expense,
    };
  }

  // 일별 합계 조회
  Future<Map<DateTime, Map<String, int>>> getDailyTotals({
    required String ledgerId,
    required int year,
    required int month,
  }) async {
    final transactions = await getTransactionsByMonth(
      ledgerId: ledgerId,
      year: year,
      month: month,
    );

    final dailyTotals = <DateTime, Map<String, int>>{};

    for (final t in transactions) {
      final date = DateTime(t.date.year, t.date.month, t.date.day);
      dailyTotals[date] ??= {'income': 0, 'expense': 0};

      if (t.isIncome) {
        dailyTotals[date]!['income'] =
            (dailyTotals[date]!['income'] ?? 0) + t.amount;
      } else {
        dailyTotals[date]!['expense'] =
            (dailyTotals[date]!['expense'] ?? 0) + t.amount;
      }
    }

    return dailyTotals;
  }

  // 실시간 구독
  RealtimeChannel subscribeTransactions({
    required String ledgerId,
    required void Function() onUpdate,
  }) {
    return _client
        .channel('transactions_$ledgerId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'transactions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'ledger_id',
            value: ledgerId,
          ),
          callback: (payload) => onUpdate(),
        )
        .subscribe();
  }
}
