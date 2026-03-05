import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/core/utils/number_format_utils.dart';

void main() {
  group('NumberFormatUtils', () {
    group('currency', () {
      test('천 단위 구분 기호로 숫자를 올바르게 포맷한다', () {
        final formatted = NumberFormatUtils.currency.format(1234567);
        expect(formatted, equals('1,234,567'));
      });

      test('다양한 숫자를 올바르게 포맷한다', () {
        final testCases = {
          0: '0',
          1: '1',
          10: '10',
          100: '100',
          1000: '1,000',
          10000: '10,000',
          100000: '100,000',
          1000000: '1,000,000',
          1234567890: '1,234,567,890',
        };

        testCases.forEach((number, expectedFormat) {
          final formatted = NumberFormatUtils.currency.format(number);
          expect(
            formatted,
            equals(expectedFormat),
            reason: '숫자 $number가 $expectedFormat로 포맷되어야 함',
          );
        });
      });

      test('음수를 올바르게 포맷한다', () {
        final testCases = {
          -1: '-1',
          -100: '-100',
          -1000: '-1,000',
          -1234567: '-1,234,567',
        };

        testCases.forEach((number, expectedFormat) {
          final formatted = NumberFormatUtils.currency.format(number);
          expect(
            formatted,
            equals(expectedFormat),
            reason: '음수 $number가 $expectedFormat로 포맷되어야 함',
          );
        });
      });

      test('소수점 이하는 반올림하여 포맷한다', () {
        final testCases = {
          1234.4: '1,234',
          1234.5: '1,235',
          1234.6: '1,235',
          999.9: '1,000',
          -1234.5: '-1,235',
        };

        testCases.forEach((number, expectedFormat) {
          final formatted = NumberFormatUtils.currency.format(number);
          expect(
            formatted,
            equals(expectedFormat),
            reason: '소수 $number가 $expectedFormat로 포맷되어야 함',
          );
        });
      });

      test('0을 올바르게 포맷한다', () {
        final formatted = NumberFormatUtils.currency.format(0);
        expect(formatted, equals('0'));
      });

      test('매우 큰 숫자를 올바르게 포맷한다', () {
        final testCases = {
          999999999999: '999,999,999,999',
          1000000000000: '1,000,000,000,000',
        };

        testCases.forEach((number, expectedFormat) {
          final formatted = NumberFormatUtils.currency.format(number);
          expect(
            formatted,
            equals(expectedFormat),
            reason: '큰 숫자 $number가 $expectedFormat로 포맷되어야 함',
          );
        });
      });

      test('동일한 인스턴스를 재사용한다', () {
        final instance1 = NumberFormatUtils.currency;
        final instance2 = NumberFormatUtils.currency;
        expect(
          identical(instance1, instance2),
          isTrue,
          reason: '동일한 NumberFormat 인스턴스를 재사용해야 함',
        );
      });

      test('캐시된 인스턴스로 여러 번 포맷해도 올바르게 동작한다', () {
        final formatter = NumberFormatUtils.currency;

        final result1 = formatter.format(1000);
        final result2 = formatter.format(2000);
        final result3 = formatter.format(3000);

        expect(result1, equals('1,000'));
        expect(result2, equals('2,000'));
        expect(result3, equals('3,000'));
      });
    });

    group('compact - 간략화 숫자 포맷', () {
      test('100만 이상은 M 단위로 표기한다', () {
        expect(NumberFormatUtils.compact(1000000), equals('1.0M'));
        expect(NumberFormatUtils.compact(1500000), equals('1.5M'));
        expect(NumberFormatUtils.compact(2000000), equals('2.0M'));
        expect(NumberFormatUtils.compact(10000000), equals('10.0M'));
      });

      test('1000 이상 100만 미만은 K 단위로 표기한다', () {
        expect(NumberFormatUtils.compact(1000), equals('1K'));
        expect(NumberFormatUtils.compact(1500), equals('2K'));
        // (999999 / 1000).toStringAsFixed(0) = '1000' -> '1000K' (구분기호 없음)
        expect(NumberFormatUtils.compact(999999), equals('1000K'));
      });

      test('1000 미만은 천 단위 구분 기호로 포맷한다', () {
        expect(NumberFormatUtils.compact(0), equals('0'));
        expect(NumberFormatUtils.compact(1), equals('1'));
        expect(NumberFormatUtils.compact(999), equals('999'));
        expect(NumberFormatUtils.compact(500), equals('500'));
      });

      test('경계값 1000에서 K 단위로 전환한다', () {
        expect(NumberFormatUtils.compact(999), equals('999'));
        expect(NumberFormatUtils.compact(1000), equals('1K'));
      });

      test('경계값 100만에서 M 단위로 전환한다', () {
        // 999999: K 단위, (999999/1000).toStringAsFixed(0) = '1000' -> '1000K'
        expect(NumberFormatUtils.compact(999999), equals('1000K'));
        expect(NumberFormatUtils.compact(1000000), equals('1.0M'));
      });

      test('소수점 첫째 자리까지 M 단위를 표기한다', () {
        expect(NumberFormatUtils.compact(1100000), equals('1.1M'));
        expect(NumberFormatUtils.compact(1900000), equals('1.9M'));
        expect(NumberFormatUtils.compact(9500000), equals('9.5M'));
      });

      test('K 단위는 소수점 없이 정수로 표기한다', () {
        // toStringAsFixed(0) 사용으로 반올림됨
        expect(NumberFormatUtils.compact(1499), equals('1K'));
        expect(NumberFormatUtils.compact(1500), equals('2K'));
        expect(NumberFormatUtils.compact(9999), equals('10K'));
      });
    });
  });
}
