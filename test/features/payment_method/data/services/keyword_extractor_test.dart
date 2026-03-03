import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/payment_method/data/services/keyword_extractor.dart';

void main() {
  group('KeywordExtractor', () {
    test('일반 거래 제목에서 키워드를 올바르게 추출해야 한다', () {
      final result = KeywordExtractor.extract('스타벅스 강남점');
      expect(result, ['스타벅스', '강남점']);
    });

    test('순수 숫자만 있는 단어는 제외해야 한다', () {
      final result = KeywordExtractor.extract('스타벅스 3000');
      expect(result, ['스타벅스']);
    });

    test('날짜 패턴(yyyy-MM-dd)을 제외해야 한다', () {
      final result = KeywordExtractor.extract('스타벅스 2026-03-03');
      expect(result, ['스타벅스']);
    });

    test('날짜 패턴(MM/dd)을 제외해야 한다', () {
      final result = KeywordExtractor.extract('스타벅스 03/03');
      expect(result, ['스타벅스']);
    });

    test('날짜 패턴(MM.dd)을 제외해야 한다', () {
      final result = KeywordExtractor.extract('스타벅스 03.03');
      expect(result, ['스타벅스']);
    });

    test('금액(원) 패턴을 제외해야 한다', () {
      final result = KeywordExtractor.extract('스타벅스 5000원');
      expect(result, ['스타벅스']);
    });

    test('시간 패턴(HH:mm)을 제외해야 한다', () {
      final result = KeywordExtractor.extract('스타벅스 14:30');
      expect(result, ['스타벅스']);
    });

    test('1글자 단어는 제외해야 한다', () {
      final result = KeywordExtractor.extract('스타벅스 A 강남점');
      expect(result, ['스타벅스', '강남점']);
    });

    test('null 입력 시 빈 리스트를 반환해야 한다', () {
      final result = KeywordExtractor.extract(null);
      expect(result, isEmpty);
    });

    test('빈 문자열 입력 시 빈 리스트를 반환해야 한다', () {
      final result = KeywordExtractor.extract('');
      expect(result, isEmpty);
    });

    test('공백만 있는 문자열 입력 시 빈 리스트를 반환해야 한다', () {
      final result = KeywordExtractor.extract('   ');
      expect(result, isEmpty);
    });

    test('중복 단어는 제거해야 한다', () {
      final result = KeywordExtractor.extract('스타벅스 스타벅스 강남점');
      expect(result, ['스타벅스', '강남점']);
    });

    test('복합 필터링: 숫자, 날짜, 시간, 금액이 섞인 제목에서 키워드만 추출해야 한다', () {
      final result =
          KeywordExtractor.extract('KB국민카드 스타벅스 5000원 2026-03-03 14:30');
      expect(result, ['KB국민카드', '스타벅스']);
    });
  });
}
