package com.whenopen.when_open

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import java.time.LocalDateTime
import java.time.ZoneId

/**
 * E16 nativ: ein Alarm auf die naechste Oeffnungs-/Schliessgrenze, danach
 * neu zeichnen und neu planen. RTC (nicht WAKEUP): bei ausgeschaltetem
 * Display wird nichts geweckt — der faellige Alarm kommt beim Einschalten
 * sofort, also genau dann, wenn jemand aufs Widget schaut.
 */
object WidgetTakt {
    const val AKTION_TAKT = "com.whenopen.when_open.WIDGET_TAKT"
    const val AKTION_AKTUALISIEREN = "com.whenopen.when_open.WIDGET_AKTUALISIEREN"

    /** Alle Widget-Instanzen neu zeichnen und den naechsten Takt planen. */
    fun allesAktualisieren(context: Context, bestaetigt: Boolean = false) {
        val manager = AppWidgetManager.getInstance(context)
        val ids = manager.getAppWidgetIds(
            ComponentName(context, WhenOpenWidgetProvider::class.java)
        )
        for (id in ids) {
            WhenOpenWidgetProvider.aktualisiere(context, manager, id, bestaetigt)
        }
        if (ids.isEmpty()) abbrechen(context) else planen(context)
    }

    fun planen(context: Context) {
        val orte = WidgetDaten.laden(context).orte
        // 5 s hinter die Grenze, damit sicher auf der neuen Seite gerechnet wird
        val ziel = OeffnungsLogik.naechsteAenderung(orte, LocalDateTime.now())
            .plusSeconds(5)
            .atZone(ZoneId.systemDefault()).toInstant().toEpochMilli()
        val alarm = context.getSystemService(AlarmManager::class.java)
        val intent = taktIntent(context)
        try {
            if (exaktErlaubt(context)) {
                alarm.setExact(AlarmManager.RTC, ziel, intent)
            } else {
                // Ohne Exakt-Recht: Android dehnt das Fenster auf >= 10 min
                alarm.setWindow(AlarmManager.RTC, ziel, 60_000L, intent)
            }
        } catch (e: SecurityException) {
            Log.w("WidgetTakt", "Exakter Alarm abgelehnt, nutze Fenster", e)
            alarm.setWindow(AlarmManager.RTC, ziel, 60_000L, intent)
        }
    }

    /** Darf der Takt minutengenau laufen? (Android 12+: entziehbares Recht) */
    fun exaktErlaubt(context: Context): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.S ||
            context.getSystemService(AlarmManager::class.java).canScheduleExactAlarms()

    fun abbrechen(context: Context) {
        context.getSystemService(AlarmManager::class.java).cancel(taktIntent(context))
    }

    /** Expliziter Broadcast an den Provider (kein Flutter beteiligt). */
    fun broadcast(context: Context, aktion: String, requestCode: Int): PendingIntent =
        PendingIntent.getBroadcast(
            context,
            requestCode,
            Intent(context, WhenOpenWidgetProvider::class.java).setAction(aktion),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

    private fun taktIntent(context: Context) = broadcast(context, AKTION_TAKT, 0)
}
