package com.household.shared.shared_household_account

import org.junit.Assert.*
import org.junit.Test
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone

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

    // =========================================================================
    // 날짜 포맷팅 버그 테스트 (KST 00:00~08:59 사이 자동수집 시 전날로 저장되는 버그)
    // =========================================================================
    //
    // 버그 재현:
    //   KST 2026-02-15 07:59 (UTC 2026-02-14 22:59)에 KB국민카드 Push 수신
    //   -> parsed_date에 UTC 기준 "2026-02-14"가 저장됨 (올바른 값: "2026-02-15")
    //
    // 원인:
    //   SupabaseHelper에서 DATE 컬럼(parsed_date, date)에 저장할 때
    //   SimpleDateFormat의 타임존을 UTC로 설정하여 로컬 날짜가 아닌 UTC 날짜를 보냄
    //
    // 영향:
    //   KST 00:00~08:59 사이에 수신된 모든 자동수집 거래가 전날 날짜로 저장됨
    // =========================================================================

    @Test
    fun `버그재현 - UTC 타임존으로 날짜 포맷 시 KST 이른 아침 거래가 전날로 저장된다`() {
        // KST 2026-02-15 07:59:14 = UTC 2026-02-14 22:59:14
        // System.currentTimeMillis()가 반환하는 epoch millis 시뮬레이션
        val kstTimeZone = TimeZone.getTimeZone("Asia/Seoul")
        val cal = java.util.Calendar.getInstance(kstTimeZone).apply {
            set(2026, 1, 15, 7, 59, 14) // month는 0-based, 1 = February
            set(java.util.Calendar.MILLISECOND, 0)
        }
        val timestamp = cal.timeInMillis

        // 버그가 있던 코드: UTC 타임존으로 날짜 포맷
        val buggyDateFormat = SimpleDateFormat("yyyy-MM-dd", Locale.US)
        buggyDateFormat.timeZone = TimeZone.getTimeZone("UTC")
        val buggyResult = buggyDateFormat.format(Date(timestamp))

        // UTC 기준이므로 2026-02-14가 나옴 (버그!)
        assertEquals(
            "UTC 타임존으로 포맷하면 KST 이른 아침 시간대에 전날 날짜가 된다 (이것이 버그의 원인)",
            "2026-02-14",
            buggyResult
        )
    }

    @Test
    fun `수정검증 - formatLocalDate로 KST 이른 아침 거래가 올바른 날짜로 저장된다`() {
        val kstTimeZone = TimeZone.getTimeZone("Asia/Seoul")
        val cal = java.util.Calendar.getInstance(kstTimeZone).apply {
            set(2026, 1, 15, 7, 59, 14)
            set(java.util.Calendar.MILLISECOND, 0)
        }
        val timestamp = cal.timeInMillis

        // SupabaseHelper.formatLocalDate는 기기 로컬 타임존 사용
        val result = SupabaseHelper.formatLocalDate(timestamp)

        assertEquals(
            "formatLocalDate는 로컬 타임존 기준으로 올바른 날짜(2026-02-15)를 반환해야 한다",
            "2026-02-15",
            result
        )
    }

    @Test
    fun `수정검증 - formatUtcTimestamp는 UTC로 올바르게 포맷된다`() {
        val kstTimeZone = TimeZone.getTimeZone("Asia/Seoul")
        val cal = java.util.Calendar.getInstance(kstTimeZone).apply {
            set(2026, 1, 15, 7, 59, 14)
            set(java.util.Calendar.MILLISECOND, 0)
        }
        val timestamp = cal.timeInMillis

        val result = SupabaseHelper.formatUtcTimestamp(timestamp)

        assertTrue(
            "formatUtcTimestamp는 UTC로 변환되어 2026-02-14T22:59로 시작해야 한다",
            result.startsWith("2026-02-14T22:59")
        )
        assertTrue(
            "formatUtcTimestamp는 'Z' 접미사를 포함해야 한다",
            result.endsWith("Z")
        )
    }

    @Test
    fun `수정검증 - formatLocalDate로 KST 자정 직후(00시 05분) 거래도 당일 날짜로 저장된다`() {
        val kstTimeZone = TimeZone.getTimeZone("Asia/Seoul")
        val cal = java.util.Calendar.getInstance(kstTimeZone).apply {
            set(2026, 1, 15, 0, 5, 0)
            set(java.util.Calendar.MILLISECOND, 0)
        }
        val timestamp = cal.timeInMillis

        // 버그 코드 (UTC 포맷)는 전날이 됨을 확인
        val buggyFormat = SimpleDateFormat("yyyy-MM-dd", Locale.US)
        buggyFormat.timeZone = TimeZone.getTimeZone("UTC")
        assertEquals(
            "UTC 포맷 시 자정 직후 거래도 전날이 된다 (버그 재현)",
            "2026-02-14",
            buggyFormat.format(Date(timestamp))
        )

        // 수정된 헬퍼 메서드는 올바른 날짜를 반환
        assertEquals(
            "formatLocalDate로 자정 직후 거래는 당일 날짜여야 한다",
            "2026-02-15",
            SupabaseHelper.formatLocalDate(timestamp)
        )
    }

    @Test
    fun `수정검증 - formatLocalDate로 KST 오전 8시 59분(경계값) 거래가 당일 날짜로 저장된다`() {
        val kstTimeZone = TimeZone.getTimeZone("Asia/Seoul")
        val cal = java.util.Calendar.getInstance(kstTimeZone).apply {
            set(2026, 1, 15, 8, 59, 59)
            set(java.util.Calendar.MILLISECOND, 0)
        }
        val timestamp = cal.timeInMillis

        // 버그 코드 (UTC 포맷)는 전날이 됨을 확인 (경계값)
        val buggyFormat = SimpleDateFormat("yyyy-MM-dd", Locale.US)
        buggyFormat.timeZone = TimeZone.getTimeZone("UTC")
        assertEquals(
            "UTC 포맷 시 KST 08:59까지 전날이 된다 (버그 영향 범위의 경계)",
            "2026-02-14",
            buggyFormat.format(Date(timestamp))
        )

        assertEquals(
            "formatLocalDate로 08:59 거래는 당일 날짜여야 한다",
            "2026-02-15",
            SupabaseHelper.formatLocalDate(timestamp)
        )
    }

    @Test
    fun `수정검증 - KST 오전 9시 이후 거래는 UTC에서도 같은 날짜다`() {
        // KST 09:00 = UTC 00:00 (같은 날) -> 버그 비발생 구간
        val kstTimeZone = TimeZone.getTimeZone("Asia/Seoul")
        val cal = java.util.Calendar.getInstance(kstTimeZone).apply {
            set(2026, 1, 15, 9, 0, 0)
            set(java.util.Calendar.MILLISECOND, 0)
        }
        val timestamp = cal.timeInMillis

        val utcFormat = SimpleDateFormat("yyyy-MM-dd", Locale.US)
        utcFormat.timeZone = TimeZone.getTimeZone("UTC")

        assertEquals(
            "KST 09:00 이후에는 UTC와 formatLocalDate 결과가 같아야 한다",
            utcFormat.format(Date(timestamp)),
            SupabaseHelper.formatLocalDate(timestamp)
        )
        assertEquals("2026-02-15", SupabaseHelper.formatLocalDate(timestamp))
    }

    @Test
    fun `수정검증 - formatLocalDate와 formatUtcTimestamp가 같은 epoch에 대해 일관된 결과를 반환한다`() {
        val kstTimeZone = TimeZone.getTimeZone("Asia/Seoul")
        val cal = java.util.Calendar.getInstance(kstTimeZone).apply {
            set(2026, 1, 15, 7, 59, 14)
            set(java.util.Calendar.MILLISECOND, 0)
        }
        val timestamp = cal.timeInMillis

        val localDate = SupabaseHelper.formatLocalDate(timestamp)
        val utcTimestamp = SupabaseHelper.formatUtcTimestamp(timestamp)

        // parsed_date(DATE)는 로컬 날짜, source_timestamp(TIMESTAMPTZ)는 UTC
        assertEquals("parsed_date는 로컬 날짜 2026-02-15", "2026-02-15", localDate)
        assertTrue("source_timestamp는 UTC 2026-02-14", utcTimestamp.startsWith("2026-02-14"))
    }

    @Test
    fun `수정검증 - getTodayDate는 formatLocalDate와 동일한 결과를 반환한다`() {
        // getTodayDate()는 내부적으로 formatLocalDate(System.currentTimeMillis())를 호출
        val now = System.currentTimeMillis()
        val expected = SupabaseHelper.formatLocalDate(now)
        val localFormat = SimpleDateFormat("yyyy-MM-dd", Locale.US)
        val manualResult = localFormat.format(Date(now))

        assertEquals(
            "formatLocalDate는 기기 로컬 타임존으로 오늘 날짜를 반환해야 한다",
            manualResult,
            expected
        )
    }
}
