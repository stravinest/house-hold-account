import 'package:flutter/material.dart';

/// 지출 유형 필터 (전체/고정비/변동비)
enum ExpenseTypeFilter {
  all,
  fixed,
  variable,
}

extension ExpenseTypeFilterExtension on ExpenseTypeFilter {
  String get label {
    switch (this) {
      case ExpenseTypeFilter.all:
        return '전체';
      case ExpenseTypeFilter.fixed:
        return '고정비';
      case ExpenseTypeFilter.variable:
        return '변동비';
    }
  }

  String get description {
    switch (this) {
      case ExpenseTypeFilter.all:
        return '모든 지출';
      case ExpenseTypeFilter.fixed:
        return '월세, 보험료 등 정기 지출';
      case ExpenseTypeFilter.variable:
        return '고정비 제외 지출';
    }
  }
}

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

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<ExpenseTypeFilter>(
      segments: ExpenseTypeFilter.values.map((filter) {
        return ButtonSegment(
          value: filter,
          label: Text(filter.label),
        );
      }).toList(),
      selected: {selectedFilter},
      onSelectionChanged: enabled
          ? (selected) => onChanged(selected.first)
          : null,
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
