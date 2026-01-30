import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/asset_goal.dart';
import '../providers/asset_goal_provider.dart';
import 'asset_goal_form_sheet.dart';

/// A card widget that displays an asset goal with progress tracking.
/// Based on pencil design node: Mikvv
class AssetGoalCardSimple extends ConsumerWidget {
  final String ledgerId;

  const AssetGoalCardSimple({super.key, required this.ledgerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final goalsAsync = ref.watch(assetGoalNotifierProvider(ledgerId));

    return goalsAsync.when(
      data: (goals) {
        if (goals.isEmpty) return const SizedBox.shrink();

        // 가장 가까운 목표 선택
        final sortedGoals = List.of(goals)
          ..sort((a, b) {
            if (a.targetDate == null && b.targetDate == null) return 0;
            if (a.targetDate == null) return 1;
            if (b.targetDate == null) return -1;
            return a.targetDate!.compareTo(b.targetDate!);
          });

        final goal = sortedGoals.first;
        final currentAmountAsync = ref.watch(
          assetGoalCurrentAmountProvider(goal),
        );
        final progress = ref.watch(assetGoalProgressProvider(goal));

        return currentAmountAsync.when(
          data: (currentAmount) =>
              _buildGoalCard(context, ref, l10n, goal, currentAmount, progress),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildGoalCard(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    AssetGoal goal,
    int currentAmount,
    double progress,
  ) {
    final numberFormat = NumberFormat('#,###');
    final remaining = goal.targetAmount - currentAmount;
    final progressPercent = (progress * 100).clamp(0, 100);
    final progressColor = progress >= 1.0
        ? const Color(0xFF2E7D32)
        : const Color(0xFFBA1A1A);

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더: 목표 아이콘 + 제목 + 편집/삭제 버튼
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF006A6A),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.flag,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '목표',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1A1C19),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => _showGoalFormSheet(context, goal),
                    child: const Icon(
                      Icons.edit,
                      size: 20,
                      color: Color(0xFF44483E),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _deleteGoal(context, ref, l10n, goal),
                    child: const Icon(
                      Icons.delete,
                      size: 20,
                      color: Color(0xFFBA1A1A),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 목표 금액
          Text(
            '${numberFormat.format(goal.targetAmount)}${l10n.transactionAmountUnit}',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1C19),
            ),
          ),
          const SizedBox(height: 16),

          // 프로그레스 영역
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 현재/목표 레이블
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '현재 ${numberFormat.format(currentAmount)}${l10n.transactionAmountUnit}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1A1C19),
                    ),
                  ),
                  Text(
                    '목표 ${numberFormat.format(goal.targetAmount)}${l10n.transactionAmountUnit}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.normal,
                      color: Color(0xFF44483E),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 프로그레스 바
              Container(
                height: 12,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // 0~1% 범위는 1%로 표시 (너무 작아서 안 보이는 문제 해결)
                    final clampedProgress = progress.clamp(0.0, 1.0);
                    // 실제 표시할 너비: 0~1%일 때 1%, 그 이상일 때는 실제 진행률
                    final displayProgress = progress >= 0.01
                        ? clampedProgress
                        : 0.01;
                    final displayWidth = constraints.maxWidth * displayProgress;

                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: displayWidth,
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

              // 배지 + 남은 금액
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${progressPercent.toStringAsFixed(1)}% 달성',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFBA1A1A),
                      ),
                    ),
                  ),
                  if (remaining > 0)
                    Text(
                      '${numberFormat.format(remaining)}${l10n.transactionAmountUnit} 남음',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.normal,
                        color: Color(0xFF44483E),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 하단 안내 텍스트
          const Center(
            child: Text(
              '탭하여 상세 금액 보기',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.normal,
                color: Color(0xFF44483E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showGoalFormSheet(BuildContext context, AssetGoal goal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AssetGoalFormSheet(goal: goal),
    );
  }

  Future<void> _deleteGoal(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    AssetGoal goal,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('목표 삭제'),
        content: Text('${goal.title} 목표를 삭제하시겠습니까?'),
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
    }
  }
}
