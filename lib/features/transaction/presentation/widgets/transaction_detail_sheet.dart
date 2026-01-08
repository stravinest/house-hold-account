import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/transaction.dart';
import '../providers/transaction_provider.dart';
import 'edit_transaction_sheet.dart';

/// 거래 상세 정보를 표시하는 Bottom Sheet
class TransactionDetailSheet extends ConsumerWidget {
  final Transaction transaction;

  const TransactionDetailSheet({super.key, required this.transaction});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final formatter = NumberFormat('#,###', 'ko_KR');
    final dateFormat = DateFormat('yyyy년 M월 d일 (E)', 'ko_KR');
    final amountColor = transaction.isIncome ? Colors.blue : Colors.red;

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
          // 핸들 바
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withAlpha(76),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // 헤더 (제목 + 수정/삭제 버튼)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                //오른쪽으로 정렬
                Row(
                  children: [
                    //
                    TextButton.icon(
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('수정'),
                      onPressed: () => _openEditSheet(context),
                    ),
                    TextButton.icon(
                      icon: Icon(
                        Icons.delete,
                        size: 18,
                        color: colorScheme.error,
                      ),
                      label: Text(
                        '삭제',
                        style: TextStyle(color: colorScheme.error),
                      ),
                      onPressed: () => _showDeleteConfirmDialog(context, ref),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(),

          // 상세 내용
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // 카테고리 아이콘 + 메모
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color:
                          _parseColor(transaction.categoryColor) ??
                          colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        transaction.categoryIcon ?? '',
                        style: const TextStyle(fontSize: 32),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 메모
                  Text(
                    transaction.memo?.isNotEmpty == true
                        ? transaction.memo!
                        : '메모 없음',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: transaction.memo?.isNotEmpty == true
                          ? null
                          : colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  // 카테고리명
                  if (transaction.categoryName != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      transaction.categoryName!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // 상세 정보 목록
                  _buildDetailRow(
                    context,
                    icon: Icons.attach_money,
                    label: '금액',
                    value:
                        '${transaction.isIncome ? '+' : '-'}${formatter.format(transaction.amount)}원',
                    valueColor: amountColor,
                  ),

                  _buildDetailRow(
                    context,
                    icon: Icons.calendar_today,
                    label: '날짜',
                    value: dateFormat.format(transaction.date),
                  ),

                  if (transaction.paymentMethodName != null)
                    _buildDetailRow(
                      context,
                      icon: Icons.credit_card,
                      label: '결제수단',
                      value: transaction.paymentMethodName!,
                    ),

                  if (transaction.userName != null)
                    _buildDetailRow(
                      context,
                      icon: Icons.person,
                      label: '작성자',
                      value: transaction.userName!,
                    ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  void _openEditSheet(BuildContext context) {
    Navigator.pop(context); // 상세 시트 닫기
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => EditTransactionSheet(transaction: transaction),
    );
  }

  Future<void> _showDeleteConfirmDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
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
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref
            .read(transactionNotifierProvider.notifier)
            .deleteTransaction(transaction.id);
        if (context.mounted) {
          Navigator.pop(context); // 상세 시트 닫기
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('거래가 삭제되었습니다')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('삭제 실패: $e')));
        }
      }
    }
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
