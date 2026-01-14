import 'package:flutter/material.dart';

import '../themes/design_tokens.dart';

/// 앱 전체에서 사용하는 표준 Card 위젯
///
/// 일관된 스타일의 카드를 제공합니다.
/// 기본적으로 elevation 없이 둥근 모서리를 가지며,
/// [onTap]이 제공되면 탭 가능한 카드가 됩니다.
class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.elevation,
    super.key,
  });

  /// 카드 내부 콘텐츠
  final Widget child;

  /// 카드 내부 패딩 (기본: Spacing.md)
  final EdgeInsetsGeometry? padding;

  /// 카드 외부 마진
  final EdgeInsetsGeometry? margin;

  /// 탭 콜백 (제공되면 InkWell로 감싸짐)
  final VoidCallback? onTap;

  /// 카드 고도 (기본: Elevation.none)
  final double? elevation;

  @override
  Widget build(BuildContext context) {
    final cardContent = Padding(
      padding: padding ?? const EdgeInsets.all(Spacing.md),
      child: child,
    );

    final card = Card(
      elevation: elevation ?? Elevation.none,
      margin: margin ?? EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BorderRadiusToken.md),
      ),
      child: onTap != null
          ? InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(BorderRadiusToken.md),
              child: cardContent,
            )
          : cardContent,
    );

    return card;
  }
}
