import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/payment_method/domain/entities/learned_sms_format.dart';

void main() {
  group('LearnedSmsFormat', () {
    final testCreatedAt = DateTime(2026, 2, 12, 10, 0, 0);
    final testUpdatedAt = DateTime(2026, 2, 12, 11, 0, 0);

    final learnedFormat = LearnedSmsFormat(
      id: 'test-id',
      paymentMethodId: 'payment-method-id',
      senderPattern: 'KB',
      senderKeywords: ['KB카드', 'KB국민'],
      amountRegex: r'(\d{1,3}(,\d{3})*|\d+)원',
      typeKeywords: {
        'expense': ['승인', '결제'],
        'income': ['입금', '수령'],
      },
      merchantRegex: r'가맹점\s*[:：]\s*(.+)',
      dateRegex: r'(\d{2})/(\d{2})\s+(\d{2}):(\d{2})',
      sampleSms: '[Web발신]\n승인 10,000원\nKB카드\n스타벅스',
      isSystem: false,
      confidence: 0.9,
      matchCount: 10,
      createdAt: testCreatedAt,
      updatedAt: testUpdatedAt,
    );

    test('기본값이 올바르게 설정된다', () {
      final format = LearnedSmsFormat(
        id: 'test-id',
        paymentMethodId: 'payment-method-id',
        senderPattern: 'KB',
        senderKeywords: ['KB카드'],
        amountRegex: r'\d+원',
        typeKeywords: {'expense': ['승인']},
        createdAt: testCreatedAt,
        updatedAt: testUpdatedAt,
      );

      expect(format.isSystem, false);
      expect(format.confidence, 0.8);
      expect(format.matchCount, 0);
      expect(format.merchantRegex, null);
      expect(format.dateRegex, null);
      expect(format.sampleSms, null);
    });

    group('matchesSender', () {
      test('senderPattern이 포함되면 true를 반환한다', () {
        expect(learnedFormat.matchesSender('KB'), true);
        expect(learnedFormat.matchesSender('KB-CARD'), true);
        expect(learnedFormat.matchesSender('[KB]'), true);
      });

      test('senderKeywords 중 하나라도 포함되면 true를 반환한다', () {
        expect(learnedFormat.matchesSender('KB카드'), true);
        expect(learnedFormat.matchesSender('KB국민'), true);
        expect(learnedFormat.matchesSender('[KB국민카드]'), true);
      });

      test('매칭되지 않으면 false를 반환한다', () {
        expect(learnedFormat.matchesSender('신한카드'), false);
        expect(learnedFormat.matchesSender('NH'), false);
        expect(learnedFormat.matchesSender(''), false);
      });

      test('대소문자를 구분한다', () {
        final format = LearnedSmsFormat(
          id: 'test-id',
          paymentMethodId: 'payment-method-id',
          senderPattern: 'kb',
          senderKeywords: [],
          amountRegex: r'\d+원',
          typeKeywords: {},
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        expect(format.matchesSender('kb'), true);
        expect(format.matchesSender('KB'), false);
      });
    });

    group('copyWith', () {
      test('특정 필드만 변경할 수 있다', () {
        final updated = learnedFormat.copyWith(
          matchCount: 20,
          confidence: 0.95,
        );

        expect(updated.matchCount, 20);
        expect(updated.confidence, 0.95);
        expect(updated.id, learnedFormat.id);
        expect(updated.senderPattern, learnedFormat.senderPattern);
      });

      test('모든 필드를 변경할 수 있다', () {
        final newCreatedAt = DateTime(2026, 3, 1);
        final newUpdatedAt = DateTime(2026, 3, 2);

        final updated = learnedFormat.copyWith(
          id: 'new-id',
          paymentMethodId: 'new-payment-id',
          senderPattern: 'NH',
          senderKeywords: ['NH농협'],
          amountRegex: r'\d+원',
          typeKeywords: {'income': ['입금']},
          merchantRegex: r'상호[:：]\s*(.+)',
          dateRegex: r'\d{4}-\d{2}-\d{2}',
          sampleSms: 'new sample',
          isSystem: true,
          confidence: 0.85,
          matchCount: 5,
          createdAt: newCreatedAt,
          updatedAt: newUpdatedAt,
        );

        expect(updated.id, 'new-id');
        expect(updated.senderPattern, 'NH');
        expect(updated.senderKeywords, ['NH농협']);
        expect(updated.isSystem, true);
        expect(updated.confidence, 0.85);
        expect(updated.matchCount, 5);
      });

      test('인자를 제공하지 않으면 원본과 동일한 값을 유지한다', () {
        final copied = learnedFormat.copyWith();

        expect(copied.id, learnedFormat.id);
        expect(copied.senderPattern, learnedFormat.senderPattern);
        expect(copied.confidence, learnedFormat.confidence);
        expect(copied.matchCount, learnedFormat.matchCount);
      });
    });

    group('Equatable', () {
      test('동일한 값을 가진 인스턴스는 같다', () {
        final format1 = LearnedSmsFormat(
          id: 'test-id',
          paymentMethodId: 'payment-method-id',
          senderPattern: 'KB',
          senderKeywords: ['KB카드'],
          amountRegex: r'\d+원',
          typeKeywords: {'expense': ['승인']},
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        final format2 = LearnedSmsFormat(
          id: 'test-id',
          paymentMethodId: 'payment-method-id',
          senderPattern: 'KB',
          senderKeywords: ['KB카드'],
          amountRegex: r'\d+원',
          typeKeywords: {'expense': ['승인']},
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        expect(format1, format2);
      });

      test('다른 값을 가진 인스턴스는 다르다', () {
        final format1 = learnedFormat;
        final format2 = learnedFormat.copyWith(id: 'different-id');

        expect(format1, isNot(format2));
      });
    });

    group('LearnedFormat 인터페이스', () {
      test('LearnedFormat 인터페이스를 구현한다', () {
        expect(learnedFormat.amountRegex, isA<String>());
        expect(learnedFormat.typeKeywords, isA<Map<String, List<String>>>());
        expect(learnedFormat.merchantRegex, isA<String?>());
        expect(learnedFormat.dateRegex, isA<String?>());
        expect(learnedFormat.confidence, isA<double>());
      });
    });

    group('엣지 케이스', () {
      test('빈 senderKeywords 리스트를 처리할 수 있다', () {
        final format = LearnedSmsFormat(
          id: 'test-id',
          paymentMethodId: 'payment-method-id',
          senderPattern: 'KB',
          senderKeywords: [],
          amountRegex: r'\d+원',
          typeKeywords: {},
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        expect(format.senderKeywords, isEmpty);
        expect(format.matchesSender('KB'), true);
        expect(format.matchesSender('신한'), false);
      });

      test('빈 typeKeywords 맵을 처리할 수 있다', () {
        final format = LearnedSmsFormat(
          id: 'test-id',
          paymentMethodId: 'payment-method-id',
          senderPattern: 'KB',
          senderKeywords: [],
          amountRegex: r'\d+원',
          typeKeywords: {},
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        expect(format.typeKeywords, isEmpty);
      });

      test('매우 긴 정규식을 처리할 수 있다', () {
        final longRegex = r'(\d{1,3}(,\d{3})*|\d+)' * 10;
        final format = learnedFormat.copyWith(amountRegex: longRegex);

        expect(format.amountRegex, longRegex);
      });

      test('0.0부터 1.0까지의 confidence 값을 처리할 수 있다', () {
        final format1 = learnedFormat.copyWith(confidence: 0.0);
        final format2 = learnedFormat.copyWith(confidence: 1.0);
        final format3 = learnedFormat.copyWith(confidence: 0.5);

        expect(format1.confidence, 0.0);
        expect(format2.confidence, 1.0);
        expect(format3.confidence, 0.5);
      });

      test('매우 큰 matchCount를 처리할 수 있다', () {
        final format = learnedFormat.copyWith(matchCount: 999999);

        expect(format.matchCount, 999999);
      });

      test('특수 문자가 포함된 senderPattern을 처리할 수 있다', () {
        final format = LearnedSmsFormat(
          id: 'test-id',
          paymentMethodId: 'payment-method-id',
          senderPattern: '[KB-CARD]',
          senderKeywords: [],
          amountRegex: r'\d+원',
          typeKeywords: {},
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        expect(format.matchesSender('[KB-CARD]'), true);
      });

      test('매우 긴 sampleSms를 처리할 수 있다', () {
        final longSms = '[Web발신]\n' * 100 + '승인 10,000원';
        final format = learnedFormat.copyWith(sampleSms: longSms);

        expect(format.sampleSms, longSms);
      });
    });
  });
}
