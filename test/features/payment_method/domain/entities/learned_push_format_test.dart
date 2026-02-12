import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/payment_method/domain/entities/learned_push_format.dart';

void main() {
  group('LearnedPushFormat', () {
    final testCreatedAt = DateTime(2026, 2, 12, 10, 0, 0);
    final testUpdatedAt = DateTime(2026, 2, 12, 11, 0, 0);

    final learnedFormat = LearnedPushFormat(
      id: 'test-id',
      paymentMethodId: 'payment-method-id',
      packageName: 'com.kbcard.cxh.appcard',
      appKeywords: ['KB Pay', 'KB카드'],
      amountRegex: r'(\d{1,3}(,\d{3})*|\d+)원',
      typeKeywords: {
        'expense': ['승인', '결제'],
        'income': ['입금', '수령'],
      },
      merchantRegex: r'가맹점\s*[:：]\s*(.+)',
      dateRegex: r'(\d{2})/(\d{2})\s+(\d{2}):(\d{2})',
      sampleNotification: '승인 10,000원\nKB Pay\n스타벅스',
      confidence: 0.9,
      matchCount: 10,
      createdAt: testCreatedAt,
      updatedAt: testUpdatedAt,
    );

    test('기본값이 올바르게 설정된다', () {
      final format = LearnedPushFormat(
        id: 'test-id',
        paymentMethodId: 'payment-method-id',
        packageName: 'com.test.app',
        appKeywords: ['테스트'],
        amountRegex: r'\d+원',
        typeKeywords: {'expense': ['승인']},
        createdAt: testCreatedAt,
        updatedAt: testUpdatedAt,
      );

      expect(format.confidence, 0.8);
      expect(format.matchCount, 0);
      expect(format.merchantRegex, null);
      expect(format.dateRegex, null);
      expect(format.sampleNotification, null);
    });

    group('matchesPackageName', () {
      test('정확히 일치하는 패키지명에 대해 true를 반환한다', () {
        expect(
          learnedFormat.matchesPackageName('com.kbcard.cxh.appcard'),
          true,
        );
      });

      test('일치하지 않는 패키지명에 대해 false를 반환한다', () {
        expect(learnedFormat.matchesPackageName('com.shinhancard.app'), false);
        expect(learnedFormat.matchesPackageName('com.kbcard'), false);
        expect(learnedFormat.matchesPackageName(''), false);
      });

      test('대소문자를 구분한다', () {
        expect(
          learnedFormat.matchesPackageName('com.KBCARD.cxh.appcard'),
          false,
        );
      });
    });

    group('matchesNotification', () {
      test('패키지명과 키워드가 모두 일치하면 true를 반환한다', () {
        expect(
          learnedFormat.matchesNotification(
            'com.kbcard.cxh.appcard',
            '승인 10,000원 KB Pay 스타벅스',
          ),
          true,
        );
        expect(
          learnedFormat.matchesNotification(
            'com.kbcard.cxh.appcard',
            '결제 KB카드 내역',
          ),
          true,
        );
      });

      test('패키지명이 일치하지 않으면 false를 반환한다', () {
        expect(
          learnedFormat.matchesNotification(
            'com.wrong.package',
            '승인 10,000원 KB Pay',
          ),
          false,
        );
      });

      test('패키지명은 일치하지만 키워드가 없으면 false를 반환한다', () {
        expect(
          learnedFormat.matchesNotification(
            'com.kbcard.cxh.appcard',
            '승인 10,000원 신한카드',
          ),
          false,
        );
      });

      test('빈 content에 대해 false를 반환한다', () {
        expect(
          learnedFormat.matchesNotification('com.kbcard.cxh.appcard', ''),
          false,
        );
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
        expect(updated.packageName, learnedFormat.packageName);
      });

      test('모든 필드를 변경할 수 있다', () {
        final newCreatedAt = DateTime(2026, 3, 1);
        final newUpdatedAt = DateTime(2026, 3, 2);

        final updated = learnedFormat.copyWith(
          id: 'new-id',
          paymentMethodId: 'new-payment-id',
          packageName: 'com.new.app',
          appKeywords: ['새앱'],
          amountRegex: r'\d+원',
          typeKeywords: {'income': ['입금']},
          merchantRegex: r'상호[:：]\s*(.+)',
          dateRegex: r'\d{4}-\d{2}-\d{2}',
          sampleNotification: 'new sample',
          confidence: 0.85,
          matchCount: 5,
          createdAt: newCreatedAt,
          updatedAt: newUpdatedAt,
        );

        expect(updated.id, 'new-id');
        expect(updated.packageName, 'com.new.app');
        expect(updated.appKeywords, ['새앱']);
        expect(updated.confidence, 0.85);
        expect(updated.matchCount, 5);
      });

      test('인자를 제공하지 않으면 원본과 동일한 값을 유지한다', () {
        final copied = learnedFormat.copyWith();

        expect(copied.id, learnedFormat.id);
        expect(copied.packageName, learnedFormat.packageName);
        expect(copied.confidence, learnedFormat.confidence);
        expect(copied.matchCount, learnedFormat.matchCount);
      });
    });

    group('Equatable', () {
      test('동일한 값을 가진 인스턴스는 같다', () {
        final format1 = LearnedPushFormat(
          id: 'test-id',
          paymentMethodId: 'payment-method-id',
          packageName: 'com.test.app',
          appKeywords: ['테스트'],
          amountRegex: r'\d+원',
          typeKeywords: {'expense': ['승인']},
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        final format2 = LearnedPushFormat(
          id: 'test-id',
          paymentMethodId: 'payment-method-id',
          packageName: 'com.test.app',
          appKeywords: ['테스트'],
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
      test('빈 appKeywords 리스트를 처리할 수 있다', () {
        final format = LearnedPushFormat(
          id: 'test-id',
          paymentMethodId: 'payment-method-id',
          packageName: 'com.test.app',
          appKeywords: [],
          amountRegex: r'\d+원',
          typeKeywords: {},
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        expect(format.appKeywords, isEmpty);
        expect(
          format.matchesNotification('com.test.app', 'any content'),
          false,
        );
      });

      test('빈 typeKeywords 맵을 처리할 수 있다', () {
        final format = LearnedPushFormat(
          id: 'test-id',
          paymentMethodId: 'payment-method-id',
          packageName: 'com.test.app',
          appKeywords: ['테스트'],
          amountRegex: r'\d+원',
          typeKeywords: {},
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        expect(format.typeKeywords, isEmpty);
      });

      test('매우 긴 패키지명을 처리할 수 있다', () {
        final longPackageName = 'com.${'very' * 20}.long.package.name';
        final format = learnedFormat.copyWith(packageName: longPackageName);

        expect(format.packageName, longPackageName);
        expect(format.matchesPackageName(longPackageName), true);
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

      test('여러 개의 appKeywords를 처리할 수 있다', () {
        final format = LearnedPushFormat(
          id: 'test-id',
          paymentMethodId: 'payment-method-id',
          packageName: 'com.test.app',
          appKeywords: ['키워드1', '키워드2', '키워드3'],
          amountRegex: r'\d+원',
          typeKeywords: {},
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        expect(
          format.matchesNotification('com.test.app', '키워드1이 포함됨'),
          true,
        );
        expect(
          format.matchesNotification('com.test.app', '키워드2가 있음'),
          true,
        );
        expect(
          format.matchesNotification('com.test.app', '키워드3 확인'),
          true,
        );
      });

      test('매우 긴 sampleNotification을 처리할 수 있다', () {
        final longNotification = '승인 10,000원\n' * 100;
        final format = learnedFormat.copyWith(
          sampleNotification: longNotification,
        );

        expect(format.sampleNotification, longNotification);
      });
    });
  });
}
