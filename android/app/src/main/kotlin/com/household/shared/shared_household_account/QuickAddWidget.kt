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

            val expenseIntent = createDeepLinkIntent(context, "quick-expense")
            val expensePendingIntent = PendingIntent.getActivity(
                context,
                appWidgetId,
                expenseIntent,
                PendingIntent.FLAG_CANCEL_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.btn_add_expense, expensePendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        private fun createDeepLinkIntent(context: Context, path: String): Intent {
            // Explicitly target QuickInputActivity to avoid intent resolver picking MainActivity
            return Intent(context, QuickInputActivity::class.java).apply {
                data = Uri.parse("$SCHEME://$path")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
        }
    }
}
