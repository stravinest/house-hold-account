import 'package:flutter/material.dart';
import '../../core/utils/color_utils.dart';

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
            return _buildColorCircle(color);
          }).toList(),
        ),
        const SizedBox(height: 8),
        // 두 번째 줄 (6개)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: colors.sublist(6, 12).map((color) {
            return _buildColorCircle(color);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildColorCircle(String color) {
    final isSelected = color == selectedColor;
    return GestureDetector(
      onTap: () => onColorSelected(color),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: ColorUtils.parseHexColor(color),
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(color: Colors.black, width: 2)
              : null,
        ),
        child: isSelected
            ? const Icon(Icons.check, color: Colors.white, size: 18)
            : null,
      ),
    );
  }
}
