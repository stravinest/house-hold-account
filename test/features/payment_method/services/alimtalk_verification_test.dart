import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/payment_method/data/services/notification_listener_wrapper.dart';

/// 카카오톡 알림톡 금융 알림 3중 검증 독립 테스트
/// NotificationListenerWrapper의 의존성 없이 순수 로직만 테스트한다
///
/// 3중 검증 조건:
/// 1) title이 금융 채널 키워드 포함 (발신 채널 확인)
/// 2) content에 거래 키워드 포함 (승인, 결제, 출금 등)
/// 3) content에 금액 패턴 포함 (숫자+원)
void main() {
  group('알림톡 3중 검증 - 정상 케이스 (통과해야 하는 알림)', () {
    test('KB국민카드 결제 알림을 통과시켜야 한다', () {
      final result = NotificationListenerWrapper.isFinancialAlimtalkForTesting(
        'KB국민카드',
        '50,000원 승인 스타벅스',
      );
      expect(result, isTrue, reason: 'KB국민카드 + 승인 + 금액 = 3중 검증 통과');
    });

    test('신한카드 승인 알림을 통과시켜야 한다', () {
      final result = NotificationListenerWrapper.isFinancialAlimtalkForTesting(
        '신한카드',
        '30,000원 결제 완료 홍대카페',
      );
      expect(result, isTrue, reason: '신한카드 + 결제 + 금액 = 3중 검증 통과');
    });

    test('현대카드 할부 알림을 통과시켜야 한다', () {
      final result = NotificationListenerWrapper.isFinancialAlimtalkForTesting(
        '현대카드',
        '1,200,000원 3개월 할부 삼성전자',
      );
      expect(result, isTrue, reason: '현대카드 + 할부 + 금액 = 3중 검증 통과');
    });

    test('카카오뱅크 이체 알림을 통과시켜야 한다', () {
      final result = NotificationListenerWrapper.isFinancialAlimtalkForTesting(
        '카카오뱅크',
        '100,000원 이체',
      );
      expect(result, isTrue, reason: '카카오뱅크 + 이체 + 금액 = 3중 검증 통과');
    });

    test('카카오페이 충전 알림을 통과시켜야 한다', () {
      final result = NotificationListenerWrapper.isFinancialAlimtalkForTesting(
        '카카오페이',
        '10,000원 충전 완료',
      );
      expect(result, isTrue, reason: '카카오페이 + 충전 + 금액 = 3중 검증 통과');
    });

    test('NH농협 입금 알림을 통과시켜야 한다', () {
      final result = NotificationListenerWrapper.isFinancialAlimtalkForTesting(
        'NH농협',
        '500,000원 입금 홍길동',
      );
      expect(result, isTrue, reason: 'NH농협 + 입금 + 금액 = 3중 검증 통과');
    });

    test('카카오톡 카드영수증 채널 알림을 통과시켜야 한다', () {
      // 실제 카카오톡에서 카드 결제 알림톡은 title이 "카카오톡 카드영수증"으로 옴
      final result = NotificationListenerWrapper.isFinancialAlimtalkForTesting(
        '카카오톡 카드영수증',
        'KB국민카드1004승인 전*규님 600원 일시불 02/06 20:49 설아 아이스크림 누적1,194,249원',
      );
      expect(result, isTrue, reason: '카드영수증 채널 + 승인 + 금액 = 3중 검증 통과');
    });

    test('우리은행 출금 알림을 통과시켜야 한다', () {
      final result = NotificationListenerWrapper.isFinancialAlimtalkForTesting(
        '우리은행',
        '출금 200,000원 ATM',
      );
      expect(result, isTrue, reason: '우리은행 + 출금 + 금액 = 3중 검증 통과');
    });

    test('롯데카드 결제 알림을 통과시켜야 한다', () {
      final result = NotificationListenerWrapper.isFinancialAlimtalkForTesting(
        '롯데카드',
        '일시불 45,000원 결제 CU편의점',
      );
      expect(result, isTrue, reason: '롯데카드 + 결제 + 금액 = 3중 검증 통과');
    });

    test('하나카드 환불 알림을 통과시켜야 한다', () {
      final result = NotificationListenerWrapper.isFinancialAlimtalkForTesting(
        '하나카드',
        '환불 15,000원 처리 완료',
      );
      expect(result, isTrue, reason: '하나카드 + 환불 + 금액 = 3중 검증 통과');
    });

    test('토스뱅크 잔액 알림을 통과시켜야 한다', () {
      final result = NotificationListenerWrapper.isFinancialAlimtalkForTesting(
        '토스뱅크',
        '잔액 1,234,567원',
      );
      expect(result, isTrue, reason: '토스뱅크 + 잔액 + 금액 = 3중 검증 통과');
    });

    test('체크카드 사용 알림을 통과시켜야 한다', () {
      final result = NotificationListenerWrapper.isFinancialAlimtalkForTesting(
        '국민카드',
        '체크카드 15,000원 GS25',
      );
      expect(result, isTrue, reason: '국민카드 + 체크카드 + 금액 = 3중 검증 통과');
    });

    test('삼성카드 취소 알림을 통과시켜야 한다', () {
      final result = NotificationListenerWrapper.isFinancialAlimtalkForTesting(
        '삼성카드',
        '취소 50,000원 스타벅스',
      );
      expect(result, isTrue, reason: '삼성카드 + 취소 + 금액 = 3중 검증 통과');
    });
  });

  group('알림톡 3중 검증 - 차단 케이스 (거부해야 하는 알림)', () {
    test('카카오톡 일반 대화는 차단해야 한다', () {
      final result = NotificationListenerWrapper.isFinancialAlimtalkForTesting(
        '홍길동',
        '오늘 저녁 뭐 먹을까?',
      );
      expect(result, isFalse, reason: '비금융 채널은 차단되어야 한다');
    });

    test('배달의민족 주문 알림은 차단해야 한다', () {
      final result = NotificationListenerWrapper.isFinancialAlimtalkForTesting(
        '배달의민족',
        '주문 완료 25,000원 결제',
      );
      expect(result, isFalse, reason: '배달 앱은 금융 채널이 아니다');
    });

    test('쿠팡 배송 알림은 차단해야 한다', () {
      final result = NotificationListenerWrapper.isFinancialAlimtalkForTesting(
        '쿠팡',
        '배송 시작 30,000원 결제',
      );
      expect(result, isFalse, reason: '쿠팡은 금융 채널이 아니다');
    });

    test('금융채널이지만 프로모션 메시지는 차단해야 한다', () {
      final result = NotificationListenerWrapper.isFinancialAlimtalkForTesting(
        'KB국민카드',
        '이벤트 당첨! 혜택 받으세요',
      );
      expect(result, isFalse, reason: '거래 키워드 없고 금액 없으므로 차단');
    });

    test('금융채널이지만 공지사항은 차단해야 한다', () {
      final result = NotificationListenerWrapper.isFinancialAlimtalkForTesting(
        'KB국민카드',
        '시스템 점검 안내 - 12월 31일 02:00~06:00',
      );
      expect(result, isFalse, reason: '공지사항에는 거래 키워드와 금액이 없다');
    });

    test('빈 title은 차단해야 한다', () {
      final result = NotificationListenerWrapper.isFinancialAlimtalkForTesting(
        '',
        '50,000원 승인 스타벅스',
      );
      expect(result, isFalse, reason: '빈 title은 차단되어야 한다');
    });

    test('빈 content는 차단해야 한다', () {
      final result = NotificationListenerWrapper.isFinancialAlimtalkForTesting(
        'KB국민카드',
        '',
      );
      expect(result, isFalse, reason: '빈 content는 차단되어야 한다');
    });

    test('네이버 쇼핑 알림은 차단해야 한다', () {
      final result = NotificationListenerWrapper.isFinancialAlimtalkForTesting(
        '네이버 쇼핑',
        '주문 확인 50,000원 결제 완료',
      );
      expect(result, isFalse, reason: '네이버 쇼핑은 금융 채널이 아니다');
    });
  });

  group('알림톡 3중 검증 - 경계 케이스', () {
    test('금융채널 + 거래키워드 + 금액없음 -> 차단', () {
      final result = NotificationListenerWrapper.isFinancialAlimtalkForTesting(
        'KB국민카드',
        '승인 완료되었습니다',
      );
      expect(result, isFalse, reason: '금액 패턴이 없으면 차단');
    });

    test('금융채널 + 비거래키워드 + 금액있음 -> 차단', () {
      final result = NotificationListenerWrapper.isFinancialAlimtalkForTesting(
        'KB국민카드',
        '포인트 적립 안내 10,000원',
      );
      expect(result, isFalse, reason: '거래 키워드가 없으면 차단');
    });

    test('비금융채널 + 거래키워드 + 금액있음 -> 차단', () {
      final result = NotificationListenerWrapper.isFinancialAlimtalkForTesting(
        '홍길동',
        '50,000원 승인 스타벅스',
      );
      expect(result, isFalse, reason: '금융 채널이 아니면 차단');
    });

    test('금액이 쉼표 없이 작은 경우도 통과해야 한다', () {
      final result = NotificationListenerWrapper.isFinancialAlimtalkForTesting(
        'KB국민카드',
        '500원 승인 편의점',
      );
      expect(result, isTrue, reason: '500원도 금액 패턴으로 매칭되어야 한다');
    });

    test('title 대소문자를 무시하고 매칭해야 한다', () {
      // 한국어 금융 채널은 대소문자 무관하지만, 영문이 포함된 경우 테스트
      final result = NotificationListenerWrapper.isFinancialAlimtalkForTesting(
        'kb국민카드',
        '50,000원 승인 스타벅스',
      );
      expect(result, isTrue, reason: '소문자 title도 매칭되어야 한다');
    });

    test('큰 금액도 매칭되어야 한다', () {
      final result = NotificationListenerWrapper.isFinancialAlimtalkForTesting(
        '현대카드',
        '12,345,678원 할부 고급가구',
      );
      expect(result, isTrue, reason: '천만원 이상 금액도 매칭되어야 한다');
    });
  });

  group('_isFinancialApp 테스트', () {
    test('KB Pay 패키지를 금융 앱으로 인식해야 한다', () {
      final result = NotificationListenerWrapper.isFinancialAppForTesting(
        'com.kbcard.cxh.appcard',
      );
      expect(result, isTrue);
    });

    test('카카오톡을 금융 앱으로 인식해야 한다 (알림톡 수집)', () {
      final result = NotificationListenerWrapper.isFinancialAppForTesting(
        'com.kakao.talk',
      );
      expect(result, isTrue, reason: '카카오톡은 알림톡 수집을 위해 금융 앱 목록에 포함됨');
    });

    test('비금융 앱은 차단해야 한다', () {
      final result = NotificationListenerWrapper.isFinancialAppForTesting(
        'com.example.app',
      );
      expect(result, isFalse);
    });

    test('삼성페이를 인식해야 한다', () {
      final result = NotificationListenerWrapper.isFinancialAppForTesting(
        'com.samsung.android.spay',
      );
      expect(result, isTrue);
    });

    test('토스를 인식해야 한다', () {
      final result = NotificationListenerWrapper.isFinancialAppForTesting(
        'viva.republica.toss',
      );
      expect(result, isTrue);
    });

    test('경기지역화폐를 인식해야 한다', () {
      final result = NotificationListenerWrapper.isFinancialAppForTesting(
        'gov.gyeonggi.ggcard',
      );
      expect(result, isTrue);
    });
  });
}
