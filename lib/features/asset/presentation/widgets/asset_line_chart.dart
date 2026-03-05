import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/number_format_utils.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../statistics/domain/entities/statistics_entities.dart';
import '../providers/asset_provider.dart';

class AssetLineChart extends ConsumerWidget {
  const AssetLineChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final period = ref.watch(assetChartPeriodProvider);

    if (period == TrendPeriod.yearly) {
      return _buildYearlyChart(context, ref, l10n, theme);
    }
    return _buildMonthlyChart(context, ref, l10n, theme);
  }

  Widget _buildMonthlyChart(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    final monthlyAsync = ref.watch(assetMonthlyChartProvider);

    return monthlyAsync.when(
      data: (monthly) {
        if (monthly.isEmpty) {
          return _buildEmptyState(l10n, theme);
        }

        final amounts = monthly.map((m) => m.amount).toList();
        final maxY = _calculateMaxY(amounts);
        final minY = _calculateMinY(amounts);
        final spots = _buildSpots(amounts);

        return _buildChart(
          theme: theme,
          spots: spots,
          dataLength: monthly.length,
          maxY: maxY,
          minY: minY,
          bottomTitleBuilder: (index) {
            if (index >= 0 && index < monthly.length) {
              return l10n.statisticsMonthLabel(monthly[index].month);
            }
            return null;
          },
          tooltipBuilder: (index) {
            if (index >= 0 && index < monthly.length) {
              final item = monthly[index];
              return '${item.year}.${item.month.toString().padLeft(2, '0')}\n${NumberFormatUtils.currency.format(item.amount)}';
            }
            return null;
          },
        );
      },
      loading: () => const AspectRatio(
        aspectRatio: 1.7,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Center(child: Text(e.toString())),
    );
  }

  Widget _buildYearlyChart(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    final yearlyAsync = ref.watch(assetYearlyChartProvider);

    return yearlyAsync.when(
      data: (yearly) {
        if (yearly.isEmpty) {
          return _buildEmptyState(l10n, theme);
        }

        final amounts = yearly.map((y) => y.amount).toList();
        final maxY = _calculateMaxY(amounts);
        final minY = _calculateMinY(amounts);
        final spots = _buildSpots(amounts);

        return _buildChart(
          theme: theme,
          spots: spots,
          dataLength: yearly.length,
          maxY: maxY,
          minY: minY,
          bottomTitleBuilder: (index) {
            if (index >= 0 && index < yearly.length) {
              return l10n.statisticsYearLabel(yearly[index].year);
            }
            return null;
          },
          tooltipBuilder: (index) {
            if (index >= 0 && index < yearly.length) {
              final item = yearly[index];
              return '${item.year}\n${NumberFormatUtils.currency.format(item.amount)}';
            }
            return null;
          },
        );
      },
      loading: () => const AspectRatio(
        aspectRatio: 1.7,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Center(child: Text(e.toString())),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n, ThemeData theme) {
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

  Widget _buildChart({
    required ThemeData theme,
    required List<FlSpot> spots,
    required int dataLength,
    required double maxY,
    required double minY,
    required String? Function(int index) bottomTitleBuilder,
    required String? Function(int index) tooltipBuilder,
  }) {
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
                    final title = bottomTitleBuilder(index);
                    if (title != null) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          title,
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
                        NumberFormatUtils.currency.format(value.toInt()),
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
              horizontalInterval: maxY > 0 ? maxY / 4 : 25,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.5,
                  ),
                  strokeWidth: 1,
                );
              },
            ),
            minX: 0,
            maxX: (dataLength - 1).toDouble(),
            minY: minY,
            maxY: maxY,
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) =>
                    theme.colorScheme.surfaceContainerHighest,
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((spot) {
                    final index = spot.x.toInt();
                    final text = tooltipBuilder(index);
                    if (text != null) {
                      return LineTooltipItem(
                        text,
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

  double _calculateMaxY(List<int> amounts) {
    if (amounts.isEmpty) return 100;

    final maxAmount = amounts.reduce((a, b) => a > b ? a : b);
    final minAmount = amounts.reduce((a, b) => a < b ? a : b);

    if (maxAmount <= 0) return 100;

    if (minAmount < 0) {
      return ((maxAmount - minAmount) * 1.2).ceilToDouble();
    }

    return (maxAmount * 1.2).ceilToDouble();
  }

  double _calculateMinY(List<int> amounts) {
    if (amounts.isEmpty) return 0;

    final minAmount = amounts.reduce((a, b) => a < b ? a : b);

    if (minAmount < 0) {
      return (minAmount * 1.2).floorToDouble();
    }

    return 0;
  }

  List<FlSpot> _buildSpots(List<int> amounts) {
    return List.generate(
      amounts.length,
      (index) => FlSpot(index.toDouble(), amounts[index].toDouble()),
    );
  }
}
