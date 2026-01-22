import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/payment_method/data/services/sms_scanner_service.dart';
import 'package:shared_household_account/features/payment_method/data/services/korean_financial_patterns.dart';
import 'package:shared_household_account/features/payment_method/domain/entities/learned_sms_format.dart';

/// 테스트용 PlatformChecker 구현
class MockPlatformChecker implements PlatformChecker {
  final bool _isAndroid;
  final bool _isIOS;

  MockPlatformChecker({bool isAndroid = false, bool isIOS = false})
    : _isAndroid = isAndroid,
      _isIOS = isIOS;

  @override
  bool get isAndroid => _isAndroid;

  @override
  bool get isIOS => _isIOS;
}

void main() {
  // Note: SmsScannerService 테스트는 Repository 의존성으로 인해
  // 통합 테스트에서 진행합니다. 여기서는 독립적인 유틸리티 테스트만 수행합니다.

  group('SmsMessageData', () {
    test('SmsMessageData 객체가 올바르게 생성되어야 한다', () {
      final message = SmsMessageData(
        id: 'msg-1',
        sender: 'KB국민카드',
        body: '승인 50,000원 스타벅스',
        date: DateTime(2024, 1, 15, 14, 30),
        isRead: true,
      );

      expect(message.id, equals('msg-1'));
      expect(message.sender, equals('KB국민카드'));
      expect(message.body, equals('승인 50,000원 스타벅스'));
      expect(message.isRead, isTrue);
    });

    test('toString이 유용한 디버그 정보를 반환해야 한다', () {
      final message = SmsMessageData(
        id: 'msg-1',
        sender: 'KB국민카드',
        body: '승인 50,000원',
        date: DateTime(2024, 1, 15),
      );

      final str = message.toString();

      expect(str, contains('KB국민카드'));
      expect(str, contains('승인 50,000원'));
    });
  });

  group('SmsFormatScanResult', () {
    test('빈 결과는 hasFinancialMessages가 false여야 한다', () {
      const result = SmsFormatScanResult(
        financialMessages: [],
        groupedBySender: {},
        detectedFormats: [],
      );

      expect(result.hasFinancialMessages, isFalse);
      expect(result.totalCount, equals(0));
    });

    test('메시지가 있으면 hasFinancialMessages가 true여야 한다', () {
      final result = SmsFormatScanResult(
        financialMessages: [
          SmsMessageData(
            id: '1',
            sender: 'KB',
            body: 'test',
            date: DateTime.now(),
          ),
        ],
        groupedBySender: const {},
        detectedFormats: const [],
      );

      expect(result.hasFinancialMessages, isTrue);
      expect(result.totalCount, equals(1));
    });
  });

  group('FormatLearningResult', () {
    test('success 팩토리가 올바른 결과를 반환해야 한다', () {
      final mockFormat = LearnedSmsFormat(
        id: 'test-id',
        paymentMethodId: 'pm-1',
        senderPattern: 'KB국민',
        senderKeywords: const ['KB국민', 'KB카드'],
        amountRegex: r'([0-9,]+)\s*원',
        typeKeywords: const {
          'expense': ['승인'],
          'income': ['입금'],
        },
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final result = FormatLearningResult.success(mockFormat, confidence: 0.9);

      expect(result.success, isTrue);
      expect(result.learnedFormat, isNotNull);
      expect(result.confidence, equals(0.9));
      expect(result.error, isNull);
    });

    test('failure 팩토리가 올바른 결과를 반환해야 한다', () {
      final result = FormatLearningResult.failure('테스트 에러');

      expect(result.success, isFalse);
      expect(result.learnedFormat, isNull);
      expect(result.error, equals('테스트 에러'));
    });
  });

  group('KoreanFinancialPatterns', () {
    test('findByName으로 KB국민카드를 찾을 수 있어야 한다', () {
      final pattern = KoreanFinancialPatterns.findByName('KB국민카드');

      expect(pattern, isNotNull);
      expect(pattern!.institutionName, equals('KB국민카드'));
      expect(pattern.institutionType, equals('card'));
    });

    test('findByName으로 카카오뱅크를 찾을 수 있어야 한다', () {
      final pattern = KoreanFinancialPatterns.findByName('카카오뱅크');

      expect(pattern, isNotNull);
      expect(pattern!.institutionName, equals('카카오뱅크'));
      expect(pattern.institutionType, equals('bank'));
    });

    test('findByName으로 경기지역화폐를 찾을 수 있어야 한다', () {
      final pattern = KoreanFinancialPatterns.findByName('경기지역화폐');

      expect(pattern, isNotNull);
      expect(pattern!.institutionName, equals('경기지역화폐'));
      expect(pattern.institutionType, equals('local_currency'));
    });

    test('존재하지 않는 금융사는 null을 반환해야 한다', () {
      final pattern = KoreanFinancialPatterns.findByName('존재하지않는은행');

      expect(pattern, isNull);
    });

    test('findBySender로 발신자 패턴을 매칭할 수 있어야 한다', () {
      final pattern = KoreanFinancialPatterns.findBySender('15881688');

      expect(pattern, isNotNull);
      expect(pattern!.institutionName, equals('KB국민카드'));
    });

    test('cardPatterns는 카드사만 포함해야 한다', () {
      final cards = KoreanFinancialPatterns.cardPatterns;

      expect(cards, isNotEmpty);
      expect(cards.every((p) => p.institutionType == 'card'), isTrue);
    });

    test('bankPatterns는 은행만 포함해야 한다', () {
      final banks = KoreanFinancialPatterns.bankPatterns;

      expect(banks, isNotEmpty);
      expect(banks.every((p) => p.institutionType == 'bank'), isTrue);
    });

    test('localCurrencyPatterns는 지역화폐만 포함해야 한다', () {
      final localCurrencies = KoreanFinancialPatterns.localCurrencyPatterns;

      expect(localCurrencies, isNotEmpty);
      expect(
        localCurrencies.every((p) => p.institutionType == 'local_currency'),
        isTrue,
      );
    });

    test('allPatterns에 모든 금융사가 포함되어야 한다', () {
      const all = KoreanFinancialPatterns.allPatterns;

      // 카드사 9개, 은행 9개, 지역화폐 3개 = 21개
      expect(all.length, greaterThanOrEqualTo(21));

      // 각 타입이 모두 포함되어 있는지 확인
      expect(all.any((p) => p.institutionType == 'card'), isTrue);
      expect(all.any((p) => p.institutionType == 'bank'), isTrue);
      expect(all.any((p) => p.institutionType == 'local_currency'), isTrue);
    });
  });
}
