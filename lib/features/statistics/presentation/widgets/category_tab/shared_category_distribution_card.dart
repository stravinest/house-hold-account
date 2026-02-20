import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/utils/category_l10n_helper.dart';
import '../../../../../core/utils/color_utils.dart';
import '../../../../../core/utils/number_format_utils.dart';
import '../../../../../l10n/generated/app_localizations.dart';
import '../../../../../shared/widgets/category_icon.dart';
import '../../../../share/presentation/providers/share_provider.dart';
import '../common/member_tabs.dart';
import '../../../data/repositories/statistics_repository.dart';
import '../../../domain/entities/statistics_entities.dart';
import '../../providers/statistics_provider.dart';
import 'category_detail_bottom_sheet.dart';

/// 공유 가계부용 카테고리 분포 카드 - Pencil Nzqas + memberTabs 디자인 적용
class SharedCategoryDistributionCard extends ConsumerWidget {
  const SharedCategoryDistributionCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final userStatsAsync = ref.watch(categoryStatisticsByUserProvider);
    final sharedState = ref.watch(sharedStatisticsStateProvider);
    final membersAsync = ref.watch(currentLedgerMembersProvider);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Text(
            l10n.statisticsCategoryDistribution,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
          ),
          const SizedBox(height: 16),

          // 도넛 차트
          userStatsAsync.when(
            data: (userStats) {
              if (userStats.isEmpty) {
                return _buildEmptyState(context, l10n);
              }

              final users = userStats.values.toList()
                ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

              return _SharedDonutChart(users: users, sharedState: sharedState);
            },
            loading: () => const SizedBox(
              height: 220,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stack) => _buildEmptyState(context, l10n),
          ),
          const SizedBox(height: 16),

          // 사용자 선택 탭 (memberTabs) - 도넛 차트 아래 배치
          membersAsync.when(
            data: (members) {
              if (members.length < 2) {
                return const SizedBox.shrink();
              }

              return MemberTabs(
                members: members,
                sharedState: sharedState,
                onStateChanged: (newState) {
                  ref.read(sharedStatisticsStateProvider.notifier).state =
                      newState;
                },
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (error, stack) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 16),

          // 범례 리스트
          userStatsAsync.when(
            data: (userStats) {
              if (userStats.isEmpty) {
                return const SizedBox.shrink();
              }

              final users = userStats.values.toList()
                ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

              return _SharedLegendList(users: users, sharedState: sharedState, ref: ref);
            },
            loading: () => const SizedBox.shrink(),
            error: (error, stack) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 200,
      child: Center(
        child: Text(
          l10n.statisticsNoData,
          style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }
}

/// 도넛 차트 - 모드에 따라 다르게 표시
class _SharedDonutChart extends StatelessWidget {
  final List<UserCategoryStatistics> users;
  final SharedStatisticsState sharedState;

  const _SharedDonutChart({required this.users, required this.sharedState});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    // 모드에 따라 데이터 처리
    List<CategoryStatistics> categories;
    int totalAmount;
    String centerLabel;

    switch (sharedState.mode) {
      case SharedStatisticsMode.combined:
        // 합계: 모든 사용자의 카테고리 합산
        final combined = _getCombinedCategories();
        categories = combined.$1;
        totalAmount = combined.$2;
        centerLabel = l10n.statisticsFilterCombined;
        break;

      case SharedStatisticsMode.singleUser:
        // 특정 사용자만
        final selectedUser = users.firstWhere(
          (u) => u.userId == sharedState.selectedUserId,
          orElse: () => users.first,
        );
        categories = selectedUser.categoryList;
        totalAmount = selectedUser.totalAmount;
        centerLabel = selectedUser.userName;
        break;

      case SharedStatisticsMode.overlay:
        // 겹쳐서 모드에서는 합계와 동일하게 표시
        final combinedOverlay = _getCombinedCategories();
        categories = combinedOverlay.$1;
        totalAmount = combinedOverlay.$2;
        centerLabel = l10n.statisticsFilterCombined;
        break;
    }

    if (totalAmount == 0 || categories.isEmpty) {
      return Semantics(
        label: l10n.statisticsNoData,
        child: SizedBox(
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 0,
                  centerSpaceRadius: 60,
                  sections: [
                    PieChartSectionData(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                      value: 1,
                      title: '',
                      radius: 50,
                    ),
                  ],
                  pieTouchData: PieTouchData(enabled: false),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    centerLabel,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '0${l10n.transactionAmountUnit}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // 상위 5개 + 기타 처리
    final processedCategories = _processCategories(l10n, categories);

    return SizedBox(
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 60,
              sections: _buildSections(processedCategories, totalAmount),
              pieTouchData: PieTouchData(enabled: false),
            ),
          ),
          // 중앙 텍스트
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                centerLabel,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${NumberFormatUtils.currency.format(totalAmount)}${l10n.transactionAmountUnit}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  (List<CategoryStatistics>, int) _getCombinedCategories() {
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

    return (sortedCategories, totalAmount);
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
      final color = ColorUtils.parseHexColor(
        category.categoryColor,
        fallback: const Color(0xFF9E9E9E),
      );

      return PieChartSectionData(
        color: color,
        value: category.amount.toDouble(),
        title: percentage >= 8 ? '${percentage.toStringAsFixed(0)}%' : '',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }
}

/// 범례 리스트 - Pencil legend 디자인
class _SharedLegendList extends StatelessWidget {
  final List<UserCategoryStatistics> users;
  final SharedStatisticsState sharedState;
  final WidgetRef ref;

  const _SharedLegendList({
    required this.users,
    required this.sharedState,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final numberFormat = NumberFormatUtils.currency;
    final type = ref.read(selectedStatisticsTypeProvider);

    // 모드에 따라 데이터 처리
    List<CategoryStatistics> categories;
    int totalAmount;

    switch (sharedState.mode) {
      case SharedStatisticsMode.combined:
      case SharedStatisticsMode.overlay:
        final combined = _getCombinedCategories();
        categories = combined.$1;
        totalAmount = combined.$2;
        break;

      case SharedStatisticsMode.singleUser:
        final selectedUser = users.firstWhere(
          (u) => u.userId == sharedState.selectedUserId,
          orElse: () => users.first,
        );
        categories = selectedUser.categoryList;
        totalAmount = selectedUser.totalAmount;
        break;
    }

    if (categories.isEmpty) {
      return const SizedBox.shrink();
    }

    final displayStats = categories.take(5).toList();

    return Column(
      children: [
        if (displayStats.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                l10n.statisticsTapToDetail,
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ...displayStats.map((item) {
          final percentage = totalAmount > 0
              ? (item.amount / totalAmount) * 100
              : 0.0;

          return GestureDetector(
            onTap: () {
              final expenseFilter = ref.read(selectedExpenseTypeFilterProvider);
              CategoryDetailBottomSheet.show(
                context,
                ref,
                categoryId: item.categoryId,
                categoryName: CategoryL10nHelper.translate(
                  item.categoryName,
                  l10n,
                ),
                categoryColor: item.categoryColor,
                categoryIcon: item.categoryIcon,
                categoryPercentage: percentage,
                type: type,
                totalAmount: item.amount,
                isFixedExpenseFilter: expenseFilter == ExpenseTypeFilter.fixed,
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  CategoryIcon(
                    icon: item.categoryIcon,
                    name: item.categoryName,
                    color: item.categoryColor,
                    size: CategoryIconSize.small,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    CategoryL10nHelper.translate(item.categoryName, l10n),
                    style: const TextStyle(fontSize: 14),
                  ),
                  const Spacer(),
                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${numberFormat.format(item.amount)}${l10n.transactionAmountUnit}',
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  (List<CategoryStatistics>, int) _getCombinedCategories() {
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

    return (sortedCategories, totalAmount);
  }
}
