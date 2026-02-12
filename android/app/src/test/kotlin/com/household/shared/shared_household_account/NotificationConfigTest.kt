package com.household.shared.shared_household_account

import org.junit.Assert.*
import org.junit.Test

/**
 * NotificationConfig 테스트
 * 알림 설정 상수들의 값이 올바르게 정의되어 있는지 검증한다
 */
class NotificationConfigTest {

    @Test
    fun `FORMAT_CACHE_DURATION_MS - 5분으로 설정되어 있다`() {
        assertEquals(
            "캐시 유지 시간이 5분(300000ms)이어야 한다",
            5 * 60 * 1000L,
            NotificationConfig.FORMAT_CACHE_DURATION_MS
        )
    }

    @Test
    fun `DUPLICATE_CHECK_WINDOW_MS - 5분으로 설정되어 있다`() {
        assertEquals(
            "중복 체크 윈도우가 5분(300000ms)이어야 한다",
            5 * 60 * 1000L,
            NotificationConfig.DUPLICATE_CHECK_WINDOW_MS
        )
    }

    @Test
    fun `DUPLICATE_BUCKET_DURATION_MS - 3분으로 설정되어 있다`() {
        assertEquals(
            "중복 버킷 기간이 3분(180000ms)이어야 한다",
            3 * 60 * 1000L,
            NotificationConfig.DUPLICATE_BUCKET_DURATION_MS
        )
    }

    @Test
    fun `MAX_RETRY_COUNT - 3으로 설정되어 있다`() {
        assertEquals(
            "최대 재시도 횟수가 3이어야 한다",
            3,
            NotificationConfig.MAX_RETRY_COUNT
        )
    }

    @Test
    fun `OLD_NOTIFICATION_DAYS - 7일로 설정되어 있다`() {
        assertEquals(
            "오래된 알림 보관 기간이 7일이어야 한다",
            7,
            NotificationConfig.OLD_NOTIFICATION_DAYS
        )
    }

    @Test
    fun `NETWORK_CONNECT_TIMEOUT_SECONDS - 30초로 설정되어 있다`() {
        assertEquals(
            "네트워크 연결 타임아웃이 30초여야 한다",
            30L,
            NotificationConfig.NETWORK_CONNECT_TIMEOUT_SECONDS
        )
    }

    @Test
    fun `NETWORK_READ_TIMEOUT_SECONDS - 30초로 설정되어 있다`() {
        assertEquals(
            "네트워크 읽기 타임아웃이 30초여야 한다",
            30L,
            NotificationConfig.NETWORK_READ_TIMEOUT_SECONDS
        )
    }

    @Test
    fun `NETWORK_WRITE_TIMEOUT_SECONDS - 30초로 설정되어 있다`() {
        assertEquals(
            "네트워크 쓰기 타임아웃이 30초여야 한다",
            30L,
            NotificationConfig.NETWORK_WRITE_TIMEOUT_SECONDS
        )
    }

    @Test
    fun `CONNECTION_POOL_MAX_IDLE - 5로 설정되어 있다`() {
        assertEquals(
            "커넥션 풀 최대 유휴 연결 수가 5여야 한다",
            5,
            NotificationConfig.CONNECTION_POOL_MAX_IDLE
        )
    }

    @Test
    fun `CONNECTION_POOL_KEEP_ALIVE_MINUTES - 5분으로 설정되어 있다`() {
        assertEquals(
            "커넥션 풀 연결 유지 시간이 5분이어야 한다",
            5L,
            NotificationConfig.CONNECTION_POOL_KEEP_ALIVE_MINUTES
        )
    }

    @Test
    fun `SMS_CONTENT_DELIMITERS - 비어있지 않다`() {
        assertTrue(
            "SMS 구분자 리스트가 비어있지 않아야 한다",
            NotificationConfig.SMS_CONTENT_DELIMITERS.isNotEmpty()
        )
    }

    @Test
    fun `SMS_CONTENT_DELIMITERS - Web발신 구분자를 포함한다`() {
        assertTrue(
            "[Web발신] 구분자가 포함되어야 한다",
            NotificationConfig.SMS_CONTENT_DELIMITERS.contains("[Web발신]")
        )
    }

    @Test
    fun `SMS_CONTENT_DELIMITERS - 웹발신 구분자를 포함한다`() {
        assertTrue(
            "[웹발신] 구분자가 포함되어야 한다",
            NotificationConfig.SMS_CONTENT_DELIMITERS.contains("[웹발신]")
        )
    }

    @Test
    fun `SMS_CONTENT_DELIMITERS - 2개의 구분자를 포함한다`() {
        assertEquals(
            "정확히 2개의 SMS 구분자가 정의되어 있어야 한다",
            2,
            NotificationConfig.SMS_CONTENT_DELIMITERS.size
        )
    }

    @Test
    fun `DUPLICATE_BUCKET_DURATION_MS - DUPLICATE_CHECK_WINDOW_MS보다 작거나 같다`() {
        assertTrue(
            "중복 버킷 기간이 중복 체크 윈도우보다 작거나 같아야 한다",
            NotificationConfig.DUPLICATE_BUCKET_DURATION_MS <= NotificationConfig.DUPLICATE_CHECK_WINDOW_MS
        )
    }

    @Test
    fun `네트워크 타임아웃 - 모두 양수다`() {
        assertTrue(
            "연결 타임아웃이 양수여야 한다",
            NotificationConfig.NETWORK_CONNECT_TIMEOUT_SECONDS > 0
        )
        assertTrue(
            "읽기 타임아웃이 양수여야 한다",
            NotificationConfig.NETWORK_READ_TIMEOUT_SECONDS > 0
        )
        assertTrue(
            "쓰기 타임아웃이 양수여야 한다",
            NotificationConfig.NETWORK_WRITE_TIMEOUT_SECONDS > 0
        )
    }

    @Test
    fun `커넥션 풀 설정 - 모두 양수다`() {
        assertTrue(
            "최대 유휴 연결 수가 양수여야 한다",
            NotificationConfig.CONNECTION_POOL_MAX_IDLE > 0
        )
        assertTrue(
            "연결 유지 시간이 양수여야 한다",
            NotificationConfig.CONNECTION_POOL_KEEP_ALIVE_MINUTES > 0
        )
    }
}
