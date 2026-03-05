import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/core/utils/korean_amount_formatter.dart';

void main() {
  group('formatKoreanAmount - 한글 금액 변환 테스트', () {
    test('0 이하의 금액은 빈 문자열을 반환해야 한다', () {
      expect(formatKoreanAmount(0), '');
      expect(formatKoreanAmount(-1000), '');
    });

    test('1만원 미만의 금액은 원 단위로 표시해야 한다', () {
      expect(formatKoreanAmount(500), '500원');
      expect(formatKoreanAmount(5000), '5,000원');
      expect(formatKoreanAmount(9999), '9,999원');
    });

    test('1만원 이상 1억 미만의 금액은 만원 단위로 표시해야 한다', () {
      expect(formatKoreanAmount(10000), '1만원');
      expect(formatKoreanAmount(50000), '5만원');
      expect(formatKoreanAmount(100000), '10만원');
      expect(formatKoreanAmount(1000000), '100만원');
      expect(formatKoreanAmount(35000000), '3,500만원');
      expect(formatKoreanAmount(99990000), '9,999만원');
    });

    test('만원 단위에서 나머지가 있는 경우 함께 표시해야 한다', () {
      expect(formatKoreanAmount(15000), '1만 5,000원');
      expect(formatKoreanAmount(12345), '1만 2,345원');
      expect(formatKoreanAmount(50500), '5만 500원');
    });

    test('1억 이상의 금액은 억원 단위로 표시해야 한다', () {
      expect(formatKoreanAmount(100000000), '1억원');
      expect(formatKoreanAmount(500000000), '5억원');
      expect(formatKoreanAmount(1000000000), '10억원');
    });

    test('억과 만이 모두 있는 경우 함께 표시해야 한다', () {
      expect(formatKoreanAmount(150000000), '1억 5,000만원');
      expect(formatKoreanAmount(350000000), '3억 5,000만원');
      expect(formatKoreanAmount(123450000), '1억 2,345만원');
      expect(formatKoreanAmount(100010000), '1억 1만원');
    });

    test('억만 있고 만 이하가 0인 경우 억원만 표시해야 한다', () {
      expect(formatKoreanAmount(200000000), '2억원');
      expect(formatKoreanAmount(1000000000), '10억원');
    });

    test('억과 원 단위만 있는 경우 (만 단위가 0)', () {
      expect(formatKoreanAmount(100005000), '1억 5,000원');
    });

    test('대출에서 자주 사용되는 금액을 올바르게 변환해야 한다', () {
      expect(formatKoreanAmount(30000000), '3,000만원');
      expect(formatKoreanAmount(200000000), '2억원');
      expect(formatKoreanAmount(350000000), '3억 5,000만원');
      expect(formatKoreanAmount(500000000), '5억원');
    });
  });
}
