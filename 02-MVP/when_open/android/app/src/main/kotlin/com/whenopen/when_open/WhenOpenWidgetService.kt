package com.whenopen.when_open

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONArray
import org.json.JSONObject

/** Liefert die Listenzeilen des Widgets aus den vorberechneten Dart-Daten. */
class WhenOpenWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        val appWidgetId = intent.getIntExtra(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID
        )
        return WhenOpenViewsFactory(applicationContext, appWidgetId)
    }
}

/** Eine Zeile: entweder Gruppen-Ueberschrift oder Orts-Eintrag. */
private sealed class Zeile {
    data class Kopf(val name: String, val anzahl: Int) : Zeile()
    data class Ort(
        val id: String,
        val name: String,
        val statusText: String,
        val offen: Boolean
    ) : Zeile()
}

private class WhenOpenViewsFactory(
    private val context: Context,
    private val appWidgetId: Int
) : RemoteViewsService.RemoteViewsFactory {

    private var zeilen: List<Zeile> = emptyList()

    override fun onCreate() = ladeDaten()

    override fun onDataSetChanged() = ladeDaten()

    /**
     * Workflow 2: offen oben, geschlossen unten (je alphabetisch — kommt
     * bereits sortiert aus Dart). Bei "Alle Orte" nach Kategorie gruppiert
     * (E10), bei festem Filter flache Liste (E14).
     */
    private fun ladeDaten() {
        val json = HomeWidgetPlugin.getData(context)
            .getString("widget_daten", null) ?: run {
            zeilen = emptyList()
            return
        }
        try {
            val daten = JSONObject(json)
            val filter =
                WhenOpenWidgetProvider.gespeicherterFilter(context, appWidgetId)
            val geoeffnet = eintraege(daten.optJSONArray("geoeffnet"), true)
            val geschlossen = eintraege(daten.optJSONArray("geschlossen"), false)

            zeilen = if (filter == WhenOpenWidgetProvider.FILTER_ALLE) {
                graupiertNachKategorie(daten, geoeffnet, geschlossen)
            } else {
                val kategorieId =
                    if (filter == WhenOpenWidgetProvider.FILTER_SONSTIGE) null
                    else filter
                (geoeffnet + geschlossen).filter { it.kategorieId == kategorieId }
                    .map { it.zeile }
            }
        } catch (_: Exception) {
            zeilen = emptyList()
        }
    }

    private data class EintragMitKategorie(
        val kategorieId: String?,
        val zeile: Zeile.Ort
    )

    private fun eintraege(
        array: JSONArray?,
        offen: Boolean
    ): List<EintragMitKategorie> {
        if (array == null) return emptyList()
        val ergebnis = mutableListOf<EintragMitKategorie>()
        for (i in 0 until array.length()) {
            val e = array.getJSONObject(i)
            ergebnis.add(
                EintragMitKategorie(
                    kategorieId = if (e.has("kategorieId"))
                        e.getString("kategorieId") else null,
                    zeile = Zeile.Ort(
                        id = e.getString("id"),
                        name = e.getString("name"),
                        statusText = e.getString("statusText"),
                        offen = offen
                    )
                )
            )
        }
        return ergebnis
    }

    private fun graupiertNachKategorie(
        daten: JSONObject,
        geoeffnet: List<EintragMitKategorie>,
        geschlossen: List<EintragMitKategorie>
    ): List<Zeile> {
        val alle = geoeffnet + geschlossen
        val ergebnis = mutableListOf<Zeile>()
        val kategorien = daten.optJSONArray("kategorien") ?: JSONArray()

        // Ohne Kategorien: schlichte Liste (offen oben, geschlossen unten)
        if (kategorien.length() == 0) {
            return alle.map { it.zeile }
        }

        for (i in 0 until kategorien.length()) {
            val kategorie = kategorien.getJSONObject(i)
            val id = kategorie.getString("id")
            val gruppe = alle.filter { it.kategorieId == id }
            if (gruppe.isEmpty()) continue
            ergebnis.add(
                Zeile.Kopf(kategorie.optString("name", ""), gruppe.size)
            )
            ergebnis.addAll(gruppe.map { it.zeile })
        }
        val sonstige = alle.filter { it.kategorieId == null }
        if (sonstige.isNotEmpty()) {
            ergebnis.add(
                Zeile.Kopf(
                    daten.optString(
                        "sonstigeText",
                        context.getString(R.string.widget_sonstige)
                    ),
                    sonstige.size
                )
            )
            ergebnis.addAll(sonstige.map { it.zeile })
        }
        return ergebnis
    }

    override fun getViewAt(position: Int): RemoteViews {
        return when (val zeile = zeilen[position]) {
            is Zeile.Kopf -> RemoteViews(
                context.packageName, R.layout.when_open_widget_header_row
            ).apply {
                setTextViewText(R.id.header_name, zeile.name)
                setTextViewText(R.id.header_anzahl, zeile.anzahl.toString())
            }

            is Zeile.Ort -> RemoteViews(
                context.packageName, R.layout.when_open_widget_row
            ).apply {
                setTextViewText(R.id.row_name, zeile.name)
                setTextViewText(R.id.row_status, zeile.statusText)
                setImageViewResource(
                    R.id.row_dot,
                    if (zeile.offen) R.drawable.widget_dot_open
                    else R.drawable.widget_dot_closed
                )
                setTextColor(
                    R.id.row_status,
                    context.getColor(
                        if (zeile.offen) R.color.widget_open
                        else R.color.widget_muted
                    )
                )
                setTextColor(
                    R.id.row_name,
                    context.getColor(
                        if (zeile.offen) R.color.widget_ink
                        else R.color.widget_muted
                    )
                )
                // Fill-In fuer das PendingIntent-Template des Providers
                setOnClickFillInIntent(
                    R.id.widget_row,
                    Intent().setData(
                        Uri.parse("whenopen://app/open/${zeile.id}")
                    )
                )
            }
        }
    }

    override fun getCount() = zeilen.size
    override fun getViewTypeCount() = 2
    override fun getItemId(position: Int) = position.toLong()
    override fun hasStableIds() = false
    override fun getLoadingView(): RemoteViews? = null
    override fun onDestroy() {}
}
