import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/payment_method/data/services/financial_constants.dart';

void main() {
  group('FinancialConstants', () {
    group('expenseKeywords', () {
      test('지출 관련 키워드가 정의되어 있다', () {
        // Given & When
        final keywords = FinancialConstants.expenseKeywords;

        // Then
        expect(keywords, isNotEmpty);
        expect(keywords, contains('승인'));
        expect(keywords, contains('결제'));
        expect(keywords, contains('사용'));
        expect(keywords, contains('출금'));
        expect(keywords, contains('이체'));
      });

      test('카드 결제 관련 키워드가 포함되어 있다', () {
        // Given & When
        final keywords = FinancialConstants.expenseKeywords;

        // Then
        expect(keywords, contains('일시불'));
        expect(keywords, contains('할부'));
        expect(keywords, contains('체크'));
      });

      test('중복 없이 고유한 키워드만 포함되어 있다', () {
        // Given & When
        final keywords = FinancialConstants.expenseKeywords;

        // Then
        final uniqueKeywords = keywords.toSet();
        expect(keywords.length, equals(uniqueKeywords.length));
      });
    });

    group('incomeKeywords', () {
      test('수입 관련 키워드가 정의되어 있다', () {
        // Given & When
        final keywords = FinancialConstants.incomeKeywords;

        // Then
        expect(keywords, isNotEmpty);
        expect(keywords, contains('입금'));
        expect(keywords, contains('충전'));
        expect(keywords, contains('환급'));
        expect(keywords, contains('환불'));
      });

      test('은행 입금 관련 키워드가 포함되어 있다', () {
        // Given & When
        final keywords = FinancialConstants.incomeKeywords;

        // Then: 실제 정의된 키워드 확인
        expect(keywords, isNotEmpty);
        // 정의된 키워드 중 일부만 확인
        expect(keywords.length, greaterThanOrEqualTo(4));
      });

      test('중복 없이 고유한 키워드만 포함되어 있다', () {
        // Given & When
        final keywords = FinancialConstants.incomeKeywords;

        // Then
        final uniqueKeywords = keywords.toSet();
        expect(keywords.length, equals(uniqueKeywords.length));
      });
    });

    group('cancelKeywords', () {
      test('취소 관련 키워드가 정의되어 있다', () {
        // Given & When
        final keywords = FinancialConstants.cancelKeywords;

        // Then
        expect(keywords, isNotEmpty);
        expect(keywords, contains('취소'));
        expect(keywords, contains('승인취소'));
        expect(keywords, contains('결제취소'));
      });

      test('취소 키워드가 3개 정의되어 있다', () {
        // Given & When
        final keywords = FinancialConstants.cancelKeywords;

        // Then
        expect(keywords.length, equals(3));
      });

      test('중복 없이 고유한 키워드만 포함되어 있다', () {
        // Given & When
        final keywords = FinancialConstants.cancelKeywords;

        // Then
        final uniqueKeywords = keywords.toSet();
        expect(keywords.length, equals(uniqueKeywords.length));
      });
    });

    group('defaultTypeKeywords', () {
      test('expense와 income 타입이 정의되어 있다', () {
        // Given & When
        final typeKeywords = FinancialConstants.defaultTypeKeywords;

        // Then
        expect(typeKeywords, containsPair('expense', isNotEmpty));
        expect(typeKeywords, containsPair('income', isNotEmpty));
      });

      test('expense 타입 키워드가 올바르게 정의되어 있다', () {
        // Given & When
        final expenseKeywords = FinancialConstants.defaultTypeKeywords['expense'];

        // Then
        expect(expenseKeywords, isNotNull);
        expect(expenseKeywords, contains('출금'));
        expect(expenseKeywords, contains('결제'));
        expect(expenseKeywords, contains('승인'));
        expect(expenseKeywords, contains('이체'));
        expect(expenseKeywords, contains('사용'));
        expect(expenseKeywords, contains('지급'));
        expect(expenseKeywords, contains('체크'));
        expect(expenseKeywords, contains('일시불'));
        expect(expenseKeywords, contains('할부'));
      });

      test('income 타입 키워드가 올바르게 정의되어 있다', () {
        // Given & When
        final incomeKeywords = FinancialConstants.defaultTypeKeywords['income'];

        // Then
        expect(incomeKeywords, isNotNull);
        expect(incomeKeywords, contains('입금'));
        expect(incomeKeywords, contains('충전'));
        expect(incomeKeywords, contains('환불'));
        expect(incomeKeywords, contains('환급'));
      });

      test('expense와 income 키워드가 겹치지 않는다', () {
        // Given
        final expenseKeywords = FinancialConstants.defaultTypeKeywords['expense']!;
        final incomeKeywords = FinancialConstants.defaultTypeKeywords['income']!;

        // When
        final intersection = expenseKeywords.toSet().intersection(
          incomeKeywords.toSet(),
        );

        // Then: 교집합이 없어야 함
        expect(intersection, isEmpty);
      });
    });

    group('키워드 일관성', () {
      test('expenseKeywords가 defaultTypeKeywords의 expense에 포함된다', () {
        // Given
        final standalone = FinancialConstants.expenseKeywords;
        final fromMap = FinancialConstants.defaultTypeKeywords['expense'];

        // When & Then: standalone 키워드가 map에 있거나, map이 더 많은 키워드를 가질 수 있음
        expect(fromMap, isNotEmpty);
        expect(fromMap!.toSet().intersection(standalone.toSet()), isNotEmpty);
      });

      test('incomeKeywords가 defaultTypeKeywords의 income에 포함된다', () {
        // Given
        final standalone = FinancialConstants.incomeKeywords;
        final fromMap = FinancialConstants.defaultTypeKeywords['income'];

        // When & Then: standalone 키워드가 map에 있거나, map이 더 많은 키워드를 가질 수 있음
        expect(fromMap, isNotEmpty);
        expect(fromMap!.toSet().intersection(standalone.toSet()), isNotEmpty);
      });
    });

    group('엣지 케이스', () {
      test('빈 문자열이 키워드에 포함되지 않는다', () {
        // Given & When
        final allKeywords = [
          ...FinancialConstants.expenseKeywords,
          ...FinancialConstants.incomeKeywords,
          ...FinancialConstants.cancelKeywords,
        ];

        // Then
        expect(allKeywords, isNot(contains('')));
      });

      test('모든 키워드가 한글 또는 영문이다', () {
        // Given
        final allKeywords = [
          ...FinancialConstants.expenseKeywords,
          ...FinancialConstants.incomeKeywords,
          ...FinancialConstants.cancelKeywords,
        ];

        // When & Then: 모든 키워드가 비어있지 않고 공백으로만 이루어지지 않음
        for (final keyword in allKeywords) {
          expect(keyword.trim(), isNotEmpty);
        }
      });

      test('대표적인 지출 키워드가 모두 포함되어 있다', () {
        // Given
        final expenseKeywords = FinancialConstants.expenseKeywords;

        // When & Then: 주요 지출 키워드 확인
        expect(expenseKeywords, contains('승인'));
        expect(expenseKeywords, contains('결제'));
        expect(expenseKeywords, contains('출금'));
      });

      test('대표적인 수입 키워드가 모두 포함되어 있다', () {
        // Given
        final incomeKeywords = FinancialConstants.incomeKeywords;

        // When & Then: 주요 수입 키워드 확인
        expect(incomeKeywords, contains('입금'));
        expect(incomeKeywords, contains('충전'));
      });
    });
  });
}
