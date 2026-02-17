import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/utils/color_utils.dart';
import '../../../../../core/utils/number_format_utils.dart';
import '../../../../../l10n/generated/app_localizations.dart';
import '../../../../../shared/themes/design_tokens.dart';
import '../../../data/repositories/statistics_repository.dart';
import '../../providers/statistics_provider.dart';

/// 카테고리 상세 Bottom Sheet - Top5 거래 표시
class CategoryDetailBottomSheet extends ConsumerWidget {
  const CategoryDetailBottomSheet({super.key});

  static void show(
    BuildContext context,
    WidgetRef ref, {
    required String categoryId,
    required String categoryName,
    required String categoryColor,
    required String categoryIcon,
    required double categoryPercentage,
    required String type,
    required int totalAmount,
    bool isFixedExpenseFilter = false,
  }) {
    ref.read(categoryDetailStateProvider.notifier).state = CategoryDetailState(
      isOpen: true,
      categoryId: categoryId,
      categoryName: categoryName,
      categoryColor: categoryColor,
      categoryIcon: categoryIcon,
      categoryPercentage: categoryPercentage,
      type: type,
      totalAmount: totalAmount,
      isFixedExpenseFilter: isFixedExpenseFilter,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CategoryDetailBottomSheet(),
    ).whenComplete(() {
      ref.read(categoryDetailStateProvider.notifier).state =
          const CategoryDetailState();
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final state = ref.watch(categoryDetailStateProvider);
    final topItemsAsync = ref.watch(categoryTopTransactionsProvider);
    final numberFormat = NumberFormatUtils.currency;

    final categoryColor = ColorUtils.parseHexColor(
      state.categoryColor,
      fallback: const Color(0xFF9E9E9E),
    );

    final amountPrefix = state.type == 'expense'
        ? '-'
        : state.type == 'income'
            ? '+'
            : '';
    final amountColor = state.type == 'expense'
        ? const Color(0xFFBA1A1A)
        : state.type == 'income'
            ? const Color(0xFF2E7D32)
            : const Color(0xFF1565C0);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 드래그 핸들
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // 헤더
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: categoryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      state.categoryName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${state.categoryPercentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close,
                        size: 20,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        minimumSize: const Size(32, 32),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$amountPrefix${numberFormat.format(state.totalAmount)}${l10n.transactionAmountUnit}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.statisticsMonthTotal,
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Divider(height: 1, color: colorScheme.outlineVariant),

          // Top5 리스트
          Flexible(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                MediaQuery.of(context).viewPadding.bottom + Spacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _getListTitle(state.type, l10n),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  topItemsAsync.when(
                    data: (result) {
                      final items = result.items;
                      if (items.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              l10n.statisticsNoData,
                              style: TextStyle(
                                fontSize: 14,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        );
                      }
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: items.map((item) {
                          return _TopItemRow(
                            item: item,
                            amountPrefix: amountPrefix,
                            amountColor: amountColor,
                            rankBgColor: state.type == 'asset'
                                ? const Color(0xFF1565C0)
                                : const Color(0xFF2E7D32),
                            isLast: item.rank == items.length,
                          );
                        }).toList(),
                      );
                    },
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (error, stack) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          l10n.errorGeneric,
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.error,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getListTitle(String type, AppLocalizations l10n) {
    switch (type) {
      case 'income':
        return l10n.statisticsCategoryTopIncome;
      case 'asset':
        return l10n.statisticsCategoryTopAsset;
      default:
        return l10n.statisticsCategoryTopExpense;
    }
  }
}

class _TopItemRow extends StatelessWidget {
  final CategoryTopTransaction item;
  final String amountPrefix;
  final Color amountColor;
  final Color rankBgColor;
  final bool isLast;

  const _TopItemRow({
    required this.item,
    required this.amountPrefix,
    required this.amountColor,
    required this.rankBgColor,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final numberFormat = NumberFormatUtils.currency;
    final l10n = AppLocalizations.of(context);
    final userColor = ColorUtils.parseHexColor(
      item.userColor,
      fallback: const Color(0xFFA8D8EA),
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
      ),
      child: Row(
        children: [
          // 순위 뱃지
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: item.rank == 1
                  ? rankBgColor
                  : rankBgColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              '${item.rank}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: item.rank == 1
                    ? Colors.white
                    : rankBgColor,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // 제목 + 날짜/사용자
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      item.date,
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      width: 3,
                      height: 3,
                      decoration: BoxDecoration(
                        color: colorScheme.onSurfaceVariant,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: userColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item.userName,
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 금액 + 비율
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$amountPrefix${numberFormat.format(item.amount)}${l10n.transactionAmountUnit}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: amountColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${item.percentage}%',
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
