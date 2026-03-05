import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/snackbar_utils.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/themes/design_tokens.dart';
import '../../../../shared/widgets/skeleton_loading.dart';
import '../../../ledger/presentation/providers/ledger_provider.dart';
import '../../domain/entities/asset_goal.dart';
import '../providers/asset_goal_provider.dart';
import '../providers/asset_provider.dart';
import '../widgets/asset_category_list.dart';
import '../widgets/asset_donut_chart.dart';
import '../widgets/asset_goal_form_sheet.dart';
import '../widgets/asset_line_chart.dart';
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
                child: AssetLineChart(monthly: statistics.monthly),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: l10n.assetCategoryDistribution,
                child: AssetDonutChart(byCategory: statistics.byCategory),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: l10n.assetList,
                child: AssetCategoryList(assetStatistics: statistics),
              ),
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
    ref.invalidate(assetGoalsProvider);
    if (context.mounted) {
      SnackBarUtils.showSuccess(context, l10n.assetGoalDeleted);
    }
  }
}

// 자산 목표 섹션: assetOnlyGoalsProvider로 자산 목표만 필터링하여 리스트 표시
class _AssetGoalSection extends ConsumerWidget {
  final String ledgerId;

  const _AssetGoalSection({required this.ledgerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assetGoalsAsync = ref.watch(assetOnlyGoalsProvider);

    return assetGoalsAsync.when(
      data: (goals) {
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
      error: (e, _) => const SizedBox.shrink(),
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
    final currentAmountAsync = ref.watch(assetGoalCurrentAmountProvider(goal));
    final progress = ref.watch(assetGoalProgressProvider(goal));

    return currentAmountAsync.when(
      data: (currentAmount) {
        final numberFormat = NumberFormat('#,###');
        final remaining = goal.targetAmount - currentAmount;
        final progressPercent = (progress * 100).clamp(0, 100);
        final colorScheme = Theme.of(context).colorScheme;
        final progressColor = progress >= 1.0
            ? colorScheme.primary
            : colorScheme.error;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(20),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Icon(Icons.flag, size: 20, color: colorScheme.onPrimary),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            goal.title,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: onEdit,
                        icon: Icon(Icons.edit, size: 20, color: colorScheme.onSurfaceVariant),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        tooltip: l10n.tooltipEdit,
                      ),
                      IconButton(
                        onPressed: onDelete,
                        icon: Icon(Icons.delete, size: 20, color: colorScheme.error),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        tooltip: l10n.tooltipDelete,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '${numberFormat.format(goal.targetAmount)}${l10n.transactionAmountUnit}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.assetGoalCurrentWithAmount('${numberFormat.format(currentAmount)}${l10n.transactionAmountUnit}'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    l10n.assetGoalTargetWithAmount('${numberFormat.format(goal.targetAmount)}${l10n.transactionAmountUnit}'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                height: 12,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: colorScheme.outlineVariant,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final clampedProgress = progress.clamp(0.0, 1.0);
                    final displayProgress = progress >= 0.01 ? clampedProgress : 0.01;
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: constraints.maxWidth * displayProgress,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: progressColor,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      l10n.assetGoalAchievementPercent(progressPercent.toStringAsFixed(1)),
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colorScheme.onErrorContainer),
                    ),
                  ),
                  if (remaining > 0)
                    Text(
                      l10n.assetGoalRemainingWithUnit('${numberFormat.format(remaining)}${l10n.transactionAmountUnit}'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, _) => const SizedBox.shrink(),
    );
  }
}

// 대출 목표 섹션: loanGoalsProvider로 대출 목표만 필터링하여 표시
class _LoanGoalSection extends ConsumerWidget {
  final String ledgerId;

  const _LoanGoalSection({required this.ledgerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loanGoalsAsync = ref.watch(loanGoalsProvider);

    return loanGoalsAsync.when(
      data: (goals) {
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

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

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
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
