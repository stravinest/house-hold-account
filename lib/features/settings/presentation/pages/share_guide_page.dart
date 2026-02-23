import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/themes/design_tokens.dart';
import '../widgets/guide_common_widgets.dart';
import 'guide_page.dart' show GuideColors;

class ShareGuidePage extends StatelessWidget {
  const ShareGuidePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: GuideColors.surface,
      appBar: AppBar(
        backgroundColor: GuideColors.surface,
        title: Text(l10n.shareGuideTitle),
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(Spacing.md + Spacing.xs),
        children: [
          // 안내 배너
          GuideInfoBanner(text: l10n.shareGuideIntro),

          const SizedBox(height: Spacing.lg),

          // Step 1 - 멤버 초대하기
          GuideStepHeader(stepLabel: l10n.shareGuideStepLabel('1', l10n.shareGuideStep1Title)),
          const SizedBox(height: Spacing.sm),
          GuideStepCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.shareGuideStep1Desc,
                  style: const TextStyle(
                    fontSize: 13,
                    color: GuideColors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: Spacing.md),
                // 이메일 입력 모크업
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: GuideColors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.mail_outline,
                            size: 20,
                            color: GuideColors.onSurfaceVariant,
                          ),
                          const SizedBox(width: Spacing.sm),
                          Text(
                            l10n.shareGuideMockEmail,
                            style: const TextStyle(
                              fontSize: 13,
                              color: GuideColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Spacing.md),
                      Container(
                        width: double.infinity,
                        height: 36,
                        decoration: BoxDecoration(
                          color: GuideColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          l10n.shareGuideMockInviteBtn,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: GuideColors.onPrimary,
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

          // Step 2 - 초대 수락
          GuideStepHeader(stepLabel: l10n.shareGuideStepLabel('2', l10n.shareGuideStep2Title)),
          const SizedBox(height: Spacing.sm),
          GuideStepCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.shareGuideStep2Desc,
                  style: const TextStyle(
                    fontSize: 13,
                    color: GuideColors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: Spacing.md),
                // 알림 카드 모크업
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: GuideColors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.notifications_outlined,
                            size: 20,
                            color: GuideColors.primary,
                          ),
                          const SizedBox(width: Spacing.sm),
                          Expanded(
                            child: Text(
                              l10n.shareGuideMockInviteArrived,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: GuideColors.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Spacing.md),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            width: 60,
                            height: 30,
                            decoration: BoxDecoration(
                              color: GuideColors.surfaceContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              l10n.shareGuideMockReject,
                              style: const TextStyle(
                                fontSize: 12,
                                color: GuideColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                          const SizedBox(width: Spacing.sm),
                          Container(
                            width: 60,
                            height: 30,
                            decoration: BoxDecoration(
                              color: GuideColors.primary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              l10n.shareGuideMockAccept,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: GuideColors.onPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: Spacing.lg),

          // Step 3 - 실시간 동기화
          GuideStepHeader(stepLabel: l10n.shareGuideStepLabel('3', l10n.shareGuideStep3Title)),
          const SizedBox(height: Spacing.sm),
          GuideStepCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.shareGuideStep3Desc,
                  style: const TextStyle(
                    fontSize: 13,
                    color: GuideColors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: Spacing.md),
                // 멤버별 거래 모크업
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: GuideColors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      _MemberTransactionRow(
                        color: GuideColors.memberBlue,
                        name: l10n.shareGuideMockMe,
                        amount: l10n.shareGuideMockMeAmount,
                      ),
                      const SizedBox(height: Spacing.sm),
                      _MemberTransactionRow(
                        color: GuideColors.memberCoral,
                        name: l10n.shareGuideMockPartner,
                        amount: l10n.shareGuideMockPartnerAmount,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: Spacing.lg),

          // Step 4 - 캘린더에서 확인하기
          GuideStepHeader(stepLabel: l10n.shareGuideStepLabel('4', l10n.shareGuideStep4Title)),
          const SizedBox(height: Spacing.sm),
          GuideStepCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.shareGuideStep4Desc,
                  style: const TextStyle(
                    fontSize: 13,
                    color: GuideColors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: Spacing.md),
                // 캘린더 모크업
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: GuideColors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.shareGuideMockCalendarDate,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: GuideColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: Spacing.sm),
                      Container(height: 1, color: GuideColors.outlineVariant),
                      const SizedBox(height: Spacing.sm),
                      _CalendarTransactionRow(
                        color: GuideColors.memberBlue,
                        store: l10n.shareGuideMockStarbucks,
                        category: l10n.shareGuideMockCafeDrink,
                        amount: l10n.shareGuideMockStarbucksAmount,
                      ),
                      const SizedBox(height: Spacing.sm),
                      _CalendarTransactionRow(
                        color: GuideColors.memberCoral,
                        store: l10n.shareGuideMockEmart,
                        category: l10n.shareGuideMockGrocery,
                        amount: l10n.shareGuideMockEmartAmount,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: Spacing.lg),

          // Step 5 - 통계에서 확인하기
          GuideStepHeader(stepLabel: l10n.shareGuideStepLabel('5', l10n.shareGuideStep5Title)),
          const SizedBox(height: Spacing.sm),
          GuideStepCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.shareGuideStep5Desc,
                  style: const TextStyle(
                    fontSize: 13,
                    color: GuideColors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: Spacing.md),
                // 통계 바 차트 모크업
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: GuideColors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.shareGuideMockChartTitle,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: GuideColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: Spacing.md),
                      _BarChartRow(
                        name: l10n.shareGuideMockMe,
                        color: GuideColors.memberBlue,
                        ratio: 0.65,
                        amount: l10n.shareGuideMockMeChartAmount,
                      ),
                      const SizedBox(height: Spacing.sm),
                      _BarChartRow(
                        name: l10n.shareGuideMockPartner,
                        color: GuideColors.memberCoral,
                        ratio: 0.35,
                        amount: l10n.shareGuideMockPartnerChartAmount,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: Spacing.lg),

          // Tip 섹션
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
                  Icons.lightbulb_outline,
                  size: 20,
                  color: GuideColors.primary,
                ),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: Text(
                    l10n.shareGuideTip,
                    style: const TextStyle(
                      fontSize: 13,
                      color: GuideColors.onSurfaceVariant,
                      height: 1.5,
                    ),
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

class _MemberTransactionRow extends StatelessWidget {
  final Color color;
  final String name;
  final String amount;

  const _MemberTransactionRow({
    required this.color,
    required this.name,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: Spacing.sm),
        Expanded(
          child: Text(
            name,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: GuideColors.onSurface,
            ),
          ),
        ),
        Text(
          amount,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: GuideColors.expense,
          ),
        ),
      ],
    );
  }
}

class _CalendarTransactionRow extends StatelessWidget {
  final Color color;
  final String store;
  final String category;
  final String amount;

  const _CalendarTransactionRow({
    required this.color,
    required this.store,
    required this.category,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 36,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: Spacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                store,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: GuideColors.onSurface,
                ),
              ),
              Text(
                category,
                style: const TextStyle(
                  fontSize: 11,
                  color: GuideColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Text(
          amount,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: GuideColors.expense,
          ),
        ),
      ],
    );
  }
}

class _BarChartRow extends StatelessWidget {
  final String name;
  final Color color;
  final double ratio;
  final String amount;

  const _BarChartRow({
    required this.name,
    required this.color,
    required this.ratio,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: GuideColors.onSurface,
              ),
            ),
            Text(
              amount,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: GuideColors.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LayoutBuilder(
          builder: (context, constraints) {
            return Container(
              width: constraints.maxWidth * ratio,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          },
        ),
      ],
    );
  }
}
