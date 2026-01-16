import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/themes/design_tokens.dart';
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
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).languageCode;
    final formatter = NumberFormat('#,###', locale == 'ko' ? 'ko_KR' : 'en_US');
    final dateFormat = locale == 'ko'
        ? DateFormat('yyyy년 M월 d일 (E)', 'ko_KR')
        : DateFormat('MMMM d, yyyy (E)', 'en_US');
    final amountColor = transaction.isIncome
        ? colorScheme.primary
        : transaction.isAssetType
        ? colorScheme.tertiary
        : colorScheme.error;

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
              borderRadius: BorderRadius.circular(BorderRadiusToken.xs),
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
                        label: Text(l10n.commonEdit),
                        onPressed: () => _openEditSheet(context),
                      ),
                      TextButton.icon(
                        icon: Icon(
                          Icons.delete,
                          size: 18,
                          color: colorScheme.error,
                        ),
                        label: Text(
                          l10n.commonDelete,
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
              padding: const EdgeInsets.all(Spacing.md),
              child: Column(
                children: [
                  // 제목
                  _buildDetailRow(
                    context,
                    icon: Icons.title,
                    label: l10n.labelTitle,
                    value: transaction.title?.isNotEmpty == true
                        ? transaction.title!
                        : l10n.transactionNoTitle,
                    valueColor: transaction.title?.isNotEmpty == true
                        ? null
                        : colorScheme.onSurfaceVariant,
                  ),

                  // 메모 (있을 경우)
                  if (transaction.memo?.isNotEmpty == true)
                    _buildDetailRow(
                      context,
                      icon: Icons.note,
                      label: l10n.labelMemo,
                      value: transaction.memo!,
                    ),

                  // 금액
                  _buildDetailRow(
                    context,
                    icon: Icons.attach_money,
                    label: l10n.labelAmount,
                    value:
                        '${transaction.isIncome
                            ? '+'
                            : transaction.isAssetType
                            ? ''
                            : '-'}${formatter.format(transaction.amount)}${l10n.transactionAmountUnit}',
                    valueColor: amountColor,
                  ),

                  // 날짜
                  _buildDetailRow(
                    context,
                    icon: Icons.calendar_today,
                    label: l10n.labelDate,
                    value: dateFormat.format(transaction.date),
                  ),

                  // 카테고리
                  if (transaction.categoryName != null)
                    _buildDetailRow(
                      context,
                      icon: Icons.category,
                      label: l10n.labelCategory,
                      value: transaction.categoryName!,
                    ),

                  // 결제수단
                  if (transaction.paymentMethodName != null)
                    _buildDetailRow(
                      context,
                      icon: Icons.credit_card,
                      label: l10n.labelPaymentMethod,
                      value: transaction.paymentMethodName!,
                    ),

                  // 작성자
                  if (transaction.userName != null)
                    _buildDetailRow(
                      context,
                      icon: Icons.person,
                      label: l10n.labelAuthor,
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
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.transactionDeleteConfirmTitle),
        content: Text(l10n.transactionDeleteConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            child: Text(l10n.commonDelete),
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
            SnackBar(
              content: Text(l10n.transactionDeleted),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.transactionDeleteFailed(e.toString())),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      }
    }
  }
}
