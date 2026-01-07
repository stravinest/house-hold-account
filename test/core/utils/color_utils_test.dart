import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/core/utils/color_utils.dart';

void main() {
  group('ColorUtils', () {
    group('parseHexColor', () {
      test('유효한 HEX 색상 코드를 올바르게 파싱한다', () {
        final color = ColorUtils.parseHexColor('#A8D8EA');
        expect(color, equals(const Color(0xFFA8D8EA)));
      });

      test('다양한 유효한 HEX 색상 코드를 올바르게 파싱한다', () {
        final testCases = {
          '#FFFFFF': const Color(0xFFFFFFFF),
          '#000000': const Color(0xFF000000),
          '#FF0000': const Color(0xFFFF0000),
          '#00FF00': const Color(0xFF00FF00),
          '#0000FF': const Color(0xFF0000FF),
        };

        testCases.forEach((hex, expectedColor) {
          final color = ColorUtils.parseHexColor(hex);
          expect(color, equals(expectedColor), reason: 'HEX $hex가 올바르게 파싱되어야 함');
        });
      });

      test('소문자 HEX 색상 코드를 올바르게 파싱한다', () {
        final color = ColorUtils.parseHexColor('#a8d8ea');
        expect(color, equals(const Color(0xFFA8D8EA)));
      });

      test('잘못된 HEX 코드는 기본 색상을 반환한다', () {
        final invalidCases = [
          'invalid',
          '#GGGGGG',
          '#12345',
          '#1234567',
          '',
          'A8D8EA',
          '#',
        ];

        for (final invalidHex in invalidCases) {
          final color = ColorUtils.parseHexColor(invalidHex);
          expect(color, equals(ColorUtils.defaultColor),
            reason: '잘못된 HEX 코드 "$invalidHex"는 기본 색상을 반환해야 함');
        }
      });

      test('null 문자열은 기본 색상을 반환한다', () {
        final color = ColorUtils.parseHexColor('null');
        expect(color, equals(ColorUtils.defaultColor));
      });

      test('빈 문자열은 기본 색상을 반환한다', () {
        final color = ColorUtils.parseHexColor('');
        expect(color, equals(ColorUtils.defaultColor));
      });

      test('# 없는 HEX 코드는 기본 색상을 반환한다', () {
        final color = ColorUtils.parseHexColor('A8D8EA');
        expect(color, equals(ColorUtils.defaultColor));
      });
    });

    group('colorToHex', () {
      test('Color 객체를 HEX 코드로 올바르게 변환한다', () {
        const color = Color(0xFFA8D8EA);
        final hex = ColorUtils.colorToHex(color);
        expect(hex, equals('#A8D8EA'));
      });

      test('다양한 Color 객체를 HEX 코드로 올바르게 변환한다', () {
        final testCases = {
          const Color(0xFFFFFFFF): '#FFFFFF',
          const Color(0xFF000000): '#000000',
          const Color(0xFFFF0000): '#FF0000',
          const Color(0xFF00FF00): '#00FF00',
          const Color(0xFF0000FF): '#0000FF',
        };

        testCases.forEach((color, expectedHex) {
          final hex = ColorUtils.colorToHex(color);
          expect(hex, equals(expectedHex), reason: 'Color $color가 올바르게 변환되어야 함');
        });
      });

      test('변환된 HEX 코드를 다시 파싱하면 원래 색상이 된다', () {
        const originalColor = Color(0xFFA8D8EA);
        final hex = ColorUtils.colorToHex(originalColor);
        final parsedColor = ColorUtils.parseHexColor(hex);
        expect(parsedColor, equals(originalColor));
      });
    });

    group('defaultColor', () {
      test('기본 색상은 파스텔 블루(#A8D8EA)이다', () {
        expect(ColorUtils.defaultColor, equals(const Color(0xFFA8D8EA)));
      });
    });
  });
}
