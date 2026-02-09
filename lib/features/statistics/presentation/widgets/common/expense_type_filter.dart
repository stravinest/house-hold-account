import 'package:flutter/material.dart';

import '../../../../../l10n/generated/app_localizations.dart';
import '../../../domain/entities/statistics_entities.dart';

/// 고정비/변동비 인라인 서브필터 위젯 - Pencil gd8Cl 디자인 적용
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
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ExpenseTypeFilter.values.map((filter) {
          final isSelected = selectedFilter == filter;

          return InkWell(
            onTap: enabled ? () => onChanged(filter) : null,
            borderRadius: BorderRadius.circular(6),
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.surface
                    : Colors.transparent,
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
                _getLabel(l10n, filter),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: !enabled
                      ? colorScheme.onSurfaceVariant.withValues(alpha: 0.5)
                      : isSelected
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
