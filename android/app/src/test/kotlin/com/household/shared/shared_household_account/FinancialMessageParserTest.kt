package com.household.shared.shared_household_account

import org.junit.Assert.*
import org.junit.Test

/**
 * FinancialMessageParser 테스트
 * 금융 SMS/Push 메시지의 파싱 로직을 검증한다.
 * parse(기본 파싱), parseWithFormat(학습된 포맷), generateDuplicateHash(해시 생성) 테스트
 */
class FinancialMessageParserTest {

    // =====================================================
    // parse - 기본 파싱 테스트
    // =====================================================

    @Test
    fun `parse - KB국민카드 승인 SMS를 파싱한다`() {
        val result = FinancialMessageParser.parse(
            sender = "com.kbcard.cxh.appcard",
            content = "KB국민카드 50,000원 승인 스타벅스 01/15 14:30"
        )

        assertTrue("파싱 결과가 true여야 한다", result.isParsed)
        assertEquals("금액이 50000이어야 한다", 50000, result.amount)
        assertEquals("지출 타입이어야 한다", "expense", result.transactionType)
    }

    @Test
    fun `parse - 신한카드 결제 메시지를 파싱한다`() {
        val result = FinancialMessageParser.parse(
            sender = "com.shcard.smartpay",
            content = "신한카드 결제 30,000원 일시불 홍대 카페"
        )

        assertTrue("파싱 결과가 true여야 한다", result.isParsed)
        assertEquals("금액이 30000이어야 한다", 30000, result.amount)
        assertEquals("지출 타입이어야 한다", "expense", result.transactionType)
    }

    @Test
    fun `parse - 입금 메시지를 income으로 파싱한다`() {
        val result = FinancialMessageParser.parse(
            sender = "com.kbstar.kbbank",
            content = "KB국민은행 입금 500,000원 홍길동"
        )

        assertTrue("파싱 결과가 true여야 한다", result.isParsed)
        assertEquals("금액이 500000이어야 한다", 500000, result.amount)
        assertEquals("수입 타입이어야 한다", "income", result.transactionType)
    }

    @Test
    fun `parse - 금액이 없는 메시지는 isParsed가 false다`() {
        val result = FinancialMessageParser.parse(
            sender = "com.kbcard.cxh.appcard",
            content = "KB국민카드 앱 업데이트 안내"
        )

        assertFalse("금액이 없으면 파싱 실패해야 한다", result.isParsed)
        assertNull("금액이 null이어야 한다", result.amount)
    }

    @Test
    fun `parse - 취소 메시지를 처리한다`() {
        val result = FinancialMessageParser.parse(
            sender = "com.kbcard.cxh.appcard",
            content = "KB국민카드 승인취소 50,000원 스타벅스"
        )

        assertFalse("취소 메시지는 isParsed가 false여야 한다", result.isParsed)
        assertEquals("매칭 패턴이 cancel이어야 한다", "cancel", result.matchedPattern)
    }

    @Test
    fun `parse - 큰 금액을 올바르게 파싱한다`() {
        val result = FinancialMessageParser.parse(
            sender = "com.kbcard.cxh.appcard",
            content = "KB국민카드 1,200,000원 승인 삼성전자"
        )

        assertTrue("파싱 결과가 true여야 한다", result.isParsed)
        assertEquals("금액이 1200000이어야 한다", 1200000, result.amount)
    }

    @Test
    fun `parse - 쉼표 없는 소액을 파싱한다`() {
        val result = FinancialMessageParser.parse(
            sender = "com.kbcard.cxh.appcard",
            content = "KB국민카드 승인 500원 편의점"
        )

        assertTrue("파싱 결과가 true여야 한다", result.isParsed)
        assertEquals("금액이 500이어야 한다", 500, result.amount)
    }

    @Test
    fun `parse - 충전 메시지를 income으로 파싱한다`() {
        val result = FinancialMessageParser.parse(
            sender = "gov.gyeonggi.ggcard",
            content = "경기지역화폐 충전 100,000원"
        )

        assertTrue("파싱 결과가 true여야 한다", result.isParsed)
        assertEquals("수입 타입이어야 한다", "income", result.transactionType)
    }

    // =====================================================
    // parseWithFormat - 학습된 포맷 파싱 테스트
    // =====================================================

    @Test
    fun `parseWithFormat - 학습된 정규식으로 금액을 추출한다`() {
        val format = LearnedPushFormat(
            id = "test-format-1",
            paymentMethodId = "pm-1",
            packageName = "com.kbcard.cxh.appcard",
            appKeywords = listOf("KB국민카드"),
            amountRegex = "([0-9,]+)원",
            typeKeywords = mapOf(
                "expense" to listOf("승인", "결제"),
                "income" to listOf("입금")
            ),
            merchantRegex = "원\\s+(.+)$",
            dateRegex = null,
            confidence = 0.9
        )

        val result = FinancialMessageParser.parseWithFormat(
            content = "KB국민카드 50,000원 승인 스타벅스",
            format = format
        )

        assertTrue("학습된 포맷으로 파싱이 성공해야 한다", result.isParsed)
        assertEquals("금액이 50000이어야 한다", 50000, result.amount)
    }

    @Test
    fun `parseWithFormat - 정규식이 실패하면 기본 파싱으로 fallback한다`() {
        val format = LearnedPushFormat(
            id = "test-format-2",
            paymentMethodId = "pm-1",
            packageName = "com.kbcard.cxh.appcard",
            appKeywords = listOf("KB국민카드"),
            amountRegex = "INVALID_REGEX_THAT_WONT_MATCH",
            typeKeywords = mapOf(
                "expense" to listOf("승인", "결제"),
                "income" to listOf("입금")
            ),
            merchantRegex = null,
            dateRegex = null,
            confidence = 0.8
        )

        val result = FinancialMessageParser.parseWithFormat(
            content = "KB국민카드 50,000원 승인 스타벅스",
            format = format
        )

        // amountRegex가 매칭되지 않아도 기본 AMOUNT_PATTERN으로 fallback
        assertTrue("fallback 파싱이 성공해야 한다", result.isParsed)
        assertEquals("금액이 50000이어야 한다", 50000, result.amount)
    }

    @Test
    fun `parseWithFormat - 취소 메시지는 isParsed가 false다`() {
        val format = LearnedPushFormat(
            id = "test-format-3",
            paymentMethodId = "pm-1",
            packageName = "com.kbcard.cxh.appcard",
            appKeywords = listOf("KB국민카드"),
            amountRegex = "([0-9,]+)원",
            typeKeywords = mapOf(
                "expense" to listOf("승인", "결제"),
                "income" to listOf("입금")
            ),
            merchantRegex = null,
            dateRegex = null
        )

        val result = FinancialMessageParser.parseWithFormat(
            content = "KB국민카드 취소 50,000원",
            format = format
        )

        assertFalse("취소 메시지는 isParsed가 false여야 한다", result.isParsed)
    }

    // =====================================================
    // generateDuplicateHash 테스트
    // =====================================================

    @Test
    fun `generateDuplicateHash - 동일한 입력이면 동일한 해시를 생성한다`() {
        val hash1 = FinancialMessageParser.generateDuplicateHash(
            amount = 50000,
            paymentMethodId = "pm-1",
            timestamp = 1700000000000
        )
        val hash2 = FinancialMessageParser.generateDuplicateHash(
            amount = 50000,
            paymentMethodId = "pm-1",
            timestamp = 1700000000000
        )

        assertEquals("동일한 입력은 동일한 해시를 반환해야 한다", hash1, hash2)
    }

    @Test
    fun `generateDuplicateHash - 다른 금액이면 다른 해시를 생성한다`() {
        val hash1 = FinancialMessageParser.generateDuplicateHash(
            amount = 50000,
            paymentMethodId = "pm-1",
            timestamp = 1700000000000
        )
        val hash2 = FinancialMessageParser.generateDuplicateHash(
            amount = 30000,
            paymentMethodId = "pm-1",
            timestamp = 1700000000000
        )

        assertNotEquals("다른 금액은 다른 해시를 반환해야 한다", hash1, hash2)
    }

    @Test
    fun `generateDuplicateHash - 같은 시간 버킷 내에서는 동일한 해시를 생성한다`() {
        val bucketDuration = NotificationConfig.DUPLICATE_BUCKET_DURATION_MS
        val baseTime = 1700000000000L

        // 같은 버킷 내 (1초 차이)
        val hash1 = FinancialMessageParser.generateDuplicateHash(
            amount = 50000,
            paymentMethodId = "pm-1",
            timestamp = baseTime
        )
        val hash2 = FinancialMessageParser.generateDuplicateHash(
            amount = 50000,
            paymentMethodId = "pm-1",
            timestamp = baseTime + 1000 // 1초 후
        )

        assertEquals("같은 버킷 내에서는 동일한 해시여야 한다", hash1, hash2)
    }

    @Test
    fun `generateDuplicateHash - 다른 시간 버킷이면 다른 해시를 생성한다`() {
        val bucketDuration = NotificationConfig.DUPLICATE_BUCKET_DURATION_MS
        val baseTime = 1700000000000L

        val hash1 = FinancialMessageParser.generateDuplicateHash(
            amount = 50000,
            paymentMethodId = "pm-1",
            timestamp = baseTime
        )
        val hash2 = FinancialMessageParser.generateDuplicateHash(
            amount = 50000,
            paymentMethodId = "pm-1",
            timestamp = baseTime + bucketDuration + 1 // 다른 버킷
        )

        assertNotEquals("다른 버킷이면 다른 해시여야 한다", hash1, hash2)
    }

    @Test
    fun `generateDuplicateHash - paymentMethodId가 null이면 unknown을 사용한다`() {
        val hash = FinancialMessageParser.generateDuplicateHash(
            amount = 50000,
            paymentMethodId = null,
            timestamp = 1700000000000
        )

        assertNotNull("null paymentMethodId도 해시를 생성해야 한다", hash)
        assertTrue("해시가 빈 문자열이 아니어야 한다", hash.isNotEmpty())
    }

    @Test
    fun `generateDuplicateHash - 해시가 MD5 형식인지 확인한다`() {
        val hash = FinancialMessageParser.generateDuplicateHash(
            amount = 50000,
            paymentMethodId = "pm-1",
            timestamp = 1700000000000
        )

        // MD5 해시는 32자리 16진수 문자열
        assertEquals("MD5 해시 길이는 32여야 한다", 32, hash.length)
        assertTrue(
            "해시는 16진수 문자로만 구성되어야 한다",
            hash.matches(Regex("^[0-9a-f]+$"))
        )
    }

    // =====================================================
    // ParsedResult 속성 테스트
    // =====================================================

    @Test
    fun `ParsedResult - amount와 transactionType이 모두 있으면 isParsed는 true다`() {
        val result = FinancialMessageParser.ParsedResult(
            amount = 50000,
            transactionType = "expense",
            merchant = "스타벅스",
            dateTimeMillis = null,
            cardLastDigits = null,
            confidence = 0.7,
            matchedPattern = null
        )

        assertTrue("amount와 transactionType이 있으면 isParsed는 true여야 한다", result.isParsed)
    }

    @Test
    fun `ParsedResult - amount가 null이면 isParsed는 false다`() {
        val result = FinancialMessageParser.ParsedResult(
            amount = null,
            transactionType = "expense",
            merchant = null,
            dateTimeMillis = null,
            cardLastDigits = null,
            confidence = 0.0,
            matchedPattern = null
        )

        assertFalse("amount가 null이면 isParsed는 false여야 한다", result.isParsed)
    }

    @Test
    fun `ParsedResult - transactionType이 null이면 isParsed는 false다`() {
        val result = FinancialMessageParser.ParsedResult(
            amount = 50000,
            transactionType = null,
            merchant = null,
            dateTimeMillis = null,
            cardLastDigits = null,
            confidence = 0.0,
            matchedPattern = null
        )

        assertFalse("transactionType이 null이면 isParsed는 false여야 한다", result.isParsed)
    }
}
