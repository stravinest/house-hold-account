import '../../../../config/supabase_config.dart';
import '../../domain/entities/budget.dart';

class BudgetRepository {
  final _client = SupabaseConfig.client;

  // 예산 목록 조회
  Future<List<Budget>> getBudgets({
    required String ledgerId,
    required int year,
    required int month,
  }) async {
    final response = await _client
        .from('budgets')
        .select('*, categories(name, icon, color)')
        .eq('ledger_id', ledgerId)
        .eq('year', year)
        .eq('month', month)
        .order('created_at');

    return (response as List).map((json) => Budget.fromJson(json)).toList();
  }

  // 예산 생성
  Future<Budget> createBudget({
    required String ledgerId,
    String? categoryId,
    required int amount,
    required int year,
    required int month,
  }) async {
    final response = await _client
        .from('budgets')
        .insert({
          'ledger_id': ledgerId,
          'category_id': categoryId,
          'amount': amount,
          'year': year,
          'month': month,
        })
        .select('*, categories(name, icon, color)')
        .single();

    return Budget.fromJson(response);
  }

  // 예산 수정
  Future<Budget> updateBudget({
    required String id,
    int? amount,
  }) async {
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (amount != null) updates['amount'] = amount;

    final response = await _client
        .from('budgets')
        .update(updates)
        .eq('id', id)
        .select('*, categories(name, icon, color)')
        .single();

    return Budget.fromJson(response);
  }

  // 예산 삭제
  Future<void> deleteBudget(String id) async {
    await _client.from('budgets').delete().eq('id', id);
  }

  // 예산 대비 지출 현황 조회
  Future<Map<String, int>> getBudgetSpent({
    required String ledgerId,
    required int year,
    required int month,
  }) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0);

    final response = await _client
        .from('transactions')
        .select('amount, category_id')
        .eq('ledger_id', ledgerId)
        .eq('type', 'expense')
        .gte('date', startDate.toIso8601String().split('T').first)
        .lte('date', endDate.toIso8601String().split('T').first);

    final Map<String, int> spent = {'total': 0};

    for (final row in response as List) {
      final amount = row['amount'] as int;
      final categoryId = row['category_id'] as String?;

      spent['total'] = (spent['total'] ?? 0) + amount;

      if (categoryId != null) {
        spent[categoryId] = (spent[categoryId] ?? 0) + amount;
      }
    }

    return spent;
  }

  // 총 예산 조회 또는 생성
  Future<Budget?> getTotalBudget({
    required String ledgerId,
    required int year,
    required int month,
  }) async {
    final response = await _client
        .from('budgets')
        .select('*, categories(name, icon, color)')
        .eq('ledger_id', ledgerId)
        .eq('year', year)
        .eq('month', month)
        .isFilter('category_id', null)
        .maybeSingle();

    if (response == null) return null;
    return Budget.fromJson(response);
  }

  // 카테고리별 예산 조회
  Future<Budget?> getCategoryBudget({
    required String ledgerId,
    required String categoryId,
    required int year,
    required int month,
  }) async {
    final response = await _client
        .from('budgets')
        .select('*, categories(name, icon, color)')
        .eq('ledger_id', ledgerId)
        .eq('category_id', categoryId)
        .eq('year', year)
        .eq('month', month)
        .maybeSingle();

    if (response == null) return null;
    return Budget.fromJson(response);
  }

  // 이전 달 예산 복사
  Future<void> copyBudgetFromPreviousMonth({
    required String ledgerId,
    required int year,
    required int month,
  }) async {
    // 이전 달 계산
    final prevMonth = month == 1 ? 12 : month - 1;
    final prevYear = month == 1 ? year - 1 : year;

    // 이전 달 예산 조회
    final prevBudgets = await getBudgets(
      ledgerId: ledgerId,
      year: prevYear,
      month: prevMonth,
    );

    // 현재 달에 복사
    for (final budget in prevBudgets) {
      await createBudget(
        ledgerId: ledgerId,
        categoryId: budget.categoryId,
        amount: budget.amount,
        year: year,
        month: month,
      );
    }
  }
}
