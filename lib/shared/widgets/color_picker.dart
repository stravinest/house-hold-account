import 'package:flutter/material.dart';
import '../../core/utils/color_utils.dart';
import '../themes/design_tokens.dart';

class ColorPicker extends StatelessWidget {
  final String selectedColor;
  final ValueChanged<String> onColorSelected;

  const ColorPicker({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
  });

  // 색상 팔레트 (6x2 레이아웃, 12개)
  static const List<String> colors = [
    '#A8D8EA', // 파스텔 블루 (기본값)
    '#FFB6A3', // 코랄 오렌지
    '#B8E6C9', // 민트 그린
    '#D4A5D4', // 라벤더
    '#FFCBA4', // 피치
    '#F8B4D9', // 핑크
    '#C9A9DC', // 연보라
    '#B4D4FF', // 스카이 블루
    '#FFE5B4', // 크림
    '#D4F4DD', // 라임
    '#FFFACD', // 파스텔 옐로우
    '#E0FFFF', // 파스텔 시안
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 첫 번째 줄 (6개)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: colors.sublist(0, 6).map((color) {
            return _buildColorCircle(context, color);
          }).toList(),
        ),
        const SizedBox(height: Spacing.sm),
        // 두 번째 줄 (6개)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: colors.sublist(6, 12).map((color) {
            return _buildColorCircle(context, color);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildColorCircle(BuildContext context, String color) {
    final isSelected = color == selectedColor;
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onColorSelected(color),
        customBorder: const CircleBorder(),
        child: Container(
          width: TouchTarget.minimum,
          height: TouchTarget.minimum,
          alignment: Alignment.center,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: ColorUtils.parseHexColor(color),
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(color: colorScheme.onSurface, width: 2)
                  : null,
            ),
            child: isSelected
                ? Icon(
                    Icons.check,
                    color: colorScheme.onSurface,
                    size: IconSize.sm,
                  )
                : null,
          ),
        ),
      ),
    );
  }
}
