import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/utils/category_l10n_helper.dart';
import '../../../../../core/utils/number_format_utils.dart';
import '../../../../../l10n/generated/app_localizations.dart';
import '../../../data/repositories/statistics_repository.dart';
import '../../providers/statistics_provider.dart';
import 'category_donut_chart.dart';

/// 카테고리 분포 카드 - Pencil Nzqas 디자인 적용
class CategoryDistributionCard extends ConsumerWidget {
  const CategoryDistributionCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final statisticsAsync = ref.watch(categoryStatisticsProvider);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Text(
            l10n.statisticsCategoryDistribution,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
          ),
          const SizedBox(height: 16),

          // 도넛 차트
          const CategoryDonutChart(),
          const SizedBox(height: 16),

          // 범례 리스트 - Pencil legend 디자인
          statisticsAsync.when(
            data: (statistics) {
              if (statistics.isEmpty) {
                return const SizedBox.shrink();
              }
              return _CategoryLegendList(statistics: statistics);
            },
            loading: () => const SizedBox.shrink(),
            error: (error, stack) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

/// 카테고리 범례 리스트 - Pencil legend 디자인
class _CategoryLegendList extends StatelessWidget {
  final List<CategoryStatistics> statistics;

  const _CategoryLegendList({required this.statistics});

  Color _parseColor(String colorString) {
    try {
      final colorValue = int.parse(colorString.replaceFirst('#', '0xFF'));
      return Color(colorValue);
    } catch (e) {
      return const Color(0xFF9E9E9E);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final numberFormat = NumberFormatUtils.currency;

    final totalAmount = statistics.fold(0, (sum, item) => sum + item.amount);

    // 상위 5개만 표시
    final displayStats = statistics.take(5).toList();

    return Column(
      children: displayStats.map((item) {
        final percentage = totalAmount > 0
            ? (item.amount / totalAmount) * 100
            : 0.0;
        final color = _parseColor(item.categoryColor);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              // 색상 원
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 12),
              // 카테고리명
              Text(
                CategoryL10nHelper.translate(item.categoryName, l10n),
                style: const TextStyle(fontSize: 14),
              ),
              // Spacer
              const Spacer(),
              // 퍼센트
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 12),
              // 금액
              Text(
                '${numberFormat.format(item.amount)}${l10n.transactionAmountUnit}',
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
