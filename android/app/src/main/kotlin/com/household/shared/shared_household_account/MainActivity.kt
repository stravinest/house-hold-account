package com.household.shared.shared_household_account

import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.WindowManager
import io.flutter.BuildConfig
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*

class MainActivity : FlutterActivity() {
    companion object {
        private const val TAG = "MainActivity"
        private const val KEYBOARD_CHANNEL = "keyboard_control"
        private const val NOTIFICATION_SYNC_CHANNEL = "com.household.shared/notification_sync"
        private const val NOTIFICATION_EVENT_CHANNEL = "com.household.shared/notification_events"
        private const val DEBUG_TEST_CHANNEL = "com.household.shared/debug_test"
        private const val ERROR_CODE = "NOTIFICATION_SYNC_ERROR"

        // Flutter로 이벤트를 전달하기 위한 싱글톤 참조
        @Volatile
        private var eventSink: EventChannel.EventSink? = null
        private val mainHandler = Handler(Looper.getMainLooper())

        /**
         * 네이티브에서 새 알림 수신 시 Flutter로 이벤트 전달
         * FinancialNotificationListener에서 호출
         */
        fun notifyNewNotification(packageName: String, count: Int) {
            mainHandler.post {
                val sink = eventSink
                if (sink != null) {
                    sink.success(mapOf(
                        "type" to "new_notification",
                        "packageName" to packageName,
                        "pendingCount" to count
                    ))
                    Log.d(TAG, "Sent new notification event to Flutter: $packageName, count: $count")
                } else {
                    Log.d(TAG, "EventSink is null, Flutter not listening: $packageName, count: $count")
                }
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        window.setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_STATE_ALWAYS_HIDDEN)
    }

    private val mainScope = CoroutineScope(Dispatchers.Main + SupervisorJob())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        setupKeyboardChannel(flutterEngine)
        setupNotificationSyncChannel(flutterEngine)
        setupNotificationEventChannel(flutterEngine)
        setupDebugTestChannel(flutterEngine)
    }

    override fun onDestroy() {
        super.onDestroy()
        mainScope.cancel()
    }

    private fun setupKeyboardChannel(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, KEYBOARD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "hideKeyboard" -> {
                    hideKeyboard()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun setupNotificationEventChannel(flutterEngine: FlutterEngine) {
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, NOTIFICATION_EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    Log.d(TAG, "Notification event channel connected")
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                    Log.d(TAG, "Notification event channel disconnected")
                }
            })
    }

    private fun setupNotificationSyncChannel(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NOTIFICATION_SYNC_CHANNEL).setMethodCallHandler { call, result ->
            Log.d(TAG, "Notification sync method called: ${call.method}")

            when (call.method) {
                "getPendingNotifications" -> handleSyncMethod(result, "getPendingNotifications") { helper ->
                    helper.getPendingNotifications()
                }

                "markAsSynced" -> handleSyncMethod(result, "markAsSynced") { helper ->
                    @Suppress("UNCHECKED_CAST")
                    val ids = (call.argument<List<Number>>("ids") ?: emptyList())
                        .map { it.toLong() }
                    helper.markAsSynced(ids)
                }

                "clearOldNotifications" -> handleSyncMethod(result, "clearOldNotifications") { helper ->
                    val days = call.argument<Int>("days") ?: 7
                    helper.clearOldNotifications(days)
                }

                "getPendingCount" -> handleSyncMethod(result, "getPendingCount") { helper ->
                    helper.getPendingCount()
                }

                "getFailedCount" -> handleSyncMethod(result, "getFailedCount") { helper ->
                    helper.getFailedCount()
                }

                "incrementRetryCount" -> handleSyncMethod(result, "incrementRetryCount") { helper ->
                    val id = call.argument<Number>("id")?.toLong()
                        ?: throw IllegalArgumentException("id is required")
                    helper.incrementRetryCount(id)
                }

                "clearAll" -> {
                    // 디버그 빌드에서만 허용 (프로덕션 보호)
                    if (!BuildConfig.DEBUG) {
                        Log.w(TAG, "clearAll is only available in debug builds")
                        result.error("DEBUG_ONLY", "This method is only available in debug builds", null)
                        return@setMethodCallHandler
                    }
                    handleSyncMethod(result, "clearAll") { helper ->
                        helper.clearAll()
                    }
                }

                else -> result.notImplemented()
            }
        }
    }

    /**
     * 알림 동기화 메서드 공통 핸들러
     * try-catch 패턴을 추출하여 코드 중복 제거
     */
    private inline fun <T> handleSyncMethod(
        result: MethodChannel.Result,
        methodName: String,
        crossinline block: (NotificationStorageHelper) -> T
    ) {
        try {
            val helper = NotificationStorageHelper.getInstance(applicationContext)
            val value = block(helper)
            Log.d(TAG, "$methodName completed successfully")
            result.success(value)
        } catch (e: Exception) {
            Log.e(TAG, "Error in $methodName", e)
            result.error(ERROR_CODE, e.message, null)
        }
    }

    private fun setupDebugTestChannel(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DEBUG_TEST_CHANNEL).setMethodCallHandler { call, result ->
            if (!BuildConfig.DEBUG) {
                Log.w(TAG, "Debug test channel is only available in debug builds")
                result.error("DEBUG_ONLY", "This channel is only available in debug builds", null)
                return@setMethodCallHandler
            }

            Log.d(TAG, "Debug test method called: ${call.method}")

            when (call.method) {
                "simulateSms" -> {
                    val sender = call.argument<String>("sender") ?: "15881688"
                    val body = call.argument<String>("body") ?: ""
                    simulateSmsForTest(sender, body, result)
                }

                "simulatePush" -> {
                    val packageName = call.argument<String>("packageName") ?: ""
                    val title = call.argument<String>("title") ?: ""
                    val text = call.argument<String>("text") ?: ""
                    simulatePushForTest(packageName, title, text, result)
                }

                "getDebugStatus" -> {
                    getDebugStatus(result)
                }

                "clearAllTestData" -> {
                    clearAllTestData(result)
                }

                "getSupabaseStatus" -> {
                    getSupabaseStatus(result)
                }

                "testParsing" -> {
                    val content = call.argument<String>("content") ?: ""
                    val sourceType = call.argument<String>("sourceType") ?: "sms"
                    testParsing(content, sourceType, result)
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun simulateSmsForTest(sender: String, body: String, result: MethodChannel.Result) {
        Log.d(TAG, "[TEST] Simulating SMS from: $sender")
        
        mainScope.launch {
            try {
                val storageHelper = NotificationStorageHelper.getInstance(applicationContext)
                val supabaseHelper = SupabaseHelper.getInstance(applicationContext)
                val timestamp = System.currentTimeMillis()

                val sqliteId = storageHelper.insertNotification(
                    packageName = "sms:$sender",
                    title = sender,
                    text = body,
                    receivedAt = timestamp
                )
                Log.d(TAG, "[TEST] SMS saved to SQLite with id: $sqliteId")

                var supabaseSuccess = false
                if (supabaseHelper.isInitialized) {
                    val ledgerId = supabaseHelper.getCurrentLedgerId()
                    val token = supabaseHelper.getValidToken()
                    val userId = token?.let { supabaseHelper.getUserIdFromToken(it) }

                    if (ledgerId != null && userId != null) {
                        val parsed = FinancialMessageParser.parse(sender, body)
                        Log.d(TAG, "[TEST] Parsed result: amount=${parsed.amount}, type=${parsed.transactionType}, merchant=${parsed.merchant}")

                        if (parsed.isParsed) {
                            val duplicateHash = FinancialMessageParser.generateDuplicateHash(
                                parsed.amount ?: 0,
                                null,
                                timestamp
                            )

                            supabaseSuccess = withContext(Dispatchers.IO) {
                                supabaseHelper.createPendingTransaction(
                                    ledgerId = ledgerId,
                                    userId = userId,
                                    paymentMethodId = "",
                                    sourceType = "sms",
                                    sourceSender = sender,
                                    sourceContent = body,
                                    sourceTimestamp = timestamp,
                                    parsedAmount = parsed.amount,
                                    parsedType = parsed.transactionType,
                                    parsedMerchant = parsed.merchant,
                                    parsedCategoryId = null,
                                    duplicateHash = duplicateHash,
                                    isDuplicate = false
                                )
                            }

                            if (supabaseSuccess) {
                                storageHelper.markAsSynced(listOf(sqliteId))
                                Log.d(TAG, "[TEST] SMS saved to Supabase")
                            }
                        }
                    }
                }

                val pendingCount = storageHelper.getPendingCount()
                notifyNewNotification("sms:$sender", pendingCount)

                result.success(mapOf(
                    "sqliteId" to sqliteId,
                    "supabaseSuccess" to supabaseSuccess,
                    "pendingCount" to pendingCount
                ))
            } catch (e: Exception) {
                Log.e(TAG, "[TEST] SMS simulation failed", e)
                result.error("TEST_ERROR", e.message, null)
            }
        }
    }

    private fun simulatePushForTest(packageName: String, title: String, text: String, result: MethodChannel.Result) {
        Log.d(TAG, "[TEST] Simulating Push from: $packageName")
        
        mainScope.launch {
            try {
                val storageHelper = NotificationStorageHelper.getInstance(applicationContext)
                val supabaseHelper = SupabaseHelper.getInstance(applicationContext)
                val timestamp = System.currentTimeMillis()
                val combinedContent = if (title.isNotEmpty()) "$title $text" else text

                val sqliteId = storageHelper.insertNotification(
                    packageName = packageName,
                    title = title,
                    text = text,
                    receivedAt = timestamp
                )
                Log.d(TAG, "[TEST] Push saved to SQLite with id: $sqliteId")

                var supabaseSuccess = false
                if (supabaseHelper.isInitialized) {
                    val ledgerId = supabaseHelper.getCurrentLedgerId()
                    val token = supabaseHelper.getValidToken()
                    val userId = token?.let { supabaseHelper.getUserIdFromToken(it) }

                    if (ledgerId != null && userId != null) {
                        val parsed = FinancialMessageParser.parse(packageName, combinedContent)
                        Log.d(TAG, "[TEST] Parsed result: amount=${parsed.amount}, type=${parsed.transactionType}, merchant=${parsed.merchant}")

                        if (parsed.isParsed) {
                            val duplicateHash = FinancialMessageParser.generateDuplicateHash(
                                parsed.amount ?: 0,
                                null,
                                timestamp
                            )

                            supabaseSuccess = withContext(Dispatchers.IO) {
                                supabaseHelper.createPendingTransaction(
                                    ledgerId = ledgerId,
                                    userId = userId,
                                    paymentMethodId = "",
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

                            if (supabaseSuccess) {
                                storageHelper.markAsSynced(listOf(sqliteId))
                                Log.d(TAG, "[TEST] Push saved to Supabase")
                            }
                        }
                    }
                }

                val pendingCount = storageHelper.getPendingCount()
                notifyNewNotification(packageName, pendingCount)

                result.success(mapOf(
                    "sqliteId" to sqliteId,
                    "supabaseSuccess" to supabaseSuccess,
                    "pendingCount" to pendingCount
                ))
            } catch (e: Exception) {
                Log.e(TAG, "[TEST] Push simulation failed", e)
                result.error("TEST_ERROR", e.message, null)
            }
        }
    }

    private fun getDebugStatus(result: MethodChannel.Result) {
        try {
            val storageHelper = NotificationStorageHelper.getInstance(applicationContext)
            val supabaseHelper = SupabaseHelper.getInstance(applicationContext)

            val status = mapOf(
                "sqlite" to mapOf(
                    "pendingCount" to storageHelper.getPendingCount(),
                    "failedCount" to storageHelper.getFailedCount()
                ),
                "supabase" to mapOf(
                    "initialized" to supabaseHelper.isInitialized,
                    "hasToken" to (supabaseHelper.getAuthToken() != null),
                    "ledgerId" to supabaseHelper.getCurrentLedgerId()
                ),
                "notificationListener" to mapOf(
                    "instance" to (FinancialNotificationListener.instance != null)
                )
            )

            result.success(status)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to get debug status", e)
            result.error("DEBUG_ERROR", e.message, null)
        }
    }

    private fun clearAllTestData(result: MethodChannel.Result) {
        try {
            val storageHelper = NotificationStorageHelper.getInstance(applicationContext)
            val count = storageHelper.clearAll()
            Log.d(TAG, "[TEST] Cleared $count notifications from SQLite")
            result.success(count)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to clear test data", e)
            result.error("DEBUG_ERROR", e.message, null)
        }
    }

    private fun getSupabaseStatus(result: MethodChannel.Result) {
        mainScope.launch {
            try {
                val supabaseHelper = SupabaseHelper.getInstance(applicationContext)
                
                val tokenValid = withContext(Dispatchers.IO) {
                    supabaseHelper.getValidToken() != null
                }

                result.success(mapOf(
                    "initialized" to supabaseHelper.isInitialized,
                    "tokenValid" to tokenValid,
                    "ledgerId" to supabaseHelper.getCurrentLedgerId(),
                    "hasRefreshToken" to (supabaseHelper.getRefreshToken() != null)
                ))
            } catch (e: Exception) {
                Log.e(TAG, "Failed to get Supabase status", e)
                result.error("DEBUG_ERROR", e.message, null)
            }
        }
    }

    private fun testParsing(content: String, sourceType: String, result: MethodChannel.Result) {
        try {
            val parsed = FinancialMessageParser.parse("test", content)
            
            result.success(mapOf(
                "isParsed" to parsed.isParsed,
                "amount" to parsed.amount,
                "transactionType" to parsed.transactionType,
                "merchant" to parsed.merchant,
                "dateTimeMillis" to parsed.dateTimeMillis,
                "cardLastDigits" to parsed.cardLastDigits,
                "confidence" to parsed.confidence,
                "matchedPattern" to parsed.matchedPattern
            ))
        } catch (e: Exception) {
            Log.e(TAG, "Failed to test parsing", e)
            result.error("DEBUG_ERROR", e.message, null)
        }
    }

    private fun hideKeyboard() {
        val imm = getSystemService(android.content.Context.INPUT_METHOD_SERVICE) as android.view.inputmethod.InputMethodManager
        currentFocus?.let {
            imm.hideSoftInputFromWindow(it.windowToken, 0)
        }
    }
}
