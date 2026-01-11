import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/repositories/statistics_repository.dart';
import '../../../domain/entities/statistics_entities.dart';
import '../../../../transaction/presentation/providers/transaction_provider.dart';
import '../../providers/statistics_provider.dart';

class TrendBarChart extends ConsumerWidget {
  const TrendBarChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(trendPeriodProvider);
    final selectedType = ref.watch(selectedStatisticsTypeProvider);

    if (period == TrendPeriod.monthly) {
      return _MonthlyTrendChart(selectedType: selectedType);
    } else {
      return _YearlyTrendChart(selectedType: selectedType);
    }
  }
}

class _MonthlyTrendChart extends ConsumerWidget {
  final String selectedType;

  const _MonthlyTrendChart({required this.selectedType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendAsync = ref.watch(monthlyTrendWithAverageProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final numberFormat = NumberFormat('#,###');

    return trendAsync.when(
      data: (trendData) {
        if (trendData.data.isEmpty) {
          return _buildEmptyState(context);
        }
        return _buildChart(context, trendData, selectedDate, numberFormat);
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
    TrendStatisticsData trendData,
    DateTime selectedDate,
    NumberFormat numberFormat,
  ) {
    final data = trendData.data.cast<MonthlyStatistics>();
    final average = trendData.getAverageByType(selectedType);
    final theme = Theme.of(context);
    final barColor = _getBarColor(selectedType, context);

    // maxY 계산
    double maxY = 0;
    for (final item in data) {
      final value = _getValueByType(item, selectedType);
      if (value > maxY) maxY = value.toDouble();
    }
    if (average > maxY) maxY = average.toDouble();
    maxY = maxY * 1.2;
    if (maxY == 0) maxY = 100;

    return SizedBox(
      height: 250,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: data.length * 60.0 + 40,
          child: Padding(
            padding: const EdgeInsets.only(top: 16, right: 16),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                minY: 0,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => theme.colorScheme.surfaceContainerHighest,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final item = data[group.x.toInt()];
                      return BarTooltipItem(
                        '${item.year}.${item.month.toString().padLeft(2, '0')}\n${numberFormat.format(rod.toY.toInt())}원',
                        TextStyle(color: theme.colorScheme.onSurface),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < data.length) {
                          final item = data[index];
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '${item.year % 100}.${item.month.toString().padLeft(2, '0')}',
                              style: theme.textTheme.bodySmall,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: theme.colorScheme.outlineVariant,
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: _buildBarGroups(data, selectedDate, barColor),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: average.toDouble(),
                      color: theme.colorScheme.outline,
                      strokeWidth: 1,
                      dashArray: [5, 5],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        labelResolver: (_) => '평균',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups(
    List<MonthlyStatistics> data,
    DateTime selectedDate,
    Color barColor,
  ) {
    return List.generate(data.length, (index) {
      final item = data[index];
      final value = _getValueByType(item, selectedType);
      final isSelected = item.year == selectedDate.year && item.month == selectedDate.month;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: value.toDouble(),
            color: isSelected ? barColor : barColor.withOpacity(0.5),
            width: 24,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    });
  }

  int _getValueByType(MonthlyStatistics item, String type) {
    switch (type) {
      case 'income':
        return item.income;
      case 'saving':
        return item.saving;
      default:
        return item.expense;
    }
  }

  Color _getBarColor(String type, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (type) {
      case 'income':
        return isDark ? Colors.blue.shade300 : Colors.blue;
      case 'saving':
        return isDark ? Colors.green.shade300 : Colors.green;
      default:
        return isDark ? Colors.red.shade300 : Colors.red;
    }
  }
}

class _YearlyTrendChart extends ConsumerWidget {
  final String selectedType;

  const _YearlyTrendChart({required this.selectedType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendAsync = ref.watch(yearlyTrendProvider);
    final numberFormat = NumberFormat('#,###');

    return trendAsync.when(
      data: (data) {
        if (data.isEmpty) {
          return _buildEmptyState(context);
        }
        return _buildChart(context, data, numberFormat);
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
    List<YearlyStatistics> data,
    NumberFormat numberFormat,
  ) {
    final theme = Theme.of(context);
    final barColor = _getBarColor(selectedType, context);

    // maxY 계산
    double maxY = 0;
    for (final item in data) {
      final value = _getValueByType(item, selectedType);
      if (value > maxY) maxY = value.toDouble();
    }
    maxY = maxY * 1.2;
    if (maxY == 0) maxY = 100;

    // 평균 계산
    int total = 0;
    for (final item in data) {
      total += _getValueByType(item, selectedType);
    }
    final average = data.isNotEmpty ? total ~/ data.length : 0;

    return SizedBox(
      height: 250,
      child: Padding(
        padding: const EdgeInsets.only(top: 16, right: 16, left: 16),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxY,
            minY: 0,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => theme.colorScheme.surfaceContainerHighest,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final item = data[group.x.toInt()];
                  return BarTooltipItem(
                    '${item.year}년\n${numberFormat.format(rod.toY.toInt())}원',
                    TextStyle(color: theme.colorScheme.onSurface),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index >= 0 && index < data.length) {
                      final item = data[index];
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '${item.year}년',
                          style: theme.textTheme.bodySmall,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                  reservedSize: 30,
                ),
              ),
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: maxY / 4,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: theme.colorScheme.outlineVariant,
                  strokeWidth: 1,
                );
              },
            ),
            borderData: FlBorderData(show: false),
            barGroups: _buildBarGroups(data, barColor),
            extraLinesData: ExtraLinesData(
              horizontalLines: [
                HorizontalLine(
                  y: average.toDouble(),
                  color: theme.colorScheme.outline,
                  strokeWidth: 1,
                  dashArray: [5, 5],
                  label: HorizontalLineLabel(
                    show: true,
                    alignment: Alignment.topRight,
                    labelResolver: (_) => '평균',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups(
    List<YearlyStatistics> data,
    Color barColor,
  ) {
    final currentYear = DateTime.now().year;

    return List.generate(data.length, (index) {
      final item = data[index];
      final value = _getValueByType(item, selectedType);
      final isSelected = item.year == currentYear;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: value.toDouble(),
            color: isSelected ? barColor : barColor.withOpacity(0.5),
            width: 40,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    });
  }

  int _getValueByType(YearlyStatistics item, String type) {
    switch (type) {
      case 'income':
        return item.income;
      case 'saving':
        return item.saving;
      default:
        return item.expense;
    }
  }

  Color _getBarColor(String type, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (type) {
      case 'income':
        return isDark ? Colors.blue.shade300 : Colors.blue;
      case 'saving':
        return isDark ? Colors.green.shade300 : Colors.green;
      default:
        return isDark ? Colors.red.shade300 : Colors.red;
    }
  }
}
