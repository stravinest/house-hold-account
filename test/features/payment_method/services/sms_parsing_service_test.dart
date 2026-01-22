import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/payment_method/data/services/sms_parsing_service.dart';

void main() {
  group('SmsParsingService', () {
    group('parseSms - KB국민카드 SMS 파싱', () {
      test('일시불 결제 SMS에서 금액, 상호명, 거래유형을 정확히 추출해야 한다', () {
        const sender = 'KB국민카드';
        const content =
            '[Web발신] KB국민카드 1*2*승인 홍*동 50,000원 일시불 스타벅스코리아 01/15 14:30';

        final result = SmsParsingService.parseSms(sender, content);

        expect(result.isParsed, isTrue);
        expect(result.amount, equals(50000));
        expect(result.transactionType, equals('expense'));
        expect(result.matchedPattern, equals('KB국민카드'));
        expect(result.confidence, greaterThan(0.5));
      });

      test('할부 결제 SMS도 정확히 파싱해야 한다', () {
        const sender = 'KB국민카드';
        const content =
            '[Web발신] KB국민카드 1234 승인 홍길동 1,200,000원 3개월할부 삼성전자 01/20 10:00';

        final result = SmsParsingService.parseSms(sender, content);

        expect(result.isParsed, isTrue);
        expect(result.amount, equals(1200000));
        expect(result.transactionType, equals('expense'));
      });
    });

    group('parseSms - 신한카드 SMS 파싱', () {
      test('신한카드 결제 SMS를 정확히 파싱해야 한다', () {
        const sender = '신한카드';
        const content = '신한카드 1234 홍길동님 25,000원 승인 이마트 01/15 14:30';

        final result = SmsParsingService.parseSms(sender, content);

        expect(result.isParsed, isTrue);
        expect(result.amount, equals(25000));
        expect(result.transactionType, equals('expense'));
        expect(result.matchedPattern, equals('신한카드'));
      });
    });

    group('parseSms - 은행 SMS 파싱', () {
      test('KB국민은행 출금 SMS를 정확히 파싱해야 한다', () {
        const sender = 'KB국민은행';
        const content = 'KB국민은행 출금 100,000원 홍길동 잔액 500,000원 01/15 14:30';

        final result = SmsParsingService.parseSms(sender, content);

        expect(result.isParsed, isTrue);
        expect(result.amount, equals(100000));
        expect(result.transactionType, equals('expense'));
      });

      test('카카오뱅크 입금 SMS를 정확히 파싱해야 한다', () {
        const sender = '카카오뱅크';
        const content = '카카오뱅크 입금 500,000원 홍길동님으로부터';

        final result = SmsParsingService.parseSms(sender, content);

        expect(result.isParsed, isTrue);
        expect(result.amount, equals(500000));
        expect(result.transactionType, equals('income'));
      });

      test('토스뱅크 입금 SMS를 정확히 파싱해야 한다', () {
        const sender = '토스';
        const content = '토스뱅크 300,000원 입금 급여';

        final result = SmsParsingService.parseSms(sender, content);

        expect(result.isParsed, isTrue);
        expect(result.amount, equals(300000));
        expect(result.transactionType, equals('income'));
      });
    });

    group('parseSms - 지역화폐 SMS 파싱', () {
      test('경기지역화폐 결제 SMS를 정확히 파싱해야 한다', () {
        const sender = '경기지역화폐';
        const content = '경기지역화폐 결제 30,000원 이마트 잔액 70,000원';

        final result = SmsParsingService.parseSms(sender, content);

        expect(result.isParsed, isTrue);
        expect(result.amount, equals(30000));
        expect(result.transactionType, equals('expense'));
      });

      test('경기지역화폐 충전 SMS를 정확히 파싱해야 한다', () {
        const sender = '경기지역화폐';
        const content = '경기지역화폐 충전 100,000원 잔액 100,000원';

        final result = SmsParsingService.parseSms(sender, content);

        expect(result.isParsed, isTrue);
        expect(result.amount, equals(100000));
        expect(result.transactionType, equals('income'));
      });
    });

    group('parseSms - 취소 메시지 처리', () {
      test('승인취소 SMS는 무시해야 한다', () {
        const sender = 'KB국민카드';
        const content = '[Web발신] KB국민카드 승인취소 50,000원 스타벅스 01/15 15:00';

        final result = SmsParsingService.parseSms(sender, content);

        expect(result.isParsed, isFalse);
        expect(result.matchedPattern, equals('cancel'));
      });

      test('결제취소 SMS는 무시해야 한다', () {
        const sender = '신한카드';
        const content = '신한카드 결제취소 30,000원 이마트';

        final result = SmsParsingService.parseSms(sender, content);

        expect(result.isParsed, isFalse);
      });
    });

    group('parseSms - 엣지 케이스', () {
      test('금액이 없는 SMS는 파싱 실패해야 한다', () {
        const sender = 'KB국민카드';
        const content = '[Web발신] KB국민카드 승인 스타벅스';

        final result = SmsParsingService.parseSms(sender, content);

        expect(result.isParsed, isFalse);
        expect(result.amount, isNull);
      });

      test('알 수 없는 발신자의 금융 SMS도 금액을 추출해야 한다', () {
        const sender = '알수없는금융사';
        const content = '결제 승인 75,000원 가맹점명';

        final result = SmsParsingService.parseSms(sender, content);

        expect(result.amount, equals(75000));
        expect(result.transactionType, equals('expense'));
        expect(result.matchedPattern, isNull);
      });

      test('큰 금액도 정확히 파싱해야 한다', () {
        const sender = 'KB국민카드';
        const content = 'KB국민카드 승인 12,345,678원 일시불 고가상품';

        final result = SmsParsingService.parseSms(sender, content);

        expect(result.amount, equals(12345678));
      });

      test('콤마 없는 금액도 파싱해야 한다', () {
        const sender = 'KB국민카드';
        const content = 'KB국민카드 승인 5000원 편의점';

        final result = SmsParsingService.parseSms(sender, content);

        expect(result.amount, equals(5000));
      });
    });

    group('generateDuplicateHash', () {
      test('동일한 입력에 대해 동일한 해시를 생성해야 한다', () {
        final timestamp = DateTime(2024, 1, 15, 14, 30);

        final hash1 = SmsParsingService.generateDuplicateHash(
          50000,
          'payment-id-1',
          timestamp,
        );
        final hash2 = SmsParsingService.generateDuplicateHash(
          50000,
          'payment-id-1',
          timestamp,
        );

        expect(hash1, equals(hash2));
      });

      test('3분 이내의 동일 거래는 동일한 해시를 가져야 한다', () {
        final timestamp1 = DateTime(2024, 1, 15, 14, 30);
        final timestamp2 = DateTime(2024, 1, 15, 14, 31); // 1분 후

        final hash1 = SmsParsingService.generateDuplicateHash(
          50000,
          'payment-id-1',
          timestamp1,
        );
        final hash2 = SmsParsingService.generateDuplicateHash(
          50000,
          'payment-id-1',
          timestamp2,
        );

        expect(hash1, equals(hash2));
      });

      test('3분 이상 차이나는 거래는 다른 해시를 가져야 한다', () {
        final timestamp1 = DateTime(2024, 1, 15, 14, 30);
        final timestamp2 = DateTime(2024, 1, 15, 14, 35); // 5분 후

        final hash1 = SmsParsingService.generateDuplicateHash(
          50000,
          'payment-id-1',
          timestamp1,
        );
        final hash2 = SmsParsingService.generateDuplicateHash(
          50000,
          'payment-id-1',
          timestamp2,
        );

        expect(hash1, isNot(equals(hash2)));
      });

      test('다른 금액은 다른 해시를 가져야 한다', () {
        final timestamp = DateTime(2024, 1, 15, 14, 30);

        final hash1 = SmsParsingService.generateDuplicateHash(
          50000,
          'payment-id-1',
          timestamp,
        );
        final hash2 = SmsParsingService.generateDuplicateHash(
          60000,
          'payment-id-1',
          timestamp,
        );

        expect(hash1, isNot(equals(hash2)));
      });

      test('다른 결제수단은 다른 해시를 가져야 한다', () {
        final timestamp = DateTime(2024, 1, 15, 14, 30);

        final hash1 = SmsParsingService.generateDuplicateHash(
          50000,
          'payment-id-1',
          timestamp,
        );
        final hash2 = SmsParsingService.generateDuplicateHash(
          50000,
          'payment-id-2',
          timestamp,
        );

        expect(hash1, isNot(equals(hash2)));
      });
    });
  });

  group('FinancialSmsSenders', () {
    test('KB국민카드 발신자를 올바르게 식별해야 한다', () {
      expect(
        FinancialSmsSenders.identifyFinancialInstitution('KB국민카드'),
        equals('KB국민카드'),
      );
      expect(
        FinancialSmsSenders.identifyFinancialInstitution('KB카드'),
        equals('KB국민카드'),
      );
      expect(
        FinancialSmsSenders.identifyFinancialInstitution('15881688'),
        equals('KB국민카드'),
      );
    });

    test('신한카드 발신자를 올바르게 식별해야 한다', () {
      expect(
        FinancialSmsSenders.identifyFinancialInstitution('신한카드'),
        equals('신한카드'),
      );
      expect(
        FinancialSmsSenders.identifyFinancialInstitution('15447200'),
        equals('신한카드'),
      );
    });

    test('카카오뱅크 발신자를 올바르게 식별해야 한다', () {
      expect(
        FinancialSmsSenders.identifyFinancialInstitution('카카오뱅크'),
        equals('카카오뱅크'),
      );
      expect(
        FinancialSmsSenders.identifyFinancialInstitution('카뱅'),
        equals('카카오뱅크'),
      );
    });

    test('경기지역화폐 발신자를 올바르게 식별해야 한다', () {
      expect(
        FinancialSmsSenders.identifyFinancialInstitution('경기지역화폐'),
        equals('경기지역화폐'),
      );
      expect(
        FinancialSmsSenders.identifyFinancialInstitution('경기화폐'),
        equals('경기지역화폐'),
      );
    });

    test('알 수 없는 발신자는 null을 반환해야 한다', () {
      expect(
        FinancialSmsSenders.identifyFinancialInstitution('알수없는발신자'),
        isNull,
      );
    });

    test('isFinancialSender가 금융 발신자를 정확히 판별해야 한다', () {
      expect(FinancialSmsSenders.isFinancialSender('KB국민카드'), isTrue);
      expect(FinancialSmsSenders.isFinancialSender('신한카드'), isTrue);
      expect(FinancialSmsSenders.isFinancialSender('토스'), isTrue);
      expect(FinancialSmsSenders.isFinancialSender('일반문자'), isFalse);
    });
  });

  group('KoreanFinancialSmsPatterns', () {
    test('금액 패턴이 다양한 형식의 금액을 매칭해야 한다', () {
      final pattern = KoreanFinancialSmsPatterns.amountPattern;

      expect(pattern.hasMatch('50,000원'), isTrue);
      expect(pattern.hasMatch('5000원'), isTrue);
      expect(pattern.hasMatch('1,234,567원'), isTrue);
      expect(pattern.hasMatch('100 원'), isTrue);
    });

    test('지출 키워드가 올바르게 정의되어야 한다', () {
      const keywords = KoreanFinancialSmsPatterns.expenseKeywords;

      expect(keywords.contains('승인'), isTrue);
      expect(keywords.contains('결제'), isTrue);
      expect(keywords.contains('출금'), isTrue);
      expect(keywords.contains('이체'), isTrue);
    });

    test('수입 키워드가 올바르게 정의되어야 한다', () {
      const keywords = KoreanFinancialSmsPatterns.incomeKeywords;

      expect(keywords.contains('입금'), isTrue);
      expect(keywords.contains('충전'), isTrue);
      expect(keywords.contains('환불'), isTrue);
    });

    test('취소 키워드가 올바르게 정의되어야 한다', () {
      const keywords = KoreanFinancialSmsPatterns.cancelKeywords;

      expect(keywords.contains('취소'), isTrue);
      expect(keywords.contains('승인취소'), isTrue);
      expect(keywords.contains('결제취소'), isTrue);
    });
  });
}
