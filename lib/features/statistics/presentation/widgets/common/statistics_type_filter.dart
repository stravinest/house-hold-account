import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../l10n/generated/app_localizations.dart';
import '../../providers/statistics_provider.dart';

/// 통계 타입 필터 (수입/지출/자산) - Pencil H3XG5 디자인 적용
class StatisticsTypeFilter extends ConsumerWidget {
  final bool enabled;
  final Set<String>? disabledTypes;

  const StatisticsTypeFilter({
    super.key,
    this.enabled = true,
    this.disabledTypes,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final selectedType = ref.watch(selectedStatisticsTypeProvider);

    final types = [
      ('income', l10n.statisticsTypeIncome),
      ('expense', l10n.statisticsTypeExpense),
      ('asset', l10n.statisticsTypeAsset),
    ];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: types.map((type) {
          final isSelected = selectedType == type.$1;
          final isDisabled =
              !enabled || (disabledTypes?.contains(type.$1) ?? false);

          return GestureDetector(
            onTap: isDisabled
                ? null
                : () {
                    ref.read(selectedStatisticsTypeProvider.notifier).state =
                        type.$1;
                  },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? colorScheme.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                type.$2,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  color: isDisabled
                      ? colorScheme.onSurfaceVariant.withValues(alpha: 0.5)
                      : isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
