import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../models/app_einstellungen.dart';
import '../models/kategorie.dart';
import '../models/location.dart';

/// Liest und schreibt die WhenOpen-Datendatei (Schema 2.0).
///
/// Kritische Regel (Plan, Georg): nie Daten ohne Backup-Strategie
/// ueberschreiben; Schreiboperationen sind atomar (write-then-rename).
class LocationRepository {
  LocationRepository(this._verzeichnis);

  static const dateiname = 'whenopen_data.json';
  static const _uuid = Uuid();

  /// Hoechstzahl behaltener `whenopen_backup_*.json` — aeltere werden nach
  /// jedem neuen Backup geloescht, damit die Sicherungen nicht unbegrenzt
  /// wachsen und Speicher/Adressdaten ansammeln.
  static const _maxBackups = 5;

  /// Obergrenzen fuer eine importierte Sicherung — Schutz vor JSON-DoS durch
  /// eine riesige/tief verschachtelte Datei (untrusted, kann via Messenger
  /// empfangen worden sein). 2 MiB bzw. 1000 Einträge liegen weit über jedem
  /// realistischen Bestand (App-Limit: 50 Orte).
  static const _maxImportZeichen = 2 * 1024 * 1024;
  static const _maxImportEintraege = 1000;

  final Directory _verzeichnis;

  /// True, wenn beim letzten [laden] eine korrupte Datei weggesichert wurde.
  /// Die UI zeigt dann einmalig einen Hinweis-Dialog.
  bool letzterLadefehler = false;

  /// Serialisiert alle mutierenden Operationen. Jede Mutation ist ein
  /// read-modify-write (laden → aendern → speichern); ohne Serialisierung
  /// koennten zwei schnell aufeinanderfolgende Aenderungen sich gegenseitig
  /// ueberschreiben (Lost Update). Reine Lesezugriffe laufen weiter frei.
  Future<void> _schreibsperre = Future<void>.value();

  Future<T> _seriell<T>(Future<T> Function() aktion) {
    final lauf = _schreibsperre.then((_) => aktion());
    // Die Sperre laeuft auch nach einem Fehler weiter; der Fehler selbst geht
    // unveraendert an den Aufrufer.
    _schreibsperre = lauf.then((_) {}, onError: (_) {});
    return lauf;
  }

  /// Repository im App-Dokumentenverzeichnis (Produktionspfad).
  static Future<LocationRepository> imAppVerzeichnis() async {
    final dir = await getApplicationDocumentsDirectory();
    return LocationRepository(dir);
  }

  File get _datei => File('${_verzeichnis.path}/$dateiname');

  /// Laedt die Daten. Fehlende Datei → leere Daten. Korrupte Datei →
  /// Backup `whenopen_backup_[timestamp].json` anlegen, leer starten.
  Future<WhenOpenData> laden() async {
    letzterLadefehler = false;
    if (!await _datei.exists()) {
      return const WhenOpenData();
    }
    try {
      final inhalt = await _datei.readAsString();
      final json = jsonDecode(inhalt) as Map<String, dynamic>;
      return WhenOpenData.fromJson(json);
    } on Exception {
      // FormatException (kein JSON / falsche Struktur) oder TypeError-artige
      // Cast-Fehler beim Parsen — Originaldatei sichern, leer starten.
      await _sichereKorrupteDatei();
      letzterLadefehler = true;
      return const WhenOpenData();
    } catch (_) {
      // TypeError beim Cast ist kein Exception-Subtyp — gleiche Behandlung.
      await _sichereKorrupteDatei();
      letzterLadefehler = true;
      return const WhenOpenData();
    }
  }

  Future<void> _sichereKorrupteDatei() async {
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');
    final backupPfad =
        '${_verzeichnis.path}/whenopen_backup_$timestamp.json';
    await _datei.rename(backupPfad);
    await _begrenzeBackups();
  }

  /// Behaelt nur die juengsten [_maxBackups] `whenopen_backup_*.json` und
  /// loescht aeltere. Der Zeitstempel steckt im Dateinamen (ISO-8601), daher
  /// entspricht die lexikografische Sortierung der chronologischen.
  /// Aufraeumen darf den eigentlichen Vorgang nie stoeren — Fehler werden
  /// geschluckt.
  Future<void> _begrenzeBackups() async {
    try {
      final eintraege = await _verzeichnis.list().toList();
      final backups = eintraege
          .whereType<File>()
          .where((f) =>
              f.uri.pathSegments.last.startsWith('whenopen_backup_'))
          .toList()
        ..sort((a, b) => b.path.compareTo(a.path));
      for (final alt in backups.skip(_maxBackups)) {
        try {
          await alt.delete();
        } catch (_) {
          // einzelne Loeschfehler ignorieren
        }
      }
    } catch (_) {
      // Verzeichnis nicht lesbar o. Ae. — Cleanup ist best effort.
    }
  }

  /// Schreibt atomar: erst in `.tmp`, dann umbenennen. Auf Android (POSIX)
  /// ersetzt rename atomar; auf Windows (Tests) wird das Ziel vorab geloescht.
  Future<void> speichern(WhenOpenData daten) async {
    final tmp = File('${_verzeichnis.path}/$dateiname.tmp');
    const encoder = JsonEncoder.withIndent('  ');
    await tmp.writeAsString(encoder.convert(daten.toJson()), flush: true);
    try {
      await tmp.rename(_datei.path);
    } on FileSystemException {
      // Windows: rename auf existierende Datei kann fehlschlagen.
      await _datei.delete();
      await tmp.rename(_datei.path);
    }
  }

  Future<List<Location>> getAll() async => (await laden()).eintraege;

  Future<List<Kategorie>> getKategorien() async => (await laden()).kategorien;

  /// Neu anlegen oder (gleiche ID) aktualisieren.
  Future<void> saveLocation(Location location) => _seriell(() async {
        final daten = await laden();
        final eintraege = [...daten.eintraege];
        final index = eintraege.indexWhere((e) => e.id == location.id);
        if (index >= 0) {
          eintraege[index] = location;
        } else {
          eintraege.add(location);
        }
        await speichern(daten.copyWith(eintraege: eintraege));
      });

  Future<void> deleteLocation(String id) => _seriell(() async {
        final daten = await laden();
        await speichern(daten.copyWith(
          eintraege: daten.eintraege.where((e) => e.id != id).toList(),
        ));
      });

  /// Pfad der Datendatei (fuer Export via Share-Intent).
  Future<String> exportPath() async => _datei.path;

  // ── Einstellungen (Schema 2.1) ──────────────────────────────────────

  Future<AppEinstellungen> getEinstellungen() async =>
      (await laden()).einstellungen;

  /// Heimatadresse/Umkreis o. Ae. speichern (Eintraege bleiben unberuehrt).
  Future<void> setEinstellungen(AppEinstellungen einstellungen) =>
      _seriell(() async {
        final daten = await laden();
        await speichern(daten.copyWith(einstellungen: einstellungen));
      });

  // ── Backup / Wiederherstellen (P10) ─────────────────────────────────

  /// Pretty-gedruckter JSON-String der aktuellen Daten (fuer „Sichern" in den
  /// Download-Ordner und fuer die teilbare Kopie).
  Future<String> exportInhalt() async {
    final daten = await laden();
    return const JsonEncoder.withIndent('  ').convert(daten.toJson());
  }

  /// Schreibt eine datierte, teilbare Kopie der aktuellen Daten ins
  /// Temp-Verzeichnis und gibt die Datei zurueck (fuer den Teilen-Dialog).
  Future<File> exportKopie() async {
    final tmp = await getTemporaryDirectory();
    final datum = DateTime.now().toIso8601String().split('T').first;
    final ziel = File('${tmp.path}/whenopen-sicherung-$datum.json');
    await ziel.writeAsString(await exportInhalt(), flush: true);
    return ziel;
  }

  /// Validiert einen Sicherungs-String und gibt die enthaltenen Daten zurueck,
  /// **ohne zu speichern** — fuer die Import-Vorschau, bevor Bestandsdaten
  /// ersetzt werden. Wirft [FormatException] bei ungueltigem Inhalt.
  WhenOpenData pruefeSicherung(String inhalt) {
    if (inhalt.length > _maxImportZeichen) {
      throw const FormatException('Sicherungsdatei zu groß');
    }
    final dynamic roh = jsonDecode(inhalt);
    if (roh is! Map<String, dynamic> ||
        roh['version'] == null ||
        roh['eintraege'] is! List) {
      throw const FormatException('Keine gültige WhenOpen-Sicherung');
    }
    final kategorien = roh['kategorien'];
    if ((roh['eintraege'] as List).length > _maxImportEintraege ||
        (kategorien is List && kategorien.length > _maxImportEintraege)) {
      throw const FormatException('Sicherung enthält zu viele Einträge');
    }
    // Wirft bei falschem Schema (z. B. kaputte Eintraege) — bewusst vor dem
    // Speichern, damit die Bestandsdaten erst nach erfolgreicher Pruefung
    // ersetzt werden.
    return WhenOpenData.fromJson(roh);
  }

  /// Stellt Daten aus einem JSON-String wieder her. Validiert zuerst — bei
  /// ungueltigem Inhalt wirft die Methode und die aktuellen Daten bleiben
  /// unangetastet. Vor dem Ueberschreiben wird die aktuelle Datei gesichert.
  Future<void> importJson(String inhalt) => _seriell(() async {
        final daten = pruefeSicherung(inhalt);
        if (await _datei.exists()) {
          final ts = DateTime.now()
              .toIso8601String()
              .replaceAll(':', '-')
              .replaceAll('.', '-');
          await _datei.copy('${_verzeichnis.path}/whenopen_backup_$ts.json');
          await _begrenzeBackups();
        }
        await speichern(daten);
      });

  // ── Kategorien (E15) ────────────────────────────────────────────────

  Future<Kategorie> addKategorie(String name, {String? farbe}) =>
      _seriell(() async {
        final daten = await laden();
        final naechsteSortierung = daten.kategorien.isEmpty
            ? 0
            : daten.kategorien
                    .map((k) => k.sortierung)
                    .reduce((a, b) => a > b ? a : b) +
                1;
        final kategorie = Kategorie(
          id: _uuid.v4(),
          name: name,
          farbe: farbe,
          sortierung: naechsteSortierung,
        );
        await speichern(
            daten.copyWith(kategorien: [...daten.kategorien, kategorie]));
        return kategorie;
      });

  Future<void> renameKategorie(String id, String neuerName) =>
      _seriell(() => _updateKategorie(id, (k) => k.copyWith(name: neuerName)));

  Future<void> setKategorieFarbe(String id, String? farbe) => _seriell(
        () => _updateKategorie(
            id, (k) => k.copyWith(farbe: farbe, farbeLoeschen: farbe == null)),
      );

  Future<void> _updateKategorie(
      String id, Kategorie Function(Kategorie) update) async {
    final daten = await laden();
    await speichern(daten.copyWith(
      kategorien: daten.kategorien
          .map((k) => k.id == id ? update(k) : k)
          .toList(),
    ));
  }

  /// Alle Eintraege von [vonId] nach [nachId] umhaengen, Quelle loeschen.
  Future<void> mergeKategorien(String vonId, String nachId) =>
      _seriell(() async {
        final daten = await laden();
        await speichern(daten.copyWith(
          kategorien: daten.kategorien.where((k) => k.id != vonId).toList(),
          eintraege: daten.eintraege
              .map((e) =>
                  e.kategorie == vonId ? e.copyWith(kategorie: nachId) : e)
              .toList(),
        ));
      });

  /// Kategorie loeschen — betroffene Eintraege fallen auf "Sonstige" (null).
  Future<void> deleteKategorie(String id) => _seriell(() async {
        final daten = await laden();
        await speichern(daten.copyWith(
          kategorien: daten.kategorien.where((k) => k.id != id).toList(),
          eintraege: daten.eintraege
              .map((e) =>
                  e.kategorie == id ? e.copyWith(kategorieLoeschen: true) : e)
              .toList(),
        ));
      });

  /// Sortierung der Kategorien neu setzen (Drag-Reihenfolge, E15).
  Future<void> setKategorienReihenfolge(List<String> idsInReihenfolge) =>
      _seriell(() async {
        final daten = await laden();
        await speichern(daten.copyWith(
          kategorien: daten.kategorien.map((k) {
            final neu = idsInReihenfolge.indexOf(k.id);
            return neu >= 0 ? k.copyWith(sortierung: neu) : k;
          }).toList(),
        ));
      });
}
