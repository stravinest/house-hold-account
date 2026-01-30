package com.household.shared.shared_household_account

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.telephony.SmsMessage
import android.util.Log
import io.flutter.BuildConfig
import kotlinx.coroutines.*

/**
 * 금융 SMS를 수집하는 BroadcastReceiver (Push는 FinancialNotificationListener에서 처리)
 * 앱이 종료되어도 시스템에서 SMS 수신 시 호출되며, SQLite에 저장
 * 현재: SQLite 저장 + Supabase 직접 저장 (Kotlin 파싱)
 * Supabase 실패 시 SQLite 백업으로 Flutter 동기화
 */
class SmsBroadcastReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "FinancialSmsReceiver"
        
        private val FINANCIAL_SMS_SENDERS: Set<String> = buildSet {
            add("kb국민카드")
            add("신한카드")
            add("삼성카드")
            add("현대카드")
            add("롯데카드")
            add("우리카드")
            add("하나카드")
            add("nh카드")
            add("bc카드")
            add("국민은행")
            add("신한은행")
            add("우리은행")
            add("하나은행")
            add("농협")
            add("ibk기업")
            add("카카오뱅크")
            add("토스뱅크")
            add("케이뱅크")
            add("카카오페이")
            add("네이버페이")
            add("토스")
            add("페이코")
            add("경기지역화폐")
        }
        
        private val PAYMENT_KEYWORDS = listOf(
            "원", "won", "krw", "승인", "결제", "사용", "출금", "입금", "이체", "충전"
        )
        
        // Coroutine scope for background processing
        private val receiverScope = CoroutineScope(Dispatchers.IO + SupervisorJob())
        
        // Cache for learned formats
        private var learnedFormatsCache: List<LearnedSmsFormat> = emptyList()
        private var lastFormatsFetchTime: Long = 0
        private val FORMATS_CACHE_DURATION = 5 * 60 * 1000L  // 5 minutes
    }

    private fun getStorageHelper(context: Context): NotificationStorageHelper {
        return NotificationStorageHelper.getInstance(context)
    }

    private fun getSupabaseHelper(context: Context): SupabaseHelper {
        return SupabaseHelper(context)
    }

    override fun onReceive(context: Context?, intent: Intent?) {
        if (context == null || intent == null) return
        if (intent.action != "android.provider.Telephony.SMS_RECEIVED") return

        val bundle = intent.extras ?: return
        val pdus = bundle.get("pdus") as? Array<*> ?: return
        val format = bundle.getString("format")

        for (pdu in pdus) {
            val smsMessage = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                SmsMessage.createFromPdu(pdu as ByteArray, format)
            } else {
                @Suppress("DEPRECATION")
                SmsMessage.createFromPdu(pdu as ByteArray)
            }

            val sender = smsMessage.displayOriginatingAddress?.lowercase() ?: continue
            val body = smsMessage.messageBody ?: continue
            val timestamp = smsMessage.timestampMillis

            if (!isFinancialSms(sender, body)) {
                continue
            }

            Log.d(TAG, "Financial SMS received from: $sender")

            val storageHelper = getStorageHelper(context)

            if (storageHelper.isDuplicate(sender, body)) {
                Log.d(TAG, "Duplicate SMS, skipping")
                continue
            }

            // Save to SQLite first (backup)
            val sqliteId = storageHelper.insertNotification(
                packageName = "sms:$sender",
                title = sender,
                text = body,
                receivedAt = timestamp
            )
            Log.d(TAG, "SMS saved to SQLite with id: $sqliteId")

            // Process Supabase save in background
            val appContext = context.applicationContext
            receiverScope.launch {
                processSms(appContext, sender, body, timestamp, sqliteId)
            }

            // Notify Flutter
            val pendingCount = storageHelper.getPendingCount()
            MainActivity.notifyNewNotification("sms:$sender", pendingCount)
        }
    }

    private suspend fun processSms(
        context: Context,
        sender: String,
        body: String,
        timestamp: Long,
        sqliteId: Long
    ) {
        val supabaseHelper = getSupabaseHelper(context)
        
        if (!supabaseHelper.isInitialized) {
            Log.d(TAG, "Supabase not initialized, using SQLite only")
            return
        }

        val ledgerId = supabaseHelper.getCurrentLedgerId()
        val token = supabaseHelper.getValidToken()
        val userId = token?.let { supabaseHelper.getUserIdFromToken(it) }

        if (ledgerId == null || userId == null) {
            Log.d(TAG, "No ledger or user, using SQLite only")
            return
        }

        // Refresh formats cache if needed
        refreshFormatsCache(supabaseHelper, ledgerId)

        // Find matching format
        val matchingFormat = learnedFormatsCache.find { format ->
            format.senderPattern.equals(sender, ignoreCase = true) ||
            format.senderKeywords.any { keyword ->
                sender.contains(keyword, ignoreCase = true) ||
                body.contains(keyword, ignoreCase = true)
            }
        }

        // Parse the SMS
        val parsed = if (matchingFormat != null) {
            FinancialMessageParser.parseWithSmsFormat(body, matchingFormat)
        } else {
            FinancialMessageParser.parse(sender, body)
        }

        if (!parsed.isParsed) {
            Log.d(TAG, "Failed to parse SMS, keeping in SQLite for Flutter sync")
            return
        }

        // Generate duplicate hash
        val duplicateHash = FinancialMessageParser.generateDuplicateHash(
            parsed.amount ?: 0,
            matchingFormat?.paymentMethodId,
            timestamp
        )

        // Save to Supabase
        val success = supabaseHelper.createPendingTransaction(
            ledgerId = ledgerId,
            userId = userId,
            paymentMethodId = matchingFormat?.paymentMethodId ?: "",
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

        if (success) {
            Log.d(TAG, "SMS saved to Supabase, marking SQLite as synced")
            val storageHelper = getStorageHelper(context)
            storageHelper.markAsSynced(listOf(sqliteId))
        } else {
            Log.d(TAG, "Supabase save failed, keeping in SQLite for later sync")
        }
    }

    private suspend fun refreshFormatsCache(supabaseHelper: SupabaseHelper, ledgerId: String) {
        val now = System.currentTimeMillis()
        if (now - lastFormatsFetchTime < FORMATS_CACHE_DURATION && learnedFormatsCache.isNotEmpty()) {
            return
        }

        try {
            learnedFormatsCache = supabaseHelper.getLearnedSmsFormats(ledgerId)
            lastFormatsFetchTime = now
            Log.d(TAG, "Refreshed ${learnedFormatsCache.size} learned SMS formats")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to refresh SMS formats cache", e)
        }
    }

    private fun isFinancialSms(sender: String, body: String): Boolean {
        val senderLower = sender.lowercase()
        val bodyLower = body.lowercase()

        val isFinancialSender = FINANCIAL_SMS_SENDERS.any { 
            senderLower.contains(it) 
        }

        val hasPaymentKeyword = PAYMENT_KEYWORDS.any { 
            bodyLower.contains(it) 
        }

        return isFinancialSender || hasPaymentKeyword
    }
}
