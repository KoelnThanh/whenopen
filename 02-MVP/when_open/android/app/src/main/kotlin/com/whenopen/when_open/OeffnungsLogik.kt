package com.whenopen.when_open

import java.time.DayOfWeek
import java.time.LocalDateTime

/** Ein Oeffnungsblock in Minuten seit Mitternacht (offen: von <= t < bis). */
data class Block(val von: Int, val bis: Int)

data class Ort(
    val id: String,
    val name: String,
    val kategorieId: String?,
    val tage: Map<DayOfWeek, List<Block>>
)

data class Kategorie(val id: String, val name: String, val sortierung: Int)

data class Bestand(val kategorien: List<Kategorie>, val orte: List<Ort>) {
    companion object {
        val LEER = Bestand(emptyList(), emptyList())
    }
}

data class Status(val offen: Boolean, val text: String)

/** Textbausteine der Statuszeile (aus strings.xml, in Tests direkt gesetzt). */
data class StatusTexte(
    val bis: String = "bis %s",
    val ab: String = "ab %s",
    val morgenAb: String = "morgen ab %s",
    val tagAb: String = "ab %1\$s %2\$s",
    val keineZeiten: String = "Keine Öffnungszeiten",
    val tageKurz: List<String> = listOf("Mo", "Di", "Mi", "Do", "Fr", "Sa", "So")
)

/**
 * Kotlin-Spiegel von `OpenStatusService` (Dart, E9/E16) — das Widget rechnet
 * damit selbst, statt vorberechnete Texte aus einem Flutter-Hintergrundprozess
 * zu brauchen. Zustandslos, die Zeit kommt als Parameter (testbar).
 * Aenderungen an der Blocklogik immer auf BEIDEN Seiten nachziehen.
 */
object OeffnungsLogik {

    fun status(ort: Ort, jetzt: LocalDateTime, texte: StatusTexte): Status {
        val heute = jetzt.dayOfWeek
        val minute = jetzt.hour * 60 + jetzt.minute
        val bloecke = ort.tage[heute].orEmpty()

        bloecke.firstOrNull { minute >= it.von && minute < it.bis }?.let {
            return Status(true, texte.bis.format(hhmm(it.bis)))
        }
        // Pause: heute kommt noch ein spaeterer Block
        bloecke.filter { it.von > minute }.minByOrNull { it.von }?.let {
            return Status(false, texte.ab.format(hhmm(it.von)))
        }
        for (i in 1..7) {
            val tag = heute.plus(i.toLong())
            val erster = ort.tage[tag].orEmpty().minByOrNull { it.von } ?: continue
            val zeit = hhmm(erster.von)
            val text = if (i == 1) texte.morgenAb.format(zeit)
            else texte.tagAb.format(texte.tageKurz[tag.value - 1], zeit)
            return Status(false, text)
        }
        return Status(false, texte.keineZeiten)
    }

    /**
     * E16: naechste echt zukuenftige Block-Grenze (von/bis) heute ueber alle
     * Orte, sonst die naechste Mitternacht (Wochentagswechsel).
     */
    fun naechsteAenderung(orte: List<Ort>, jetzt: LocalDateTime): LocalDateTime {
        val minute = jetzt.hour * 60 + jetzt.minute
        val naechste = orte
            .flatMap { it.tage[jetzt.dayOfWeek].orEmpty() }
            .flatMap { listOf(it.von, it.bis) }
            .filter { it > minute }
            .minOrNull()
        val heute = jetzt.toLocalDate()
        return if (naechste != null) heute.atTime(naechste / 60, naechste % 60)
        else heute.plusDays(1).atStartOfDay()
    }

    fun hhmm(minuten: Int) = "%02d:%02d".format(minuten / 60, minuten % 60)

    /** "HH:MM" → Minuten; null bei ungueltigem Wert (Eintrag wird uebergangen). */
    fun parseZeit(hhmm: String): Int? {
        val teile = hhmm.split(':')
        if (teile.size != 2) return null
        val h = teile[0].toIntOrNull() ?: return null
        val m = teile[1].toIntOrNull() ?: return null
        if (h !in 0..23 || m !in 0..59) return null
        return h * 60 + m
    }

    private val KUERZEL = mapOf(
        "mo" to DayOfWeek.MONDAY, "di" to DayOfWeek.TUESDAY,
        "mi" to DayOfWeek.WEDNESDAY, "do" to DayOfWeek.THURSDAY,
        "fr" to DayOfWeek.FRIDAY, "sa" to DayOfWeek.SATURDAY,
        "so" to DayOfWeek.SUNDAY
    )

    fun wochentag(kuerzel: String): DayOfWeek? = KUERZEL[kuerzel]
}
