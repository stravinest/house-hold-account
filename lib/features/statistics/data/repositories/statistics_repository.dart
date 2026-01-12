import '../../../../config/supabase_config.dart';
import '../../domain/entities/statistics_entities.dart';
import '../../presentation/widgets/common/expense_type_filter.dart';

class StatisticsRepository {
  final _client = SupabaseConfig.client;

  // 카테고리별 지출/수입 합계
  Future<List<CategoryStatistics>> getCategoryStatistics({
    required String ledgerId,
    required int year,
    required int month,
    required String type, // 'income' or 'expense'
    ExpenseTypeFilter? expenseTypeFilter,
    bool? includeFixedExpenseInExpense, // 고정비를 지출에 편입할지 여부
  }) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0);

    // 고정비 필터일 경우 고정비 카테고리를 사용
    final useFixedExpenseCategory =
        type == 'expense' && expenseTypeFilter == ExpenseTypeFilter.fixed;

    var query = _client
        .from('transactions')
        .select(
          useFixedExpenseCategory
              ? 'amount, fixed_expense_category_id, is_fixed_expense, fixed_expense_categories(name, icon, color)'
              : 'amount, category_id, is_fixed_expense, categories(name, icon, color)',
        )
        .eq('ledger_id', ledgerId)
        .eq('type', type)
        .gte('date', startDate.toIso8601String().split('T').first)
        .lte('date', endDate.toIso8601String().split('T').first);

    // 지출일 경우에만 고정비/변동비 필터 적용
    if (type == 'expense' && expenseTypeFilter != null) {
      switch (expenseTypeFilter) {
        case ExpenseTypeFilter.fixed:
          query = query.eq('is_fixed_expense', true);
          break;
        case ExpenseTypeFilter.variable:
          query = query.eq('is_fixed_expense', false);
          break;
        case ExpenseTypeFilter.all:
          // 필터 없음
          break;
      }
    }

    final response = await query;

    // 카테고리별로 그룹화
    final Map<String, CategoryStatistics> grouped = {};

    for (final row in response as List) {
      final rowMap = row as Map<String, dynamic>;
      final amount = (rowMap['amount'] as num?)?.toInt() ?? 0;
      final isFixedExpense = rowMap['is_fixed_expense'] == true;

      // 고정비 필터일 때는 fixed_expense_category_id 사용
      final categoryId = useFixedExpenseCategory
          ? rowMap['fixed_expense_category_id']?.toString()
          : rowMap['category_id']?.toString();

      // 고정비 필터일 때는 fixed_expense_categories 사용
      final category = useFixedExpenseCategory
          ? rowMap['fixed_expense_categories'] as Map<String, dynamic>?
          : rowMap['categories'] as Map<String, dynamic>?;

      // 고정비 설정에 따라 그룹키 결정
      String groupKey;
      String categoryName;
      String categoryIcon;
      String categoryColor;

      // 지출 타입이고, 고정비 편입 설정이 true이고, 실제로 고정비인 경우
      // 단, ExpenseTypeFilter가 all일 때만 적용 (고정비/변동비 필터 시에는 원래 카테고리로 표시)
      if (type == 'expense' &&
          includeFixedExpenseInExpense == true &&
          isFixedExpense &&
          (expenseTypeFilter == null ||
              expenseTypeFilter == ExpenseTypeFilter.all)) {
        // 고정비를 별도 카테고리로 그룹화
        groupKey = '_fixed_expense_';
        categoryName = '고정비';
        categoryIcon = '📌';
        categoryColor = '#FF9800'; // 오렌지색
      } else {
        // 기존 로직: 원래 카테고리대로 그룹화
        groupKey = categoryId ?? '_uncategorized_';
        categoryName = '미지정';
        categoryIcon = '';
        categoryColor = '#9E9E9E';

        if (category != null) {
          categoryName = category['name']?.toString() ?? '미지정';
          categoryIcon = category['icon']?.toString() ?? '';
          categoryColor = category['color']?.toString() ?? '#9E9E9E';
        }
      }

      if (grouped.containsKey(groupKey)) {
        grouped[groupKey] = grouped[groupKey]!.copyWith(
          amount: grouped[groupKey]!.amount + amount,
        );
      } else {
        grouped[groupKey] = CategoryStatistics(
          categoryId: groupKey,
          categoryName: categoryName,
          categoryIcon: categoryIcon,
          categoryColor: categoryColor,
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
      int saving = 0;

      for (final row in response as List) {
        final amount = row['amount'] as int;
        final type = row['type'] as String;

        if (type == 'income') {
          income += amount;
        } else if (type == 'saving') {
          saving += amount;
        } else {
          expense += amount;
        }
      }

      results.add(
        MonthlyStatistics(
          year: targetDate.year,
          month: targetDate.month,
          income: income,
          expense: expense,
          saving: saving,
        ),
      );
    }

    return results;
  }

  // 월 비교 데이터 (현재 월 vs 지난 월)
  Future<MonthComparisonData> getMonthComparison({
    required String ledgerId,
    required int year,
    required int month,
    required String type,
    ExpenseTypeFilter? expenseTypeFilter,
  }) async {
    // 현재 월
    final currentStartDate = DateTime(year, month, 1);
    final currentEndDate = DateTime(year, month + 1, 0);

    // 지난 월
    final previousDate = DateTime(year, month - 1, 1);
    final previousStartDate = DateTime(
      previousDate.year,
      previousDate.month,
      1,
    );
    final previousEndDate = DateTime(
      previousDate.year,
      previousDate.month + 1,
      0,
    );

    // 현재 월 데이터 조회
    var currentQuery = _client
        .from('transactions')
        .select('amount, is_fixed_expense')
        .eq('ledger_id', ledgerId)
        .eq('type', type)
        .gte('date', currentStartDate.toIso8601String().split('T').first)
        .lte('date', currentEndDate.toIso8601String().split('T').first);

    // 지출일 경우에만 고정비/변동비 필터 적용
    if (type == 'expense' && expenseTypeFilter != null) {
      switch (expenseTypeFilter) {
        case ExpenseTypeFilter.fixed:
          currentQuery = currentQuery.eq('is_fixed_expense', true);
          break;
        case ExpenseTypeFilter.variable:
          currentQuery = currentQuery.eq('is_fixed_expense', false);
          break;
        case ExpenseTypeFilter.all:
          // 필터 없음
          break;
      }
    }

    // 지난 월 데이터 조회
    var previousQuery = _client
        .from('transactions')
        .select('amount, is_fixed_expense')
        .eq('ledger_id', ledgerId)
        .eq('type', type)
        .gte('date', previousStartDate.toIso8601String().split('T').first)
        .lte('date', previousEndDate.toIso8601String().split('T').first);

    // 지출일 경우에만 고정비/변동비 필터 적용
    if (type == 'expense' && expenseTypeFilter != null) {
      switch (expenseTypeFilter) {
        case ExpenseTypeFilter.fixed:
          previousQuery = previousQuery.eq('is_fixed_expense', true);
          break;
        case ExpenseTypeFilter.variable:
          previousQuery = previousQuery.eq('is_fixed_expense', false);
          break;
        case ExpenseTypeFilter.all:
          // 필터 없음
          break;
      }
    }

    final currentResponse = await currentQuery;
    final previousResponse = await previousQuery;

    int currentTotal = 0;
    int previousTotal = 0;

    for (final row in currentResponse as List) {
      currentTotal += (row['amount'] as num).toInt();
    }

    for (final row in previousResponse as List) {
      previousTotal += (row['amount'] as num).toInt();
    }

    final difference = currentTotal - previousTotal;
    final percentageChange = previousTotal > 0
        ? ((difference / previousTotal) * 100)
        : (currentTotal > 0 ? 100.0 : 0.0);

    return MonthComparisonData(
      currentTotal: currentTotal,
      previousTotal: previousTotal,
      difference: difference,
      percentageChange: percentageChange,
    );
  }

  // 결제수단별 통계
  Future<List<PaymentMethodStatistics>> getPaymentMethodStatistics({
    required String ledgerId,
    required int year,
    required int month,
    required String type,
  }) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0);

    final response = await _client
        .from('transactions')
        .select('amount, payment_method_id, payment_methods(name, icon, color)')
        .eq('ledger_id', ledgerId)
        .eq('type', type)
        .gte('date', startDate.toIso8601String().split('T').first)
        .lte('date', endDate.toIso8601String().split('T').first);

    // 결제수단별로 그룹화
    final Map<String, PaymentMethodStatistics> grouped = {};
    int totalAmount = 0;

    for (final row in response as List) {
      final rowMap = row as Map<String, dynamic>;
      final paymentMethodId = rowMap['payment_method_id']?.toString();
      final amount = (rowMap['amount'] as num?)?.toInt() ?? 0;
      final paymentMethod = rowMap['payment_methods'] as Map<String, dynamic>?;

      totalAmount += amount;

      // null인 경우 특수 키 사용
      final groupKey = paymentMethodId ?? '_no_payment_method_';

      // 결제수단 정보 추출
      String pmName = '미지정';
      String pmIcon = '';
      String pmColor = '#9E9E9E';

      if (paymentMethod != null) {
        pmName = paymentMethod['name']?.toString() ?? '미지정';
        pmIcon = paymentMethod['icon']?.toString() ?? '';
        pmColor = paymentMethod['color']?.toString() ?? '#9E9E9E';
      }

      if (grouped.containsKey(groupKey)) {
        grouped[groupKey] = grouped[groupKey]!.copyWith(
          amount: grouped[groupKey]!.amount + amount,
        );
      } else {
        grouped[groupKey] = PaymentMethodStatistics(
          paymentMethodId: groupKey,
          paymentMethodName: pmName,
          paymentMethodIcon: pmIcon,
          paymentMethodColor: pmColor,
          amount: amount,
          percentage: 0,
        );
      }
    }

    // 비율 계산 및 정렬
    final result = grouped.values.map((item) {
      final percentage = totalAmount > 0
          ? (item.amount / totalAmount) * 100
          : 0.0;
      return item.copyWith(percentage: percentage);
    }).toList()..sort((a, b) => b.amount.compareTo(a.amount));

    return result;
  }

  // 연별 추이 (최근 N년)
  Future<List<YearlyStatistics>> getYearlyTrend({
    required String ledgerId,
    int years = 3,
  }) async {
    final now = DateTime.now();
    final results = <YearlyStatistics>[];

    for (int i = years - 1; i >= 0; i--) {
      final targetYear = now.year - i;
      final startDate = DateTime(targetYear, 1, 1);
      final endDate = DateTime(targetYear, 12, 31);

      final response = await _client
          .from('transactions')
          .select('amount, type')
          .eq('ledger_id', ledgerId)
          .gte('date', startDate.toIso8601String().split('T').first)
          .lte('date', endDate.toIso8601String().split('T').first);

      int income = 0;
      int expense = 0;
      int saving = 0;

      for (final row in response as List) {
        final amount = (row['amount'] as num).toInt();
        final type = row['type'] as String;

        if (type == 'income') {
          income += amount;
        } else if (type == 'saving') {
          saving += amount;
        } else {
          expense += amount;
        }
      }

      results.add(
        YearlyStatistics(
          year: targetYear,
          income: income,
          expense: expense,
          saving: saving,
        ),
      );
    }

    return results;
  }

  // 월별 추이 (선택된 날짜 기준, 평균값 포함, 0원 제외)
  Future<TrendStatisticsData> getMonthlyTrendWithAverage({
    required String ledgerId,
    required DateTime baseDate,
    int months = 6,
  }) async {
    final results = <MonthlyStatistics>[];
    int totalIncome = 0;
    int totalExpense = 0;
    int totalSaving = 0;
    // 0원이 아닌 달의 개수 (평균 계산용)
    int incomeCount = 0;
    int expenseCount = 0;
    int savingCount = 0;

    for (int i = months - 1; i >= 0; i--) {
      final targetDate = DateTime(baseDate.year, baseDate.month - i, 1);
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
      int saving = 0;

      for (final row in response as List) {
        final amount = (row['amount'] as num).toInt();
        final type = row['type'] as String;

        if (type == 'income') {
          income += amount;
        } else if (type == 'saving') {
          saving += amount;
        } else {
          expense += amount;
        }
      }

      // 0원이 아닌 경우만 카운트
      if (income > 0) incomeCount++;
      if (expense > 0) expenseCount++;
      if (saving > 0) savingCount++;

      totalIncome += income;
      totalExpense += expense;
      totalSaving += saving;

      results.add(
        MonthlyStatistics(
          year: targetDate.year,
          month: targetDate.month,
          income: income,
          expense: expense,
          saving: saving,
        ),
      );
    }

    return TrendStatisticsData(
      data: results,
      averageIncome: incomeCount > 0 ? (totalIncome / incomeCount).round() : 0,
      averageExpense: expenseCount > 0
          ? (totalExpense / expenseCount).round()
          : 0,
      averageSaving: savingCount > 0 ? (totalSaving / savingCount).round() : 0,
    );
  }

  // 연별 추이 (선택된 날짜 기준, 평균값 포함, 0원 제외)
  Future<TrendStatisticsData> getYearlyTrendWithAverage({
    required String ledgerId,
    required DateTime baseDate,
    int years = 6,
  }) async {
    final results = <YearlyStatistics>[];
    int totalIncome = 0;
    int totalExpense = 0;
    int totalSaving = 0;
    // 0원이 아닌 연도의 개수 (평균 계산용)
    int incomeCount = 0;
    int expenseCount = 0;
    int savingCount = 0;

    for (int i = years - 1; i >= 0; i--) {
      final targetYear = baseDate.year - i;
      final startDate = DateTime(targetYear, 1, 1);
      final endDate = DateTime(targetYear, 12, 31);

      final response = await _client
          .from('transactions')
          .select('amount, type')
          .eq('ledger_id', ledgerId)
          .gte('date', startDate.toIso8601String().split('T').first)
          .lte('date', endDate.toIso8601String().split('T').first);

      int income = 0;
      int expense = 0;
      int saving = 0;

      for (final row in response as List) {
        final amount = (row['amount'] as num).toInt();
        final type = row['type'] as String;

        if (type == 'income') {
          income += amount;
        } else if (type == 'saving') {
          saving += amount;
        } else {
          expense += amount;
        }
      }

      // 0원이 아닌 경우만 카운트
      if (income > 0) incomeCount++;
      if (expense > 0) expenseCount++;
      if (saving > 0) savingCount++;

      totalIncome += income;
      totalExpense += expense;
      totalSaving += saving;

      results.add(
        YearlyStatistics(
          year: targetYear,
          income: income,
          expense: expense,
          saving: saving,
        ),
      );
    }

    return TrendStatisticsData(
      data: results,
      averageIncome: incomeCount > 0 ? (totalIncome / incomeCount).round() : 0,
      averageExpense: expenseCount > 0
          ? (totalExpense / expenseCount).round()
          : 0,
      averageSaving: savingCount > 0 ? (totalSaving / savingCount).round() : 0,
    );
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
  final int saving;

  const MonthlyStatistics({
    required this.year,
    required this.month,
    required this.income,
    required this.expense,
    this.saving = 0,
  });

  int get balance => income - expense;

  String get monthLabel => '$month월';
}
