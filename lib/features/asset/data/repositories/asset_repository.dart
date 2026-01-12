import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/asset_statistics.dart';

class AssetRepository {
  final SupabaseClient _client;

  AssetRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  Future<int> getTotalAssets({required String ledgerId}) async {
    final response = await _client
        .from('transactions')
        .select('amount')
        .eq('ledger_id', ledgerId)
        .eq('type', 'saving')
        .eq('is_asset', true);

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
        .eq('type', 'saving')
        .eq('is_asset', true)
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
          .eq('type', 'saving')
          .eq('is_asset', true)
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
        .eq('type', 'saving')
        .eq('is_asset', true)
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
}
