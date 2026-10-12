import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';

/// Stoesst ein Neuzeichnen des Home-Widgets an.
///
/// Status, Sortierung und der Takt bis zur naechsten Oeffnungs-/Schliesszeit
/// laufen nativ (WhenOpenWidgetProvider/WidgetTakt) direkt auf der
/// JSON-Datei. Dart muss dafuer weder Daten aufbereiten noch ein
/// Hintergrund-Isolate starten — es meldet nur "Daten haben sich geaendert".
abstract final class WidgetService {
  static const _androidWidgetProvider = 'WhenOpenWidgetProvider';
  static const _kanal = MethodChannel('com.whenopen/widget');

  static Future<void> aktualisiereWidget() async {
    if (!Platform.isAndroid) return;
    try {
      await HomeWidget.updateWidget(androidName: _androidWidgetProvider);
    } catch (e, st) {
      // Das Widget darf die App nie stoeren — nur protokollieren.
      developer.log(
        'Widget-Update fehlgeschlagen',
        name: 'WidgetService',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Darf das Widget minutengenau umspringen? Ohne das (ab Android 14 nicht
  /// vorerteilte) Exakt-Wecker-Recht verschiebt Android den Takt um bis zu
  /// 10 Minuten. Ausserhalb Android oder bei Fehlern: true (kein Hinweis).
  static Future<bool> exaktErlaubt() async {
    if (!Platform.isAndroid) return true;
    try {
      return await _kanal.invokeMethod<bool>('exaktErlaubt') ?? true;
    } on PlatformException {
      return true;
    }
  }

  /// Oeffnet die System-Einstellung "Wecker & Erinnerungen" fuer WhenOpen.
  static Future<void> exaktAnfragen() => _kanal.invokeMethod('exaktAnfragen');
}
