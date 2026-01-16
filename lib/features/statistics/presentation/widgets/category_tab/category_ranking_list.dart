import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/utils/category_l10n_helper.dart';
import '../../../../../core/utils/number_format_utils.dart';
import '../../../../../l10n/generated/app_localizations.dart';
import '../../../../../shared/widgets/skeleton_loading.dart';
import '../../../data/repositories/statistics_repository.dart';
import '../../providers/statistics_provider.dart';

class CategoryRankingList extends ConsumerWidget {
  const CategoryRankingList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final statisticsAsync = ref.watch(categoryStatisticsProvider);

    return statisticsAsync.when(
      data: (statistics) {
        if (statistics.isEmpty) {
          return const SizedBox.shrink();
        }

        final totalAmount = statistics.fold(
          0,
          (sum, item) => sum + item.amount,
        );

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: statistics.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final item = statistics[index];
            final percentage = totalAmount > 0
                ? (item.amount / totalAmount) * 100
                : 0.0;

            return _CategoryRankingItem(
              rank: index + 1,
              category: item,
              percentage: percentage,
              totalAmount: totalAmount,
              numberFormat: NumberFormatUtils.currency,
              l10n: l10n,
            );
          },
        );
      },
      loading: () => ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 5,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) => const _CategoryRankingSkeleton(),
      ),
      error: (error, _) =>
          Center(child: Text(l10n.errorWithMessage(error.toString()))),
    );
  }
}

class _CategoryRankingItem extends StatelessWidget {
  final int rank;
  final CategoryStatistics category;
  final double percentage;
  final int totalAmount;
  final NumberFormat numberFormat;
  final AppLocalizations l10n;

  const _CategoryRankingItem({
    required this.rank,
    required this.category,
    required this.percentage,
    required this.totalAmount,
    required this.numberFormat,
    required this.l10n,
  });

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
    final theme = Theme.of(context);
    final color = _parseColor(category.categoryColor);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              // 순위
              SizedBox(
                width: 24,
                child: Text(
                  '$rank',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: rank <= 3
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // 카테고리명
              Expanded(
                child: Text(
                  CategoryL10nHelper.translate(category.categoryName, l10n),
                  style: theme.textTheme.bodyLarge,
                ),
              ),
              // 비율
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 12),
              // 금액
              Text(
                '${numberFormat.format(category.amount)}${l10n.transactionAmountUnit}',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 진행 바
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

/// 카테고리 랭킹 아이템 스켈레톤
///
/// 카테고리 랭킹 리스트의 로딩 상태를 표현합니다.
class _CategoryRankingSkeleton extends StatelessWidget {
  const _CategoryRankingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              // 순위 스켈레톤
              const SizedBox(
                width: 24,
                child: SkeletonLine(width: 20, height: 16),
              ),
              const SizedBox(width: 12),
              // 카테고리명 스켈레톤
              Expanded(
                child: SkeletonLine(
                  width: MediaQuery.of(context).size.width * 0.3,
                  height: 16,
                ),
              ),
              // 비율 스켈레톤
              SkeletonLine(
                width: MediaQuery.of(context).size.width * 0.12,
                height: 14,
              ),
              const SizedBox(width: 12),
              // 금액 스켈레톤
              SkeletonLine(
                width: MediaQuery.of(context).size.width * 0.2,
                height: 16,
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 진행 바 스켈레톤
          const SkeletonBox(width: double.infinity, height: 6, borderRadius: 4),
        ],
      ),
    );
  }
}
