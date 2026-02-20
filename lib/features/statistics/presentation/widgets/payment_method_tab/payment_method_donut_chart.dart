import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/utils/color_utils.dart';
import '../../../../../core/utils/number_format_utils.dart';
import '../../../../../l10n/generated/app_localizations.dart';
import '../../../domain/entities/statistics_entities.dart';
import '../../providers/statistics_provider.dart';

class PaymentMethodDonutChart extends ConsumerWidget {
  const PaymentMethodDonutChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final statisticsAsync = ref.watch(paymentMethodStatisticsProvider);

    // 유저 선택 상태에 따라 중앙 라벨 결정
    final sharedState =
        ref.watch(paymentMethodSharedStatisticsStateProvider);
    final isShared = ref.watch(isSharedLedgerProvider);
    final userStatsAsync =
        ref.watch(paymentMethodStatisticsByUserProvider);

    String centerLabel = l10n.statisticsTotalExpense;
    if (isShared &&
        sharedState.mode == SharedStatisticsMode.singleUser &&
        sharedState.selectedUserId != null) {
      final userStats = userStatsAsync.valueOrNull;
      if (userStats != null &&
          userStats.containsKey(sharedState.selectedUserId)) {
        centerLabel = userStats[sharedState.selectedUserId]!.userName;
      }
    } else if (isShared &&
        sharedState.mode == SharedStatisticsMode.combined) {
      centerLabel = l10n.statisticsFilterCombined;
    }

    return statisticsAsync.when(
      data: (statistics) {
        if (statistics.isEmpty) {
          return _buildEmptyState(context, l10n, centerLabel);
        }
        return _buildChart(context, l10n, statistics, centerLabel);
      },
      loading: () => const SizedBox(
        height: 250,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) =>
          Center(child: Text(l10n.errorWithMessage(error.toString()))),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    AppLocalizations l10n,
    String centerLabel,
  ) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 250,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              centerLabel,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.statisticsNoData,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(
    BuildContext context,
    AppLocalizations l10n,
    List<PaymentMethodStatistics> statistics,
    String centerLabel,
  ) {
    final totalAmount = statistics.fold(0, (sum, item) => sum + item.amount);

    return SizedBox(
      height: 250,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 60,
              sections: _buildSections(statistics, totalAmount),
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {},
              ),
            ),
          ),
          // 중앙 총금액 표시
          _buildCenterText(context, l10n, totalAmount, centerLabel),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildSections(
    List<PaymentMethodStatistics> data,
    int totalAmount,
  ) {
    return data.map((item) {
      final percentage = item.percentage;
      final color = ColorUtils.parseHexColor(
        item.paymentMethodColor,
        fallback: const Color(0xFF9E9E9E),
      );

      return PieChartSectionData(
        color: color,
        value: item.amount.toDouble(),
        title: percentage >= 5 ? '${percentage.toStringAsFixed(0)}%' : '',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildCenterText(
    BuildContext context,
    AppLocalizations l10n,
    int totalAmount,
    String centerLabel,
  ) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          centerLabel,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${NumberFormatUtils.currency.format(totalAmount)}${l10n.transactionAmountUnit}',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
