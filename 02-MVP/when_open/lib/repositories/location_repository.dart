import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

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

  final Directory _verzeichnis;

  /// True, wenn beim letzten [laden] eine korrupte Datei weggesichert wurde.
  /// Die UI zeigt dann einmalig einen Hinweis-Dialog.
  bool letzterLadefehler = false;

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
  Future<void> saveLocation(Location location) async {
    final daten = await laden();
    final eintraege = [...daten.eintraege];
    final index = eintraege.indexWhere((e) => e.id == location.id);
    if (index >= 0) {
      eintraege[index] = location;
    } else {
      eintraege.add(location);
    }
    await speichern(daten.copyWith(eintraege: eintraege));
  }

  Future<void> deleteLocation(String id) async {
    final daten = await laden();
    await speichern(daten.copyWith(
      eintraege: daten.eintraege.where((e) => e.id != id).toList(),
    ));
  }

  /// Pfad der Datendatei (fuer Export via Share-Intent).
  Future<String> exportPath() async => _datei.path;

  // ── Kategorien (E15) ────────────────────────────────────────────────

  Future<Kategorie> addKategorie(String name, {String? farbe}) async {
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
  }

  Future<void> renameKategorie(String id, String neuerName) async {
    await _updateKategorie(id, (k) => k.copyWith(name: neuerName));
  }

  Future<void> setKategorieFarbe(String id, String? farbe) async {
    await _updateKategorie(
        id, (k) => k.copyWith(farbe: farbe, farbeLoeschen: farbe == null));
  }

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
  Future<void> mergeKategorien(String vonId, String nachId) async {
    final daten = await laden();
    await speichern(daten.copyWith(
      kategorien: daten.kategorien.where((k) => k.id != vonId).toList(),
      eintraege: daten.eintraege
          .map((e) => e.kategorie == vonId ? e.copyWith(kategorie: nachId) : e)
          .toList(),
    ));
  }

  /// Kategorie loeschen — betroffene Eintraege fallen auf "Sonstige" (null).
  Future<void> deleteKategorie(String id) async {
    final daten = await laden();
    await speichern(daten.copyWith(
      kategorien: daten.kategorien.where((k) => k.id != id).toList(),
      eintraege: daten.eintraege
          .map((e) =>
              e.kategorie == id ? e.copyWith(kategorieLoeschen: true) : e)
          .toList(),
    ));
  }

  /// Sortierung der Kategorien neu setzen (Drag-Reihenfolge, E15).
  Future<void> setKategorienReihenfolge(List<String> idsInReihenfolge) async {
    final daten = await laden();
    await speichern(daten.copyWith(
      kategorien: daten.kategorien.map((k) {
        final neu = idsInReihenfolge.indexOf(k.id);
        return neu >= 0 ? k.copyWith(sortierung: neu) : k;
      }).toList(),
    ));
  }
}
