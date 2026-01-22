import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../l10n/generated/app_localizations.dart';
import '../../providers/statistics_provider.dart';

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
    final selectedType = ref.watch(selectedStatisticsTypeProvider);

    return SegmentedButton<String>(
      segments: [
        ButtonSegment<String>(
          value: 'income',
          label: Text(l10n.statisticsTypeIncome),
          enabled: enabled && !(disabledTypes?.contains('income') ?? false),
        ),
        ButtonSegment<String>(
          value: 'expense',
          label: Text(l10n.statisticsTypeExpense),
          enabled: enabled && !(disabledTypes?.contains('expense') ?? false),
        ),
        ButtonSegment<String>(
          value: 'asset',
          label: Text(l10n.statisticsTypeAsset),
          enabled: enabled && !(disabledTypes?.contains('asset') ?? false),
        ),
      ],
      selected: {selectedType},
      onSelectionChanged: enabled
          ? (Set<String> newSelection) {
              ref.read(selectedStatisticsTypeProvider.notifier).state =
                  newSelection.first;
            }
          : null,
      style: const ButtonStyle(visualDensity: VisualDensity.compact),
    );
  }
}
