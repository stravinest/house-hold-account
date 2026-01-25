package com.household.shared.shared_household_account

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.os.Bundle
import android.view.ViewGroup
import android.widget.Button
import android.widget.EditText
import android.widget.Toast
import es.antonborri.home_widget.HomeWidgetPlugin
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.launch

class QuickInputActivity : Activity() {
    private lateinit var supabaseHelper: SupabaseHelper
    
    private lateinit var amountInput: EditText
    private lateinit var titleInput: EditText
    private lateinit var saveButton: Button
    private lateinit var cancelButton: Button
    
    private val activityScope = CoroutineScope(Dispatchers.Main + Job())
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_quick_input)
        
        window.setLayout(
            ViewGroup.LayoutParams.WRAP_CONTENT,
            ViewGroup.LayoutParams.WRAP_CONTENT
        )
        
        supabaseHelper = SupabaseHelper(this)
        
        // 초기화 실패 시 앱을 먼저 실행하라는 메시지 표시
        if (!supabaseHelper.isInitialized) {
            Toast.makeText(this, "앱을 먼저 실행해주세요", Toast.LENGTH_LONG).show()
            finish()
            return
        }
        
        amountInput = findViewById(R.id.amountInput)
        titleInput = findViewById(R.id.titleInput)
        saveButton = findViewById(R.id.saveButton)
        cancelButton = findViewById(R.id.cancelButton)
        
        saveButton.setOnClickListener {
            saveExpense()
        }
        
        cancelButton.setOnClickListener {
            finish()
        }
    }
    
    private fun saveExpense() {
        val amountText = amountInput.text?.toString()
        
        if (amountText.isNullOrBlank()) {
            Toast.makeText(this, "금액을 입력하세요", Toast.LENGTH_SHORT).show()
            return
        }
        
        val amount = amountText.toIntOrNull()
        if (amount == null || amount <= 0) {
            Toast.makeText(this, "유효한 금액을 입력하세요", Toast.LENGTH_SHORT).show()
            return
        }
        
        activityScope.launch {
            try {
                val ledgerId = supabaseHelper.getCurrentLedgerId()
                if (ledgerId.isNullOrBlank()) {
                    Toast.makeText(this@QuickInputActivity, "가계부를 찾을 수 없습니다", Toast.LENGTH_SHORT).show()
                    return@launch
                }

                val token = supabaseHelper.getValidToken()
                if (token.isNullOrBlank()) {
                    Toast.makeText(this@QuickInputActivity, "로그인이 만료되었습니다. 앱을 먼저 실행해주세요", Toast.LENGTH_LONG).show()
                    finish()
                    return@launch
                }

                val userId = supabaseHelper.getUserIdFromToken(token)
                if (userId.isNullOrBlank()) {
                    Toast.makeText(this@QuickInputActivity, "사용자 정보를 찾을 수 없습니다", Toast.LENGTH_SHORT).show()
                    return@launch
                }

                val title = titleInput.text?.toString()?.takeIf { it.isNotBlank() }
                val today = supabaseHelper.getTodayDate()

                val success = supabaseHelper.createExpenseTransaction(
                    ledgerId = ledgerId,
                    userId = userId,
                    amount = amount,
                    title = title,
                    categoryId = null,
                    date = today
                )

                if (success) {
                    updateWidgetData(ledgerId)
                    Toast.makeText(this@QuickInputActivity, "저장 완료", Toast.LENGTH_SHORT).show()
                    finish()
                } else {
                    Toast.makeText(this@QuickInputActivity, "저장 실패. 네트워크를 확인해주세요", Toast.LENGTH_SHORT).show()
                }
            } catch (e: Exception) {
                Toast.makeText(this@QuickInputActivity, "오류: ${e.message}", Toast.LENGTH_SHORT).show()
            }
        }
    }

    private fun updateWidgetData(ledgerId: String) {
        activityScope.launch {
            try {
                val monthlyTotal = supabaseHelper.getMonthlyTotal(ledgerId)
                if (monthlyTotal != null) {
                    val (income, expense) = monthlyTotal

                    val widgetData = HomeWidgetPlugin.getData(this@QuickInputActivity)
                    widgetData.edit()
                        .putInt("monthly_income", income)
                        .putInt("monthly_expense", expense)
                        .apply()

                    val appWidgetManager = AppWidgetManager.getInstance(this@QuickInputActivity)
                    val componentName = ComponentName(this@QuickInputActivity, MonthlySummaryWidget::class.java)
                    val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)

                    for (appWidgetId in appWidgetIds) {
                        MonthlySummaryWidget.updateAppWidget(this@QuickInputActivity, appWidgetManager, appWidgetId)
                    }

                    android.util.Log.d("QuickInputActivity", "Widget updated - income: $income, expense: $expense")
                }
            } catch (e: Exception) {
                android.util.Log.e("QuickInputActivity", "Failed to update widget", e)
            }
        }
    }
}
