import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/asset_statistics.dart';

class AssetCategoryList extends StatelessWidget {
  final List<CategoryAsset> byCategory;

  const AssetCategoryList({super.key, required this.byCategory});

  String? _getDateInfo(AssetItem item) {
    if (item.maturityDate == null) {
      return null;
    }
    final daysLeft = item.maturityDate!.difference(DateTime.now()).inDays;
    if (daysLeft < 0) {
      return '만기 ${daysLeft.abs()}일 지남';
    } else if (daysLeft == 0) {
      return '오늘 만기';
    } else {
      return '만기 ${daysLeft}일 남음';
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
                  Expanded(
                    child: Text(
                      category.categoryName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    '${numberFormat.format(category.amount)} 원',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            ...category.items.map((item) {
              final dateInfo = _getDateInfo(item);
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 4,
                ),
                title: Text(item.title),
                subtitle: dateInfo != null
                    ? Text(
                        dateInfo,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      )
                    : null,
                trailing: Text(
                  '${numberFormat.format(item.amount)} 원',
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
