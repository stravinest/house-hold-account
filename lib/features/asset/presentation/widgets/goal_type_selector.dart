import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/themes/design_tokens.dart';
import '../../domain/entities/asset_goal.dart';

Future<GoalType?> showGoalTypeSelector(BuildContext context) {
  return showModalBottomSheet<GoalType>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => const _GoalTypeSelectorSheet(),
  );
}

class _GoalTypeSelectorSheet extends StatelessWidget {
  const _GoalTypeSelectorSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 핸들 바
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withAlpha(76),
                borderRadius: BorderRadius.circular(BorderRadiusToken.xs),
              ),
            ),
            // 제목
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.md,
                vertical: Spacing.sm,
              ),
              child: Text(
                l10n.goalTypeSelect,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Divider(height: 1),
            const SizedBox(height: Spacing.sm),
            // 자산 목표 옵션
            _GoalTypeOption(
              icon: Icons.trending_up,
              title: l10n.goalTypeAsset,
              description: l10n.goalTypeAssetDesc,
              iconColor: colorScheme.primary,
              onTap: () => Navigator.pop(context, GoalType.asset),
            ),
            const SizedBox(height: Spacing.xs),
            // 대출 목표 옵션
            _GoalTypeOption(
              icon: Icons.account_balance,
              title: l10n.goalTypeLoan,
              description: l10n.goalTypeLoanDesc,
              iconColor: colorScheme.tertiary,
              onTap: () => Navigator.pop(context, GoalType.loan),
            ),
            const SizedBox(height: Spacing.md),
          ],
        ),
      ),
    );
  }
}

class _GoalTypeOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color iconColor;
  final VoidCallback onTap;

  const _GoalTypeOption({
    required this.icon,
    required this.title,
    required this.description,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
      child: Material(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(BorderRadiusToken.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(BorderRadiusToken.md),
          child: Padding(
            padding: const EdgeInsets.all(Spacing.md),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconColor.withAlpha(26),
                    borderRadius: BorderRadius.circular(BorderRadiusToken.sm),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
