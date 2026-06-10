import 'package:flutter/material.dart' show TimeOfDay, Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:when_open/l10n/app_localizations.dart';
import 'package:when_open/models/location.dart';
import 'package:when_open/models/opening_day.dart';
import 'package:when_open/models/wochentag.dart';
import 'package:when_open/services/open_status_service.dart';

TimeBlock _block(int vonH, int vonM, int bisH, int bisM) => TimeBlock(
      von: TimeOfDay(hour: vonH, minute: vonM),
      bis: TimeOfDay(hour: bisH, minute: bisM),
    );

Location _ort({
  String id = 'loc-1',
  String name = 'Testort',
  required Map<Wochentag, List<TimeBlock>> woche,
}) {
  return Location(
    id: id,
    name: name,
    oeffnungszeiten: woche.entries
        .map((e) => OpeningDay(wochentag: e.key, zeiten: e.value))
        .toList(),
    erstelltAm: DateTime.utc(2026),
    geaendertAm: DateTime.utc(2026),
  );
}

/// Referenzwoche: 2026-06-08 (Mo) bis 2026-06-14 (So).
/// 2026-06-10 ist ein Mittwoch — wie im Mockup-Beispieltag.
DateTime _am(Wochentag tag, int stunde, int minute) {
  final montag = DateTime(2026, 6, 8);
  return DateTime(
      montag.year, montag.month, montag.day + tag.index, stunde, minute);
}

void main() {
  // Standard-Ort: Mo-Fr 09:00-18:00
  final werktagsOrt = _ort(woche: {
    for (final t in [
      Wochentag.montag,
      Wochentag.dienstag,
      Wochentag.mittwoch,
      Wochentag.donnerstag,
      Wochentag.freitag,
    ])
      t: [_block(9, 0, 18, 0)],
  });

  // Mehrblock-Ort (E9): Mittwoch 08:00-11:00, 14:00-16:00, 17:00-19:00
  final mehrblockOrt = _ort(woche: {
    Wochentag.mittwoch: [
      _block(8, 0, 11, 0),
      _block(14, 0, 16, 0),
      _block(17, 0, 19, 0),
    ],
  });

  // Nur Montag geoeffnet
  final nurMontag = _ort(woche: {
    Wochentag.montag: [_block(8, 0, 12, 0)],
  });

  // Nie geoeffnet
  final nieGeoeffnet = _ort(woche: {});

  group('isOpenNow (E9 Block-Logik)', () {
    test('Werktag, aktuell geoeffnet: offen mit korrekter Schliesszeit', () {
      final status = OpenStatusService.isOpenNow(
          werktagsOrt, _am(Wochentag.mittwoch, 9, 30));
      expect(status.offen, isTrue);
      expect(status.schliesstUm, const TimeOfDay(hour: 18, minute: 0));
    });

    test('exakt zur Oeffnungszeit gilt als geoeffnet (von <= t < bis)', () {
      final status = OpenStatusService.isOpenNow(
          werktagsOrt, _am(Wochentag.mittwoch, 9, 0));
      expect(status.offen, isTrue);
    });

    test('exakt zur Schliesszeit gilt als geschlossen', () {
      final status = OpenStatusService.isOpenNow(
          werktagsOrt, _am(Wochentag.mittwoch, 18, 0));
      expect(status.offen, isFalse);
    });

    test('vor Oeffnungszeit: geschlossen, naechste Oeffnung heute', () {
      final status = OpenStatusService.isOpenNow(
          werktagsOrt, _am(Wochentag.mittwoch, 7, 0));
      expect(status.offen, isFalse);
      expect(status.naechsteOeffnung, isNotNull);
      expect(status.naechsteOeffnung!.istHeute, isTrue);
      expect(status.naechsteOeffnung!.von, const TimeOfDay(hour: 9, minute: 0));
    });

    test('nach Schliesszeit: naechste Oeffnung am Folgetag', () {
      final status = OpenStatusService.isOpenNow(
          werktagsOrt, _am(Wochentag.mittwoch, 19, 0));
      expect(status.offen, isFalse);
      expect(status.naechsteOeffnung!.istHeute, isFalse);
      expect(status.naechsteOeffnung!.wochentag, Wochentag.donnerstag);
      expect(status.naechsteOeffnung!.tageVoraus, 1);
    });

    test('Pause zwischen zwei Bloecken: geschlossen, naechster Block heute',
        () {
      final status = OpenStatusService.isOpenNow(
          mehrblockOrt, _am(Wochentag.mittwoch, 12, 0));
      expect(status.offen, isFalse);
      expect(status.naechsteOeffnung!.istHeute, isTrue);
      expect(
          status.naechsteOeffnung!.von, const TimeOfDay(hour: 14, minute: 0));
    });

    test('Mehrblock-Tag: jeder Block offen, jede Luecke geschlossen', () {
      bool offenUm(int h, int m) => OpenStatusService.isOpenNow(
            mehrblockOrt,
            _am(Wochentag.mittwoch, h, m),
          ).offen;

      expect(offenUm(8, 0), isTrue); // Block 1
      expect(offenUm(10, 59), isTrue);
      expect(offenUm(11, 0), isFalse); // Pause 1
      expect(offenUm(13, 59), isFalse);
      expect(offenUm(14, 0), isTrue); // Block 2
      expect(offenUm(16, 30), isFalse); // Pause 2
      expect(offenUm(17, 0), isTrue); // Block 3
      expect(offenUm(18, 59), isTrue);
      expect(offenUm(19, 0), isFalse); // Feierabend
    });

    test('zweiter Block liefert dessen Schliesszeit', () {
      final status = OpenStatusService.isOpenNow(
          mehrblockOrt, _am(Wochentag.mittwoch, 15, 0));
      expect(status.offen, isTrue);
      expect(status.schliesstUm, const TimeOfDay(hour: 16, minute: 0));
    });

    test('Tag ohne Eintrag: geschlossen', () {
      final status = OpenStatusService.isOpenNow(
          mehrblockOrt, _am(Wochentag.freitag, 10, 0));
      expect(status.offen, isFalse);
    });
  });

  group('findNextOpening (Wochengrenze)', () {
    test('Sonntag: naechste Oeffnung Montag', () {
      final next = OpenStatusService.findNextOpening(
          werktagsOrt, _am(Wochentag.sonntag, 12, 0));
      expect(next!.wochentag, Wochentag.montag);
      expect(next.tageVoraus, 1);
      expect(next.von, const TimeOfDay(hour: 9, minute: 0));
    });

    test('Samstag 23:59: ueberspringt Sonntag korrekt', () {
      final next = OpenStatusService.findNextOpening(
          nurMontag, _am(Wochentag.samstag, 23, 59));
      expect(next!.wochentag, Wochentag.montag);
      expect(next.tageVoraus, 2);
    });

    test('nie geoeffnet: null, kein Crash', () {
      final next = OpenStatusService.findNextOpening(
          nieGeoeffnet, _am(Wochentag.mittwoch, 10, 0));
      expect(next, isNull);
    });

    test('gleicher Wochentag naechste Woche (nach Schliessung heute)', () {
      // Montag 13:00, nur Montag 08-12 geoeffnet → naechster Montag (+7)
      final next = OpenStatusService.findNextOpening(
          nurMontag, _am(Wochentag.montag, 13, 0));
      expect(next!.wochentag, Wochentag.montag);
      expect(next.tageVoraus, 7);
    });
  });

  group('naechsteAenderung (E16 Scheduling)', () {
    test('liefert die naechste Block-Grenze heute', () {
      final naechste = OpenStatusService.naechsteAenderung(
          [mehrblockOrt], _am(Wochentag.mittwoch, 9, 30));
      expect(naechste, _am(Wochentag.mittwoch, 11, 0));
    });

    test('Grenze "von" eines spaeteren Blocks zaehlt ebenfalls', () {
      final naechste = OpenStatusService.naechsteAenderung(
          [mehrblockOrt], _am(Wochentag.mittwoch, 12, 30));
      expect(naechste, _am(Wochentag.mittwoch, 14, 0));
    });

    test('keine Grenze mehr heute: naechste Mitternacht', () {
      final naechste = OpenStatusService.naechsteAenderung(
          [mehrblockOrt], _am(Wochentag.mittwoch, 20, 0));
      expect(naechste, _am(Wochentag.donnerstag, 0, 0));
    });

    test('leere Liste: Mitternacht (Datumswechsel)', () {
      final naechste = OpenStatusService.naechsteAenderung(
          [], _am(Wochentag.mittwoch, 10, 0));
      expect(naechste, _am(Wochentag.donnerstag, 0, 0));
    });

    test('mehrere Orte: kleinste Grenze gewinnt', () {
      final naechste = OpenStatusService.naechsteAenderung(
          [werktagsOrt, mehrblockOrt], _am(Wochentag.mittwoch, 10, 30));
      // mehrblockOrt schliesst 11:00, werktagsOrt erst 18:00
      expect(naechste, _am(Wochentag.mittwoch, 11, 0));
    });
  });

  group('buildWidgetData', () {
    final l10n = lookupAppLocalizations(const Locale('de'));

    test('teilt korrekt in offen/geschlossen und sortiert alphabetisch', () {
      final orte = [
        _ort(id: 'c', name: 'Zebra-Laden', woche: {
          Wochentag.mittwoch: [_block(8, 0, 20, 0)],
        }),
        _ort(id: 'a', name: 'Apotheke', woche: {
          Wochentag.mittwoch: [_block(8, 0, 20, 0)],
        }),
        _ort(id: 'b', name: 'Behoerde', woche: {
          Wochentag.donnerstag: [_block(8, 0, 12, 0)],
        }),
      ];

      final daten = OpenStatusService.buildWidgetData(
          orte, _am(Wochentag.mittwoch, 9, 30), l10n);

      expect(daten.geoeffnet.map((e) => e.name), ['Apotheke', 'Zebra-Laden']);
      expect(daten.geschlossen.map((e) => e.name), ['Behoerde']);
      expect(daten.geoeffnet.first.statusText, 'bis 20:00');
    });

    test('statusText-Varianten', () {
      String text(Location ort, DateTime now) =>
          OpenStatusService.buildWidgetData([ort], now, l10n)
              .alle
              .single
              .statusText;

      // offen → "bis HH:MM"
      expect(text(werktagsOrt, _am(Wochentag.mittwoch, 10, 0)), 'bis 18:00');
      // Pause → "ab HH:MM" (naechster Block heute)
      expect(text(mehrblockOrt, _am(Wochentag.mittwoch, 12, 0)), 'ab 14:00');
      // morgen → "morgen ab HH:MM"
      expect(text(werktagsOrt, _am(Wochentag.mittwoch, 19, 0)),
          'morgen ab 09:00');
      // anderer Tag → "ab Mo 08:00"
      expect(
          text(nurMontag, _am(Wochentag.mittwoch, 10, 0)), 'ab Mo 08:00');
      // nie geoeffnet → "Keine Öffnungszeiten"
      expect(text(nieGeoeffnet, _am(Wochentag.mittwoch, 10, 0)),
          'Keine Öffnungszeiten');
    });
  });
}
