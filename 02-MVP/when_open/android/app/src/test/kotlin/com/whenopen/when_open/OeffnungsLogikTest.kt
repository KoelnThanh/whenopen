package com.whenopen.when_open

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.DayOfWeek
import java.time.DayOfWeek.MONDAY
import java.time.DayOfWeek.WEDNESDAY
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.temporal.TemporalAdjusters

/** Spiegelt die Faelle aus test/services/open_status_service_test.dart. */
class OeffnungsLogikTest {
    private val texte = StatusTexte()

    private fun b(vonH: Int, vonM: Int, bisH: Int, bisM: Int) =
        Block(vonH * 60 + vonM, bisH * 60 + bisM)

    private fun ort(name: String, tage: Map<DayOfWeek, List<Block>>) =
        Ort(id = name, name = name, kategorieId = null, tage = tage)

    /** Ein fester Mittwoch / Montag als Bezug. */
    private fun am(tag: DayOfWeek, h: Int, m: Int): LocalDateTime =
        LocalDate.of(2026, 10, 12).with(TemporalAdjusters.nextOrSame(tag)).atTime(h, m)

    private val werktags = ort("Werktags",
        (1..5).associate { DayOfWeek.of(it) to listOf(b(9, 0, 18, 0)) })
    private val mehrblock = ort("Mehrblock",
        mapOf(WEDNESDAY to listOf(b(8, 0, 11, 0), b(14, 0, 18, 0))))
    private val nurMontag = ort("Montag", mapOf(MONDAY to listOf(b(8, 0, 12, 0))))
    private val nie = ort("Nie", emptyMap())

    private fun text(o: Ort, t: LocalDateTime) = OeffnungsLogik.status(o, t, texte).text

    @Test
    fun statusTextVarianten() {
        assertEquals("bis 18:00", text(werktags, am(WEDNESDAY, 10, 0)))
        assertEquals("ab 14:00", text(mehrblock, am(WEDNESDAY, 12, 0)))
        assertEquals("morgen ab 09:00", text(werktags, am(WEDNESDAY, 19, 0)))
        assertEquals("ab Mo 08:00", text(nurMontag, am(WEDNESDAY, 10, 0)))
        assertEquals("Keine Öffnungszeiten", text(nie, am(WEDNESDAY, 10, 0)))
    }

    @Test
    fun grenzenSindHalboffen() {
        // von gehoert dazu, bis nicht (von <= t < bis)
        assertTrue(OeffnungsLogik.status(werktags, am(WEDNESDAY, 9, 0), texte).offen)
        assertFalse(OeffnungsLogik.status(werktags, am(WEDNESDAY, 18, 0), texte).offen)
        assertFalse(OeffnungsLogik.status(werktags, am(WEDNESDAY, 8, 59), texte).offen)
    }

    @Test
    fun gleicherWochentagNaechsteWoche() {
        // Montag nach Schluss: naechste Oeffnung erst wieder Montag in 7 Tagen
        assertEquals("ab Mo 08:00", text(nurMontag, am(MONDAY, 13, 0)))
    }

    @Test
    fun naechsteAenderungIstKleinsteGrenzeHeute() {
        val t = am(WEDNESDAY, 10, 30)
        assertEquals(t.toLocalDate().atTime(11, 0),
            OeffnungsLogik.naechsteAenderung(listOf(werktags, mehrblock), t))
    }

    @Test
    fun naechsteAenderungSonstMitternacht() {
        val t = am(WEDNESDAY, 19, 0)
        assertEquals(t.toLocalDate().plusDays(1).atStartOfDay(),
            OeffnungsLogik.naechsteAenderung(listOf(werktags, mehrblock), t))
    }

    @Test
    fun parseZeit() {
        assertEquals(14 * 60 + 30, OeffnungsLogik.parseZeit("14:30"))
        assertEquals(null, OeffnungsLogik.parseZeit("24:00"))
        assertEquals(null, OeffnungsLogik.parseZeit("kaputt"))
    }
}
