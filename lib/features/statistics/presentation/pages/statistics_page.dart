import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/statistics_provider.dart';

class StatisticsPage extends ConsumerWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 월별 요약 카드
          const _MonthlySummaryCard(),
          const SizedBox(height: 24),

          // 타입 선택 (지출/수입)
          const _TypeSelector(),
          const SizedBox(height: 16),

          // 카테고리별 파이 차트
          const _CategoryPieChart(),
          const SizedBox(height: 24),

          // 카테고리별 목록
          const _CategoryList(),
          const SizedBox(height: 24),

          // 월별 추세 차트
          Text(
            '월별 추세',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          const _MonthlyTrendChart(),
          const SizedBox(height: 24),

          // 일별 추세 차트
          Text(
            '일별 추세',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          const _DailyTrendChart(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// 월별 요약 카드
class _MonthlySummaryCard extends ConsumerWidget {
  const _MonthlySummaryCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totals = ref.watch(totalStatisticsProvider);
    final numberFormat = NumberFormat('#,###');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _SummaryItem(
                    label: '수입',
                    amount: totals['income'] ?? 0,
                    color: Colors.blue,
                    numberFormat: numberFormat,
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Theme.of(context).dividerColor,
                ),
                Expanded(
                  child: _SummaryItem(
                    label: '지출',
                    amount: totals['expense'] ?? 0,
                    color: Colors.red,
                    numberFormat: numberFormat,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '잔액: ',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '${numberFormat.format(totals['balance'] ?? 0)}원',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: (totals['balance'] ?? 0) >= 0
                            ? Colors.blue
                            : Colors.red,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final int amount;
  final Color color;
  final NumberFormat numberFormat;

  const _SummaryItem({
    required this.label,
    required this.amount,
    required this.color,
    required this.numberFormat,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          '${numberFormat.format(amount)}원',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
      ],
    );
  }
}

// 타입 선택기
class _TypeSelector extends ConsumerWidget {
  const _TypeSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedType = ref.watch(selectedStatisticsTypeProvider);

    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(
          value: 'expense',
          label: Text('지출'),
          icon: Icon(Icons.arrow_downward),
        ),
        ButtonSegment(
          value: 'income',
          label: Text('수입'),
          icon: Icon(Icons.arrow_upward),
        ),
      ],
      selected: {selectedType},
      onSelectionChanged: (selected) {
        ref.read(selectedStatisticsTypeProvider.notifier).state = selected.first;
      },
    );
  }
}

// 카테고리별 파이 차트
class _CategoryPieChart extends ConsumerWidget {
  const _CategoryPieChart();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statisticsAsync = ref.watch(categoryStatisticsProvider);

    return statisticsAsync.when(
      data: (statistics) {
        if (statistics.isEmpty) {
          return Card(
            child: SizedBox(
              height: 200,
              child: Center(
                child: Text(
                  '데이터가 없습니다',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            ),
          );
        }

        final total = statistics.fold(0, (sum, item) => sum + item.amount);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: statistics.map((stat) {
                    final percentage = (stat.amount / total * 100);
                    return PieChartSectionData(
                      color: _parseColor(stat.categoryColor),
                      value: stat.amount.toDouble(),
                      title: percentage >= 5
                          ? '${percentage.toStringAsFixed(1)}%'
                          : '',
                      radius: 50,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const Card(
        child: SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, st) => Card(
        child: SizedBox(
          height: 200,
          child: Center(child: Text('오류: $e')),
        ),
      ),
    );
  }

  Color _parseColor(String hexColor) {
    try {
      final hex = hexColor.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return Colors.grey;
    }
  }
}

// 카테고리별 목록
class _CategoryList extends ConsumerWidget {
  const _CategoryList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statisticsAsync = ref.watch(categoryStatisticsProvider);
    final numberFormat = NumberFormat('#,###');

    return statisticsAsync.when(
      data: (statistics) {
        if (statistics.isEmpty) return const SizedBox.shrink();

        final total = statistics.fold(0, (sum, item) => sum + item.amount);

        return Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: statistics.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final stat = statistics[index];
              final percentage = (stat.amount / total * 100);

              return ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _parseColor(stat.categoryColor).withAlpha(51),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: stat.categoryIcon.isEmpty
                        ? Text(
                            '-',
                            style: TextStyle(
                              fontSize: 20,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          )
                        : Text(
                            stat.categoryIcon,
                            style: const TextStyle(fontSize: 20),
                          ),
                  ),
                ),
                title: Text(stat.categoryName),
                subtitle: LinearProgressIndicator(
                  value: percentage / 100,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation(
                    _parseColor(stat.categoryColor),
                  ),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${numberFormat.format(stat.amount)}원',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, st) => const SizedBox.shrink(),
    );
  }

  Color _parseColor(String hexColor) {
    try {
      final hex = hexColor.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return Colors.grey;
    }
  }
}

// 월별 추세 차트
class _MonthlyTrendChart extends ConsumerWidget {
  const _MonthlyTrendChart();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendAsync = ref.watch(monthlyTrendProvider);

    return trendAsync.when(
      data: (trend) {
        if (trend.isEmpty) {
          return Card(
            child: SizedBox(
              height: 200,
              child: Center(
                child: Text(
                  '데이터가 없습니다',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            ),
          );
        }

        final maxY = trend
            .map((e) => e.income > e.expense ? e.income : e.expense)
            .reduce((a, b) => a > b ? a : b)
            .toDouble();

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY * 1.2,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final stat = trend[groupIndex];
                        final label = rodIndex == 0 ? '수입' : '지출';
                        final amount = rodIndex == 0 ? stat.income : stat.expense;
                        return BarTooltipItem(
                          '$label: ${NumberFormat('#,###').format(amount)}원',
                          const TextStyle(color: Colors.white),
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
                          if (value.toInt() >= trend.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              trend[value.toInt()].monthLabel,
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        },
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
                  borderData: FlBorderData(show: false),
                  barGroups: trend.asMap().entries.map((entry) {
                    final index = entry.key;
                    final stat = entry.value;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: stat.income.toDouble(),
                          color: Colors.blue,
                          width: 12,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                        BarChartRodData(
                          toY: stat.expense.toDouble(),
                          color: Colors.red,
                          width: 12,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const Card(
        child: SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, st) => Card(
        child: SizedBox(
          height: 200,
          child: Center(child: Text('오류: $e')),
        ),
      ),
    );
  }
}

// 일별 추세 차트
class _DailyTrendChart extends ConsumerWidget {
  const _DailyTrendChart();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendAsync = ref.watch(dailyTrendProvider);
    final selectedType = ref.watch(selectedStatisticsTypeProvider);

    return trendAsync.when(
      data: (trend) {
        if (trend.isEmpty) {
          return Card(
            child: SizedBox(
              height: 200,
              child: Center(
                child: Text(
                  '데이터가 없습니다',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            ),
          );
        }

        final values = trend
            .map((e) => selectedType == 'income' ? e.income : e.expense)
            .toList();
        final maxY = values.reduce((a, b) => a > b ? a : b).toDouble();

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxY > 0 ? maxY / 4 : 1,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.shade300,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 7,
                        getTitlesWidget: (value, meta) {
                          final day = value.toInt();
                          if (day == 1 || day == 8 || day == 15 || day == 22 || day == 29) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                '$day일',
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
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
                  borderData: FlBorderData(show: false),
                  minX: 1,
                  maxX: trend.length.toDouble(),
                  minY: 0,
                  maxY: maxY > 0 ? maxY * 1.2 : 100,
                  lineBarsData: [
                    LineChartBarData(
                      spots: trend.map((stat) {
                        final value = selectedType == 'income'
                            ? stat.income
                            : stat.expense;
                        return FlSpot(stat.day.toDouble(), value.toDouble());
                      }).toList(),
                      isCurved: true,
                      color: selectedType == 'income' ? Colors.blue : Colors.red,
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: (selectedType == 'income' ? Colors.blue : Colors.red)
                            .withAlpha(26),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (spots) {
                        return spots.map((spot) {
                          return LineTooltipItem(
                            '${spot.x.toInt()}일: ${NumberFormat('#,###').format(spot.y.toInt())}원',
                            const TextStyle(color: Colors.white),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const Card(
        child: SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, st) => Card(
        child: SizedBox(
          height: 200,
          child: Center(child: Text('오류: $e')),
        ),
      ),
    );
  }
}
