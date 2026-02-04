package com.household.shared.shared_household_account

import android.content.Context
import android.util.Base64
import android.util.Log
import io.flutter.BuildConfig
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.ConnectionPool
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONArray
import org.json.JSONObject
import java.net.URLEncoder
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.concurrent.TimeUnit

data class Category(
    val id: String,
    val name: String,
    val icon: String,
    val color: String
)

data class LearnedPushFormat(
    val id: String,
    val paymentMethodId: String,
    val packageName: String,
    val appKeywords: List<String>,
    val amountRegex: String,
    val typeKeywords: Map<String, List<String>>,
    val merchantRegex: String?,
    val dateRegex: String?,
    val confidence: Double? = 0.8
)

data class LearnedSmsFormat(
    val id: String,
    val paymentMethodId: String,
    val senderPattern: String,
    val senderKeywords: List<String>,
    val amountRegex: String,
    val typeKeywords: Map<String, List<String>>,
    val merchantRegex: String?,
    val dateRegex: String?
)

class SupabaseHelper private constructor(private val context: Context) {
    private val supabaseUrl: String?
    private val anonKey: String?
    
    val isInitialized: Boolean
        get() = supabaseUrl != null && anonKey != null

    companion object {
        private const val TAG = "SupabaseHelper"
        private const val SCHEMA = "house"
        
        private val client: OkHttpClient by lazy {
            OkHttpClient.Builder()
                .connectTimeout(NotificationConfig.NETWORK_CONNECT_TIMEOUT_SECONDS, TimeUnit.SECONDS)
                .readTimeout(NotificationConfig.NETWORK_READ_TIMEOUT_SECONDS, TimeUnit.SECONDS)
                .writeTimeout(NotificationConfig.NETWORK_WRITE_TIMEOUT_SECONDS, TimeUnit.SECONDS)
                .connectionPool(ConnectionPool(
                    NotificationConfig.CONNECTION_POOL_MAX_IDLE,
                    NotificationConfig.CONNECTION_POOL_KEEP_ALIVE_MINUTES,
                    TimeUnit.MINUTES
                ))
                .build()
        }
        
        @Volatile
        private var instance: SupabaseHelper? = null
        
        fun getInstance(context: Context): SupabaseHelper {
            return instance ?: synchronized(this) {
                instance ?: SupabaseHelper(context.applicationContext).also {
                    instance = it
                }
            }
        }
    }

    init {
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        supabaseUrl = prefs.getString("flutter.supabase_url", null)
        anonKey = prefs.getString("flutter.supabase_anon_key", null)
        
        if (BuildConfig.DEBUG && (supabaseUrl == null || anonKey == null)) {
            Log.w(TAG, "Supabase credentials not found. Please open the app first.")
        }
    }

    private fun getAuthTokenKey(): String? {
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val allKeys = prefs.all.keys
        for (key in allKeys) {
            if (key.contains("auth-token")) {
                return key
            }
        }
        return null
    }

    private fun getSessionJson(): JSONObject? {
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val tokenKey = getAuthTokenKey() ?: return null

        val tokenJson = prefs.getString(tokenKey, null) ?: return null
        return try {
            JSONObject(tokenJson)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to parse session JSON", e)
            null
        }
    }

    fun getAuthToken(): String? {
        val session = getSessionJson() ?: return null
        val accessToken = session.optString("access_token", null)

        if (accessToken != null) {
            if (BuildConfig.DEBUG) {
                Log.d(TAG, "Found access token")
            }
            return accessToken
        }

        if (BuildConfig.DEBUG) {
            Log.w(TAG, "No access token found in session")
        }
        return null
    }

    fun getRefreshToken(): String? {
        val session = getSessionJson() ?: return null
        val refreshToken = session.optString("refresh_token", null)

        if (refreshToken != null) {
            if (BuildConfig.DEBUG) {
                Log.d(TAG, "Found refresh token")
            }
            return refreshToken
        }

        if (BuildConfig.DEBUG) {
            Log.w(TAG, "No refresh token found in session")
        }
        return null
    }

    private fun isTokenExpired(token: String): Boolean {
        return try {
            val parts = token.split(".")
            if (parts.size < 2) return true

            val payload = String(Base64.decode(parts[1], Base64.URL_SAFE or Base64.NO_WRAP))
            val json = JSONObject(payload)

            val exp = json.optLong("exp", 0)
            if (exp == 0L) return true

            val now = System.currentTimeMillis() / 1000
            val isExpired = now >= exp

            if (BuildConfig.DEBUG) {
                if (isExpired) {
                    Log.d(TAG, "Token expired at $exp, now is $now")
                } else {
                    val remainingSeconds = exp - now
                    Log.d(TAG, "Token valid for $remainingSeconds seconds")
                }
            }

            isExpired
        } catch (e: Exception) {
            Log.e(TAG, "Failed to check token expiration", e)
            true
        }
    }

    private suspend fun refreshAccessToken(refreshToken: String): JSONObject? = withContext(Dispatchers.IO) {
        try {
            val baseUrl = supabaseUrl ?: return@withContext null
            val apiKey = anonKey ?: return@withContext null

            if (BuildConfig.DEBUG) {
                Log.d(TAG, "Attempting to refresh access token")
            }

            val json = JSONObject().apply {
                put("refresh_token", refreshToken)
            }

            val requestBody = json.toString().toRequestBody("application/json".toMediaType())

            val request = Request.Builder()
                .url("$baseUrl/auth/v1/token?grant_type=refresh_token")
                .post(requestBody)
                .addHeader("apikey", apiKey)
                .addHeader("Content-Type", "application/json")
                .build()

            val response = client.newCall(request).execute()

            if (response.isSuccessful) {
                val responseBody = response.body?.string() ?: return@withContext null
                val responseJson = JSONObject(responseBody)

                if (BuildConfig.DEBUG) {
                    Log.d(TAG, "Token refresh successful")
                }
                return@withContext responseJson
            } else {
                if (BuildConfig.DEBUG) {
                    val errorBody = response.body?.string() ?: "No error body"
                    Log.e(TAG, "Token refresh failed: ${response.code} ${response.message}\n$errorBody")
                }
                return@withContext null
            }
        } catch (e: Exception) {
            if (BuildConfig.DEBUG) {
                Log.e(TAG, "Exception during token refresh", e)
            }
            return@withContext null
        }
    }

    private fun saveNewSession(newSession: JSONObject): Boolean {
        return try {
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val tokenKey = getAuthTokenKey() ?: return false

            prefs.edit()
                .putString(tokenKey, newSession.toString())
                .apply()

            if (BuildConfig.DEBUG) {
                Log.d(TAG, "New session saved to SharedPreferences")
            }
            true
        } catch (e: Exception) {
            if (BuildConfig.DEBUG) {
                Log.e(TAG, "Failed to save new session", e)
            }
            false
        }
    }

    suspend fun getValidToken(): String? {
        val currentToken = getAuthToken()

        if (currentToken != null && !isTokenExpired(currentToken)) {
            if (BuildConfig.DEBUG) {
                Log.d(TAG, "Current token is valid")
            }
            return currentToken
        }

        if (BuildConfig.DEBUG) {
            Log.d(TAG, "Token expired or missing, attempting refresh")
        }

        val refreshToken = getRefreshToken()
        if (refreshToken == null) {
            if (BuildConfig.DEBUG) {
                Log.w(TAG, "No refresh token available")
            }
            return null
        }

        val newSession = refreshAccessToken(refreshToken)
        if (newSession == null) {
            if (BuildConfig.DEBUG) {
                Log.e(TAG, "Failed to refresh token")
            }
            return null
        }

        if (!saveNewSession(newSession)) {
            if (BuildConfig.DEBUG) {
                Log.e(TAG, "Failed to save new session")
            }
            return null
        }

        val newAccessToken = newSession.optString("access_token", null)
        if (BuildConfig.DEBUG && newAccessToken != null) {
            Log.d(TAG, "Successfully refreshed and saved new token")
        }

        return newAccessToken
    }

    fun getUserIdFromToken(token: String): String? {
        return try {
            val parts = token.split(".")
            if (parts.size < 2) return null
            
            val payload = String(Base64.decode(parts[1], Base64.URL_SAFE or Base64.NO_WRAP))
            val json = JSONObject(payload)
            json.optString("sub", null)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to extract user ID from token", e)
            null
        }
    }

    fun getCurrentLedgerId(): String? {
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        return prefs.getString("flutter.current_ledger_id", null)
    }

    suspend fun getExpenseCategories(ledgerId: String): List<Category> = withContext(Dispatchers.IO) {
        try {
            val baseUrl = supabaseUrl ?: return@withContext emptyList()
            val apiKey = anonKey ?: return@withContext emptyList()
            val token = getValidToken() ?: return@withContext emptyList()
            
            val url = "$baseUrl/rest/v1/categories?ledger_id=eq.$ledgerId&type=eq.expense&select=id,name,icon,color&order=sort_order.asc"
            
            val request = Request.Builder()
                .url(url)
                .get()
                .addHeader("Authorization", "Bearer $token")
                .addHeader("apikey", apiKey)
                .addHeader("Accept-Profile", SCHEMA)
                .build()
            
            val response = client.newCall(request).execute()
            
            if (response.isSuccessful) {
                val responseBody = response.body?.string() ?: "[]"
                val jsonArray = JSONArray(responseBody)
                
                val categories = mutableListOf<Category>()
                for (i in 0 until jsonArray.length()) {
                    val item = jsonArray.getJSONObject(i)
                    categories.add(
                        Category(
                            id = item.getString("id"),
                            name = item.getString("name"),
                            icon = item.getString("icon"),
                            color = item.getString("color")
                        )
                    )
                }
                
                Log.d(TAG, "Loaded ${categories.size} categories")
                categories
            } else {
                Log.e(TAG, "Failed to load categories: ${response.code} ${response.message}")
                emptyList()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Exception while loading categories", e)
            emptyList()
        }
    }

    suspend fun createExpenseTransaction(
        ledgerId: String,
        userId: String,
        amount: Int,
        title: String?,
        categoryId: String?,
        date: String
    ): Boolean = withContext(Dispatchers.IO) {
        try {
            val baseUrl = supabaseUrl ?: return@withContext false
            val apiKey = anonKey ?: return@withContext false
            val token = getValidToken() ?: return@withContext false
            
            val json = JSONObject().apply {
                put("ledger_id", ledgerId)
                put("user_id", userId)
                put("amount", amount)
                put("type", "expense")
                put("date", date)
                if (!title.isNullOrBlank()) {
                    put("title", title)
                }
                if (!categoryId.isNullOrBlank()) {
                    put("category_id", categoryId)
                }
            }
            
            val requestBody = json.toString().toRequestBody("application/json".toMediaType())
            
            val request = Request.Builder()
                .url("$baseUrl/rest/v1/transactions")
                .post(requestBody)
                .addHeader("Authorization", "Bearer $token")
                .addHeader("apikey", apiKey)
                .addHeader("Content-Type", "application/json")
                .addHeader("Content-Profile", SCHEMA)
                .addHeader("Prefer", "return=minimal")
                .build()
            
            val response = client.newCall(request).execute()
            
            if (response.isSuccessful) {
                Log.d(TAG, "Transaction created successfully")
                true
            } else {
                val errorBody = response.body?.string() ?: "No error body"
                Log.e(TAG, "Failed to create transaction: ${response.code} ${response.message}\n$errorBody")
                false
            }
        } catch (e: Exception) {
            Log.e(TAG, "Exception while creating transaction", e)
            false
        }
    }

    fun getTodayDate(): String {
        return SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).format(Date())
    }

    suspend fun getMonthlyTotal(ledgerId: String): Pair<Int, Int>? = withContext(Dispatchers.IO) {
        try {
            val baseUrl = supabaseUrl ?: return@withContext null
            val apiKey = anonKey ?: return@withContext null
            val token = getValidToken() ?: return@withContext null

            val calendar = java.util.Calendar.getInstance()
            val year = calendar.get(java.util.Calendar.YEAR)
            val month = calendar.get(java.util.Calendar.MONTH) + 1

            val startDate = String.format("%04d-%02d-01", year, month)
            val endDate = String.format("%04d-%02d-%02d", year, month, 
                calendar.getActualMaximum(java.util.Calendar.DAY_OF_MONTH))

            val url = "$baseUrl/rest/v1/transactions?ledger_id=eq.$ledgerId&date=gte.$startDate&date=lte.$endDate&select=amount,type"

            val request = Request.Builder()
                .url(url)
                .get()
                .addHeader("Authorization", "Bearer $token")
                .addHeader("apikey", apiKey)
                .addHeader("Accept-Profile", SCHEMA)
                .build()

            val response = client.newCall(request).execute()

            if (response.isSuccessful) {
                val responseBody = response.body?.string() ?: "[]"
                val jsonArray = JSONArray(responseBody)

                var totalIncome = 0
                var totalExpense = 0

                for (i in 0 until jsonArray.length()) {
                    val item = jsonArray.getJSONObject(i)
                    val amount = item.getInt("amount")
                    val type = item.getString("type")

                    when (type) {
                        "income" -> totalIncome += amount
                        "expense" -> totalExpense += amount
                    }
                }

                Log.d(TAG, "Monthly total - income: $totalIncome, expense: $totalExpense")
                Pair(totalIncome, totalExpense)
            } else {
                Log.e(TAG, "Failed to get monthly total: ${response.code}")
                null
            }
        } catch (e: Exception) {
            Log.e(TAG, "Exception while getting monthly total", e)
            null
        }
    }

    suspend fun getLearnedPushFormats(ledgerId: String, ownerUserId: String): List<LearnedPushFormat> = withContext(Dispatchers.IO) {
        try {
            val baseUrl = supabaseUrl ?: return@withContext emptyList()
            val apiKey = anonKey ?: return@withContext emptyList()
            val token = getValidToken() ?: return@withContext emptyList()

            val url = "$baseUrl/rest/v1/learned_push_formats?select=*,payment_methods!inner(ledger_id,owner_user_id)&payment_methods.ledger_id=eq.$ledgerId&payment_methods.owner_user_id=eq.$ownerUserId"

            val request = Request.Builder()
                .url(url)
                .get()
                .addHeader("Authorization", "Bearer $token")
                .addHeader("apikey", apiKey)
                .addHeader("Accept-Profile", SCHEMA)
                .build()

            val response = client.newCall(request).execute()

            if (response.isSuccessful) {
                val responseBody = response.body?.string() ?: "[]"
                val jsonArray = JSONArray(responseBody)

                val formats = mutableListOf<LearnedPushFormat>()
                for (i in 0 until jsonArray.length()) {
                    val item = jsonArray.getJSONObject(i)
                    formats.add(
                        LearnedPushFormat(
                            id = item.getString("id"),
                            paymentMethodId = item.getString("payment_method_id"),
                            packageName = item.getString("package_name"),
                            appKeywords = parseStringArray(item.optJSONArray("app_keywords")),
                            amountRegex = item.optString("amount_regex", "([0-9,]+)\\s*원"),
                            typeKeywords = parseTypeKeywords(item.optJSONObject("type_keywords")),
                            merchantRegex = item.optString("merchant_regex", null),
                            dateRegex = item.optString("date_regex", null),
                            confidence = item.optDouble("confidence", 0.8)
                        )
                    )
                }

                Log.d(TAG, "Loaded ${formats.size} push formats for ledger $ledgerId, user $ownerUserId")
                formats
            } else {
                Log.e(TAG, "Failed to load push formats: ${response.code}")
                emptyList()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Exception while loading push formats", e)
            emptyList()
        }
    }

    suspend fun getLearnedSmsFormats(ledgerId: String): List<LearnedSmsFormat> = withContext(Dispatchers.IO) {
        try {
            val baseUrl = supabaseUrl ?: return@withContext emptyList()
            val apiKey = anonKey ?: return@withContext emptyList()
            val token = getValidToken() ?: return@withContext emptyList()

            val url = "$baseUrl/rest/v1/learned_sms_formats?select=*,payment_methods!inner(ledger_id)&payment_methods.ledger_id=eq.$ledgerId"

            val request = Request.Builder()
                .url(url)
                .get()
                .addHeader("Authorization", "Bearer $token")
                .addHeader("apikey", apiKey)
                .addHeader("Accept-Profile", SCHEMA)
                .build()

            val response = client.newCall(request).execute()

            if (response.isSuccessful) {
                val responseBody = response.body?.string() ?: "[]"
                val jsonArray = JSONArray(responseBody)

                val formats = mutableListOf<LearnedSmsFormat>()
                for (i in 0 until jsonArray.length()) {
                    val item = jsonArray.getJSONObject(i)
                    formats.add(
                        LearnedSmsFormat(
                            id = item.getString("id"),
                            paymentMethodId = item.getString("payment_method_id"),
                            senderPattern = item.getString("sender_pattern"),
                            senderKeywords = parseStringArray(item.optJSONArray("sender_keywords")),
                            amountRegex = item.optString("amount_regex", "([0-9,]+)\\s*원"),
                            typeKeywords = parseTypeKeywords(item.optJSONObject("type_keywords")),
                            merchantRegex = item.optString("merchant_regex", null),
                            dateRegex = item.optString("date_regex", null)
                        )
                    )
                }

                Log.d(TAG, "Loaded ${formats.size} SMS formats for ledger $ledgerId")
                formats
            } else {
                Log.e(TAG, "Failed to load SMS formats: ${response.code}")
                emptyList()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Exception while loading SMS formats", e)
            emptyList()
        }
    }

    data class PaymentMethodAutoSettings(
        val autoSaveMode: String,
        val autoCollectSource: String
    ) {
        val isAutoMode: Boolean get() = autoSaveMode == "auto"
        val isSmsSource: Boolean get() = autoCollectSource == "sms"
        val isPushSource: Boolean get() = autoCollectSource == "push"
    }

    data class PaymentMethodInfo(
        val id: String,
        val name: String,
        val autoSaveMode: String,
        val autoCollectSource: String,
        val ownerUserId: String
    )

    suspend fun getPaymentMethodsByLedger(ledgerId: String, ownerUserId: String): List<PaymentMethodInfo> = withContext(Dispatchers.IO) {
        try {
            val baseUrl = supabaseUrl ?: return@withContext emptyList()
            val apiKey = anonKey ?: return@withContext emptyList()
            val token = getValidToken() ?: return@withContext emptyList()

            val request = Request.Builder()
                .url("$baseUrl/rest/v1/payment_methods?ledger_id=eq.$ledgerId&owner_user_id=eq.$ownerUserId&select=id,name,auto_save_mode,auto_collect_source,owner_user_id")
                .get()
                .addHeader("Authorization", "Bearer $token")
                .addHeader("apikey", apiKey)
                .addHeader("Accept-Profile", SCHEMA)
                .build()

            val response = client.newCall(request).execute()

            if (response.isSuccessful) {
                val responseBody = response.body?.string() ?: return@withContext emptyList()
                val jsonArray = JSONArray(responseBody)
                val methods = mutableListOf<PaymentMethodInfo>()
                
                for (i in 0 until jsonArray.length()) {
                    val item = jsonArray.getJSONObject(i)
                    methods.add(PaymentMethodInfo(
                        id = item.getString("id"),
                        name = item.getString("name"),
                        autoSaveMode = item.optString("auto_save_mode", "suggest"),
                        autoCollectSource = item.optString("auto_collect_source", "sms"),
                        ownerUserId = item.optString("owner_user_id", "")
                    ))
                }
                
                Log.d(TAG, "Loaded ${methods.size} payment methods for ledger $ledgerId, user $ownerUserId")
                methods
            } else {
                Log.e(TAG, "Failed to load payment methods: ${response.code}")
                emptyList()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Exception while loading payment methods", e)
            emptyList()
        }
    }

    suspend fun getPaymentMethodAutoSettings(paymentMethodId: String): PaymentMethodAutoSettings? = withContext(Dispatchers.IO) {
        try {
            if (paymentMethodId.isEmpty()) return@withContext null
            
            val baseUrl = supabaseUrl ?: return@withContext null
            val apiKey = anonKey ?: return@withContext null
            val token = getValidToken() ?: return@withContext null

            val request = Request.Builder()
                .url("$baseUrl/rest/v1/payment_methods?id=eq.$paymentMethodId&select=auto_save_mode,auto_collect_source")
                .get()
                .addHeader("Authorization", "Bearer $token")
                .addHeader("apikey", apiKey)
                .addHeader("Accept-Profile", SCHEMA)
                .build()

            val response = client.newCall(request).execute()

            if (response.isSuccessful) {
                val responseBody = response.body?.string() ?: return@withContext null
                val jsonArray = JSONArray(responseBody)
                if (jsonArray.length() > 0) {
                    val jsonObject = jsonArray.getJSONObject(0)
                    return@withContext PaymentMethodAutoSettings(
                        autoSaveMode = jsonObject.optString("auto_save_mode", "suggest"),
                        autoCollectSource = jsonObject.optString("auto_collect_source", null)
                    )
                }
            }
            null
        } catch (e: Exception) {
            Log.e(TAG, "Error getting payment method auto settings", e)
            null
        }
    }

    suspend fun createPendingTransaction(
        ledgerId: String,
        userId: String,
        paymentMethodId: String,
        sourceType: String,
        sourceSender: String,
        sourceContent: String,
        sourceTimestamp: Long,
        parsedAmount: Int?,
        parsedType: String?,
        parsedMerchant: String?,
        parsedCategoryId: String?,
        duplicateHash: String,
        isDuplicate: Boolean
    ): Boolean = withContext(Dispatchers.IO) {
        try {
            val baseUrl = supabaseUrl ?: return@withContext false
            val apiKey = anonKey ?: return@withContext false
            val token = getValidToken() ?: return@withContext false

            val dateFormat = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US)
            dateFormat.timeZone = java.util.TimeZone.getTimeZone("UTC")

            val json = JSONObject().apply {
                put("ledger_id", ledgerId)
                put("user_id", userId)
                put("payment_method_id", paymentMethodId)
                put("source_type", sourceType)
                put("source_sender", sourceSender)
                put("source_content", sourceContent)
                put("source_timestamp", dateFormat.format(Date(sourceTimestamp)))
                put("status", "pending")
                put("duplicate_hash", duplicateHash)
                put("is_duplicate", isDuplicate)
                put("is_viewed", false)
                if (parsedAmount != null) put("parsed_amount", parsedAmount)
                if (parsedType != null) put("parsed_type", parsedType)
                if (parsedMerchant != null) put("parsed_merchant", parsedMerchant)
                if (parsedCategoryId != null) put("parsed_category_id", parsedCategoryId)
                put("parsed_date", dateFormat.format(Date(sourceTimestamp)))
            }

            val requestBody = json.toString().toRequestBody("application/json".toMediaType())

            val request = Request.Builder()
                .url("$baseUrl/rest/v1/pending_transactions")
                .post(requestBody)
                .addHeader("Authorization", "Bearer $token")
                .addHeader("apikey", apiKey)
                .addHeader("Content-Type", "application/json")
                .addHeader("Content-Profile", SCHEMA)
                .addHeader("Prefer", "return=minimal")
                .build()

            val response = client.newCall(request).execute()

            if (response.isSuccessful) {
                Log.d(TAG, "Pending transaction created successfully")
                true
            } else {
                val errorBody = response.body?.string() ?: "No error body"
                Log.e(TAG, "Failed to create pending transaction: ${response.code}\n$errorBody")
                false
            }
        } catch (e: Exception) {
            Log.e(TAG, "Exception while creating pending transaction", e)
            false
        }
    }

    suspend fun createConfirmedTransaction(
        ledgerId: String,
        userId: String,
        paymentMethodId: String,
        sourceType: String,
        sourceSender: String,
        sourceContent: String,
        sourceTimestamp: Long,
        parsedAmount: Int?,
        parsedType: String?,
        parsedMerchant: String?,
        parsedCategoryId: String?
    ): Boolean = withContext(Dispatchers.IO) {
        try {
            val baseUrl = supabaseUrl ?: return@withContext false
            val apiKey = anonKey ?: return@withContext false
            val token = getValidToken() ?: return@withContext false

            val dateFormat = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US)
            dateFormat.timeZone = java.util.TimeZone.getTimeZone("UTC")
            val dateOnlyFormat = SimpleDateFormat("yyyy-MM-dd", Locale.US)
            dateOnlyFormat.timeZone = java.util.TimeZone.getTimeZone("UTC")

            val pendingJson = JSONObject().apply {
                put("ledger_id", ledgerId)
                put("user_id", userId)
                put("payment_method_id", paymentMethodId)
                put("source_type", sourceType)
                put("source_sender", sourceSender)
                put("source_content", sourceContent)
                put("source_timestamp", dateFormat.format(Date(sourceTimestamp)))
                put("status", "confirmed")
                put("is_viewed", false)
                if (parsedAmount != null) put("parsed_amount", parsedAmount)
                if (parsedType != null) put("parsed_type", parsedType)
                if (parsedMerchant != null) put("parsed_merchant", parsedMerchant)
                if (parsedCategoryId != null) put("parsed_category_id", parsedCategoryId)
                put("parsed_date", dateOnlyFormat.format(Date(sourceTimestamp)))
            }

            val pendingRequestBody = pendingJson.toString().toRequestBody("application/json".toMediaType())
            val pendingRequest = Request.Builder()
                .url("$baseUrl/rest/v1/pending_transactions")
                .post(pendingRequestBody)
                .addHeader("Authorization", "Bearer $token")
                .addHeader("apikey", apiKey)
                .addHeader("Content-Type", "application/json")
                .addHeader("Content-Profile", SCHEMA)
                .addHeader("Prefer", "return=minimal")
                .build()

            val pendingResponse = client.newCall(pendingRequest).execute()
            if (!pendingResponse.isSuccessful) {
                val errorBody = pendingResponse.body?.string() ?: "No error body"
                Log.e(TAG, "Failed to create pending_transactions (confirmed): ${pendingResponse.code}\n$errorBody")
                return@withContext false
            }
            Log.d(TAG, "Pending transaction (confirmed) created successfully")

            val transactionJson = JSONObject().apply {
                put("ledger_id", ledgerId)
                put("user_id", userId)
                if (paymentMethodId.isNotEmpty()) put("payment_method_id", paymentMethodId)
                put("amount", parsedAmount ?: 0)
                put("type", parsedType ?: "expense")
                put("title", parsedMerchant ?: "")
                put("date", dateOnlyFormat.format(Date(sourceTimestamp)))
                if (parsedCategoryId != null) put("category_id", parsedCategoryId)
                put("source_type", sourceType)
            }

            val transactionRequestBody = transactionJson.toString().toRequestBody("application/json".toMediaType())
            val transactionRequest = Request.Builder()
                .url("$baseUrl/rest/v1/transactions")
                .post(transactionRequestBody)
                .addHeader("Authorization", "Bearer $token")
                .addHeader("apikey", apiKey)
                .addHeader("Content-Type", "application/json")
                .addHeader("Content-Profile", SCHEMA)
                .addHeader("Prefer", "return=minimal")
                .build()

            val transactionResponse = client.newCall(transactionRequest).execute()
            if (transactionResponse.isSuccessful) {
                Log.d(TAG, "Transaction created successfully (auto-collect)")
                true
            } else {
                val errorBody = transactionResponse.body?.string() ?: "No error body"
                Log.e(TAG, "Failed to create transaction: ${transactionResponse.code}\n$errorBody")
                false
            }
        } catch (e: Exception) {
            Log.e(TAG, "Exception while creating confirmed transaction", e)
            false
        }
    }

    private fun parseStringArray(jsonArray: JSONArray?): List<String> {
        if (jsonArray == null) return emptyList()
        val result = mutableListOf<String>()
        for (i in 0 until jsonArray.length()) {
            result.add(jsonArray.getString(i))
        }
        return result
    }

    private fun parseTypeKeywords(jsonObject: JSONObject?): Map<String, List<String>> {
        if (jsonObject == null) {
            return mapOf(
                "income" to listOf("입금", "충전"),
                "expense" to listOf("출금", "결제", "승인", "이체")
            )
        }
        val result = mutableMapOf<String, List<String>>()
        val keys = jsonObject.keys()
        while (keys.hasNext()) {
            val key = keys.next()
            val array = jsonObject.optJSONArray(key)
            result[key] = parseStringArray(array)
        }
        return result
    }

    /**
     * 사용자의 자동수집 알림 설정 조회
     *
     * @param userId 사용자 ID
     * @param isAutoMode true: auto_collect_saved_enabled, false: auto_collect_suggested_enabled
     * @return 알림 활성화 여부 (기본값: true - 설정이 없거나 에러 시 알림 표시)
     */
    suspend fun getAutoCollectNotificationSetting(
        userId: String,
        isAutoMode: Boolean
    ): Boolean = withContext(Dispatchers.IO) {
        try {
            val baseUrl = supabaseUrl ?: run {
                Log.w(TAG, "Supabase URL not configured, using default notification setting: true")
                return@withContext true
            }
            val apiKey = anonKey ?: run {
                Log.w(TAG, "Supabase API key not configured, using default notification setting: true")
                return@withContext true
            }
            val token = getValidToken() ?: run {
                Log.w(TAG, "No valid token available, using default notification setting: true")
                return@withContext true
            }

            val column = if (isAutoMode)
                "auto_collect_saved_enabled"
            else
                "auto_collect_suggested_enabled"

            // URL 파라미터 인코딩으로 인젝션 방지
            val encodedUserId = URLEncoder.encode(userId, "UTF-8")
            val url = "$baseUrl/rest/v1/notification_settings?select=$column&user_id=eq.$encodedUserId"

            val request = Request.Builder()
                .url(url)
                .get()
                .addHeader("Authorization", "Bearer $token")
                .addHeader("apikey", apiKey)
                .addHeader("Accept-Profile", SCHEMA)
                .build()

            val response = client.newCall(request).execute()

            if (response.isSuccessful) {
                val responseBody = response.body?.string() ?: return@withContext true
                val jsonArray = JSONArray(responseBody)
                if (jsonArray.length() > 0) {
                    val setting = jsonArray.getJSONObject(0)
                    val enabled = setting.optBoolean(column, true)
                    Log.d(TAG, "Notification setting for $column: $enabled (userId: $userId)")
                    return@withContext enabled
                }
            }
            // 사용자 설정 레코드가 없는 경우 - 기본값 true (알림 활성화)
            // 이는 신규 사용자나 설정을 변경한 적 없는 사용자를 위한 것
            Log.i(TAG, "No notification setting record found for user $userId, using default: true (notifications enabled)")
            true
        } catch (e: Exception) {
            Log.e(TAG, "Error getting notification setting for user $userId", e)
            true
        }
    }

    /**
     * 알림 히스토리 저장 (push_notifications 테이블)
     *
     * @param userId 사용자 ID
     * @param type 알림 타입 ("auto_collect_suggested" or "auto_collect_saved")
     * @param title 알림 제목
     * @param body 알림 본문
     * @param data 추가 데이터
     * @return 저장 성공 여부
     */
    suspend fun savePushNotificationHistory(
        userId: String,
        type: String,
        title: String,
        body: String,
        data: Map<String, Any?>
    ): Boolean = withContext(Dispatchers.IO) {
        try {
            val baseUrl = supabaseUrl ?: return@withContext false
            val apiKey = anonKey ?: return@withContext false
            val token = getValidToken() ?: return@withContext false

            val json = JSONObject().apply {
                put("user_id", userId)
                put("type", type)
                put("title", title)
                put("body", body)
                put("data", JSONObject(data))
                put("is_read", false)
            }

            val requestBody = json.toString().toRequestBody("application/json".toMediaType())

            val request = Request.Builder()
                .url("$baseUrl/rest/v1/push_notifications")
                .post(requestBody)
                .addHeader("Authorization", "Bearer $token")
                .addHeader("apikey", apiKey)
                .addHeader("Content-Type", "application/json")
                .addHeader("Content-Profile", SCHEMA)
                .addHeader("Prefer", "return=minimal")
                .build()

            val response = client.newCall(request).execute()

            if (response.isSuccessful) {
                Log.d(TAG, "Push notification history saved: $type")
                true
            } else {
                val errorBody = response.body?.string() ?: "No error body"
                Log.e(TAG, "Failed to save push notification history: ${response.code}\n$errorBody")
                false
            }
        } catch (e: Exception) {
            Log.e(TAG, "Exception while saving push notification history", e)
            false
        }
    }
}
