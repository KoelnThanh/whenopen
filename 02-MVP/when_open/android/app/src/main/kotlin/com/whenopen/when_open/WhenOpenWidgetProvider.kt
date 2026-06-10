package com.whenopen.when_open

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONObject

/**
 * Home-Widget (E14): fester Kategorie-Filter pro Instanz, Kopfzeile mit
 * Kategorie links / Datum rechts, kein Schriftzug. Die Daten kommen
 * vorberechnet aus Dart (home_widget SharedPreferences, Key "widget_daten").
 */
class WhenOpenWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (id in appWidgetIds) {
            aktualisiere(context, appWidgetManager, id)
        }
    }

    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        val prefs = filterPrefs(context).edit()
        for (id in appWidgetIds) prefs.remove(filterKey(id))
        prefs.apply()
    }

    companion object {
        const val FILTER_ALLE = "alle"
        const val FILTER_SONSTIGE = "sonstige"
        private const val FILTER_PREFS = "whenopen_widget_filter"

        fun filterPrefs(context: Context) =
            context.getSharedPreferences(FILTER_PREFS, Context.MODE_PRIVATE)

        fun filterKey(appWidgetId: Int) = "filter_$appWidgetId"

        fun gespeicherterFilter(context: Context, appWidgetId: Int): String =
            filterPrefs(context).getString(filterKey(appWidgetId), FILTER_ALLE)
                ?: FILTER_ALLE

        fun aktualisiere(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val views = RemoteViews(context.packageName, R.layout.when_open_widget)

            // Kopfzeile: Kategoriename + Datum aus den Dart-Daten
            val datenJson =
                HomeWidgetPlugin.getData(context).getString("widget_daten", null)
            val filter = gespeicherterFilter(context, appWidgetId)
            var kopf = context.getString(R.string.widget_alle_orte)
            var datum = ""
            if (datenJson != null) {
                try {
                    val json = JSONObject(datenJson)
                    datum = json.optString("datum", "")
                    kopf = when (filter) {
                        FILTER_ALLE -> json.optString(
                            "alleOrteText", kopf
                        )
                        FILTER_SONSTIGE -> json.optString(
                            "sonstigeText",
                            context.getString(R.string.widget_sonstige)
                        )
                        else -> {
                            val kategorien = json.optJSONArray("kategorien")
                            var name = kopf
                            if (kategorien != null) {
                                for (i in 0 until kategorien.length()) {
                                    val k = kategorien.getJSONObject(i)
                                    if (k.optString("id") == filter) {
                                        name = k.optString("name", name)
                                    }
                                }
                            }
                            name
                        }
                    }
                    views.setTextViewText(
                        R.id.widget_empty,
                        json.optString(
                            "leerText",
                            context.getString(R.string.widget_leer)
                        )
                    )
                } catch (_: Exception) {
                    // Korrupte Daten: zuletzt bekannter Stand bleibt stehen.
                }
            }
            views.setTextViewText(R.id.widget_kategorie, "$kopf ▾")
            views.setTextViewText(R.id.widget_datum, datum)

            // Listen-Adapter (RemoteViewsService), appWidgetId in der Intent-URI,
            // damit jede Instanz ihren eigenen Filter bekommt.
            val serviceIntent = Intent(context, WhenOpenWidgetService::class.java).apply {
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                data = Uri.parse(toUri(Intent.URI_INTENT_SCHEME))
            }
            views.setRemoteAdapter(R.id.widget_list, serviceIntent)
            views.setEmptyView(R.id.widget_list, R.id.widget_empty)

            // Zeilen-Tap: Deep Link whenopen://app/open/<id> (Template + Fill-In)
            val clickIntent = Intent(context, MainActivity::class.java).apply {
                action = Intent.ACTION_VIEW
            }
            val template = PendingIntent.getActivity(
                context,
                appWidgetId,
                clickIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
            )
            views.setPendingIntentTemplate(R.id.widget_list, template)

            // Leerzustand-Tap: App oeffnen
            val openApp = PendingIntent.getActivity(
                context,
                appWidgetId + 100000,
                Intent(context, MainActivity::class.java),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_empty, openApp)

            // Kopf-Tap: Filter dieses Widgets neu konfigurieren
            val configIntent = Intent(context, WhenOpenWidgetConfigActivity::class.java).apply {
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                data = Uri.parse("whenopen://widget-config/$appWidgetId")
            }
            val configPending = PendingIntent.getActivity(
                context,
                appWidgetId + 200000,
                configIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_header, configPending)

            appWidgetManager.updateAppWidget(appWidgetId, views)
            appWidgetManager.notifyAppWidgetViewDataChanged(
                appWidgetId, R.id.widget_list
            )
        }
    }
}
