import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../l10n/generated/app_localizations.dart';
import '../../../data/repositories/statistics_repository.dart';
import '../../providers/statistics_provider.dart';

class CategoryDonutChart extends ConsumerWidget {
  const CategoryDonutChart({super.key});

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
    final l10n = AppLocalizations.of(context)!;
    final statisticsAsync = ref.watch(categoryStatisticsProvider);
    final selectedType = ref.watch(selectedStatisticsTypeProvider);
    final numberFormat = NumberFormat('#,###');

    return statisticsAsync.when(
      data: (statistics) {
        if (statistics.isEmpty) {
          return _buildEmptyState(context, l10n);
        }
        return _buildChart(
          context,
          l10n,
          statistics,
          selectedType,
          numberFormat,
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
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
    List<CategoryStatistics> statistics,
    String selectedType,
    NumberFormat numberFormat,
  ) {
    // 상위 5개 + 기타 처리
    final processedData = _processData(l10n, statistics);
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
          _buildCenterText(
            context,
            l10n,
            totalAmount,
            selectedType,
            numberFormat,
          ),
        ],
      ),
    );
  }

  List<CategoryStatistics> _processData(
    AppLocalizations l10n,
    List<CategoryStatistics> statistics,
  ) {
    if (statistics.length <= 5) {
      return statistics;
    }

    // 상위 5개
    final top5 = statistics.take(5).toList();

    // 나머지를 '기타'로 합침
    final others = statistics.skip(5).toList();
    final othersTotal = others.fold(0, (sum, item) => sum + item.amount);

    if (othersTotal > 0) {
      top5.add(
        CategoryStatistics(
          categoryId: '_others_',
          categoryName: l10n.statisticsOther,
          categoryIcon: '',
          categoryColor: '#9E9E9E',
          amount: othersTotal,
        ),
      );
    }

    return top5;
  }

  List<PieChartSectionData> _buildSections(
    List<CategoryStatistics> data,
    int totalAmount,
  ) {
    return data.map((item) {
      final percentage = totalAmount > 0
          ? (item.amount / totalAmount) * 100
          : 0.0;
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
    AppLocalizations l10n,
    int totalAmount,
    String selectedType,
    NumberFormat numberFormat,
  ) {
    final theme = Theme.of(context);
    final typeLabel = _getTypeLabel(l10n, selectedType);

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
          '${numberFormat.format(totalAmount)}${l10n.transactionAmountUnit}',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _getTypeLabel(AppLocalizations l10n, String type) {
    switch (type) {
      case 'income':
        return l10n.statisticsTotalIncome;
      case 'asset':
        return l10n.statisticsTotalAsset;
      default:
        return l10n.statisticsTotalExpense;
    }
  }
}
