import 'package:flutter/material.dart';

import '../../../../../l10n/generated/app_localizations.dart';
import 'payment_method_donut_chart.dart';
import 'payment_method_list.dart';

class PaymentMethodTabView extends StatelessWidget {
  const PaymentMethodTabView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 안내 메시지 (지출만 표시)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.statisticsPaymentNotice,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 도넛 차트
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.statisticsPaymentDistribution,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const PaymentMethodDonutChart(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 결제수단 리스트
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    l10n.statisticsPaymentRanking,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                const PaymentMethodList(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
