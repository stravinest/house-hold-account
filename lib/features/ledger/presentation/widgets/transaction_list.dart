import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/themes/design_tokens.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/skeleton_loading.dart';
import '../../../transaction/domain/entities/transaction.dart';
import '../../../transaction/presentation/providers/transaction_provider.dart';
import '../../../transaction/presentation/widgets/add_transaction_sheet.dart';
import '../../../transaction/presentation/widgets/edit_transaction_sheet.dart';
import '../../../transaction/presentation/widgets/transaction_detail_sheet.dart';

class TransactionList extends ConsumerWidget {
  final DateTime date;

  const TransactionList({super.key, required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(dailyTransactionsProvider);

    return transactionsAsync.when(
      data: (transactions) {
        if (transactions.isEmpty) {
          return _EmptyState(date: date);
        }

        return ListView.separated(
          padding: const EdgeInsets.all(Spacing.md),
          cacheExtent: 500, // 성능 최적화: 스크롤 시 미리 렌더링
          itemCount: transactions.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final transaction = transactions[index];
            return _TransactionCard(
              transaction: transaction,
              onDelete: () async {
                await ref
                    .read(transactionNotifierProvider.notifier)
                    .deleteTransaction(transaction.id);
              },
            );
          },
        );
      },
      loading: () => ListView.separated(
        padding: const EdgeInsets.all(Spacing.md),
        cacheExtent: 500,
        itemCount: 5,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) => const SkeletonTransactionItem(),
      ),
      error: (e, _) {
        final l10n = AppLocalizations.of(context)!;
        return ListView(
          padding: const EdgeInsets.all(Spacing.md),
          children: [
            const SizedBox(height: 100),
            EmptyState(
              icon: Icons.error_outline,
              message: l10n.errorGeneric,
              subtitle: e.toString(),
              action: FilledButton.tonal(
                onPressed: () => ref.refresh(dailyTransactionsProvider),
                child: Text(l10n.commonRetry),
              ),
            ),
          ],
        );
      },
    );
  }
}

// 빈 상태 위젯
class _EmptyState extends StatelessWidget {
  final DateTime date;

  const _EmptyState({required this.date});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateFormat = DateFormat('M월 d일 (E)', 'ko_KR');

    return ListView(
      padding: const EdgeInsets.all(Spacing.md),
      children: [
        const SizedBox(height: 100),
        EmptyState(
          icon: Icons.receipt_long_outlined,
          message: dateFormat.format(date),
          subtitle: l10n.calendarNoRecords,
          action: FilledButton.tonal(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (context) => AddTransactionSheet(initialDate: date),
              );
            },
            child: Text(l10n.calendarNewTransaction),
          ),
        ),
      ],
    );
  }
}

// 거래 카드 위젯
class _TransactionCard extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback onDelete;

  const _TransactionCard({required this.transaction, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final formatter = NumberFormat('#,###', 'ko_KR');
    final amountColor = transaction.isIncome
        ? colorScheme.primary
        : transaction.isAssetType
        ? colorScheme.tertiary
        : colorScheme.error;

    return Slidable(
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (context) =>
                    EditTransactionSheet(transaction: transaction),
              );
            },
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            icon: Icons.edit,
            label: l10n.commonEdit,
          ),
          SlidableAction(
            onPressed: (_) async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: Text(l10n.calendarTransactionDelete),
                  content: Text(l10n.calendarTransactionDeleteConfirm),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: Text(l10n.commonCancel),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      child: Text(l10n.commonDelete),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                onDelete();
              }
            },
            backgroundColor: colorScheme.error,
            foregroundColor: colorScheme.onError,
            icon: Icons.delete,
            label: l10n.commonDelete,
          ),
        ],
      ),
      child: Card(
        child: InkWell(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              builder: (context) =>
                  TransactionDetailSheet(transaction: transaction),
            );
          },
          borderRadius: BorderRadius.circular(BorderRadiusToken.md),
          child: Padding(
            padding: const EdgeInsets.all(Spacing.md),
            child: Row(
              children: [
                // 카테고리 아이콘
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color:
                        _parseColor(transaction.categoryColor) ??
                        colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(BorderRadiusToken.md),
                  ),
                  child: Center(
                    child: Text(
                      transaction.categoryIcon ?? '📦',
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // 메모 및 사용자 정보
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (transaction.title != null &&
                          transaction.title!.isNotEmpty) ...[
                        Text(
                          transaction.title!,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ] else ...[
                        Text(
                          l10n.transactionNoTitle,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                      if (transaction.userName != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          transaction.userName!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colorScheme.outline),
                        ),
                      ],
                    ],
                  ),
                ),

                // 금액
                Text(
                  '${transaction.isIncome
                      ? '+'
                      : transaction.isAssetType
                      ? ''
                      : '-'}${formatter.format(transaction.amount)}${l10n.transactionAmountUnit}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: amountColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
