import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../statistics/domain/entities/statistics_entities.dart';
import '../providers/asset_provider.dart';

class AssetPeriodDropdown extends ConsumerWidget {
  const AssetPeriodDropdown({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final selectedPeriod = ref.watch(assetChartPeriodProvider);

    final label = selectedPeriod == TrendPeriod.monthly
        ? l10n.statisticsPeriodMonthly
        : l10n.statisticsPeriodYearly;

    return PopupMenuButton<TrendPeriod>(
      onSelected: (value) {
        ref.read(assetChartPeriodProvider.notifier).state = value;
      },
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: colorScheme.surfaceContainer,
      itemBuilder: (context) {
        final periods = [
          (
            TrendPeriod.monthly,
            l10n.statisticsPeriodMonthly,
            Icons.calendar_month,
          ),
          (
            TrendPeriod.yearly,
            l10n.statisticsPeriodYearly,
            Icons.date_range,
          ),
        ];

        return periods.map((period) {
          final isSelected = selectedPeriod == period.$1;

          return PopupMenuItem<TrendPeriod>(
            value: period.$1,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  period.$3,
                  size: 16,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurface,
                ),
                const SizedBox(width: 8),
                Text(
                  period.$2,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          );
        }).toList();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selectedPeriod == TrendPeriod.monthly
                  ? Icons.calendar_month
                  : Icons.date_range,
              size: 16,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.keyboard_arrow_down,
              size: 14,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
