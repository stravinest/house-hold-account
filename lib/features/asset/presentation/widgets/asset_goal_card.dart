import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/snackbar_utils.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/themes/design_tokens.dart' as tokens;
import '../../../../shared/widgets/empty_state.dart';
import '../../domain/entities/asset_goal.dart';
import '../providers/asset_goal_provider.dart';

class AssetGoalCard extends ConsumerWidget {
  final AssetGoal goal;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const AssetGoalCard({
    super.key,
    required this.goal,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentAmount = ref.watch(assetGoalCurrentAmountProvider(goal));
    final progress = ref.watch(assetGoalProgressProvider(goal));
    final remainingDays = ref.watch(assetGoalRemainingDaysProvider(goal));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      goal.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (onDelete != null)
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline),
                      iconSize: 20,
                      tooltip: l10n.tooltipDelete,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              currentAmount.when(
                data: (amount) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProgressBar(context, l10n, progress),
                    const SizedBox(height: 8),
                    _buildAmountRow(context, l10n, amount),
                    const SizedBox(height: 8),
                    _buildInfoRow(context, l10n, remainingDays, progress),
                  ],
                ),
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, stack) => Text(
                  '오류: $error',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(
    BuildContext context,
    AppLocalizations l10n,
    double progress,
  ) {
    final progressColor = _getProgressColor(progress);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final clampedProgress = progress.clamp(0.0, 1.0);
    final isCompleted = progress >= 1.0;

    // 배경 트랙 색상 - 미달성 영역을 명확하게 표시
    final colorScheme = Theme.of(context).colorScheme;
    final trackColor = isDark
        ? colorScheme.surfaceContainerHighest
        : colorScheme.surfaceContainerHighest;

    // 내부 그림자 색상
    final innerShadowColor = colorScheme.shadow.withValues(
      alpha: isDark ? 0.4 : 0.1,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 달성률 라벨
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                l10n.assetGoalAchievementRate,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
              // 퍼센트 강조 표시
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${(progress * 100).toStringAsFixed(1)}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: progressColor,
                      height: 1,
                    ),
                  ),
                  Text(
                    '%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: progressColor.withValues(alpha: 0.7),
                    ),
                  ),
                  if (isCompleted) ...[
                    const SizedBox(width: 6),
                    Icon(Icons.check_circle, size: 20, color: progressColor),
                  ],
                ],
              ),
            ],
          ),
        ),

        // 커스텀 진행률 바 - 전체 목표 범위(0%~100%)를 명확히 표시
        Container(
          height: 18,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(tokens.BorderRadiusToken.sm),
            color: trackColor,
            // 내부 그림자로 입체감
            boxShadow: [
              BoxShadow(
                color: innerShadowColor,
                offset: const Offset(0, 2),
                blurRadius: 4,
                spreadRadius: -2,
              ),
            ],
            // 전체 목표 범위(0%~100%)를 명확히 표시하는 강화된 테두리
            border: Border.all(color: colorScheme.outline, width: 2.0),
          ),
          child: ClipRRect(
            // 테두리 두께(2px)를 고려하여 내부 borderRadius 조정
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                // 배경 패턴 (미달성 영역 표시 - 전체 목표의 일부임을 시각화)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _ProgressTrackPainter(
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: isDark ? 0.2 : 0.5,
                      ),
                    ),
                  ),
                ),

                // 진행률 바 (그라데이션) - 달성 영역
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: clampedProgress,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: LinearGradient(
                        colors: [
                          progressColor,
                          _getLighterColor(progressColor),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      boxShadow: [
                        // 바 그림자
                        BoxShadow(
                          color: progressColor.withValues(alpha: 0.4),
                          offset: const Offset(0, 2),
                          blurRadius: 4,
                        ),
                        // 빛나는 효과
                        if (progress > 0)
                          BoxShadow(
                            color: progressColor.withValues(alpha: 0.2),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // 상단 하이라이트
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: 7,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(8),
                              ),
                              gradient: LinearGradient(
                                colors: [
                                  colorScheme.onPrimary.withValues(alpha: 0.35),
                                  colorScheme.onPrimary.withValues(alpha: 0.0),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 100% 달성 시 반짝임 효과
                if (isCompleted)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: LinearGradient(
                          colors: [
                            colorScheme.onPrimary.withValues(alpha: 0.0),
                            colorScheme.onPrimary.withValues(alpha: 0.15),
                            colorScheme.onPrimary.withValues(alpha: 0.0),
                          ],
                          stops: const [0.0, 0.5, 1.0],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // 마일스톤 표시
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildMilestone(context, 0, progress, isDark),
            _buildMilestone(context, 0.5, progress, isDark),
            _buildMilestone(context, 1.0, progress, isDark),
          ],
        ),
      ],
    );
  }

  Widget _buildMilestone(
    BuildContext context,
    double milestone,
    double progress,
    bool isDark,
  ) {
    final isPassed = progress >= milestone;
    final label = milestone == 0
        ? '0%'
        : milestone == 0.5
        ? '50%'
        : '100%';

    final colorScheme = Theme.of(context).colorScheme;
    return Text(
      label,
      style: TextStyle(
        fontSize: 10,
        fontWeight: isPassed ? FontWeight.w600 : FontWeight.w400,
        color: isPassed
            ? _getProgressColor(progress).withValues(alpha: 0.8)
            : colorScheme.onSurface.withValues(alpha: 0.3),
      ),
    );
  }

  Color _getLighterColor(Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness + 0.15).clamp(0.0, 1.0)).toColor();
  }

  Widget _buildAmountRow(
    BuildContext context,
    AppLocalizations l10n,
    int currentAmount,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.assetGoalCurrentAmount,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            Text(
              _formatCurrency(currentAmount),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        Icon(
          Icons.arrow_forward,
          size: 16,
          color: Theme.of(context).textTheme.bodySmall?.color,
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              l10n.assetGoalTargetAmount,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            Text(
              _formatCurrency(goal.targetAmount),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    AppLocalizations l10n,
    int? remainingDays,
    double progress,
  ) {
    final isOverdue = remainingDays != null && remainingDays < 0;
    final isCompleted = progress >= 1.0;

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        if (goal.targetDate != null)
          _buildChip(
            context,
            icon: Icons.calendar_today,
            label: DateFormat('yyyy.MM.dd').format(goal.targetDate!),
          ),
        if (remainingDays != null)
          _buildChip(
            context,
            icon: isOverdue ? Icons.warning : Icons.access_time,
            label: isOverdue
                ? l10n.assetGoalDaysPassed(remainingDays.abs())
                : l10n.assetGoalDaysRemaining(remainingDays),
            color: isOverdue ? Theme.of(context).colorScheme.error : null,
          ),
        if (isCompleted)
          _buildChip(
            context,
            icon: Icons.check_circle,
            label: l10n.assetGoalCompleted,
            color: Theme.of(context).colorScheme.tertiary,
          ),
      ],
    );
  }

  Widget _buildChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    Color? color,
  }) {
    final chipColor = color ?? Theme.of(context).textTheme.bodySmall?.color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor?.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: chipColor),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: chipColor)),
        ],
      ),
    );
  }

  Color _getProgressColor(double progress) {
    // context 없이 사용되므로 Material 색상 상수 사용
    // 100%: 녹색(성공), 75%+: 파랑(진행 중), 50%+: 주황(주의), 그 외: 빨강(경고)
    if (progress >= 1.0) return const Color(0xFF4CAF50); // Green 500
    if (progress >= 0.75) return const Color(0xFF2196F3); // Blue 500
    if (progress >= 0.5) return const Color(0xFFFF9800); // Orange 500
    return const Color(0xFFF44336); // Red 500
  }

  String _formatCurrency(int amount) {
    return '₩${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }
}

class AssetGoalListView extends ConsumerWidget {
  final String ledgerId;
  final Function(AssetGoal)? onGoalTap;

  const AssetGoalListView({super.key, required this.ledgerId, this.onGoalTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final goalsState = ref.watch(assetGoalNotifierProvider(ledgerId));

    return goalsState.when(
      data: (goals) {
        if (goals.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(32),
            child: EmptyState(
              icon: Icons.flag_outlined,
              message: l10n.assetGoalNone,
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: goals.length,
          itemBuilder: (context, index) {
            final goal = goals[index];
            return AssetGoalCard(
              goal: goal,
              onTap: () => onGoalTap?.call(goal),
              onDelete: () => _showDeleteDialog(context, ref, l10n, goal),
            );
          },
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            '오류: $error',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ),
    );
  }

  Future<void> _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    AssetGoal goal,
  ) async {
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
}

// 진행률 바 배경 패턴 페인터
class _ProgressTrackPainter extends CustomPainter {
  final Color color;

  _ProgressTrackPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    // 대각선 패턴으로 목표 영역 표시
    const spacing = 8.0;
    for (double i = -size.height; i < size.width + size.height; i += spacing) {
      canvas.drawLine(
        Offset(i, size.height),
        Offset(i + size.height, 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ProgressTrackPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
