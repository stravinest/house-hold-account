import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
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
    final amountColor = transaction.isIncome
        ? Colors.blue
        : transaction.isSaving
            ? Colors.green
            : Colors.red;

    // 현재 사용자 확인
    final currentUser = ref.watch(currentUserProvider);
    final isOwner = currentUser?.id == transaction.userId;

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

          // 헤더 (수정/삭제 버튼 - 본인 거래만 표시)
          if (isOwner)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
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
                  // 제목
                  _buildDetailRow(
                    context,
                    icon: Icons.title,
                    label: '제목',
                    value: transaction.title?.isNotEmpty == true
                        ? transaction.title!
                        : '제목 없음',
                    valueColor: transaction.title?.isNotEmpty == true
                        ? null
                        : colorScheme.onSurfaceVariant,
                  ),

                  // 메모 (있을 경우)
                  if (transaction.memo?.isNotEmpty == true)
                    _buildDetailRow(
                      context,
                      icon: Icons.note,
                      label: '메모',
                      value: transaction.memo!,
                    ),

                  // 금액
                  _buildDetailRow(
                    context,
                    icon: Icons.attach_money,
                    label: '금액',
                    value:
                        '${transaction.isIncome ? '+' : transaction.isSaving ? '' : '-'}${formatter.format(transaction.amount)}원',
                    valueColor: amountColor,
                  ),

                  // 날짜
                  _buildDetailRow(
                    context,
                    icon: Icons.calendar_today,
                    label: '날짜',
                    value: dateFormat.format(transaction.date),
                  ),

                  // 카테고리
                  if (transaction.categoryName != null)
                    _buildDetailRow(
                      context,
                      icon: Icons.category,
                      label: '카테고리',
                      value: transaction.categoryName!,
                    ),

                  // 결제수단
                  if (transaction.paymentMethodName != null)
                    _buildDetailRow(
                      context,
                      icon: Icons.credit_card,
                      label: '결제수단',
                      value: transaction.paymentMethodName!,
                    ),

                  // 작성자
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('거래가 삭제되었습니다'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('삭제 실패: $e'),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      }
    }
  }
}
