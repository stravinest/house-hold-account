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
    final numberFormat = NumberFormat('#,###');
    final isPositive = monthlyChange >= 0;

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.assetTotal,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF44483E),
              fontWeight: FontWeight.normal,
            ),
          ),
          const SizedBox(height: 16),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '${numberFormat.format(totalAmount)}${l10n.transactionAmountUnit}',
              style: const TextStyle(
                fontSize: 32,
                color: Color(0xFF2E7D32),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                size: 16,
                color: isPositive
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFFBA1A1A),
              ),
              const SizedBox(width: 6),
              Text(
                l10n.assetThisMonth(
                  '${isPositive ? '+' : ''}${numberFormat.format(monthlyChange)}',
                ),
                style: TextStyle(
                  fontSize: 13,
                  color: isPositive
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFFBA1A1A),
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showGoalFormSheet(BuildContext context, dynamic goal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AssetGoalFormSheet(goal: goal),
    );
  }
}
