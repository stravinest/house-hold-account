import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/themes/design_tokens.dart';
import 'guide_page.dart' show GuideColors;

class AutoCollectGuidePage extends StatelessWidget {
  const AutoCollectGuidePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.autoCollectGuideTitle),
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(Spacing.md + Spacing.xs),
        children: [
          // 안내 배너
          Container(
            padding: const EdgeInsets.all(Spacing.md),
            decoration: BoxDecoration(
              color: GuideColors.primaryContainer,
              borderRadius: BorderRadius.circular(Spacing.md),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 20,
                  color: GuideColors.primary,
                ),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: Text(
                    l10n.autoCollectGuideIntro,
                    style: const TextStyle(
                      fontSize: 12,
                      color: GuideColors.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: Spacing.lg),

          // Step 1
          _StepHeader(number: '1', title: l10n.autoCollectGuideStep1Title),
          const SizedBox(height: Spacing.sm),
          _StepCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.autoCollectGuideStep1Desc,
                  style: const TextStyle(
                    fontSize: 12,
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
          _StepHeader(number: '2', title: l10n.autoCollectGuideStep2Title),
          const SizedBox(height: Spacing.sm),
          _StepCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.autoCollectGuideStep2Desc,
                  style: const TextStyle(
                    fontSize: 12,
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
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.sms_outlined,
                                size: 16,
                                color: GuideColors.primary,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'SMS',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: GuideColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.notifications_outlined,
                              size: 16,
                              color: GuideColors.onSurfaceVariant,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Push',
                              style: TextStyle(
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

          // Step 3
          _StepHeader(number: '3', title: l10n.autoCollectGuideStep3Title),
          const SizedBox(height: Spacing.sm),
          _StepCard(
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

          // Step 4
          _StepHeader(number: '4', title: l10n.autoCollectGuideStep4Title),
          const SizedBox(height: Spacing.sm),
          _StepCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.autoCollectGuideStep4Desc,
                  style: const TextStyle(
                    fontSize: 12,
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
                              color: Color(0xFFBA1A1A),
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

class _StepHeader extends StatelessWidget {
  final String number;
  final String title;

  const _StepHeader({required this.number, required this.title});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Text(
      l10n.autoCollectGuideStepLabel(number, title),
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: GuideColors.onSurface,
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final Widget child;

  const _StepCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: GuideColors.surfaceContainer,
        borderRadius: BorderRadius.circular(Spacing.md),
      ),
      child: child,
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
