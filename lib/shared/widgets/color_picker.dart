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

  // PRD에 정의된 색상 팔레트
  static const List<String> colors = [
    '#A8D8EA', // 파스텔 블루 (기본값)
    '#FFB6A3', // 코랄 오렌지
    '#B8E6C9', // 민트 그린
    '#D4A5D4', // 라벤더
    '#FFCBA4', // 피치
    '#FFD6A5', // 복숭아
    '#C9A9DC', // 연보라
    '#A8E6CF', // 민트
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: colors.map((color) {
        final isSelected = color == selectedColor;
        return GestureDetector(
          onTap: () => onColorSelected(color),
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: ColorUtils.parseHexColor(color),
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(color: Colors.black, width: 3)
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white)
                : null,
          ),
        );
      }).toList(),
    );
  }
}
