import 'package:flutter/material.dart';

import '../../core/utils/color_utils.dart';
import '../../l10n/generated/app_localizations.dart';
import '../themes/design_tokens.dart';
import 'category_icon.dart';

/// Material 아이콘 그리드 선택기
///
/// [CategoryIcon.iconMap]과 [CategoryIcon.iconGroups]를 활용하여
/// 아이콘을 그리드 형태로 표시하고 선택할 수 있게 합니다.
class IconPicker extends StatelessWidget {
  /// 현재 선택된 아이콘 이름 (빈 문자열 = 아이콘 없음)
  final String selectedIcon;

  /// 아이콘 선택 시 콜백
  final ValueChanged<String> onIconSelected;

  /// 해당 그룹 아이콘 우선 표시 (expense, income, asset, fixed, payment)
  final String? filterGroup;

  /// 아이콘 미리보기 색상 (#RRGGBB)
  final String selectedColor;

  const IconPicker({
    super.key,
    required this.selectedIcon,
    required this.onIconSelected,
    this.filterGroup,
    this.selectedColor = '#6750A4',
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final previewColor = ColorUtils.parseHexColor(
      selectedColor,
      fallback: colorScheme.primary,
    );

    // 그룹 필터에 해당하는 아이콘을 먼저, 나머지를 뒤에 배치
    final List<String> orderedIcons = _buildOrderedIcons();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.categoryIcon,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: Spacing.sm),
        SizedBox(
          width: double.infinity,
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              // 빈 문자열 옵션 (아이콘 없음 = 첫 글자 사용)
              _IconChip(
                iconName: '',
                label: l10n.iconNone,
                isSelected: selectedIcon.isEmpty,
                color: previewColor,
                onTap: () => onIconSelected(''),
              ),
              // 아이콘 목록
              ...orderedIcons.map((iconName) {
                final iconData = CategoryIcon.iconMap[iconName];
                if (iconData == null) return const SizedBox.shrink();
                return _IconChip(
                  iconName: iconName,
                  iconData: iconData,
                  isSelected: selectedIcon == iconName,
                  color: previewColor,
                  onTap: () => onIconSelected(iconName),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  List<String> _buildOrderedIcons() {
    final Set<String> result = {};

    // 그룹 필터가 있으면 해당 그룹 아이콘 먼저
    if (filterGroup != null) {
      final groupIcons = CategoryIcon.iconGroups[filterGroup];
      if (groupIcons != null) {
        result.addAll(groupIcons);
      }
    }

    // 나머지 아이콘 추가 (중복 제거)
    for (final entry in CategoryIcon.iconGroups.entries) {
      if (entry.key != filterGroup) {
        result.addAll(entry.value);
      }
    }

    return result.toList();
  }
}

class _IconChip extends StatelessWidget {
  final String iconName;
  final IconData? iconData;
  final String? label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _IconChip({
    required this.iconName,
    this.iconData,
    this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // 선택 시: 선택 색상의 연한 배경 + 색상 아이콘
    // 미선택 시: 밝은 배경 + onSurfaceVariant 아이콘
    final bgColor = isSelected
        ? color.withAlpha(40)
        : colorScheme.surfaceContainerLow;
    final iconColor = isSelected ? color : colorScheme.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: iconData != null
            ? Icon(iconData, size: 22, color: iconColor)
            : Text(
                label ?? '?',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: iconColor,
                ),
              ),
      ),
    );
  }
}

/// 색상 선택 그리드
///
/// 원형 칩 그리드로 색상을 선택할 수 있게 합니다.
/// 선택 시 초록색 외곽선 + 흰색 체크 아이콘 표시
class ColorPicker extends StatelessWidget {
  /// 선택 가능한 색상 팔레트
  final List<String> palette;

  /// 현재 선택된 색상 (#RRGGBB)
  final String selectedColor;

  /// 색상 선택 시 콜백
  final ValueChanged<String> onColorSelected;

  const ColorPicker({
    super.key,
    required this.palette,
    required this.selectedColor,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.categoryColor,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: Spacing.sm),
        SizedBox(
          width: double.infinity,
          child: Wrap(
            spacing: 10,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: palette.map((colorHex) {
              final color = ColorUtils.parseHexColor(colorHex);
              final isSelected = selectedColor == colorHex;
              return GestureDetector(
                onTap: () => onColorSelected(colorHex),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(
                            color: const Color(0xFF2E7D32),
                            width: 2.5,
                          )
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          size: 16,
                          color: Colors.white,
                        )
                      : null,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
