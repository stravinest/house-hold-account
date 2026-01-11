import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/repositories/statistics_repository.dart';
import '../../providers/statistics_provider.dart';

class CategoryDonutChart extends ConsumerWidget {
  const CategoryDonutChart({super.key});

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
    final statisticsAsync = ref.watch(categoryStatisticsProvider);
    final selectedType = ref.watch(selectedStatisticsTypeProvider);
    final numberFormat = NumberFormat('#,###');

    return statisticsAsync.when(
      data: (statistics) {
        if (statistics.isEmpty) {
          return _buildEmptyState(context);
        }
        return _buildChart(context, statistics, selectedType, numberFormat);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
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
    List<CategoryStatistics> statistics,
    String selectedType,
    NumberFormat numberFormat,
  ) {
    // 상위 5개 + 기타 처리
    final processedData = _processData(statistics);
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
              sections: _buildSections(processedData, totalAmount),
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {},
              ),
            ),
          ),
          // 중앙 총금액 표시
          _buildCenterText(context, totalAmount, selectedType, numberFormat),
        ],
      ),
    );
  }

  List<CategoryStatistics> _processData(List<CategoryStatistics> statistics) {
    if (statistics.length <= 5) {
      return statistics;
    }

    // 상위 5개
    final top5 = statistics.take(5).toList();

    // 나머지를 '기타'로 합침
    final others = statistics.skip(5).toList();
    final othersTotal = others.fold(0, (sum, item) => sum + item.amount);

    if (othersTotal > 0) {
      top5.add(CategoryStatistics(
        categoryId: '_others_',
        categoryName: '기타',
        categoryIcon: '',
        categoryColor: '#9E9E9E',
        amount: othersTotal,
      ));
    }

    return top5;
  }

  List<PieChartSectionData> _buildSections(
    List<CategoryStatistics> data,
    int totalAmount,
  ) {
    return data.map((item) {
      final percentage = totalAmount > 0 ? (item.amount / totalAmount) * 100 : 0.0;
      final color = _parseColor(item.categoryColor);

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
    String selectedType,
    NumberFormat numberFormat,
  ) {
    final theme = Theme.of(context);
    final typeLabel = _getTypeLabel(selectedType);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          typeLabel,
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

  String _getTypeLabel(String type) {
    switch (type) {
      case 'income':
        return '총 수입';
      case 'saving':
        return '총 저축';
      default:
        return '총 지출';
    }
  }
}
