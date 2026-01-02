import '../../../../config/supabase_config.dart';

class StatisticsRepository {
  final _client = SupabaseConfig.client;

  // 카테고리별 지출/수입 합계
  Future<List<CategoryStatistics>> getCategoryStatistics({
    required String ledgerId,
    required int year,
    required int month,
    required String type, // 'income' or 'expense'
  }) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0);

    final response = await _client
        .from('transactions')
        .select('amount, category_id, categories(name, icon, color)')
        .eq('ledger_id', ledgerId)
        .eq('type', type)
        .gte('date', startDate.toIso8601String().split('T').first)
        .lte('date', endDate.toIso8601String().split('T').first);

    // 카테고리별로 그룹화
    final Map<String, CategoryStatistics> grouped = {};

    for (final row in response as List) {
      final categoryId = row['category_id'] as String;
      final amount = row['amount'] as int;
      final category = row['categories'] as Map<String, dynamic>?;

      if (grouped.containsKey(categoryId)) {
        grouped[categoryId] = grouped[categoryId]!.copyWith(
          amount: grouped[categoryId]!.amount + amount,
        );
      } else {
        grouped[categoryId] = CategoryStatistics(
          categoryId: categoryId,
          categoryName: category?['name'] as String? ?? '미분류',
          categoryIcon: category?['icon'] as String? ?? '📦',
          categoryColor: category?['color'] as String? ?? '#6750A4',
          amount: amount,
        );
      }
    }

    // 금액 기준 내림차순 정렬
    final result = grouped.values.toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    return result;
  }

  // 월별 수입/지출 추세 (최근 6개월)
  Future<List<MonthlyStatistics>> getMonthlyTrend({
    required String ledgerId,
    int months = 6,
  }) async {
    final now = DateTime.now();
    final results = <MonthlyStatistics>[];

    for (int i = months - 1; i >= 0; i--) {
      final targetDate = DateTime(now.year, now.month - i, 1);
      final startDate = DateTime(targetDate.year, targetDate.month, 1);
      final endDate = DateTime(targetDate.year, targetDate.month + 1, 0);

      final response = await _client
          .from('transactions')
          .select('amount, type')
          .eq('ledger_id', ledgerId)
          .gte('date', startDate.toIso8601String().split('T').first)
          .lte('date', endDate.toIso8601String().split('T').first);

      int income = 0;
      int expense = 0;

      for (final row in response as List) {
        final amount = row['amount'] as int;
        final type = row['type'] as String;

        if (type == 'income') {
          income += amount;
        } else {
          expense += amount;
        }
      }

      results.add(MonthlyStatistics(
        year: targetDate.year,
        month: targetDate.month,
        income: income,
        expense: expense,
      ));
    }

    return results;
  }

  // 일별 지출 추세 (현재 월)
  Future<List<DailyStatistics>> getDailyTrend({
    required String ledgerId,
    required int year,
    required int month,
  }) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0);

    final response = await _client
        .from('transactions')
        .select('amount, type, date')
        .eq('ledger_id', ledgerId)
        .gte('date', startDate.toIso8601String().split('T').first)
        .lte('date', endDate.toIso8601String().split('T').first)
        .order('date');

    final Map<int, DailyStatistics> grouped = {};

    // 모든 날짜 초기화
    for (int day = 1; day <= endDate.day; day++) {
      grouped[day] = DailyStatistics(
        day: day,
        income: 0,
        expense: 0,
      );
    }

    for (final row in response as List) {
      final dateStr = row['date'] as String;
      final date = DateTime.parse(dateStr);
      final day = date.day;
      final amount = row['amount'] as int;
      final type = row['type'] as String;

      if (type == 'income') {
        grouped[day] = grouped[day]!.copyWith(
          income: grouped[day]!.income + amount,
        );
      } else {
        grouped[day] = grouped[day]!.copyWith(
          expense: grouped[day]!.expense + amount,
        );
      }
    }

    return grouped.values.toList();
  }
}

// 카테고리별 통계 모델
class CategoryStatistics {
  final String categoryId;
  final String categoryName;
  final String categoryIcon;
  final String categoryColor;
  final int amount;

  const CategoryStatistics({
    required this.categoryId,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColor,
    required this.amount,
  });

  CategoryStatistics copyWith({
    String? categoryId,
    String? categoryName,
    String? categoryIcon,
    String? categoryColor,
    int? amount,
  }) {
    return CategoryStatistics(
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      categoryColor: categoryColor ?? this.categoryColor,
      amount: amount ?? this.amount,
    );
  }
}

// 월별 통계 모델
class MonthlyStatistics {
  final int year;
  final int month;
  final int income;
  final int expense;

  const MonthlyStatistics({
    required this.year,
    required this.month,
    required this.income,
    required this.expense,
  });

  int get balance => income - expense;

  String get monthLabel => '$month월';
}

// 일별 통계 모델
class DailyStatistics {
  final int day;
  final int income;
  final int expense;

  const DailyStatistics({
    required this.day,
    required this.income,
    required this.expense,
  });

  DailyStatistics copyWith({
    int? day,
    int? income,
    int? expense,
  }) {
    return DailyStatistics(
      day: day ?? this.day,
      income: income ?? this.income,
      expense: expense ?? this.expense,
    );
  }
}
