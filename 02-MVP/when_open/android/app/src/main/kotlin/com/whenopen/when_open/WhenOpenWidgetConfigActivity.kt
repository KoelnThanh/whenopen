package com.whenopen.when_open

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Intent
import android.graphics.Color
import android.os.Bundle
import android.view.Gravity
import android.widget.Button
import android.widget.LinearLayout
import android.widget.RadioButton
import android.widget.RadioGroup
import android.widget.ScrollView
import android.widget.TextView

/**
 * Widget-Konfiguration (E14): beim Platzieren eine Kategorie waehlen.
 * Existieren keine Kategorien, wird ohne Rueckfrage "Alle Orte" gesetzt.
 * Mehrere Widget-Instanzen koennen verschiedene Filter haben.
 */
class WhenOpenWidgetConfigActivity : Activity() {

    private var appWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID

    /** Eine waehlbare Option: Filterwert + Anzeigename. */
    private data class Option(val filter: String, val name: String)

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setResult(RESULT_CANCELED)

        appWidgetId = intent?.extras?.getInt(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID
        ) ?: AppWidgetManager.INVALID_APPWIDGET_ID
        if (appWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            finish()
            return
        }

        val optionen = ladeOptionen()

        // E14: ohne Kategorien keine Frage — direkt "Alle Orte".
        if (optionen.size <= 1) {
            speichereUndSchliesse(WhenOpenWidgetProvider.FILTER_ALLE)
            return
        }

        baueUi(optionen)
    }

    private fun ladeOptionen(): List<Option> {
        val optionen = mutableListOf(
            Option(
                WhenOpenWidgetProvider.FILTER_ALLE,
                getString(R.string.widget_alle_orte)
            )
        )
        val kategorien = WidgetDaten.laden(this).kategorien
        kategorien.forEach { optionen.add(Option(it.id, it.name)) }
        if (kategorien.isNotEmpty()) {
            optionen.add(
                Option(
                    WhenOpenWidgetProvider.FILTER_SONSTIGE,
                    getString(R.string.widget_sonstige)
                )
            )
        }
        return optionen
    }

    private fun baueUi(optionen: List<Option>) {
        val dichte = resources.displayMetrics.density
        fun dp(wert: Int) = (wert * dichte).toInt()

        val aktuellerFilter =
            WhenOpenWidgetProvider.gespeicherterFilter(this, appWidgetId)

        val radioGroup = RadioGroup(this)
        optionen.forEachIndexed { index, option ->
            radioGroup.addView(RadioButton(this).apply {
                id = index
                text = option.name
                textSize = 15f
                setTextColor(Color.parseColor("#E8EAED"))
                setPadding(dp(4), dp(10), dp(4), dp(10))
                isChecked = option.filter == aktuellerFilter
            })
        }
        if (radioGroup.checkedRadioButtonId == -1) radioGroup.check(0)

        val buttons = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.END
            addView(Button(this@WhenOpenWidgetConfigActivity).apply {
                text = getString(R.string.widget_abbrechen)
                setOnClickListener { finish() }
            })
            addView(Button(this@WhenOpenWidgetConfigActivity).apply {
                text = getString(R.string.widget_hinzufuegen)
                setOnClickListener {
                    speichereUndSchliesse(
                        optionen[radioGroup.checkedRadioButtonId].filter
                    )
                }
            })
        }

        val wurzel = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(Color.parseColor("#1E232C"))
            setPadding(dp(20), dp(18), dp(20), dp(10))
            addView(TextView(this@WhenOpenWidgetConfigActivity).apply {
                text = getString(R.string.widget_konfig_titel)
                textSize = 17f
                setTextColor(Color.parseColor("#E8EAED"))
            })
            addView(TextView(this@WhenOpenWidgetConfigActivity).apply {
                text = getString(R.string.widget_konfig_frage)
                textSize = 13f
                setTextColor(Color.parseColor("#9AA0AA"))
                setPadding(0, dp(2), 0, dp(8))
            })
            addView(radioGroup)
            addView(buttons)
        }

        setContentView(ScrollView(this).apply { addView(wurzel) })
    }

    private fun speichereUndSchliesse(filter: String) {
        WhenOpenWidgetProvider.filterPrefs(this).edit()
            .putString(WhenOpenWidgetProvider.filterKey(appWidgetId), filter)
            .apply()

        WhenOpenWidgetProvider.aktualisiere(
            this, AppWidgetManager.getInstance(this), appWidgetId
        )

        setResult(RESULT_OK, Intent().putExtra(
            AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId
        ))
        finish()
    }
}
