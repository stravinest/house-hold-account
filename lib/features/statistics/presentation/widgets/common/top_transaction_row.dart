import 'package:flutter/material.dart';

import '../../../../../core/utils/color_utils.dart';
import '../../../../../core/utils/number_format_utils.dart';
import '../../../../../l10n/generated/app_localizations.dart';
import '../../../data/repositories/statistics_repository.dart';

/// 상세 Bottom Sheet에서 Top5 거래 항목을 표시하는 공통 위젯
class TopTransactionRow extends StatelessWidget {
  final CategoryTopTransaction item;
  final String amountPrefix;
  final Color amountColor;
  final Color rankBgColor;
  final bool isLast;

  const TopTransactionRow({
    super.key,
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
                color: item.rank == 1 ? Colors.white : rankBgColor,
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
