package com.vivida8.echo

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class EchoHomeWidget : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val phrase = widgetData.getString("phrase", "安静的一刻，值得被留下来")
        val date = widgetData.getString("date", "")

        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_echo)
            views.setTextViewText(R.id.phrase, phrase)
            views.setTextViewText(R.id.date, date)
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
