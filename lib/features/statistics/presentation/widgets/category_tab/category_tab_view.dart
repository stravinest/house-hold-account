import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../l10n/generated/app_localizations.dart';
import '../../providers/statistics_provider.dart';
import '../common/expense_type_filter.dart';
import '../common/statistics_type_filter.dart';
import 'category_donut_chart.dart';
import 'category_ranking_list.dart';
import 'category_summary_card.dart';

class CategoryTabView extends ConsumerWidget {
  const CategoryTabView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final selectedType = ref.watch(selectedStatisticsTypeProvider);
    final expenseTypeFilter = ref.watch(selectedExpenseTypeFilterProvider);

    return SingleChildScrollView(
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
    );
  }
}
