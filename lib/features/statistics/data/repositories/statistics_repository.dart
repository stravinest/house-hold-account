import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../config/supabase_config.dart';
import '../../domain/entities/statistics_entities.dart';

class StatisticsRepository {
  // 하드코딩 문자열 상수 - UI에서 CategoryL10nHelper로 번역됨
  static const _uncategorizedName = '미지정';
  static const _uncategorizedIcon = '';
  static const _uncategorizedColor = '#9E9E9E';

  final SupabaseClient _client;

  StatisticsRepository({SupabaseClient? client})
      : _client = client ?? SupabaseConfig.client;

  // 카테고리별 지출/수입 합계
  Future<List<CategoryStatistics>> getCategoryStatistics({
    required String ledgerId,
    required int year,
    required int month,
    required String type, // 'income' or 'expense'
    ExpenseTypeFilter? expenseTypeFilter,
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
              : 'amount, category_id, is_fixed_expense, fixed_expense_category_id, categories(name, icon, color), fixed_expense_categories(name, icon, color)',
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
      final categoryIdValue = useFixedExpenseCategory
          ? rowMap['fixed_expense_category_id']
          : rowMap['category_id'];
      final categoryId = categoryIdValue?.toString();

      // 고정비 필터일 때는 fixed_expense_categories 사용
      final category = useFixedExpenseCategory
          ? rowMap['fixed_expense_categories'] as Map<String, dynamic>?
          : rowMap['categories'] as Map<String, dynamic>?;

      // 카테고리 정보 결정
      String groupKey;
      String categoryName;
      String categoryIcon;
      String categoryColor;

      {
        // 고정비 거래는 fixed_expense_categories에서 카테고리 정보를 가져옴
        if (isFixedExpense && !useFixedExpenseCategory) {
          final fixedCategory =
              rowMap['fixed_expense_categories'] as Map<String, dynamic>?;
          final fixedCategoryId =
              rowMap['fixed_expense_category_id']?.toString();
          if (fixedCategoryId != null) {
            groupKey = 'fixed_$fixedCategoryId';
            if (fixedCategory != null) {
              categoryName = fixedCategory['name'].toString();
              categoryIcon = fixedCategory['icon'].toString();
              categoryColor = fixedCategory['color'].toString();
            } else {
              // 조인 실패 시 기본값 사용
              categoryName = _uncategorizedName;
              categoryIcon = _uncategorizedIcon;
              categoryColor = _uncategorizedColor;
            }
          } else if (categoryId != null && category != null) {
            // 고정비 카테고리가 없으면 일반 카테고리로 폴백
            groupKey = categoryId;
            categoryName = category['name'].toString();
            categoryIcon = category['icon'].toString();
            categoryColor = category['color'].toString();
          } else {
            groupKey = '_uncategorized_';
            categoryName = _uncategorizedName;
            categoryIcon = _uncategorizedIcon;
            categoryColor = _uncategorizedColor;
          }
        } else if (categoryId == null) {
          groupKey = '_uncategorized_';
          categoryName = _uncategorizedName;
          categoryIcon = _uncategorizedIcon;
          categoryColor = _uncategorizedColor;
        } else {
          groupKey = categoryId;
          if (category != null) {
            categoryName = category['name'].toString();
            categoryIcon = category['icon'].toString();
            categoryColor = category['color'].toString();
          } else {
            categoryName = _uncategorizedName;
            categoryIcon = _uncategorizedIcon;
            categoryColor = _uncategorizedColor;
          }
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

  // 사용자별 카테고리 통계 조회 (공유 가계부용)
  Future<Map<String, UserCategoryStatistics>> getCategoryStatisticsByUser({
    required String ledgerId,
    required int year,
    required int month,
    required String type,
    ExpenseTypeFilter? expenseTypeFilter,
  }) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0);

    // user_id와 profiles 정보도 함께 조회
    var query = _client
        .from('transactions')
        .select(
          'amount, category_id, user_id, is_fixed_expense, fixed_expense_category_id, categories(name, icon, color), fixed_expense_categories(name, icon, color), profiles!user_id(display_name, email, color)',
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
          break;
      }
    }

    final response = await query;

    // 사용자별로 그룹화
    final Map<String, UserCategoryStatistics> userStats = {};

    for (final row in response as List) {
      final rowMap = row as Map<String, dynamic>;
      final userId = rowMap['user_id'] as String?;
      if (userId == null) continue;

      final amount = (rowMap['amount'] as num?)?.toInt() ?? 0;
      final isFixedExpense = rowMap['is_fixed_expense'] == true;
      final category = rowMap['categories'] as Map<String, dynamic>?;
      final profile = rowMap['profiles'] as Map<String, dynamic>?;

      // 사용자 정보 추출
      final displayName = profile?['display_name'] as String?;
      final email = profile?['email'] as String?;
      final userColor = profile?['color'] as String? ?? '#4CAF50';
      final userName = displayName ?? email?.split('@').first ?? 'Unknown';

      // 카테고리 정보 추출 (고정비 거래는 고정비 카테고리 사용)
      final String categoryId;
      final String categoryName;
      final String categoryIcon;
      final String categoryColor;

      if (isFixedExpense) {
        final fixedCategory =
            rowMap['fixed_expense_categories'] as Map<String, dynamic>?;
        final fixedCategoryId =
            rowMap['fixed_expense_category_id']?.toString();
        if (fixedCategoryId != null && fixedCategory != null) {
          categoryId = 'fixed_$fixedCategoryId';
          categoryName = fixedCategory['name'].toString();
          categoryIcon = fixedCategory['icon'].toString();
          categoryColor = fixedCategory['color'].toString();
        } else {
          categoryId = '_uncategorized_';
          categoryName = _uncategorizedName;
          categoryIcon = _uncategorizedIcon;
          categoryColor = _uncategorizedColor;
        }
      } else {
        categoryId = rowMap['category_id']?.toString() ?? '_uncategorized_';
        categoryName = category?['name']?.toString() ?? _uncategorizedName;
        categoryIcon = category?['icon']?.toString() ?? _uncategorizedIcon;
        categoryColor =
            category?['color']?.toString() ?? _uncategorizedColor;
      }

      // 사용자 통계 초기화
      if (!userStats.containsKey(userId)) {
        userStats[userId] = UserCategoryStatistics(
          userId: userId,
          userName: userName,
          userColor: userColor,
          totalAmount: 0,
          categories: {},
        );
      }

      // 총액 누적
      userStats[userId] = userStats[userId]!.copyWith(
        totalAmount: userStats[userId]!.totalAmount + amount,
      );

      // 카테고리별 누적
      final currentCategories = Map<String, CategoryStatistics>.from(
        userStats[userId]!.categories,
      );
      if (currentCategories.containsKey(categoryId)) {
        currentCategories[categoryId] = currentCategories[categoryId]!.copyWith(
          amount: currentCategories[categoryId]!.amount + amount,
        );
      } else {
        currentCategories[categoryId] = CategoryStatistics(
          categoryId: categoryId,
          categoryName: categoryName,
          categoryIcon: categoryIcon,
          categoryColor: categoryColor,
          amount: amount,
        );
      }

      userStats[userId] = userStats[userId]!.copyWith(
        categories: currentCategories,
      );
    }

    // 각 사용자의 카테고리를 금액 기준으로 정렬
    for (final userId in userStats.keys) {
      final sortedCategories = userStats[userId]!.categories.values.toList()
        ..sort((a, b) => b.amount.compareTo(a.amount));

      final sortedMap = <String, CategoryStatistics>{};
      for (final cat in sortedCategories) {
        sortedMap[cat.categoryId] = cat;
      }

      userStats[userId] = userStats[userId]!.copyWith(categories: sortedMap);
    }

    return userStats;
  }

  // 월별 수입/지출 추세 (최근 6개월) - N+1 쿼리 최적화: 단일 쿼리로 변경
  Future<List<MonthlyStatistics>> getMonthlyTrend({
    required String ledgerId,
    int months = 6,
  }) async {
    final now = DateTime.now();

    // 전체 기간 계산 (단일 쿼리용)
    final startDate = DateTime(now.year, now.month - months + 1, 1);
    final endDate = DateTime(now.year, now.month + 1, 0);

    // 단일 쿼리로 전체 기간 데이터 조회
    final response = await _client
        .from('transactions')
        .select('amount, type, date')
        .eq('ledger_id', ledgerId)
        .gte('date', startDate.toIso8601String().split('T').first)
        .lte('date', endDate.toIso8601String().split('T').first);

    // 월별로 그룹화
    final Map<String, MonthlyStatistics> grouped = {};

    // 빈 월 데이터 초기화
    for (int i = months - 1; i >= 0; i--) {
      final targetDate = DateTime(now.year, now.month - i, 1);
      final key = '${targetDate.year}-${targetDate.month}';
      grouped[key] = MonthlyStatistics(
        year: targetDate.year,
        month: targetDate.month,
        income: 0,
        expense: 0,
        saving: 0,
      );
    }

    // 데이터 집계
    for (final row in response as List) {
      final amount = (row['amount'] as num).toInt();
      final type = row['type'] as String;
      final date = DateTime.parse(row['date'] as String);
      final key = '${date.year}-${date.month}';

      if (grouped.containsKey(key)) {
        final current = grouped[key]!;
        if (type == 'income') {
          grouped[key] = MonthlyStatistics(
            year: current.year,
            month: current.month,
            income: current.income + amount,
            expense: current.expense,
            saving: current.saving,
          );
        } else if (type == 'asset') {
          grouped[key] = MonthlyStatistics(
            year: current.year,
            month: current.month,
            income: current.income,
            expense: current.expense,
            saving: current.saving + amount,
          );
        } else {
          grouped[key] = MonthlyStatistics(
            year: current.year,
            month: current.month,
            income: current.income,
            expense: current.expense + amount,
            saving: current.saving,
          );
        }
      }
    }

    // 날짜 순서대로 정렬하여 반환
    final results = <MonthlyStatistics>[];
    for (int i = months - 1; i >= 0; i--) {
      final targetDate = DateTime(now.year, now.month - i, 1);
      final key = '${targetDate.year}-${targetDate.month}';
      results.add(grouped[key]!);
    }

    return results;
  }

  // 월 비교 데이터 (현재 월 vs 지난 월) - 단일 쿼리로 최적화
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

    // 단일 쿼리로 양쪽 월 데이터 조회
    var query = _client
        .from('transactions')
        .select('amount, is_fixed_expense, date')
        .eq('ledger_id', ledgerId)
        .eq('type', type)
        .gte('date', previousStartDate.toIso8601String().split('T').first)
        .lte('date', currentEndDate.toIso8601String().split('T').first);

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

    int currentTotal = 0;
    int previousTotal = 0;

    // 클라이언트 측에서 월별로 그룹화
    for (final row in response as List) {
      final amount = (row['amount'] as num).toInt();
      final date = DateTime.parse(row['date'] as String);

      // 현재 월에 속하는지 확인
      if (date.year == currentStartDate.year &&
          date.month == currentStartDate.month) {
        currentTotal += amount;
      }
      // 이전 월에 속하는지 확인
      else if (date.year == previousStartDate.year &&
          date.month == previousStartDate.month) {
        previousTotal += amount;
      }
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

  // 결제수단 그룹 키 생성
  // - 자동수집 결제수단 (can_auto_save=true): 이름 기준 그룹화 (합산)
  // - 공유 결제수단 (can_auto_save=false): UUID 기준 그룹화
  // - 결제수단 없음: '_no_payment_method_'
  String _getPaymentMethodGroupKey({
    required String? paymentMethodId,
    required String? name,
    required bool canAutoSave,
  }) {
    if (paymentMethodId == null) {
      return '_no_payment_method_';
    }

    // 자동수집 결제수단: 이름 기준 그룹화 (공유 가계부에서 동일 이름 합산)
    if (canAutoSave && name != null && name.isNotEmpty) {
      return 'auto_$name';
    }

    // 공유 결제수단: UUID 기준 그룹화 (기존 동작)
    return paymentMethodId;
  }

  // 결제수단별 통계
  Future<List<PaymentMethodStatistics>> getPaymentMethodStatistics({
    required String ledgerId,
    required int year,
    required int month,
    required String type,
    ExpenseTypeFilter? expenseTypeFilter,
    String? userId,
  }) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0);

    var query = _client
        .from('transactions')
        .select(
          'amount, payment_method_id, is_fixed_expense, payment_methods(name, icon, color, can_auto_save)',
        )
        .eq('ledger_id', ledgerId)
        .eq('type', type)
        .gte('date', startDate.toIso8601String().split('T').first)
        .lte('date', endDate.toIso8601String().split('T').first);

    // 고정비/변동비 필터 적용
    if (type == 'expense' && expenseTypeFilter != null) {
      switch (expenseTypeFilter) {
        case ExpenseTypeFilter.fixed:
          query = query.eq('is_fixed_expense', true);
          break;
        case ExpenseTypeFilter.variable:
          query = query.eq('is_fixed_expense', false);
          break;
        case ExpenseTypeFilter.all:
          break;
      }
    }

    // 유저 필터 적용
    if (userId != null) {
      query = query.eq('user_id', userId);
    }

    final response = await query;

    // 결제수단별로 그룹화
    final Map<String, PaymentMethodStatistics> grouped = {};
    int totalAmount = 0;

    for (final row in response as List) {
      final rowMap = row as Map<String, dynamic>;
      final paymentMethodIdValue = rowMap['payment_method_id'];
      final paymentMethodId = paymentMethodIdValue?.toString();
      final amount = (rowMap['amount'] as num?)?.toInt() ?? 0;
      final paymentMethod = rowMap['payment_methods'] as Map<String, dynamic>?;

      totalAmount += amount;

      // 결제수단 정보 추출 (그룹 키 생성 전에 먼저 추출)
      String pmName = _uncategorizedName;
      String pmIcon = _uncategorizedIcon;
      String pmColor = _uncategorizedColor;
      bool canAutoSave = false;

      if (paymentMethod != null) {
        pmName = paymentMethod['name']?.toString() ?? _uncategorizedName;
        pmIcon = paymentMethod['icon']?.toString() ?? '';
        pmColor = paymentMethod['color']?.toString() ?? '#9E9E9E';
        canAutoSave = paymentMethod['can_auto_save'] == true;
      }

      // 그룹 키 생성 (자동수집은 이름 기준, 공유는 UUID 기준)
      final groupKey = _getPaymentMethodGroupKey(
        paymentMethodId: paymentMethodId,
        name: pmName,
        canAutoSave: canAutoSave,
      );

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
          canAutoSave: canAutoSave,
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

  // 사용자별 결제수단 통계 조회 (공유 가계부용)
  Future<Map<String, UserPaymentMethodStatistics>>
      getPaymentMethodStatisticsByUser({
    required String ledgerId,
    required int year,
    required int month,
    required String type,
    ExpenseTypeFilter? expenseTypeFilter,
  }) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0);

    var query = _client
        .from('transactions')
        .select(
          'amount, payment_method_id, user_id, is_fixed_expense, payment_methods(name, icon, color, can_auto_save), profiles!user_id(display_name, email, color)',
        )
        .eq('ledger_id', ledgerId)
        .eq('type', type)
        .gte('date', startDate.toIso8601String().split('T').first)
        .lte('date', endDate.toIso8601String().split('T').first);

    // 고정비/변동비 필터 적용
    if (type == 'expense' && expenseTypeFilter != null) {
      switch (expenseTypeFilter) {
        case ExpenseTypeFilter.fixed:
          query = query.eq('is_fixed_expense', true);
          break;
        case ExpenseTypeFilter.variable:
          query = query.eq('is_fixed_expense', false);
          break;
        case ExpenseTypeFilter.all:
          break;
      }
    }

    final response = await query;

    // 사용자별로 그룹화
    final Map<String, UserPaymentMethodStatistics> userStats = {};

    for (final row in response as List) {
      final rowMap = row as Map<String, dynamic>;
      final userId = rowMap['user_id'] as String?;
      if (userId == null) continue;

      final amount = (rowMap['amount'] as num?)?.toInt() ?? 0;
      final paymentMethodIdValue = rowMap['payment_method_id'];
      final paymentMethodId = paymentMethodIdValue?.toString();
      final paymentMethod =
          rowMap['payment_methods'] as Map<String, dynamic>?;
      final profile = rowMap['profiles'] as Map<String, dynamic>?;

      // 사용자 정보 추출
      final displayName = profile?['display_name'] as String?;
      final email = profile?['email'] as String?;
      final userColor = profile?['color'] as String? ?? '#4CAF50';
      final userName =
          displayName ?? email?.split('@').first ?? 'Unknown';

      // 결제수단 정보 추출
      String pmName = _uncategorizedName;
      String pmIcon = _uncategorizedIcon;
      String pmColor = _uncategorizedColor;
      bool canAutoSave = false;

      if (paymentMethod != null) {
        pmName =
            paymentMethod['name']?.toString() ?? _uncategorizedName;
        pmIcon = paymentMethod['icon']?.toString() ?? '';
        pmColor = paymentMethod['color']?.toString() ?? '#9E9E9E';
        canAutoSave = paymentMethod['can_auto_save'] == true;
      }

      final groupKey = _getPaymentMethodGroupKey(
        paymentMethodId: paymentMethodId,
        name: pmName,
        canAutoSave: canAutoSave,
      );

      // 사용자 통계 초기화
      if (!userStats.containsKey(userId)) {
        userStats[userId] = UserPaymentMethodStatistics(
          userId: userId,
          userName: userName,
          userColor: userColor,
          totalAmount: 0,
          paymentMethods: {},
        );
      }

      // 총액 누적
      userStats[userId] = userStats[userId]!.copyWith(
        totalAmount: userStats[userId]!.totalAmount + amount,
      );

      // 결제수단별 누적
      final currentPMs = Map<String, PaymentMethodStatistics>.from(
        userStats[userId]!.paymentMethods,
      );
      if (currentPMs.containsKey(groupKey)) {
        currentPMs[groupKey] = currentPMs[groupKey]!.copyWith(
          amount: currentPMs[groupKey]!.amount + amount,
        );
      } else {
        currentPMs[groupKey] = PaymentMethodStatistics(
          paymentMethodId: groupKey,
          paymentMethodName: pmName,
          paymentMethodIcon: pmIcon,
          paymentMethodColor: pmColor,
          canAutoSave: canAutoSave,
          amount: amount,
          percentage: 0,
        );
      }

      userStats[userId] = userStats[userId]!.copyWith(
        paymentMethods: currentPMs,
      );
    }

    // 각 사용자의 결제수단 비율 계산 및 정렬
    for (final userId in userStats.keys) {
      final total = userStats[userId]!.totalAmount;
      final sortedPMs = userStats[userId]!.paymentMethods.values.map((pm) {
        final percentage =
            total > 0 ? (pm.amount / total) * 100 : 0.0;
        return pm.copyWith(percentage: percentage);
      }).toList()
        ..sort((a, b) => b.amount.compareTo(a.amount));

      final sortedMap = <String, PaymentMethodStatistics>{};
      for (final pm in sortedPMs) {
        sortedMap[pm.paymentMethodId] = pm;
      }

      userStats[userId] =
          userStats[userId]!.copyWith(paymentMethods: sortedMap);
    }

    return userStats;
  }

  // 연별 추이 (최근 N년) - 단일 쿼리로 최적화
  Future<List<YearlyStatistics>> getYearlyTrend({
    required String ledgerId,
    int years = 3,
  }) async {
    final now = DateTime.now();
    final startYear = now.year - years + 1;
    final startDate = DateTime(startYear, 1, 1);
    final endDate = DateTime(now.year, 12, 31);

    // 단일 쿼리로 전체 기간 데이터 조회
    final response = await _client
        .from('transactions')
        .select('amount, type, date')
        .eq('ledger_id', ledgerId)
        .gte('date', startDate.toIso8601String().split('T').first)
        .lte('date', endDate.toIso8601String().split('T').first);

    // 연도별 데이터 초기화
    final yearlyData = <int, Map<String, int>>{};
    for (int i = 0; i < years; i++) {
      final year = startYear + i;
      yearlyData[year] = {'income': 0, 'expense': 0, 'saving': 0};
    }

    // 클라이언트에서 연도별 집계
    for (final row in response as List) {
      final dateStr = row['date'] as String;
      final year = DateTime.parse(dateStr).year;
      final amount = (row['amount'] as num).toInt();
      final type = row['type'] as String;

      if (!yearlyData.containsKey(year)) continue;

      if (type == 'income') {
        yearlyData[year]!['income'] = yearlyData[year]!['income']! + amount;
      } else if (type == 'asset') {
        yearlyData[year]!['saving'] = yearlyData[year]!['saving']! + amount;
      } else {
        yearlyData[year]!['expense'] = yearlyData[year]!['expense']! + amount;
      }
    }

    // 정렬된 결과 반환
    return yearlyData.entries
        .map(
          (e) => YearlyStatistics(
            year: e.key,
            income: e.value['income']!,
            expense: e.value['expense']!,
            saving: e.value['saving']!,
          ),
        )
        .toList()
      ..sort((a, b) => a.year.compareTo(b.year));
  }

  // 월별 추이 (선택된 날짜 기준, 평균값 포함, 0원 제외) - 단일 쿼리로 최적화
  Future<TrendStatisticsData> getMonthlyTrendWithAverage({
    required String ledgerId,
    required DateTime baseDate,
    int months = 6,
    ExpenseTypeFilter? expenseTypeFilter,
  }) async {
    // 시작/종료 날짜 계산
    final startDate = DateTime(baseDate.year, baseDate.month - months + 1, 1);
    final endDate = DateTime(baseDate.year, baseDate.month + 1, 0);

    // 단일 쿼리로 전체 기간 데이터 조회 (고정비 필터용 is_fixed_expense 포함)
    final response = await _client
        .from('transactions')
        .select('amount, type, date, is_fixed_expense')
        .eq('ledger_id', ledgerId)
        .gte('date', startDate.toIso8601String().split('T').first)
        .lte('date', endDate.toIso8601String().split('T').first);

    // 월별 데이터 초기화
    final monthlyData = <String, Map<String, int>>{};
    for (int i = 0; i < months; i++) {
      final targetDate = DateTime(
        baseDate.year,
        baseDate.month - months + 1 + i,
        1,
      );
      final key = '${targetDate.year}-${targetDate.month}';
      monthlyData[key] = {
        'income': 0,
        'expense': 0,
        'saving': 0,
        'year': targetDate.year,
        'month': targetDate.month,
      };
    }

    // 클라이언트에서 월별 집계
    for (final row in response as List) {
      final dateStr = row['date'] as String;
      final date = DateTime.parse(dateStr);
      final key = '${date.year}-${date.month}';
      final amount = (row['amount'] as num).toInt();
      final type = row['type'] as String;

      if (!monthlyData.containsKey(key)) continue;

      // 지출 타입일 때 고정비/변동비 필터 적용
      if (type == 'expense' && expenseTypeFilter != null) {
        final isFixedExpense = row['is_fixed_expense'] == true;
        if (expenseTypeFilter == ExpenseTypeFilter.fixed && !isFixedExpense) {
          continue;
        }
        if (expenseTypeFilter == ExpenseTypeFilter.variable && isFixedExpense) {
          continue;
        }
      }

      if (type == 'income') {
        monthlyData[key]!['income'] = monthlyData[key]!['income']! + amount;
      } else if (type == 'asset') {
        monthlyData[key]!['saving'] = monthlyData[key]!['saving']! + amount;
      } else {
        monthlyData[key]!['expense'] = monthlyData[key]!['expense']! + amount;
      }
    }

    // 평균 계산 (0원 제외)
    int totalIncome = 0;
    int totalExpense = 0;
    int totalAsset = 0;
    int incomeCount = 0;
    int expenseCount = 0;
    int savingCount = 0;

    final results = <MonthlyStatistics>[];
    for (final entry in monthlyData.entries) {
      final data = entry.value;
      final income = data['income']!;
      final expense = data['expense']!;
      final saving = data['saving']!;

      if (income > 0) {
        totalIncome += income;
        incomeCount++;
      }
      if (expense > 0) {
        totalExpense += expense;
        expenseCount++;
      }
      if (saving > 0) {
        totalAsset += saving;
        savingCount++;
      }

      results.add(
        MonthlyStatistics(
          year: data['year']!,
          month: data['month']!,
          income: income,
          expense: expense,
          saving: saving,
        ),
      );
    }

    // 날짜순 정렬
    results.sort((a, b) {
      final yearCmp = a.year.compareTo(b.year);
      return yearCmp != 0 ? yearCmp : a.month.compareTo(b.month);
    });

    return TrendStatisticsData(
      data: results,
      averageIncome: incomeCount > 0 ? (totalIncome / incomeCount).round() : 0,
      averageExpense: expenseCount > 0
          ? (totalExpense / expenseCount).round()
          : 0,
      averageAsset: savingCount > 0 ? (totalAsset / savingCount).round() : 0,
    );
  }

  // 카테고리 내 Top5 거래 조회 - 단일 쿼리로 총액 + Top5 동시 처리
  Future<CategoryTopResult> getCategoryTopTransactions({
    required String ledgerId,
    required int year,
    required int month,
    required String type,
    required String categoryId,
    bool isFixedExpenseFilter = false,
    ExpenseTypeFilter? expenseTypeFilter,
    int limit = 5,
  }) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0);

    var query = _client
        .from('transactions')
        .select(
          'id, title, amount, date, user_id, profiles!user_id(display_name, color)',
        )
        .eq('ledger_id', ledgerId)
        .eq('type', type)
        .gte('date', startDate.toIso8601String().split('T').first)
        .lte('date', endDate.toIso8601String().split('T').first);

    // 고정비/변동비 필터 적용 (지출 타입일 때)
    if (type == 'expense' && expenseTypeFilter != null) {
      switch (expenseTypeFilter) {
        case ExpenseTypeFilter.fixed:
          query = query.eq('is_fixed_expense', true);
          break;
        case ExpenseTypeFilter.variable:
          query = query.eq('is_fixed_expense', false);
          break;
        case ExpenseTypeFilter.all:
          break;
      }
    }

    if (categoryId == '_uncategorized_') {
      // 고정비 필터일 때는 fixed_expense_category_id가 null인 것을 조회
      if (isFixedExpenseFilter) {
        query = query.isFilter('fixed_expense_category_id', null);
      } else {
        query = query.isFilter('category_id', null);
        // 고정비 카테고리가 설정된 거래는 미지정에서 제외
        query = query.or('is_fixed_expense.eq.false,fixed_expense_category_id.is.null');
      }
    } else if (categoryId == '_fixed_expense_') {
      query = query.eq('is_fixed_expense', true);
    } else if (categoryId.startsWith('fixed_')) {
      final actualId = categoryId.substring(6);
      query = query.eq('fixed_expense_category_id', actualId);
    } else if (isFixedExpenseFilter) {
      query = query.eq('fixed_expense_category_id', categoryId);
    } else {
      query = query.eq('category_id', categoryId);
    }

    final allRows = await query;

    // 클라이언트에서 총액 계산
    final totalAmount = allRows.fold<int>(
      0,
      (sum, row) => sum + ((row['amount'] as num?)?.toInt() ?? 0),
    );

    // 금액순 정렬 후 상위 limit개 추출
    allRows.sort(
      (a, b) => ((b['amount'] as num?) ?? 0).compareTo((a['amount'] as num?) ?? 0),
    );
    final topRows = allRows.take(limit).toList();

    // 요일 배열: DateTime.weekday는 1(월)~7(일)
    const dayNames = ['월', '화', '수', '목', '금', '토', '일'];
    final items = <CategoryTopTransaction>[];

    for (int i = 0; i < topRows.length; i++) {
      final row = topRows[i];
      final amount = (row['amount'] as num?)?.toInt() ?? 0;
      final profile = row['profiles'] as Map<String, dynamic>?;
      final dateStr = row['date'] as String;
      final txDate = DateTime.parse(dateStr);
      final formattedDate =
          '${txDate.month}월 ${txDate.day}일 (${dayNames[txDate.weekday - 1]})';

      items.add(CategoryTopTransaction(
        rank: i + 1,
        title: row['title'] as String? ?? '',
        amount: amount,
        percentage: totalAmount > 0
            ? ((amount / totalAmount) * 1000).round() / 10
            : 0.0,
        date: formattedDate,
        userName: profile?['display_name'] as String? ?? '',
        userColor: profile?['color'] as String? ?? '#A8D8EA',
      ));
    }

    return CategoryTopResult(items: items, totalAmount: totalAmount);
  }

  // 연별 추이 (선택된 날짜 기준, 평균값 포함, 0원 제외) - 단일 쿼리로 최적화
  Future<TrendStatisticsData> getYearlyTrendWithAverage({
    required String ledgerId,
    required DateTime baseDate,
    int years = 6,
    ExpenseTypeFilter? expenseTypeFilter,
  }) async {
    final startYear = baseDate.year - years + 1;
    final startDate = DateTime(startYear, 1, 1);
    final endDate = DateTime(baseDate.year, 12, 31);

    // 단일 쿼리로 전체 기간 데이터 조회 (고정비 필터용 is_fixed_expense 포함)
    final response = await _client
        .from('transactions')
        .select('amount, type, date, is_fixed_expense')
        .eq('ledger_id', ledgerId)
        .gte('date', startDate.toIso8601String().split('T').first)
        .lte('date', endDate.toIso8601String().split('T').first);

    // 연도별 데이터 초기화
    final yearlyData = <int, Map<String, int>>{};
    for (int i = 0; i < years; i++) {
      final year = startYear + i;
      yearlyData[year] = {'income': 0, 'expense': 0, 'saving': 0};
    }

    // 클라이언트에서 연도별 집계
    for (final row in response as List) {
      final dateStr = row['date'] as String;
      final year = DateTime.parse(dateStr).year;
      final amount = (row['amount'] as num).toInt();
      final type = row['type'] as String;

      if (!yearlyData.containsKey(year)) continue;

      // 지출 타입일 때 고정비/변동비 필터 적용
      if (type == 'expense' && expenseTypeFilter != null) {
        final isFixedExpense = row['is_fixed_expense'] == true;
        if (expenseTypeFilter == ExpenseTypeFilter.fixed && !isFixedExpense) {
          continue;
        }
        if (expenseTypeFilter == ExpenseTypeFilter.variable && isFixedExpense) {
          continue;
        }
      }

      if (type == 'income') {
        yearlyData[year]!['income'] = yearlyData[year]!['income']! + amount;
      } else if (type == 'asset') {
        yearlyData[year]!['saving'] = yearlyData[year]!['saving']! + amount;
      } else {
        yearlyData[year]!['expense'] = yearlyData[year]!['expense']! + amount;
      }
    }

    // 평균 계산 (0원 제외)
    int totalIncome = 0;
    int totalExpense = 0;
    int totalAsset = 0;
    int incomeCount = 0;
    int expenseCount = 0;
    int savingCount = 0;

    final results = <YearlyStatistics>[];
    for (final entry in yearlyData.entries) {
      final data = entry.value;
      final income = data['income']!;
      final expense = data['expense']!;
      final saving = data['saving']!;

      if (income > 0) {
        totalIncome += income;
        incomeCount++;
      }
      if (expense > 0) {
        totalExpense += expense;
        expenseCount++;
      }
      if (saving > 0) {
        totalAsset += saving;
        savingCount++;
      }

      results.add(
        YearlyStatistics(
          year: entry.key,
          income: income,
          expense: expense,
          saving: saving,
        ),
      );
    }

    // 연도순 정렬
    results.sort((a, b) => a.year.compareTo(b.year));

    return TrendStatisticsData(
      data: results,
      averageIncome: incomeCount > 0 ? (totalIncome / incomeCount).round() : 0,
      averageExpense: expenseCount > 0
          ? (totalExpense / expenseCount).round()
          : 0,
      averageAsset: savingCount > 0 ? (totalAsset / savingCount).round() : 0,
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

// 사용자별 카테고리 통계 모델 (공유 가계부용)
class UserCategoryStatistics {
  final String userId;
  final String userName;
  final String userColor;
  final int totalAmount;
  final Map<String, CategoryStatistics> categories;

  const UserCategoryStatistics({
    required this.userId,
    required this.userName,
    required this.userColor,
    required this.totalAmount,
    required this.categories,
  });

  UserCategoryStatistics copyWith({
    String? userId,
    String? userName,
    String? userColor,
    int? totalAmount,
    Map<String, CategoryStatistics>? categories,
  }) {
    return UserCategoryStatistics(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userColor: userColor ?? this.userColor,
      totalAmount: totalAmount ?? this.totalAmount,
      categories: categories ?? this.categories,
    );
  }

  // 카테고리 리스트로 변환 (정렬된 상태)
  List<CategoryStatistics> get categoryList {
    final list = categories.values.toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
    return list;
  }
}

// 카테고리 Top 거래 결과
class CategoryTopResult {
  final List<CategoryTopTransaction> items;
  final int totalAmount;

  const CategoryTopResult({required this.items, required this.totalAmount});
}

// 카테고리 Top 거래 모델
class CategoryTopTransaction {
  final int rank;
  final String title;
  final int amount;
  final double percentage;
  final String date;
  final String userName;
  final String userColor;

  const CategoryTopTransaction({
    required this.rank,
    required this.title,
    required this.amount,
    required this.percentage,
    required this.date,
    required this.userName,
    required this.userColor,
  });
}

// 사용자별 결제수단 통계 모델 (공유 가계부용)
class UserPaymentMethodStatistics {
  final String userId;
  final String userName;
  final String userColor;
  final int totalAmount;
  final Map<String, PaymentMethodStatistics> paymentMethods;

  const UserPaymentMethodStatistics({
    required this.userId,
    required this.userName,
    required this.userColor,
    required this.totalAmount,
    required this.paymentMethods,
  });

  UserPaymentMethodStatistics copyWith({
    String? userId,
    String? userName,
    String? userColor,
    int? totalAmount,
    Map<String, PaymentMethodStatistics>? paymentMethods,
  }) {
    return UserPaymentMethodStatistics(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userColor: userColor ?? this.userColor,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentMethods: paymentMethods ?? this.paymentMethods,
    );
  }

  // 결제수단 리스트로 변환 (정렬된 상태)
  List<PaymentMethodStatistics> get paymentMethodList {
    final list = paymentMethods.values.toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
    return list;
  }
}
