import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/shared/themes/design_tokens.dart';

void main() {
  group('Spacing', () {
    test('xs는 4.0이다', () {
      expect(Spacing.xs, equals(4.0));
    });

    test('sm은 8.0이다', () {
      expect(Spacing.sm, equals(8.0));
    });

    test('md는 16.0이다', () {
      expect(Spacing.md, equals(16.0));
    });

    test('lg는 24.0이다', () {
      expect(Spacing.lg, equals(24.0));
    });

    test('xl은 32.0이다', () {
      expect(Spacing.xl, equals(32.0));
    });

    test('xxl은 48.0이다', () {
      expect(Spacing.xxl, equals(48.0));
    });

    test('간격 값이 오름차순으로 정렬되어 있다', () {
      expect(Spacing.xs, lessThan(Spacing.sm));
      expect(Spacing.sm, lessThan(Spacing.md));
      expect(Spacing.md, lessThan(Spacing.lg));
      expect(Spacing.lg, lessThan(Spacing.xl));
      expect(Spacing.xl, lessThan(Spacing.xxl));
    });
  });

  group('BorderRadiusToken', () {
    test('xs는 4.0이다', () {
      expect(BorderRadiusToken.xs, equals(4.0));
    });

    test('sm은 8.0이다', () {
      expect(BorderRadiusToken.sm, equals(8.0));
    });

    test('md는 12.0이다', () {
      expect(BorderRadiusToken.md, equals(12.0));
    });

    test('lg는 16.0이다', () {
      expect(BorderRadiusToken.lg, equals(16.0));
    });

    test('xl은 20.0이다', () {
      expect(BorderRadiusToken.xl, equals(20.0));
    });

    test('circular는 9999.0이다', () {
      expect(BorderRadiusToken.circular, equals(9999.0));
    });

    test('반경 값이 오름차순으로 정렬되어 있다', () {
      expect(BorderRadiusToken.xs, lessThan(BorderRadiusToken.sm));
      expect(BorderRadiusToken.sm, lessThan(BorderRadiusToken.md));
      expect(BorderRadiusToken.md, lessThan(BorderRadiusToken.lg));
      expect(BorderRadiusToken.lg, lessThan(BorderRadiusToken.xl));
      expect(BorderRadiusToken.xl, lessThan(BorderRadiusToken.circular));
    });
  });

  group('Elevation', () {
    test('none은 0.0이다', () {
      expect(Elevation.none, equals(0.0));
    });

    test('low는 1.0이다', () {
      expect(Elevation.low, equals(1.0));
    });

    test('medium은 2.0이다', () {
      expect(Elevation.medium, equals(2.0));
    });

    test('high는 4.0이다', () {
      expect(Elevation.high, equals(4.0));
    });

    test('veryHigh는 8.0이다', () {
      expect(Elevation.veryHigh, equals(8.0));
    });

    test('고도 값이 오름차순으로 정렬되어 있다', () {
      expect(Elevation.none, lessThan(Elevation.low));
      expect(Elevation.low, lessThan(Elevation.medium));
      expect(Elevation.medium, lessThan(Elevation.high));
      expect(Elevation.high, lessThan(Elevation.veryHigh));
    });
  });

  group('IconSize', () {
    test('xs는 16.0이다', () {
      expect(IconSize.xs, equals(16.0));
    });

    test('sm은 20.0이다', () {
      expect(IconSize.sm, equals(20.0));
    });

    test('md는 24.0이다', () {
      expect(IconSize.md, equals(24.0));
    });

    test('lg는 32.0이다', () {
      expect(IconSize.lg, equals(32.0));
    });

    test('xl은 48.0이다', () {
      expect(IconSize.xl, equals(48.0));
    });

    test('xxl은 64.0이다', () {
      expect(IconSize.xxl, equals(64.0));
    });

    test('아이콘 크기 값이 오름차순으로 정렬되어 있다', () {
      expect(IconSize.xs, lessThan(IconSize.sm));
      expect(IconSize.sm, lessThan(IconSize.md));
      expect(IconSize.md, lessThan(IconSize.lg));
      expect(IconSize.lg, lessThan(IconSize.xl));
      expect(IconSize.xl, lessThan(IconSize.xxl));
    });
  });

  group('TouchTarget', () {
    test('minimum은 44.0이다', () {
      expect(TouchTarget.minimum, equals(44.0));
    });

    test('recommended는 48.0이다', () {
      expect(TouchTarget.recommended, equals(48.0));
    });

    test('large는 56.0이다', () {
      expect(TouchTarget.large, equals(56.0));
    });

    test('터치 영역 크기가 오름차순으로 정렬되어 있다', () {
      expect(TouchTarget.minimum, lessThan(TouchTarget.recommended));
      expect(TouchTarget.recommended, lessThan(TouchTarget.large));
    });

    test('recommended는 Material 가이드라인 최소값 48을 만족한다', () {
      expect(TouchTarget.recommended, greaterThanOrEqualTo(48.0));
    });
  });

  group('AnimationDuration', () {
    test('duration100은 100ms이다', () {
      expect(
        AnimationDuration.duration100,
        equals(const Duration(milliseconds: 100)),
      );
    });

    test('duration200은 200ms이다', () {
      expect(
        AnimationDuration.duration200,
        equals(const Duration(milliseconds: 200)),
      );
    });

    test('duration300은 300ms이다', () {
      expect(
        AnimationDuration.duration300,
        equals(const Duration(milliseconds: 300)),
      );
    });

    test('duration500은 500ms이다', () {
      expect(
        AnimationDuration.duration500,
        equals(const Duration(milliseconds: 500)),
      );
    });

    test('duration1000은 1000ms이다', () {
      expect(
        AnimationDuration.duration1000,
        equals(const Duration(milliseconds: 1000)),
      );
    });

    test('애니메이션 지속 시간이 오름차순으로 정렬되어 있다', () {
      expect(
        AnimationDuration.duration100,
        lessThan(AnimationDuration.duration200),
      );
      expect(
        AnimationDuration.duration200,
        lessThan(AnimationDuration.duration300),
      );
      expect(
        AnimationDuration.duration300,
        lessThan(AnimationDuration.duration500),
      );
      expect(
        AnimationDuration.duration500,
        lessThan(AnimationDuration.duration1000),
      );
    });
  });

  group('SnackBarDuration', () {
    test('short는 2초이다', () {
      expect(SnackBarDuration.short, equals(const Duration(seconds: 2)));
    });

    test('medium은 4초이다', () {
      expect(SnackBarDuration.medium, equals(const Duration(seconds: 4)));
    });

    test('long은 6초이다', () {
      expect(SnackBarDuration.long, equals(const Duration(seconds: 6)));
    });

    test('SnackBar 표시 시간이 오름차순으로 정렬되어 있다', () {
      expect(SnackBarDuration.short, lessThan(SnackBarDuration.medium));
      expect(SnackBarDuration.medium, lessThan(SnackBarDuration.long));
    });
  });

  group('PaymentMethodColors', () {
    test('팔레트가 비어있지 않다', () {
      expect(PaymentMethodColors.palette, isNotEmpty);
    });

    test('팔레트에 12개의 색상이 있다', () {
      expect(PaymentMethodColors.palette.length, equals(12));
    });

    test('모든 색상이 # 으로 시작하는 HEX 형식이다', () {
      for (final color in PaymentMethodColors.palette) {
        expect(
          color,
          matches(RegExp(r'^#[0-9A-Fa-f]{6}$')),
          reason: '$color 는 올바른 HEX 형식이 아니다',
        );
      }
    });

    test('팔레트에 Green 색상이 포함되어 있다', () {
      expect(PaymentMethodColors.palette, contains('#4CAF50'));
    });

    test('팔레트에 Blue 색상이 포함되어 있다', () {
      expect(PaymentMethodColors.palette, contains('#2196F3'));
    });

    test('팔레트에 중복 색상이 없다', () {
      final unique = PaymentMethodColors.palette.toSet();
      expect(unique.length, equals(PaymentMethodColors.palette.length));
    });
  });

  group('CategoryColorPalette', () {
    test('팔레트가 비어있지 않다', () {
      expect(CategoryColorPalette.palette, isNotEmpty);
    });

    test('팔레트에 12개의 색상이 있다', () {
      expect(CategoryColorPalette.palette.length, equals(12));
    });

    test('모든 색상이 # 으로 시작하는 HEX 형식이다', () {
      for (final color in CategoryColorPalette.palette) {
        expect(
          color,
          matches(RegExp(r'^#[0-9A-Fa-f]{6}$')),
          reason: '$color 는 올바른 HEX 형식이 아니다',
        );
      }
    });

    test('팔레트에 중복 색상이 없다', () {
      final unique = CategoryColorPalette.palette.toSet();
      expect(unique.length, equals(CategoryColorPalette.palette.length));
    });
  });

  group('FixedExpenseColors', () {
    test('lightBackground 색상값이 올바르다', () {
      expect(FixedExpenseColors.lightBackground, equals(const Color(0xFFFFE0B2)));
    });

    test('lightForeground 색상값이 올바르다', () {
      expect(FixedExpenseColors.lightForeground, equals(const Color(0xFFE65100)));
    });

    test('darkBackground 색상값이 올바르다', () {
      expect(FixedExpenseColors.darkBackground, equals(const Color(0xFF4E2C00)));
    });

    test('darkForeground 색상값이 올바르다', () {
      expect(FixedExpenseColors.darkForeground, equals(const Color(0xFFFFCC80)));
    });

    test('라이트 모드와 다크 모드 색상이 서로 다르다', () {
      expect(
        FixedExpenseColors.lightBackground,
        isNot(equals(FixedExpenseColors.darkBackground)),
      );
      expect(
        FixedExpenseColors.lightForeground,
        isNot(equals(FixedExpenseColors.darkForeground)),
      );
    });
  });
}
