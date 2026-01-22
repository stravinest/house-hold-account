import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../providers/asset_goal_provider.dart';
import 'asset_goal_form_sheet.dart';
import 'asset_goal_section.dart';

/// A card widget that displays the total asset amount and monthly change.
///
/// Features:
/// - Shows total asset amount with formatted currency
/// - Displays monthly change with color-coded arrow (green for positive, red for negative)
/// - "Set Goal" button when no goal exists
/// - Asset goal section with progress tracking when goals exist
class AssetSummaryCard extends ConsumerWidget {
  final int totalAmount;
  final int monthlyChange;
  final String? ledgerId;

  const AssetSummaryCard({
    super.key,
    required this.totalAmount,
    required this.monthlyChange,
    this.ledgerId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final numberFormat = NumberFormat('#,###');
    final isPositive = monthlyChange >= 0;
    final goalsAsync = ledgerId != null
        ? ref.watch(assetGoalNotifierProvider(ledgerId!))
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
                  l10n.assetTotal,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (ledgerId != null && !hasGoal)
                  OutlinedButton.icon(
                    onPressed: () => _showGoalFormSheet(context, null),
                    icon: const Icon(Icons.flag_outlined, size: 16),
                    label: Text(l10n.assetGoalSet),
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
              '${numberFormat.format(totalAmount)}${l10n.transactionAmountUnit}',
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
                  l10n.assetThisMonth(
                    '${isPositive ? '+' : ''}${numberFormat.format(monthlyChange)}',
                  ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isPositive
                        ? theme.colorScheme.tertiary
                        : theme.colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (ledgerId != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              AssetGoalSection(ledgerId: ledgerId!),
            ],
          ],
        ),
      ),
    );
  }

  void _showGoalFormSheet(
    BuildContext context,
    dynamic goal,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AssetGoalFormSheet(goal: goal),
    );
  }
}
