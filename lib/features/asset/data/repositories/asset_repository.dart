import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/asset_goal.dart';
import '../../domain/entities/asset_statistics.dart';
import '../models/asset_goal_model.dart';

// 재시도 가능한 쿼리 실행 헬퍼
Future<T> _retryOnConnectionError<T>(
  Future<T> Function() operation, {
  int maxRetries = 3,
  Duration delay = const Duration(milliseconds: 500),
}) async {
  int attempt = 0;
  while (true) {
    try {
      return await operation();
    } catch (e) {
      attempt++;
      final isConnectionError =
          e.toString().contains('Connection closed') ||
          e.toString().contains('ClientException') ||
          e is SocketException;

      if (!isConnectionError || attempt >= maxRetries) {
        rethrow;
      }

      debugPrint('Connection error, retrying ($attempt/$maxRetries)...');
      await Future.delayed(delay * attempt);
    }
  }
}

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

  // 월별 누적 자산 - 단일 쿼리로 최적화
  Future<List<MonthlyAsset>> getMonthlyAssets({
    required String ledgerId,
    int months = 6,
  }) async {
    final now = DateTime.now();
    final endOfCurrentMonth = DateTime(now.year, now.month + 1, 0);

    // 단일 쿼리로 전체 자산 거래 조회 (현재 월까지)
    final response = await _client
        .from('transactions')
        .select('amount, date')
        .eq('ledger_id', ledgerId)
        .eq('type', 'asset')
        .lte('date', endOfCurrentMonth.toIso8601String().split('T').first)
        .order('date', ascending: true);

    // 월별 누적 계산을 위한 준비
    final results = <MonthlyAsset>[];
    int runningTotal = 0;

    // 대상 월 목록 생성
    final targetMonths = <DateTime>[];
    for (int i = months - 1; i >= 0; i--) {
      targetMonths.add(DateTime(now.year, now.month - i, 1));
    }

    // 각 거래를 순회하며 월별 누적 계산
    int txIndex = 0;
    final transactions = response as List;

    for (final targetDate in targetMonths) {
      final endOfMonth = DateTime(targetDate.year, targetDate.month + 1, 0);

      // 해당 월 말일까지의 거래 누적
      while (txIndex < transactions.length) {
        final txDate = DateTime.parse(transactions[txIndex]['date'] as String);
        if (txDate.isAfter(endOfMonth)) break;

        runningTotal += (transactions[txIndex]['amount'] as int);
        txIndex++;
      }

      results.add(
        MonthlyAsset(
          year: targetDate.year,
          month: targetDate.month,
          amount: runningTotal,
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
      final categoryId = rowMap['category_id'].toString() ?? '_uncategorized_';

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
    } catch (e, st) {
      Error.throwWithStackTrace(Exception('목표 조회 실패: $e'), st);
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
    } catch (e, st) {
      Error.throwWithStackTrace(Exception('목표 생성 실패: $e'), st);
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
    } catch (e, st) {
      Error.throwWithStackTrace(Exception('목표 수정 실패: $e'), st);
    }
  }

  Future<void> deleteGoal(String goalId) async {
    try {
      await _client.from('asset_goals').delete().eq('id', goalId);
    } catch (e, st) {
      Error.throwWithStackTrace(Exception('목표 삭제 실패: $e'), st);
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
    } catch (e, st) {
      Error.throwWithStackTrace(Exception('현재 자산 조회 실패: $e'), st);
    }
  }

  // 자산 통계 - 병렬 쿼리로 최적화 (연결 오류 시 재시도)
  Future<AssetStatistics> getEnhancedStatistics({
    required String ledgerId,
  }) async {
    try {
      final now = DateTime.now();

      // 독립적인 쿼리들을 병렬로 실행 (연결 오류 시 재시도)
      final results = await _retryOnConnectionError(
        () => Future.wait([
          getTotalAssets(ledgerId: ledgerId),
          getMonthlyChange(
            ledgerId: ledgerId,
            year: now.year,
            month: now.month,
          ),
          _getTotalAssetsUntil(
            ledgerId: ledgerId,
            date: DateTime(now.year, now.month, 0),
          ),
          _getTotalAssetsUntil(
            ledgerId: ledgerId,
            date: DateTime(now.year - 1, now.month + 1, 0),
          ),
          getMonthlyAssets(ledgerId: ledgerId),
          getAssetsByCategory(ledgerId: ledgerId),
        ]),
      );

      final totalAmount = results[0] as int;
      final monthlyChange = results[1] as int;
      final lastMonthTotal = results[2] as int;
      final yearAgoTotal = results[3] as int;
      final monthly = results[4] as List<MonthlyAsset>;
      final byCategory = results[5] as List<CategoryAsset>;

      final monthlyChangeRate = lastMonthTotal == 0
          ? 0.0
          : (monthlyChange / lastMonthTotal) * 100;

      final annualGrowthRate = yearAgoTotal == 0
          ? 0.0
          : ((totalAmount - yearAgoTotal) / yearAgoTotal) * 100;

      return AssetStatistics(
        totalAmount: totalAmount,
        monthlyChange: monthlyChange,
        monthlyChangeRate: monthlyChangeRate,
        annualGrowthRate: annualGrowthRate,
        monthly: monthly,
        byCategory: byCategory,
      );
    } catch (e, st) {
      Error.throwWithStackTrace(Exception('통계 조회 실패: $e'), st);
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
