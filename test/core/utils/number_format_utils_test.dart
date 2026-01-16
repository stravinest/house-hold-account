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
          expect(formatted, equals(expectedFormat),
              reason: '숫자 $number가 $expectedFormat로 포맷되어야 함');
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
          expect(formatted, equals(expectedFormat),
              reason: '음수 $number가 $expectedFormat로 포맷되어야 함');
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
          expect(formatted, equals(expectedFormat),
              reason: '소수 $number가 $expectedFormat로 포맷되어야 함');
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
          expect(formatted, equals(expectedFormat),
              reason: '큰 숫자 $number가 $expectedFormat로 포맷되어야 함');
        });
      });

      test('동일한 인스턴스를 재사용한다', () {
        final instance1 = NumberFormatUtils.currency;
        final instance2 = NumberFormatUtils.currency;
        expect(identical(instance1, instance2), isTrue,
            reason: '동일한 NumberFormat 인스턴스를 재사용해야 함');
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
  });
}
