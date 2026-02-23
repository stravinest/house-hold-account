import 'package:flutter/material.dart';

import '../../../../shared/themes/design_tokens.dart';
import '../pages/guide_page.dart' show GuideColors;

/// 가이드 페이지 공통 안내 배너 위젯
class GuideInfoBanner extends StatelessWidget {
  final String text;

  const GuideInfoBanner({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: GuideColors.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.info_outline,
            size: 20,
            color: GuideColors.primary,
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: GuideColors.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// 가이드 페이지 공통 스텝 헤더 위젯
class GuideStepHeader extends StatelessWidget {
  final String stepLabel;

  const GuideStepHeader({super.key, required this.stepLabel});

  @override
  Widget build(BuildContext context) {
    return Text(
      stepLabel,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: GuideColors.onSurface,
      ),
    );
  }
}

/// 가이드 페이지 공통 스텝 카드 위젯
class GuideStepCard extends StatelessWidget {
  final Widget child;

  const GuideStepCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: GuideColors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}
