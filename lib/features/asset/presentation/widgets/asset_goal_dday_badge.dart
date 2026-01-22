import 'package:flutter/material.dart';

/// A badge widget that displays the D-Day countdown for an asset goal.
///
/// Shows:
/// - "D-N" for goals N days away (urgent if < 30 days)
/// - "D+N" for goals N days overdue
///
/// The badge color changes based on urgency:
/// - Error color: overdue goals
/// - Tertiary color: urgent goals (< 30 days)
/// - Primary color: normal goals
class AssetGoalDDayBadge extends StatelessWidget {
  final int remainingDays;

  const AssetGoalDDayBadge({super.key, required this.remainingDays});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
          colors: [badgeColor.withOpacity(0.15), badgeColor.withOpacity(0.08)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor.withOpacity(0.3), width: 1),
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
}
