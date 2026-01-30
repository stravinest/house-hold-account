package com.household.shared.shared_household_account

import android.content.Context
import android.database.ContentObserver
import android.database.Cursor
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.Telephony
import android.util.Log
import kotlinx.coroutines.*

/**
 * Android 14+ (API 34+)에서는 SMS_RECEIVED 브로드캐스트가 기본 SMS 앱에만 전달됩니다.
 * 따라서 ContentObserver를 사용하여 SMS 데이터베이스 변경을 감지합니다.
 * 
 * 이 Observer는 content://sms 의 변경을 감지하고,
 * 새로운 금융 SMS가 추가되면 처리합니다.
 */
class SmsContentObserver(
    private val context: Context,
    handler: Handler = Handler(Looper.getMainLooper())
) : ContentObserver(handler) {

    companion object {
        private const val TAG = "FinancialSmsObserver"
        private val SMS_URI: Uri = Uri.parse("content://sms")
        private val SMS_INBOX_URI: Uri = Uri.parse("content://sms/inbox")
        
        @Volatile
        private var instance: SmsContentObserver? = null
        private var lastProcessedId: Long = -1
        private var isRegistered = false
        
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
            add("15881688")
            add("15881111")
            add("15881000")
            add("15772100")
            add("15882900")
            add("15881600")
            add("15881800")
        }
        
        private val PAYMENT_KEYWORDS = listOf(
            "원", "won", "krw", "승인", "결제", "사용", "출금", "입금", "이체", "충전"
        )

        fun getInstance(context: Context): SmsContentObserver {
            return instance ?: synchronized(this) {
                instance ?: SmsContentObserver(context.applicationContext).also { 
                    instance = it 
                }
            }
        }
        
        fun register(context: Context) {
            synchronized(this) {
                if (isRegistered) {
                    Log.d(TAG, "SmsContentObserver already registered")
                    return
                }
                
                val observer = getInstance(context)
                observer.initializeLastProcessedId()
                
                context.contentResolver.registerContentObserver(
                    SMS_URI,
                    true,
                    observer
                )
                isRegistered = true
                Log.d(TAG, "SmsContentObserver registered, lastProcessedId: $lastProcessedId")
            }
        }
        
        fun unregister(context: Context) {
            synchronized(this) {
                if (!isRegistered) {
                    Log.d(TAG, "SmsContentObserver not registered")
                    return
                }
                
                instance?.let {
                    context.contentResolver.unregisterContentObserver(it)
                    isRegistered = false
                    Log.d(TAG, "SmsContentObserver unregistered")
                }
            }
        }
    }
    
    private val observerScope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    private var learnedFormatsCache: List<LearnedSmsFormat> = emptyList()
    private var paymentMethodsCache: List<SupabaseHelper.PaymentMethodInfo> = emptyList()
    private var lastFormatsFetchTime: Long = 0
    private val FORMATS_CACHE_DURATION = 5 * 60 * 1000L
    
    private val processingSmsIds = mutableSetOf<Long>()
    private val processingLock = Any()
    
    private fun getStorageHelper(): NotificationStorageHelper {
        return NotificationStorageHelper.getInstance(context)
    }
    
    private fun getSupabaseHelper(): SupabaseHelper {
        return SupabaseHelper(context)
    }
    
    private fun initializeLastProcessedId() {
        try {
            context.contentResolver.query(
                SMS_INBOX_URI,
                arrayOf(Telephony.Sms._ID),
                null,
                null,
                "${Telephony.Sms._ID} DESC LIMIT 1"
            )?.use { cursor ->
                if (cursor.moveToFirst()) {
                    lastProcessedId = cursor.getLong(0)
                    Log.d(TAG, "Initialized lastProcessedId: $lastProcessedId")
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to initialize lastProcessedId", e)
        }
    }

    override fun onChange(selfChange: Boolean) {
        onChange(selfChange, null)
    }

    override fun onChange(selfChange: Boolean, uri: Uri?) {
        Log.d(TAG, "SMS content changed, uri: $uri, selfChange: $selfChange")
        observerScope.launch {
            processNewSms()
        }
    }
    
    private suspend fun processNewSms() {
        try {
            val newMessages = getNewSmsMessages()
            
            for (smsData in newMessages) {
                val shouldProcess = synchronized(processingLock) {
                    if (processingSmsIds.contains(smsData.id)) {
                        false
                    } else {
                        processingSmsIds.add(smsData.id)
                        true
                    }
                }
                
                if (shouldProcess) {
                    try {
                        processSmsMessage(smsData)
                    } finally {
                        synchronized(processingLock) {
                            processingSmsIds.remove(smsData.id)
                        }
                    }
                } else {
                    Log.d(TAG, "SMS id=${smsData.id} already being processed, skipping")
                }
            }
            
            if (newMessages.isNotEmpty()) {
                lastProcessedId = newMessages.maxOf { it.id }
                Log.d(TAG, "Updated lastProcessedId to: $lastProcessedId")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error processing new SMS", e)
        }
    }
    
    private fun getNewSmsMessages(): List<SmsData> {
        val messages = mutableListOf<SmsData>()
        
        try {
            val selection = "${Telephony.Sms._ID} > ? AND ${Telephony.Sms.TYPE} = ?"
            val selectionArgs = arrayOf(
                lastProcessedId.toString(),
                Telephony.Sms.MESSAGE_TYPE_INBOX.toString()
            )
            
            context.contentResolver.query(
                SMS_INBOX_URI,
                arrayOf(
                    Telephony.Sms._ID,
                    Telephony.Sms.ADDRESS,
                    Telephony.Sms.BODY,
                    Telephony.Sms.DATE
                ),
                selection,
                selectionArgs,
                "${Telephony.Sms._ID} ASC"
            )?.use { cursor ->
                while (cursor.moveToNext()) {
                    val id = cursor.getLong(0)
                    val address = cursor.getString(1) ?: continue
                    val body = cursor.getString(2) ?: continue
                    val date = cursor.getLong(3)
                    
                    if (isFinancialSms(address, body)) {
                        messages.add(SmsData(id, address, body, date))
                        Log.d(TAG, "Found new financial SMS: id=$id, from=$address")
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error querying SMS", e)
        }
        
        return messages
    }
    
    private suspend fun processSmsMessage(smsData: SmsData) {
        val storageHelper = getStorageHelper()
        
        val normalizedBody = normalizeContent(smsData.body)
        
        if (storageHelper.isDuplicate(smsData.address, normalizedBody)) {
            Log.d(TAG, "Duplicate SMS, skipping: ${smsData.id}")
            return
        }
        
        Log.d(TAG, "Processing financial SMS from: ${smsData.address}")
        
        val sqliteId = storageHelper.insertNotification(
            packageName = "sms:${smsData.address}",
            title = smsData.address,
            text = normalizedBody,
            receivedAt = smsData.date
        )
        Log.d(TAG, "SMS saved to SQLite with id: $sqliteId")
        
        val normalizedSmsData = smsData.copy(body = normalizedBody)
        processSmsToSupabase(normalizedSmsData, sqliteId)
        
        val pendingCount = storageHelper.getPendingCount()
        MainActivity.notifyNewNotification("sms:${smsData.address}", pendingCount)
    }
    
    private suspend fun processSmsToSupabase(smsData: SmsData, sqliteId: Long) {
        val supabaseHelper = getSupabaseHelper()
        
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

        refreshFormatsCache(supabaseHelper, ledgerId)

        val matchingFormat = learnedFormatsCache.find { format ->
            format.senderPattern.equals(smsData.address, ignoreCase = true) ||
            format.senderKeywords.any { keyword ->
                smsData.address.contains(keyword, ignoreCase = true) ||
                smsData.body.contains(keyword, ignoreCase = true)
            }
        }

        val parsed = if (matchingFormat != null) {
            FinancialMessageParser.parseWithSmsFormat(smsData.body, matchingFormat)
        } else {
            FinancialMessageParser.parse(smsData.address, smsData.body)
        }

        if (!parsed.isParsed) {
            Log.d(TAG, "Failed to parse SMS, keeping in SQLite for Flutter sync")
            return
        }

        var paymentMethodId = matchingFormat?.paymentMethodId ?: ""
        var matchedPaymentMethod: SupabaseHelper.PaymentMethodInfo? = null
        
        // learned_sms_formats에서 매칭 안 되면 결제수단 이름으로 fallback 매칭
        if (paymentMethodId.isEmpty()) {
            matchedPaymentMethod = paymentMethodsCache.find { pm ->
                pm.autoCollectSource == "sms" && 
                (smsData.body.contains(pm.name, ignoreCase = true) || smsData.address.contains(pm.name, ignoreCase = true))
            }
            if (matchedPaymentMethod != null) {
                paymentMethodId = matchedPaymentMethod.id
                Log.d(TAG, "Fallback matched by payment method name: ${matchedPaymentMethod.name}")
            }
        }

        val duplicateHash = FinancialMessageParser.generateDuplicateHash(
            parsed.amount ?: 0,
            paymentMethodId.ifEmpty { null },
            smsData.date
        )
        
        // 매칭되는 결제수단이 없으면 스킵 (SQLite는 synced 처리하여 Flutter에서 재처리 방지)
        if (paymentMethodId.isEmpty()) {
            Log.d(TAG, "No matching payment method found, skipping SMS collection")
            getStorageHelper().markAsSynced(listOf(sqliteId))
            return
        }

        val settings = matchedPaymentMethod?.let {
            SupabaseHelper.PaymentMethodAutoSettings(it.autoSaveMode, it.autoCollectSource)
        } ?: supabaseHelper.getPaymentMethodAutoSettings(paymentMethodId)

        // Push 모드로 설정된 결제수단이면 SMS 스킵 (SQLite는 synced 처리)
        if (settings != null && !settings.isSmsSource) {
            Log.d(TAG, "Payment method is set to push mode, skipping SMS collection")
            getStorageHelper().markAsSynced(listOf(sqliteId))
            return
        }

        val success = if (settings?.isAutoMode == true) {
            Log.d(TAG, "Auto mode enabled for payment method: $paymentMethodId, creating confirmed transaction")
            supabaseHelper.createConfirmedTransaction(
                ledgerId = ledgerId,
                userId = userId,
                paymentMethodId = paymentMethodId,
                sourceType = "sms",
                sourceSender = smsData.address,
                sourceContent = smsData.body,
                sourceTimestamp = smsData.date,
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
                sourceType = "sms",
                sourceSender = smsData.address,
                sourceContent = smsData.body,
                sourceTimestamp = smsData.date,
                parsedAmount = parsed.amount,
                parsedType = parsed.transactionType,
                parsedMerchant = parsed.merchant,
                parsedCategoryId = null,
                duplicateHash = duplicateHash,
                isDuplicate = false
            )
        }

        if (success) {
            Log.d(TAG, "SMS saved to Supabase, marking SQLite as synced")
            val storageHelper = getStorageHelper()
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
            paymentMethodsCache = supabaseHelper.getPaymentMethodsByLedger(ledgerId)
            lastFormatsFetchTime = now
            Log.d(TAG, "Refreshed ${learnedFormatsCache.size} learned SMS formats, ${paymentMethodsCache.size} payment methods")
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
    
    private fun normalizeContent(content: String): String {
        return content
            .replace("\r\n", " ")
            .replace("\n", " ")
            .replace("\r", " ")
            .replace(Regex("\\s+"), " ")
            .trim()
    }
    
    data class SmsData(
        val id: Long,
        val address: String,
        val body: String,
        val date: Long
    )
}
