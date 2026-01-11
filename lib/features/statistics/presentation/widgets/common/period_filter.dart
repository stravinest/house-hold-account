import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/statistics_entities.dart';
import '../../providers/statistics_provider.dart';

class PeriodFilter extends ConsumerWidget {
  const PeriodFilter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPeriod = ref.watch(trendPeriodProvider);

    return SegmentedButton<TrendPeriod>(
      segments: const [
        ButtonSegment<TrendPeriod>(
          value: TrendPeriod.monthly,
          label: Text('월별'),
        ),
        ButtonSegment<TrendPeriod>(
          value: TrendPeriod.yearly,
          label: Text('연별'),
        ),
      ],
      selected: {selectedPeriod},
      onSelectionChanged: (Set<TrendPeriod> newSelection) {
        ref.read(trendPeriodProvider.notifier).state = newSelection.first;
      },
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
