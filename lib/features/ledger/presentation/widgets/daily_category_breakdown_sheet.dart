import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/category_l10n_helper.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../transaction/domain/entities/transaction.dart';
import '../../../transaction/presentation/providers/transaction_provider.dart';

class DailyCategoryBreakdownSheet extends ConsumerWidget {
  final DateTime date;

  const DailyCategoryBreakdownSheet({super.key, required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final transactionsAsync = ref.watch(dailyTransactionsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 헤더
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: colorScheme.outlineVariant, width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('yyyy년 M월 d일 (E)', 'ko_KR').format(date),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.calendarCategoryBreakdown,
                        style: Theme.of(context).textTheme.bodySmall.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: l10n.tooltipClose,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // 내용
          Flexible(
            child: transactionsAsync.when(
              data: (transactions) {
                if (transactions.isEmpty) {
                  return _buildEmptyState(context);
                }

                final categoryGroups = _groupByCategory(transactions);
                final totals = _calculateTotals(transactions);

                return SingleChildScrollView(
                  child: Column(
                    children: [
                      // 일일 요약
                      _buildDailySummary(context, totals),

                      const Divider(height: 1),

                      // 카테고리별 목록
                      ...categoryGroups.entries.map((entry) {
                        final categoryName = entry.key;
                        final categoryTransactions = entry.value;
                        final categoryTotal = categoryTransactions.fold<int>(
                          0,
                          (sum, t) => sum + t.amount,
                        );

                        return _buildCategorySection(
                          context,
                          categoryName,
                          categoryTransactions,
                          categoryTotal,
                        );
                      }),
                    ],
                  ),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stack) => Padding(
                padding: const EdgeInsets.all(32.0),
                child: EmptyState(
                  icon: Icons.error_outline,
                  message: l10n.errorGeneric,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: EmptyState(
        icon: Icons.receipt_long_outlined,
        message: l10n.calendarNoRecords,
      ),
    );
  }

  Widget _buildDailySummary(BuildContext context, Map<String, int> totals) {
    final l10n = AppLocalizations.of(context)!;
    final formatter = NumberFormat('#,###', 'ko_KR');
    final income = totals['income'] ?? 0;
    final expense = totals['expense'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem(
            context,
            l10n.transactionIncome,
            income,
            Theme.of(context).colorScheme.primary,
            formatter,
          ),
          Container(
            width: 1,
            height: 40,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          _buildSummaryItem(
            context,
            l10n.transactionExpense,
            expense,
            Theme.of(context).colorScheme.error,
            formatter,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    String label,
    int amount,
    Color color,
    NumberFormat formatter,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${formatter.format(amount)}${l10n.transactionAmountUnit}',
          style: Theme.of(context).textTheme.titleMedium.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySection(
    BuildContext context,
    String categoryName,
    List<Transaction> transactions,
    int total,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final formatter = NumberFormat('#,###', 'ko_KR');
    final isIncome = transactions.first.isIncome;
    final categoryIcon = transactions.first.categoryIcon ?? '📦';
    final categoryColor =
        _parseColor(transactions.first.categoryColor) ??
        colorScheme.primaryContainer;

    return ExpansionTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: categoryColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(categoryIcon, style: const TextStyle(fontSize: 20)),
        ),
      ),
      title: Text(
        CategoryL10nHelper.translate(categoryName, l10n),
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        l10n.calendarTransactionCount(transactions.length),
        style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
      ),
      trailing: Text(
        '${formatter.format(total)}${l10n.transactionAmountUnit}',
        style: TextStyle(
          color: isIncome ? colorScheme.primary : colorScheme.error,
          fontWeight: FontWeight.bold,
        ),
      ),
      children: transactions.map((transaction) {
        return ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 72,
            vertical: 4,
          ),
          title: Row(
            children: [
              if (transaction.userName != null) ...[
                Text(
                  transaction.userName!,
                  style: TextStyle(fontSize: 12, color: colorScheme.outline),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  transaction.title ?? l10n.transactionNoTitle,
                  style: const TextStyle(fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          trailing: Text(
            '${formatter.format(transaction.amount)}${l10n.transactionAmountUnit}',
            style: TextStyle(
              fontSize: 13,
              color: isIncome ? colorScheme.primary : colorScheme.error,
            ),
          ),
        );
      }).toList(),
    );
  }

  Map<String, List<Transaction>> _groupByCategory(
    List<Transaction> transactions,
  ) {
    final Map<String, List<Transaction>> groups = {};

    for (final transaction in transactions) {
      // '미분류' 키는 CategoryL10nHelper에서 번역됨
      final categoryName = transaction.categoryName ?? '미분류';
      if (!groups.containsKey(categoryName)) {
        groups[categoryName] = [];
      }
      groups[categoryName]!.add(transaction);
    }

    return groups;
  }

  Map<String, int> _calculateTotals(List<Transaction> transactions) {
    int income = 0;
    int expense = 0;

    for (final transaction in transactions) {
      if (transaction.isIncome) {
        income += transaction.amount;
      } else {
        expense += transaction.amount;
      }
    }

    return {'income': income, 'expense': expense};
  }

  Color? _parseColor(String? colorStr) {
    if (colorStr == null) return null;
    try {
      final hex = colorStr.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } on FormatException {
      // 잘못된 hex 형식의 색상값 - 기본값 반환
      return null;
    }
  }
}
