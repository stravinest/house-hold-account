import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/utils/number_format_utils.dart';
import '../../../../../l10n/generated/app_localizations.dart';
import '../../../../../shared/widgets/skeleton_loading.dart';
import '../../../domain/entities/statistics_entities.dart';
import '../../providers/statistics_provider.dart';

class PaymentMethodList extends ConsumerWidget {
  const PaymentMethodList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final statisticsAsync = ref.watch(paymentMethodStatisticsProvider);

    return statisticsAsync.when(
      data: (statistics) {
        if (statistics.isEmpty) {
          return const SizedBox.shrink();
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: statistics.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final item = statistics[index];
            return _PaymentMethodItem(rank: index + 1, item: item, l10n: l10n);
          },
        );
      },
      loading: () => const _SkeletonPaymentMethodList(),
      error: (error, _) =>
          Center(child: Text(l10n.errorWithMessage(error.toString()))),
    );
  }
}

class _PaymentMethodItem extends StatelessWidget {
  final int rank;
  final PaymentMethodStatistics item;
  final AppLocalizations l10n;

  const _PaymentMethodItem({
    required this.rank,
    required this.item,
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
    final color = _parseColor(item.paymentMethodColor);

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
              // 결제수단명 + 뱃지
              Expanded(
                child: Row(
                  children: [
                    // 결제수단명
                    Flexible(
                      child: Text(
                        item.paymentMethodName,
                        style: theme.textTheme.bodyLarge,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    // 뱃지
                    _PaymentMethodBadge(
                      canAutoSave: item.canAutoSave,
                      l10n: l10n,
                    ),
                  ],
                ),
              ),
              // 비율
              Text(
                '${item.percentage.toStringAsFixed(1)}%',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 12),
              // 금액
              Text(
                '${NumberFormatUtils.currency.format(item.amount)}${l10n.transactionAmountUnit}',
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
              value: item.percentage / 100,
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

/// 결제수단 리스트 스켈레톤 로딩
class _SkeletonPaymentMethodList extends StatelessWidget {
  const _SkeletonPaymentMethodList();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 5,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) => const _SkeletonPaymentMethodItem(),
    );
  }
}

/// 결제수단 아이템 스켈레톤
class _SkeletonPaymentMethodItem extends StatelessWidget {
  const _SkeletonPaymentMethodItem();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              // 순위
              const SizedBox(
                width: 24,
                child: SkeletonLine(width: 16, height: 20),
              ),
              const SizedBox(width: 12),
              // 결제수단명
              Expanded(
                child: SkeletonLine(
                  width: MediaQuery.of(context).size.width * 0.3,
                  height: 16,
                ),
              ),
              // 비율
              SkeletonLine(
                width: MediaQuery.of(context).size.width * 0.15,
                height: 14,
              ),
              const SizedBox(width: 12),
              // 금액
              SkeletonLine(
                width: MediaQuery.of(context).size.width * 0.2,
                height: 16,
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 진행 바
          const SkeletonBox(width: double.infinity, height: 6, borderRadius: 4),
        ],
      ),
    );
  }
}

/// 결제수단 유형 뱃지 (자동수집 / 공유)
class _PaymentMethodBadge extends StatelessWidget {
  final bool canAutoSave;
  final AppLocalizations l10n;

  const _PaymentMethodBadge({required this.canAutoSave, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 뱃지 색상 및 텍스트 결정
    final badgeColor = canAutoSave
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerHighest;

    final textColor = canAutoSave
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurfaceVariant;

    final badgeText = canAutoSave
        ? l10n.statisticsPaymentMethodAutoSave
        : l10n.statisticsPaymentMethodShared;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        badgeText,
        style: theme.textTheme.labelSmall?.copyWith(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
