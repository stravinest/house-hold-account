import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/utils/category_l10n_helper.dart';
import '../../../../../core/utils/color_utils.dart';
import '../../../../../core/utils/number_format_utils.dart';
import '../../../../../l10n/generated/app_localizations.dart';
import '../../../../../shared/widgets/category_icon.dart';
import '../../../../ledger/domain/entities/ledger.dart';
import '../../../../share/presentation/providers/share_provider.dart';
import '../../../data/repositories/statistics_repository.dart';
import '../../providers/statistics_provider.dart';

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

              return _MemberTabs(
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

              return _SharedLegendList(users: users, sharedState: sharedState);
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

/// 사용자 선택 탭 - Pencil memberTabs (nkQZa) 디자인
/// 각 탭이 동일한 너비를 차지하고, 유저별 고유 색상 적용
class _MemberTabs extends StatelessWidget {
  final List<LedgerMember> members;
  final SharedStatisticsState sharedState;
  final ValueChanged<SharedStatisticsState> onStateChanged;

  const _MemberTabs({
    required this.members,
    required this.sharedState,
    required this.onStateChanged,
  });

  String _getDisplayName(LedgerMember member) {
    if (member.displayName != null && member.displayName!.isNotEmpty) {
      return member.displayName!;
    }
    if (member.email != null && member.email!.isNotEmpty) {
      return member.email!.split('@').first;
    }
    return 'User';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        children: [
          // 합계 버튼
          Expanded(
            child: _buildTabButton(
              context: context,
              label: l10n.statisticsFilterCombined,
              isSelected: sharedState.mode == SharedStatisticsMode.combined,
              userColor: null, // 합계는 유저 색상 없음
              onTap: () {
                onStateChanged(
                  const SharedStatisticsState(
                    mode: SharedStatisticsMode.combined,
                  ),
                );
              },
            ),
          ),

          // 사용자별 버튼 - LedgerMember.color 직접 사용
          ...members.map((member) {
            final isSelected =
                sharedState.mode == SharedStatisticsMode.singleUser &&
                sharedState.selectedUserId == member.userId;
            final displayName = _getDisplayName(member);

            return Expanded(
              child: _buildTabButton(
                context: context,
                label: displayName,
                isSelected: isSelected,
                userColor: member.color, // LedgerMember에서 직접 가져옴
                onTap: () {
                  onStateChanged(
                    SharedStatisticsState(
                      mode: SharedStatisticsMode.singleUser,
                      selectedUserId: member.userId,
                    ),
                  );
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required String? userColor,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final parsedUserColor = ColorUtils.parseHexColor(userColor, fallback: const Color(0xFF9E9E9E));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 유저 색상 동그라미 (유저 탭일 경우만)
            if (userColor != null) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isSelected ? colorScheme.onPrimary : parsedUserColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
            ],
            // 라벨 (긴 텍스트 말줄임 처리)
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                  color: isSelected
                      ? colorScheme.onPrimary
                      : (userColor != null
                            ? parsedUserColor
                            : colorScheme.onSurfaceVariant),
                ),
              ),
            ),
          ],
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
      final color = ColorUtils.parseHexColor(category.categoryColor, fallback: const Color(0xFF9E9E9E));

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

  const _SharedLegendList({required this.users, required this.sharedState});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final numberFormat = NumberFormatUtils.currency;

    // 모드에 따라 데이터 처리
    List<CategoryStatistics> categories;
    int totalAmount;

    switch (sharedState.mode) {
      case SharedStatisticsMode.combined:
      case SharedStatisticsMode.overlay:
        // 합계: 모든 사용자의 카테고리 합산
        final combined = _getCombinedCategories();
        categories = combined.$1;
        totalAmount = combined.$2;
        break;

      case SharedStatisticsMode.singleUser:
        // 특정 사용자만
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

    // 상위 5개만 표시
    final displayStats = categories.take(5).toList();

    return Column(
      children: displayStats.map((item) {
        final percentage = totalAmount > 0
            ? (item.amount / totalAmount) * 100
            : 0.0;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              // 카테고리 아이콘
              CategoryIcon(
                icon: item.categoryIcon,
                name: item.categoryName,
                color: item.categoryColor,
                size: CategoryIconSize.small,
              ),
              const SizedBox(width: 8),
              // 카테고리명
              Text(
                CategoryL10nHelper.translate(item.categoryName, l10n),
                style: const TextStyle(fontSize: 14),
              ),
              // Spacer
              const Spacer(),
              // 퍼센트
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 12),
              // 금액
              Text(
                '${numberFormat.format(item.amount)}${l10n.transactionAmountUnit}',
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      }).toList(),
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
