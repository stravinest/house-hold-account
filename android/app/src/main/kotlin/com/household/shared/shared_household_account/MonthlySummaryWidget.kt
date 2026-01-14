package com.household.shared.shared_household_account

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import java.text.NumberFormat
import java.util.Locale

class MonthlySummaryWidget : AppWidgetProvider() {

    companion object {
        private const val ACTION_REFRESH = "com.household.shared.ACTION_REFRESH_WIDGET"
        private const val SCHEME = "sharedhousehold"
        private val numberFormat = NumberFormat.getNumberInstance(Locale.KOREA)

        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val views = RemoteViews(context.packageName, R.layout.widget_monthly_summary)

            val widgetData = HomeWidgetPlugin.getData(context)
            val expense = widgetData.getInt("monthly_expense", 0)
            val income = widgetData.getInt("monthly_income", 0)
            
            android.util.Log.d("MonthlySummaryWidget", "updateAppWidget - expense: $expense, income: $income")

            views.setTextViewText(R.id.text_expense, formatCurrency(expense))
            views.setTextViewText(R.id.text_income, formatCurrency(income))

            val homeIntent = createDeepLinkIntent(context, "home")
            val homePendingIntent = PendingIntent.getActivity(
                context,
                2,
                homeIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_container, homePendingIntent)

            val refreshIntent = Intent(context, MonthlySummaryWidget::class.java).apply {
                action = ACTION_REFRESH
            }
            val refreshPendingIntent = PendingIntent.getBroadcast(
                context,
                appWidgetId,
                refreshIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.btn_refresh, refreshPendingIntent)

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

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        android.util.Log.d("MonthlySummaryWidget", "onUpdate called for ${appWidgetIds.size} widgets")
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        
        android.util.Log.d("MonthlySummaryWidget", "onReceive: ${intent.action}")
        
        if (intent.action == ACTION_REFRESH) {
            android.util.Log.d("MonthlySummaryWidget", "Refresh button clicked!")
            
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val componentName = ComponentName(context, MonthlySummaryWidget::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)
            
            android.util.Log.d("MonthlySummaryWidget", "Updating ${appWidgetIds.size} widgets")
            
            for (appWidgetId in appWidgetIds) {
                updateAppWidget(context, appWidgetManager, appWidgetId)
            }
        }
    }

    override fun onEnabled(context: Context) {}

    override fun onDisabled(context: Context) {}
}
