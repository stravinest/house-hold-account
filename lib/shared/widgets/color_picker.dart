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

  // PRD에 정의된 색상 팔레트 (5x2 레이아웃)
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
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
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
