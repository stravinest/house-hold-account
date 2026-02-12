package com.household.shared.shared_household_account

import org.junit.Assert.*
import org.junit.Test

/**
 * SupabaseHelper 테스트
 * 데이터 클래스 및 유틸리티 함수 테스트
 *
 * 주의: SupabaseHelper는 Android Context와 SharedPreferences에 의존하므로
 * 실제 인스턴스 테스트는 Android instrumentation test로 작성해야 함
 * 여기서는 데이터 클래스와 상수만 테스트
 */
class SupabaseHelperTest {

    @Test
    fun `PaymentMethodAutoSettings - autoSaveMode가 auto면 isAutoMode는 true다`() {
        val settings = SupabaseHelper.PaymentMethodAutoSettings(
            autoSaveMode = "auto",
            autoCollectSource = "sms"
        )

        assertTrue("autoSaveMode가 auto면 isAutoMode가 true여야 한다", settings.isAutoMode)
    }

    @Test
    fun `PaymentMethodAutoSettings - autoSaveMode가 suggest면 isAutoMode는 false다`() {
        val settings = SupabaseHelper.PaymentMethodAutoSettings(
            autoSaveMode = "suggest",
            autoCollectSource = "sms"
        )

        assertFalse("autoSaveMode가 suggest면 isAutoMode가 false여야 한다", settings.isAutoMode)
    }

    @Test
    fun `PaymentMethodAutoSettings - autoSaveMode가 manual이면 isAutoMode는 false다`() {
        val settings = SupabaseHelper.PaymentMethodAutoSettings(
            autoSaveMode = "manual",
            autoCollectSource = "sms"
        )

        assertFalse("autoSaveMode가 manual이면 isAutoMode가 false여야 한다", settings.isAutoMode)
    }

    @Test
    fun `PaymentMethodAutoSettings - autoCollectSource가 sms면 isSmsSource는 true다`() {
        val settings = SupabaseHelper.PaymentMethodAutoSettings(
            autoSaveMode = "auto",
            autoCollectSource = "sms"
        )

        assertTrue("autoCollectSource가 sms면 isSmsSource가 true여야 한다", settings.isSmsSource)
    }

    @Test
    fun `PaymentMethodAutoSettings - autoCollectSource가 push면 isPushSource는 true다`() {
        val settings = SupabaseHelper.PaymentMethodAutoSettings(
            autoSaveMode = "auto",
            autoCollectSource = "push"
        )

        assertTrue("autoCollectSource가 push면 isPushSource가 true여야 한다", settings.isPushSource)
    }

    @Test
    fun `PaymentMethodAutoSettings - autoCollectSource가 push면 isSmsSource는 false다`() {
        val settings = SupabaseHelper.PaymentMethodAutoSettings(
            autoSaveMode = "auto",
            autoCollectSource = "push"
        )

        assertFalse("autoCollectSource가 push면 isSmsSource가 false여야 한다", settings.isSmsSource)
    }

    @Test
    fun `PaymentMethodAutoSettings - autoCollectSource가 sms면 isPushSource는 false다`() {
        val settings = SupabaseHelper.PaymentMethodAutoSettings(
            autoSaveMode = "auto",
            autoCollectSource = "sms"
        )

        assertFalse("autoCollectSource가 sms면 isPushSource가 false여야 한다", settings.isPushSource)
    }

    @Test
    fun `Category 데이터 클래스 - 모든 필드를 올바르게 저장한다`() {
        val category = Category(
            id = "cat-1",
            name = "식비",
            icon = "restaurant",
            color = "#FF5733"
        )

        assertEquals("ID가 올바르게 저장되어야 한다", "cat-1", category.id)
        assertEquals("이름이 올바르게 저장되어야 한다", "식비", category.name)
        assertEquals("아이콘이 올바르게 저장되어야 한다", "restaurant", category.icon)
        assertEquals("색상이 올바르게 저장되어야 한다", "#FF5733", category.color)
    }

    @Test
    fun `LearnedPushFormat 데이터 클래스 - 모든 필드를 올바르게 저장한다`() {
        val format = LearnedPushFormat(
            id = "format-1",
            paymentMethodId = "pm-1",
            packageName = "com.kbcard.cxh.appcard",
            appKeywords = listOf("KB국민카드", "KB Pay"),
            amountRegex = "([0-9,]+)원",
            typeKeywords = mapOf("expense" to listOf("승인", "결제")),
            merchantRegex = "원\\s+(.+)$",
            dateRegex = "(\\d{2}/\\d{2})",
            confidence = 0.9
        )

        assertEquals("ID가 올바르게 저장되어야 한다", "format-1", format.id)
        assertEquals("결제수단 ID가 올바르게 저장되어야 한다", "pm-1", format.paymentMethodId)
        assertEquals("패키지명이 올바르게 저장되어야 한다", "com.kbcard.cxh.appcard", format.packageName)
        assertEquals("앱 키워드가 올바르게 저장되어야 한다", 2, format.appKeywords.size)
        assertEquals("금액 정규식이 올바르게 저장되어야 한다", "([0-9,]+)원", format.amountRegex)
        assertEquals("신뢰도가 올바르게 저장되어야 한다", 0.9, format.confidence ?: 0.0, 0.001)
    }

    @Test
    fun `LearnedPushFormat 데이터 클래스 - confidence 기본값은 0점8이다`() {
        val format = LearnedPushFormat(
            id = "format-1",
            paymentMethodId = "pm-1",
            packageName = "com.test.app",
            appKeywords = listOf("Test"),
            amountRegex = "([0-9,]+)원",
            typeKeywords = mapOf("expense" to listOf("승인")),
            merchantRegex = null,
            dateRegex = null
        )

        assertEquals("기본 신뢰도가 0.8이어야 한다", 0.8, format.confidence ?: 0.0, 0.001)
    }

    @Test
    fun `LearnedSmsFormat 데이터 클래스 - 모든 필드를 올바르게 저장한다`() {
        val format = LearnedSmsFormat(
            id = "sms-format-1",
            paymentMethodId = "pm-1",
            senderPattern = "15881688",
            senderKeywords = listOf("KB", "국민카드"),
            amountRegex = "([0-9,]+)원",
            typeKeywords = mapOf("expense" to listOf("승인", "결제")),
            merchantRegex = "원\\s+(.+)",
            dateRegex = "(\\d{2}/\\d{2})"
        )

        assertEquals("ID가 올바르게 저장되어야 한다", "sms-format-1", format.id)
        assertEquals("결제수단 ID가 올바르게 저장되어야 한다", "pm-1", format.paymentMethodId)
        assertEquals("발신자 패턴이 올바르게 저장되어야 한다", "15881688", format.senderPattern)
        assertEquals("발신자 키워드가 올바르게 저장되어야 한다", 2, format.senderKeywords.size)
        assertEquals("금액 정규식이 올바르게 저장되어야 한다", "([0-9,]+)원", format.amountRegex)
    }

    @Test
    fun `PaymentMethodInfo 데이터 클래스 - 모든 필드를 올바르게 저장한다`() {
        val info = SupabaseHelper.PaymentMethodInfo(
            id = "pm-1",
            name = "KB국민카드",
            autoSaveMode = "auto",
            autoCollectSource = "push",
            ownerUserId = "user-123"
        )

        assertEquals("ID가 올바르게 저장되어야 한다", "pm-1", info.id)
        assertEquals("이름이 올바르게 저장되어야 한다", "KB국민카드", info.name)
        assertEquals("자동저장 모드가 올바르게 저장되어야 한다", "auto", info.autoSaveMode)
        assertEquals("자동수집 소스가 올바르게 저장되어야 한다", "push", info.autoCollectSource)
        assertEquals("소유자 ID가 올바르게 저장되어야 한다", "user-123", info.ownerUserId)
    }

    @Test
    fun `PaymentMethodAutoSettings - 다양한 조합을 올바르게 처리한다`() {
        val autoSms = SupabaseHelper.PaymentMethodAutoSettings("auto", "sms")
        val suggestPush = SupabaseHelper.PaymentMethodAutoSettings("suggest", "push")
        val manualSms = SupabaseHelper.PaymentMethodAutoSettings("manual", "sms")

        assertTrue("auto+sms: isAutoMode가 true여야 한다", autoSms.isAutoMode)
        assertTrue("auto+sms: isSmsSource가 true여야 한다", autoSms.isSmsSource)

        assertFalse("suggest+push: isAutoMode가 false여야 한다", suggestPush.isAutoMode)
        assertTrue("suggest+push: isPushSource가 true여야 한다", suggestPush.isPushSource)

        assertFalse("manual+sms: isAutoMode가 false여야 한다", manualSms.isAutoMode)
        assertTrue("manual+sms: isSmsSource가 true여야 한다", manualSms.isSmsSource)
    }

    @Test
    fun `LearnedPushFormat - typeKeywords가 여러 타입을 포함할 수 있다`() {
        val format = LearnedPushFormat(
            id = "format-1",
            paymentMethodId = "pm-1",
            packageName = "com.test.app",
            appKeywords = listOf("Test"),
            amountRegex = "([0-9,]+)원",
            typeKeywords = mapOf(
                "expense" to listOf("승인", "결제"),
                "income" to listOf("입금", "충전")
            ),
            merchantRegex = null,
            dateRegex = null
        )

        assertTrue("expense 키워드가 포함되어야 한다", format.typeKeywords.containsKey("expense"))
        assertTrue("income 키워드가 포함되어야 한다", format.typeKeywords.containsKey("income"))
        assertEquals("expense 키워드가 2개여야 한다", 2, format.typeKeywords["expense"]?.size)
        assertEquals("income 키워드가 2개여야 한다", 2, format.typeKeywords["income"]?.size)
    }

    @Test
    fun `LearnedPushFormat - merchantRegex와 dateRegex는 nullable이다`() {
        val formatWithoutRegex = LearnedPushFormat(
            id = "format-1",
            paymentMethodId = "pm-1",
            packageName = "com.test.app",
            appKeywords = listOf("Test"),
            amountRegex = "([0-9,]+)원",
            typeKeywords = mapOf("expense" to listOf("승인")),
            merchantRegex = null,
            dateRegex = null
        )

        assertNull("merchantRegex가 null일 수 있어야 한다", formatWithoutRegex.merchantRegex)
        assertNull("dateRegex가 null일 수 있어야 한다", formatWithoutRegex.dateRegex)
    }

    @Test
    fun `LearnedSmsFormat - merchantRegex와 dateRegex는 nullable이다`() {
        val formatWithoutRegex = LearnedSmsFormat(
            id = "sms-format-1",
            paymentMethodId = "pm-1",
            senderPattern = "15881688",
            senderKeywords = listOf("KB"),
            amountRegex = "([0-9,]+)원",
            typeKeywords = mapOf("expense" to listOf("승인")),
            merchantRegex = null,
            dateRegex = null
        )

        assertNull("merchantRegex가 null일 수 있어야 한다", formatWithoutRegex.merchantRegex)
        assertNull("dateRegex가 null일 수 있어야 한다", formatWithoutRegex.dateRegex)
    }
}
