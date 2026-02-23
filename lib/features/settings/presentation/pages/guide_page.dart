import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/router.dart';
import '../../../../l10n/generated/app_localizations.dart';

// Pencil 디자인 색상 (house.pen 기준)
class GuideColors {
  static const surface = Color(0xFFFDFDF5);
  static const surfaceContainer = Color(0xFFEFEEE6);
  static const primary = Color(0xFF2E7D32);
  static const primaryContainer = Color(0xFFA8DAB5);
  static const onSurface = Color(0xFF1A1C19);
  static const onSurfaceVariant = Color(0xFF44483E);
  static const outlineVariant = Color(0xFFC4C8BB);
  static const onPrimary = Color(0xFFFFFFFF);
  static const white = Color(0xFFFFFFFF);
  static const expense = Color(0xFFE53935);
  static const warning = Color(0xFFE65100);
  static const error = Color(0xFFBA1A1A);
  static const memberBlue = Color(0xFFA8D8EA);
  static const memberCoral = Color(0xFFFFB6A3);
  static const chipBlueBorder = Color(0xFF90CAF9);
  static const chipOrangeBorder = Color(0xFFFFAB91);
}

class GuidePage extends StatelessWidget {
  const GuidePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: GuideColors.surface,
      appBar: AppBar(
        backgroundColor: GuideColors.surface,
        title: Text(l10n.settingsGuide),
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          // 환영 섹션
          Column(
            children: [
              Image.asset(
                'assets/images/app_icon.png',
                width: 48,
                height: 48,
                errorBuilder: (context, error, stack) => const Icon(
                  Icons.account_balance_wallet,
                  size: 48,
                  color: GuideColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.guideWelcomeTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: GuideColors.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.guideWelcomeDescription,
                style: const TextStyle(
                  fontSize: 14,
                  color: GuideColors.onSurfaceVariant,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),

          const SizedBox(height: 24),
          const Divider(color: GuideColors.outlineVariant, height: 1),
          const SizedBox(height: 24),

          _GuideNavigationCard(
            icon: Icons.edit_note,
            title: l10n.guideRecordTitle,
            description: l10n.guideRecordDescription,
            badgeLabel: l10n.guideDetailView,
            onTap: () => context.push(Routes.transactionGuide),
          ),
          const SizedBox(height: 24),
          _GuideNavigationCard(
            icon: Icons.group,
            title: l10n.guideShareTitle,
            description: l10n.guideShareDescription,
            badgeLabel: l10n.guideDetailView,
            onTap: () => context.push(Routes.shareGuide),
          ),
          const SizedBox(height: 24),
          _GuideCard(
            icon: Icons.bar_chart,
            title: l10n.guideStatsTitle,
            description: l10n.guideStatsDescription,
          ),
          if (Platform.isAndroid) ...[
            const SizedBox(height: 24),
            _GuideNavigationCard(
              icon: Icons.phonelink_ring,
              title: l10n.guideAutoCollectTitle,
              description: l10n.guideAutoCollectDescription,
              badgeLabel: l10n.guideDetailView,
              onTap: () => context.push(Routes.autoCollectGuide),
            ),
          ],

          const SizedBox(height: 24),
          const Divider(color: GuideColors.outlineVariant, height: 1),
          const SizedBox(height: 24),

          // Tip 섹션
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: GuideColors.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.guideTipLabel,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: GuideColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.guideTip,
                  style: const TextStyle(
                    fontSize: 13,
                    color: GuideColors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _GuideCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _GuideCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GuideColors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: GuideColors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 24, color: GuideColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: GuideColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: GuideColors.onSurfaceVariant,
                    height: 1.4,
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

class _GuideNavigationCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String badgeLabel;
  final VoidCallback onTap;

  const _GuideNavigationCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.badgeLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: GuideColors.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: GuideColors.primary),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: GuideColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 24,
                color: GuideColors.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: GuideColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: GuideColors.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: GuideColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      badgeLabel,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: GuideColors.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 20,
              color: GuideColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
