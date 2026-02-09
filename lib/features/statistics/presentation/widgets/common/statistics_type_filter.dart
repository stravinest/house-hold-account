import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../l10n/generated/app_localizations.dart';
import '../../providers/statistics_provider.dart';

/// 통계 타입 드롭다운 (수입/지출/자산) - Pencil gd8Cl 디자인 적용
class StatisticsTypeFilter extends ConsumerWidget {
  const StatisticsTypeFilter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final selectedType = ref.watch(selectedStatisticsTypeProvider);

    final typeConfig = _getTypeConfig(selectedType, l10n, colorScheme);

    return PopupMenuButton<String>(
      onSelected: (value) {
        ref.read(selectedStatisticsTypeProvider.notifier).state = value;
      },
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: colorScheme.surfaceContainer,
      itemBuilder: (context) {
        final types = [
          ('expense', l10n.statisticsTypeExpense, Icons.account_balance_wallet_outlined),
          ('income', l10n.statisticsTypeIncome, Icons.trending_up),
          ('asset', l10n.statisticsTypeAsset, Icons.account_balance_outlined),
        ];

        return types.map((type) {
          final isSelected = selectedType == type.$1;
          final itemColor = _getIconColor(type.$1, colorScheme);

          return PopupMenuItem<String>(
            value: type.$1,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(type.$3, size: 16, color: itemColor),
                const SizedBox(width: 8),
                Text(
                  type.$2,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          );
        }).toList();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(typeConfig.icon, size: 16, color: typeConfig.color),
            const SizedBox(width: 6),
            Text(
              typeConfig.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: typeConfig.color,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.keyboard_arrow_down,
              size: 14,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Color _getIconColor(String type, ColorScheme colorScheme) {
    switch (type) {
      case 'income':
        return colorScheme.primary;
      case 'expense':
        return colorScheme.primary;
      case 'asset':
        return const Color(0xFF006A6A);
      default:
        return colorScheme.primary;
    }
  }

  _TypeConfig _getTypeConfig(
    String type,
    AppLocalizations l10n,
    ColorScheme colorScheme,
  ) {
    switch (type) {
      case 'income':
        return _TypeConfig(
          label: l10n.statisticsTypeIncome,
          icon: Icons.trending_up,
          color: colorScheme.primary,
        );
      case 'asset':
        return _TypeConfig(
          label: l10n.statisticsTypeAsset,
          icon: Icons.account_balance_outlined,
          color: const Color(0xFF006A6A),
        );
      case 'expense':
      default:
        return _TypeConfig(
          label: l10n.statisticsTypeExpense,
          icon: Icons.account_balance_wallet_outlined,
          color: colorScheme.primary,
        );
    }
  }
}

class _TypeConfig {
  final String label;
  final IconData icon;
  final Color color;

  const _TypeConfig({
    required this.label,
    required this.icon,
    required this.color,
  });
}
