import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/category_l10n_helper.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/asset_statistics.dart';

class AssetCategoryList extends StatelessWidget {
  final AssetStatistics assetStatistics;

  const AssetCategoryList({super.key, required this.assetStatistics});

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
    final numberFormat = NumberFormat('#,###');

    final byCategory = assetStatistics.byCategory;
    if (byCategory.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text(
            l10n.assetNoAsset,
            style: theme.textTheme.bodyLarge.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    // 금액 기준 내림차순 정렬
    final sortedCategories = List<CategoryAsset>.from(byCategory)
      ..sort((a, b) => b.amount.compareTo(a.amount));

    final totalAmount = assetStatistics.totalAmount.toDouble();

    return Column(
      children: sortedCategories.asMap().entries.map((entry) {
        final rank = entry.key + 1;
        final category = entry.value;
        final percentage = totalAmount > 0
            ? (category.amount / totalAmount) * 100
            : 0.0;
        final categoryColor = _parseColor(category.categoryColor);

        return ExpansionTile(
          initiallyExpanded: false,
          title: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                Row(
                  children: [
                    // 순위
                    SizedBox(
                      width: 24,
                      child: Text(
                        '$rank',
                        style: theme.textTheme.titleMedium.copyWith(
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
                        CategoryL10nHelper.translate(
                          category.categoryName,
                          l10n,
                        ),
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                    // 백분율
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: theme.textTheme.bodyMedium.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 금액
                    Text(
                      '${numberFormat.format(category.amount)}${l10n.transactionAmountUnit}',
                      style: theme.textTheme.bodyLarge.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(categoryColor),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          children: category.items.map((item) {
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 4,
              ),
              title: Text(item.title),
              trailing: Text(
                '${numberFormat.format(item.amount)}${l10n.transactionAmountUnit}',
                style: theme.textTheme.bodyMedium,
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }
}
