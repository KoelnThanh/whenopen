package com.whenopen.when_open

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import java.time.LocalDateTime

/** Liefert die Listenzeilen des Widgets, Status live berechnet. */
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
     * Workflow 2: je Gruppe offen oben, geschlossen unten, jeweils
     * alphabetisch. Bei "Alle Orte" nach Kategorie gruppiert (E10), bei
     * festem Filter flache Liste (E14). Der Status wird hier zum aktuellen
     * Zeitpunkt berechnet — jedes Neuzeichnen ist damit automatisch richtig.
     */
    private fun ladeDaten() {
        val bestand = WidgetDaten.laden(context)
        val texte = WidgetDaten.statusTexte(context)
        val jetzt = LocalDateTime.now()
        val bekannteKategorien = bestand.kategorien.map { it.id }.toSet()

        // Unbekannte Kategorie-IDs (z. B. geloeschte Kategorie) zaehlen als Sonstige
        val bewertet = bestand.orte.map { ort ->
            val status = OeffnungsLogik.status(ort, jetzt, texte)
            Bewertet(
                kategorieId = ort.kategorieId?.takeIf { it in bekannteKategorien },
                zeile = Zeile.Ort(ort.id, ort.name, status.text, status.offen)
            )
        }.sortedWith(
            compareByDescending<Bewertet> { it.zeile.offen }
                .thenBy { it.zeile.name.lowercase() }
        )

        val filter = WhenOpenWidgetProvider.gespeicherterFilter(context, appWidgetId)
        zeilen = when (filter) {
            WhenOpenWidgetProvider.FILTER_ALLE -> gruppiert(bestand.kategorien, bewertet)
            WhenOpenWidgetProvider.FILTER_SONSTIGE ->
                bewertet.filter { it.kategorieId == null }.map { it.zeile }
            else -> bewertet.filter { it.kategorieId == filter }.map { it.zeile }
        }
    }

    private data class Bewertet(val kategorieId: String?, val zeile: Zeile.Ort)

    private fun gruppiert(kategorien: List<Kategorie>, alle: List<Bewertet>): List<Zeile> {
        // Ohne Kategorien: schlichte Liste (offen oben, geschlossen unten)
        if (kategorien.isEmpty()) return alle.map { it.zeile }

        val ergebnis = mutableListOf<Zeile>()
        fun gruppe(name: String, eintraege: List<Bewertet>) {
            if (eintraege.isEmpty()) return
            ergebnis.add(Zeile.Kopf(name, eintraege.size))
            ergebnis.addAll(eintraege.map { it.zeile })
        }
        for (kategorie in kategorien) {
            gruppe(kategorie.name, alle.filter { it.kategorieId == kategorie.id })
        }
        gruppe(
            context.getString(R.string.widget_sonstige),
            alle.filter { it.kategorieId == null }
        )
        return ergebnis
    }

    override fun getViewAt(position: Int): RemoteViews {
        // Liste kann sich zwischen getCount und getViewAt aendern
        val zeile = zeilen.getOrNull(position)
            ?: return RemoteViews(context.packageName, R.layout.when_open_widget_row)
        return when (zeile) {
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
