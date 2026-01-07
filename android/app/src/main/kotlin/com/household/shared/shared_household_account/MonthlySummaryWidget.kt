package com.household.shared.shared_household_account

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import java.text.NumberFormat
import java.util.Locale

/**
 * 월간 요약 위젯 (Monthly Summary Widget)
 *
 * 홈 화면에서 이번 달 지출/수입/잔액을 확인할 수 있는 위젯입니다.
 * 위젯을 탭하면 앱의 메인 화면으로 이동합니다.
 */
class MonthlySummaryWidget : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onEnabled(context: Context) {
        // 위젯이 처음 추가될 때 호출
    }

    override fun onDisabled(context: Context) {
        // 마지막 위젯이 제거될 때 호출
    }

    companion object {
        private const val SCHEME = "sharedhousehold"
        private val numberFormat = NumberFormat.getNumberInstance(Locale.KOREA)

        // 색상 상수
        private const val COLOR_EXPENSE = "#E53935"
        private const val COLOR_INCOME = "#43A047"
        private const val COLOR_BALANCE_POSITIVE = "#43A047"
        private const val COLOR_BALANCE_NEGATIVE = "#E53935"
        private const val COLOR_BALANCE_ZERO = "#000000"

        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val views = RemoteViews(context.packageName, R.layout.widget_monthly_summary)

            // SharedPreferences에서 데이터 읽기
            val widgetData = HomeWidgetPlugin.getData(context)
            val expense = widgetData.getInt("monthly_expense", 0)
            val income = widgetData.getInt("monthly_income", 0)
            val balance = widgetData.getInt("monthly_balance", income - expense)
            val ledgerName = widgetData.getString("ledger_name", "가계부") ?: "가계부"

            // 가계부 이름 표시
            views.setTextViewText(R.id.widget_ledger_name, ledgerName)

            // 금액 포맷팅 및 표시
            views.setTextViewText(R.id.text_expense, formatCurrency(expense))
            views.setTextViewText(R.id.text_income, formatCurrency(income))
            views.setTextViewText(R.id.text_balance, formatCurrency(balance))

            // 잔액 색상 설정
            val balanceColor = when {
                balance > 0 -> Color.parseColor(COLOR_BALANCE_POSITIVE)
                balance < 0 -> Color.parseColor(COLOR_BALANCE_NEGATIVE)
                else -> Color.parseColor(COLOR_BALANCE_ZERO)
            }
            views.setTextColor(R.id.text_balance, balanceColor)

            // 위젯 전체 클릭 시 앱 메인 화면으로 이동
            val homeIntent = createDeepLinkIntent(context, "home")
            val homePendingIntent = PendingIntent.getActivity(
                context,
                2,
                homeIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_container, homePendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        private fun formatCurrency(amount: Int): String {
            val absAmount = kotlin.math.abs(amount)
            val formatted = numberFormat.format(absAmount)
            return if (amount < 0) "-${formatted}원" else "${formatted}원"
        }

        private fun createDeepLinkIntent(context: Context, path: String): Intent {
            val uri = Uri.parse("$SCHEME://$path")
            return Intent(Intent.ACTION_VIEW, uri).apply {
                setPackage(context.packageName)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
        }
    }
}
