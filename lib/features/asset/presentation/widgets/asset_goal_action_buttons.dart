import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/snackbar_utils.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/asset_goal.dart';
import '../providers/asset_goal_provider.dart';
import 'asset_goal_form_sheet.dart';

class AssetGoalActionButtons extends ConsumerWidget {
  final AssetGoal goal;
  final String ledgerId;

  const AssetGoalActionButtons({
    required this.goal,
    required this.ledgerId,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildActionButton(
          icon: Icons.edit_rounded,
          onPressed: () => _showGoalFormSheet(context, goal),
          theme: theme,
        ),
        const SizedBox(width: 4),
        _buildActionButton(
          icon: Icons.delete_rounded,
          onPressed: () => _deleteGoal(context, ref, goal, ledgerId),
          theme: theme,
          isDestructive: true,
        ),
      ],
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
    AssetGoal goal,
    String ledgerId,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.assetGoalDelete),
        content: Text(l10n.assetGoalDeleteConfirm(goal.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            child: Text(l10n.commonDelete),
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
          SnackBarUtils.showSuccess(context, l10n.assetGoalDeleted);
        }
      } catch (e) {
        if (context.mounted) {
          SnackBarUtils.showError(
            context,
            l10n.assetGoalDeleteFailed(e.toString()),
          );
        }
      }
    }
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
}
