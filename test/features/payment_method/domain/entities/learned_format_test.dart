import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/payment_method/domain/entities/learned_format.dart';
import 'package:shared_household_account/features/payment_method/domain/entities/learned_sms_format.dart';

void main() {
  group('LearnedFormat', () {
    late LearnedFormat learnedFormat;

    setUp(() {
      learnedFormat = LearnedSmsFormat(
        id: 'test-id',
        paymentMethodId: 'payment-id',
        senderPattern: 'KB카드',
        senderKeywords: ['KB', '카드'],
        amountRegex: r'(\d{1,3}(,\d{3})*|\d+)원',
        typeKeywords: {
          'expense': ['출금', '결제', '승인'],
          'income': ['입금', '환불'],
        },
        merchantRegex: r'가맹점:(.+)',
        dateRegex: r'(\d{2}/\d{2})',
        sampleSms: '[KB카드] 10,000원 승인 가맹점:테스트',
        isSystem: true,
        confidence: 0.9,
        matchCount: 5,
        createdAt: DateTime(2026, 2, 12, 10, 0, 0),
        updatedAt: DateTime(2026, 2, 12, 11, 0, 0),
      );
    });

    test('LearnedFormat 인터페이스를 구현한다', () {
      expect(learnedFormat, isA<LearnedFormat>());
    });

    group('필수 getter', () {
      test('amountRegex getter가 작동한다', () {
        expect(learnedFormat.amountRegex, r'(\d{1,3}(,\d{3})*|\d+)원');
      });

      test('typeKeywords getter가 작동한다', () {
        expect(learnedFormat.typeKeywords, {
          'expense': ['출금', '결제', '승인'],
          'income': ['입금', '환불'],
        });
      });

      test('merchantRegex getter가 작동한다', () {
        expect(learnedFormat.merchantRegex, r'가맹점:(.+)');
      });

      test('dateRegex getter가 작동한다', () {
        expect(learnedFormat.dateRegex, r'(\d{2}/\d{2})');
      });

      test('confidence getter가 작동한다', () {
        expect(learnedFormat.confidence, 0.9);
      });
    });

    group('null 허용 필드', () {
      test('merchantRegex가 null일 수 있다', () {
        final format = LearnedSmsFormat(
          id: 'test-id',
          paymentMethodId: 'payment-id',
          senderPattern: 'KB카드',
          senderKeywords: ['KB'],
          amountRegex: r'(\d+)원',
          typeKeywords: {'expense': ['승인']},
          merchantRegex: null,
          dateRegex: null,
          createdAt: DateTime(2026, 2, 12, 10, 0, 0),
          updatedAt: DateTime(2026, 2, 12, 11, 0, 0),
        );

        expect(format.merchantRegex, null);
      });

      test('dateRegex가 null일 수 있다', () {
        final format = LearnedSmsFormat(
          id: 'test-id',
          paymentMethodId: 'payment-id',
          senderPattern: 'KB카드',
          senderKeywords: ['KB'],
          amountRegex: r'(\d+)원',
          typeKeywords: {'expense': ['승인']},
          merchantRegex: null,
          dateRegex: null,
          createdAt: DateTime(2026, 2, 12, 10, 0, 0),
          updatedAt: DateTime(2026, 2, 12, 11, 0, 0),
        );

        expect(format.dateRegex, null);
      });
    });

    group('typeKeywords 구조', () {
      test('expense 키워드를 포함한다', () {
        expect(learnedFormat.typeKeywords.containsKey('expense'), true);
        expect(learnedFormat.typeKeywords['expense'], ['출금', '결제', '승인']);
      });

      test('income 키워드를 포함한다', () {
        expect(learnedFormat.typeKeywords.containsKey('income'), true);
        expect(learnedFormat.typeKeywords['income'], ['입금', '환불']);
      });

      test('빈 키워드 리스트를 포함할 수 있다', () {
        final format = LearnedSmsFormat(
          id: 'test-id',
          paymentMethodId: 'payment-id',
          senderPattern: 'KB카드',
          senderKeywords: ['KB'],
          amountRegex: r'(\d+)원',
          typeKeywords: {
            'expense': [],
            'income': [],
          },
          createdAt: DateTime(2026, 2, 12, 10, 0, 0),
          updatedAt: DateTime(2026, 2, 12, 11, 0, 0),
        );

        expect(format.typeKeywords['expense'], []);
        expect(format.typeKeywords['income'], []);
      });

      test('다양한 타입 키를 포함할 수 있다', () {
        final format = LearnedSmsFormat(
          id: 'test-id',
          paymentMethodId: 'payment-id',
          senderPattern: 'KB카드',
          senderKeywords: ['KB'],
          amountRegex: r'(\d+)원',
          typeKeywords: {
            'expense': ['승인'],
            'income': ['입금'],
            'transfer': ['이체'],
          },
          createdAt: DateTime(2026, 2, 12, 10, 0, 0),
          updatedAt: DateTime(2026, 2, 12, 11, 0, 0),
        );

        expect(format.typeKeywords.containsKey('transfer'), true);
        expect(format.typeKeywords['transfer'], ['이체']);
      });
    });

    group('confidence 값', () {
      test('0.0에서 1.0 사이의 값을 가질 수 있다', () {
        final values = [0.0, 0.5, 0.8, 0.9, 1.0];

        for (final value in values) {
          final format = LearnedSmsFormat(
            id: 'test-id',
            paymentMethodId: 'payment-id',
            senderPattern: 'KB카드',
            senderKeywords: ['KB'],
            amountRegex: r'(\d+)원',
            typeKeywords: {'expense': ['승인']},
            confidence: value,
            createdAt: DateTime(2026, 2, 12, 10, 0, 0),
            updatedAt: DateTime(2026, 2, 12, 11, 0, 0),
          );

          expect(format.confidence, value);
        }
      });

      test('기본값이 0.8이다', () {
        final format = LearnedSmsFormat(
          id: 'test-id',
          paymentMethodId: 'payment-id',
          senderPattern: 'KB카드',
          senderKeywords: ['KB'],
          amountRegex: r'(\d+)원',
          typeKeywords: {'expense': ['승인']},
          createdAt: DateTime(2026, 2, 12, 10, 0, 0),
          updatedAt: DateTime(2026, 2, 12, 11, 0, 0),
        );

        expect(format.confidence, 0.8);
      });
    });

    group('regex 패턴', () {
      test('amountRegex가 금액 패턴을 정의한다', () {
        expect(learnedFormat.amountRegex, isA<String>());
        expect(learnedFormat.amountRegex.isNotEmpty, true);
      });

      test('다양한 금액 패턴을 지원할 수 있다', () {
        final patterns = [
          r'(\d{1,3}(,\d{3})*|\d+)원',
          r'\d+원',
          r'금액:(\d+)',
          r'KRW (\d+)',
        ];

        for (final pattern in patterns) {
          final format = LearnedSmsFormat(
            id: 'test-id',
            paymentMethodId: 'payment-id',
            senderPattern: 'KB카드',
            senderKeywords: ['KB'],
            amountRegex: pattern,
            typeKeywords: {'expense': ['승인']},
            createdAt: DateTime(2026, 2, 12, 10, 0, 0),
            updatedAt: DateTime(2026, 2, 12, 11, 0, 0),
          );

          expect(format.amountRegex, pattern);
        }
      });

      test('merchantRegex가 가맹점 패턴을 정의한다', () {
        expect(learnedFormat.merchantRegex, isA<String>());
        expect(learnedFormat.merchantRegex, r'가맹점:(.+)');
      });

      test('dateRegex가 날짜 패턴을 정의한다', () {
        expect(learnedFormat.dateRegex, isA<String>());
        expect(learnedFormat.dateRegex, r'(\d{2}/\d{2})');
      });

      test('다양한 날짜 패턴을 지원할 수 있다', () {
        final patterns = [
          r'(\d{2}/\d{2})',
          r'(\d{4}-\d{2}-\d{2})',
          r'(\d{2}\.\d{2})',
        ];

        for (final pattern in patterns) {
          final format = LearnedSmsFormat(
            id: 'test-id',
            paymentMethodId: 'payment-id',
            senderPattern: 'KB카드',
            senderKeywords: ['KB'],
            amountRegex: r'(\d+)원',
            typeKeywords: {'expense': ['승인']},
            dateRegex: pattern,
            createdAt: DateTime(2026, 2, 12, 10, 0, 0),
            updatedAt: DateTime(2026, 2, 12, 11, 0, 0),
          );

          expect(format.dateRegex, pattern);
        }
      });
    });

    group('엣지 케이스', () {
      test('빈 typeKeywords 맵을 처리할 수 있다', () {
        final format = LearnedSmsFormat(
          id: 'test-id',
          paymentMethodId: 'payment-id',
          senderPattern: 'KB카드',
          senderKeywords: ['KB'],
          amountRegex: r'(\d+)원',
          typeKeywords: {},
          createdAt: DateTime(2026, 2, 12, 10, 0, 0),
          updatedAt: DateTime(2026, 2, 12, 11, 0, 0),
        );

        expect(format.typeKeywords, {});
        expect(format.typeKeywords.isEmpty, true);
      });

      test('매우 긴 regex 패턴을 처리할 수 있다', () {
        final longRegex = r'(\d+)' * 100;
        final format = LearnedSmsFormat(
          id: 'test-id',
          paymentMethodId: 'payment-id',
          senderPattern: 'KB카드',
          senderKeywords: ['KB'],
          amountRegex: longRegex,
          typeKeywords: {'expense': ['승인']},
          createdAt: DateTime(2026, 2, 12, 10, 0, 0),
          updatedAt: DateTime(2026, 2, 12, 11, 0, 0),
        );

        expect(format.amountRegex, longRegex);
      });

      test('많은 키워드를 처리할 수 있다', () {
        final manyKeywords = List.generate(100, (index) => '키워드$index');
        final format = LearnedSmsFormat(
          id: 'test-id',
          paymentMethodId: 'payment-id',
          senderPattern: 'KB카드',
          senderKeywords: ['KB'],
          amountRegex: r'(\d+)원',
          typeKeywords: {'expense': manyKeywords},
          createdAt: DateTime(2026, 2, 12, 10, 0, 0),
          updatedAt: DateTime(2026, 2, 12, 11, 0, 0),
        );

        expect(format.typeKeywords['expense']!.length, 100);
      });

      test('confidence가 0보다 작은 값을 가질 수 있다', () {
        final format = LearnedSmsFormat(
          id: 'test-id',
          paymentMethodId: 'payment-id',
          senderPattern: 'KB카드',
          senderKeywords: ['KB'],
          amountRegex: r'(\d+)원',
          typeKeywords: {'expense': ['승인']},
          confidence: -0.5,
          createdAt: DateTime(2026, 2, 12, 10, 0, 0),
          updatedAt: DateTime(2026, 2, 12, 11, 0, 0),
        );

        expect(format.confidence, -0.5);
      });

      test('confidence가 1보다 큰 값을 가질 수 있다', () {
        final format = LearnedSmsFormat(
          id: 'test-id',
          paymentMethodId: 'payment-id',
          senderPattern: 'KB카드',
          senderKeywords: ['KB'],
          amountRegex: r'(\d+)원',
          typeKeywords: {'expense': ['승인']},
          confidence: 1.5,
          createdAt: DateTime(2026, 2, 12, 10, 0, 0),
          updatedAt: DateTime(2026, 2, 12, 11, 0, 0),
        );

        expect(format.confidence, 1.5);
      });

      test('특수문자가 포함된 regex를 처리할 수 있다', () {
        final specialRegex = r'[금액:\$\(\)\[\]\{\}\.\+\*\?]';
        final format = LearnedSmsFormat(
          id: 'test-id',
          paymentMethodId: 'payment-id',
          senderPattern: 'KB카드',
          senderKeywords: ['KB'],
          amountRegex: specialRegex,
          typeKeywords: {'expense': ['승인']},
          createdAt: DateTime(2026, 2, 12, 10, 0, 0),
          updatedAt: DateTime(2026, 2, 12, 11, 0, 0),
        );

        expect(format.amountRegex, specialRegex);
      });

      test('유니코드 문자가 포함된 키워드를 처리할 수 있다', () {
        final unicodeKeywords = ['승인', '출금', '💳', '🏦'];
        final format = LearnedSmsFormat(
          id: 'test-id',
          paymentMethodId: 'payment-id',
          senderPattern: 'KB카드',
          senderKeywords: ['KB'],
          amountRegex: r'(\d+)원',
          typeKeywords: {'expense': unicodeKeywords},
          createdAt: DateTime(2026, 2, 12, 10, 0, 0),
          updatedAt: DateTime(2026, 2, 12, 11, 0, 0),
        );

        expect(format.typeKeywords['expense'], unicodeKeywords);
      });
    });
  });
}
