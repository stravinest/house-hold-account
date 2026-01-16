import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../l10n/generated/app_localizations.dart';
import '../../../domain/entities/statistics_entities.dart';
import '../../providers/statistics_provider.dart';
import '../common/expense_type_filter.dart';

class CategorySummaryCard extends ConsumerWidget {
  const CategorySummaryCard({super.key});

  String _getTypeLabel(
    AppLocalizations l10n,
    String type,
    ExpenseTypeFilter? expenseFilter,
  ) {
    switch (type) {
      case 'income':
        return l10n.transactionIncome;
      case 'asset':
        return l10n.transactionAsset;
      case 'expense':
        if (expenseFilter == ExpenseTypeFilter.fixed) {
          return l10n.statisticsFixed;
        } else if (expenseFilter == ExpenseTypeFilter.variable) {
          return l10n.statisticsVariable;
        } else {
          return l10n.transactionExpense;
        }
      default:
        return l10n.transactionExpense;
    }
  }

  Color _getTypeColor(String type, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (type) {
      case 'income':
        return colorScheme.primary;
      case 'asset':
        return colorScheme.tertiary;
      default:
        return colorScheme.error;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
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
            l10n,
            selectedType,
            expenseFilter,
            comparison,
            numberFormat,
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) =>
              Center(child: Text(l10n.errorWithMessage(error.toString()))),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AppLocalizations l10n,
    String selectedType,
    ExpenseTypeFilter expenseFilter,
    MonthComparisonData comparison,
    NumberFormat numberFormat,
  ) {
    final typeLabel = _getTypeLabel(l10n, selectedType, expenseFilter);
    final typeColor = _getTypeColor(selectedType, context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.statisticsTotal(typeLabel),
          style: theme.textTheme.titleMedium.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${numberFormat.format(comparison.currentTotal)}${l10n.transactionAmountUnit}',
          style: theme.textTheme.headlineMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: typeColor,
          ),
        ),
        const SizedBox(height: 12),
        _buildComparisonRow(context, l10n, comparison, numberFormat),
      ],
    );
  }

  Widget _buildComparisonRow(
    BuildContext context,
    AppLocalizations l10n,
    MonthComparisonData comparison,
    NumberFormat numberFormat,
  ) {
    final theme = Theme.of(context);

    if (comparison.previousTotal == 0 && comparison.currentTotal == 0) {
      return Text(
        l10n.statisticsNoPreviousData,
        style: theme.textTheme.bodyMedium.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;
    final isIncrease = comparison.isIncrease;
    final isDecrease = comparison.isDecrease;
    final arrow = isIncrease
        ? Icons.arrow_upward
        : (isDecrease ? Icons.arrow_downward : Icons.remove);
    final arrowColor = isIncrease
        ? colorScheme.error
        : (isDecrease ? colorScheme.primary : colorScheme.onSurfaceVariant);
    final changeText = isIncrease
        ? l10n.statisticsIncrease
        : (isDecrease ? l10n.statisticsDecrease : l10n.statisticsSame);

    return Row(
      children: [
        Icon(arrow, size: 16, color: arrowColor),
        const SizedBox(width: 4),
        Text(
          '${numberFormat.format(comparison.difference.abs())}${l10n.transactionAmountUnit}',
          style: theme.textTheme.bodyMedium.copyWith(
            color: arrowColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          l10n.statisticsVsLastMonth(
            comparison.percentageChange.abs().toStringAsFixed(1),
            changeText,
          ),
          style: theme.textTheme.bodySmall.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
