import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../config/supabase_config.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../models/transaction_model.dart';

class TransactionRepository {
  final SupabaseClient _client;

  TransactionRepository({SupabaseClient? client})
      : _client = client ?? SupabaseConfig.client;

  // 날짜별 거래 조회
  Future<List<TransactionModel>> getTransactionsByDate({
    required String ledgerId,
    required DateTime date,
  }) async {
    final dateStr = date.toIso8601String().split('T').first;

    final response = await _client
        .from('transactions')
        .select(
          '*, categories(name, icon, color), profiles(display_name, email, color), payment_methods(name), fixed_expense_categories(name, icon, color), recurring_templates(start_date)',
        )
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
        .select(
          '*, categories(name, icon, color), profiles(display_name, email, color), payment_methods(name), fixed_expense_categories(name, icon, color), recurring_templates(start_date)',
        )
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
    String? categoryId,
    String? paymentMethodId,
    required int amount,
    required String type,
    required DateTime date,
    String? title,
    String? memo,
    String? imageUrl,
    bool isRecurring = false,
    String? recurringType,
    DateTime? recurringEndDate,
    bool isFixedExpense = false,
    String? fixedExpenseCategoryId,
    bool isAsset = false,
    DateTime? maturityDate,
    String? sourceType,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Login required');

    final data = TransactionModel.toCreateJson(
      ledgerId: ledgerId,
      categoryId: categoryId,
      userId: userId,
      paymentMethodId: paymentMethodId,
      amount: amount,
      type: type,
      date: date,
      title: title,
      memo: memo,
      imageUrl: imageUrl,
      isRecurring: isRecurring,
      recurringType: recurringType,
      recurringEndDate: recurringEndDate,
      isFixedExpense: isFixedExpense,
      fixedExpenseCategoryId: fixedExpenseCategoryId,
      isAsset: isAsset,
      maturityDate: maturityDate,
      sourceType: sourceType,
    );

    final response = await _client
        .from('transactions')
        .insert(data)
        .select(
          '*, categories(name, icon, color), profiles(display_name, email, color), payment_methods(name), fixed_expense_categories(name, icon, color), recurring_templates(start_date)',
        )
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
    String? title,
    String? memo,
    String? imageUrl,
    bool? isRecurring,
    String? recurringType,
    DateTime? recurringEndDate,
    bool? isFixedExpense,
    String? fixedExpenseCategoryId,
  }) async {
    final updates = <String, dynamic>{'updated_at': DateTimeUtils.nowUtcIso()};
    if (categoryId != null) updates['category_id'] = categoryId;
    if (paymentMethodId != null) updates['payment_method_id'] = paymentMethodId;
    if (amount != null) updates['amount'] = amount;
    if (type != null) updates['type'] = type;
    if (date != null) updates['date'] = date.toIso8601String().split('T').first;
    if (title != null) updates['title'] = title;
    if (memo != null) updates['memo'] = memo;
    if (imageUrl != null) updates['image_url'] = imageUrl;
    if (isRecurring != null) updates['is_recurring'] = isRecurring;
    if (recurringType != null) updates['recurring_type'] = recurringType;
    if (recurringEndDate != null) {
      updates['recurring_end_date'] = recurringEndDate
          .toIso8601String()
          .split('T')
          .first;
    }
    if (isFixedExpense != null) updates['is_fixed_expense'] = isFixedExpense;
    if (fixedExpenseCategoryId != null) {
      updates['fixed_expense_category_id'] = fixedExpenseCategoryId;
    }

    final response = await _client
        .from('transactions')
        .update(updates)
        .eq('id', id)
        .select(
          '*, categories(name, icon, color), profiles(display_name, email, color), payment_methods(name), fixed_expense_categories(name, icon, color), recurring_templates(start_date)',
        )
        .single();

    return TransactionModel.fromJson(response);
  }

  // 거래 삭제
  Future<void> deleteTransaction(String id) async {
    await _client.from('transactions').delete().eq('id', id);
  }

  // 월별 합계 조회 (사용자별 데이터 포함)
  Future<Map<String, dynamic>> getMonthlyTotal({
    required String ledgerId,
    required int year,
    required int month,
    bool excludeFixedExpense = false,
  }) async {
    try {
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0);
      final startStr = startDate.toIso8601String().split('T').first;
      final endStr = endDate.toIso8601String().split('T').first;

      // transactions와 profiles를 조인하여 user_id, display_name, color 조회 (필요한 컬럼만 선택하여 최적화)
      // is_fixed_expense 포함하여 고정비 필터링 지원
      final response = await _client
          .from('transactions')
          .select(
            'amount, type, user_id, is_fixed_expense, profiles!user_id(display_name, color)',
          )
          .eq('ledger_id', ledgerId)
          .gte('date', startStr)
          .lte('date', endStr)
          .order('date', ascending: true);

      int totalIncome = 0;
      int totalExpense = 0;
      final userTotals = <String, Map<String, dynamic>>{};

      for (final transaction in response as List) {
        final userId = transaction['user_id'] as String;
        final amount = transaction['amount'] as int;
        final type = transaction['type'] as String;
        final isFixedExpense = transaction['is_fixed_expense'] as bool? ?? false;

        // profile에서 display_name과 color 가져오기
        final profileData = transaction['profiles'];
        final displayName =
            (profileData != null && profileData['display_name'] != null)
            ? profileData['display_name'] as String
            : 'User';
        final userColor = (profileData != null && profileData['color'] != null)
            ? profileData['color'] as String
            : '#A8D8EA';

        // 사용자별 데이터 초기화
        userTotals.putIfAbsent(
          userId,
          () => {
            'displayName': displayName,
            'income': 0,
            'expense': 0,
            'asset': 0,
            'color': userColor,
          },
        );

        // 금액 누적 (고정비 제외 옵션 적용)
        if (type == 'income') {
          userTotals[userId]!['income'] =
              (userTotals[userId]!['income'] as int) + amount;
          totalIncome += amount;
        } else if (type == 'asset') {
          userTotals[userId]!['asset'] =
              (userTotals[userId]!['asset'] as int) + amount;
        } else {
          // 고정비 제외 옵션이 켜져있고, 해당 거래가 고정비인 경우 지출에서 제외
          if (excludeFixedExpense && isFixedExpense) {
            continue;
          }
          userTotals[userId]!['expense'] =
              (userTotals[userId]!['expense'] as int) + amount;
          totalExpense += amount;
        }
      }

      return {
        'income': totalIncome,
        'expense': totalExpense,
        'balance': totalIncome - totalExpense,
        'users': userTotals,
      };
    } catch (e) {
      // 에러 처리 원칙에 따라 에러를 전파
      rethrow;
    }
  }

  // 일별 합계 조회 (사용자별 데이터 포함)
  Future<Map<DateTime, Map<String, dynamic>>> getDailyTotals({
    required String ledgerId,
    required int year,
    required int month,
    bool excludeFixedExpense = false,
  }) async {
    try {
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0);
      final startStr = startDate.toIso8601String().split('T').first;
      final endStr = endDate.toIso8601String().split('T').first;

      // transactions와 profiles를 조인하여 user_id, display_name, color 조회 (필요한 컬럼만 선택하여 최적화)
      // is_fixed_expense 포함하여 고정비 필터링 지원
      final response = await _client
          .from('transactions')
          .select(
            'date, amount, type, user_id, is_fixed_expense, profiles!user_id(display_name, color)',
          )
          .eq('ledger_id', ledgerId)
          .gte('date', startStr)
          .lte('date', endStr)
          .order('date', ascending: true);

      final dailyTotals = <DateTime, Map<String, dynamic>>{};

      for (final transaction in response as List) {
        final dateStr = transaction['date'] as String;
        final date = DateTime.parse(dateStr);
        final dateKey = DateTime(date.year, date.month, date.day);

        final userId = transaction['user_id'] as String;
        final amount = transaction['amount'] as int;
        final type = transaction['type'] as String;
        final isFixedExpense = transaction['is_fixed_expense'] as bool? ?? false;

        // profile에서 display_name과 color 가져오기
        final profileData = transaction['profiles'];
        final displayName =
            (profileData != null && profileData['display_name'] != null)
            ? profileData['display_name'] as String
            : 'User';
        final userColor = (profileData != null && profileData['color'] != null)
            ? profileData['color'] as String
            : '#A8D8EA';

        // 날짜별 데이터 초기화
        dailyTotals.putIfAbsent(
          dateKey,
          () => {
            'users': <String, Map<String, dynamic>>{},
            'totalIncome': 0,
            'totalExpense': 0,
          },
        );

        final dayData = dailyTotals[dateKey]!;
        final users = dayData['users'] as Map<String, Map<String, dynamic>>;

        // 사용자별 데이터 초기화
        users.putIfAbsent(
          userId,
          () => {
            'displayName': displayName,
            'income': 0,
            'expense': 0,
            'asset': 0,
            'color': userColor,
          },
        );

        // 금액 누적 (고정비 제외 시 합계에서만 제외, 캘린더 dot 표시는 유지)
        if (type == 'income') {
          users[userId]!['income'] = (users[userId]!['income'] as int) + amount;
          dayData['totalIncome'] = (dayData['totalIncome'] as int) + amount;
        } else if (type == 'asset') {
          users[userId]!['asset'] = (users[userId]!['asset'] as int) + amount;
        } else {
          // 고정비 제외 옵션이 켜져 있어도 사용자별 지출은 누적 (dot 표시용)
          users[userId]!['expense'] =
              (users[userId]!['expense'] as int) + amount;
          // 합계에서만 고정비 제외
          if (!(excludeFixedExpense && isFixedExpense)) {
            dayData['totalExpense'] = (dayData['totalExpense'] as int) + amount;
          }
        }
      }

      return dailyTotals;
    } catch (e) {
      // 에러 처리 원칙에 따라 에러를 전파
      rethrow;
    }
  }

  // 실시간 구독
  RealtimeChannel subscribeTransactions({
    required String ledgerId,
    required void Function() onUpdate,
  }) {
    final channel = _client.channel('transactions_$ledgerId');

    return channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'house',
          table: 'transactions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'ledger_id',
            value: ledgerId,
          ),
          callback: (payload) {
            if (kDebugMode) {
              debugPrint('Realtime change detected for ledger: $ledgerId');
            }
            onUpdate();
          },
        )
        .subscribe((status, [error]) {
          if (status == RealtimeSubscribeStatus.channelError ||
              status == RealtimeSubscribeStatus.timedOut) {
            debugPrint(
              'Realtime subscription error for ledger $ledgerId: $status, $error',
            );
          }
        });
  }

  // 반복 거래 템플릿 생성
  Future<Map<String, dynamic>> createRecurringTemplate({
    required String ledgerId,
    String? categoryId,
    String? paymentMethodId,
    required int amount,
    required String type,
    required DateTime startDate,
    DateTime? endDate,
    required String recurringType,
    String? title,
    String? memo,
    bool isFixedExpense = false,
    String? fixedExpenseCategoryId,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Login required');

    // 반복 실행일 계산 (매월/매년 반복 시)
    final recurringDay = startDate.day;

    final data = {
      'ledger_id': ledgerId,
      'user_id': userId,
      'category_id': categoryId,
      'payment_method_id': paymentMethodId,
      'amount': amount,
      'type': type,
      'start_date': startDate.toIso8601String().split('T').first,
      'end_date': endDate?.toIso8601String().split('T').first,
      'recurring_type': recurringType,
      'recurring_day': recurringDay,
      'title': title,
      'memo': memo,
      'is_fixed_expense': isFixedExpense,
      'fixed_expense_category_id': fixedExpenseCategoryId,
      'is_active': true,
    };

    final response = await _client
        .from('recurring_templates')
        .insert(data)
        .select()
        .single();

    return response;
  }

  // 반복 거래 자동 생성 함수 호출 (템플릿 등록 직후 실행)
  Future<void> generateRecurringTransactions() async {
    await _client.rpc('generate_recurring_transactions');
  }

  // 반복 거래 템플릿 목록 조회
  Future<List<Map<String, dynamic>>> getRecurringTemplates({
    required String ledgerId,
  }) async {
    final response = await _client
        .from('recurring_templates')
        .select(
          '*, categories(name, icon, color), payment_methods(name), fixed_expense_categories(name, icon, color)',
        )
        .eq('ledger_id', ledgerId)
        .eq('is_active', true)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // 반복 거래 템플릿 삭제
  Future<void> deleteRecurringTemplate(String templateId) async {
    await _client
        .from('recurring_templates')
        .delete()
        .eq('id', templateId);
  }

  // 반복 거래 템플릿 활성화/비활성화 토글
  Future<void> toggleRecurringTemplate(String templateId, bool isActive) async {
    await _client
        .from('recurring_templates')
        .update({
          'is_active': isActive,
          'updated_at': DateTimeUtils.nowUtcIso(),
        })
        .eq('id', templateId);
  }

  // 반복 거래 템플릿 수정
  Future<void> updateRecurringTemplate(
    String templateId, {
    int? amount,
    String? title,
    String? memo,
    String? recurringType,
    DateTime? endDate,
    bool clearEndDate = false,
    String? categoryId,
    String? paymentMethodId,
    String? fixedExpenseCategoryId,
  }) async {
    final updates = <String, dynamic>{
      'updated_at': DateTimeUtils.nowUtcIso(),
    };
    if (amount != null) updates['amount'] = amount;
    if (title != null) updates['title'] = title;
    if (memo != null) updates['memo'] = memo;
    if (recurringType != null) updates['recurring_type'] = recurringType;
    if (endDate != null) {
      updates['end_date'] = endDate.toIso8601String().split('T').first;
    } else if (clearEndDate) {
      updates['end_date'] = null;
    }
    if (categoryId != null) updates['category_id'] = categoryId;
    if (paymentMethodId != null) {
      updates['payment_method_id'] = paymentMethodId;
    }
    if (fixedExpenseCategoryId != null) {
      updates['fixed_expense_category_id'] = fixedExpenseCategoryId;
    }

    await _client
        .from('recurring_templates')
        .update(updates)
        .eq('id', templateId);
  }

  // 반복 거래 템플릿 목록 조회 (활성 + 비활성 모두)
  Future<List<Map<String, dynamic>>> getAllRecurringTemplates({
    required String ledgerId,
  }) async {
    final response = await _client
        .from('recurring_templates')
        .select(
          '*, categories(name, icon, color), payment_methods(name), fixed_expense_categories(name, icon, color)',
        )
        .eq('ledger_id', ledgerId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // 거래 삭제 + 템플릿 비활성화 (이후 모든 반복 중단)
  // 템플릿 비활성화를 먼저 실행하여, 거래 삭제 실패 시에도 재생성 방지
  Future<void> deleteTransactionAndDeactivateTemplate(
    String transactionId,
    String templateId,
  ) async {
    await _client
        .from('recurring_templates')
        .update({
          'is_active': false,
          'updated_at': DateTimeUtils.nowUtcIso(),
        })
        .eq('id', templateId);
    await _client.from('transactions').delete().eq('id', transactionId);
  }
}
