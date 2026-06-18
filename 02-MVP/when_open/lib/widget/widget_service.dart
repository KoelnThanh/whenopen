import 'dart:convert';
import 'dart:developer' as developer;
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
    // Kurzform, damit "Stand HH:mm · <Datum>" einzeilig in die Kopfzeile passt.
    final datum = DateFormat('EEE d.M.', 'de').format(jetzt);
    final aktualisiert = DateFormat('HH:mm', 'de').format(jetzt);

    final json = jsonEncode({
      'datum': datum,
      // Uhrzeit der letzten Neuberechnung — der Nutzer sieht so die Frische.
      'aktualisiert': aktualisiert,
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
    // 5 s Puffer hinter die Grenze, damit die Neuberechnung sicher auf der
    // neuen Seite der Stufenfunktion liegt.
    final weckzeit = naechste.add(const Duration(seconds: 5));

    // Ab Android 12+ ist SCHEDULE_EXACT_ALARM ein entziehbares Recht; ist es
    // entzogen, scheitert der exakte Alarm (SecurityException / false). Dann
    // NICHT die Reschedule-Kette abreissen lassen, sondern auf einen ungenauen
    // Alarm zurueckfallen — Minutengenauigkeit ist fuer ein Oeffnungszeiten-
    // Widget entbehrlich, und das WorkManager-Netz (E16) faengt den Rest ab.
    if (await _planeAlarm(weckzeit, exact: true)) return;
    await _planeAlarm(weckzeit, exact: false);
  }

  /// Plant den (self-rescheduling) Widget-Alarm auf [weckzeit]. Liefert false,
  /// wenn das Planen fehlschlug (z. B. entzogenes Exact-Alarm-Recht) — der
  /// Aufrufer faellt dann auf einen ungenauen Alarm zurueck.
  static Future<bool> _planeAlarm(DateTime weckzeit,
      {required bool exact}) async {
    try {
      return await AndroidAlarmManager.oneShotAt(
        weckzeit,
        _alarmId,
        widgetAlarmCallback,
        exact: exact,
        wakeup: true,
        allowWhileIdle: true,
        rescheduleOnReboot: true,
      );
    } catch (e, st) {
      developer.log(
        'Widget-Alarm (exact: $exact) konnte nicht geplant werden',
        name: 'WidgetService',
        error: e,
        stackTrace: st,
      );
      return false;
    }
  }
}

/// Einstiegspunkt fuer den AlarmManager (separates Hintergrund-Isolate).
@pragma('vm:entry-point')
Future<void> widgetAlarmCallback() async {
  await WidgetService.aktualisiereWidget();
}

/// Einstiegspunkt fuer den Aktualisieren-Knopf im Widget (home_widget-
/// Interaktivitaet, separates Hintergrund-Isolate). [uri] ist der vom Knopf
/// mitgegebene Deep Link (whenopen://widget/refresh) — derzeit gibt es nur
/// eine Aktion, daher ohne Verzweigung. aktualisiereWidget() rechnet neu,
/// pusht und plant den E16-Alarm neu (repariert eine abgerissene Kette).
@pragma('vm:entry-point')
Future<void> widgetInteraktionCallback(Uri? uri) async {
  await WidgetService.aktualisiereWidget();
}
