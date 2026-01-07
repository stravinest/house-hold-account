import 'package:flutter/material.dart';

/// HEX 색상 코드와 Color 객체 간 변환을 처리하는 유틸리티 클래스
class ColorUtils {
  /// 기본 색상: 파스텔 블루 (#A8D8EA)
  static const Color defaultColor = Color(0xFFA8D8EA);

  /// HEX 색상 코드를 Color 객체로 변환
  ///
  /// [hexColor] 형식: #RRGGBB (예: #A8D8EA)
  /// 파싱 실패 시 기본 색상 반환
  static Color parseHexColor(String hexColor) {
    try {
      // HEX 코드 유효성 검사: #으로 시작하고 정확히 7자리여야 함
      if (!hexColor.startsWith('#') || hexColor.length != 7) {
        return defaultColor;
      }
      return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
    } catch (e) {
      return defaultColor;
    }
  }

  /// Color 객체를 HEX 코드로 변환
  ///
  /// 반환 형식: #RRGGBB (예: #A8D8EA)
  static String colorToHex(Color color) {
    final argb = color.toARGB32();
    return '#${argb.toRadixString(16).substring(2).toUpperCase()}';
  }
}
