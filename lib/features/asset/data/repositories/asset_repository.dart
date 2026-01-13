import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/asset_goal.dart';
import '../../domain/entities/asset_statistics.dart';
import '../models/asset_goal_model.dart';

class AssetRepository {
  final SupabaseClient _client;

  AssetRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  Future<int> getTotalAssets({required String ledgerId}) async {
    final response = await _client
        .from('transactions')
        .select('amount')
        .eq('ledger_id', ledgerId)
        .eq('type', 'asset');

    int total = 0;
    for (final row in response as List) {
      total += (row['amount'] as int);
    }

    return total;
  }

  Future<int> getMonthlyChange({
    required String ledgerId,
    required int year,
    required int month,
  }) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0);

    final response = await _client
        .from('transactions')
        .select('amount')
        .eq('ledger_id', ledgerId)
        .eq('type', 'asset')
        .gte('date', startDate.toIso8601String().split('T').first)
        .lte('date', endDate.toIso8601String().split('T').first);

    int change = 0;
    for (final row in response as List) {
      change += (row['amount'] as int);
    }

    return change;
  }

  Future<List<MonthlyAsset>> getMonthlyAssets({
    required String ledgerId,
    int months = 6,
  }) async {
    final now = DateTime.now();
    final results = <MonthlyAsset>[];

    for (int i = months - 1; i >= 0; i--) {
      final targetDate = DateTime(now.year, now.month - i, 1);
      final endOfMonth = DateTime(targetDate.year, targetDate.month + 1, 0);

      final response = await _client
          .from('transactions')
          .select('amount')
          .eq('ledger_id', ledgerId)
          .eq('type', 'asset')
          .lte('date', endOfMonth.toIso8601String().split('T').first);

      int total = 0;
      for (final row in response as List) {
        total += (row['amount'] as int);
      }

      results.add(
        MonthlyAsset(
          year: targetDate.year,
          month: targetDate.month,
          amount: total,
        ),
      );
    }

    return results;
  }

  Future<List<CategoryAsset>> getAssetsByCategory({
    required String ledgerId,
  }) async {
    final response = await _client
        .from('transactions')
        .select('''
          id,
          amount,
          title,
          maturity_date,
          category_id,
          categories(
            name,
            icon,
            color
          )
        ''')
        .eq('ledger_id', ledgerId)
        .eq('type', 'asset')
        .order('date', ascending: false);

    final Map<String, List<Map<String, dynamic>>> groupedByCategory = {};

    for (final row in response as List) {
      final rowMap = row as Map<String, dynamic>;
      final categoryId = rowMap['category_id']?.toString() ?? '_uncategorized_';

      if (!groupedByCategory.containsKey(categoryId)) {
        groupedByCategory[categoryId] = [];
      }

      groupedByCategory[categoryId]!.add(rowMap);
    }

    final List<CategoryAsset> categoryAssets = [];

    for (final entry in groupedByCategory.entries) {
      final categoryId = entry.key;
      final transactions = entry.value;

      String categoryName = '미지정';
      String? categoryIcon;
      String? categoryColor;

      if (categoryId != '_uncategorized_' && transactions.isNotEmpty) {
        final category =
            transactions.first['categories'] as Map<String, dynamic>?;
        if (category != null) {
          categoryName = category['name'] as String? ?? '미지정';
          categoryIcon = category['icon'] as String?;
          categoryColor = category['color'] as String?;
        }
      }

      int totalAmount = 0;
      final items = <AssetItem>[];

      for (final tx in transactions) {
        final amount = tx['amount'] as int;
        totalAmount += amount;

        items.add(
          AssetItem(
            id: tx['id'] as String,
            title: tx['title'] as String? ?? categoryName,
            amount: amount,
            maturityDate: tx['maturity_date'] != null
                ? DateTime.parse(tx['maturity_date'] as String)
                : null,
          ),
        );
      }

      categoryAssets.add(
        CategoryAsset(
          categoryId: categoryId,
          categoryName: categoryName,
          categoryIcon: categoryIcon,
          categoryColor: categoryColor,
          amount: totalAmount,
          items: items,
        ),
      );
    }

    categoryAssets.sort((a, b) => b.amount.compareTo(a.amount));

    return categoryAssets;
  }

  Future<List<AssetGoal>> getGoals({required String ledgerId}) async {
    try {
      final response = await _client
          .from('asset_goals')
          .select()
          .eq('ledger_id', ledgerId)
          .order('target_date', ascending: true);

      return (response as List)
          .map((json) => AssetGoalModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('목표 조회 실패: $e');
    }
  }

  Future<AssetGoal> createGoal(AssetGoal goal) async {
    try {
      final model = AssetGoalModel(
        id: goal.id,
        ledgerId: goal.ledgerId,
        title: goal.title,
        targetAmount: goal.targetAmount,
        targetDate: goal.targetDate,
        assetType: goal.assetType,
        categoryIds: goal.categoryIds,
        createdAt: goal.createdAt,
        updatedAt: goal.updatedAt,
        createdBy: goal.createdBy,
      );

      final response = await _client
          .from('asset_goals')
          .insert(model.toInsertJson())
          .select()
          .single();

      return AssetGoalModel.fromJson(response);
    } catch (e) {
      throw Exception('목표 생성 실패: $e');
    }
  }

  Future<AssetGoal> updateGoal(AssetGoal goal) async {
    try {
      final model = AssetGoalModel(
        id: goal.id,
        ledgerId: goal.ledgerId,
        title: goal.title,
        targetAmount: goal.targetAmount,
        targetDate: goal.targetDate,
        assetType: goal.assetType,
        categoryIds: goal.categoryIds,
        createdAt: goal.createdAt,
        updatedAt: goal.updatedAt,
        createdBy: goal.createdBy,
      );

      final response = await _client
          .from('asset_goals')
          .update(model.toUpdateJson())
          .eq('id', goal.id)
          .select()
          .single();

      return AssetGoalModel.fromJson(response);
    } catch (e) {
      throw Exception('목표 수정 실패: $e');
    }
  }

  Future<void> deleteGoal(String goalId) async {
    try {
      await _client.from('asset_goals').delete().eq('id', goalId);
    } catch (e) {
      throw Exception('목표 삭제 실패: $e');
    }
  }

  Future<int> getCurrentAmount({
    required String ledgerId,
    String? assetType,
    List<String>? categoryIds,
  }) async {
    try {
      var query = _client
          .from('transactions')
          .select('amount')
          .eq('ledger_id', ledgerId)
          .eq('type', 'asset');

      if (categoryIds != null && categoryIds.isNotEmpty) {
        query = query.inFilter('category_id', categoryIds);
      }

      final response = await query;

      int total = 0;
      for (final row in response as List) {
        total += (row['amount'] as int);
      }

      return total;
    } catch (e) {
      throw Exception('현재 자산 조회 실패: $e');
    }
  }

  Future<AssetTypeBreakdown> getAssetsByType({required String ledgerId}) async {
    try {
      final response = await _client
          .from('transactions')
          .select('''
            amount,
            categories(name)
          ''')
          .eq('ledger_id', ledgerId)
          .eq('type', 'asset');

      int savingAmount = 0;
      int investmentAmount = 0;
      int realEstateAmount = 0;

      final savingCategories = ['정기예금', '적금'];
      final investmentCategories = ['주식', '펀드', '암호화폐'];
      final realEstateCategories = ['부동산'];

      for (final row in response as List) {
        final rowMap = row as Map<String, dynamic>;
        final amount = rowMap['amount'] as int;
        final category = rowMap['categories'] as Map<String, dynamic>?;
        final categoryName = category?['name'] as String? ?? '';

        if (savingCategories.contains(categoryName)) {
          savingAmount += amount;
        } else if (investmentCategories.contains(categoryName)) {
          investmentAmount += amount;
        } else if (realEstateCategories.contains(categoryName)) {
          realEstateAmount += amount;
        } else {
          savingAmount += amount;
        }
      }

      return AssetTypeBreakdown(
        savingAmount: savingAmount,
        investmentAmount: investmentAmount,
        realEstateAmount: realEstateAmount,
      );
    } catch (e) {
      throw Exception('자산 타입별 조회 실패: $e');
    }
  }

  Future<AssetStatistics> getEnhancedStatistics({
    required String ledgerId,
  }) async {
    try {
      final now = DateTime.now();
      final totalAmount = await getTotalAssets(ledgerId: ledgerId);

      final monthlyChange = await getMonthlyChange(
        ledgerId: ledgerId,
        year: now.year,
        month: now.month,
      );

      final lastMonthTotal = await _getTotalAssetsUntil(
        ledgerId: ledgerId,
        date: DateTime(now.year, now.month, 0),
      );

      final yearAgoTotal = await _getTotalAssetsUntil(
        ledgerId: ledgerId,
        date: DateTime(now.year - 1, now.month + 1, 0),
      );

      final monthlyChangeRate = lastMonthTotal == 0
          ? 0.0
          : (monthlyChange / lastMonthTotal) * 100;

      final annualGrowthRate = yearAgoTotal == 0
          ? 0.0
          : ((totalAmount - yearAgoTotal) / yearAgoTotal) * 100;

      final monthly = await getMonthlyAssets(ledgerId: ledgerId);
      final byCategory = await getAssetsByCategory(ledgerId: ledgerId);
      final byType = await getAssetsByType(ledgerId: ledgerId);

      return AssetStatistics(
        totalAmount: totalAmount,
        monthlyChange: monthlyChange,
        monthlyChangeRate: monthlyChangeRate,
        annualGrowthRate: annualGrowthRate,
        monthly: monthly,
        byCategory: byCategory,
        byType: byType,
      );
    } catch (e) {
      throw Exception('통계 조회 실패: $e');
    }
  }

  Future<int> _getTotalAssetsUntil({
    required String ledgerId,
    required DateTime date,
  }) async {
    final response = await _client
        .from('transactions')
        .select('amount')
        .eq('ledger_id', ledgerId)
        .eq('type', 'asset')
        .lte('date', date.toIso8601String().split('T').first);

    int total = 0;
    for (final row in response as List) {
      total += (row['amount'] as int);
    }

    return total;
  }
}
