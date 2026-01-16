import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/asset_statistics.dart';

class AssetLineChart extends StatelessWidget {
  final List<MonthlyAsset> monthly;

  const AssetLineChart({super.key, required this.monthly});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final numberFormat = NumberFormat('#,###');

    if (monthly.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            l10n.assetNoAssetData,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final maxY = _calculateMaxY();
    final minY = _calculateMinY();
    final spots = _buildSpots();

    return AspectRatio(
      aspectRatio: 1.7,
      child: Padding(
        padding: const EdgeInsets.only(
          right: 18,
          left: 12,
          top: 24,
          bottom: 12,
        ),
        child: LineChart(
          LineChartData(
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: false,
                color: theme.colorScheme.primary,
                barWidth: 3,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 4,
                      color: theme.colorScheme.primary,
                      strokeWidth: 2,
                      strokeColor: theme.colorScheme.surface,
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                ),
              ),
            ],
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index >= 0 && index < monthly.length) {
                      final item = monthly[index];
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          l10n.statisticsMonthLabel(item.month),
                          style: theme.textTheme.bodySmall,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 50,
                  getTitlesWidget: (value, meta) {
                    if (value == maxY || value == 0) {
                      return Text(
                        numberFormat.format(value.toInt()),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 10,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: maxY / 4,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                  strokeWidth: 1,
                );
              },
            ),
            minX: 0,
            maxX: (monthly.length - 1).toDouble(),
            minY: minY,
            maxY: maxY,
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) =>
                    theme.colorScheme.surfaceContainerHighest,
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((spot) {
                    final index = spot.x.toInt();
                    if (index >= 0 && index < monthly.length) {
                      final item = monthly[index];
                      return LineTooltipItem(
                        '${item.year}.${item.month.toString().padLeft(2, '0')}\n${numberFormat.format(item.amount)}원',
                        TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }
                    return null;
                  }).toList();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  double _calculateMaxY() {
    if (monthly.isEmpty) return 100;

    final maxAmount = monthly
        .map((m) => m.amount)
        .reduce((a, b) => a > b ? a : b);

    final minAmount = monthly
        .map((m) => m.amount)
        .reduce((a, b) => a < b ? a : b);

    if (maxAmount <= 0) return 100;

    if (minAmount < 0) {
      return ((maxAmount - minAmount) * 1.2).ceilToDouble();
    }

    return (maxAmount * 1.2).ceilToDouble();
  }

  double _calculateMinY() {
    if (monthly.isEmpty) return 0;

    final minAmount = monthly
        .map((m) => m.amount)
        .reduce((a, b) => a < b ? a : b);

    if (minAmount < 0) {
      return (minAmount * 1.2).floorToDouble();
    }

    return 0;
  }

  List<FlSpot> _buildSpots() {
    return List.generate(
      monthly.length,
      (index) => FlSpot(index.toDouble(), monthly[index].amount.toDouble()),
    );
  }
}
