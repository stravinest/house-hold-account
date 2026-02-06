package com.household.shared.shared_household_account

import org.junit.Assert.*
import org.junit.Test

/**
 * NotificationFilterHelper 테스트
 * 금융 알림 필터링 순수 함수들의 동작을 검증하며,
 * 특히 카카오톡 알림톡 3중 검증이 핵심 테스트 대상임
 */
class NotificationFilterHelperTest {

    // =====================================================
    // isFinancialApp 테스트
    // =====================================================

    @Test
    fun `isFinancialApp - KB Pay 패키지를 금융 앱으로 인식한다`() {
        assertTrue(
            NotificationFilterHelper.isFinancialApp("com.kbcard.cxh.appcard")
        )
    }

    @Test
    fun `isFinancialApp - 대소문자를 무시하고 인식한다`() {
        assertTrue(
            NotificationFilterHelper.isFinancialApp("COM.KBCARD.CXH.APPCARD")
        )
    }

    @Test
    fun `isFinancialApp - KB국민은행 패키지를 인식한다`() {
        assertTrue(
            NotificationFilterHelper.isFinancialApp("com.kbstar.kbbank")
        )
    }

    @Test
    fun `isFinancialApp - 신한 SOL페이를 인식한다`() {
        assertTrue(
            NotificationFilterHelper.isFinancialApp("com.shcard.smartpay")
        )
    }

    @Test
    fun `isFinancialApp - 삼성카드를 인식한다`() {
        assertTrue(
            NotificationFilterHelper.isFinancialApp("kr.co.samsungcard.mpocket")
        )
    }

    @Test
    fun `isFinancialApp - 토스를 인식한다`() {
        assertTrue(
            NotificationFilterHelper.isFinancialApp("viva.republica.toss")
        )
    }

    @Test
    fun `isFinancialApp - 카카오페이를 인식한다`() {
        assertTrue(
            NotificationFilterHelper.isFinancialApp("com.kakaopay.app")
        )
    }

    @Test
    fun `isFinancialApp - 경기지역화폐를 인식한다`() {
        assertTrue(
            NotificationFilterHelper.isFinancialApp("gov.gyeonggi.ggcard")
        )
    }

    @Test
    fun `isFinancialApp - 카카오톡은 금융 앱이 아니다`() {
        assertFalse(
            NotificationFilterHelper.isFinancialApp("com.kakao.talk")
        )
    }

    @Test
    fun `isFinancialApp - 미등록 패키지를 차단한다`() {
        assertFalse(
            NotificationFilterHelper.isFinancialApp("com.example.app")
        )
    }

    @Test
    fun `isFinancialApp - 빈 문자열을 차단한다`() {
        assertFalse(
            NotificationFilterHelper.isFinancialApp("")
        )
    }

    // =====================================================
    // isAlimtalkApp 테스트
    // =====================================================

    @Test
    fun `isAlimtalkApp - 카카오톡을 인식한다`() {
        assertTrue(
            NotificationFilterHelper.isAlimtalkApp("com.kakao.talk")
        )
    }

    @Test
    fun `isAlimtalkApp - 대소문자를 무시한다`() {
        assertTrue(
            NotificationFilterHelper.isAlimtalkApp("COM.KAKAO.TALK")
        )
    }

    @Test
    fun `isAlimtalkApp - 카카오페이는 알림톡 앱이 아니다`() {
        assertFalse(
            NotificationFilterHelper.isAlimtalkApp("com.kakaopay.app")
        )
    }

    @Test
    fun `isAlimtalkApp - 빈 문자열은 false를 반환한다`() {
        assertFalse(
            NotificationFilterHelper.isAlimtalkApp("")
        )
    }

    // =====================================================
    // isMessageApp 테스트
    // =====================================================

    @Test
    fun `isMessageApp - 삼성 메시지 앱을 인식한다`() {
        assertTrue(
            NotificationFilterHelper.isMessageApp("com.samsung.android.messaging")
        )
    }

    @Test
    fun `isMessageApp - 구글 메시지 앱을 인식한다`() {
        assertTrue(
            NotificationFilterHelper.isMessageApp("com.google.android.apps.messaging")
        )
    }

    @Test
    fun `isMessageApp - Stock Android MMS를 인식한다`() {
        assertTrue(
            NotificationFilterHelper.isMessageApp("com.android.mms")
        )
    }

    @Test
    fun `isMessageApp - 비메시지 앱을 차단한다`() {
        assertFalse(
            NotificationFilterHelper.isMessageApp("com.example.app")
        )
    }

    @Test
    fun `isMessageApp - 금융 앱은 메시지 앱이 아니다`() {
        assertFalse(
            NotificationFilterHelper.isMessageApp("com.kbcard.cxh.appcard")
        )
    }

    // =====================================================
    // isFinancialAlimtalk - 3중 검증 (가장 중요한 테스트)
    // =====================================================

    @Test
    fun `isFinancialAlimtalk - KB국민카드 결제 알림을 통과시킨다`() {
        assertTrue(
            NotificationFilterHelper.isFinancialAlimtalk(
                title = "KB국민카드",
                content = "50,000원 승인 스타벅스"
            )
        )
    }

    @Test
    fun `isFinancialAlimtalk - 신한카드 승인 알림을 통과시킨다`() {
        assertTrue(
            NotificationFilterHelper.isFinancialAlimtalk(
                title = "신한카드",
                content = "30,000원 결제 완료"
            )
        )
    }

    @Test
    fun `isFinancialAlimtalk - 현대카드 할부 알림을 통과시킨다`() {
        assertTrue(
            NotificationFilterHelper.isFinancialAlimtalk(
                title = "현대카드",
                content = "1,200,000원 3개월 할부 삼성전자"
            )
        )
    }

    @Test
    fun `isFinancialAlimtalk - 카카오뱅크 이체 알림을 통과시킨다`() {
        assertTrue(
            NotificationFilterHelper.isFinancialAlimtalk(
                title = "카카오뱅크",
                content = "100,000원 이체"
            )
        )
    }

    @Test
    fun `isFinancialAlimtalk - 농협 입금 알림을 통과시킨다`() {
        assertTrue(
            NotificationFilterHelper.isFinancialAlimtalk(
                title = "NH농협",
                content = "500,000원 입금 홍길동"
            )
        )
    }

    @Test
    fun `isFinancialAlimtalk - 카카오페이 충전 알림을 통과시킨다`() {
        assertTrue(
            NotificationFilterHelper.isFinancialAlimtalk(
                title = "카카오페이",
                content = "10,000원 충전 완료"
            )
        )
    }

    @Test
    fun `isFinancialAlimtalk - 카카오톡 카드영수증 채널 알림을 통과시킨다`() {
        // 실제 카카오톡 알림톡에서 title이 "카카오톡 카드영수증"으로 올 수 있음
        assertTrue(
            NotificationFilterHelper.isFinancialAlimtalk(
                title = "카카오톡 카드영수증",
                content = "KB국민카드1004승인 전*규님 600원 일시불 02/06 20:49 설아 아이스크림 누적1,194,249원"
            )
        )
    }

    @Test
    fun `isFinancialAlimtalk - 금융채널이지만 거래키워드 없으면 차단한다`() {
        assertFalse(
            NotificationFilterHelper.isFinancialAlimtalk(
                title = "KB국민카드",
                content = "이벤트 당첨! 혜택을 받으세요 10,000원"
            )
        )
    }

    @Test
    fun `isFinancialAlimtalk - 금융채널이고 거래키워드 있지만 금액 없으면 차단한다`() {
        assertFalse(
            NotificationFilterHelper.isFinancialAlimtalk(
                title = "KB국민카드",
                content = "승인 처리 완료되었습니다"
            )
        )
    }

    @Test
    fun `isFinancialAlimtalk - 비금융 채널은 거래키워드와 금액이 있어도 차단한다`() {
        assertFalse(
            NotificationFilterHelper.isFinancialAlimtalk(
                title = "홍길동",
                content = "50,000원 승인 스타벅스"
            )
        )
    }

    @Test
    fun `isFinancialAlimtalk - title이 null이면 차단한다`() {
        assertFalse(
            NotificationFilterHelper.isFinancialAlimtalk(
                title = null,
                content = "50,000원 승인 스타벅스"
            )
        )
    }

    @Test
    fun `isFinancialAlimtalk - content가 null이면 차단한다`() {
        assertFalse(
            NotificationFilterHelper.isFinancialAlimtalk(
                title = "KB국민카드",
                content = null
            )
        )
    }

    @Test
    fun `isFinancialAlimtalk - 빈 title이면 차단한다`() {
        assertFalse(
            NotificationFilterHelper.isFinancialAlimtalk(
                title = "",
                content = "50,000원 승인 스타벅스"
            )
        )
    }

    @Test
    fun `isFinancialAlimtalk - 빈 content면 차단한다`() {
        assertFalse(
            NotificationFilterHelper.isFinancialAlimtalk(
                title = "KB국민카드",
                content = ""
            )
        )
    }

    @Test
    fun `isFinancialAlimtalk - 공백만 있는 title이면 차단한다`() {
        assertFalse(
            NotificationFilterHelper.isFinancialAlimtalk(
                title = "   ",
                content = "50,000원 승인 스타벅스"
            )
        )
    }

    @Test
    fun `isFinancialAlimtalk - 쿠팡 배송 알림은 차단한다`() {
        assertFalse(
            NotificationFilterHelper.isFinancialAlimtalk(
                title = "쿠팡",
                content = "배송 완료 50,000원 결제"
            )
        )
    }

    @Test
    fun `isFinancialAlimtalk - 배달의민족 주문 알림은 차단한다`() {
        assertFalse(
            NotificationFilterHelper.isFinancialAlimtalk(
                title = "배달의민족",
                content = "주문 완료 25,000원 결제"
            )
        )
    }

    @Test
    fun `isFinancialAlimtalk - 금융채널 공지사항은 차단한다`() {
        assertFalse(
            NotificationFilterHelper.isFinancialAlimtalk(
                title = "KB국민카드",
                content = "시스템 점검 안내 - 12월 31일"
            )
        )
    }

    @Test
    fun `isFinancialAlimtalk - 체크카드 사용 알림을 통과시킨다`() {
        assertTrue(
            NotificationFilterHelper.isFinancialAlimtalk(
                title = "국민카드",
                content = "체크카드 15,000원 스타벅스"
            )
        )
    }

    @Test
    fun `isFinancialAlimtalk - 잔액 알림을 통과시킨다`() {
        assertTrue(
            NotificationFilterHelper.isFinancialAlimtalk(
                title = "신한은행",
                content = "잔액 1,234,567원"
            )
        )
    }

    @Test
    fun `isFinancialAlimtalk - 환불 알림을 통과시킨다`() {
        assertTrue(
            NotificationFilterHelper.isFinancialAlimtalk(
                title = "삼성카드",
                content = "환불 50,000원 처리 완료"
            )
        )
    }

    @Test
    fun `isFinancialAlimtalk - 프로모션 메시지는 차단한다`() {
        assertFalse(
            NotificationFilterHelper.isFinancialAlimtalk(
                title = "KB국민카드",
                content = "포인트 적립 안내 - 새해 특별 이벤트"
            )
        )
    }

    // =====================================================
    // containsPaymentKeyword 테스트
    // =====================================================

    @Test
    fun `containsPaymentKeyword - 원 키워드가 포함된 텍스트를 인식한다`() {
        assertTrue(
            NotificationFilterHelper.containsPaymentKeyword("50,000원 승인")
        )
    }

    @Test
    fun `containsPaymentKeyword - 결제 키워드를 인식한다`() {
        assertTrue(
            NotificationFilterHelper.containsPaymentKeyword("결제 완료")
        )
    }

    @Test
    fun `containsPaymentKeyword - 이체 키워드를 인식한다`() {
        assertTrue(
            NotificationFilterHelper.containsPaymentKeyword("이체 처리되었습니다")
        )
    }

    @Test
    fun `containsPaymentKeyword - pay 키워드를 인식한다`() {
        assertTrue(
            NotificationFilterHelper.containsPaymentKeyword("KB Pay")
        )
    }

    @Test
    fun `containsPaymentKeyword - 관련 키워드가 없는 텍스트를 차단한다`() {
        assertFalse(
            NotificationFilterHelper.containsPaymentKeyword("안녕하세요")
        )
    }

    @Test
    fun `containsPaymentKeyword - 빈 문자열을 차단한다`() {
        assertFalse(
            NotificationFilterHelper.containsPaymentKeyword("")
        )
    }

    // =====================================================
    // normalizeContent 테스트
    // =====================================================

    @Test
    fun `normalizeContent - 줄바꿈을 공백으로 변환한다`() {
        assertEquals(
            "KB국민카드 50,000원 승인 스타벅스",
            NotificationFilterHelper.normalizeContent("KB국민카드\n50,000원\n승인\n스타벅스")
        )
    }

    @Test
    fun `normalizeContent - 연속 공백을 하나로 합친다`() {
        assertEquals(
            "KB국민카드 50,000원",
            NotificationFilterHelper.normalizeContent("KB국민카드    50,000원")
        )
    }

    @Test
    fun `normalizeContent - 앞뒤 공백을 제거한다`() {
        assertEquals(
            "KB국민카드",
            NotificationFilterHelper.normalizeContent("  KB국민카드  ")
        )
    }

    @Test
    fun `normalizeContent - 캐리지리턴을 처리한다`() {
        assertEquals(
            "KB국민카드 50,000원",
            NotificationFilterHelper.normalizeContent("KB국민카드\r\n50,000원")
        )
    }

    // =====================================================
    // determineSourceType 테스트
    // =====================================================

    @Test
    fun `determineSourceType - 메시지 앱이면 sms를 반환한다`() {
        assertEquals(
            "sms",
            NotificationFilterHelper.determineSourceType(isFromMessageApp = true)
        )
    }

    @Test
    fun `determineSourceType - 메시지 앱이 아니면 notification을 반환한다`() {
        assertEquals(
            "notification",
            NotificationFilterHelper.determineSourceType(isFromMessageApp = false)
        )
    }

    // =====================================================
    // getExpectedSource 테스트
    // =====================================================

    @Test
    fun `getExpectedSource - sms이면 sms를 반환한다`() {
        assertEquals(
            "sms",
            NotificationFilterHelper.getExpectedSource("sms")
        )
    }

    @Test
    fun `getExpectedSource - notification이면 push를 반환한다`() {
        assertEquals(
            "push",
            NotificationFilterHelper.getExpectedSource("notification")
        )
    }

    @Test
    fun `getExpectedSource - 기타 값이면 push를 반환한다`() {
        assertEquals(
            "push",
            NotificationFilterHelper.getExpectedSource("unknown")
        )
    }

    // =====================================================
    // 상수 리스트 검증
    // =====================================================

    @Test
    fun `FINANCIAL_APP_PACKAGES - 비어있지 않다`() {
        assertTrue(
            NotificationFilterHelper.FINANCIAL_APP_PACKAGES.isNotEmpty()
        )
    }

    @Test
    fun `FINANCIAL_CHANNEL_KEYWORDS - 비어있지 않다`() {
        assertTrue(
            NotificationFilterHelper.FINANCIAL_CHANNEL_KEYWORDS.isNotEmpty()
        )
    }

    @Test
    fun `ALIMTALK_TRANSACTION_KEYWORDS - 비어있지 않다`() {
        assertTrue(
            NotificationFilterHelper.ALIMTALK_TRANSACTION_KEYWORDS.isNotEmpty()
        )
    }

    @Test
    fun `PAYMENT_KEYWORDS - 비어있지 않다`() {
        assertTrue(
            NotificationFilterHelper.PAYMENT_KEYWORDS.isNotEmpty()
        )
    }
}
