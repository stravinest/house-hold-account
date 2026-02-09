import 'package:flutter/material.dart';

/// HEX 색상 코드와 Color 객체 간 변환을 처리하는 유틸리티 클래스
class ColorUtils {
  /// 기본 색상: 파스텔 블루 (#A8D8EA)
  static const Color defaultColor = Color(0xFFA8D8EA);

  /// HEX 색상 코드를 Color 객체로 변환
  ///
  /// 지원 형식: #RRGGBB, #RRGGBBAA, RRGGBB
  /// 파싱 실패 시 [fallback] 또는 기본 색상 반환
  static Color parseHexColor(String? hexColor, {Color? fallback}) {
    if (hexColor == null || hexColor.isEmpty) {
      return fallback ?? defaultColor;
    }
    try {
      final cleaned = hexColor.replaceFirst('#', '');
      if (cleaned.length == 6) {
        return Color(int.parse('FF$cleaned', radix: 16));
      }
      if (cleaned.length == 8) {
        // RRGGBBAA -> AARRGGBB
        final alpha = cleaned.substring(6, 8);
        final rgb = cleaned.substring(0, 6);
        return Color(int.parse('$alpha$rgb', radix: 16));
      }
      return fallback ?? defaultColor;
    } catch (e) {
      return fallback ?? defaultColor;
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
