package com.household.shared.shared_household_account

import android.app.Notification
import android.content.Intent
import android.os.IBinder
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import io.flutter.BuildConfig
import kotlinx.coroutines.*

/**
 * 금융 앱 Push 알림을 수집하는 NotificationListenerService (SMS는 SmsBroadcastReceiver에서 처리)
 * 앱이 종료되어도 시스템 서비스로서 계속 동작하며, SQLite에 알림 저장
 * 
 * 현재: SQLite 저장 -> Flutter 동기화
 * 향후: Kotlin에서 직접 파싱 -> Supabase 저장 예정
 */
class FinancialNotificationListener : NotificationListenerService() {

    companion object {
        private const val TAG = "FinancialPushListener"

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

    private val supabaseHelper: SupabaseHelper by lazy {
        SupabaseHelper(applicationContext)
    }

    private val serviceScope = CoroutineScope(Dispatchers.IO + SupervisorJob())

    // Cache for learned formats and payment methods (refreshed periodically)
    private var learnedFormatsCache: List<LearnedPushFormat> = emptyList()
    private var paymentMethodsCache: List<SupabaseHelper.PaymentMethodInfo> = emptyList()
    private var lastFormatsFetchTime: Long = 0
    private val FORMATS_CACHE_DURATION = 5 * 60 * 1000L  // 5 minutes

    override fun onCreate() {
        super.onCreate()
        instance = this
        // storageHelper는 lazy이므로 첫 접근 시 초기화됨
        Log.d(TAG, "FinancialNotificationListener service created")
    }

    override fun onDestroy() {
        super.onDestroy()
        serviceScope.cancel()
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
        
        SmsContentObserver.register(applicationContext)
        Log.d(TAG, "SmsContentObserver registered via NotificationListener")
    }

    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        Log.d(TAG, "Notification listener disconnected")
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        if (sbn == null) return

        val packageName = sbn.packageName?.lowercase() ?: return

        if (!isFinancialApp(packageName)) return

        Log.d(TAG, "Financial notification received from: $packageName")

        val notification = sbn.notification ?: return
        val extras = notification.extras ?: return

        val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString()
        val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString()
        val bigText = extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString()

        val content = bigText ?: text
        if (content.isNullOrBlank()) {
            Log.d(TAG, "Notification has no text content, skipping")
            return
        }

        if (!containsPaymentKeyword(content)) {
            Log.d(TAG, "Notification does not contain payment keywords, skipping")
            return
        }

        val normalizedContent = normalizeContent(content)

        if (storageHelper.isDuplicate(packageName, normalizedContent)) {
            Log.d(TAG, "Duplicate notification, skipping")
            return
        }

        val combinedContent = if (title != null) "$title $normalizedContent" else normalizedContent
        val timestamp = sbn.postTime

        serviceScope.launch {
            processNotification(packageName, combinedContent, timestamp, title, normalizedContent)
        }
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        // 알림 제거 시에는 별도 처리 없음
    }

    private suspend fun processNotification(
        packageName: String,
        combinedContent: String,
        timestamp: Long,
        title: String?,
        originalContent: String
    ) {
        val sqliteId = storageHelper.insertNotification(
            packageName = packageName,
            title = title,
            text = originalContent,
            receivedAt = timestamp
        )
        Log.d(TAG, "Notification saved to SQLite with id: $sqliteId")

        if (!supabaseHelper.isInitialized) {
            Log.d(TAG, "Supabase not initialized, using SQLite only")
            notifyFlutter(packageName)
            return
        }

        val ledgerId = supabaseHelper.getCurrentLedgerId()
        val token = supabaseHelper.getValidToken()
        val userId = token?.let { supabaseHelper.getUserIdFromToken(it) }

        if (ledgerId == null || userId == null) {
            Log.d(TAG, "No ledger or user, using SQLite only")
            notifyFlutter(packageName)
            return
        }

        refreshFormatsCache(ledgerId)

        val matchingFormat = learnedFormatsCache.find { format ->
            format.packageName.equals(packageName, ignoreCase = true) ||
            format.appKeywords.any { keyword ->
                combinedContent.contains(keyword, ignoreCase = true)
            }
        }

        val parsed = if (matchingFormat != null) {
            FinancialMessageParser.parseWithFormat(combinedContent, matchingFormat)
        } else {
            FinancialMessageParser.parse(packageName, combinedContent)
        }

        if (!parsed.isParsed) {
            Log.d(TAG, "Failed to parse notification, keeping in SQLite for Flutter sync")
            notifyFlutter(packageName)
            return
        }

        var paymentMethodId = matchingFormat?.paymentMethodId ?: ""
        var matchedPaymentMethod: SupabaseHelper.PaymentMethodInfo? = null
        
        // learned_push_formats에서 매칭 안 되면 결제수단 이름으로 fallback 매칭
        if (paymentMethodId.isEmpty()) {
            matchedPaymentMethod = paymentMethodsCache.find { pm ->
                pm.autoCollectSource == "push" && combinedContent.contains(pm.name, ignoreCase = true)
            }
            if (matchedPaymentMethod != null) {
                paymentMethodId = matchedPaymentMethod.id
                Log.d(TAG, "Fallback matched by payment method name: ${matchedPaymentMethod.name}")
            }
        }

        val duplicateHash = FinancialMessageParser.generateDuplicateHash(
            parsed.amount ?: 0,
            paymentMethodId.ifEmpty { null },
            timestamp
        )
        
        // 매칭되는 결제수단이 없으면 스킵 (SQLite는 synced 처리하여 Flutter에서 재처리 방지)
        if (paymentMethodId.isEmpty()) {
            Log.d(TAG, "No matching payment method found, skipping push notification collection")
            storageHelper.markAsSynced(listOf(sqliteId))
            notifyFlutter(packageName)
            return
        }

        val settings = matchedPaymentMethod?.let {
            SupabaseHelper.PaymentMethodAutoSettings(it.autoSaveMode, it.autoCollectSource)
        } ?: supabaseHelper.getPaymentMethodAutoSettings(paymentMethodId)

        // SMS 모드로 설정된 결제수단이면 Push 스킵 (SQLite는 synced 처리)
        if (settings != null && !settings.isPushSource) {
            Log.d(TAG, "Payment method is set to SMS mode, skipping push notification collection")
            storageHelper.markAsSynced(listOf(sqliteId))
            notifyFlutter(packageName)
            return
        }

        val success = if (settings?.isAutoMode == true) {
            Log.d(TAG, "Auto mode enabled for payment method: $paymentMethodId, creating confirmed transaction")
            supabaseHelper.createConfirmedTransaction(
                ledgerId = ledgerId,
                userId = userId,
                paymentMethodId = paymentMethodId,
                sourceType = "notification",
                sourceSender = packageName,
                sourceContent = combinedContent,
                sourceTimestamp = timestamp,
                parsedAmount = parsed.amount,
                parsedType = parsed.transactionType,
                parsedMerchant = parsed.merchant,
                parsedCategoryId = null
            )
        } else {
            Log.d(TAG, "Suggest mode for payment method: $paymentMethodId, creating pending transaction")
            supabaseHelper.createPendingTransaction(
                ledgerId = ledgerId,
                userId = userId,
                paymentMethodId = paymentMethodId,
                sourceType = "notification",
                sourceSender = packageName,
                sourceContent = combinedContent,
                sourceTimestamp = timestamp,
                parsedAmount = parsed.amount,
                parsedType = parsed.transactionType,
                parsedMerchant = parsed.merchant,
                parsedCategoryId = null,
                duplicateHash = duplicateHash,
                isDuplicate = false
            )
        }

        if (success) {
            Log.d(TAG, "Notification saved to Supabase, marking SQLite as synced")
            storageHelper.markAsSynced(listOf(sqliteId))
        } else {
            Log.d(TAG, "Supabase save failed, keeping in SQLite for later sync")
        }

        notifyFlutter(packageName)
    }

    private suspend fun refreshFormatsCache(ledgerId: String) {
        val now = System.currentTimeMillis()
        if (now - lastFormatsFetchTime < FORMATS_CACHE_DURATION && learnedFormatsCache.isNotEmpty()) {
            return
        }

        try {
            learnedFormatsCache = supabaseHelper.getLearnedPushFormats(ledgerId)
            paymentMethodsCache = supabaseHelper.getPaymentMethodsByLedger(ledgerId)
            lastFormatsFetchTime = now
            Log.d(TAG, "Refreshed ${learnedFormatsCache.size} learned push formats, ${paymentMethodsCache.size} payment methods")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to refresh formats cache", e)
        }
    }

    private fun notifyFlutter(packageName: String) {
        val pendingCount = storageHelper.getPendingCount()
        Log.d(TAG, "Total pending notifications: $pendingCount")
        MainActivity.notifyNewNotification(packageName, pendingCount)
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
    
    private fun normalizeContent(content: String): String {
        return content
            .replace("\r\n", " ")
            .replace("\n", " ")
            .replace("\r", " ")
            .replace(Regex("\\s+"), " ")
            .trim()
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
