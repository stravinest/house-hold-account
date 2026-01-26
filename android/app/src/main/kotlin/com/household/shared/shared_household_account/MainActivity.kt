package com.household.shared.shared_household_account

import android.os.Bundle
import android.util.Log
import android.view.WindowManager
import io.flutter.BuildConfig
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val TAG = "MainActivity"
        private const val KEYBOARD_CHANNEL = "keyboard_control"
        private const val NOTIFICATION_SYNC_CHANNEL = "com.household.shared/notification_sync"
        private const val ERROR_CODE = "NOTIFICATION_SYNC_ERROR"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // 소프트 키보드 숨기기
        window.setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_STATE_ALWAYS_HIDDEN)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        setupKeyboardChannel(flutterEngine)
        setupNotificationSyncChannel(flutterEngine)
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

    private fun hideKeyboard() {
        val imm = getSystemService(android.content.Context.INPUT_METHOD_SERVICE) as android.view.inputmethod.InputMethodManager
        currentFocus?.let {
            imm.hideSoftInputFromWindow(it.windowToken, 0)
        }
    }
}
