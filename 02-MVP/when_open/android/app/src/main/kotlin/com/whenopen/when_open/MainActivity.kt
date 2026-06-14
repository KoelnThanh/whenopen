package com.whenopen.when_open

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.IOException

/**
 * Reicht den Sicherungs-Kanal an [BackupStorage] durch (Schreiben/Lesen im
 * sichtbaren Ordner `Download/WhenOpen`) und bietet eine **native Dateiauswahl**
 * (`ACTION_OPEN_DOCUMENT`) zum Importieren beliebiger — auch empfangener —
 * Sicherungsdateien. Bewusst ohne `file_picker`-Paket: dessen Kotlin-Modul ist
 * mit Flutters „Built-in Kotlin" inkompatibel.
 */
class MainActivity : FlutterActivity() {
    private val kanal = "com.whenopen/backup"
    private val anfrageDateiwahl = 0x6202
    private var offeneAuswahl: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, kanal)
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "sichern" -> {
                            val inhalt = call.argument<String>("inhalt") ?: ""
                            result.success(
                                BackupStorage.sichern(applicationContext, this, inhalt),
                            )
                        }
                        "letzteSicherung" -> {
                            result.success(
                                BackupStorage.letzteSicherung(applicationContext, this),
                            )
                        }
                        "dateiWaehlen" -> starteDateiauswahl(result)
                        else -> result.notImplemented()
                    }
                } catch (e: SecurityException) {
                    result.error("KEINE_BERECHTIGUNG", e.message, null)
                } catch (e: Exception) {
                    result.error("FEHLER", e.message, null)
                }
            }
    }

    /** System-Dateibrowser oeffnen; das Ergebnis kommt in [onActivityResult]. */
    private fun starteDateiauswahl(result: MethodChannel.Result) {
        if (offeneAuswahl != null) {
            result.error("BESCHAEFTIGT", "Es laeuft bereits eine Auswahl", null)
            return
        }
        offeneAuswahl = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "*/*"
            putExtra(
                Intent.EXTRA_MIME_TYPES,
                arrayOf("application/json", "text/plain", "application/octet-stream"),
            )
        }
        startActivityForResult(intent, anfrageDateiwahl)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != anfrageDateiwahl) return
        val result = offeneAuswahl ?: return
        offeneAuswahl = null

        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            result.success(null) // Auswahl abgebrochen
            return
        }
        try {
            val inhalt = contentResolver.openInputStream(uri)?.use {
                // Gedeckeltes Lesen: eine beliebige (auch fremd empfangene)
                // Datei darf nicht unbegrenzt in den Speicher gelesen werden.
                BackupStorage.liesBegrenzt(it).toString(Charsets.UTF_8)
            } ?: throw IOException("Datei nicht lesbar")
            result.success(mapOf("name" to dateiName(uri), "inhalt" to inhalt))
        } catch (e: Exception) {
            result.error("LESEFEHLER", e.message, null)
        }
    }

    /** Anzeigename der gewaehlten content://-URI (fuer die Import-Vorschau). */
    private fun dateiName(uri: Uri): String {
        contentResolver.query(
            uri,
            arrayOf(OpenableColumns.DISPLAY_NAME),
            null,
            null,
            null,
        )?.use { c ->
            val idx = c.getColumnIndex(OpenableColumns.DISPLAY_NAME)
            if (idx >= 0 && c.moveToFirst()) return c.getString(idx)
        }
        return uri.lastPathSegment ?: "sicherung.json"
    }
}
