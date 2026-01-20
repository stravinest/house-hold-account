import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../shared/themes/design_tokens.dart';
import '../../data/models/pending_transaction_model.dart';
import '../../domain/entities/pending_transaction.dart';

class PendingTransactionCard extends StatelessWidget {
  final PendingTransactionModel transaction;
  final VoidCallback? onConfirm;
  final VoidCallback? onReject;
  final VoidCallback? onEdit;

  // NumberFormat 캐싱 (매 빌드마다 생성하지 않음)
  static final _currencyFormat = NumberFormat.currency(
    locale: 'ko_KR',
    symbol: '',
    decimalDigits: 0,
  );
  static final _timeFormat = DateFormat('HH:mm');

  const PendingTransactionCard({
    super.key,
    required this.transaction,
    this.onConfirm,
    this.onReject,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isParsed = transaction.isParsed;
    final isExpense = transaction.isExpense;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(Spacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더: 소스 타입 & 시간
              Row(
                children: [
                  _buildSourceBadge(context),
                  const SizedBox(width: Spacing.sm),
                  if (transaction.sourceSender != null)
                    Expanded(
                      child: Text(
                        transaction.sourceSender!,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const Spacer(),
                  Text(
                    _formatTime(transaction.sourceTimestamp),
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.sm),

              // 파싱된 정보 (있으면)
              if (isParsed) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 금액
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatAmount(transaction.parsedAmount!, isExpense),
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isExpense
                                  ? colorScheme.error
                                  : colorScheme.primary,
                            ),
                          ),
                          if (transaction.parsedMerchant != null)
                            Text(
                              transaction.parsedMerchant!,
                              style: textTheme.bodyMedium,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    // 상태 배지
                    _buildStatusBadge(context),
                  ],
                ),
                const SizedBox(height: Spacing.sm),
              ],

              // 원본 메시지 (축약)
              Container(
                padding: const EdgeInsets.all(Spacing.sm),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(BorderRadiusToken.sm),
                ),
                child: Text(
                  transaction.sourceContent,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // 파싱 실패 경고
              if (!isParsed) ...[
                const SizedBox(height: Spacing.sm),
                Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 16,
                      color: colorScheme.error,
                    ),
                    const SizedBox(width: Spacing.xs),
                    Text(
                      '거래 정보를 파싱할 수 없습니다',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ],

              // 액션 버튼 (pending 상태일 때만)
              if (onConfirm != null || onReject != null) ...[
                const SizedBox(height: Spacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onReject != null)
                      TextButton.icon(
                        onPressed: onReject,
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('거부'),
                        style: TextButton.styleFrom(
                          foregroundColor: colorScheme.error,
                        ),
                      ),
                    const SizedBox(width: Spacing.sm),
                    if (onConfirm != null && isParsed)
                      FilledButton.icon(
                        onPressed: onConfirm,
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('저장'),
                      ),
                    if (onConfirm != null && !isParsed)
                      OutlinedButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('수정'),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSourceBadge(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSms = transaction.sourceType == SourceType.sms;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.sm,
        vertical: Spacing.xs,
      ),
      decoration: BoxDecoration(
        color: isSms
            ? colorScheme.primaryContainer
            : colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(BorderRadiusToken.xs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSms ? Icons.sms_outlined : Icons.notifications_outlined,
            size: 14,
            color: isSms
                ? colorScheme.onPrimaryContainer
                : colorScheme.onTertiaryContainer,
          ),
          const SizedBox(width: 4),
          Text(
            isSms ? 'SMS' : '알림',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isSms
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onTertiaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Color backgroundColor;
    Color foregroundColor;
    IconData icon;
    String label;

    switch (transaction.status) {
      case PendingTransactionStatus.pending:
        backgroundColor = colorScheme.secondaryContainer;
        foregroundColor = colorScheme.onSecondaryContainer;
        icon = Icons.hourglass_empty;
        label = '대기';
        break;
      case PendingTransactionStatus.confirmed:
        backgroundColor = colorScheme.primaryContainer;
        foregroundColor = colorScheme.onPrimaryContainer;
        icon = Icons.check;
        label = '확인됨';
        break;
      case PendingTransactionStatus.converted:
        backgroundColor = colorScheme.tertiaryContainer;
        foregroundColor = colorScheme.onTertiaryContainer;
        icon = Icons.check_circle;
        label = '저장됨';
        break;
      case PendingTransactionStatus.rejected:
        backgroundColor = colorScheme.errorContainer;
        foregroundColor = colorScheme.onErrorContainer;
        icon = Icons.close;
        label = '거부됨';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.sm,
        vertical: Spacing.xs,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(BorderRadiusToken.xs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foregroundColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: foregroundColor,
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(int amount, bool isExpense) {
    final prefix = isExpense ? '-' : '+';
    return '$prefix${_currencyFormat.format(amount)}원';
  }

  String _formatTime(DateTime dateTime) {
    return _timeFormat.format(dateTime);
  }
}
