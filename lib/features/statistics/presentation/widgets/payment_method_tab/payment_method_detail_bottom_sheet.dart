import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/utils/number_format_utils.dart';
import '../../../../../l10n/generated/app_localizations.dart';
import '../../../../../shared/themes/design_tokens.dart';
import '../../../../../shared/widgets/category_icon.dart';
import '../../providers/statistics_provider.dart';
import '../common/top_transaction_row.dart';

/// 결제수단 상세 Bottom Sheet - Top5 거래 표시
class PaymentMethodDetailBottomSheet extends ConsumerWidget {
  const PaymentMethodDetailBottomSheet({super.key});

  static void show(
    BuildContext context,
    WidgetRef ref, {
    required String paymentMethodId,
    required String paymentMethodName,
    required String paymentMethodIcon,
    required String paymentMethodColor,
    required bool canAutoSave,
    required double percentage,
    required int totalAmount,
    String? selectedUserId,
    bool isFixedExpenseFilter = false,
  }) {
    ref.read(paymentMethodDetailStateProvider.notifier).state =
        PaymentMethodDetailState(
      isOpen: true,
      paymentMethodId: paymentMethodId,
      paymentMethodName: paymentMethodName,
      paymentMethodIcon: paymentMethodIcon,
      paymentMethodColor: paymentMethodColor,
      canAutoSave: canAutoSave,
      percentage: percentage,
      totalAmount: totalAmount,
      selectedUserId: selectedUserId,
      isFixedExpenseFilter: isFixedExpenseFilter,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PaymentMethodDetailBottomSheet(),
    ).whenComplete(() {
      ref.read(paymentMethodDetailStateProvider.notifier).state =
          const PaymentMethodDetailState();
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final state = ref.watch(paymentMethodDetailStateProvider);
    final topItemsAsync = ref.watch(paymentMethodTopTransactionsProvider);
    final numberFormat = NumberFormatUtils.currency;

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
                    CategoryIcon(
                      icon: state.paymentMethodIcon,
                      name: state.paymentMethodName,
                      color: state.paymentMethodColor,
                      size: CategoryIconSize.small,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        state.paymentMethodName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${state.percentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 8),
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
                      '-${numberFormat.format(state.totalAmount)}${l10n.transactionAmountUnit}',
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
                  Text(
                    l10n.statisticsCategoryTopExpense,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
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
                          return TopTransactionRow(
                            item: item,
                            amountPrefix: '-',
                            amountColor: colorScheme.error,
                            rankBgColor: colorScheme.error,
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
}
