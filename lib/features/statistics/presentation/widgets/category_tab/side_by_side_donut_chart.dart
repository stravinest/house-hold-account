import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/utils/number_format_utils.dart';
import '../../../../../l10n/generated/app_localizations.dart';
import '../../../data/repositories/statistics_repository.dart';
import '../../providers/statistics_provider.dart';

/// 두 사용자의 도넛 차트를 나란히 표시하는 위젯
class SideBySideDonutChart extends ConsumerWidget {
  const SideBySideDonutChart({super.key});

  Color _parseColor(String colorString) {
    try {
      final colorValue = int.parse(colorString.replaceFirst('#', '0xFF'));
      return Color(colorValue);
    } catch (e) {
      return const Color(0xFF9E9E9E);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final userStatsAsync = ref.watch(categoryStatisticsByUserProvider);
    final sharedState = ref.watch(sharedStatisticsStateProvider);

    return userStatsAsync.when(
      data: (userStats) {
        if (userStats.isEmpty) {
          return _buildEmptyState(context, l10n);
        }

        final users = userStats.values.toList()
          ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

        // 모드에 따라 다르게 표시
        switch (sharedState.mode) {
          case SharedStatisticsMode.combined:
            // 합쳐서: 합산된 단일 도넛 차트
            return _buildCombinedChart(context, l10n, users);

          case SharedStatisticsMode.singleUser:
            // 특정 사용자만: 선택된 사용자의 도넛 차트
            final selectedUser = users.firstWhere(
              (u) => u.userId == sharedState.selectedUserId,
              orElse: () => users.first,
            );
            return _buildSingleUserChart(context, l10n, selectedUser);

          case SharedStatisticsMode.overlay:
          default:
            // 겹쳐서: 나란히 두 개 도넛 차트
            return _buildSideBySideCharts(context, l10n, users);
        }
      },
      loading: () => const SizedBox(
        height: 250,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => SizedBox(
        height: 250,
        child: Center(child: Text(l10n.errorWithMessage(error.toString()))),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 200,
      child: Center(
        child: Text(
          l10n.statisticsNoData,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildSideBySideCharts(
    BuildContext context,
    AppLocalizations l10n,
    List<UserCategoryStatistics> users,
  ) {
    if (users.length < 2) {
      return _buildSingleUserChart(context, l10n, users.first);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.statisticsCategoryDistribution,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildUserDonut(
                    context,
                    l10n,
                    users[0],
                    isHighlighted: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildUserDonut(
                    context,
                    l10n,
                    users[1],
                    isHighlighted: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserDonut(
    BuildContext context,
    AppLocalizations l10n,
    UserCategoryStatistics user, {
    bool isHighlighted = false,
    double size = 140,
  }) {
    final theme = Theme.of(context);
    final userColor = _parseColor(user.userColor);
    final categories = user.categoryList;

    if (user.totalAmount == 0 || categories.isEmpty) {
      return Column(
        children: [
          SizedBox(
            height: size,
            width: size,
            child: Center(
              child: Text(
                l10n.statisticsNoData,
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            user.userName,
            style: theme.textTheme.titleSmall?.copyWith(
              color: userColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            '${NumberFormatUtils.currency.format(0)}${l10n.transactionAmountUnit}',
            style: theme.textTheme.bodySmall,
          ),
        ],
      );
    }

    // 상위 5개 + 기타 처리
    final processedCategories = _processCategories(l10n, categories);

    return Column(
      children: [
        Container(
          decoration: isHighlighted
              ? BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: userColor.withValues(alpha: 0.3),
                    width: 3,
                  ),
                )
              : null,
          child: SizedBox(
            height: size,
            width: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: size * 0.25,
                    sections: _buildSections(
                      processedCategories,
                      user.totalAmount,
                    ),
                    pieTouchData: PieTouchData(enabled: false),
                  ),
                ),
                // 중앙 아이콘 또는 사용자 표시
                Container(
                  width: size * 0.4,
                  height: size * 0.4,
                  decoration: BoxDecoration(
                    color: userColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.person, color: userColor, size: size * 0.2),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          user.userName,
          style: theme.textTheme.titleSmall?.copyWith(
            color: userColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          '${NumberFormatUtils.currency.format(user.totalAmount)}${l10n.transactionAmountUnit}',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildSingleUserChart(
    BuildContext context,
    AppLocalizations l10n,
    UserCategoryStatistics user,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.statisticsCategoryDistribution,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Center(
              child: _buildUserDonut(
                context,
                l10n,
                user,
                size: 200,
                isHighlighted: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCombinedChart(
    BuildContext context,
    AppLocalizations l10n,
    List<UserCategoryStatistics> users,
  ) {
    final theme = Theme.of(context);

    // 모든 사용자의 카테고리를 합산
    final combinedCategories = <String, CategoryStatistics>{};
    int totalAmount = 0;

    for (final user in users) {
      totalAmount += user.totalAmount;
      for (final category in user.categories.values) {
        if (combinedCategories.containsKey(category.categoryId)) {
          combinedCategories[category.categoryId] =
              combinedCategories[category.categoryId]!.copyWith(
                amount:
                    combinedCategories[category.categoryId]!.amount +
                    category.amount,
              );
        } else {
          combinedCategories[category.categoryId] = category;
        }
      }
    }

    final sortedCategories = combinedCategories.values.toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    if (totalAmount == 0 || sortedCategories.isEmpty) {
      return _buildEmptyState(context, l10n);
    }

    final processedCategories = _processCategories(l10n, sortedCategories);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.statisticsCategoryDistribution,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 60,
                      sections: _buildSections(
                        processedCategories,
                        totalAmount,
                      ),
                      pieTouchData: PieTouchData(enabled: false),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.statisticsFilterCombined,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${NumberFormatUtils.currency.format(totalAmount)}${l10n.transactionAmountUnit}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<CategoryStatistics> _processCategories(
    AppLocalizations l10n,
    List<CategoryStatistics> categories,
  ) {
    if (categories.length <= 5) {
      return categories;
    }

    final top5 = categories.take(5).toList();
    final others = categories.skip(5).toList();
    final othersTotal = others.fold(0, (sum, item) => sum + item.amount);

    if (othersTotal > 0) {
      top5.add(
        CategoryStatistics(
          categoryId: '_others_',
          categoryName: l10n.statisticsOther,
          categoryIcon: '',
          categoryColor: '#9E9E9E',
          amount: othersTotal,
        ),
      );
    }

    return top5;
  }

  List<PieChartSectionData> _buildSections(
    List<CategoryStatistics> categories,
    int totalAmount,
  ) {
    return categories.map((category) {
      final percentage = totalAmount > 0
          ? (category.amount / totalAmount) * 100
          : 0.0;
      final color = _parseColor(category.categoryColor);

      return PieChartSectionData(
        color: color,
        value: category.amount.toDouble(),
        title: percentage >= 8 ? '${percentage.toStringAsFixed(0)}%' : '',
        radius: 40,
        titleStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }
}
