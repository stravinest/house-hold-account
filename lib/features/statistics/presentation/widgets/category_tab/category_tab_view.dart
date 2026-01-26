import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../core/utils/snackbar_utils.dart';
import '../../../../../l10n/generated/app_localizations.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../providers/statistics_provider.dart';
import '../common/expense_type_filter.dart';
import '../common/statistics_type_filter.dart';
import 'category_donut_chart.dart';
import 'category_ranking_list.dart';
import 'category_summary_card.dart';

class CategoryTabView extends ConsumerStatefulWidget {
  const CategoryTabView({super.key});

  @override
  ConsumerState<CategoryTabView> createState() => _CategoryTabViewState();
}

class _CategoryTabViewState extends ConsumerState<CategoryTabView> {
  Future<void> _refreshCategoryData() async {
    ref.invalidate(categoryExpenseStatisticsProvider);
    ref.invalidate(categoryIncomeStatisticsProvider);
    ref.invalidate(categoryAssetStatisticsProvider);
    ref.invalidate(monthComparisonProvider);

    try {
      await Future.wait([
        ref.read(categoryExpenseStatisticsProvider.future),
        ref.read(categoryIncomeStatisticsProvider.future),
        ref.read(categoryAssetStatisticsProvider.future),
        ref.read(monthComparisonProvider.future),
      ]);
    } on AuthException catch (e) {
      debugPrint('카테고리 통계 새로고침 오류 (인증): $e');
      if (mounted) {
        _handleAuthError(e);
      }
      rethrow;
    } on SocketException catch (e) {
      debugPrint('카테고리 통계 새로고침 오류 (네트워크): $e');
      if (mounted) {
        _showNetworkError();
      }
      rethrow;
    } catch (e) {
      debugPrint('카테고리 통계 새로고침 오류: $e');
      if (mounted && _isNetworkError(e)) {
        _showNetworkError();
      }
      rethrow;
    }
  }

  bool _isNetworkError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('socketexception') ||
        errorString.contains('failed host lookup') ||
        errorString.contains('network') ||
        errorString.contains('authretryablefetchexception');
  }

  void _handleAuthError(AuthException error) {
    final l10n = AppLocalizations.of(context);
    final errorMessage = error.message.toLowerCase();

    if (errorMessage.contains('expired') ||
        errorMessage.contains('refresh') ||
        errorMessage.contains('invalid') ||
        error.statusCode == '401') {
      SnackBarUtils.showError(
        context,
        l10n.errorSessionExpired ?? 'Session expired. Please log in again.',
        duration: const Duration(seconds: 4),
      );

      Future.delayed(const Duration(seconds: 1), () async {
        await ref.read(authNotifierProvider.notifier).signOut();
      });
    }
  }

  void _showNetworkError() {
    final l10n = AppLocalizations.of(context);
    SnackBarUtils.showError(
      context,
      l10n.errorNetwork ?? 'Please check your network connection.',
      duration: const Duration(seconds: 3),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final selectedType = ref.watch(selectedStatisticsTypeProvider);
    final expenseTypeFilter = ref.watch(selectedExpenseTypeFilterProvider);

    return RefreshIndicator(
      onRefresh: _refreshCategoryData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 타입 필터 (수입/지출/자산)
            const Center(child: StatisticsTypeFilter()),

            // 고정비/변동비 필터 (지출 선택 시에만 표시)
            if (selectedType == 'expense') ...[
              const SizedBox(height: 12),
              Center(
                child: ExpenseTypeFilterWidget(
                  selectedFilter: expenseTypeFilter,
                  onChanged: (filter) {
                    ref.read(selectedExpenseTypeFilterProvider.notifier).state =
                        filter;
                  },
                ),
              ),
            ],
            const SizedBox(height: 16),

            // 요약 카드 (전월 대비 포함)
            const CategorySummaryCard(),
            const SizedBox(height: 16),

            // 도넛 차트
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.statisticsCategoryDistribution,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const CategoryDonutChart(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 순위 리스트
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      l10n.statisticsCategoryRanking,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const CategoryRankingList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
