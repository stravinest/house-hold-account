import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../l10n/generated/app_localizations.dart';
import '../../../domain/entities/statistics_entities.dart';
import '../../providers/statistics_provider.dart';

class PeriodFilter extends ConsumerWidget {
  const PeriodFilter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final selectedPeriod = ref.watch(trendPeriodProvider);

    return SegmentedButton<TrendPeriod>(
      segments: [
        ButtonSegment<TrendPeriod>(
          value: TrendPeriod.monthly,
          label: Text(l10n.statisticsPeriodMonthly),
        ),
        ButtonSegment<TrendPeriod>(
          value: TrendPeriod.yearly,
          label: Text(l10n.statisticsPeriodYearly),
        ),
      ],
      selected: {selectedPeriod},
      onSelectionChanged: (Set<TrendPeriod> newSelection) {
        ref.read(trendPeriodProvider.notifier).state = newSelection.first;
      },
      style: const ButtonStyle(visualDensity: VisualDensity.compact),
    );
  }
}
