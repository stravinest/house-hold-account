import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/snackbar_utils.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/themes/design_tokens.dart';
import '../../../../shared/widgets/skeleton_loading.dart';
import '../../../ledger/presentation/providers/ledger_provider.dart';
import '../../../share/presentation/providers/share_provider.dart';
import '../../../statistics/presentation/providers/statistics_provider.dart';
import '../../../statistics/presentation/widgets/common/member_tabs.dart';
import '../../domain/entities/asset_goal.dart';
import '../../domain/entities/asset_statistics.dart';
import '../providers/asset_goal_provider.dart';
import '../providers/asset_provider.dart';
import '../widgets/asset_category_list.dart';
import '../widgets/asset_donut_chart.dart';
import '../widgets/asset_goal_form_sheet.dart';
import '../widgets/asset_line_chart.dart';
import '../widgets/asset_period_dropdown.dart';
import '../widgets/asset_summary_card.dart';
import '../widgets/goal_type_selector.dart';
import '../widgets/loan_goal_card.dart';
import '../widgets/loan_goal_form_sheet.dart';

class AssetPage extends ConsumerWidget {
  const AssetPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final statisticsAsync = ref.watch(assetStatisticsProvider);
    final ledgerId = ref.watch(selectedLedgerIdProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(assetStatisticsProvider);
        ref.invalidate(assetMonthlyChartProvider);
        ref.invalidate(assetYearlyChartProvider);
        ref.invalidate(assetFilteredByCategoryProvider);
        await ref.read(assetStatisticsProvider.future);
      },
      child: statisticsAsync.when(
        data: (statistics) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AssetSummaryCard(
                totalAmount: statistics.totalAmount,
                monthlyChange: statistics.monthlyChange,
                ledgerId: ledgerId,
              ),
              if (ledgerId != null) ...[
                _AssetGoalSection(ledgerId: ledgerId),
                _LoanGoalSection(ledgerId: ledgerId),
                _AddGoalButton(ledgerId: ledgerId),
              ],
              const SizedBox(height: 16),
              _SectionCard(
                title: l10n.assetChange,
                filter: const AssetPeriodDropdown(),
                child: const AssetLineChart(),
              ),
              const SizedBox(height: 16),
              const _FilteredCategorySection(),
              const SizedBox(height: 80),
            ],
          ),
        ),
        loading: () => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0D000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLine(width: 80, height: 16),
                    SizedBox(height: 8),
                    SkeletonLine(width: 160, height: 32),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        SkeletonBox(
                          width: 16,
                          height: 16,
                          borderRadius: BorderRadiusToken.xs,
                        ),
                        SizedBox(width: 4),
                        SkeletonLine(width: 100, height: 14),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0D000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            SkeletonBox(
                              width: 28,
                              height: 28,
                              borderRadius: BorderRadiusToken.xs,
                            ),
                            SizedBox(width: 8),
                            SkeletonLine(width: 50, height: 16),
                          ],
                        ),
                        Row(
                          children: [
                            SkeletonBox(
                              width: 20,
                              height: 20,
                              borderRadius: BorderRadiusToken.xs,
                            ),
                            SizedBox(width: 8),
                            SkeletonBox(
                              width: 20,
                              height: 20,
                              borderRadius: BorderRadiusToken.xs,
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    SkeletonLine(width: 150, height: 28),
                    SizedBox(height: 16),
                    SkeletonLine(width: double.infinity, height: 12),
                    SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SkeletonLine(width: 80, height: 14),
                        SkeletonLine(width: 100, height: 14),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0D000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLine(width: 100, height: 18),
                    SizedBox(height: 16),
                    SkeletonBox(
                      width: double.infinity,
                      height: 200,
                      borderRadius: BorderRadiusToken.md,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0D000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLine(width: 120, height: 18),
                    SizedBox(height: 16),
                    Center(child: SkeletonCircle(size: 180)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0D000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SkeletonLine(width: 80, height: 18),
                    const SizedBox(height: 16),
                    ...List.generate(
                      3,
                      (index) => const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Expanded(child: SkeletonLine(height: 16)),
                            SizedBox(width: 16),
                            SkeletonLine(width: 80, height: 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
        error: (error, stackTrace) =>
            Center(child: Text(l10n.errorWithMessage(error.toString()))),
      ),
    );
  }
}

Future<void> _confirmAndDeleteGoal(
  BuildContext context,
  WidgetRef ref,
  String ledgerId,
  AssetGoal goal,
) async {
  final l10n = AppLocalizations.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.assetGoalDeleteTitle),
      content: Text(l10n.assetGoalDeleteMessage(goal.title)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.commonCancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.commonDelete),
        ),
      ],
    ),
  );
  if (confirmed == true && context.mounted) {
    final notifier = ref.read(assetGoalNotifierProvider(ledgerId).notifier);
    await notifier.deleteGoal(goal.id);
    if (context.mounted) {
      SnackBarUtils.showSuccess(context, l10n.assetGoalDeleted);
    }
  }
}

// 자산 목표 섹션: assetGoalNotifierProvider를 직접 watch하여 자산 목표만 필터링
class _AssetGoalSection extends ConsumerWidget {
  final String ledgerId;

  const _AssetGoalSection({required this.ledgerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allGoalsAsync = ref.watch(assetGoalNotifierProvider(ledgerId));

    return allGoalsAsync.when(
      data: (allGoals) {
        final goals = allGoals.where((g) => g.goalType == GoalType.asset).toList();
        if (goals.isEmpty) return const SizedBox.shrink();
        return Column(
          children: goals.map((goal) {
            return _AssetGoalItem(
              goal: goal,
              ledgerId: ledgerId,
              onEdit: () => _showAssetFormSheet(context, goal),
              onDelete: () => _confirmAndDeleteGoal(context, ref, ledgerId, goal),
            );
          }).toList(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, _) {
        return const SizedBox.shrink();
      },
    );
  }

  void _showAssetFormSheet(BuildContext context, AssetGoal goal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => goal.goalType == GoalType.loan
          ? LoanGoalFormSheet(goal: goal)
          : AssetGoalFormSheet(goal: goal),
    );
  }
}

class _AssetGoalItem extends ConsumerWidget {
  final AssetGoal goal;
  final String ledgerId;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AssetGoalItem({
    required this.goal,
    required this.ledgerId,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final currentAmountAsync = ref.watch(assetGoalCurrentAmountProvider(goal));
    final progress = ref.watch(assetGoalProgressProvider(goal));
    final remainingDays = ref.watch(assetGoalRemainingDaysProvider(goal));

    return currentAmountAsync.when(
      data: (currentAmount) {
        final remaining = goal.targetAmount - currentAmount;
        final clampedProgress = progress.clamp(0.0, 1.0);
        final progressColor = colorScheme.primary;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 헤더: 배지 + 제목 + 수정/삭제
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withAlpha(26),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.flag_outlined,
                            size: 14,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            l10n.assetGoalTitle,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        goal.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined),
                      iconSize: 20,
                      tooltip: l10n.tooltipEdit,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                    ),
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline),
                      iconSize: 20,
                      tooltip: l10n.tooltipDelete,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 목표 금액
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.assetGoalTargetAmount,
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatCurrency(goal.targetAmount),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 달성률 + 프로그래스 바
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.assetGoalAchievementRate,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '${(clampedProgress * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: progressColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: clampedProgress,
                    minHeight: 8,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  ),
                ),
                const SizedBox(height: 12),

                // 상세 정보
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _buildInfoItem(
                      context,
                      icon: Icons.account_balance_wallet_outlined,
                      label: l10n.assetGoalCurrentAmount,
                      value: _formatCurrency(currentAmount),
                    ),
                    if (remaining > 0)
                      _buildInfoItem(
                        context,
                        icon: Icons.trending_up,
                        label: l10n.assetGoalTargetAmount,
                        value: _formatCurrency(goal.targetAmount),
                      ),
                    if (goal.targetDate != null)
                      _buildInfoItem(
                        context,
                        icon: Icons.flag_outlined,
                        label: l10n.assetGoalDateOptional,
                        value: DateFormat('yyyy.MM.dd').format(goal.targetDate!),
                      ),
                    if (remainingDays != null && remainingDays > 0)
                      _buildInfoItem(
                        context,
                        icon: Icons.access_time,
                        label: 'D-Day',
                        value: l10n.assetGoalDaysRemaining(remainingDays),
                      ),
                    if (progress >= 1.0)
                      _buildInfoItem(
                        context,
                        icon: Icons.check_circle_outline,
                        label: l10n.assetGoalCompleted,
                        value: l10n.assetGoalCompleted,
                        isHighlighted: true,
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildInfoItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    bool isHighlighted = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final bgColor = isHighlighted
        ? colorScheme.primary.withAlpha(20)
        : colorScheme.surfaceContainerHighest;
    final labelColor = isHighlighted
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 11, color: labelColor),
              const SizedBox(width: 3),
              Text(label, style: TextStyle(fontSize: 10, color: labelColor)),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(int amount) {
    return '₩${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }
}

// 대출 목표 섹션: assetGoalNotifierProvider를 직접 watch하여 대출 목표만 필터링
class _LoanGoalSection extends ConsumerWidget {
  final String ledgerId;

  const _LoanGoalSection({required this.ledgerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allGoalsAsync = ref.watch(assetGoalNotifierProvider(ledgerId));

    return allGoalsAsync.when(
      data: (allGoals) {
        final goals = allGoals.where((g) => g.goalType == GoalType.loan).toList();
        if (goals.isEmpty) return const SizedBox.shrink();
        return Column(
          children: goals.map((goal) {
            return LoanGoalCard(
              goal: goal,
              onEdit: () => _showLoanFormSheet(context, goal),
              onDelete: () => _confirmAndDeleteGoal(context, ref, ledgerId, goal),
            );
          }).toList(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, _) => const SizedBox.shrink(),
    );
  }

  void _showLoanFormSheet(BuildContext context, AssetGoal goal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LoanGoalFormSheet(goal: goal),
    );
  }
}

// 목표 추가 버튼: GoalType 선택 후 적절한 폼 시트 표시
class _AddGoalButton extends StatelessWidget {
  final String ledgerId;

  const _AddGoalButton({required this.ledgerId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: OutlinedButton.icon(
        onPressed: () => _onAddGoal(context),
        icon: Icon(Icons.add, color: colorScheme.primary),
        label: Text(
          l10n.assetGoalNew,
          style: TextStyle(color: colorScheme.primary),
        ),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          side: BorderSide(color: colorScheme.primary.withAlpha(128)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Future<void> _onAddGoal(BuildContext context) async {
    final goalType = await showGoalTypeSelector(context);
    if (goalType == null || !context.mounted) return;

    if (goalType == GoalType.asset) {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => const AssetGoalFormSheet(),
      );
    } else {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => const LoanGoalFormSheet(),
      );
    }
  }
}

// 유저 필터가 적용된 카테고리별 분포 + 자산 목록 섹션
class _FilteredCategorySection extends ConsumerWidget {
  const _FilteredCategorySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final filteredCategoryAsync = ref.watch(assetFilteredByCategoryProvider);
    final isShared = ref.watch(isSharedLedgerProvider);

    // 탭 전환 시 이전 데이터를 유지하여 스크롤 위치가 초기화되지 않도록 함
    final byCategory = filteredCategoryAsync.valueOrNull;
    final isLoading = filteredCategoryAsync.isLoading;
    final hasError = filteredCategoryAsync.hasError;

    if (byCategory == null && isLoading) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (hasError && byCategory == null) {
      return Center(
        child: Text(l10n.errorWithMessage(
          filteredCategoryAsync.error.toString(),
        )),
      );
    }

    final data = byCategory ?? [];

    return Column(
      children: [
        // 카테고리별 분포 카드
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.assetCategoryDistribution,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  AnimatedOpacity(
                    opacity: isLoading ? 0.5 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: AssetDonutChart(byCategory: data),
                  ),
                  if (isShared) ...[
                    const SizedBox(height: 16),
                    _buildMemberTabs(ref),
                  ],
                ],
              ),
              if (isLoading)
                Positioned.fill(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface.withAlpha(180),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // 자산 목록 카드
        AnimatedOpacity(
          opacity: isLoading ? 0.5 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: _SectionCard(
            title: l10n.assetList,
            child: AssetCategoryList(
              assetStatistics: AssetStatistics(
                totalAmount: data.fold(0, (sum, c) => sum + c.amount),
                monthlyChange: 0,
                monthlyChangeRate: 0,
                annualGrowthRate: 0,
                monthly: const [],
                byCategory: data,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMemberTabs(WidgetRef ref) {
    final membersAsync = ref.watch(currentLedgerMembersProvider);
    final sharedState = ref.watch(assetSharedStateProvider);

    return membersAsync.when(
      data: (members) {
        if (members.length < 2) return const SizedBox.shrink();

        return MemberTabs(
          members: members,
          sharedState: sharedState,
          onStateChanged: (newState) {
            ref.read(assetSharedStateProvider.notifier).state = newState;
          },
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget? filter;
  final Widget child;

  const _SectionCard({
    required this.title,
    this.filter,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (filter != null) filter!,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
