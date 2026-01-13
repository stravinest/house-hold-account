import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';

import '../../../transaction/domain/entities/transaction.dart';
import '../../../transaction/presentation/providers/transaction_provider.dart';
import '../../../transaction/presentation/widgets/add_transaction_sheet.dart';
import '../../../transaction/presentation/widgets/edit_transaction_sheet.dart';
import '../../../transaction/presentation/widgets/transaction_detail_sheet.dart';

class TransactionList extends ConsumerWidget {
  final DateTime date;

  const TransactionList({
    super.key,
    required this.date,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(dailyTransactionsProvider);

    return transactionsAsync.when(
      data: (transactions) {
        if (transactions.isEmpty) {
          return _EmptyState(date: date);
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
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
      loading: () => ListView(
        children: const [
          SizedBox(height: 200),
          Center(child: CircularProgressIndicator()),
        ],
      ),
      error: (e, _) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 100),
          const Icon(Icons.error_outline, size: 48),
          const SizedBox(height: 16),
          Text(
            '오류가 발생했습니다: $e',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Center(
            child: FilledButton.tonal(
              onPressed: () => ref.refresh(dailyTransactionsProvider),
              child: const Text('다시 시도'),
            ),
          ),
        ],
      ),
    );
  }
}

// 빈 상태 위젯
class _EmptyState extends StatelessWidget {
  final DateTime date;

  const _EmptyState({required this.date});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('M월 d일 (E)', 'ko_KR');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 100),
        Icon(
          Icons.receipt_long_outlined,
          size: 64,
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
        const SizedBox(height: 16),
        Text(
          dateFormat.format(date),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          '기록된 내역이 없습니다',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 24),
        Center(
          child: FilledButton.tonal(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (context) => AddTransactionSheet(initialDate: date),
              );
            },
            child: const Text('새 거래'),
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

  const _TransactionCard({
    required this.transaction,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final formatter = NumberFormat('#,###', 'ko_KR');
    final amountColor = transaction.isIncome
        ? Colors.blue
        : transaction.isAssetType
            ? Colors.green
            : Colors.red;

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
                builder: (context) => EditTransactionSheet(
                  transaction: transaction,
                ),
              );
            },
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            icon: Icons.edit,
            label: '수정',
          ),
          SlidableAction(
            onPressed: (_) async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('거래 삭제'),
                  content: const Text('이 거래를 삭제하시겠습니까?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('취소'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('삭제'),
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
            label: '삭제',
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
              builder: (context) => TransactionDetailSheet(
                transaction: transaction,
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // 카테고리 아이콘
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _parseColor(transaction.categoryColor) ??
                        colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
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
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ] else ...[
                        Text(
                          '제목 없음',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                      if (transaction.userName != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          transaction.userName!,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colorScheme.outline,
                                  ),
                        ),
                      ],
                    ],
                  ),
                ),

                // 금액
                Text(
                  '${transaction.isIncome ? '+' : transaction.isAssetType ? '' : '-'}${formatter.format(transaction.amount)}원',
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
    } catch (_) {
      return null;
    }
  }
}
