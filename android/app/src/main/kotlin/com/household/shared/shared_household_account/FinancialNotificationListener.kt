package com.household.shared.shared_household_account

import android.app.Notification
import android.content.Intent
import android.os.IBinder
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import io.flutter.BuildConfig

/**
 * 금융 앱 알림을 수집하는 커스텀 NotificationListenerService
 * 앱이 종료되어도 시스템 서비스로서 계속 동작하며, SQLite에 알림 저장
 */
class FinancialNotificationListener : NotificationListenerService() {

    companion object {
        private const val TAG = "FinancialNotification"

        // 금융 앱 패키지명 목록 (소문자로 저장)
        private val FINANCIAL_APP_PACKAGES: Set<String> = buildSet {
            // KB 카드/은행
            add("com.kbcard.cxh.appcard")      // KB Pay (KB국민카드 앱)
            add("com.kbstar.kbbank")           // KB국민은행

            // 신한 카드/은행
            add("com.shcard.smartpay")         // 신한 SOL페이 (메인 카드 앱)
            add("com.shinhancard.wallet")      // 신한카드 올댓
            add("com.shinhan.sbanking")        // 신한은행

            // 삼성 카드/페이
            add("kr.co.samsungcard.mpocket")   // 삼성카드 메인 앱
            add("com.samsung.android.spay")    // 삼성페이
            add("net.ib.android.smcard")       // monimo (삼성금융네트웍스)

            // 현대카드
            add("com.hyundaicard.appcard")     // 현대카드 메인 앱
            add("com.hyundaicard.weather")     // 현대카드 웨더
            add("com.hyundaicard.cultureapp")  // 현대카드 DIVE

            // 롯데카드
            add("com.lcacapp")                 // 디지로카 (롯데카드 메인 앱)
            add("com.lottecard.lcap")          // 롯데카드 인슈플러스

            // 경기지역화폐
            add("gov.gyeonggi.ggcard")         // 경기지역화폐 공식 앱

            // 간편결제
            add("com.kakaopay.app")            // 카카오페이
            add("com.naverfin.payapp")         // 네이버페이
            add("viva.republica.toss")         // 토스

            // 우리 카드/은행
            add("com.wooricard.smartapp")      // 우리카드
            add("com.wooribank.smart.npib")    // 우리은행

            // 하나 카드/은행
            add("com.hanaskcard.paycla")       // 하나카드
            add("com.hanabank.ebk.channel.android.hananbank")  // 하나은행

            // NH농협
            add("nh.smart.nhallonepay")        // NH올원페이
            add("com.nh.cashcardapp")          // NH카드

            // 기타 은행
            add("com.ibk.neobanking")          // IBK기업은행
            add("com.epost.psf.sdsi")          // 우체국
            add("com.kdb.mobilebank")          // 산업은행
            add("kr.co.citibank.citimobile")   // 씨티은행

            // 테스트용 패키지 (디버그 빌드에서만 포함)
            if (BuildConfig.DEBUG) {
                add("com.android.shell")       // cmd notification post 테스트용
            }
        }

        // 결제/거래 관련 키워드 (성능 최적화를 위해 상수로 정의)
        private val PAYMENT_KEYWORDS = listOf(
            // 금액 관련
            "원", "won", "krw",
            // 거래 유형
            "승인", "결제", "사용", "출금", "입금", "이체", "충전",
            "취소", "환불",
            // 카드 관련
            "카드", "체크", "신용", "체크카드", "신용카드",
            // 계좌 관련
            "계좌", "통장", "잔액",
            // 지역화폐
            "지역화폐", "페이", "pay"
        )

        // 서비스 인스턴스 참조 (Flutter와 통신용)
        @Volatile
        var instance: FinancialNotificationListener? = null
            private set
    }

    // lazy initialization으로 onCreate 전 접근 시에도 안전하게 처리
    private val storageHelper: NotificationStorageHelper by lazy {
        NotificationStorageHelper.getInstance(applicationContext)
    }

    override fun onCreate() {
        super.onCreate()
        instance = this
        // storageHelper는 lazy이므로 첫 접근 시 초기화됨
        Log.d(TAG, "FinancialNotificationListener service created")
    }

    override fun onDestroy() {
        super.onDestroy()
        instance = null
        Log.d(TAG, "FinancialNotificationListener service destroyed")
    }

    override fun onBind(intent: Intent?): IBinder? {
        Log.d(TAG, "Service bound")
        return super.onBind(intent)
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
        Log.d(TAG, "Notification listener connected")
    }

    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        Log.d(TAG, "Notification listener disconnected")
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        if (sbn == null) return

        val packageName = sbn.packageName?.lowercase() ?: return

        // 금융 앱인지 확인
        if (!isFinancialApp(packageName)) {
            return
        }

        Log.d(TAG, "Financial notification received from: $packageName")

        // 알림 내용 추출
        val notification = sbn.notification ?: return
        val extras = notification.extras ?: return

        val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString()
        val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString()
        val bigText = extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString()

        // 텍스트 내용이 있어야 저장
        val content = bigText ?: text
        if (content.isNullOrBlank()) {
            Log.d(TAG, "Notification has no text content, skipping")
            return
        }

        // 결제/거래 관련 키워드 확인 (선택적 필터링)
        if (!containsPaymentKeyword(content)) {
            // 민감 정보 로깅 방지 - 내용은 출력하지 않음
            Log.d(TAG, "Notification does not contain payment keywords, skipping")
            return
        }

        // 중복 확인
        if (storageHelper.isDuplicate(packageName, content)) {
            Log.d(TAG, "Duplicate notification, skipping")
            return
        }

        // SQLite에 저장
        val id = storageHelper.insertNotification(
            packageName = packageName,
            title = title,
            text = content,
            receivedAt = sbn.postTime
        )

        // 민감 정보(금액, 가맹점명 등)는 로그에 출력하지 않음
        Log.d(TAG, "Notification saved with id: $id from $packageName")

        // 저장된 알림 수 로그
        val pendingCount = storageHelper.getPendingCount()
        Log.d(TAG, "Total pending notifications: $pendingCount")

        // Flutter로 새 알림 이벤트 전달 (앱이 실행 중인 경우)
        MainActivity.notifyNewNotification(packageName, pendingCount)
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        // 알림 제거 시에는 별도 처리 없음
    }

    /**
     * 금융 앱인지 확인
     */
    private fun isFinancialApp(packageName: String): Boolean {
        return FINANCIAL_APP_PACKAGES.contains(packageName.lowercase())
    }

    /**
     * 결제/거래 관련 키워드 포함 여부 확인
     * 키워드는 companion object에 상수로 정의되어 성능 최적화
     */
    private fun containsPaymentKeyword(text: String): Boolean {
        val lowerText = text.lowercase()
        return PAYMENT_KEYWORDS.any { keyword ->
            lowerText.contains(keyword)
        }
    }

    // 아래 메서드들은 현재 MainActivity에서 NotificationStorageHelper를 직접 사용하므로
    // 호출되지 않지만, 향후 서비스 인스턴스를 통한 직접 접근이 필요할 때를 위해 보관

    /**
     * 동기화 대기 중인 알림 조회
     * 현재 미사용 - MainActivity에서 직접 StorageHelper 접근
     */
    @Suppress("unused")
    fun getPendingNotifications(): List<Map<String, Any?>> {
        return storageHelper.getPendingNotifications()
    }

    /**
     * 알림을 동기화됨으로 표시
     * 현재 미사용 - MainActivity에서 직접 StorageHelper 접근
     */
    @Suppress("unused")
    fun markAsSynced(ids: List<Long>): Int {
        return storageHelper.markAsSynced(ids)
    }

    /**
     * 오래된 알림 삭제
     * 현재 미사용 - MainActivity에서 직접 StorageHelper 접근
     */
    @Suppress("unused")
    fun clearOldNotifications(olderThanDays: Int): Int {
        return storageHelper.clearOldNotifications(olderThanDays)
    }

    /**
     * 동기화 대기 알림 수 조회
     * 현재 미사용 - MainActivity에서 직접 StorageHelper 접근
     */
    @Suppress("unused")
    fun getPendingCount(): Int {
        return storageHelper.getPendingCount()
    }
}
