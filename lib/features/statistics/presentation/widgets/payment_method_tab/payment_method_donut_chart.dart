import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/utils/number_format_utils.dart';
import '../../../../../l10n/generated/app_localizations.dart';
import '../../../domain/entities/statistics_entities.dart';
import '../../providers/statistics_provider.dart';

class PaymentMethodDonutChart extends ConsumerWidget {
  const PaymentMethodDonutChart({super.key});

  Color _parseColor(String colorString) {
    try {
      final colorValue = int.parse(colorString.replaceFirst('#', '0xFF'));
      return Color(colorValue);
    } catch (e) {
      return const Color(0xFF9E9E9E);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final statisticsAsync = ref.watch(paymentMethodStatisticsProvider);

    return statisticsAsync.when(
      data: (statistics) {
        if (statistics.isEmpty) {
          return _buildEmptyState(context, l10n);
        }
        return _buildChart(context, l10n, statistics);
      },
      loading: () => const SizedBox(
        height: 250,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) =>
          Center(child: Text(l10n.errorWithMessage(error.toString()))),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return SizedBox(
      height: 250,
      child: Center(
        child: Text(
          l10n.statisticsNoData,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildChart(
    BuildContext context,
    AppLocalizations l10n,
    List<PaymentMethodStatistics> statistics,
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
          _buildCenterText(context, l10n, totalAmount),
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
      final color = _parseColor(item.paymentMethodColor);

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
  ) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.statisticsTotalExpense,
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
