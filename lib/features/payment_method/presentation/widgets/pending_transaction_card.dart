import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/themes/design_tokens.dart';
import '../../data/models/pending_transaction_model.dart';
import '../../domain/entities/pending_transaction.dart';
import '../providers/pending_transaction_provider.dart';

class PendingTransactionCard extends ConsumerStatefulWidget {
  final PendingTransactionModel transaction;
  final String ledgerId;
  final String userId;
  final VoidCallback? onConfirm;
  final VoidCallback? onReject;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onViewOriginal;

  const PendingTransactionCard({
    super.key,
    required this.transaction,
    required this.ledgerId,
    required this.userId,
    this.onConfirm,
    this.onReject,
    this.onEdit,
    this.onDelete,
    this.onViewOriginal,
  });

  @override
  ConsumerState<PendingTransactionCard> createState() =>
      _PendingTransactionCardState();
}

class _PendingTransactionCardState
    extends ConsumerState<PendingTransactionCard> {
  // NumberFormat 캐싱 (매 빌드마다 생성하지 않음)
  static final _currencyFormat = NumberFormat.currency(
    locale: 'ko_KR',
    symbol: '',
    decimalDigits: 0,
  );
  static final _timeFormat = DateFormat('HH:mm');
  static final _dateTimeFormat = DateFormat('M/d HH:mm');

  bool _isExpanded = false;
  PendingTransactionModel? _originalTransaction;
  bool _isLoadingOriginal = false;

  @override
  void initState() {
    super.initState();
    if (widget.transaction.isDuplicate) {
      _loadOriginalTransaction();
    }
  }

  Future<void> _loadOriginalTransaction() async {
    if (!widget.transaction.isDuplicate ||
        widget.transaction.duplicateHash == null) {
      return;
    }

    setState(() => _isLoadingOriginal = true);

    try {
      final repository = ref.read(pendingTransactionRepositoryProvider);
      final original = await repository.findOriginalDuplicate(
        ledgerId: widget.ledgerId,
        userId: widget.userId,
        duplicateHash: widget.transaction.duplicateHash!,
        currentTransactionId: widget.transaction.id,
      );

      if (mounted) {
        setState(() {
          _originalTransaction = original;
          _isLoadingOriginal = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingOriginal = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isParsed = widget.transaction.isParsed;
    final isExpense = widget.transaction.isExpense;
    final isDuplicate = widget.transaction.isDuplicate;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onEdit,
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
                  if (widget.transaction.sourceSender != null)
                    Expanded(
                      child: Text(
                        widget.transaction.sourceSender!,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const Spacer(),
                  Text(
                    _formatTime(widget.transaction.sourceTimestamp),
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (widget.onDelete != null) ...[
                    const SizedBox(width: Spacing.xs),
                    InkWell(
                      onTap: widget.onDelete,
                      borderRadius: BorderRadius.circular(
                        BorderRadiusToken.circular,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.delete_outline,
                          size: 16,
                          color: colorScheme.error,
                        ),
                      ),
                    ),
                  ],
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
                            _formatAmount(
                              widget.transaction.parsedAmount!,
                              isExpense,
                            ),
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isExpense
                                  ? colorScheme.error
                                  : colorScheme.primary,
                            ),
                          ),
                          if (widget.transaction.parsedMerchant != null)
                            Text(
                              widget.transaction.parsedMerchant!,
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
                  widget.transaction.sourceContent,
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
                      l10n.pendingTransactionParsingFailed,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ],

              // 중복 정보 섹션 (중복일 때만)
              if (isDuplicate) ...[
                const SizedBox(height: Spacing.sm),
                _buildDuplicateInfoSection(context, l10n, colorScheme, textTheme),
              ],

              // 액션 버튼
              if (widget.onConfirm != null ||
                  widget.onReject != null ||
                  widget.onEdit != null) ...[
                const SizedBox(height: Spacing.sm),
                _buildActionButtons(
                  context: context,
                  l10n: l10n,
                  colorScheme: colorScheme,
                  isDuplicate: isDuplicate,
                  isParsed: isParsed,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDuplicateInfoSection(
    BuildContext context,
    AppLocalizations l10n,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(BorderRadiusToken.sm),
        border: Border.all(
          color: colorScheme.error.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더 (펼침/접힘 버튼)
          InkWell(
            onTap: () {
              setState(() => _isExpanded = !_isExpanded);
            },
            borderRadius: BorderRadius.circular(BorderRadiusToken.sm),
            child: Padding(
              padding: const EdgeInsets.all(Spacing.sm),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: colorScheme.error,
                  ),
                  const SizedBox(width: Spacing.xs),
                  Expanded(
                    child: Text(
                      l10n.duplicateTransactionWarning,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 20,
                    color: colorScheme.error,
                  ),
                ],
              ),
            ),
          ),

          // 펼쳐진 내용
          if (_isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(Spacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isLoadingOriginal)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(Spacing.sm),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  else if (_originalTransaction != null) ...[
                    Text(
                      l10n.originalTransactionTime,
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: Spacing.xs),
                    Text(
                      _formatDateTime(_originalTransaction!.sourceTimestamp),
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: Spacing.sm),

                    // 원본 보기 버튼
                    if (widget.onViewOriginal != null)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: widget.onViewOriginal,
                          icon: const Icon(Icons.launch, size: 16),
                          label: Text(l10n.viewOriginal),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colorScheme.error,
                            side: BorderSide(color: colorScheme.error),
                          ),
                        ),
                      ),
                  ] else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.originalTransactionNotFound,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: Spacing.xs),
                        Text(
                          l10n.duplicateMessageReceivedTwice,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSourceBadge(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final isSms = widget.transaction.sourceType == SourceType.sms;

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
            isSms ? l10n.sourceTypeSms : l10n.sourceTypeNotification,
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
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    Color backgroundColor;
    Color foregroundColor;
    IconData icon;
    String label;

    switch (widget.transaction.status) {
      case PendingTransactionStatus.pending:
        backgroundColor = colorScheme.secondaryContainer;
        foregroundColor = colorScheme.onSecondaryContainer;
        icon = Icons.hourglass_empty;
        label = l10n.pendingTransactionStatusWaiting;
        break;
      case PendingTransactionStatus.confirmed:
        backgroundColor = colorScheme.primaryContainer;
        foregroundColor = colorScheme.onPrimaryContainer;
        icon = Icons.check;
        label = l10n.pendingTransactionStatusConfirmed;
        break;
      case PendingTransactionStatus.converted:
        backgroundColor = colorScheme.tertiaryContainer;
        foregroundColor = colorScheme.onTertiaryContainer;
        icon = Icons.check_circle;
        label = l10n.pendingTransactionStatusSaved;
        break;
      case PendingTransactionStatus.rejected:
        backgroundColor = colorScheme.errorContainer;
        foregroundColor = colorScheme.onErrorContainer;
        icon = Icons.close;
        label = l10n.pendingTransactionStatusDenied;
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

  String _formatDateTime(DateTime dateTime) {
    return _dateTimeFormat.format(dateTime);
  }
}
