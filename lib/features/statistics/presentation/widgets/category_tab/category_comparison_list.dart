import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/utils/number_format_utils.dart';
import '../../../../../l10n/generated/app_localizations.dart';
import '../../../data/repositories/statistics_repository.dart';
import '../../providers/statistics_provider.dart';

/// 카테고리별 비교 막대 리스트 위젯
/// 각 카테고리에서 사용자별 금액을 비교하는 가로 막대 차트
class CategoryComparisonList extends ConsumerWidget {
  const CategoryComparisonList({super.key});

  Color _parseColor(String? colorString) {
    if (colorString == null) return const Color(0xFF9E9E9E);
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
          return const SizedBox.shrink();
        }

        final users = userStats.values.toList()
          ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

        // 모드에 따라 다르게 표시
        if (sharedState.mode == SharedStatisticsMode.overlay) {
          return _buildComparisonList(context, l10n, users);
        } else if (sharedState.mode == SharedStatisticsMode.singleUser) {
          final selectedUser = users.firstWhere(
            (u) => u.userId == sharedState.selectedUserId,
            orElse: () => users.first,
          );
          return _buildSingleUserList(context, l10n, selectedUser);
        } else {
          // combined: 합산 리스트
          return _buildCombinedList(context, l10n, users);
        }
      },
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(child: Text(l10n.errorWithMessage(error.toString()))),
        ),
      ),
    );
  }

  /// 사용자별 비교 리스트 (겹쳐서 모드)
  Widget _buildComparisonList(
    BuildContext context,
    AppLocalizations l10n,
    List<UserCategoryStatistics> users,
  ) {
    final theme = Theme.of(context);

    // 모든 카테고리 ID 수집
    final allCategoryIds = <String>{};
    for (final user in users) {
      allCategoryIds.addAll(user.categories.keys);
    }

    // 카테고리별로 총액 계산하여 정렬
    final categoryTotals = <String, int>{};
    for (final categoryId in allCategoryIds) {
      int total = 0;
      for (final user in users) {
        total += user.categories[categoryId]?.amount ?? 0;
      }
      categoryTotals[categoryId] = total;
    }

    final sortedCategoryIds = categoryTotals.keys.toList()
      ..sort((a, b) => categoryTotals[b]!.compareTo(categoryTotals[a]!));

    // 상위 10개만 표시
    final displayCategories = sortedCategoryIds.take(10).toList();

    if (displayCategories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              l10n.statisticsCategoryComparison,
              style: theme.textTheme.titleMedium,
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayCategories.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final categoryId = displayCategories[index];
              return _buildComparisonItem(
                context,
                l10n,
                categoryId,
                users,
                categoryTotals[categoryId]!,
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildComparisonItem(
    BuildContext context,
    AppLocalizations l10n,
    String categoryId,
    List<UserCategoryStatistics> users,
    int categoryTotal,
  ) {
    final theme = Theme.of(context);

    // 카테고리 정보 가져오기 (첫 번째로 찾은 사용자의 카테고리 정보 사용)
    CategoryStatistics? categoryInfo;
    for (final user in users) {
      if (user.categories.containsKey(categoryId)) {
        categoryInfo = user.categories[categoryId];
        break;
      }
    }

    if (categoryInfo == null) {
      return const SizedBox.shrink();
    }

    // 사용자별 금액
    final userAmounts = <UserCategoryStatistics, int>{};
    for (final user in users) {
      userAmounts[user] = user.categories[categoryId]?.amount ?? 0;
    }

    // 최대 금액 계산 (막대 비율 계산용)
    final maxAmount = userAmounts.values.reduce((a, b) => a > b ? a : b);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 카테고리명
          Row(
            children: [
              Expanded(
                child: Text(
                  categoryInfo.categoryName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                '${NumberFormatUtils.currency.format(categoryTotal)}${l10n.transactionAmountUnit}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 사용자별 막대
          ...users.map((user) {
            final amount = userAmounts[user] ?? 0;
            final ratio = maxAmount > 0 ? amount / maxAmount : 0.0;
            final userColor = _parseColor(user.userColor);

            return Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  // 사용자 색상 표시
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: userColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 막대
                  Expanded(
                    child: Stack(
                      children: [
                        Container(
                          height: 16,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: ratio.clamp(0.0, 1.0),
                          child: Container(
                            height: 16,
                            decoration: BoxDecoration(
                              color: userColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 4),
                            child: ratio > 0.25
                                ? Text(
                                    NumberFormatUtils.compact(amount),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 금액 (막대 밖에 표시)
                  if (ratio <= 0.25) ...[
                    const SizedBox(width: 8),
                    Text(
                      NumberFormatUtils.compact(amount),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  /// 단일 사용자 리스트
  Widget _buildSingleUserList(
    BuildContext context,
    AppLocalizations l10n,
    UserCategoryStatistics user,
  ) {
    final theme = Theme.of(context);
    final categories = user.categoryList.take(10).toList();
    final maxAmount =
        categories.isNotEmpty ? categories.first.amount : 0;

    if (categories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              l10n.statisticsCategoryRanking,
              style: theme.textTheme.titleMedium,
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: categories.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final category = categories[index];
              final ratio = maxAmount > 0 ? category.amount / maxAmount : 0.0;
              final percentage = user.totalAmount > 0
                  ? (category.amount / user.totalAmount * 100)
                  : 0.0;

              return _buildRankingItem(
                context,
                l10n,
                index + 1,
                category,
                ratio,
                percentage,
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildRankingItem(
    BuildContext context,
    AppLocalizations l10n,
    int rank,
    CategoryStatistics category,
    double ratio,
    double percentage,
  ) {
    final theme = Theme.of(context);
    final color = _parseColor(category.categoryColor);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 24,
                child: Text(
                  '$rank',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: rank <= 3
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  category.categoryName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${NumberFormatUtils.currency.format(category.amount)}${l10n.transactionAmountUnit}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0),
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  /// 합산 리스트
  Widget _buildCombinedList(
    BuildContext context,
    AppLocalizations l10n,
    List<UserCategoryStatistics> users,
  ) {
    final theme = Theme.of(context);

    // 모든 카테고리 합산
    final combinedCategories = <String, CategoryStatistics>{};
    int totalAmount = 0;

    for (final user in users) {
      for (final category in user.categories.values) {
        if (combinedCategories.containsKey(category.categoryId)) {
          combinedCategories[category.categoryId] =
              combinedCategories[category.categoryId]!.copyWith(
            amount: combinedCategories[category.categoryId]!.amount +
                category.amount,
          );
        } else {
          combinedCategories[category.categoryId] = category;
        }
        totalAmount += category.amount;
      }
    }

    final sortedCategories = combinedCategories.values.toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    final categories = sortedCategories.take(10).toList();
    final maxAmount = categories.isNotEmpty ? categories.first.amount : 0;

    if (categories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              l10n.statisticsCategoryRanking,
              style: theme.textTheme.titleMedium,
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: categories.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final category = categories[index];
              final ratio = maxAmount > 0 ? category.amount / maxAmount : 0.0;
              final percentage =
                  totalAmount > 0 ? (category.amount / totalAmount * 100) : 0.0;

              return _buildRankingItem(
                context,
                l10n,
                index + 1,
                category,
                ratio,
                percentage,
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
