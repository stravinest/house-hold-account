package com.household.shared.shared_household_account

object NotificationConfig {
    const val FORMAT_CACHE_DURATION_MS = 5 * 60 * 1000L
    const val DUPLICATE_CHECK_WINDOW_MS = 5 * 60 * 1000L
    const val DUPLICATE_BUCKET_DURATION_MS = 3 * 60 * 1000L
    const val MAX_RETRY_COUNT = 3
    const val OLD_NOTIFICATION_DAYS = 7
    
    const val NETWORK_CONNECT_TIMEOUT_SECONDS = 30L
    const val NETWORK_READ_TIMEOUT_SECONDS = 30L
    const val NETWORK_WRITE_TIMEOUT_SECONDS = 30L
    const val CONNECTION_POOL_MAX_IDLE = 5
    const val CONNECTION_POOL_KEEP_ALIVE_MINUTES = 5L

    // SMS 누적 알림 구분자 목록
    // Samsung Messages 등에서 여러 SMS를 하나의 알림에 누적할 때 사용되는 접두사
    val SMS_CONTENT_DELIMITERS = listOf(
        "[Web발신]",
        "[웹발신]",
    )
}
