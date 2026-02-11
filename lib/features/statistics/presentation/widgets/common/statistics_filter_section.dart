import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/statistics_provider.dart';
import 'expense_type_filter.dart';
import 'statistics_type_filter.dart';

/// 통계 필터 섹션 - 드롭다운 + 구분선 + 서브필터를 한 줄로 조합
/// Pencil gd8Cl 디자인 적용
class StatisticsFilterSection extends ConsumerWidget {
  const StatisticsFilterSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedType = ref.watch(selectedStatisticsTypeProvider);
    final expenseTypeFilter = ref.watch(selectedExpenseTypeFilterProvider);
    final isExpense = selectedType == 'expense';

    return Row(
      children: [
        const StatisticsTypeFilter(),
        if (isExpense) ...[
          const SizedBox(width: 8),
          SizedBox(
            width: 1,
            height: 20,
            child: ColoredBox(color: colorScheme.outlineVariant),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: ExpenseTypeFilterWidget(
              selectedFilter: expenseTypeFilter,
              onChanged: (filter) {
                ref.read(selectedExpenseTypeFilterProvider.notifier).state =
                    filter;
              },
            ),
          ),
        ],
      ],
    );
  }
}
