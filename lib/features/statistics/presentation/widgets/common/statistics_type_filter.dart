import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    final selectedType = ref.watch(selectedStatisticsTypeProvider);

    return SegmentedButton<String>(
      segments: [
        ButtonSegment<String>(
          value: 'income',
          label: const Text('수입'),
          enabled: enabled && !(disabledTypes?.contains('income') ?? false),
        ),
        ButtonSegment<String>(
          value: 'expense',
          label: const Text('지출'),
          enabled: enabled && !(disabledTypes?.contains('expense') ?? false),
        ),
        ButtonSegment<String>(
          value: 'asset',
          label: const Text('자산'),
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
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
