import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/themes/design_tokens.dart';
import '../widgets/guide_common_widgets.dart';
import 'guide_page.dart' show GuideColors;

class TransactionGuidePage extends StatelessWidget {
  const TransactionGuidePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: GuideColors.surface,
      appBar: AppBar(
        backgroundColor: GuideColors.surface,
        title: Text(l10n.transactionGuideTitle),
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(Spacing.md + Spacing.xs),
        children: [
          // 안내 배너
          GuideInfoBanner(text: l10n.transactionGuideIntro),

          const SizedBox(height: Spacing.lg),

          // Step 1: + 버튼으로 거래 추가
          GuideStepHeader(stepLabel: l10n.transactionGuideStepLabel('1', l10n.transactionGuideStep1Title)),
          const SizedBox(height: Spacing.sm),
          GuideStepCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.transactionGuideStep1Desc,
                  style: const TextStyle(
                    fontSize: 13,
                    color: GuideColors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: Spacing.md),
                // 거래 유형 탭 모크업
                Row(
                  children: [
                    _MockChip(label: l10n.transactionGuideMockIncome, isActive: true),
                    const SizedBox(width: Spacing.sm),
                    _MockChip(label: l10n.transactionGuideMockExpense, isActive: false),
                    const SizedBox(width: Spacing.sm),
                    _MockChip(label: l10n.transactionGuideMockAsset, isActive: false),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: Spacing.lg),

          // Step 2: 금액 입력
          GuideStepHeader(stepLabel: l10n.transactionGuideStepLabel('2', l10n.transactionGuideStep2Title)),
          const SizedBox(height: Spacing.sm),
          GuideStepCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.transactionGuideStep2Desc,
                  style: const TextStyle(
                    fontSize: 13,
                    color: GuideColors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: Spacing.md),
                // 금액 표시 모크업
                Container(
                  padding: const EdgeInsets.all(Spacing.md),
                  decoration: BoxDecoration(
                    color: GuideColors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.transactionGuideMockAmountLabel,
                        style: const TextStyle(
                          fontSize: 11,
                          color: GuideColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: Spacing.xs),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.only(bottom: 6),
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: GuideColors.primary,
                              width: 2,
                            ),
                          ),
                        ),
                        child: Text(
                          l10n.transactionGuideMockAmountValue,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: GuideColors.onSurface,
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

          // Step 3: 상세 정보 입력
          GuideStepHeader(stepLabel: l10n.transactionGuideStepLabel('3', l10n.transactionGuideStep3Title)),
          const SizedBox(height: Spacing.sm),
          GuideStepCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.transactionGuideStep3Desc,
                  style: const TextStyle(
                    fontSize: 13,
                    color: GuideColors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: Spacing.md),
                // 상세 정보 모크업
                Container(
                  padding: const EdgeInsets.all(Spacing.md),
                  decoration: BoxDecoration(
                    color: GuideColors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      _MockDetailRow(label: l10n.transactionGuideMockCategory, value: l10n.transactionGuideMockCategoryValue),
                      const Divider(height: 1, color: GuideColors.outlineVariant),
                      _MockDetailRow(label: l10n.transactionGuideMockPaymentMethod, value: l10n.transactionGuideMockPaymentMethodValue),
                      const Divider(height: 1, color: GuideColors.outlineVariant),
                      _MockDetailRow(label: l10n.transactionGuideMockMemo, value: l10n.transactionGuideMockMemoValue),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: Spacing.lg),

          // Step 4: 고정비 / 할부 / 반복 설정
          GuideStepHeader(stepLabel: l10n.transactionGuideStepLabel('4', l10n.transactionGuideStep4Title)),
          const SizedBox(height: Spacing.sm),
          GuideStepCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.transactionGuideStep4Desc,
                  style: const TextStyle(
                    fontSize: 13,
                    color: GuideColors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: Spacing.md),

                // 4-a) 고정비 등록
                _SubSectionHeader(icon: Icons.push_pin, label: l10n.transactionGuideMockFixedExpenseRegister),
                const SizedBox(height: Spacing.sm),
                Container(
                  padding: const EdgeInsets.all(Spacing.md),
                  decoration: BoxDecoration(
                    color: GuideColors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.transactionGuideMockFixedExpenseToggle,
                            style: const TextStyle(
                              fontSize: 13,
                              color: GuideColors.onSurface,
                            ),
                          ),
                          Container(
                            width: 40,
                            height: 22,
                            decoration: BoxDecoration(
                              color: GuideColors.primary,
                              borderRadius: BorderRadius.circular(11),
                            ),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.all(2),
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: const BoxDecoration(
                                color: GuideColors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Spacing.sm),
                      Text(
                        l10n.transactionGuideMockFixedExpenseNote,
                        style: const TextStyle(
                          fontSize: 11,
                          color: GuideColors.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: Spacing.md),

                // 4-b) 할부 입력
                _SubSectionHeader(icon: Icons.credit_card, label: l10n.transactionGuideMockInstallmentInput),
                const SizedBox(height: Spacing.sm),
                Container(
                  padding: const EdgeInsets.all(Spacing.md),
                  decoration: BoxDecoration(
                    color: GuideColors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.transactionGuideMockInstallment,
                            style: const TextStyle(
                              fontSize: 13,
                              color: GuideColors.onSurface,
                            ),
                          ),
                          Text(
                            l10n.transactionGuideMockInstallmentMonths,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: GuideColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Spacing.sm),
                      // 할부 진행 바
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: 1 / 3,
                          minHeight: 6,
                          backgroundColor: GuideColors.surfaceContainer,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            GuideColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: Spacing.sm),
                      Text(
                        l10n.transactionGuideMockInstallmentNote,
                        style: const TextStyle(
                          fontSize: 11,
                          color: GuideColors.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: Spacing.md),

                // 4-c) 반복주기 설정
                _SubSectionHeader(icon: Icons.repeat, label: l10n.transactionGuideMockRecurringSetting),
                const SizedBox(height: Spacing.sm),
                Container(
                  padding: const EdgeInsets.all(Spacing.md),
                  decoration: BoxDecoration(
                    color: GuideColors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _MockDetailRow(label: l10n.transactionGuideMockRepeat, value: l10n.transactionGuideMockMonthly),
                      const Divider(
                        height: 1,
                        color: GuideColors.outlineVariant,
                      ),
                      _MockDetailRow(label: l10n.transactionGuideMockDate, value: l10n.transactionGuideMockDay15),
                      const SizedBox(height: Spacing.sm),
                      // 주기 칩 옵션
                      Row(
                        children: [
                          _MockChip(label: l10n.transactionGuideMockDaily, isActive: false),
                          const SizedBox(width: Spacing.sm),
                          _MockChip(label: l10n.transactionGuideMockWeekly, isActive: false),
                          const SizedBox(width: Spacing.sm),
                          _MockChip(label: l10n.transactionGuideMockMonthly, isActive: true),
                        ],
                      ),
                      const SizedBox(height: Spacing.sm),
                      Text(
                        l10n.transactionGuideMockRecurringNote,
                        style: const TextStyle(
                          fontSize: 11,
                          color: GuideColors.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: Spacing.lg),

          // Step 5: 반복거래 확인하기
          GuideStepHeader(stepLabel: l10n.transactionGuideStepLabel('5', l10n.transactionGuideStep5Title)),
          const SizedBox(height: Spacing.sm),
          GuideStepCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.transactionGuideStep5Desc,
                  style: const TextStyle(
                    fontSize: 13,
                    color: GuideColors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: Spacing.md),
                Container(
                  padding: const EdgeInsets.all(Spacing.md),
                  decoration: BoxDecoration(
                    color: GuideColors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      // 경로 표시
                      Row(
                        children: [
                          const Icon(
                            Icons.settings,
                            size: 16,
                            color: GuideColors.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            l10n.transactionGuideMockSettings,
                            style: const TextStyle(
                              fontSize: 12,
                              color: GuideColors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.chevron_right,
                            size: 16,
                            color: GuideColors.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            l10n.transactionGuideMockRecurringManagement,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: GuideColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const Divider(
                        height: Spacing.md * 2,
                        color: GuideColors.outlineVariant,
                      ),
                      // 반복거래 항목 1
                      _MockRecurringItem(
                        title: l10n.transactionGuideMockNetflix,
                        amount: l10n.transactionGuideMockNetflixAmount,
                      ),
                      const SizedBox(height: Spacing.sm),
                      // 반복거래 항목 2
                      _MockRecurringItem(
                        title: l10n.transactionGuideMockRent,
                        amount: l10n.transactionGuideMockRentAmount,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: Spacing.lg),

          // Step 6: 저장 완료
          GuideStepHeader(stepLabel: l10n.transactionGuideStepLabel('6', l10n.transactionGuideStep6Title)),
          const SizedBox(height: Spacing.sm),
          GuideStepCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.transactionGuideStep6Desc,
                  style: const TextStyle(
                    fontSize: 13,
                    color: GuideColors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: Spacing.md),
                // 저장 버튼 모크업
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacing.xl,
                      vertical: Spacing.sm + 2,
                    ),
                    decoration: BoxDecoration(
                      color: GuideColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check, size: 18, color: GuideColors.white),
                        const SizedBox(width: Spacing.sm),
                        Text(
                          l10n.transactionGuideMockSave,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: GuideColors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: Spacing.lg),

          // 팁 섹션
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
                    l10n.transactionGuideTip,
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

class _SubSectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SubSectionHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: GuideColors.primary),
        const SizedBox(width: Spacing.xs),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: GuideColors.onSurface,
          ),
        ),
      ],
    );
  }
}

class _MockChip extends StatelessWidget {
  final String label;
  final bool isActive;

  const _MockChip({required this.label, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isActive
            ? GuideColors.primaryContainer
            : GuideColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          color: isActive ? GuideColors.primary : GuideColors.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _MockDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _MockDetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: GuideColors.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: GuideColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _MockRecurringItem extends StatelessWidget {
  final String title;
  final String amount;

  const _MockRecurringItem({required this.title, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: GuideColors.surfaceContainer,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.repeat,
                size: 16,
                color: GuideColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: Spacing.sm),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: GuideColors.onSurface,
              ),
            ),
          ],
        ),
        Text(
          amount,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: GuideColors.expense,
          ),
        ),
      ],
    );
  }
}
