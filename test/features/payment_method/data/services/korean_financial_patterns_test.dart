import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/payment_method/data/services/korean_financial_patterns.dart';

void main() {
  group('KoreanFinancialPatterns', () {
    group('allPatterns', () {
      test('모든 금융사 패턴이 정의되어 있다', () {
        // Given & When
        final patterns = KoreanFinancialPatterns.allPatterns;

        // Then
        expect(patterns, isNotEmpty);
        expect(patterns.length, greaterThan(20)); // 카드사 + 은행 + 지역화폐
      });

      test('각 패턴에 필수 정보가 포함되어 있다', () {
        // Given & When
        final patterns = KoreanFinancialPatterns.allPatterns;

        // Then: 모든 패턴이 필수 필드를 가지고 있어야 함
        for (final pattern in patterns) {
          expect(pattern.institutionName, isNotEmpty);
          expect(pattern.institutionType, isNotEmpty);
          expect(pattern.senderPatterns, isNotEmpty);
          expect(pattern.amountRegex, isNotEmpty);
          expect(pattern.typeKeywords, isNotEmpty);
        }
      });
    });

    group('findByName', () {
      test('KB국민카드 패턴을 이름으로 찾을 수 있다', () {
        // Given & When
        final pattern = KoreanFinancialPatterns.findByName('KB국민카드');

        // Then
        expect(pattern, isNotNull);
        expect(pattern!.institutionName, equals('KB국민카드'));
        expect(pattern.institutionType, equals('card'));
      });

      test('신한카드 패턴을 이름으로 찾을 수 있다', () {
        // Given & When
        final pattern = KoreanFinancialPatterns.findByName('신한카드');

        // Then
        expect(pattern, isNotNull);
        expect(pattern!.institutionName, equals('신한카드'));
      });

      test('존재하지 않는 금융사 이름은 null을 반환한다', () {
        // Given & When
        final pattern = KoreanFinancialPatterns.findByName('존재하지않는카드');

        // Then
        expect(pattern, isNull);
      });

      test('카카오뱅크 패턴을 이름으로 찾을 수 있다', () {
        // Given & When
        final pattern = KoreanFinancialPatterns.findByName('카카오뱅크');

        // Then
        expect(pattern, isNotNull);
        expect(pattern!.institutionType, equals('bank'));
      });

      test('수원페이 패턴을 이름으로 찾을 수 있다', () {
        // Given & When
        final pattern = KoreanFinancialPatterns.findByName('수원페이');

        // Then
        expect(pattern, isNotNull);
        expect(pattern!.institutionType, equals('local_currency'));
      });
    });

    group('findBySender', () {
      test('KB국민 발신자를 매칭할 수 있다', () {
        // Given & When
        final pattern = KoreanFinancialPatterns.findBySender('KB국민');

        // Then
        expect(pattern, isNotNull);
        expect(pattern!.institutionName, equals('KB국민카드'));
      });

      test('15881688 번호를 KB국민카드로 매칭할 수 있다', () {
        // Given & When
        final pattern = KoreanFinancialPatterns.findBySender('15881688');

        // Then
        expect(pattern, isNotNull);
        expect(pattern!.institutionName, equals('KB국민카드'));
      });

      test('신한카드 발신자를 매칭할 수 있다', () {
        // Given & When
        final pattern = KoreanFinancialPatterns.findBySender('신한카드');

        // Then
        expect(pattern, isNotNull);
        expect(pattern!.institutionName, equals('신한카드'));
      });

      test('경기지역화폐 발신자를 수원페이로 매칭할 수 있다', () {
        // Given & When
        final pattern = KoreanFinancialPatterns.findBySender('경기지역화폐');

        // Then
        expect(pattern, isNotNull);
        // 수원페이가 먼저 매칭됨
        expect(pattern!.senderPatterns, contains('경기지역화폐'));
      });

      test('카카오뱅크 발신자를 매칭할 수 있다', () {
        // Given & When
        final pattern = KoreanFinancialPatterns.findBySender('카카오뱅크');

        // Then
        expect(pattern, isNotNull);
        expect(pattern!.institutionName, equals('카카오뱅크'));
      });

      test('카뱅 발신자를 카카오뱅크로 매칭할 수 있다', () {
        // Given & When
        final pattern = KoreanFinancialPatterns.findBySender('카뱅');

        // Then
        expect(pattern, isNotNull);
        expect(pattern!.institutionName, equals('카카오뱅크'));
      });

      test('대소문자 구분 없이 매칭할 수 있다', () {
        // Given & When
        final pattern1 = KoreanFinancialPatterns.findBySender('toss');
        final pattern2 = KoreanFinancialPatterns.findBySender('TOSS');

        // Then
        expect(pattern1, isNotNull);
        expect(pattern2, isNotNull);
        expect(pattern1!.institutionName, equals(pattern2!.institutionName));
      });

      test('알 수 없는 발신자는 null을 반환한다', () {
        // Given & When
        final pattern = KoreanFinancialPatterns.findBySender('알수없는발신자');

        // Then
        expect(pattern, isNull);
      });
    });

    group('getByType', () {
      test('카드사 타입으로 필터링할 수 있다', () {
        // Given & When
        final cardPatterns = KoreanFinancialPatterns.getByType('card');

        // Then
        expect(cardPatterns, isNotEmpty);
        for (final pattern in cardPatterns) {
          expect(pattern.institutionType, equals('card'));
        }
      });

      test('은행 타입으로 필터링할 수 있다', () {
        // Given & When
        final bankPatterns = KoreanFinancialPatterns.getByType('bank');

        // Then
        expect(bankPatterns, isNotEmpty);
        for (final pattern in bankPatterns) {
          expect(pattern.institutionType, equals('bank'));
        }
      });

      test('지역화폐 타입으로 필터링할 수 있다', () {
        // Given & When
        final localPatterns = KoreanFinancialPatterns.getByType('local_currency');

        // Then
        expect(localPatterns, isNotEmpty);
        for (final pattern in localPatterns) {
          expect(pattern.institutionType, equals('local_currency'));
        }
      });
    });

    group('cardPatterns', () {
      test('카드사 목록을 올바르게 반환한다', () {
        // Given & When
        final cards = KoreanFinancialPatterns.cardPatterns;

        // Then
        expect(cards, isNotEmpty);
        expect(cards, contains(KoreanFinancialPatterns.kbCard));
        expect(cards, contains(KoreanFinancialPatterns.shinhanCard));
        expect(cards, contains(KoreanFinancialPatterns.samsungCard));
      });

      test('모든 카드사 패턴이 card 타입이다', () {
        // Given & When
        final cards = KoreanFinancialPatterns.cardPatterns;

        // Then
        for (final card in cards) {
          expect(card.institutionType, equals('card'));
        }
      });
    });

    group('bankPatterns', () {
      test('은행 목록을 올바르게 반환한다', () {
        // Given & When
        final banks = KoreanFinancialPatterns.bankPatterns;

        // Then
        expect(banks, isNotEmpty);
        expect(banks, contains(KoreanFinancialPatterns.kbBank));
        expect(banks, contains(KoreanFinancialPatterns.kakaoBank));
        expect(banks, contains(KoreanFinancialPatterns.tossBank));
      });

      test('모든 은행 패턴이 bank 타입이다', () {
        // Given & When
        final banks = KoreanFinancialPatterns.bankPatterns;

        // Then
        for (final bank in banks) {
          expect(bank.institutionType, equals('bank'));
        }
      });
    });

    group('localCurrencyPatterns', () {
      test('지역화폐 목록을 올바르게 반환한다', () {
        // Given & When
        final localCurrencies = KoreanFinancialPatterns.localCurrencyPatterns;

        // Then
        expect(localCurrencies, isNotEmpty);
        expect(localCurrencies, contains(KoreanFinancialPatterns.suwonPay));
        expect(localCurrencies, contains(KoreanFinancialPatterns.seoulPay));
      });

      test('모든 지역화폐 패턴이 local_currency 타입이다', () {
        // Given & When
        final localCurrencies = KoreanFinancialPatterns.localCurrencyPatterns;

        // Then
        for (final currency in localCurrencies) {
          expect(currency.institutionType, equals('local_currency'));
        }
      });
    });

    group('FinancialSmsFormat', () {
      test('KB국민카드 패턴이 올바른 정보를 가지고 있다', () {
        // Given & When
        final kb = KoreanFinancialPatterns.kbCard;

        // Then
        expect(kb.institutionName, equals('KB국민카드'));
        expect(kb.institutionType, equals('card'));
        expect(kb.senderPatterns, contains('KB국민'));
        expect(kb.senderPatterns, contains('15881688'));
        expect(kb.typeKeywords['expense'], contains('승인'));
        expect(kb.typeKeywords['income'], contains('환불'));
        expect(kb.amountRegex, isNotEmpty);
      });

      test('카카오뱅크 패턴이 올바른 정보를 가지고 있다', () {
        // Given & When
        final kakao = KoreanFinancialPatterns.kakaoBank;

        // Then
        expect(kakao.institutionName, equals('카카오뱅크'));
        expect(kakao.institutionType, equals('bank'));
        expect(kakao.senderPatterns, contains('카카오뱅크'));
        expect(kakao.senderPatterns, contains('카뱅'));
        expect(kakao.typeKeywords['expense'], contains('출금'));
        expect(kakao.typeKeywords['income'], contains('입금'));
      });

      test('수원페이 패턴이 올바른 정보를 가지고 있다', () {
        // Given & When
        final suwon = KoreanFinancialPatterns.suwonPay;

        // Then
        expect(suwon.institutionName, equals('수원페이'));
        expect(suwon.institutionType, equals('local_currency'));
        expect(suwon.senderPatterns, contains('수원페이'));
        expect(suwon.senderPatterns, contains('경기지역화폐'));
        expect(suwon.typeKeywords['expense'], contains('결제'));
        expect(suwon.typeKeywords['income'], contains('충전'));
      });

      test('금액 정규식이 다양한 포맷을 매칭할 수 있다', () {
        // Given
        final pattern = KoreanFinancialPatterns.kbCard;
        final amountRegex = RegExp(pattern.amountRegex);

        // When & Then: 다양한 금액 포맷 테스트
        expect(amountRegex.hasMatch('50,000원'), isTrue);
        expect(amountRegex.hasMatch('5000원'), isTrue);
        expect(amountRegex.hasMatch('1,234,567원'), isTrue);
        expect(amountRegex.hasMatch('100 원'), isTrue);
      });
    });
  });
}
