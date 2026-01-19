package com.household.shared.shared_household_account

import android.content.Context
import android.util.Base64
import android.util.Log
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

data class Category(
    val id: String,
    val name: String,
    val icon: String,
    val color: String
)

class SupabaseHelper(private val context: Context) {
    private val client = OkHttpClient()
    private val supabaseUrl: String?
    private val anonKey: String?
    
    val isInitialized: Boolean
        get() = supabaseUrl != null && anonKey != null

    companion object {
        private const val TAG = "SupabaseHelper"
    }

    init {
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        supabaseUrl = prefs.getString("flutter.supabase_url", null)
        anonKey = prefs.getString("flutter.supabase_anon_key", null)
        
        if (supabaseUrl == null || anonKey == null) {
            Log.w(TAG, "Supabase credentials not found. Please open the app first.")
        }
    }

    fun getAuthToken(): String? {
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        
        val allKeys = prefs.all.keys
        for (key in allKeys) {
            if (key.contains("auth-token")) {
                val tokenJson = prefs.getString(key, null)
                if (tokenJson != null) {
                    try {
                        val json = JSONObject(tokenJson)
                        val accessToken = json.optString("access_token", null)
                        if (accessToken != null) {
                            Log.d(TAG, "Found auth token with key: $key")
                            return accessToken
                        }
                    } catch (e: Exception) {
                        Log.e(TAG, "Failed to parse auth token JSON", e)
                    }
                }
            }
        }
        
        Log.w(TAG, "No auth token found in SharedPreferences")
        return null
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
            val token = getAuthToken() ?: return@withContext emptyList()
            
            val url = "$baseUrl/rest/v1/categories?ledger_id=eq.$ledgerId&type=eq.expense&select=id,name,icon,color&order=sort_order.asc"
            
            val request = Request.Builder()
                .url(url)
                .get()
                .addHeader("Authorization", "Bearer $token")
                .addHeader("apikey", apiKey)
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
            val token = getAuthToken() ?: return@withContext false
            
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
            val token = getAuthToken() ?: return@withContext null

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
}
