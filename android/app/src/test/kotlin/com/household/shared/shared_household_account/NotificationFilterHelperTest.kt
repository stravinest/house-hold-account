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

    // =====================================================
    // extractLatestSmsFromContent - 누적 SMS content 추출
    // =====================================================

    @Test
    fun `extractLatestSmsFromContent - 단일 SMS content는 그대로 반환한다`() {
        val content =
            "[Web발신] KB국민카드0038승인 제*현님 12,900원 일시불 02/08 12:27 갤러리아광교점( 누적1,348,277원"
        assertEquals(
            content,
            NotificationFilterHelper.extractLatestSmsFromContent(content)
        )
    }

    @Test
    fun `extractLatestSmsFromContent - Web발신 구분자가 없는 content는 그대로 반환한다`() {
        val content = "KB국민카드 승인 12,900원 일시불"
        assertEquals(
            content,
            NotificationFilterHelper.extractLatestSmsFromContent(content)
        )
    }

    @Test
    fun `extractLatestSmsFromContent - 2개 SMS가 누적된 경우 마지막 SMS만 추출한다`() {
        val content =
            "[Web발신] KB국민카드0038승인 제*현님 12,900원 일시불 02/08 12:27 갤러리아광교점( 누적1,348,277원 " +
            "[Web발신] KB국민카드0038승인 제*현님 11,000원 일시불 02/08 12:30 갤러리아광교점( 누적1,359,277원"
        val result = NotificationFilterHelper.extractLatestSmsFromContent(content)
        assertTrue("마지막 SMS 금액 11,000원이 포함되어야 한다", result.contains("11,000원"))
        assertFalse("이전 SMS 금액 12,900원은 포함되지 않아야 한다", result.contains("12,900원"))
        assertTrue("[Web발신] 접두사가 유지되어야 한다", result.startsWith("[Web발신]"))
    }

    @Test
    fun `extractLatestSmsFromContent - 3개 SMS가 누적된 경우 마지막 SMS만 추출한다`() {
        val content =
            "[Web발신] KB국민카드0038승인 제*현님 12,900원 일시불 02/08 12:27 갤러리아광교점( 누적1,348,277원 " +
            "[Web발신] KB국민카드0038승인 제*현님 11,000원 일시불 02/08 12:30 갤러리아광교점( 누적1,359,277원 " +
            "[Web발신] KB국민카드0038승인 제*현님 5,310원 일시불 02/08 13:07 갤러리아광교점( 누적1,364,587원"
        val result = NotificationFilterHelper.extractLatestSmsFromContent(content)
        assertTrue("마지막 SMS 금액 5,310원이 포함되어야 한다", result.contains("5,310원"))
        assertFalse("첫 번째 SMS 금액 12,900원은 포함되지 않아야 한다", result.contains("12,900원"))
        assertFalse("두 번째 SMS 금액 11,000원은 포함되지 않아야 한다", result.contains("11,000원"))
        assertTrue("[Web발신] 접두사가 유지되어야 한다", result.startsWith("[Web발신]"))
    }

    @Test
    fun `extractLatestSmsFromContent - 4개 SMS 누적 실제 버그 시나리오를 처리한다`() {
        // 실제 DB에서 발견된 버그 데이터 재현
        val content =
            "\u2068\u20681588-1688\u2069 [Web발신] KB국민카드0038승인 제*현님 12,900원 일시불 02/08 12:27 갤러리아광교점( 누적1,348,277원 " +
            "[Web발신] KB국민카드0038승인 제*현님 11,000원 일시불 02/08 12:30 갤러리아광교점( 누적1,359,277원 " +
            "[Web발신] KB국민카드0038승인 제*현님 5,310원 일시불 02/08 13:07 갤러리아광교점( 누적1,364,587원 " +
            "[Web발신] KB국민카드0038승인 제*현님 21,500원 일시불 02/08 13:53 돌핀웨일 광교점 누적1,386,087원"
        val result = NotificationFilterHelper.extractLatestSmsFromContent(content)
        assertTrue("마지막 SMS인 21,500원이 추출되어야 한다", result.contains("21,500원"))
        assertTrue("마지막 SMS의 가맹점명이 포함되어야 한다", result.contains("돌핀웨일 광교점"))
        assertFalse("첫 번째 SMS인 12,900원은 포함되지 않아야 한다", result.contains("12,900원"))
    }

    @Test
    fun `extractLatestSmsFromContent - 현대카드 등 다른 카드사의 누적 SMS도 처리한다`() {
        val content =
            "[Web발신] 네이버 현대카드 승인 제*현 2,000원 일시불 02/08 12:02 아쿠아플라넷주식 누적437,437원 " +
            "[Web발신] 네이버 현대카드 승인 제*현 5,000원 일시불 02/08 13:00 스타벅스 누적442,437원"
        val result = NotificationFilterHelper.extractLatestSmsFromContent(content)
        assertTrue("마지막 SMS 금액 5,000원이 포함되어야 한다", result.contains("5,000원"))
        assertTrue("마지막 SMS의 가맹점명이 포함되어야 한다", result.contains("스타벅스"))
        assertFalse("이전 SMS 금액 2,000원은 포함되지 않아야 한다", result.contains("2,000원"))
        assertFalse("이전 SMS의 가맹점명은 포함되지 않아야 한다", result.contains("아쿠아플라넷"))
    }

    @Test
    fun `extractLatestSmsFromContent - 웹발신 구분자도 처리한다`() {
        val content =
            "[웹발신] KB국민카드 승인 12,900원 " +
            "[웹발신] KB국민카드 승인 5,000원"
        val result = NotificationFilterHelper.extractLatestSmsFromContent(content)
        assertTrue("마지막 SMS 금액 5,000원이 포함되어야 한다", result.contains("5,000원"))
        assertFalse("이전 SMS 금액 12,900원은 포함되지 않아야 한다", result.contains("12,900원"))
        assertTrue("[웹발신] 접두사가 유지되어야 한다", result.startsWith("[웹발신]"))
    }

    // =====================================================
    // extractLatestSmsFromContent - 엣지 케이스
    // =====================================================

    @Test
    fun `extractLatestSmsFromContent - 빈 문자열은 그대로 반환한다`() {
        assertEquals(
            "",
            NotificationFilterHelper.extractLatestSmsFromContent("")
        )
    }

    @Test
    fun `extractLatestSmsFromContent - 구분자만 있는 경우 원본을 그대로 반환한다`() {
        // split("[Web발신]") -> ["", ""], lastPart = "" -> isBlank -> continue
        val content = "[Web발신]"
        assertEquals(
            "구분자만 있고 내용이 없으면 원본을 그대로 반환해야 한다",
            content,
            NotificationFilterHelper.extractLatestSmsFromContent(content)
        )
    }

    @Test
    fun `extractLatestSmsFromContent - 구분자 뒤에 공백만 있는 경우 원본을 그대로 반환한다`() {
        // split("[Web발신]") -> ["", "   "], lastPart = "   " -> trim -> "" -> isBlank -> continue
        val content = "[Web발신]   "
        assertEquals(
            "구분자 뒤 공백만 있으면 원본을 그대로 반환해야 한다",
            content,
            NotificationFilterHelper.extractLatestSmsFromContent(content)
        )
    }

    @Test
    fun `extractLatestSmsFromContent - 구분자가 content 끝에 있는 경우 원본을 그대로 반환한다`() {
        // split("[Web발신]") -> ["내용 ", ""], lastPart = "" -> isBlank -> continue
        val content = "KB국민카드 승인 12,900원 [Web발신]"
        assertEquals(
            "구분자가 끝에 있고 뒤에 내용이 없으면 원본을 그대로 반환해야 한다",
            content,
            NotificationFilterHelper.extractLatestSmsFromContent(content)
        )
    }

    @Test
    fun `extractLatestSmsFromContent - 구분자 부분 매칭은 무시한다`() {
        // "[Web발신" 은 "[Web발신]"와 contains 매칭 안됨
        val content = "[Web발신 KB국민카드 승인 12,900원"
        assertEquals(
            "닫는 괄호가 없는 불완전한 구분자는 무시하고 원본을 반환해야 한다",
            content,
            NotificationFilterHelper.extractLatestSmsFromContent(content)
        )
    }

    @Test
    fun `extractLatestSmsFromContent - 구분자 앞에 접두사 텍스트가 있는 비표준 포맷도 처리한다`() {
        // Samsung Messages가 전화번호를 구분자 앞에 붙이는 경우
        // split("[Web발신]") -> ["1588-1688 ", " KB국민카드 승인 12,900원"]
        val content = "1588-1688 [Web발신] KB국민카드 승인 12,900원"
        val result = NotificationFilterHelper.extractLatestSmsFromContent(content)
        assertTrue("구분자 뒤의 실제 SMS 내용이 포함되어야 한다", result.contains("12,900원"))
        assertTrue("[Web발신] 접두사가 유지되어야 한다", result.startsWith("[Web발신]"))
        assertFalse("구분자 앞의 전화번호는 제거되어야 한다", result.contains("1588-1688"))
    }

    @Test
    fun `extractLatestSmsFromContent - Web발신과 웹발신이 혼합된 경우 첫 번째 매칭 구분자 기준으로 처리한다`() {
        // [Web발신]이 SMS_CONTENT_DELIMITERS에서 먼저 매칭됨
        // 실제로는 통신사가 동일 구분자를 사용하므로 이 시나리오는 극히 드묾
        val content =
            "[웹발신] 첫번째 SMS 12,900원 " +
            "[Web발신] 두번째 SMS 5,000원"
        val result = NotificationFilterHelper.extractLatestSmsFromContent(content)
        // [Web발신]이 먼저 매칭되어 split -> ["[웹발신] 첫번째 SMS 12,900원 ", " 두번째 SMS 5,000원"]
        assertTrue("두번째 SMS 금액이 포함되어야 한다", result.contains("5,000원"))
        assertTrue("[Web발신] 접두사로 시작해야 한다", result.startsWith("[Web발신]"))
    }

    @Test
    fun `extractLatestSmsFromContent - 줄바꿈이 포함된 누적 SMS도 처리한다`() {
        val content =
            "[Web발신]\nKB국민카드 승인 12,900원\n갤러리아광교점 " +
            "[Web발신]\nKB국민카드 승인 5,000원\n스타벅스"
        val result = NotificationFilterHelper.extractLatestSmsFromContent(content)
        assertTrue("마지막 SMS 금액이 포함되어야 한다", result.contains("5,000원"))
        assertTrue("마지막 SMS 가맹점이 포함되어야 한다", result.contains("스타벅스"))
        assertFalse("이전 SMS 금액은 포함되지 않아야 한다", result.contains("12,900원"))
    }

    // =====================================================
    // SMS_CONTENT_DELIMITERS 상수 검증
    // =====================================================

    @Test
    fun `SMS_CONTENT_DELIMITERS - 비어있지 않다`() {
        assertTrue(
            NotificationConfig.SMS_CONTENT_DELIMITERS.isNotEmpty()
        )
    }

    @Test
    fun `SMS_CONTENT_DELIMITERS - Web발신 구분자가 포함되어 있다`() {
        assertTrue(
            NotificationConfig.SMS_CONTENT_DELIMITERS.contains("[Web발신]")
        )
    }

    @Test
    fun `SMS_CONTENT_DELIMITERS - 웹발신 구분자가 포함되어 있다`() {
        assertTrue(
            NotificationConfig.SMS_CONTENT_DELIMITERS.contains("[웹발신]")
        )
    }
}
