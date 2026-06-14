import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:when_open/models/app_einstellungen.dart';
import 'package:when_open/models/location.dart';
import 'package:when_open/models/opening_day.dart';
import 'package:when_open/models/wochentag.dart';
import 'package:when_open/repositories/location_repository.dart';

/// Beispiel-JSON aus 1.1-spezifikation.md (Schema 2.0).
const _spezifikationsBeispiel = '''
{
  "version": "2.0",
  "kategorien": [
    { "id": "kat-fam", "name": "Familie", "farbe": "#28b765", "sortierung": 0 }
  ],
  "eintraege": [
    {
      "id": "uuid-1234",
      "name": "Kinderarzt Müller",
      "adresse": "Musterstraße 1, 50667 Köln",
      "telefon": "0221 123456",
      "google_maps_link": "https://maps.google.com/?cid=123",
      "kategorie": "kat-fam",
      "erstellt_am": "2026-06-01T10:00:00Z",
      "geaendert_am": "2026-06-01T10:00:00Z",
      "oeffnungszeiten": [
        { "wochentag": "mo", "geoeffnet": true, "zeiten": [ { "von": "08:00", "bis": "11:00" }, { "von": "14:00", "bis": "16:00" }, { "von": "17:00", "bis": "19:00" } ] },
        { "wochentag": "di", "geoeffnet": true, "zeiten": [ { "von": "08:00", "bis": "18:00" } ] },
        { "wochentag": "mi", "geoeffnet": false, "zeiten": [] },
        { "wochentag": "do", "geoeffnet": true, "zeiten": [ { "von": "08:00", "bis": "18:00" } ] },
        { "wochentag": "fr", "geoeffnet": true, "zeiten": [ { "von": "08:00", "bis": "13:00" } ] },
        { "wochentag": "sa", "geoeffnet": false, "zeiten": [] },
        { "wochentag": "so", "geoeffnet": false, "zeiten": [] }
      ]
    }
  ]
}
''';

Location _testLocation({String id = 'loc-1', String name = 'Testort'}) {
  return Location(
    id: id,
    name: name,
    oeffnungszeiten: [
      const OpeningDay(wochentag: Wochentag.montag, zeiten: [
        TimeBlock(von: TimeOfDay(hour: 9, minute: 0), bis: TimeOfDay(hour: 18, minute: 0)),
      ]),
      const OpeningDay(wochentag: Wochentag.dienstag, zeiten: []),
      const OpeningDay(wochentag: Wochentag.mittwoch, zeiten: []),
      const OpeningDay(wochentag: Wochentag.donnerstag, zeiten: []),
      const OpeningDay(wochentag: Wochentag.freitag, zeiten: []),
      const OpeningDay(wochentag: Wochentag.samstag, zeiten: []),
      const OpeningDay(wochentag: Wochentag.sonntag, zeiten: []),
    ],
    erstelltAm: DateTime.utc(2026, 6, 10, 12),
    geaendertAm: DateTime.utc(2026, 6, 10, 12),
  );
}

void main() {
  late Directory tempDir;
  late LocationRepository repo;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('whenopen_test_');
    repo = LocationRepository(tempDir);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Laden', () {
    test('fehlende Datei ergibt leere Daten', () async {
      final daten = await repo.laden();
      expect(daten.eintraege, isEmpty);
      expect(daten.kategorien, isEmpty);
      expect(repo.letzterLadefehler, isFalse);
    });

    test('valide JSON aus der Spezifikation wird korrekt geparst', () async {
      final datei = File('${tempDir.path}/${LocationRepository.dateiname}');
      await datei.writeAsString(_spezifikationsBeispiel);

      final daten = await repo.laden();

      expect(daten.eintraege, hasLength(1));
      final ort = daten.eintraege.single;
      expect(ort.id, 'uuid-1234');
      expect(ort.name, 'Kinderarzt Müller');
      expect(ort.adresse, 'Musterstraße 1, 50667 Köln');
      expect(ort.telefon, '0221 123456');
      expect(ort.googleMapsLink, 'https://maps.google.com/?cid=123');
      expect(ort.kategorie, 'kat-fam');
      expect(ort.oeffnungszeiten, hasLength(7));

      // E9: Montag hat 3 Zeitbloecke (2 Pausen)
      final montag = ort.oeffnungszeiten
          .firstWhere((t) => t.wochentag == Wochentag.montag);
      expect(montag.geoeffnet, isTrue);
      expect(montag.zeiten, hasLength(3));
      expect(montag.zeiten[0].von, const TimeOfDay(hour: 8, minute: 0));
      expect(montag.zeiten[0].bis, const TimeOfDay(hour: 11, minute: 0));
      expect(montag.zeiten[2].von, const TimeOfDay(hour: 17, minute: 0));

      final mittwoch = ort.oeffnungszeiten
          .firstWhere((t) => t.wochentag == Wochentag.mittwoch);
      expect(mittwoch.geoeffnet, isFalse);
      expect(mittwoch.zeiten, isEmpty);

      // E15: Kategorien-Liste
      expect(daten.kategorien, hasLength(1));
      expect(daten.kategorien.single.id, 'kat-fam');
      expect(daten.kategorien.single.name, 'Familie');
      expect(daten.kategorien.single.farbe, '#28b765');
    });

    test('fehlende Wochentage werden als geschlossen aufgefuellt', () async {
      // Nur Montag vorhanden — Rest muss beim Laden ergaenzt werden.
      final json = {
        'version': '2.0',
        'kategorien': <Object>[],
        'eintraege': [
          {
            'id': 'x',
            'name': 'Nur Montag',
            'erstellt_am': '2026-06-01T10:00:00Z',
            'geaendert_am': '2026-06-01T10:00:00Z',
            'oeffnungszeiten': [
              {
                'wochentag': 'mo',
                'geoeffnet': true,
                'zeiten': [
                  {'von': '09:00', 'bis': '17:00'},
                ],
              },
            ],
          },
        ],
      };
      final datei = File('${tempDir.path}/${LocationRepository.dateiname}');
      await datei.writeAsString(jsonEncode(json));

      final daten = await repo.laden();
      final ort = daten.eintraege.single;
      expect(ort.oeffnungszeiten, hasLength(7));
      expect(
        ort.oeffnungszeiten.where((t) => t.geoeffnet).map((t) => t.wochentag),
        [Wochentag.montag],
      );
    });

    test('korrupte JSON: Backup wird angelegt, leere Daten zurueck', () async {
      final datei = File('${tempDir.path}/${LocationRepository.dateiname}');
      await datei.writeAsString('das ist kein json {{{');

      final daten = await repo.laden();

      expect(daten.eintraege, isEmpty);
      expect(repo.letzterLadefehler, isTrue);

      final backups = tempDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.contains('whenopen_backup_'))
          .toList();
      expect(backups, hasLength(1));
      // Originaldatei wurde wegbewegt — kein erneuter Fehler beim Laden
      expect(await datei.exists(), isFalse);
    });
  });

  group('Speichern', () {
    test('Eintrag speichern und wieder lesen (Roundtrip ohne Verlust)',
        () async {
      final ort = _testLocation();
      await repo.saveLocation(ort);

      final daten = await repo.laden();
      final geladen = daten.eintraege.single;
      expect(geladen.id, ort.id);
      expect(geladen.name, ort.name);
      expect(geladen.oeffnungszeiten[0].zeiten.single.von,
          const TimeOfDay(hour: 9, minute: 0));
      expect(geladen.oeffnungszeiten[0].zeiten.single.bis,
          const TimeOfDay(hour: 18, minute: 0));
      expect(geladen.erstelltAm, ort.erstelltAm);
    });

    test('TimeOfDay wird als HH:MM gespeichert', () async {
      await repo.saveLocation(_testLocation());
      final inhalt = await File(
              '${tempDir.path}/${LocationRepository.dateiname}')
          .readAsString();
      final json = jsonDecode(inhalt) as Map<String, dynamic>;
      final zeiten = (((json['eintraege'] as List).first
              as Map<String, dynamic>)['oeffnungszeiten'] as List)
          .first as Map<String, dynamic>;
      expect((zeiten['zeiten'] as List).first, {'von': '09:00', 'bis': '18:00'});
    });

    test('vorhandener Eintrag wird aktualisiert statt dupliziert', () async {
      await repo.saveLocation(_testLocation(name: 'Alt'));
      await repo.saveLocation(_testLocation(name: 'Neu'));

      final daten = await repo.laden();
      expect(daten.eintraege, hasLength(1));
      expect(daten.eintraege.single.name, 'Neu');
    });

    test('atomares Schreiben hinterlaesst keine Temp-Datei', () async {
      await repo.saveLocation(_testLocation());
      final tmpDateien = tempDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.tmp'))
          .toList();
      expect(tmpDateien, isEmpty);
    });

    test('Schema-Version 2.1 wird geschrieben', () async {
      await repo.saveLocation(_testLocation());
      final json = jsonDecode(await File(
              '${tempDir.path}/${LocationRepository.dateiname}')
          .readAsString()) as Map<String, dynamic>;
      expect(json['version'], '2.1');
    });
  });

  group('Einstellungen (Schema 2.1)', () {
    test('Heimatadresse + Umkreis Roundtrip', () async {
      await repo.setEinstellungen(const AppEinstellungen(
        heimatAdresse: 'Hauptstraße 1, Köln',
        heimatLat: 50.94,
        heimatLon: 6.96,
        umkreisMeter: 2000,
      ));

      final einst = await repo.getEinstellungen();
      expect(einst.heimatAdresse, 'Hauptstraße 1, Köln');
      expect(einst.heimatLat, 50.94);
      expect(einst.heimatLon, 6.96);
      expect(einst.umkreisMeter, 2000);
      expect(einst.hatHeimat, isTrue);
    });

    test('Einstellungen lassen die Eintraege unberuehrt', () async {
      await repo.saveLocation(_testLocation(id: 'bleibt'));
      await repo.setEinstellungen(
          const AppEinstellungen(heimatLat: 1, heimatLon: 2));

      final daten = await repo.laden();
      expect(daten.eintraege.single.id, 'bleibt');
      expect(daten.einstellungen.heimatLat, 1);
    });

    test('alte 2.0-Datei ohne einstellungen laedt mit Default', () async {
      final datei = File('${tempDir.path}/${LocationRepository.dateiname}');
      await datei.writeAsString(_spezifikationsBeispiel); // version 2.0

      final daten = await repo.laden();
      expect(daten.einstellungen.hatHeimat, isFalse);
      expect(daten.einstellungen.umkreisMeter, AppEinstellungen.standardUmkreis);
    });
  });

  group('Loeschen', () {
    test('Eintrag loeschen entfernt ihn', () async {
      await repo.saveLocation(_testLocation(id: 'a'));
      await repo.saveLocation(_testLocation(id: 'b', name: 'Anderer'));

      await repo.deleteLocation('a');

      final daten = await repo.laden();
      expect(daten.eintraege.map((e) => e.id), ['b']);
    });
  });

  group('Kategorien (E15)', () {
    test('Kategorie anlegen vergibt ID und Sortierung', () async {
      final kat = await repo.addKategorie('Behörden', farbe: '#5b8def');
      expect(kat.id, isNotEmpty);
      expect(kat.name, 'Behörden');
      expect(kat.sortierung, 0);

      final kat2 = await repo.addKategorie('Gesundheit');
      expect(kat2.sortierung, 1);

      final daten = await repo.laden();
      expect(daten.kategorien, hasLength(2));
    });

    test('Umbenennen wirkt nur auf die Kategorie, IDs bleiben stabil',
        () async {
      final kat = await repo.addKategorie('Behörden');
      final ort = _testLocation().copyWith(kategorie: kat.id);
      await repo.saveLocation(ort);

      await repo.renameKategorie(kat.id, 'Ämter');

      final daten = await repo.laden();
      expect(daten.kategorien.single.name, 'Ämter');
      expect(daten.kategorien.single.id, kat.id);
      expect(daten.eintraege.single.kategorie, kat.id);
    });

    test('Zusammenfuehren haengt alle Eintraege um und loescht die Quelle',
        () async {
      final von = await repo.addKategorie('Beratung');
      final nach = await repo.addKategorie('Behörden');
      await repo.saveLocation(
          _testLocation(id: 'a').copyWith(kategorie: von.id));
      await repo.saveLocation(
          _testLocation(id: 'b', name: 'B').copyWith(kategorie: nach.id));

      await repo.mergeKategorien(von.id, nach.id);

      final daten = await repo.laden();
      expect(daten.kategorien.map((k) => k.id), [nach.id]);
      expect(daten.eintraege.every((e) => e.kategorie == nach.id), isTrue);
    });

    test('Loeschen setzt betroffene Eintraege auf null (Sonstige)', () async {
      final kat = await repo.addKategorie('Einkauf');
      await repo
          .saveLocation(_testLocation(id: 'a').copyWith(kategorie: kat.id));

      await repo.deleteKategorie(kat.id);

      final daten = await repo.laden();
      expect(daten.kategorien, isEmpty);
      expect(daten.eintraege.single.kategorie, isNull);
    });
  });

  group('Backup / Wiederherstellen (P10)', () {
    test('importJson ersetzt die Daten bei gueltiger Sicherung', () async {
      await repo.saveLocation(_testLocation(id: 'alt', name: 'Alter Ort'));

      await repo.importJson(_spezifikationsBeispiel);

      final daten = await repo.laden();
      expect(daten.eintraege.map((e) => e.id), ['uuid-1234']);
      expect(daten.kategorien.single.name, 'Familie');
    });

    test('importJson sichert die bisherige Datei vor dem Ueberschreiben',
        () async {
      await repo.saveLocation(_testLocation(id: 'alt'));

      await repo.importJson(_spezifikationsBeispiel);

      final backups = tempDir.listSync().whereType<File>().where(
            (f) => f.uri.pathSegments.last.startsWith('whenopen_backup_'),
          );
      expect(backups, isNotEmpty);
    });

    test('importJson wirft bei kaputtem JSON, Daten bleiben unangetastet',
        () async {
      await repo.saveLocation(_testLocation(id: 'bleibt'));

      await expectLater(
          repo.importJson('{ kein json'), throwsFormatException);

      final daten = await repo.laden();
      expect(daten.eintraege.single.id, 'bleibt');
    });

    test('importJson wirft bei fremdem JSON ohne version/eintraege', () async {
      await repo.saveLocation(_testLocation(id: 'bleibt'));

      await expectLater(
          repo.importJson('{"foo": 1}'), throwsFormatException);

      final daten = await repo.laden();
      expect(daten.eintraege.single.id, 'bleibt');
    });
  });

  group('Export-Inhalt + Vorschau (P10.1)', () {
    test('exportInhalt liefert gueltiges JSON der aktuellen Daten', () async {
      await repo.saveLocation(_testLocation(id: 'x', name: 'Export'));

      final inhalt = await repo.exportInhalt();
      final json = jsonDecode(inhalt) as Map<String, dynamic>;

      expect(json['version'], '2.1');
      expect((json['eintraege'] as List).single['name'], 'Export');
    });

    test('pruefeSicherung validiert ohne zu speichern', () async {
      await repo.saveLocation(_testLocation(id: 'bleibt'));

      final daten = repo.pruefeSicherung(_spezifikationsBeispiel);
      expect(daten.eintraege.single.id, 'uuid-1234');
      expect(daten.kategorien.single.name, 'Familie');

      // Bestand bleibt unangetastet — Vorschau speichert nicht.
      final aktuell = await repo.laden();
      expect(aktuell.eintraege.single.id, 'bleibt');
    });

    test('pruefeSicherung wirft bei fremdem oder kaputtem JSON', () {
      expect(() => repo.pruefeSicherung('{"foo": 1}'), throwsFormatException);
      expect(() => repo.pruefeSicherung('{ kein json'), throwsFormatException);
    });

    test('pruefeSicherung wirft bei uebergrosser Datei (JSON-DoS-Schutz)', () {
      // > 2 MiB: wird vor jsonDecode abgewiesen, ohne den Parser zu belasten.
      final riesig = '{"version":"2.0","eintraege":[],"x":"'
          '${'a' * (2 * 1024 * 1024 + 10)}"}';
      expect(() => repo.pruefeSicherung(riesig), throwsFormatException);
    });

    test('pruefeSicherung wirft bei zu vielen Eintraegen', () {
      final eintrag = '{"id":"x","name":"X","oeffnungszeiten":[],'
          '"erstellt_am":"2026-06-01T10:00:00Z",'
          '"geaendert_am":"2026-06-01T10:00:00Z"}';
      final viele = '{"version":"2.0","eintraege":['
          '${List.filled(1001, eintrag).join(',')}]}';
      expect(() => repo.pruefeSicherung(viele), throwsFormatException);
    });
  });

  group('Nebenlaeufigkeit & Backup-Deckel', () {
    test('parallele Mutationen gehen nicht verloren (serialisiert)', () async {
      // Fuenf saveLocation OHNE await dazwischen — ohne Serialisierung wuerde
      // ein read-modify-write den anderen ueberschreiben (Lost Update).
      await Future.wait([
        for (var i = 0; i < 5; i++)
          repo.saveLocation(_testLocation(id: 'loc-$i', name: 'Ort $i')),
      ]);

      final daten = await repo.laden();
      expect(daten.eintraege.map((e) => e.id).toSet(),
          {'loc-0', 'loc-1', 'loc-2', 'loc-3', 'loc-4'});
    });

    test('alte whenopen_backup_*.json werden gedeckelt (hoechstens 5)',
        () async {
      await repo.saveLocation(_testLocation(id: 'basis'));

      // Acht Wiederherstellungen erzeugen acht Backup-Versuche; der Cleanup
      // soll auf die juengsten fuenf kappen. Der kleine Abstand sorgt fuer
      // eindeutige Zeitstempel im Dateinamen.
      for (var i = 0; i < 8; i++) {
        await repo.importJson(_spezifikationsBeispiel);
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }

      final backups = tempDir
          .listSync()
          .whereType<File>()
          .where(
              (f) => f.uri.pathSegments.last.startsWith('whenopen_backup_'))
          .length;
      expect(backups, lessThanOrEqualTo(5));
      expect(backups, greaterThan(0));
    });
  });
}
