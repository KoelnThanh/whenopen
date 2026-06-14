import 'package:flutter/material.dart' show TimeOfDay;

import '../models/opening_day.dart';
import '../models/wochentag.dart';

/// Parser fuer das OSM-`opening_hours`-Format — bewusst nur die haeufigsten
/// Faelle (~80%). Alles andere liefert `null`, der Nutzer traegt dann
/// manuell ein (AP-P08b: kein Vollparser anstreben).
///
/// Unterstuetzt: "Mo-Fr 09:00-18:00", Regeln mit ";", Tageslisten "Mo,We",
/// "Su off", Zeiten ohne Tagesangabe (= alle Tage), Mehrfachbloecke
/// "09:00-12:00,14:00-18:00" (E9).
abstract final class OpeningHoursParser {
  /// Obergrenze fuer den Rohwert. Schuetzt vor katastrophalem
  /// Regex-Backtracking (ReDoS): Die `opening_hours`-Werte stammen aus OSM
  /// bzw. importierten Sicherungen (untrusted). Reale Werte sind kurz; alles
  /// jenseits dieser grosszuegigen Grenze gilt als nicht unterstuetzt.
  static const _maxLaenge = 256;

  static const _tage = {
    'mo': Wochentag.montag,
    'tu': Wochentag.dienstag,
    'we': Wochentag.mittwoch,
    'th': Wochentag.donnerstag,
    'fr': Wochentag.freitag,
    'sa': Wochentag.samstag,
    'su': Wochentag.sonntag,
  };

  static List<OpeningDay>? parse(String? rohwert) {
    if (rohwert == null) return null;
    final text = rohwert.trim().toLowerCase();
    if (text.isEmpty || text.length > _maxLaenge) return null;

    final woche = {for (final w in Wochentag.values) w: <TimeBlock>[]};

    for (final regelRoh in text.split(';')) {
      final regel = regelRoh.trim();
      if (regel.isEmpty) continue;
      if (!_parseRegel(regel, woche)) return null;
    }

    if (!woche.values.any((zeiten) => zeiten.isNotEmpty)) return null;

    return [
      for (final w in Wochentag.values)
        OpeningDay(wochentag: w, zeiten: woche[w]!),
    ];
  }

  /// Eine Regel, z.B. "mo-fr 09:00-12:00,14:00-18:00" oder "su off".
  /// false = Format nicht unterstuetzt → ganzer Parse schlaegt fehl.
  static bool _parseRegel(
      String regel, Map<Wochentag, List<TimeBlock>> woche) {
    // Tagesausdruck vorn abtrennen (optional).
    final match = RegExp(r'^([a-z,\- ]*?)\s*((?:\d{1,2}:\d{2}\s*-\s*\d{1,2}:\d{2}\s*,?\s*)+|off)$')
        .firstMatch(regel);
    if (match == null) return false;

    final tagesTeil = match.group(1)!.trim();
    final zeitTeil = match.group(2)!.trim();

    final tage = tagesTeil.isEmpty
        ? Wochentag.values.toList()
        : _parseTage(tagesTeil);
    if (tage == null) return false;

    if (zeitTeil == 'off') {
      for (final tag in tage) {
        woche[tag] = [];
      }
      return true;
    }

    final bloecke = _parseZeiten(zeitTeil);
    if (bloecke == null) return false;

    for (final tag in tage) {
      woche[tag] = [...bloecke];
    }
    return true;
  }

  /// "mo-fr", "sa", "mo,we", "mo-we,fr" → Liste von Wochentagen.
  static List<Wochentag>? _parseTage(String text) {
    final ergebnis = <Wochentag>[];
    for (final teil in text.split(',')) {
      final t = teil.trim();
      if (t.isEmpty) return null;
      if (t.contains('-')) {
        final grenzen = t.split('-');
        if (grenzen.length != 2) return null;
        final von = _tage[grenzen[0].trim()];
        final bis = _tage[grenzen[1].trim()];
        if (von == null || bis == null) return null;
        // Bereich zyklisch (z.B. "sa-mo" waere exotisch, aber korrekt).
        var aktuell = von;
        while (true) {
          ergebnis.add(aktuell);
          if (aktuell == bis) break;
          aktuell = aktuell.plus(1);
        }
      } else {
        final tag = _tage[t];
        if (tag == null) return null;
        ergebnis.add(tag);
      }
    }
    return ergebnis;
  }

  /// "09:00-12:00,14:00-18:00" → Zeitbloecke.
  static List<TimeBlock>? _parseZeiten(String text) {
    final bloecke = <TimeBlock>[];
    for (final teil in text.split(',')) {
      final t = teil.trim();
      if (t.isEmpty) continue;
      final match =
          RegExp(r'^(\d{1,2}):(\d{2})\s*-\s*(\d{1,2}):(\d{2})$').firstMatch(t);
      if (match == null) return null;
      final vonH = int.parse(match.group(1)!);
      final vonM = int.parse(match.group(2)!);
      var bisH = int.parse(match.group(3)!);
      var bisM = int.parse(match.group(4)!);
      // "24:00" als Tagesende auf 23:59 abbilden; Ueber-Nacht nicht stuetzen.
      if (bisH == 24 && bisM == 0) {
        bisH = 23;
        bisM = 59;
      }
      if (vonH > 23 || vonM > 59 || bisH > 23 || bisM > 59) {
        return null;
      }
      final von = TimeOfDay(hour: vonH, minute: vonM);
      final bis = TimeOfDay(hour: bisH, minute: bisM);
      if (von.inMinuten >= bis.inMinuten) return null;
      bloecke.add(TimeBlock(von: von, bis: bis));
    }
    return bloecke.isEmpty ? null : bloecke;
  }
}
