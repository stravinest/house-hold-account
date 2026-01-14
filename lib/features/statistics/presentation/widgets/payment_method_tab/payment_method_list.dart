import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../domain/entities/statistics_entities.dart';
import '../../providers/statistics_provider.dart';

class PaymentMethodList extends ConsumerWidget {
  const PaymentMethodList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statisticsAsync = ref.watch(paymentMethodStatisticsProvider);
    final numberFormat = NumberFormat('#,###');

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
            return _PaymentMethodItem(
              rank: index + 1,
              item: item,
              numberFormat: numberFormat,
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('오류: $error')),
    );
  }
}

class _PaymentMethodItem extends StatelessWidget {
  final int rank;
  final PaymentMethodStatistics item;
  final NumberFormat numberFormat;

  const _PaymentMethodItem({
    required this.rank,
    required this.item,
    required this.numberFormat,
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
              // 결제수단명
              Expanded(
                child: Text(
                  item.paymentMethodName,
                  style: theme.textTheme.bodyLarge,
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
                '${numberFormat.format(item.amount)}원',
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
