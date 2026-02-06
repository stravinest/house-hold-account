import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/payment_method/data/services/notification_listener_wrapper.dart';

/// Kotlin/Dart 키워드 동기화 테스트
///
/// Kotlin(FinancialNotificationListener.kt)과 Dart(notification_listener_wrapper.dart)의
/// 키워드 리스트가 동기화되어 있는지 검증한다.
/// 키워드 추가/삭제 시 이 테스트가 실패하여 동기화 누락을 방지한다.
///
/// Kotlin 쪽 키워드를 하드코딩하여 비교하는 방식을 사용한다.
void main() {
  // Kotlin NotificationFilterHelper의 FINANCIAL_CHANNEL_KEYWORDS와 동일해야 함
  const kotlinFinancialChannelKeywords = [
    // 카드사
    'KB국민카드', '국민카드', '신한카드', '삼성카드', '현대카드',
    '롯데카드', '우리카드', '하나카드', 'BC카드', 'NH카드',
    '비씨카드',
    // 은행
    'KB국민은행', '국민은행', '신한은행', '우리은행', '하나은행',
    'NH농협', '농협은행', 'IBK기업은행', '기업은행',
    '카카오뱅크', '토스뱅크', '케이뱅크',
    // 간편결제
    '카카오페이', '네이버페이',
    // 카카오톡 알림톡 채널명 (실제 알림에서 title로 사용됨)
    '카드영수증',
  ];

  // Kotlin NotificationFilterHelper의 ALIMTALK_TRANSACTION_KEYWORDS와 동일해야 함
  const kotlinAlimtalkTransactionKeywords = [
    '승인', '결제', '출금', '입금', '이체', '충전',
    '취소', '환불', '일시불', '할부', '사용금액',
    '잔액', '체크카드', '신용카드',
  ];

  group('Kotlin/Dart 금융 채널 키워드 동기화', () {
    test('Dart의 금융 채널 키워드 목록이 Kotlin과 동일해야 한다', () {
      final dartKeywords =
          NotificationListenerWrapper.financialChannelKeywordsForTesting;

      // Kotlin 키워드가 모두 Dart에 포함되어 있는지 확인
      for (final keyword in kotlinFinancialChannelKeywords) {
        expect(
          dartKeywords.contains(keyword),
          isTrue,
          reason:
              'Kotlin의 "$keyword"가 Dart의 _financialChannelKeywords에도 있어야 한다. '
              'Kotlin(NotificationFilterHelper.kt)에 추가된 키워드를 '
              'Dart(notification_listener_wrapper.dart)에도 추가하세요.',
        );
      }

      // Dart 키워드가 모두 Kotlin에 포함되어 있는지 확인
      for (final keyword in dartKeywords) {
        expect(
          kotlinFinancialChannelKeywords.contains(keyword),
          isTrue,
          reason:
              'Dart의 "$keyword"가 Kotlin의 FINANCIAL_CHANNEL_KEYWORDS에도 있어야 한다. '
              'Dart(notification_listener_wrapper.dart)에 추가된 키워드를 '
              'Kotlin(NotificationFilterHelper.kt)에도 추가하세요.',
        );
      }
    });

    test('Dart와 Kotlin의 금융 채널 키워드 개수가 동일해야 한다', () {
      final dartKeywords =
          NotificationListenerWrapper.financialChannelKeywordsForTesting;

      expect(
        dartKeywords.length,
        equals(kotlinFinancialChannelKeywords.length),
        reason:
            'Dart(${dartKeywords.length}개)와 '
            'Kotlin(${kotlinFinancialChannelKeywords.length}개)의 '
            '금융 채널 키워드 개수가 다릅니다. 양쪽을 동기화하세요.',
      );
    });
  });

  group('Kotlin/Dart 거래 키워드 동기화', () {
    test('Dart의 거래 키워드 목록이 Kotlin과 동일해야 한다', () {
      final dartKeywords =
          NotificationListenerWrapper.alimtalkTransactionKeywordsForTesting;

      // Kotlin 키워드가 모두 Dart에 포함되어 있는지 확인
      for (final keyword in kotlinAlimtalkTransactionKeywords) {
        expect(
          dartKeywords.contains(keyword),
          isTrue,
          reason:
              'Kotlin의 "$keyword"가 Dart의 _alimtalkTransactionKeywords에도 있어야 한다. '
              'Kotlin(NotificationFilterHelper.kt)에 추가된 키워드를 '
              'Dart(notification_listener_wrapper.dart)에도 추가하세요.',
        );
      }

      // Dart 키워드가 모두 Kotlin에 포함되어 있는지 확인
      for (final keyword in dartKeywords) {
        expect(
          kotlinAlimtalkTransactionKeywords.contains(keyword),
          isTrue,
          reason:
              'Dart의 "$keyword"가 Kotlin의 ALIMTALK_TRANSACTION_KEYWORDS에도 있어야 한다. '
              'Dart(notification_listener_wrapper.dart)에 추가된 키워드를 '
              'Kotlin(NotificationFilterHelper.kt)에도 추가하세요.',
        );
      }
    });

    test('Dart와 Kotlin의 거래 키워드 개수가 동일해야 한다', () {
      final dartKeywords =
          NotificationListenerWrapper.alimtalkTransactionKeywordsForTesting;

      expect(
        dartKeywords.length,
        equals(kotlinAlimtalkTransactionKeywords.length),
        reason:
            'Dart(${dartKeywords.length}개)와 '
            'Kotlin(${kotlinAlimtalkTransactionKeywords.length}개)의 '
            '거래 키워드 개수가 다릅니다. 양쪽을 동기화하세요.',
      );
    });
  });

  group('금액 패턴 동기화 검증', () {
    // Kotlin AMOUNT_PATTERN: "[0-9,]+원|\\d{1,3}(,\\d{3})+"
    // Dart _amountPattern: RegExp(r'[0-9,]+원|\d{1,3}(,\d{3})+')
    // 동일한 정규식이므로 동일한 결과를 반환해야 함

    test('단순 금액 패턴이 동일하게 매칭되어야 한다', () {
      final dartPattern =
          NotificationListenerWrapper.amountPatternForTesting;

      expect(dartPattern.hasMatch('50,000원'), isTrue);
      expect(dartPattern.hasMatch('1,200,000원'), isTrue);
      expect(dartPattern.hasMatch('500원'), isTrue);
      expect(dartPattern.hasMatch('10원'), isTrue);
    });

    test('쉼표 형식 금액이 매칭되어야 한다', () {
      final dartPattern =
          NotificationListenerWrapper.amountPatternForTesting;

      expect(dartPattern.hasMatch('1,000'), isTrue);
      expect(dartPattern.hasMatch('50,000'), isTrue);
      expect(dartPattern.hasMatch('1,234,567'), isTrue);
    });

    test('금액이 아닌 텍스트는 매칭되지 않아야 한다', () {
      final dartPattern =
          NotificationListenerWrapper.amountPatternForTesting;

      expect(dartPattern.hasMatch('안녕하세요'), isFalse);
      expect(dartPattern.hasMatch('이벤트 당첨'), isFalse);
    });
  });
}
