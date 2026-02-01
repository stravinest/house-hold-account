import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/utils/number_format_utils.dart';
import '../../../../../l10n/generated/app_localizations.dart';
import '../../../data/repositories/statistics_repository.dart';
import '../../providers/statistics_provider.dart';

/// 사용자별 비율을 보여주는 비교 바 위젯
/// 총 지출과 함께 각 사용자의 비중을 시각화
class UserRatioBar extends ConsumerWidget {
  const UserRatioBar({super.key});

  Color _parseColor(String? colorString) {
    if (colorString == null) return const Color(0xFF4CAF50);
    try {
      final colorValue = int.parse(colorString.replaceFirst('#', '0xFF'));
      return Color(colorValue);
    } catch (e) {
      return const Color(0xFF4CAF50);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final userStatsAsync = ref.watch(categoryStatisticsByUserProvider);
    final selectedType = ref.watch(selectedStatisticsTypeProvider);

    return userStatsAsync.when(
      data: (userStats) {
        if (userStats.isEmpty) {
          return const SizedBox.shrink();
        }

        final totalAmount = userStats.values.fold(
          0,
          (sum, user) => sum + user.totalAmount,
        );

        if (totalAmount == 0) {
          return const SizedBox.shrink();
        }

        final users = userStats.values.toList()
          ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 총액 표시
                Text(
                  _getTotalLabel(l10n, selectedType),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${NumberFormatUtils.currency.format(totalAmount)}${l10n.transactionAmountUnit}',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _getTypeColor(selectedType, theme),
                  ),
                ),
                const SizedBox(height: 16),

                // 비율 바
                _buildRatioBar(context, users, totalAmount),
                const SizedBox(height: 12),

                // 사용자별 상세 정보
                ...users.map(
                  (user) => _buildUserRow(context, l10n, user, totalAmount),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(child: Text(l10n.errorWithMessage(error.toString()))),
        ),
      ),
    );
  }

  String _getTotalLabel(AppLocalizations l10n, String type) {
    switch (type) {
      case 'income':
        return l10n.statisticsTotalIncome;
      case 'asset':
        return l10n.statisticsTotalAsset;
      default:
        return l10n.statisticsTotalExpense;
    }
  }

  Color _getTypeColor(String type, ThemeData theme) {
    switch (type) {
      case 'income':
        return theme.colorScheme.primary;
      case 'asset':
        return theme.colorScheme.tertiary;
      default:
        return theme.colorScheme.error;
    }
  }

  Widget _buildRatioBar(
    BuildContext context,
    List<UserCategoryStatistics> users,
    int totalAmount,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 24,
        child: Row(
          children: users.map((user) {
            final ratio = totalAmount > 0
                ? user.totalAmount / totalAmount
                : 0.0;
            final color = _parseColor(user.userColor);

            return Expanded(
              flex: (ratio * 1000).round().clamp(1, 1000),
              child: Container(
                color: color,
                alignment: Alignment.center,
                child: ratio >= 0.1
                    ? Text(
                        '${(ratio * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildUserRow(
    BuildContext context,
    AppLocalizations l10n,
    UserCategoryStatistics user,
    int totalAmount,
  ) {
    final theme = Theme.of(context);
    final color = _parseColor(user.userColor);
    final ratio = totalAmount > 0
        ? (user.totalAmount / totalAmount * 100)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          // 색상 표시
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          // 사용자명
          Expanded(
            child: Text(
              user.userName,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          // 금액 및 비율
          Text(
            '${NumberFormatUtils.currency.format(user.totalAmount)}${l10n.transactionAmountUnit}',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '(${ratio.toStringAsFixed(1)}%)',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
