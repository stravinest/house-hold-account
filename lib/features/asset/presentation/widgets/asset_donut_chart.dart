import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/number_format_utils.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/asset_statistics.dart';

class AssetDonutChart extends StatelessWidget {
  final List<CategoryAsset> byCategory;

  const AssetDonutChart({super.key, required this.byCategory});

  Color _parseColor(String? colorString) {
    if (colorString == null) return const Color(0xFF9E9E9E);
    try {
      final colorValue = int.parse(colorString.replaceFirst('#', '0xFF'));
      return Color(colorValue);
    } catch (e) {
      return const Color(0xFF9E9E9E);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (byCategory.isEmpty) {
      return SizedBox(
        height: 250,
        child: Center(
          child: Text(
            l10n.assetNoData,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final processedData = _processData(l10n);
    final totalAmount = byCategory.fold(0, (sum, item) => sum + item.amount);

    return SizedBox(
      height: 250,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 60,
              sections: _buildSections(processedData, totalAmount, theme),
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {},
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.assetTotal,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${NumberFormatUtils.currency.format(totalAmount)}${l10n.transactionAmountUnit}',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<CategoryAsset> _processData(AppLocalizations l10n) {
    if (byCategory.length <= 5) {
      return byCategory;
    }

    final top5 = byCategory.take(5).toList();

    final others = byCategory.skip(5).toList();
    final othersTotal = others.fold(0, (sum, item) => sum + item.amount);

    if (othersTotal > 0) {
      top5.add(
        CategoryAsset(
          categoryId: '_others_',
          categoryName: l10n.assetOther,
          categoryIcon: null,
          categoryColor: '#9E9E9E',
          amount: othersTotal,
          items: [],
        ),
      );
    }

    return top5;
  }

  List<PieChartSectionData> _buildSections(
    List<CategoryAsset> data,
    int totalAmount,
    ThemeData theme,
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
}
