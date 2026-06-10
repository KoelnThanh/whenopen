import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../models/location.dart';
import '../repositories/location_repository.dart';
import '../services/open_status_service.dart';

/// Schreibt die aufbereiteten Widget-Daten und plant die naechste
/// Aktualisierung (E16): grenzgenauer Alarm auf die naechste Block-Grenze,
/// kein Polling. Laeuft auch im Hintergrund-Isolate (Alarm/WorkManager) —
/// deshalb ohne Riverpod, direkt auf Repository-Ebene.
abstract final class WidgetService {
  /// Alarm-ID fuer den grenzgenauen E16-Alarm (self-rescheduling).
  static const _alarmId = 2026;

  static const _androidWidgetProvider = 'WhenOpenWidgetProvider';

  /// Daten lesen, Status berechnen, an das Widget pushen, Alarm neu planen.
  static Future<void> aktualisiereWidget() async {
    final repo = await LocationRepository.imAppVerzeichnis();
    final daten = await repo.laden();
    await pushWidgetDaten(daten);
    await planeNaechstenAlarm(daten.eintraege);
  }

  /// Aufbereitete Daten in den geteilten Speicher schreiben + Redraw.
  /// Wird nach jeder Datenaenderung aufgerufen (Hook in AppDataNotifier)
  /// und beim Wechsel der App in den Hintergrund.
  static Future<void> pushWidgetDaten(WhenOpenData daten) async {
    final l10n = lookupAppLocalizations(const Locale('de'));
    final jetzt = DateTime.now();
    final widgetData =
        OpenStatusService.buildWidgetData(daten.eintraege, jetzt, l10n);

    await initializeDateFormatting('de');
    final datum = DateFormat('EEE · d. MMMM', 'de').format(jetzt);

    final json = jsonEncode({
      'datum': datum,
      'leerText': l10n.widgetLeer,
      'alleOrteText': l10n.alleOrte,
      'sonstigeText': l10n.sonstige,
      'kategorien': [
        for (final k in [...daten.kategorien]
          ..sort((a, b) => a.sortierung.compareTo(b.sortierung)))
          {'id': k.id, 'name': k.name, 'farbe': k.farbe},
      ],
      'geoeffnet': widgetData.geoeffnet.map((e) => e.toJson()).toList(),
      'geschlossen': widgetData.geschlossen.map((e) => e.toJson()).toList(),
    });

    await HomeWidget.saveWidgetData<String>('widget_daten', json);
    await HomeWidget.updateWidget(androidName: _androidWidgetProvider);
  }

  /// E16: Alarm exakt auf die naechste Statusgrenze (bzw. Mitternacht).
  /// Der Callback rechnet neu und plant sich selbst wieder ein.
  static Future<void> planeNaechstenAlarm(List<Location> locations) async {
    if (!Platform.isAndroid) return;
    final naechste =
        OpenStatusService.naechsteAenderung(locations, DateTime.now());
    await AndroidAlarmManager.oneShotAt(
      // 5 s Puffer hinter die Grenze, damit die Neuberechnung sicher
      // auf der neuen Seite der Stufenfunktion liegt.
      naechste.add(const Duration(seconds: 5)),
      _alarmId,
      widgetAlarmCallback,
      exact: true,
      wakeup: true,
      allowWhileIdle: true,
      rescheduleOnReboot: true,
    );
  }
}

/// Einstiegspunkt fuer den AlarmManager (separates Hintergrund-Isolate).
@pragma('vm:entry-point')
Future<void> widgetAlarmCallback() async {
  await WidgetService.aktualisiereWidget();
}
