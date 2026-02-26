import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/themes/design_tokens.dart';
import '../providers/category_keyword_mapping_provider.dart';

/// 결제수단 수정 페이지 내 카테고리 자동연결 섹션
/// 디자인 참조: pencil house.pen Node ID: BCDIc
class CategoryMappingSection extends ConsumerWidget {
  final String paymentMethodId;
  final String ledgerId;

  const CategoryMappingSection({
    super.key,
    required this.paymentMethodId,
    required this.ledgerId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    final allMappingsAsync = ref.watch(
      categoryKeywordMappingNotifierProvider(paymentMethodId),
    );

    final smsMappings = allMappingsAsync.valueOrNull
            ?.where((m) => m.sourceType == 'sms')
            .toList() ??
        [];
    final pushMappings = allMappingsAsync.valueOrNull
            ?.where((m) => m.sourceType == 'push')
            .toList() ??
        [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 타이틀 (자동 처리 모드, 수집 방식과 동일한 스타일)
        Text(
          l10n.categoryMappingSectionTitle,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),

        // 설명
        Text(
          l10n.categoryMappingSectionDescription,
          style: TextStyle(
            fontSize: 13,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: Spacing.md),

        // SMS 카드 행
        _buildSourceRow(
          context: context,
          l10n: l10n,
          label: 'SMS',
          count: smsMappings.length,
          badgeColor: colorScheme.primaryContainer,
          badgeTextColor: colorScheme.onPrimaryContainer,
          onManageTap: () {
            context.push(
              '/settings/payment-methods/$paymentMethodId/category-mapping/sms',
              extra: {'ledgerId': ledgerId},
            );
          },
        ),
        const SizedBox(height: Spacing.sm),

        // Push 카드 행
        _buildSourceRow(
          context: context,
          l10n: l10n,
          label: 'Push',
          count: pushMappings.length,
          badgeColor: colorScheme.tertiaryContainer,
          badgeTextColor: colorScheme.onTertiaryContainer,
          onManageTap: () {
            context.push(
              '/settings/payment-methods/$paymentMethodId/category-mapping/push',
              extra: {'ledgerId': ledgerId},
            );
          },
        ),
      ],
    );
  }

  Widget _buildSourceRow({
    required BuildContext context,
    required AppLocalizations l10n,
    required String label,
    required int count,
    required Color badgeColor,
    required Color badgeTextColor,
    required VoidCallback onManageTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(BorderRadiusToken.sm),
      ),
      child: Row(
        children: [
          // 소스 타입 배지
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: badgeTextColor,
              ),
            ),
          ),
          const SizedBox(width: Spacing.sm),

          // 연결 개수
          Expanded(
            child: Text(
              l10n.categoryMappingCount(count),
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurface,
              ),
            ),
          ),

          // 관리 버튼
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onManageTap,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.categoryMappingManage,
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: colorScheme.primary,
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
