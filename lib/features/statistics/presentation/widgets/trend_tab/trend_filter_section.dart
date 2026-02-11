import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../l10n/generated/app_localizations.dart';
import '../../../domain/entities/statistics_entities.dart';
import '../../providers/statistics_provider.dart';

/// 추이 탭 전용 필터 섹션
/// [ 월별 v ] | [ 수입  지출  자산 ]
class TrendFilterSection extends ConsumerWidget {
  const TrendFilterSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        // 기간 드롭다운 (월별/연별)
        const _PeriodDropdown(),
        const SizedBox(width: 8),
        SizedBox(
          width: 1,
          height: 20,
          child: ColoredBox(color: colorScheme.outlineVariant),
        ),
        const SizedBox(width: 8),
        // 타입 인라인 토글 (수입/지출/자산)
        const Flexible(child: _TypeInlineToggle()),
      ],
    );
  }
}

/// 기간 드롭다운 - 카테고리 타입 드롭다운과 동일 스타일
class _PeriodDropdown extends ConsumerWidget {
  const _PeriodDropdown();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final selectedPeriod = ref.watch(trendPeriodProvider);

    final label = selectedPeriod == TrendPeriod.monthly
        ? l10n.statisticsPeriodMonthly
        : l10n.statisticsPeriodYearly;

    return PopupMenuButton<TrendPeriod>(
      onSelected: (value) {
        ref.read(trendPeriodProvider.notifier).state = value;
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
          (TrendPeriod.yearly, l10n.statisticsPeriodYearly, Icons.date_range),
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

/// 타입 인라인 토글 (수입/지출/자산) - 서브필터와 동일 스타일
class _TypeInlineToggle extends ConsumerWidget {
  const _TypeInlineToggle();

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
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: types.map((type) {
          final isSelected = selectedType == type.$1;

          return InkWell(
            onTap: () {
              ref.read(selectedStatisticsTypeProvider.notifier).state = type.$1;
            },
            borderRadius: BorderRadius.circular(6),
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: isSelected ? colorScheme.surface : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                boxShadow: isSelected
                    ? const [
                        BoxShadow(
                          color: Color(0x10000000),
                          blurRadius: 3,
                          offset: Offset(0, 1),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                type.$2,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? colorScheme.primary
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
