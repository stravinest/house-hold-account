import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/payment_method/data/services/default_format_generator.dart';

void main() {
  group('DefaultFormatGenerator', () {
    group('generateSmsFormat', () {
      test('KB국민카드를 포함한 결제수단 이름에서 KB 포맷을 생성한다', () {
        // Given
        const paymentMethodName = 'KB국민카드';

        // When
        final result = DefaultFormatGenerator.generateSmsFormat(
          paymentMethodName,
        );

        // Then
        expect(result.senderPattern, equals('KB국민'));
        expect(result.senderKeywords, contains('KB국민'));
        expect(result.senderKeywords, contains('KB Pay'));
        expect(result.senderKeywords, contains('국민카드'));
        expect(result.senderKeywords, contains('KB카드'));
      });

      test('신한카드를 포함한 결제수단 이름에서 신한 포맷을 생성한다', () {
        // Given
        const paymentMethodName = '신한카드';

        // When
        final result = DefaultFormatGenerator.generateSmsFormat(
          paymentMethodName,
        );

        // Then
        expect(result.senderPattern, equals('신한'));
        expect(result.senderKeywords, contains('신한카드'));
        expect(result.senderKeywords, contains('신한'));
        expect(result.senderKeywords, contains('SOL페이'));
      });

      test('수원페이를 포함한 결제수단 이름에서 경기지역화폐 포맷을 생성한다', () {
        // Given
        const paymentMethodName = '수원페이';

        // When
        final result = DefaultFormatGenerator.generateSmsFormat(
          paymentMethodName,
        );

        // Then
        expect(result.senderPattern, equals('경기지역화폐'));
        expect(result.senderKeywords, contains('수원페이'));
        expect(result.senderKeywords, contains('경기지역화폐'));
      });

      test('카카오페이를 포함한 결제수단 이름에서 카카오페이 포맷을 생성한다', () {
        // Given
        const paymentMethodName = '카카오페이';

        // When
        final result = DefaultFormatGenerator.generateSmsFormat(
          paymentMethodName,
        );

        // Then
        expect(result.senderPattern, equals('카카오페이'));
        expect(result.senderKeywords, contains('카카오페이'));
        expect(result.senderKeywords, contains('카카오'));
      });

      test('토스를 포함한 결제수단 이름에서 토스 포맷을 생성한다', () {
        // Given
        const paymentMethodName = '토스';

        // When
        final result = DefaultFormatGenerator.generateSmsFormat(
          paymentMethodName,
        );

        // Then
        expect(result.senderPattern, equals('토스'));
        expect(result.senderKeywords, contains('토스'));
        expect(result.senderKeywords, contains('toss'));
      });

      test('매칭되는 금융사가 없으면 결제수단 이름을 기본 키워드로 사용한다', () {
        // Given
        const paymentMethodName = '알수없는카드';

        // When
        final result = DefaultFormatGenerator.generateSmsFormat(
          paymentMethodName,
        );

        // Then
        expect(result.senderPattern, equals('알수없는카드'));
        expect(result.senderKeywords, equals(['알수없는카드']));
      });

      test('서울페이를 포함한 결제수단 이름에서 서울페이 포맷을 생성한다', () {
        // Given
        const paymentMethodName = '서울페이';

        // When
        final result = DefaultFormatGenerator.generateSmsFormat(
          paymentMethodName,
        );

        // Then
        expect(result.senderPattern, equals('서울페이'));
        expect(result.senderKeywords, contains('서울페이'));
        expect(result.senderKeywords, contains('서울사랑'));
      });
    });

    group('generatePushFormat', () {
      test('KB국민카드를 포함한 결제수단 이름에서 KB Push 포맷을 생성한다', () {
        // Given
        const paymentMethodName = 'KB국민카드';

        // When
        final result = DefaultFormatGenerator.generatePushFormat(
          paymentMethodName,
        );

        // Then
        expect(result.packageName, equals('com.kbcard.cxh.appcard'));
        expect(result.appKeywords, contains('KB국민'));
        expect(result.appKeywords, contains('KB Pay'));
      });

      test('신한카드를 포함한 결제수단 이름에서 신한 Push 포맷을 생성한다', () {
        // Given
        const paymentMethodName = '신한카드';

        // When
        final result = DefaultFormatGenerator.generatePushFormat(
          paymentMethodName,
        );

        // Then
        expect(result.packageName, equals('com.shcard.smartpay'));
        expect(result.appKeywords, contains('신한카드'));
        expect(result.appKeywords, contains('SOL페이'));
      });

      test('경기지역화폐를 포함한 결제수단 이름에서 경기지역화폐 Push 포맷을 생성한다', () {
        // Given
        const paymentMethodName = '경기지역화폐';

        // When
        final result = DefaultFormatGenerator.generatePushFormat(
          paymentMethodName,
        );

        // Then
        expect(result.packageName, equals('gov.gyeonggi.ggcard'));
        expect(result.appKeywords, contains('경기지역화폐'));
      });

      test('카카오페이를 포함한 결제수단 이름에서 카카오페이 Push 포맷을 생성한다', () {
        // Given
        const paymentMethodName = '카카오페이';

        // When
        final result = DefaultFormatGenerator.generatePushFormat(
          paymentMethodName,
        );

        // Then
        expect(result.packageName, equals('com.kakaopay.app'));
        expect(result.appKeywords, contains('카카오페이'));
      });

      test('토스를 포함한 결제수단 이름에서 토스 Push 포맷을 생성한다', () {
        // Given
        const paymentMethodName = '토스';

        // When
        final result = DefaultFormatGenerator.generatePushFormat(
          paymentMethodName,
        );

        // Then
        expect(result.packageName, equals('viva.republica.toss'));
        expect(result.appKeywords, contains('토스'));
        expect(result.appKeywords, contains('toss'));
      });

      test('매칭되는 금융사가 없으면 결제수단 이름을 기본 패키지명으로 사용한다', () {
        // Given
        const paymentMethodName = '알수없는앱';

        // When
        final result = DefaultFormatGenerator.generatePushFormat(
          paymentMethodName,
        );

        // Then
        expect(result.packageName, equals('알수없는앱'));
        expect(result.appKeywords, equals(['알수없는앱']));
      });

      test('삼성카드를 포함한 결제수단 이름에서 삼성 Push 포맷을 생성한다', () {
        // Given
        const paymentMethodName = '삼성카드';

        // When
        final result = DefaultFormatGenerator.generatePushFormat(
          paymentMethodName,
        );

        // Then
        expect(result.packageName, equals('kr.co.samsungcard.mpocket'));
        expect(result.appKeywords, contains('삼성카드'));
      });

      test('NH를 포함한 결제수단 이름에서 NH 포맷을 생성한다', () {
        // Given
        const paymentMethodName = 'NH농협카드';

        // When
        final result = DefaultFormatGenerator.generatePushFormat(
          paymentMethodName,
        );

        // Then
        expect(result.packageName, equals('nh.smart.nhallonepay'));
        expect(result.appKeywords, contains('NH카드'));
        expect(result.appKeywords, contains('NH농협카드'));
      });
    });

    group('_findMatchingService', () {
      test('부분 문자열 매칭으로 금융사를 찾는다', () {
        // Given & When: KB국민이 포함된 다양한 이름
        final kb1 = DefaultFormatGenerator.generateSmsFormat('내 KB국민카드');
        final kb2 = DefaultFormatGenerator.generateSmsFormat('KB국민 1234');

        // Then: 모두 KB 패턴으로 매칭
        expect(kb1.senderPattern, equals('KB국민'));
        expect(kb2.senderPattern, equals('KB국민'));
      });

      test('경기지역화폐 계열을 올바르게 구분한다', () {
        // Given & When
        final suwon = DefaultFormatGenerator.generateSmsFormat('수원페이');
        final yongin = DefaultFormatGenerator.generateSmsFormat('용인와이페이');
        final hwaseong = DefaultFormatGenerator.generateSmsFormat('행복화성');

        // Then: 모두 경기지역화폐로 매칭되어야 함
        expect(suwon.senderPattern, equals('경기지역화폐'));
        expect(yongin.senderPattern, equals('경기지역화폐'));
        expect(hwaseong.senderPattern, equals('경기지역화폐'));

        // 각각의 키워드도 포함되어야 함
        expect(suwon.senderKeywords, contains('수원페이'));
        expect(yongin.senderKeywords, contains('용인와이페이'));
        expect(hwaseong.senderKeywords, contains('행복화성'));
      });
    });

    group('SmsFormatInfo', () {
      test('SmsFormatInfo를 올바르게 생성할 수 있다', () {
        // Given & When
        const info = SmsFormatInfo(
          senderPattern: '테스트패턴',
          senderKeywords: ['키워드1', '키워드2'],
        );

        // Then
        expect(info.senderPattern, equals('테스트패턴'));
        expect(info.senderKeywords, hasLength(2));
        expect(info.senderKeywords, contains('키워드1'));
      });
    });

    group('PushFormatInfo', () {
      test('PushFormatInfo를 올바르게 생성할 수 있다', () {
        // Given & When
        const info = PushFormatInfo(
          packageName: 'com.test.app',
          appKeywords: ['앱1', '앱2'],
        );

        // Then
        expect(info.packageName, equals('com.test.app'));
        expect(info.appKeywords, hasLength(2));
        expect(info.appKeywords, contains('앱1'));
      });
    });
  });
}
