package com.whenopen.when_open

import android.Manifest
import android.app.Activity
import android.content.ContentUris
import android.content.ContentValues
import android.content.Context
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import java.io.File
import java.io.IOException

/**
 * Schreibt/liest die WhenOpen-Sicherung in einen im Dateimanager sichtbaren
 * Ordner: `Download/WhenOpen`. Ab Android 10 (API 29) ueber MediaStore (ohne
 * Berechtigung), darunter ueber direkten Dateizugriff mit der
 * WRITE_EXTERNAL_STORAGE-Berechtigung (nur <= API 28 angefordert).
 *
 * Bewusst "ueberschreiben" statt versionieren: es gibt immer genau eine
 * aktuelle Sicherungsdatei [DATEINAME], damit das schnelle Wiederherstellen
 * einen festen, vorhersehbaren Ort hat.
 */
object BackupStorage {
    const val ORDNER = "WhenOpen"
    const val DATEINAME = "whenopen-sicherung.json"

    /** Anzeigbares Ordner-Label fuer die Bestaetigung in der UI. */
    const val LABEL = "Download/$ORDNER"

    const val REQUEST_CODE = 0x6201

    /** Sichert [inhalt]; ueberschreibt eine vorhandene Datei gleichen Namens. */
    fun sichern(context: Context, activity: Activity?, inhalt: String): String {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            sichernMediaStore(context, inhalt)
        } else {
            sichernLegacy(context, activity, inhalt)
        }
        return LABEL
    }

    /** Inhalt der neuesten `*.json` im Ordner, oder null wenn keine vorhanden. */
    fun letzteSicherung(context: Context, activity: Activity?): String? {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            letzteMediaStore(context)
        } else {
            letzteLegacy(context, activity)
        }
    }

    // ── Android 10+ : MediaStore (keine Berechtigung noetig) ───────────

    private fun downloadsUri(): Uri =
        MediaStore.Downloads.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)

    private val relativerPfad get() = "${Environment.DIRECTORY_DOWNLOADS}/$ORDNER"

    private fun sichernMediaStore(context: Context, inhalt: String) {
        val resolver = context.contentResolver
        val vorhandene = findeEigene(context, DATEINAME)
        val uri: Uri = vorhandene ?: run {
            val werte = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, DATEINAME)
                put(MediaStore.MediaColumns.MIME_TYPE, "application/json")
                put(MediaStore.MediaColumns.RELATIVE_PATH, relativerPfad)
                put(MediaStore.MediaColumns.IS_PENDING, 1)
            }
            resolver.insert(downloadsUri(), werte)
                ?: throw IOException("MediaStore-Insert fehlgeschlagen")
        }
        // "wt" = write + truncate: ueberschreibt den bisherigen Inhalt vollstaendig.
        resolver.openOutputStream(uri, "wt")?.use {
            it.write(inhalt.toByteArray(Charsets.UTF_8))
        } ?: throw IOException("OutputStream nicht verfuegbar")
        if (vorhandene == null) {
            val fertig = ContentValues().apply {
                put(MediaStore.MediaColumns.IS_PENDING, 0)
            }
            resolver.update(uri, fertig, null, null)
        }
    }

    /** Sucht eine von dieser App selbst angelegte Datei gleichen Namens. */
    private fun findeEigene(context: Context, anzeigeName: String): Uri? {
        val sel = "${MediaStore.MediaColumns.RELATIVE_PATH}=? AND " +
            "${MediaStore.MediaColumns.DISPLAY_NAME}=?"
        val args = arrayOf("$relativerPfad/", anzeigeName)
        context.contentResolver.query(
            downloadsUri(),
            arrayOf(MediaStore.MediaColumns._ID),
            sel,
            args,
            null,
        )?.use { c ->
            if (c.moveToFirst()) {
                return ContentUris.withAppendedId(downloadsUri(), c.getLong(0))
            }
        }
        return null
    }

    private fun letzteMediaStore(context: Context): String? {
        val resolver = context.contentResolver
        val sel = "${MediaStore.MediaColumns.RELATIVE_PATH}=?"
        val args = arrayOf("$relativerPfad/")
        resolver.query(
            downloadsUri(),
            arrayOf(
                MediaStore.MediaColumns._ID,
                MediaStore.MediaColumns.DISPLAY_NAME,
            ),
            sel,
            args,
            "${MediaStore.MediaColumns.DATE_MODIFIED} DESC",
        )?.use { c ->
            val idSpalte = c.getColumnIndexOrThrow(MediaStore.MediaColumns._ID)
            val nameSpalte =
                c.getColumnIndexOrThrow(MediaStore.MediaColumns.DISPLAY_NAME)
            // Hinweis (Scoped Storage): MediaStore liefert hier nur Dateien,
            // die diese App selbst angelegt hat. Eine ueber WhatsApp empfangene
            // und manuell abgelegte Sicherung wird per Dateiwahl (SAF) geladen.
            while (c.moveToNext()) {
                if (!c.getString(nameSpalte).endsWith(".json", ignoreCase = true)) {
                    continue
                }
                val uri = ContentUris.withAppendedId(downloadsUri(), c.getLong(idSpalte))
                return resolver.openInputStream(uri)?.use { ein ->
                    ein.readBytes().toString(Charsets.UTF_8)
                }
            }
        }
        return null
    }

    // ── Android 8/9 : direkter Dateizugriff + Legacy-Berechtigung ──────

    @Suppress("DEPRECATION")
    private fun legacyOrdner(): File = File(
        Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS),
        ORDNER,
    )

    private fun hatLegacyRecht(context: Context): Boolean =
        ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.WRITE_EXTERNAL_STORAGE,
        ) == PackageManager.PERMISSION_GRANTED

    private fun fordereLegacyRecht(activity: Activity?) {
        if (activity == null) return
        ActivityCompat.requestPermissions(
            activity,
            arrayOf(
                Manifest.permission.WRITE_EXTERNAL_STORAGE,
                Manifest.permission.READ_EXTERNAL_STORAGE,
            ),
            REQUEST_CODE,
        )
    }

    private fun sichernLegacy(context: Context, activity: Activity?, inhalt: String) {
        if (!hatLegacyRecht(context)) {
            fordereLegacyRecht(activity)
            throw SecurityException("Speicher-Berechtigung erforderlich")
        }
        val ordner = legacyOrdner()
        if (!ordner.exists()) ordner.mkdirs()
        File(ordner, DATEINAME).writeText(inhalt, Charsets.UTF_8)
    }

    private fun letzteLegacy(context: Context, activity: Activity?): String? {
        if (!hatLegacyRecht(context)) {
            fordereLegacyRecht(activity)
            throw SecurityException("Speicher-Berechtigung erforderlich")
        }
        val neueste = legacyOrdner().listFiles { f ->
            f.isFile && f.name.endsWith(".json", ignoreCase = true)
        }?.maxByOrNull { it.lastModified() } ?: return null
        return neueste.readText(Charsets.UTF_8)
    }
}
