import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/themes/design_tokens.dart';
import '../widgets/guide_common_widgets.dart';
import 'guide_page.dart' show GuideColors;

class AutoCollectGuidePage extends StatelessWidget {
  const AutoCollectGuidePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: GuideColors.surface,
      appBar: AppBar(
        backgroundColor: GuideColors.surface,
        title: Text(l10n.autoCollectGuideTitle),
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(Spacing.md + Spacing.xs),
        children: [
          // 안내 배너
          GuideInfoBanner(text: l10n.autoCollectGuideIntro),

          const SizedBox(height: Spacing.lg),

          // Step 1
          GuideStepHeader(stepLabel: l10n.autoCollectGuideStepLabel('1', l10n.autoCollectGuideStep1Title)),
          const SizedBox(height: Spacing.sm),
          GuideStepCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.autoCollectGuideStep1Desc,
                  style: const TextStyle(
                    fontSize: 13,
                    color: GuideColors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: Spacing.md),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.md,
                    vertical: Spacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: GuideColors.surface,
                    borderRadius: BorderRadius.circular(Spacing.sm),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: GuideColors.primary,
                          borderRadius: BorderRadius.circular(Spacing.sm),
                        ),
                        child: const Icon(
                          Icons.credit_card,
                          color: GuideColors.onPrimary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: Spacing.md),
                      Text(
                        l10n.autoCollectGuideMockCardName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: GuideColors.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: Spacing.lg),

          // Step 2
          GuideStepHeader(stepLabel: l10n.autoCollectGuideStepLabel('2', l10n.autoCollectGuideStep2Title)),
          const SizedBox(height: Spacing.sm),
          GuideStepCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.autoCollectGuideStep2Desc,
                  style: const TextStyle(
                    fontSize: 13,
                    color: GuideColors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: Spacing.md),
                // SMS/Push 세그먼트 모크업
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: GuideColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: GuideColors.primaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.sms_outlined,
                                size: 16,
                                color: GuideColors.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                l10n.autoCollectGuideMockSms,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: GuideColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.notifications_outlined,
                              size: 16,
                              color: GuideColors.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              l10n.autoCollectGuideMockPush,
                              style: const TextStyle(
                                fontSize: 12,
                                color: GuideColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Spacing.sm),
                Text(
                  l10n.autoCollectGuideStep2Note,
                  style: const TextStyle(
                    fontSize: 11,
                    color: GuideColors.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: Spacing.lg),

          // Step 3 - 수집 규칙 설정
          GuideStepHeader(stepLabel: l10n.autoCollectGuideStepLabel('3', l10n.autoCollectGuideRulesTitle)),
          const SizedBox(height: Spacing.sm),
          GuideStepCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.autoCollectGuideRulesDesc,
                  style: const TextStyle(
                    fontSize: 13,
                    color: GuideColors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: Spacing.md),
                // 감지 키워드 섹션
                _KeywordSection(
                  icon: Icons.search,
                  iconColor: GuideColors.primary,
                  title: l10n.autoCollectGuideDetectKeyword,
                  description: l10n.autoCollectGuideDetectKeywordDesc,
                  chips: [l10n.autoCollectGuideMockDetectChipKb, l10n.autoCollectGuideMockDetectChipApproval],
                  chipBorderColor: GuideColors.primary,
                ),
                const SizedBox(height: Spacing.md),
                // 금지 키워드 섹션
                _KeywordSection(
                  icon: Icons.block,
                  iconColor: GuideColors.warning,
                  title: l10n.autoCollectGuideExcludeKeyword,
                  description: l10n.autoCollectGuideExcludeKeywordDesc,
                  chips: [l10n.autoCollectGuideMockExcludeChipBalance, l10n.autoCollectGuideMockExcludeChipPoint],
                  chipBorderColor: GuideColors.warning,
                ),
                const SizedBox(height: Spacing.md),
                // Tip 박스
                Container(
                  padding: const EdgeInsets.all(Spacing.sm),
                  decoration: BoxDecoration(
                    color: GuideColors.primaryContainer,
                    borderRadius: BorderRadius.circular(Spacing.sm),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.lightbulb_outline,
                        size: 16,
                        color: GuideColors.primary,
                      ),
                      const SizedBox(width: Spacing.xs),
                      Expanded(
                        child: Text(
                          l10n.autoCollectGuideKeywordTip,
                          style: const TextStyle(
                            fontSize: 11,
                            color: GuideColors.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: Spacing.lg),

          // Step 4 - 처리 모드 선택
          GuideStepHeader(stepLabel: l10n.autoCollectGuideStepLabel('4', l10n.autoCollectGuideStep3Title)),
          const SizedBox(height: Spacing.sm),
          GuideStepCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ModeOption(
                  title: l10n.autoCollectGuideModeSuggest,
                  description: l10n.autoCollectGuideModeSuggestDesc,
                  isSelected: true,
                ),
                const SizedBox(height: Spacing.sm),
                _ModeOption(
                  title: l10n.autoCollectGuideModeAuto,
                  description: l10n.autoCollectGuideModeAutoDesc,
                  isSelected: false,
                ),
              ],
            ),
          ),

          const SizedBox(height: Spacing.lg),

          // Step 5 - 카테고리 자동연결
          GuideStepHeader(stepLabel: l10n.autoCollectGuideStepLabel('5', l10n.autoCollectGuideCategoryMappingTitle)),
          const SizedBox(height: Spacing.sm),
          GuideStepCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.autoCollectGuideCategoryMappingDesc,
                  style: const TextStyle(
                    fontSize: 13,
                    color: GuideColors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: Spacing.sm),
                Text(
                  l10n.autoCollectGuideCategoryMappingDetail1,
                  style: const TextStyle(
                    fontSize: 12,
                    color: GuideColors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: Spacing.md),
                // 매핑 예시 모크업
                Container(
                  padding: const EdgeInsets.all(Spacing.sm),
                  decoration: BoxDecoration(
                    color: GuideColors.surface,
                    borderRadius: BorderRadius.circular(Spacing.sm),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.autoCollectGuideCategoryMappingMockKeyword,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: GuideColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Text(
                            '\u2192  ',
                            style: TextStyle(
                              fontSize: 12,
                              color: GuideColors.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            l10n.autoCollectGuideCategoryMappingMockCategory,
                            style: const TextStyle(
                              fontSize: 12,
                              color: GuideColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Spacing.md),
                // Tip 박스
                Container(
                  padding: const EdgeInsets.all(Spacing.sm),
                  decoration: BoxDecoration(
                    color: GuideColors.primaryContainer,
                    borderRadius: BorderRadius.circular(Spacing.sm),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.lightbulb_outline,
                        size: 16,
                        color: GuideColors.primary,
                      ),
                      const SizedBox(width: Spacing.xs),
                      Expanded(
                        child: Text(
                          l10n.autoCollectGuideCategoryMappingDetail2,
                          style: const TextStyle(
                            fontSize: 11,
                            color: GuideColors.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: Spacing.lg),

          // Step 6 - 수집내역 확인
          GuideStepHeader(stepLabel: l10n.autoCollectGuideStepLabel('6', l10n.autoCollectGuideStep4Title)),
          const SizedBox(height: Spacing.sm),
          GuideStepCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.autoCollectGuideStep4Desc,
                  style: const TextStyle(
                    fontSize: 13,
                    color: GuideColors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: Spacing.md),
                // 수집내역 카드 모크업
                Container(
                  padding: const EdgeInsets.all(Spacing.md),
                  decoration: BoxDecoration(
                    color: GuideColors.surface,
                    borderRadius: BorderRadius.circular(Spacing.sm),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.autoCollectGuideMockStoreName,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: GuideColors.onSurface,
                            ),
                          ),
                          Text(
                            l10n.autoCollectGuideMockAmount,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: GuideColors.error,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Spacing.sm),
                      Row(
                        children: [
                          Text(
                            l10n.autoCollectGuideMockDetail,
                            style: const TextStyle(
                              fontSize: 11,
                              color: GuideColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Spacing.sm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _MockButton(
                            label: l10n.autoCollectGuideReject,
                            color: GuideColors.surfaceContainer,
                            textColor: GuideColors.onSurfaceVariant,
                          ),
                          const SizedBox(width: Spacing.sm),
                          _MockButton(
                            label: l10n.autoCollectGuideApprove,
                            color: GuideColors.primary,
                            textColor: GuideColors.onPrimary,
                            isBold: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: Spacing.xl),
        ],
      ),
    );
  }
}


class _ModeOption extends StatelessWidget {
  final String title;
  final String description;
  final bool isSelected;

  const _ModeOption({
    required this.title,
    required this.description,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.sm,
      ),
      decoration: BoxDecoration(
        color: GuideColors.surface,
        borderRadius: BorderRadius.circular(Spacing.sm),
      ),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? GuideColors.primary
                    : GuideColors.outlineVariant,
                width: 2,
              ),
            ),
            child: isSelected
                ? Center(
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: GuideColors.primary,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: GuideColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 11,
                    color: GuideColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KeywordSection extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final List<String> chips;
  final Color chipBorderColor;

  const _KeywordSection({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.chips,
    required this.chipBorderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Spacing.sm),
      decoration: BoxDecoration(
        color: GuideColors.surface,
        borderRadius: BorderRadius.circular(Spacing.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: Spacing.xs),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: iconColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            description,
            style: const TextStyle(
              fontSize: 11,
              color: GuideColors.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Wrap(
            spacing: Spacing.xs,
            children: chips
                .map(
                  (chip) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacing.sm,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: chipBorderColor, width: 1),
                      borderRadius: BorderRadius.circular(Spacing.md),
                    ),
                    child: Text(
                      chip,
                      style: TextStyle(
                        fontSize: 11,
                        color: chipBorderColor,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _MockButton extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  final bool isBold;

  const _MockButton({
    required this.label,
    required this.color,
    required this.textColor,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 30,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
          color: textColor,
        ),
      ),
    );
  }
}
