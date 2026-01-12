import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/asset_statistics.dart';

class AssetCategoryList extends StatelessWidget {
  final List<CategoryAsset> byCategory;

  const AssetCategoryList({super.key, required this.byCategory});

  Color _parseColor(String? colorString) {
    if (colorString == null) return Colors.grey;
    try {
      final colorValue = int.parse(colorString.replaceFirst('#', '0xFF'));
      return Color(colorValue);
    } catch (e) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final numberFormat = NumberFormat('#,###');

    if (byCategory.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text(
            '자산이 없습니다',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: byCategory.map((category) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _parseColor(category.categoryColor),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    category.categoryName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${numberFormat.format(category.amount)}원',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            ...category.items.map((item) {
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 4,
                ),
                title: Text(item.title),
                subtitle: item.maturityDate != null
                    ? Text(
                        '만기: ${DateFormat('yyyy.MM').format(item.maturityDate!)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      )
                    : null,
                trailing: Text(
                  '${numberFormat.format(item.amount)}원',
                  style: theme.textTheme.bodyMedium,
                ),
              );
            }),
            const Divider(height: 1),
          ],
        );
      }).toList(),
    );
  }
}
