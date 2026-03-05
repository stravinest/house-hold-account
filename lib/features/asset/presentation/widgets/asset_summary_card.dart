import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../providers/asset_provider.dart';

class AssetSummaryCard extends ConsumerWidget {
  final int totalAmount;
  final int monthlyChange;
  final String? ledgerId;

  const AssetSummaryCard({
    super.key,
    required this.totalAmount,
    required this.monthlyChange,
    this.ledgerId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final numberFormat = NumberFormat('#,###');
    final isPositive = monthlyChange >= 0;
    final colorScheme = Theme.of(context).colorScheme;

    final includeLoanRepayment = ref.watch(includeLoanRepaymentProvider);
    final loanRepaidAmount = ref.watch(totalLoanRepaidAmountProvider);
    final displayTotal = includeLoanRepayment
        ? totalAmount + loanRepaidAmount
        : totalAmount;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.assetTotal,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF44483E),
              fontWeight: FontWeight.normal,
            ),
          ),
          const SizedBox(height: 16),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '${numberFormat.format(displayTotal)}${l10n.transactionAmountUnit}',
              style: const TextStyle(
                fontSize: 32,
                color: Color(0xFF2E7D32),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                size: 16,
                color: isPositive
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFFBA1A1A),
              ),
              const SizedBox(width: 6),
              Text(
                l10n.assetThisMonth(
                  '${isPositive ? '+' : ''}${numberFormat.format(monthlyChange)}',
                ),
                style: TextStyle(
                  fontSize: 13,
                  color: isPositive
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFFBA1A1A),
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
          if (loanRepaidAmount > 0) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => ref.read(includeLoanRepaymentProvider.notifier).toggle(),
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: Checkbox(
                      value: includeLoanRepayment,
                      onChanged: (_) =>
                          ref.read(includeLoanRepaymentProvider.notifier).toggle(),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.assetIncludeLoanRepayment,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (includeLoanRepayment)
                    Text(
                      '+${numberFormat.format(loanRepaidAmount)}${l10n.transactionAmountUnit}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.tertiary,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
