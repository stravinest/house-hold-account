import 'package:flutter/material.dart';

import '../themes/design_tokens.dart';

/// 빈 상태(Empty State)를 표시하는 공통 위젯
///
/// 데이터가 없거나 검색 결과가 없을 때 사용합니다.
/// [icon]과 [message]는 필수이며, [subtitle]과 [action]은 선택적입니다.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.message,
    this.subtitle,
    this.action,
    super.key,
  });

  /// 빈 상태를 나타내는 아이콘
  final IconData icon;

  /// 주요 메시지 (예: '등록된 카테고리가 없습니다')
  final String message;

  /// 부가 설명 (예: '+ 버튼을 눌러 추가하세요')
  final String? subtitle;

  /// 액션 버튼 (예: '새로 만들기' 버튼)
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: IconSize.xxl, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: Spacing.md),
            Text(
              message,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: Spacing.sm),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: Spacing.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
