import 'package:flutter/material.dart';

import '../../../../../l10n/generated/app_localizations.dart';

/// 지출 유형 필터 (전체/고정비/변동비)
enum ExpenseTypeFilter { all, fixed, variable }

/// 고정비/변동비 필터 위젯
class ExpenseTypeFilterWidget extends StatelessWidget {
  final ExpenseTypeFilter selectedFilter;
  final ValueChanged<ExpenseTypeFilter> onChanged;
  final bool enabled;

  const ExpenseTypeFilterWidget({
    super.key,
    required this.selectedFilter,
    required this.onChanged,
    this.enabled = true,
  });

  String _getLabel(AppLocalizations l10n, ExpenseTypeFilter filter) {
    switch (filter) {
      case ExpenseTypeFilter.all:
        return l10n.statisticsExpenseAll;
      case ExpenseTypeFilter.fixed:
        return l10n.statisticsExpenseFixed;
      case ExpenseTypeFilter.variable:
        return l10n.statisticsExpenseVariable;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SegmentedButton<ExpenseTypeFilter>(
      segments: ExpenseTypeFilter.values.map((filter) {
        return ButtonSegment(
          value: filter,
          label: Text(_getLabel(l10n, filter)),
        );
      }).toList(),
      selected: {selectedFilter},
      onSelectionChanged: enabled
          ? (selected) => onChanged(selected.first)
          : null,
      style: const ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

/// ExpenseTypeFilter 확장 - l10n이 필요없는 곳에서 사용
extension ExpenseTypeFilterExtension on ExpenseTypeFilter {
  String getDescription(AppLocalizations l10n) {
    switch (this) {
      case ExpenseTypeFilter.all:
        return l10n.statisticsExpenseAllDesc;
      case ExpenseTypeFilter.fixed:
        return l10n.statisticsExpenseFixedDesc;
      case ExpenseTypeFilter.variable:
        return l10n.statisticsExpenseVariableDesc;
    }
  }
}
