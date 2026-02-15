package com.household.shared.shared_household_account

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.IBinder
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import androidx.core.app.NotificationCompat
import io.flutter.BuildConfig
import kotlinx.coroutines.*
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicInteger
import java.util.concurrent.atomic.AtomicLong

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

        // 서비스 인스턴스 참조 (Flutter와 통신용)
        @Volatile
        var instance: FinancialNotificationListener? = null
            private set

        // 알림 ID 카운터 (동일 밀리초에 여러 알림이 와도 중복 방지)
        private val notificationIdCounter = AtomicInteger(0)

        // 최근 처리된 알림 해시 캐시 (content hash -> timestamp)
        // onNotificationPosted가 동일 알림에 대해 여러 번 호출되는 경우 방지
        //
        // 3중 방어 시간 윈도우 설계:
        // - 1차 메모리 캐시: 30초 (Samsung 중복은 수ms~수초 내 발생, 30초면 충분)
        // - 2차 SQLite UNIQUE: 1분 버킷 (프로세스 재시작 후 방어, 분 경계 극단 케이스는 3차에서 방어)
        // - 3차 Supabase duplicateHash: 3분 버킷 (최종 방어, 가장 넓은 윈도우)
        private val recentNotificationHashes = ConcurrentHashMap<String, Long>()
        private const val DEDUP_WINDOW_MS = 30_000L  // 30초 이내 동일 알림 무시
        private const val MAX_CACHE_SIZE = 50  // 캐시 최대 크기 (금융 알림 빈도 고려)
        private val lastCleanupTime = AtomicLong(0L)
    }

    /**
     * Flutter에서 결제수단 설정 변경 시 호출
     * 다음 알림 처리 시 캐시를 강제로 새로고침
     */
    fun invalidateCache() {
        lastFormatsFetchTime = 0
        Log.d(TAG, "Cache invalidated by external request")
    }

    // lazy initialization으로 onCreate 전 접근 시에도 안전하게 처리
    private val storageHelper: NotificationStorageHelper by lazy {
        NotificationStorageHelper.getInstance(applicationContext)
    }

    private val supabaseHelper: SupabaseHelper by lazy {
        SupabaseHelper.getInstance(applicationContext)
    }

    private val serviceScope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    private val processNotificationMutex = Mutex()

    private var learnedFormatsCache: List<LearnedPushFormat> = emptyList()
    private var paymentMethodsCache: List<SupabaseHelper.PaymentMethodInfo> = emptyList()
    private var lastFormatsFetchTime: Long = 0

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
    }

    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        Log.d(TAG, "Notification listener disconnected")
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        if (sbn == null) return

        val packageName = sbn.packageName?.lowercase() ?: return
        val isFromMessageApp = NotificationFilterHelper.isMessageApp(packageName)
        val isAlimtalkApp = NotificationFilterHelper.isAlimtalkApp(packageName)

        if (!NotificationFilterHelper.isFinancialApp(packageName) && !isFromMessageApp && !isAlimtalkApp) return

        val timestamp = System.currentTimeMillis()
        if (BuildConfig.DEBUG) {
            Log.d(TAG, "==================================================")
            Log.d(TAG, "NOTIFICATION RECEIVED: $packageName")
            Log.d(TAG, "Is from message app: $isFromMessageApp")
            Log.d(TAG, "Is from alimtalk app: $isAlimtalkApp")
            Log.d(TAG, "Timestamp: $timestamp")
            Log.d(TAG, "==================================================")
        }

        val notification = sbn.notification ?: return
        val extras = notification.extras ?: return

        val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString()
        val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString()
        val bigText = extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString()
        val subText = extras.getCharSequence(Notification.EXTRA_SUB_TEXT)?.toString()

        // 카카오톡 알림톡: 금융 채널 title + 거래 키워드 + 금액 패턴 3중 검증
        // 개인 채팅/일반 채널 알림을 확실히 차단
        if (isAlimtalkApp) {
            val alimtalkContent = bigText ?: text
            Log.d(TAG, "[Alimtalk] title='$title', content='${alimtalkContent?.take(100)}'")
            if (!NotificationFilterHelper.isFinancialAlimtalk(title, alimtalkContent)) {
                Log.d(TAG, "[Alimtalk] 3중 검증 실패 - title='$title', content preview='${alimtalkContent?.take(80)}'")
                return
            }
            Log.d(TAG, "Alimtalk financial notification confirmed: $title")
        }

        // MessagingStyle 알림에서 메시지 텍스트 추출 (Google Messages 등)
        // 여러 줄 SMS의 경우 EXTRA_TEXT에 첫 줄만 포함되므로
        // EXTRA_MESSAGES에서 전체 본문을 추출해야 함
        val messagingText = extractMessagingText(extras)

        val rawContent = bigText ?: messagingText ?: text
        if (BuildConfig.DEBUG) {
            Log.d(TAG, "Content source: bigText=${bigText != null}, messagingText=${messagingText != null}, text=${text != null}")
            Log.d(TAG, "Raw content preview: ${rawContent?.take(100)}")
        }
        if (rawContent.isNullOrBlank()) {
            Log.d(TAG, "Notification has no text content, skipping")
            return
        }

        // SMS 앱 알림일 때만 누적 SMS 추출 적용
        // Push 알림에는 [Web발신] 구분자가 없으므로 불필요
        val content = if (isFromMessageApp) {
            NotificationFilterHelper.extractLatestSmsFromContent(rawContent)
        } else {
            rawContent
        }
        if (BuildConfig.DEBUG && content != rawContent) {
            Log.d(TAG, "Extracted latest SMS from accumulated content")
            Log.d(TAG, "  Original length: ${rawContent.length}, Extracted length: ${content.length}")
            Log.d(TAG, "  Extracted preview: ${content.take(100)}")
        }

        if (!NotificationFilterHelper.containsPaymentKeyword(content)) {
            Log.d(TAG, "Notification does not contain payment keywords, skipping")
            return
        }

        val normalizedContent = NotificationFilterHelper.normalizeContent(content)
        val combinedContent = if (title != null) "$title $normalizedContent" else normalizedContent
        // 카카오톡 알림톡도 Push 알림이므로 sourceType은 "notification"
        val sourceType = NotificationFilterHelper.determineSourceType(isFromMessageApp)

        // 메모리 캐시 기반 중복 체크 (onNotificationPosted 다중 호출 방지)
        // Samsung FreecessController freeze/unfreeze 사이클로 동일 알림이 재전달될 수 있음
        val contentHash = normalizedContent.hashCode().toString()
        val now = System.currentTimeMillis()
        val lastProcessed = recentNotificationHashes[contentHash]
        if (lastProcessed != null && (now - lastProcessed) < DEDUP_WINDOW_MS) {
            Log.d(TAG, "Duplicate notification detected in memory cache, skipping (hash=$contentHash)")
            return
        }
        recentNotificationHashes[contentHash] = now

        // 오래된 캐시 항목 정리 (10초마다 또는 캐시 크기 초과 시)
        if ((now - lastCleanupTime.get()) > 10_000L || recentNotificationHashes.size > MAX_CACHE_SIZE) {
            recentNotificationHashes.entries.removeAll { (now - it.value) > DEDUP_WINDOW_MS }
            lastCleanupTime.set(now)
        }

        serviceScope.launch {
            if (BuildConfig.DEBUG) {
                Log.d(TAG, "Starting processNotification for $packageName")
            }
            processNotification(packageName, combinedContent, timestamp, title, normalizedContent, sourceType)
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
        originalContent: String,
        sourceType: String
    ) = processNotificationMutex.withLock {
         if (BuildConfig.DEBUG) {
             Log.d(TAG, "processNotification START (mutex acquired)")
             Log.d(TAG, "  - Package: $packageName")
             Log.d(TAG, "  - Source Type: $sourceType")
             Log.d(TAG, "  - Content length: ${originalContent.length}")
         }
        
         //sql lite에 알림 저장
         val sqliteId = storageHelper.insertNotification(
             packageName = packageName,
             title = title,
             text = originalContent,
             receivedAt = timestamp,
             sourceType = sourceType
         )
         
         if (sqliteId == -1L) {
            Log.d(TAG, "Duplicate notification, skipping")
            return
         }
         
         Log.d(TAG, "Notification saved to SQLite with id: $sqliteId (sourceType=$sourceType)")

         if (!supabaseHelper.isInitialized) {
            Log.d(TAG, "Supabase not initialized, using SQLite only")
            notifyFlutter(packageName)
            return
         }

         val ledgerId = supabaseHelper.getCurrentLedgerId()
         val token = supabaseHelper.getValidToken()
         val userId = token?.let { supabaseHelper.getUserIdFromToken(it) }
         
         if (BuildConfig.DEBUG) {
             Log.d(TAG, "Ledger ID: $ledgerId")
             Log.d(TAG, "User ID: $userId")
         }
         
         if (ledgerId == null || userId == null) {
            Log.d(TAG, "No ledger or user, using SQLite only")
            notifyFlutter(packageName)
            return
         }

         if (BuildConfig.DEBUG) Log.d(TAG, "Refreshing formats cache...")
         refreshFormatsCache(ledgerId, userId)

        // ============================================================
        // 1단계: 학습된 포맷으로 매칭 시도
        // ============================================================
        // 목적: 사용자가 이전에 수집한 Push의 패턴을 사용하여 정확하게 파싱
        // 매칭 조건: (패키지명 or 키워드) AND (사용자 소유) AND (sourceType 일치)
        //
        // 중요: learnedFormatsCache는 learned_push_formats 테이블에서만 로드됨
        //       → 결제수단의 autoCollectSource가 Push여야 매칭됨
        val matchingFormat = learnedFormatsCache.find { format ->
            // 조건 1: 패키지명 또는 키워드 매칭
            val contentMatches = format.packageName.equals(packageName, ignoreCase = true) ||
                format.appKeywords.any { keyword ->
                    combinedContent.contains(keyword, ignoreCase = true)
                }

            if (BuildConfig.DEBUG && contentMatches) {
                Log.d(TAG, "Content matched for format: ${format.id}")
                Log.d(TAG, "  - Package: ${format.packageName} (input: $packageName)")
                Log.d(TAG, "  - Keywords: ${format.appKeywords}")
            }

            // 조건 2: 권한 검증 (현재 사용자 소유 결제수단인지 확인)
            val isOwnedByCurrentUser = paymentMethodsCache.any { pm -> pm.id == format.paymentMethodId }

            if (BuildConfig.DEBUG && !isOwnedByCurrentUser && contentMatches) {
                Log.d(TAG, "Format matched but NOT owned by current user (paymentMethodId: ${format.paymentMethodId})")
            }

            // 조건 3: sourceType 일치 확인
            // learned_push_formats는 Push 포맷이므로, 결제수단도 Push 모드여야 함
            val paymentMethod = paymentMethodsCache.find { it.id == format.paymentMethodId }
            val expectedSource = NotificationFilterHelper.getExpectedSource(sourceType)
            val sourceMatches = paymentMethod?.autoCollectSource == expectedSource

            if (BuildConfig.DEBUG && !sourceMatches && contentMatches && isOwnedByCurrentUser) {
                Log.d(TAG, "Format matched but SOURCE TYPE mismatch:")
                Log.d(TAG, "  - Payment method autoCollectSource: ${paymentMethod?.autoCollectSource}")
                Log.d(TAG, "  - Incoming sourceType: $sourceType (expected: $expectedSource)")
                Log.d(TAG, "  - Skipping this format, will try fallback matching")
            }

            // 조건 4: autoSaveMode 확인
            // manual 모드인 결제수단은 자동수집에서 제외
            val isAutoSaveEnabled = paymentMethod?.autoSaveMode != "manual"

            if (BuildConfig.DEBUG && !isAutoSaveEnabled && contentMatches && isOwnedByCurrentUser && sourceMatches) {
                Log.d(TAG, "Format matched but autoSaveMode is manual:")
                Log.d(TAG, "  - Payment method: ${paymentMethod?.name}")
                Log.d(TAG, "  - autoSaveMode: ${paymentMethod?.autoSaveMode}")
                Log.d(TAG, "  - Skipping this format")
            }

            contentMatches && isOwnedByCurrentUser && sourceMatches && isAutoSaveEnabled
        }

        if (BuildConfig.DEBUG) {
            if (matchingFormat != null) {
                Log.d(TAG, "Found matching learned format:")
                Log.d(TAG, "  - Format ID: ${matchingFormat.id}")
                Log.d(TAG, "  - Payment Method ID: ${matchingFormat.paymentMethodId}")
                Log.d(TAG, "  - Source: Push (learned_push_formats)")
                Log.d(TAG, "  - Confidence: ${matchingFormat.confidence}")
            } else {
                Log.d(TAG, "No matching learned format found")
                if (sourceType != "sms" && learnedFormatsCache.isNotEmpty()) {
                    Log.d(TAG, "  Available push formats (${learnedFormatsCache.size}):")
                    learnedFormatsCache.forEach { format ->
                        Log.d(TAG, "    - ${format.id}: ${format.packageName}")
                        Log.d(TAG, "      paymentMethodId: ${format.paymentMethodId}")
                        Log.d(TAG, "      confidence: ${format.confidence}")
                    }
                }
            }
        }

        // ============================================================
        // 2단계: 학습된 포맷으로 파싱 vs 일반 파싱
        // ============================================================
        // 학습된 포맷이 있으면: 사용자가 학습한 정규식으로 금액/상호/날짜 추출 (높은 정확도)
        // 학습된 포맷이 없으면: 패키지명 기반 기본 파싱 규칙 적용 (낮은 정확도)
        val parsed = if (matchingFormat != null) {
            if (BuildConfig.DEBUG) Log.d(TAG, "Parsing with learned format...")
            FinancialMessageParser.parseWithFormat(combinedContent, matchingFormat)
        } else {
            if (BuildConfig.DEBUG) Log.d(TAG, "Parsing with generic format (package: $packageName)...")
            FinancialMessageParser.parse(packageName, combinedContent)
        }

        if (BuildConfig.DEBUG) {
            Log.d(TAG, "Parse result: isParsed=${parsed.isParsed}, amount=${parsed.amount}, merchant=${parsed.merchant}, type=${parsed.transactionType}")
        }

        if (!parsed.isParsed) {
            Log.d(TAG, "Failed to parse notification, keeping in SQLite for Flutter sync")
            notifyFlutter(packageName)
            return
        }

        var paymentMethodId = matchingFormat?.paymentMethodId ?: ""
        var matchedPaymentMethod: SupabaseHelper.PaymentMethodInfo? = null
        
        // learned_push_formats에서 매칭 안 되면 결제수단 이름으로 fallback 매칭
        // sourceType에 맞는 결제수단만 매칭 (SMS -> sms, notification -> push)
        // autoSaveMode가 manual인 결제수단은 자동수집에서 제외
        if (paymentMethodId.isEmpty()) {
            val expectedSource = NotificationFilterHelper.getExpectedSource(sourceType)
            matchedPaymentMethod = paymentMethodsCache.find { pm ->
                pm.autoCollectSource == expectedSource &&
                pm.autoSaveMode != "manual" &&
                combinedContent.contains(pm.name, ignoreCase = true)
            }
            if (matchedPaymentMethod != null) {
                paymentMethodId = matchedPaymentMethod.id
                Log.d(TAG, "Fallback matched by payment method name: ${matchedPaymentMethod.name} (source: $expectedSource, mode: ${matchedPaymentMethod.autoSaveMode})")
            } else {
                Log.d(TAG, "Fallback matching failed: no eligible payment methods found (excluded manual mode)")
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

        // sourceType과 autoCollectSource 불일치 시 스킵
        // - SMS가 왔는데 결제수단이 Push 모드 → 스킵
        // - Push가 왔는데 결제수단이 SMS 모드 → 스킵
        val expectedSource = NotificationFilterHelper.getExpectedSource(sourceType)
        if (settings != null && settings.autoCollectSource != expectedSource) {
            Log.d(TAG, "Source type mismatch: sourceType=$sourceType, expected=$expectedSource, actual=${settings.autoCollectSource}")
            storageHelper.markAsSynced(listOf(sqliteId))
            notifyFlutter(packageName)
            return
        }

        // DB source_type 컬럼은 'sms' | 'notification'
        val dbSourceType = sourceType

        val success = if (settings?.isAutoMode == true) {
            Log.d(TAG, "Auto mode enabled for payment method: $paymentMethodId, creating confirmed transaction")
            supabaseHelper.createConfirmedTransaction(
                ledgerId = ledgerId,
                userId = userId,
                paymentMethodId = paymentMethodId,
                sourceType = dbSourceType,
                sourceSender = packageName,
                sourceContent = combinedContent,
                sourceTimestamp = timestamp,
                parsedAmount = parsed.amount,
                parsedType = parsed.transactionType,
                parsedMerchant = parsed.merchant,
                parsedCategoryId = null,
                duplicateHash = duplicateHash
            )
        } else {
            Log.d(TAG, "Suggest mode for payment method: $paymentMethodId, creating pending transaction")
            supabaseHelper.createPendingTransaction(
                ledgerId = ledgerId,
                userId = userId,
                paymentMethodId = paymentMethodId,
                sourceType = dbSourceType,
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

            // 결제수단 이름 가져오기
            val paymentMethodName = matchedPaymentMethod?.name
                ?: paymentMethodsCache.find { it.id == paymentMethodId }?.name

            // 알림 처리 (설정 확인 -> 로컬 알림 표시 -> 히스토리 저장)
            handleAutoCollectNotification(
                userId = userId,
                isAutoMode = settings?.isAutoMode == true,
                amount = parsed.amount,
                merchant = parsed.merchant,
                paymentMethodId = paymentMethodId,
                paymentMethodName = paymentMethodName
            )
        } else {
            Log.d(TAG, "Supabase save failed, keeping in SQLite for later sync")
        }

        notifyFlutter(packageName)
    }

    /**
     * 자동수집 알림 처리 (설정 확인 -> 로컬 알림 표시 -> 히스토리 저장)
     * processNotification에서 분리된 함수로 가독성 향상
     */
    private suspend fun handleAutoCollectNotification(
        userId: String,
        isAutoMode: Boolean,
        amount: Int?,
        merchant: String?,
        paymentMethodId: String,
        paymentMethodName: String?
    ) {
        // 사용자 알림 설정 확인
        val shouldShowNotification = supabaseHelper.getAutoCollectNotificationSetting(userId, isAutoMode)

        if (!shouldShowNotification) {
            Log.d(TAG, "Notification disabled by user setting (isAutoMode=$isAutoMode), skipping local notification")
            return
        }

        // 로컬 알림 표시
        showAutoCollectNotification(
            isAutoMode = isAutoMode,
            amount = amount,
            merchant = merchant,
            paymentMethodName = paymentMethodName
        )

        // 알림 히스토리 저장
        val notificationType = if (isAutoMode) "auto_collect_saved" else "auto_collect_suggested"
        val notificationTitle = if (isAutoMode) "자동수집 거래 저장" else "자동수집 거래 확인"
        val notificationBody = buildNotificationBody(amount, merchant, paymentMethodName)

        val historySaved = supabaseHelper.savePushNotificationHistory(
            userId = userId,
            type = notificationType,
            title = notificationTitle,
            body = notificationBody,
            data = mapOf(
                "targetTab" to if (isAutoMode) "confirmed" else "pending",
                "paymentMethodId" to paymentMethodId,
                "amount" to amount,
                "merchant" to merchant
            )
        )

        if (!historySaved) {
            Log.w(TAG, "Failed to save notification history for type=$notificationType, but local notification was shown")
        }
    }

    /**
     * 자동수집 Local Notification 표시
     */
    private fun showAutoCollectNotification(
        isAutoMode: Boolean,
        amount: Int?,
        merchant: String?,
        paymentMethodName: String?
    ) {
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        // Android 8.0+ 채널 생성 (Flutter와 동일한 채널 사용)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val existingChannel = notificationManager.getNotificationChannel("household_account_channel")
            if (existingChannel == null) {
                val channel = NotificationChannel(
                    "household_account_channel",
                    "공유 가계부 알림",
                    NotificationManager.IMPORTANCE_DEFAULT
                ).apply {
                    description = "공유 가계부 관련 알림 채널"
                    enableVibration(true)
                }
                notificationManager.createNotificationChannel(channel)
            }
        }

        val title = if (isAutoMode) "자동수집 거래 저장" else "자동수집 거래 확인"
        val body = buildNotificationBody(amount, merchant, paymentMethodName)

        // 딥링크 Intent (app_links 플러그인이 cold start/warm start 모두 처리)
        val tab = if (isAutoMode) "confirmed" else "pending"
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            data = Uri.parse("sharedhousehold://payment-method?tab=$tab")
        }

        // AtomicInteger로 고유 ID 생성 (동일 밀리초 중복 방지)
        val notificationId = notificationIdCounter.incrementAndGet()

        val pendingIntent = PendingIntent.getActivity(
            this,
            notificationId,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(this, "household_account_channel")
            .setSmallIcon(R.drawable.ic_notification)  // 알림 전용 아이콘 사용
            .setContentTitle(title)
            .setContentText(body)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .build()

        notificationManager.notify(notificationId, notification)
        Log.d(TAG, "Auto-collect notification shown (id=$notificationId): $title - $body")
    }

    /**
     * 알림 본문 생성
     */
    private fun buildNotificationBody(amount: Int?, merchant: String?, paymentMethodName: String?): String {
        return buildString {
            if (amount != null) {
                append(String.format("%,d", amount))
                append("원")
            }
            if (!merchant.isNullOrBlank()) {
                if (isNotEmpty()) append(" ")
                append(merchant)
            }
            if (!paymentMethodName.isNullOrBlank()) {
                if (isNotEmpty()) append(" - ")
                append(paymentMethodName)
            }
            if (isEmpty()) {
                append("새로운 거래가 수집되었습니다.")
            }
        }
    }

    /**
     * SMS/Push 알림 파싱에 필요한 데이터를 Supabase에서 메모리로 로드하는 함수
     *
     * 역할:
     * 1. 학습된 SMS 포맷(learnedFormatsCache) 로드
     *    - 사용자가 이전에 수집한 SMS의 패턴을 학습한 데이터
     *    - 패키지명, 금액/상호/날짜 정규식 등이 포함
     * 2. 결제수단 정보(paymentMethodsCache) 로드
     *    - 현재 사용자가 소유한 결제수단 목록
     *    - 자동수집 모드(자동/제안/수동), 소스타입(SMS/Push) 등이 포함
     * 3. 캐시 유효성 관리
     *    - 캐시 만료 시간(FORMAT_CACHE_DURATION_MS)이 지나면 자동 새로고침
     *    - 불필요한 네트워크 요청 방지 (성능 최적화)
     *
     * 사용 시점:
     * - processNotification에서 새 알림 수신 시 매 번 호출
     * - 캐시가 유효하면 Supabase 요청 스킵 (빠른 응답)
     * - 캐시가 만료되면 최신 데이터로 갱신
     *
     * 부수 효과:
     * - 알림 매칭 성능 향상 (Supabase 쿼리 불필요)
     * - 사용자가 UI에서 결제수단 추가/수정 시 invalidateCache() 호출로 강제 새로고침
     *
     * @param ledgerId 가계부 ID (Supabase 데이터 필터링용)
     * @param userId 사용자 ID (소유 결제수단, 권한 검증용)
     */
    private suspend fun refreshFormatsCache(ledgerId: String, userId: String) {
        val now = System.currentTimeMillis()

        // 캐시 유효성 검사: 마지막 업데이트로부터 경과 시간이 설정값보다 적고, 캐시가 비어있지 않으면 스킵
        if (now - lastFormatsFetchTime < NotificationConfig.FORMAT_CACHE_DURATION_MS && learnedFormatsCache.isNotEmpty()) {
            if (BuildConfig.DEBUG) Log.d(TAG, "Cache fresh, skipping refresh (age: ${now - lastFormatsFetchTime}ms)")
            return
        }

        if (BuildConfig.DEBUG) Log.d(TAG, "Cache expired or empty, refreshing...")

        try {
            // Supabase에서 해당 가계부에 대한 학습된 SMS 포맷 로드
            // 반환값: List<LearnedPushFormat> - 사용자가 이전에 수집한 SMS의 패턴들
            learnedFormatsCache = supabaseHelper.getLearnedPushFormats(ledgerId, userId)

            // Supabase에서 현재 사용자가 소유한 결제수단 정보 로드
            // 반환값: List<PaymentMethodInfo> - 현금, 카드, 체크카드 등 결제수단 정보
            paymentMethodsCache = supabaseHelper.getPaymentMethodsByLedger(ledgerId, userId)

            // 캐시 갱신 시각 저장 (다음 갱신 필요 시점 판단용)
            lastFormatsFetchTime = now

            Log.d(TAG, "Refreshed ${learnedFormatsCache.size} learned push formats, ${paymentMethodsCache.size} payment methods")

            if (BuildConfig.DEBUG) {
                paymentMethodsCache.forEach { pm ->
                    Log.d(TAG, "  Payment Method: ${pm.name}")
                    Log.d(TAG, "    - ID: ${pm.id}")
                    Log.d(TAG, "    - autoSaveMode: ${pm.autoSaveMode}")
                    Log.d(TAG, "    - autoCollectSource: ${pm.autoCollectSource}")
                    Log.d(TAG, "    - ownerUserId: ${pm.ownerUserId}")
                }
            }
        } catch (e: Exception) {
            // 캐시 갱신 실패해도 기존 캐시 사용 (우아한 저하)
            // Supabase 장애 시에도 앱이 계속 동작할 수 있도록 함
            Log.e(TAG, "Failed to refresh formats cache", e)
        }
    }

    private fun notifyFlutter(packageName: String) {
        val pendingCount = storageHelper.getPendingCount()
        Log.d(TAG, "Total pending notifications: $pendingCount")
        MainActivity.notifyNewNotification(packageName, pendingCount)
    }

    /**
     * MessagingStyle 알림에서 가장 최근 메시지 텍스트만 추출하는 함수
     * Google Messages, Samsung Messages 등이 SMS를 MessagingStyle 알림으로 생성할 때,
     * EXTRA_MESSAGES에 이전 메시지가 누적되어 저장됨
     * 마지막(최신) 메시지만 추출하여 이전 메시지 중복 파싱 방지
     */
    @Suppress("DEPRECATION")
    private fun extractMessagingText(extras: android.os.Bundle): String? {
        val messages = extras.getParcelableArray(Notification.EXTRA_MESSAGES) ?: return null
        // 마지막 메시지만 추출 (최신 SMS)
        val lastMessage = messages.lastOrNull() as? android.os.Bundle ?: return null
        return lastMessage.getCharSequence("text")?.toString()
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
