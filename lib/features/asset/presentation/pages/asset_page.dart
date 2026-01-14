import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../shared/themes/design_tokens.dart';
import '../../../ledger/presentation/providers/ledger_provider.dart';
import '../../domain/entities/asset_goal.dart';
import '../providers/asset_provider.dart';
import '../providers/asset_goal_provider.dart';
import '../widgets/asset_category_list.dart';
import '../widgets/asset_donut_chart.dart';
import '../widgets/asset_goal_form_sheet.dart';
import '../widgets/asset_line_chart.dart';

class AssetPage extends ConsumerWidget {
  const AssetPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statisticsAsync = ref.watch(assetStatisticsProvider);

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
              _AssetSummaryCard(
                totalAmount: statistics.totalAmount,
                monthlyChange: statistics.monthlyChange,
                ledgerId: ref.watch(selectedLedgerIdProvider),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: '자산 변화',
                child: AssetLineChart(monthly: statistics.monthly),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: '카테고리별 분포',
                child: AssetDonutChart(byCategory: statistics.byCategory),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: '자산 목록',
                child: AssetCategoryList(assetStatistics: statistics),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('오류: $error')),
      ),
    );
  }
}

class _AssetSummaryCard extends ConsumerStatefulWidget {
  final int totalAmount;
  final int monthlyChange;
  final String? ledgerId;

  const _AssetSummaryCard({
    required this.totalAmount,
    required this.monthlyChange,
    this.ledgerId,
  });

  @override
  ConsumerState<_AssetSummaryCard> createState() => _AssetSummaryCardState();
}

class _AssetSummaryCardState extends ConsumerState<_AssetSummaryCard> {
  bool _showGoalDetails = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final numberFormat = NumberFormat('#,###');
    final isPositive = widget.monthlyChange >= 0;
    final goalsAsync = widget.ledgerId != null
        ? ref.watch(assetGoalNotifierProvider(widget.ledgerId!))
        : null;
    final hasGoal = goalsAsync?.value?.isNotEmpty ?? false;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '총 자산',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (widget.ledgerId != null && !hasGoal)
                  OutlinedButton.icon(
                    onPressed: () => _showGoalFormSheet(context, ref, null),
                    icon: const Icon(Icons.flag_outlined, size: 16),
                    label: const Text('목표 설정'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${numberFormat.format(widget.totalAmount)}원',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 16,
                  color: isPositive
                      ? theme.colorScheme.tertiary
                      : theme.colorScheme.error,
                ),
                const SizedBox(width: 4),
                Text(
                  '이번 달 ${isPositive ? '+' : ''}${numberFormat.format(widget.monthlyChange)}원',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isPositive
                        ? theme.colorScheme.tertiary
                        : theme.colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (widget.ledgerId != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              _buildGoalSection(
                context,
                ref,
                widget.ledgerId!,
                numberFormat,
                theme,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showGoalFormSheet(
    BuildContext context,
    WidgetRef ref,
    AssetGoal? goal,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AssetGoalFormSheet(goal: goal),
    );
  }

  Future<void> _deleteGoal(
    BuildContext context,
    WidgetRef ref,
    AssetGoal goal,
    String ledgerId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('목표 삭제'),
        content: Text('\'${goal.title}\' 목표를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final notifier = ref.read(assetGoalNotifierProvider(ledgerId).notifier);
        await notifier.deleteGoal(goal.id);
        ref.invalidate(assetGoalsProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('목표가 삭제되었습니다')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('삭제 실패: $e')));
        }
      }
    }
  }

  Widget _buildGoalSection(
    BuildContext context,
    WidgetRef ref,
    String ledgerId,
    NumberFormat numberFormat,
    ThemeData theme,
  ) {
    final goalsAsync = ref.watch(assetGoalNotifierProvider(ledgerId));

    return goalsAsync.when(
      data: (goals) {
        if (goals.isEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.3,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.flag_rounded,
                    size: 32,
                    color: theme.colorScheme.primary.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '목표를 설정하고\n자산을 계획적으로 관리하세요',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final sortedGoals = List.of(goals)
          ..sort((a, b) {
            if (a.targetDate == null && b.targetDate == null) return 0;
            if (a.targetDate == null) return 1;
            if (b.targetDate == null) return -1;
            return a.targetDate!.compareTo(b.targetDate!);
          });
        final nearestGoal = sortedGoals.first;

        final currentAmountAsync = ref.watch(
          assetGoalCurrentAmountProvider(nearestGoal),
        );
        final progress = ref.watch(assetGoalProgressProvider(nearestGoal));
        final remainingDays = ref.watch(
          assetGoalRemainingDaysProvider(nearestGoal),
        );

        return currentAmountAsync.when(
          data: (currentAmount) {
            final progressColor = _getProgressColor(progress, theme);
            final clampedProgress = progress.clamp(0.0, 1.0);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Goal label + D-day badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.flag_rounded,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '목표',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    if (remainingDays != null)
                      _buildDDayBadge(remainingDays, theme),
                  ],
                ),
                const SizedBox(height: 16),

                // Goal target amount with action buttons
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${numberFormat.format(nearestGoal.targetAmount)}원',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      icon: Icons.edit_rounded,
                      onPressed: () =>
                          _showGoalFormSheet(context, ref, nearestGoal),
                      theme: theme,
                    ),
                    const SizedBox(width: 4),
                    _buildActionButton(
                      icon: Icons.delete_rounded,
                      onPressed: () =>
                          _deleteGoal(context, ref, nearestGoal, ledgerId),
                      theme: theme,
                      isDestructive: true,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Progress bar with percentage indicator above current position
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showGoalDetails = !_showGoalDetails;
                    });
                  },
                  child: SizedBox(
                    width: double.infinity,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final barWidth = constraints.maxWidth;
                        final percentPosition = barWidth * clampedProgress;
                        final percentText =
                            '${(progress * 100).toStringAsFixed(1)}%';

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Percentage indicator positioned above progress
                            SizedBox(
                              height: 24,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Positioned(
                                    left: percentPosition,
                                    bottom: 0,
                                    child: Transform.translate(
                                      offset: const Offset(-20, 0),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: progressColor.withValues(
                                            alpha: 0.15,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          percentText,
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: progressColor,
                                                fontSize: 11,
                                              ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),

                            // Thin rectangular progress bar
                            SizedBox(
                              width: double.infinity,
                              height: 10,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: theme.brightness == Brightness.dark
                                      ? Colors.white.withValues(alpha: 0.15)
                                      : theme
                                            .colorScheme
                                            .surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(
                                    BorderRadiusToken.xs,
                                  ),
                                  border: Border.all(
                                    color: theme.brightness == Brightness.dark
                                        ? Colors.white.withValues(alpha: 0.6)
                                        : theme.colorScheme.onSurfaceVariant,
                                    width: 1,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    BorderRadiusToken.xs,
                                  ),
                                  child: FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: clampedProgress,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            progressColor.withValues(
                                              alpha: 0.9,
                                            ),
                                            progressColor,
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),

                            // 0% and 100% labels at ends
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '0%',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.6),
                                    fontSize: 10,
                                  ),
                                ),
                                Text(
                                  '100%',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.6),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Amount display with arrow
                if (_showGoalDetails) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        // Current amount
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '현재',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${numberFormat.format(currentAmount)}원',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Arrow indicator
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.1,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        // Target amount
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '목표',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${numberFormat.format(nearestGoal.targetAmount)}원',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Remaining amount info
                  if (nearestGoal.targetAmount > currentAmount) ...[
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        '${numberFormat.format(nearestGoal.targetAmount - currentAmount)}원 남음',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ] else if (progress >= 1.0) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '목표 달성 완료!',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ] else
                  Center(
                    child: Text(
                      '탭하여 상세 금액 보기',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
          loading: () => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
          error: (error, stack) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 20,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '목표 정보를 불러올 수 없습니다',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      ),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }

  Widget _buildDDayBadge(int remainingDays, ThemeData theme) {
    final bool isOverdue = remainingDays < 0;
    final bool isUrgent = remainingDays >= 0 && remainingDays < 30;

    final Color badgeColor = isOverdue
        ? theme.colorScheme.error
        : isUrgent
        ? theme.colorScheme.tertiary
        : theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            badgeColor.withValues(alpha: 0.15),
            badgeColor.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOverdue ? Icons.schedule : Icons.timer_outlined,
            size: 14,
            color: badgeColor,
          ),
          const SizedBox(width: 4),
          Text(
            isOverdue
                ? 'D+${(-remainingDays).toString()}'
                : 'D-${remainingDays.toString()}',
            style: theme.textTheme.labelMedium?.copyWith(
              color: badgeColor,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    required ThemeData theme,
    bool isDestructive = false,
  }) {
    final color = isDestructive
        ? theme.colorScheme.error.withValues(alpha: 0.7)
        : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }

  Color _getProgressColor(double progress, ThemeData theme) {
    if (progress >= 1.0) return theme.colorScheme.primary;
    if (progress >= 0.75) return theme.colorScheme.tertiary;
    if (progress >= 0.5) return theme.colorScheme.secondary;
    return theme.colorScheme.error;
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
      ),
    );
  }
}
