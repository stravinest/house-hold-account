import 'package:flutter/material.dart';

import '../../../../../l10n/generated/app_localizations.dart';

/// 지출 유형 필터 (전체/고정비/변동비)
enum ExpenseTypeFilter { all, fixed, variable }

/// 고정비/변동비 필터 위젯 - Pencil H3XG5 디자인 적용
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
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ExpenseTypeFilter.values.map((filter) {
          final isSelected = selectedFilter == filter;

          return GestureDetector(
            onTap: enabled ? () => onChanged(filter) : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? colorScheme.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _getLabel(l10n, filter),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  color: !enabled
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
