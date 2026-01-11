import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../domain/entities/statistics_entities.dart';
import '../../providers/statistics_provider.dart';

class PaymentMethodDonutChart extends ConsumerWidget {
  const PaymentMethodDonutChart({super.key});

  Color _parseColor(String colorString) {
    try {
      final colorValue = int.parse(colorString.replaceFirst('#', '0xFF'));
      return Color(colorValue);
    } catch (e) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statisticsAsync = ref.watch(paymentMethodStatisticsProvider);
    final numberFormat = NumberFormat('#,###');

    return statisticsAsync.when(
      data: (statistics) {
        if (statistics.isEmpty) {
          return _buildEmptyState(context);
        }
        return _buildChart(context, statistics, numberFormat);
      },
      loading: () => const SizedBox(
        height: 250,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Center(child: Text('오류: $error')),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return SizedBox(
      height: 250,
      child: Center(
        child: Text(
          '데이터가 없습니다',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ),
    );
  }

  Widget _buildChart(
    BuildContext context,
    List<PaymentMethodStatistics> statistics,
    NumberFormat numberFormat,
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
          _buildCenterText(context, totalAmount, numberFormat),
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
    int totalAmount,
    NumberFormat numberFormat,
  ) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '총 지출',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${numberFormat.format(totalAmount)}원',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
