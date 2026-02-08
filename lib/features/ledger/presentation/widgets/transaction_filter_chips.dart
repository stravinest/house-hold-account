import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/themes/design_tokens.dart';
import '../providers/monthly_list_view_provider.dart';

/// 거래 필터 드롭다운 위젯
///
/// 활성 필터를 배지로 표시하고, 필터 버튼으로 필터를 추가/변경합니다.
/// - 활성 필터: 녹색 필 배지 + X 아이콘으로 제거
/// - 필터 버튼: 드롭다운 메뉴로 필터 선택
/// - '전체' 선택 시 다른 필터 자동 해제
/// - 모든 필터 해제 시 '전체'로 자동 복귀
class TransactionFilterChips extends ConsumerWidget {
  const TransactionFilterChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final selectedFilters = ref.watch(selectedFiltersProvider);

    // 필터 라벨 매핑
    String getFilterLabel(TransactionFilter filter) {
      switch (filter) {
        case TransactionFilter.all:
          return l10n.filterAll;
        case TransactionFilter.recurring:
          return l10n.filterRecurring;
        case TransactionFilter.income:
          return l10n.filterIncome;
        case TransactionFilter.expense:
          return l10n.filterExpense;
        case TransactionFilter.asset:
          return l10n.filterAsset;
      }
    }

    // 필터 토글 핸들러
    void toggleFilter(TransactionFilter filter) {
      final currentFilters = Set<TransactionFilter>.from(selectedFilters);

      if (filter == TransactionFilter.all) {
        ref.read(selectedFiltersProvider.notifier).state = {
          TransactionFilter.all,
        };
        return;
      }

      if (currentFilters.contains(filter)) {
        currentFilters.remove(filter);
        currentFilters.remove(TransactionFilter.all);
        if (currentFilters.isEmpty) {
          currentFilters.add(TransactionFilter.all);
        }
      } else {
        currentFilters.add(filter);
        currentFilters.remove(TransactionFilter.all);
      }

      ref.read(selectedFiltersProvider.notifier).state = currentFilters;
    }

    // 배지에서 X 클릭 시 제거
    void removeBadge(TransactionFilter filter) {
      if (filter == TransactionFilter.all) return;
      final currentFilters = Set<TransactionFilter>.from(selectedFilters);
      currentFilters.remove(filter);
      if (currentFilters.isEmpty) {
        currentFilters.add(TransactionFilter.all);
      }
      ref.read(selectedFiltersProvider.notifier).state = currentFilters;
    }

    // 활성 배지 위젯
    Widget buildActiveBadge(TransactionFilter filter) {
      final isAll = filter == TransactionFilter.all;
      return GestureDetector(
        onTap: isAll ? null : () => removeBadge(filter),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                getFilterLabel(filter),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onPrimary,
                ),
              ),
              if (!isAll) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.close,
                  size: 10,
                  color: colorScheme.onPrimary,
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.sm,
      ),
      child: Row(
        children: [
          // 배지 그룹 (가로 스크롤)
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (int i = 0;
                      i < selectedFilters.length;
                      i++) ...[
                    if (i > 0) const SizedBox(width: Spacing.sm),
                    buildActiveBadge(selectedFilters.elementAt(i)),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 필터 버튼 (드롭다운)
          PopupMenuButton<TransactionFilter>(
            onSelected: toggleFilter,
            offset: const Offset(0, 40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(BorderRadiusToken.md),
            ),
            itemBuilder: (context) {
              return TransactionFilter.values.map((filter) {
                final isSelected = selectedFilters.contains(filter);
                return PopupMenuItem<TransactionFilter>(
                  value: filter,
                  child: Row(
                    children: [
                      if (isSelected)
                        Icon(
                          Icons.check,
                          size: IconSize.xs,
                          color: colorScheme.primary,
                        )
                      else
                        const SizedBox(width: IconSize.xs),
                      const SizedBox(width: Spacing.sm),
                      Text(getFilterLabel(filter)),
                    ],
                  ),
                );
              }).toList();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(BorderRadiusToken.sm),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.filter_list,
                    size: IconSize.sm,
                    color: colorScheme.onSurface,
                  ),
                  Icon(
                    Icons.keyboard_arrow_down,
                    size: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
