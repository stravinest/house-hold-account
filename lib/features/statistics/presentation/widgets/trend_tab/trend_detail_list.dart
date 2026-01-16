import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../l10n/generated/app_localizations.dart';
import '../../../../../shared/themes/design_tokens.dart';
import '../../../../../shared/widgets/skeleton_loading.dart';
import '../../../data/repositories/statistics_repository.dart';
import '../../../domain/entities/statistics_entities.dart';
import '../../providers/statistics_provider.dart';

class TrendDetailList extends ConsumerWidget {
  const TrendDetailList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(trendPeriodProvider);

    if (period == TrendPeriod.monthly) {
      return const _MonthlyDetailList();
    } else {
      return const _YearlyDetailList();
    }
  }
}

class _MonthlyDetailList extends ConsumerWidget {
  const _MonthlyDetailList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final trendAsync = ref.watch(monthlyTrendWithAverageProvider);
    final selectedType = ref.watch(selectedStatisticsTypeProvider);
    final numberFormat = NumberFormat('#,###');

    return trendAsync.when(
      data: (trendData) {
        final data = trendData.data.cast<MonthlyStatistics>();
        if (data.isEmpty) {
          return const SizedBox.shrink();
        }

        // 역순으로 표시 (최신 월이 위로)
        final reversedData = data.reversed.toList();

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: reversedData.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final item = reversedData[index];
            final previousItem = index < reversedData.length - 1
                ? reversedData[index + 1]
                : null;

            return _TrendDetailItem(
              label: l10n.statisticsYearMonth(item.year, item.month),
              amount: _getValueByType(item, selectedType),
              previousAmount: previousItem != null
                  ? _getValueByType(previousItem, selectedType)
                  : null,
              type: selectedType,
              numberFormat: numberFormat,
              l10n: l10n,
            );
          },
        );
      },
      loading: () => const _SkeletonTrendDetailList(),
      error: (error, _) =>
          Center(child: Text(l10n.errorWithMessage(error.toString()))),
    );
  }

  int _getValueByType(MonthlyStatistics item, String type) {
    switch (type) {
      case 'income':
        return item.income;
      case 'asset':
        return item.saving;
      default:
        return item.expense;
    }
  }
}

class _YearlyDetailList extends ConsumerWidget {
  const _YearlyDetailList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final trendAsync = ref.watch(yearlyTrendWithAverageProvider);
    final selectedType = ref.watch(selectedStatisticsTypeProvider);
    final numberFormat = NumberFormat('#,###');

    return trendAsync.when(
      data: (trendData) {
        final data = trendData.data.cast<YearlyStatistics>();
        if (data.isEmpty) {
          return const SizedBox.shrink();
        }

        // 역순으로 표시 (최신 연도가 위로)
        final reversedData = data.reversed.toList();

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: reversedData.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final item = reversedData[index];
            final previousItem = index < reversedData.length - 1
                ? reversedData[index + 1]
                : null;

            return _TrendDetailItem(
              label: l10n.statisticsYear(item.year),
              amount: _getValueByType(item, selectedType),
              previousAmount: previousItem != null
                  ? _getValueByType(previousItem, selectedType)
                  : null,
              type: selectedType,
              numberFormat: numberFormat,
              l10n: l10n,
            );
          },
        );
      },
      loading: () => const _SkeletonTrendDetailList(),
      error: (error, _) =>
          Center(child: Text(l10n.errorWithMessage(error.toString()))),
    );
  }

  int _getValueByType(YearlyStatistics item, String type) {
    switch (type) {
      case 'income':
        return item.income;
      case 'asset':
        return item.saving;
      default:
        return item.expense;
    }
  }
}

class _TrendDetailItem extends StatelessWidget {
  final String label;
  final int amount;
  final int? previousAmount;
  final String type;
  final NumberFormat numberFormat;
  final AppLocalizations l10n;

  const _TrendDetailItem({
    required this.label,
    required this.amount,
    this.previousAmount,
    required this.type,
    required this.numberFormat,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Row(
        children: [
          // 기간 라벨
          Expanded(
            flex: 2,
            child: Text(label, style: theme.textTheme.bodyLarge),
          ),
          // 금액
          Expanded(
            flex: 2,
            child: Text(
              '${numberFormat.format(amount)}${l10n.transactionAmountUnit}',
              style: theme.textTheme.bodyLarge.copyWith(
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.end,
            ),
          ),
          const SizedBox(width: 12),
          // 전월/전년 대비
          Expanded(flex: 2, child: _buildComparison(context)),
        ],
      ),
    );
  }

  Widget _buildComparison(BuildContext context) {
    final theme = Theme.of(context);

    if (previousAmount == null) {
      return Text(
        '-',
        style: theme.textTheme.bodyMedium.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
        textAlign: TextAlign.end,
      );
    }

    final colorScheme = Theme.of(context).colorScheme;
    final difference = amount - previousAmount!;
    final isIncrease = difference > 0;
    final isDecrease = difference < 0;
    final arrow = isIncrease
        ? Icons.arrow_upward
        : (isDecrease ? Icons.arrow_downward : Icons.remove);
    final color = isIncrease
        ? colorScheme.error
        : (isDecrease ? colorScheme.primary : colorScheme.onSurfaceVariant);

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Icon(arrow, size: 14, color: color),
        const SizedBox(width: 2),
        Text(
          '${numberFormat.format(difference.abs())}${l10n.transactionAmountUnit}',
          style: theme.textTheme.bodySmall.copyWith(color: color),
        ),
      ],
    );
  }
}

/// 트렌드 상세 리스트 스켈레톤 로딩
class _SkeletonTrendDetailList extends StatelessWidget {
  const _SkeletonTrendDetailList();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 5,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) => const _SkeletonTrendDetailItem(),
    );
  }
}

/// 트렌드 상세 아이템 스켈레톤
class _SkeletonTrendDetailItem extends StatelessWidget {
  const _SkeletonTrendDetailItem();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Row(
        children: [
          // 기간 라벨
          Expanded(
            flex: 2,
            child: SkeletonLine(
              width: MediaQuery.of(context).size.width * 0.2,
              height: 16,
            ),
          ),
          // 금액
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: SkeletonLine(
                width: MediaQuery.of(context).size.width * 0.25,
                height: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 전월/전년 대비
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: SkeletonLine(
                width: MediaQuery.of(context).size.width * 0.2,
                height: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
