package com.whenopen.when_open

import android.content.Context
import android.util.Log
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.time.DayOfWeek

/**
 * Liest die App-Datendatei direkt — dieselbe Datei, die Flutter schreibt
 * (path_provider: getApplicationDocumentsDirectory = app_flutter/).
 * Flutter schreibt atomar (tmp + rename), ein halbes File sehen wir also nie.
 */
object WidgetDaten {
    private const val DATEINAME = "whenopen_data.json"

    fun laden(context: Context): Bestand {
        val datei = File(context.getDir("flutter", Context.MODE_PRIVATE), DATEINAME)
        if (!datei.exists()) return Bestand.LEER
        return try {
            parse(JSONObject(datei.readText()))
        } catch (e: Exception) {
            Log.w("WidgetDaten", "Datendatei nicht lesbar", e)
            Bestand.LEER
        }
    }

    private fun parse(json: JSONObject): Bestand {
        val kategorien = objekte(json.optJSONArray("kategorien")).map {
            Kategorie(
                id = it.getString("id"),
                name = it.optString("name"),
                sortierung = it.optInt("sortierung")
            )
        }.sortedBy { it.sortierung }
        val orte = objekte(json.optJSONArray("eintraege")).mapNotNull { e ->
            try {
                Ort(
                    id = e.getString("id"),
                    name = e.getString("name"),
                    kategorieId = if (e.isNull("kategorie")) null
                    else e.getString("kategorie"),
                    tage = tage(e.optJSONArray("oeffnungszeiten"))
                )
            } catch (_: Exception) {
                null // kaputter Einzeleintrag soll nicht das ganze Widget leeren
            }
        }
        return Bestand(kategorien, orte)
    }

    private fun tage(array: JSONArray?): Map<DayOfWeek, List<Block>> {
        val ergebnis = mutableMapOf<DayOfWeek, List<Block>>()
        for (tag in objekte(array)) {
            val wochentag = OeffnungsLogik.wochentag(tag.optString("wochentag")) ?: continue
            ergebnis[wochentag] = objekte(tag.optJSONArray("zeiten")).mapNotNull {
                val von = OeffnungsLogik.parseZeit(it.optString("von"))
                val bis = OeffnungsLogik.parseZeit(it.optString("bis"))
                if (von != null && bis != null) Block(von, bis) else null
            }
        }
        return ergebnis
    }

    private fun objekte(array: JSONArray?): List<JSONObject> =
        if (array == null) emptyList()
        else (0 until array.length()).mapNotNull { array.optJSONObject(it) }

    fun statusTexte(context: Context) = StatusTexte(
        bis = context.getString(R.string.status_bis),
        ab = context.getString(R.string.status_ab),
        morgenAb = context.getString(R.string.status_morgen_ab),
        tagAb = context.getString(R.string.status_tag_ab),
        keineZeiten = context.getString(R.string.status_keine_zeiten),
        tageKurz = context.resources.getStringArray(R.array.tage_kurz).toList()
    )
}
