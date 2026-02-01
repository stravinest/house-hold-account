import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/utils/number_format_utils.dart';
import '../../../../../l10n/generated/app_localizations.dart';
import '../../../data/repositories/statistics_repository.dart';
import '../../../domain/entities/statistics_entities.dart';
import '../../providers/statistics_provider.dart';
import '../common/expense_type_filter.dart';

/// 공유 가계부용 카테고리 요약 카드 - Pencil Oleyd 디자인 적용
/// 총 금액 + 진행 바 + 사용자별 내역 (색상 동그라미 포함)
class SharedCategorySummaryCard extends ConsumerWidget {
  const SharedCategorySummaryCard({super.key});

  Color _parseColor(String? colorString) {
    if (colorString == null) return const Color(0xFF9E9E9E);
    try {
      final colorValue = int.parse(colorString.replaceFirst('#', '0xFF'));
      return Color(colorValue);
    } catch (e) {
      return const Color(0xFF9E9E9E);
    }
  }

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
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final selectedType = ref.watch(selectedStatisticsTypeProvider);
    final expenseFilter = ref.watch(selectedExpenseTypeFilterProvider);
    final userStatsAsync = ref.watch(categoryStatisticsByUserProvider);
    final comparisonAsync = ref.watch(monthComparisonProvider);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: userStatsAsync.when(
        data: (userStats) {
          if (userStats.isEmpty) {
            return _buildEmptyContent(
              context,
              l10n,
              selectedType,
              expenseFilter,
            );
          }

          final users = userStats.values.toList()
            ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
          final totalAmount = users.fold(
            0,
            (sum, user) => sum + user.totalAmount,
          );

          return _buildContent(
            context,
            l10n,
            selectedType,
            expenseFilter,
            users,
            totalAmount,
            comparisonAsync.valueOrNull,
          );
        },
        loading: () => const SizedBox(
          height: 120,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (error, stack) =>
            _buildEmptyContent(context, l10n, selectedType, expenseFilter),
      ),
    );
  }

  Widget _buildEmptyContent(
    BuildContext context,
    AppLocalizations l10n,
    String selectedType,
    ExpenseTypeFilter expenseFilter,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final typeLabel = _getTypeLabel(l10n, selectedType, expenseFilter);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.statisticsTotal(typeLabel),
          style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        Text(
          '0${l10n.transactionAmountUnit}',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.normal,
            color: _getTypeColor(selectedType, context),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(
    BuildContext context,
    AppLocalizations l10n,
    String selectedType,
    ExpenseTypeFilter expenseFilter,
    List<UserCategoryStatistics> users,
    int totalAmount,
    MonthComparisonData? comparison,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final typeLabel = _getTypeLabel(l10n, selectedType, expenseFilter);
    final typeColor = _getTypeColor(selectedType, context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 총 금액 라벨
        Text(
          l10n.statisticsTotal(typeLabel),
          style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 4),

        // 총 금액
        Text(
          '${NumberFormatUtils.currency.format(totalAmount)}${l10n.transactionAmountUnit}',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.normal,
            color: typeColor,
          ),
        ),

        // 전월 대비 (있을 경우)
        if (comparison != null) ...[
          const SizedBox(height: 8),
          _buildComparisonRow(context, l10n, comparison),
        ],
        const SizedBox(height: 12),

        // 진행 바 (100%)
        Container(
          height: 32,
          decoration: BoxDecoration(
            color: typeColor.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: const Text(
            '100%',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.normal,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // 사용자별 내역
        ...users.map((user) {
          final userColor = _parseColor(user.userColor);
          final percentage = totalAmount > 0
              ? (user.totalAmount / totalAmount * 100)
              : 0.0;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                // 색상 동그라미
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: userColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),

                // 사용자 이름
                Text(
                  user.userName,
                  style: TextStyle(fontSize: 14, color: colorScheme.onSurface),
                ),

                // Spacer
                const Spacer(),

                // 금액
                Text(
                  '${NumberFormatUtils.currency.format(user.totalAmount)}${l10n.transactionAmountUnit}',
                  style: TextStyle(fontSize: 14, color: colorScheme.onSurface),
                ),
                const SizedBox(width: 8),

                // 퍼센트
                Text(
                  '(${percentage.toStringAsFixed(1)}%)',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildComparisonRow(
    BuildContext context,
    AppLocalizations l10n,
    MonthComparisonData comparison,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    if (comparison.previousTotal == 0 && comparison.currentTotal == 0) {
      return Text(
        l10n.statisticsNoPreviousData,
        style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant),
      );
    }

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
          '${NumberFormatUtils.currency.format(comparison.difference.abs())}${l10n.transactionAmountUnit}',
          style: TextStyle(
            fontSize: 14,
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
          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
