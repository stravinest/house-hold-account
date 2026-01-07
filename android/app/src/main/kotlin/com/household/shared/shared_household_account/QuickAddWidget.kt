package com.household.shared.shared_household_account

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

/**
 * 빠른 추가 위젯 (Quick Add Widget)
 *
 * 홈 화면에서 지출/수입을 빠르게 추가할 수 있는 위젯입니다.
 * 지출 버튼을 누르면 앱의 지출 추가 화면으로 이동하고,
 * 수입 버튼을 누르면 앱의 수입 추가 화면으로 이동합니다.
 */
class QuickAddWidget : AppWidgetProvider() {

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

        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val views = RemoteViews(context.packageName, R.layout.widget_quick_add)

            // 지출 추가 버튼 클릭 이벤트
            val expenseIntent = createDeepLinkIntent(context, "add-expense")
            val expensePendingIntent = PendingIntent.getActivity(
                context,
                0,
                expenseIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.btn_add_expense, expensePendingIntent)

            // 수입 추가 버튼 클릭 이벤트
            val incomeIntent = createDeepLinkIntent(context, "add-income")
            val incomePendingIntent = PendingIntent.getActivity(
                context,
                1,
                incomeIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.btn_add_income, incomePendingIntent)

            // 가계부 이름 표시 (SharedPreferences에서 읽기)
            val widgetData = HomeWidgetPlugin.getData(context)
            val ledgerName = widgetData.getString("ledger_name", "가계부") ?: "가계부"
            views.setTextViewText(R.id.widget_title, ledgerName)

            appWidgetManager.updateAppWidget(appWidgetId, views)
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
