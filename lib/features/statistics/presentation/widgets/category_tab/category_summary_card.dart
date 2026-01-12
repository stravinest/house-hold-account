import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../domain/entities/statistics_entities.dart';
import '../../providers/statistics_provider.dart';
import '../common/expense_type_filter.dart';

class CategorySummaryCard extends ConsumerWidget {
  const CategorySummaryCard({super.key});

  String _getTypeLabel(String type, ExpenseTypeFilter? expenseFilter) {
    switch (type) {
      case 'income':
        return '수입';
      case 'saving':
        return '저축';
      case 'expense':
        if (expenseFilter == ExpenseTypeFilter.fixed) {
          return '고정비';
        } else if (expenseFilter == ExpenseTypeFilter.variable) {
          return '변동비';
        } else {
          return '지출';
        }
      default:
        return '지출';
    }
  }

  Color _getTypeColor(String type, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (type) {
      case 'income':
        return isDark ? Colors.blue.shade300 : Colors.blue;
      case 'saving':
        return isDark ? Colors.green.shade300 : Colors.green;
      default:
        return isDark ? Colors.red.shade300 : Colors.red;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedType = ref.watch(selectedStatisticsTypeProvider);
    final expenseFilter = ref.watch(selectedExpenseTypeFilterProvider);
    final comparisonAsync = ref.watch(monthComparisonProvider);
    final numberFormat = NumberFormat('#,###');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: comparisonAsync.when(
          data: (comparison) => _buildContent(
            context,
            selectedType,
            expenseFilter,
            comparison,
            numberFormat,
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('오류: $error')),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    String selectedType,
    ExpenseTypeFilter expenseFilter,
    MonthComparisonData comparison,
    NumberFormat numberFormat,
  ) {
    final typeLabel = _getTypeLabel(selectedType, expenseFilter);
    final typeColor = _getTypeColor(selectedType, context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '총 $typeLabel',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${numberFormat.format(comparison.currentTotal)}원',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: typeColor,
          ),
        ),
        const SizedBox(height: 12),
        _buildComparisonRow(context, comparison, numberFormat),
      ],
    );
  }

  Widget _buildComparisonRow(
    BuildContext context,
    MonthComparisonData comparison,
    NumberFormat numberFormat,
  ) {
    final theme = Theme.of(context);

    if (comparison.previousTotal == 0 && comparison.currentTotal == 0) {
      return Text(
        '지난달 데이터 없음',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    final isIncrease = comparison.isIncrease;
    final isDecrease = comparison.isDecrease;
    final arrow = isIncrease
        ? Icons.arrow_upward
        : (isDecrease ? Icons.arrow_downward : Icons.remove);
    final arrowColor = isIncrease
        ? Colors.red
        : (isDecrease ? Colors.blue : Colors.grey);
    final changeText = isIncrease ? '증가' : (isDecrease ? '감소' : '동일');

    return Row(
      children: [
        Icon(arrow, size: 16, color: arrowColor),
        const SizedBox(width: 4),
        Text(
          '${numberFormat.format(comparison.difference.abs())}원',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: arrowColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '(지난달 대비 ${comparison.percentageChange.abs().toStringAsFixed(1)}% $changeText)',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
