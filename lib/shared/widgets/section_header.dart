import 'package:flutter/material.dart';

import '../themes/design_tokens.dart';

/// 섹션 헤더를 표시하는 공통 위젯
///
/// 목록이나 그룹의 제목을 표시할 때 사용합니다.
/// [title]은 필수이며, [icon]과 [trailing]은 선택적입니다.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    this.icon,
    this.trailing,
    super.key,
  });

  /// 섹션 제목
  final String title;

  /// 제목 앞에 표시할 아이콘 (선택)
  final IconData? icon;

  /// 제목 뒤에 표시할 위젯 (선택, 예: 더보기 버튼)
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.sm,
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: IconSize.sm, color: colorScheme.primary),
            const SizedBox(width: Spacing.sm),
          ],
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
